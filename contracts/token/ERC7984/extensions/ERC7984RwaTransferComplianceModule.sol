// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {euint64} from "@fhevm/solidity/lib/FHE.sol";
import {IERC7984RwaTransferComplianceModule, TRANSFER_COMPLIANCE_MODULE_TYPE} from "./../../../interfaces/IERC7984Rwa.sol";

/**
 * @dev A contract which allows to build a transfer compliance module for confidential Real World Assets (RWAs).
 */
abstract contract ERC7984RwaTransferComplianceModule is IERC7984RwaTransferComplianceModule {
    /// @inheritdoc IERC7984RwaTransferComplianceModule
    function isModule() public pure override returns (bytes4) {
        return this.isModule.selector;
    }

    /// @inheritdoc IERC7984RwaTransferComplianceModule
    function isCompliantTransfer(address from, address to, euint64 encryptedAmount) public virtual returns (bool) {
        return _isCompliantTransfer(from, to, encryptedAmount);
    }

    /// @inheritdoc IERC7984RwaTransferComplianceModule
    function postTransferHook(address from, address to, euint64 encryptedAmount) public virtual {
        _postTransferHook(from, to, encryptedAmount);
    }

    /// @dev Internal function which checks if a transfer is compliant.
    function _isCompliantTransfer(
        address /*from*/,
        address /*to*/,
        euint64 /*encryptedAmount*/
    ) internal virtual returns (bool) {
        // default to non-compliant
        return false;
    }

    /// @dev Internal function which peforms operation after transfer.
    function _postTransferHook(address /*from*/, address /*to*/, euint64 /*encryptedAmount*/) internal virtual {
        // default to no-op
    }
}
