// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {FHE, externalEuint64, euint64} from "@fhevm/solidity/lib/FHE.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC7984RwaComplianceModule, IERC7984RwaIdentityComplianceModule, IERC7984RwaTransferComplianceModule} from "./../../../interfaces/IERC7984Rwa.sol";
import {ERC7984Rwa} from "./ERC7984Rwa.sol";

/**
 * @dev Extension of {ERC7984Rwa} that supports compliance modules for confidential Real World Assets (RWAs).
 * Inspired by ERC-7579 modules.
 */
abstract contract ERC7984RwaCompliance is ERC7984Rwa {
    using EnumerableSet for *;

    uint256 constant IDENTITY_COMPLIANCE_MODULE_TYPE = 1;
    uint256 constant TRANSFER_COMPLIANCE_MODULE_TYPE = 2;
    EnumerableSet.AddressSet private _identityComplianceModules;
    EnumerableSet.AddressSet private _transferComplianceModules;

    /// @dev Emitted when a module is installed.
    event ModuleInstalled(uint256 moduleTypeId, address module);
    /// @dev Emitted when a module is uninstalled.
    event ModuleUninstalled(uint256 moduleTypeId, address module);

    /// @dev The module type is not supported.
    error ERC7984RwaUnsupportedModuleType(uint256 moduleTypeId);
    /// @dev The provided module doesn't match the provided module type.
    error ERC7984RwaMismatchedModuleTypeId(uint256 moduleTypeId, address module);
    /// @dev The module is already installed.
    error ERC7984RwaAlreadyInstalledModule(uint256 moduleTypeId, address module);

    /**
     * @dev Check if a certain module typeId is supported.
     *
     * Supported module types:
     *
     * * Identity compliance moduleÒ
     * * Transfer compliance module
     */
    function supportsModule(uint256 moduleTypeId) public view virtual returns (bool) {
        return moduleTypeId == IDENTITY_COMPLIANCE_MODULE_TYPE || moduleTypeId == TRANSFER_COMPLIANCE_MODULE_TYPE;
    }

    function installModule(uint256 moduleTypeId, address module) public virtual onlyAdminOrAgent {
        _installModule(moduleTypeId, module);
    }

    function _installModule(uint256 moduleTypeId, address module) internal virtual {
        require(supportsModule(moduleTypeId), ERC7984RwaUnsupportedModuleType(moduleTypeId));
        require(
            IERC7984RwaComplianceModule(module).isModuleType(moduleTypeId),
            ERC7984RwaMismatchedModuleTypeId(moduleTypeId, module)
        );

        if (moduleTypeId == IDENTITY_COMPLIANCE_MODULE_TYPE) {
            require(_identityComplianceModules.add(module), ERC7984RwaAlreadyInstalledModule(moduleTypeId, module));
        } else if (moduleTypeId == TRANSFER_COMPLIANCE_MODULE_TYPE) {
            require(_transferComplianceModules.add(module), ERC7984RwaAlreadyInstalledModule(moduleTypeId, module));
        }
        emit ModuleInstalled(moduleTypeId, module);
    }

    /// @dev Checks if an identity is authorized.
    function _isAuthorizedIdentity(address identity) internal virtual returns (bool) {
        address[] memory modules = _identityComplianceModules.values();
        uint256 modulesLength = modules.length;
        for (uint256 index = 0; index < modulesLength; index++) {
            address module = modules[index];
            if (!IERC7984RwaIdentityComplianceModule(module).isAuthorizedIdentity(identity)) {
                return false;
            }
        }
        return true;
    }

    /// @dev Checks if a transfer is authorized.
    function _isAuthorizedTransfer(address from, address to, euint64 encryptedAmount) internal virtual returns (bool) {
        address[] memory modules = _transferComplianceModules.values();
        uint256 modulesLength = modules.length;
        for (uint256 index = 0; index < modulesLength; index++) {
            address module = modules[index];
            if (!IERC7984RwaTransferComplianceModule(module).isAuthorizedTransfer(from, to, encryptedAmount)) {
                return false;
            }
        }
        return true;
    }

    /// @dev Checks if a transfer follows token compliance.
    function _isCompliant(address from, address to, euint64 encryptedAmount) internal override returns (bool) {
        return
            _isAuthorizedIdentity(from) &&
            _isAuthorizedIdentity(to) &&
            _isAuthorizedTransfer(from, to, encryptedAmount);
    }
}
