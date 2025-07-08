// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FHE, euint64, ebool} from "@fhevm/solidity/lib/FHE.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {VestingWalletConfidential} from "./VestingWalletConfidential.sol";
import {IConfidentialFungibleToken} from "../interfaces/IConfidentialFungibleToken.sol";

abstract contract VestingWalletConfidentialFactory {
    address private _vestingWalletConfidentialImplementation;

    error VestingWalletConfidentialInvalidDuration();
    error VestingWalletConfidentialInvalidStartTimestamp(address beneficiary, uint64 startTimestamp);

    /**
     * @dev
     */
    event VestingWalletConfidentialBatchFunded(ebool success);
    /**
     * @dev
     */
    event VestingWalletConfidentialCreated(address beneficiary, uint64 startTimestamp);

    /**
     * @dev
     */
    struct VestingPlan {
        address beneficiary;
        euint64 encryptedAmount;
        uint64 startTimestamp;
    }

    /**
     * @dev
     */
    constructor() {
        _vestingWalletConfidentialImplementation = address(new VestingWalletConfidential(address(0), address(0), 0, 0));
    }

    /**
     * @dev Batches the funding of multiple confidential vesting wallets.
     *
     * Funds are sent to predeterministic wallet addresses. Wallets can be created later.
     */
    function batchFundVestingWalletConfidential(
        address confidentialFungibleToken,
        euint64 totalEncryptedAmount,
        VestingPlan[] calldata vestingPlans,
        uint64 durationSeconds
    ) external returns (ebool) {
        require(durationSeconds > 0, VestingWalletConfidentialInvalidDuration());
        uint256 vestingPlansLength = vestingPlans.length;
        euint64 totalTransferedAmount = euint64.wrap(0);
        for (uint256 i = 0; i < vestingPlansLength; i++) {
            VestingPlan memory vestingPlan = vestingPlans[i];
            address beneficiary = vestingPlan.beneficiary;
            euint64 encryptedAmount = vestingPlan.encryptedAmount;
            uint64 startTimestamp = vestingPlan.startTimestamp;
            require(
                startTimestamp >= block.timestamp,
                VestingWalletConfidentialInvalidStartTimestamp(beneficiary, startTimestamp)
            );
            address vestingWalletConfidential = Clones.predictDeterministicAddress(
                _vestingWalletConfidentialImplementation,
                _getCreate2VestingWalletConfidentialSalt(beneficiary, startTimestamp),
                address(this)
            );
            euint64 transferredAmount = IConfidentialFungibleToken(confidentialFungibleToken).confidentialTransferFrom(
                msg.sender,
                vestingWalletConfidential,
                encryptedAmount
            );
            totalTransferedAmount = FHE.select(
                FHE.eq(encryptedAmount, transferredAmount),
                FHE.add(totalTransferedAmount, transferredAmount),
                FHE.asEuint64(0)
            );
        }
        ebool success = FHE.eq(totalTransferedAmount, totalEncryptedAmount);
        emit VestingWalletConfidentialBatchFunded(success);
        return success;
    }

    /**
     * @dev Creates a confidential vesting wallet.
     */
    function createVestingWalletConfidential(
        address executor,
        address beneficiary,
        uint64 startTimestamp,
        uint64 durationSeconds
    ) external returns (bool) {
        // TODO: Check params are authorized
        // Will revert if clone already created
        Clones.cloneDeterministicWithImmutableArgs(
            _vestingWalletConfidentialImplementation,
            abi.encodePacked(executor, beneficiary, startTimestamp, durationSeconds),
            _getCreate2VestingWalletConfidentialSalt(beneficiary, startTimestamp)
        );
        emit VestingWalletConfidentialCreated(beneficiary, startTimestamp);
        return true;
    }

    /**
     * @dev Gets create2 VestingWalletConfidential salt.
     */
    function _getCreate2VestingWalletConfidentialSalt(
        address beneficiary,
        uint64 startTimestamp
    ) internal virtual returns (bytes32) {
        return keccak256(abi.encodePacked(beneficiary, startTimestamp));
    }
}
