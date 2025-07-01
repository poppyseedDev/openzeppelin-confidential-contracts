// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {FHE, externalEuint64, ebool, euint64} from "@fhevm/solidity/lib/FHE.sol";

import {TFHESafeMath} from "../utils/TFHESafeMath.sol";
import {ManagedVault} from "./ManagedVault.sol";
import {ConfidentialFungibleToken} from "../token/ConfidentialFungibleToken.sol";

contract VestingConfidential {
    using FHE for *;

    struct VestingStream {
        uint48 startTime;
        address recipient;
        euint64 totalAmount;
        euint64 amountPerSecond;
        euint64 claimed;
    }

    error VestingBaseOnlyRecipient(address recipient);

    event VestingBaseManagedVaultCreated(uint256 vestingStreamId, address managedVault);

    mapping(uint256 => VestingStream) private _vestingStreams;
    mapping(uint256 vestingId => address managedVault) private _managedVaults;
    address private immutable _managedVaultImplementation = address(new ManagedVault());
    uint256 private _numVestingStreams;
    ConfidentialFungibleToken immutable token;

    constructor(ConfidentialFungibleToken token_) {
        token = token_;
    }

    function claim(uint256 streamId) public virtual {
        require(msg.sender == _vestingStreams[streamId].recipient);
        _claim(streamId);
    }

    function getOrCreateManagedVault(uint256 streamId) public virtual returns (address) {
        address existingVault = getManagedVault(streamId);
        if (existingVault != address(0)) {
            return existingVault;
        }
        // claim(streamId);
        return _setUpManagedVault(streamId);
    }

    function getManagedVault(uint256 streamId) public view virtual returns (address) {
        return _managedVaults[streamId];
    }

    function managedVaultImplementation() public view virtual returns (address) {
        return _managedVaultImplementation;
    }

    function createVestingStream(
        uint48 startTime,
        address recipient,
        externalEuint64 totalAmount,
        externalEuint64 amountPerSecond,
        bytes memory amountInputProof,
        bytes memory amountPerSecondInputProof
    ) public virtual {
        _createVestingStream(
            startTime,
            recipient,
            totalAmount.fromExternal(amountInputProof),
            amountPerSecond.fromExternal(amountPerSecondInputProof)
        );
    }

    function _doTransferIn(address from, euint64 amount) internal virtual returns (euint64) {
        amount.allowTransient(address(token));

        return token.confidentialTransferFrom(from, address(this), amount);
    }

    function _doTransferOut(address to, euint64 amount) internal virtual returns (euint64) {
        return _doTransferOut(address(this), to, amount);
    }

    function _doTransferOut(address from, address to, euint64 amount) internal virtual returns (euint64) {
        amount.allowTransient(address(token));

        return token.confidentialTransferFrom(from, to, amount);
    }

    function _setUpManagedVault(uint256 streamId) internal virtual returns (address) {
        address recipient = _vestingStreams[streamId].recipient;
        require(recipient == msg.sender, VestingBaseOnlyRecipient(recipient));

        address vault = Clones.clone(managedVaultImplementation());
        _managedVaults[streamId] = vault;

        (, euint64 amountToTransfer) = TFHESafeMath.tryDecrease(
            _vestingStreams[streamId].totalAmount,
            _vestingStreams[streamId].claimed
        );
        _doTransferOut(vault, amountToTransfer);

        emit VestingBaseManagedVaultCreated(streamId, vault);

        // Set this contract as operator for the vault
        ManagedVault(vault).call(
            address(token),
            0,
            abi.encodeCall(ConfidentialFungibleToken.setOperator, (address(this), type(uint48).max))
        );

        return vault;
    }

    function _createVestingStream(
        uint48 startTime,
        address recipient,
        euint64 amount,
        euint64 amountPerSecond
    ) internal {
        euint64 amountTransferredIn = _doTransferIn(msg.sender, amount);
        amountTransferredIn.allowThis();
        amountPerSecond.allowThis();

        _vestingStreams[++_numVestingStreams] = VestingStream({
            startTime: startTime,
            recipient: recipient,
            totalAmount: amountTransferredIn,
            amountPerSecond: amountPerSecond,
            claimed: FHE.asEuint64(0)
        });
    }

    function _claim(uint256 streamId) internal virtual {
        VestingStream storage stream = _vestingStreams[streamId];
        (ebool success, euint64 claimAmount) = TFHESafeMath.tryDecrease(
            FHE.min(FHE.mul(stream.amountPerSecond, uint64(block.timestamp - stream.startTime)), stream.totalAmount),
            stream.claimed
        );

        euint64 amountToTransferOut = FHE.select(success, claimAmount, FHE.asEuint64(0));

        // If managed vault exists, do transfer out from there
        address managedVault = getManagedVault(streamId);
        euint64 amountTransferredOut;
        if (managedVault != address(0)) {
            amountTransferredOut = _doTransferOut(managedVault, stream.recipient, amountToTransferOut);
        } else {
            amountTransferredOut = _doTransferOut(stream.recipient, amountToTransferOut);
        }

        (, euint64 newAmountClaimed) = TFHESafeMath.tryIncrease(stream.claimed, amountTransferredOut);
        newAmountClaimed.allowThis();
        stream.claimed = newAmountClaimed;
    }
}
