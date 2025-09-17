// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {FHE, ebool, euint64, externalEuint64} from "@fhevm/solidity/lib/FHE.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC7984} from "../../../../interfaces/IERC7984.sol";
import {FHESafeMath} from "../../../../utils/FHESafeMath.sol";
import {ERC7984RwaComplianceModule} from "./ERC7984RwaComplianceModule.sol";

/**
 * @dev A transfer compliance module for confidential Real World Assets (RWAs) which limits the balance of an investor.
 */
abstract contract ERC7984RwaBalanceCapModule is ERC7984RwaComplianceModule {
    using EnumerableSet for *;

    euint64 private _maxBalance;

    constructor(address token) ERC7984RwaComplianceModule(token) {
        _token = token;
    }

    /// @dev Sets max balance of an investor with proof.
    function setMaxBalance(externalEuint64 maxBalance, bytes calldata inputProof) public virtual onlyTokenAdmin {
        FHE.allowThis(_maxBalance = FHE.fromExternal(maxBalance, inputProof));
    }

    /// @dev Sets max balance of an investor.
    function setMaxBalance(euint64 maxBalance) public virtual onlyTokenAdmin {
        FHE.allowThis(_maxBalance = maxBalance);
    }

    /// @dev Gets max balance of an investor.
    function getMaxBalance() public virtual returns (euint64) {
        return _maxBalance;
    }

    /// @dev Internal function which checks if a transfer is compliant.
    function _isCompliantTransfer(
        address /*from*/,
        address to,
        euint64 encryptedAmount
    ) internal override returns (ebool compliant) {
        if (!FHE.isInitialized(encryptedAmount) || to == address(0)) {
            // if no amount or burning
            return FHE.asEbool(true);
        }
        euint64 balance = IERC7984(_token).confidentialBalanceOf(to);
        _getTokenHandleAllowance(balance);
        _getTokenHandleAllowance(encryptedAmount);
        (ebool increased, euint64 futureBalance) = FHESafeMath.tryIncrease(balance, encryptedAmount);
        compliant = FHE.and(increased, FHE.le(futureBalance, _maxBalance));
    }
}
