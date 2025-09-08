// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {FHE, externalEuint64, euint64} from "@fhevm/solidity/lib/FHE.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC7984RwaCompliance, IERC7984RwaTransferComplianceModule, FORCE_TRANSFER_COMPLIANCE_MODULE_TYPE, TRANSFER_COMPLIANCE_MODULE_TYPE} from "./../../../interfaces/IERC7984Rwa.sol";
import {ERC7984Rwa} from "./ERC7984Rwa.sol";

/**
 * @dev Extension of {ERC7984Rwa} that supports compliance modules for confidential Real World Assets (RWAs).
 * Inspired by ERC-7579 modules.
 */
abstract contract ERC7984RwaCompliance is ERC7984Rwa, IERC7984RwaCompliance {
    using EnumerableSet for *;

    EnumerableSet.AddressSet private _transferComplianceModules;
    EnumerableSet.AddressSet private _forceTransferComplianceModules;

    /// @dev Emitted when a module is installed.
    event ModuleInstalled(uint256 moduleTypeId, address module);
    /// @dev Emitted when a module is uninstalled.
    event ModuleUninstalled(uint256 moduleTypeId, address module);

    /// @dev The module type is not supported.
    error ERC7984RwaUnsupportedModuleType(uint256 moduleTypeId);
    /// @dev The address is not a transfer compliance module.
    error ERC7984RwaNotTransferComplianceModule(address module);
    /// @dev The module is already installed.
    error ERC7984RwaAlreadyInstalledModule(uint256 moduleTypeId, address module);
    /// @dev The module is already uninstalled.
    error ERC7984RwaAlreadyUninstalledModule(uint256 moduleTypeId, address module);

    /**
     * @dev Check if a certain module typeId is supported.
     *
     * Supported module types:
     *
     * * Transfer compliance module
     * * Force transfer compliance module
     */
    function supportsModule(uint256 moduleTypeId) public view virtual returns (bool) {
        return moduleTypeId == TRANSFER_COMPLIANCE_MODULE_TYPE || moduleTypeId == FORCE_TRANSFER_COMPLIANCE_MODULE_TYPE;
    }

    /**
     * @inheritdoc IERC7984RwaCompliance
     * @dev Consider gas footprint of the module before adding it since all modules will perform
     * all steps (pre-check, compliance check, post-hook) in a single transaction.
     */
    function installModule(uint256 moduleTypeId, address module) public virtual onlyAdminOrAgent {
        _installModule(moduleTypeId, module);
    }

    /// @inheritdoc IERC7984RwaCompliance
    function uninstallModule(uint256 moduleTypeId, address module) public virtual onlyAdminOrAgent {
        _uninstallModule(moduleTypeId, module);
    }

    /// @dev Internal function which installs a transfer compliance module.
    function _installModule(uint256 moduleTypeId, address module) internal virtual {
        require(supportsModule(moduleTypeId), ERC7984RwaUnsupportedModuleType(moduleTypeId));
        require(
            IERC7984RwaTransferComplianceModule(module).isModule() ==
                IERC7984RwaTransferComplianceModule.isModule.selector,
            ERC7984RwaNotTransferComplianceModule(module)
        );

        if (moduleTypeId == TRANSFER_COMPLIANCE_MODULE_TYPE) {
            require(_transferComplianceModules.add(module), ERC7984RwaAlreadyInstalledModule(moduleTypeId, module));
        } else if (moduleTypeId == FORCE_TRANSFER_COMPLIANCE_MODULE_TYPE) {
            require(
                _forceTransferComplianceModules.add(module),
                ERC7984RwaAlreadyInstalledModule(moduleTypeId, module)
            );
        }
        emit ModuleInstalled(moduleTypeId, module);
    }

    /// @dev Internal function which uninstalls a transfer compliance module.
    function _uninstallModule(uint256 moduleTypeId, address module) internal virtual {
        require(supportsModule(moduleTypeId), ERC7984RwaUnsupportedModuleType(moduleTypeId));
        if (moduleTypeId == TRANSFER_COMPLIANCE_MODULE_TYPE) {
            require(
                _transferComplianceModules.remove(module),
                ERC7984RwaAlreadyUninstalledModule(moduleTypeId, module)
            );
        } else if (moduleTypeId == FORCE_TRANSFER_COMPLIANCE_MODULE_TYPE) {
            require(
                _forceTransferComplianceModules.remove(module),
                ERC7984RwaAlreadyUninstalledModule(moduleTypeId, module)
            );
        }
        emit ModuleUninstalled(moduleTypeId, module);
    }

    /// @dev Checks if a transfer is compliant.
    function _isTransferCompliantTransfer(
        address from,
        address to,
        euint64 encryptedAmount
    ) internal virtual returns (bool) {
        address[] memory modules = _transferComplianceModules.values();
        uint256 modulesLength = modules.length;
        for (uint256 i = 0; i < modulesLength; i++) {
            if (!IERC7984RwaTransferComplianceModule(modules[i]).isCompliantTransfer(from, to, encryptedAmount)) {
                return false;
            }
        }
        return true;
    }

    /// @dev Checks if a force transfer is compliant.
    function _isTransferCompliantForceTransfer(
        address from,
        address to,
        euint64 encryptedAmount
    ) internal virtual returns (bool) {
        address[] memory modules = _forceTransferComplianceModules.values();
        uint256 modulesLength = modules.length;
        for (uint256 i = 0; i < modulesLength; i++) {
            if (!IERC7984RwaTransferComplianceModule(modules[i]).isCompliantTransfer(from, to, encryptedAmount)) {
                return false;
            }
        }
        return true;
    }

    /// @dev Peforms operation after transfer.
    function _postTransferHook(address from, address to, euint64 encryptedAmount) internal override {
        address[] memory modules = _transferComplianceModules.values();
        uint256 modulesLength = modules.length;
        for (uint256 i = 0; i < modulesLength; i++) {
            IERC7984RwaTransferComplianceModule(modules[i]).postTransferHook(from, to, encryptedAmount);
        }
    }

    /// @dev Peforms operation after force transfer.
    function _postForceTransferHook(address from, address to, euint64 encryptedAmount) internal override {
        address[] memory modules = _forceTransferComplianceModules.values();
        uint256 modulesLength = modules.length;
        for (uint256 i = 0; i < modulesLength; i++) {
            IERC7984RwaTransferComplianceModule(modules[i]).postTransferHook(from, to, encryptedAmount);
        }
    }
}
