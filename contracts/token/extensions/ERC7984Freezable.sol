// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {FHE, ebool, euint64, externalEuint64} from "@fhevm/solidity/lib/FHE.sol";
import {ConfidentialFungibleToken} from "../ConfidentialFungibleToken.sol";
import {TFHESafeMath} from "../../utils/TFHESafeMath.sol";

/**
 * Inspired by https://github.com/OpenZeppelin/openzeppelin-community-contracts/pull/186.
 *
 * @dev Extension of {ERC7984} that allows to implement a freezing
 * mechanism that can be managed by an authorized account with the
 * {_setConfidentialFrozen} function.
 *
 * The freezing mechanism provides the guarantee to the contract owner
 * (e.g. a DAO or a well-configured multisig) that a specific amount
 * of tokens held by an account won't be transferable until those
 * tokens are unfrozen.
 */
abstract contract ERC7984Freezable is ConfidentialFungibleToken {
    /// @dev Frozen amount of tokens per address.
    mapping(address account => euint64 encryptedAmount) private _frozenBalances;

    error ERC7984UnauthorizedUseOfEncryptedAmount(euint64 encryptedAmount, address user);

    event Frozen(address indexed account, euint64 encryptedAmount);

    /// @dev Returns the frozen balance of an account.
    function confidentialFrozen(address account) public view virtual returns (euint64) {
        return _frozenBalances[account];
    }

    /// @dev Returns the available (unfrozen) balance of an account. Up to {confidentialBalanceOf}.
    function confidentialAvailable(address account) public virtual returns (euint64) {
        (ebool success, euint64 unfrozen) = TFHESafeMath.tryDecrease(
            confidentialBalanceOf(account),
            confidentialFrozen(account)
        );
        FHE.allowThis(unfrozen);
        return FHE.select(success, unfrozen, FHE.asEuint64(0));
    }

    /// @dev Internal function to set the frozen token amount for an account.
    function _setConfidentialFrozen(address account, euint64 encryptedAmount) internal virtual returns (euint64) {
        require(
            FHE.isAllowed(encryptedAmount, msg.sender),
            ERC7984UnauthorizedUseOfEncryptedAmount(encryptedAmount, msg.sender)
        );
        return __setConfidentialFrozen(account, encryptedAmount);
    }

    /// @dev Internal function to set the frozen token amount for an account.
    function _setConfidentialFrozen(
        address account,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) internal virtual returns (euint64) {
        return __setConfidentialFrozen(account, FHE.fromExternal(encryptedAmount, inputProof));
    }

    function __setConfidentialFrozen(address account, euint64 encryptedAmount) internal virtual returns (euint64) {
        _frozenBalances[account] = encryptedAmount;
        emit Frozen(account, encryptedAmount);
    }

    /**
     * @dev See {ERC7984-_update}.
     *
     * Requirements:
     *
     * * `from` must have sufficient unfrozen balance.
     */
    function _update(
        address from,
        address to,
        euint64 encryptedAmount
    ) internal virtual override returns (euint64 transferred) {
        if (from != address(0)) {
            euint64 unfrozen = confidentialAvailable(from);
            encryptedAmount = FHE.select(FHE.le(encryptedAmount, unfrozen), encryptedAmount, euint64.wrap(0));
        }
        return super._update(from, to, encryptedAmount);
    }

    // We don't check frozen balance for approvals since the actual transfer
    // will be checked in _update. This allows for more flexible approval patterns.
}
