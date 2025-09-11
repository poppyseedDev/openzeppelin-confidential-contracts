// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {FHE, ebool, externalEuint64, euint64} from "@fhevm/solidity/lib/FHE.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC7984RwaCompliance, IERC7984RwaTransferComplianceModule, TRANSFER_ONLY_MODULE_TYPE, ALWAYS_ON_MODULE_TYPE} from "./../../../../interfaces/IERC7984Rwa.sol";
import {ERC7984Rwa} from "../ERC7984Rwa.sol";

/**
 * @dev Extension of {ERC7984Rwa} that supports compliance modules for confidential Real World Assets (RWAs).
 * Inspired by ERC-7579 modules.
 */
abstract contract ERC7984RwaCompliance is ERC7984Rwa, IERC7984RwaCompliance {
    using EnumerableSet for *;

    EnumerableSet.AddressSet private _alwaysOnModules;
    EnumerableSet.AddressSet private _transferOnlyModules;

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
        return moduleTypeId == ALWAYS_ON_MODULE_TYPE || moduleTypeId == TRANSFER_ONLY_MODULE_TYPE;
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

        if (moduleTypeId == ALWAYS_ON_MODULE_TYPE) {
            require(_alwaysOnModules.add(module), ERC7984RwaAlreadyInstalledModule(moduleTypeId, module));
        } else if (moduleTypeId == TRANSFER_ONLY_MODULE_TYPE) {
            require(_transferOnlyModules.add(module), ERC7984RwaAlreadyInstalledModule(moduleTypeId, module));
        }
        emit ModuleInstalled(moduleTypeId, module);
    }

    /// @dev Internal function which uninstalls a transfer compliance module.
    function _uninstallModule(uint256 moduleTypeId, address module) internal virtual {
        require(supportsModule(moduleTypeId), ERC7984RwaUnsupportedModuleType(moduleTypeId));
        if (moduleTypeId == ALWAYS_ON_MODULE_TYPE) {
            require(_alwaysOnModules.remove(module), ERC7984RwaAlreadyUninstalledModule(moduleTypeId, module));
        } else if (moduleTypeId == TRANSFER_ONLY_MODULE_TYPE) {
            require(_transferOnlyModules.remove(module), ERC7984RwaAlreadyUninstalledModule(moduleTypeId, module));
        }
        emit ModuleUninstalled(moduleTypeId, module);
    }

    /// @dev Checks if a transfer follows compliance.
    function _preCheckTransfer(address from, address to, euint64 encryptedAmount) internal override returns (ebool) {
        return
            FHE.and(_checkAlwaysBefore(from, to, encryptedAmount), _checkOnlyBeforeTransfer(from, to, encryptedAmount));
    }

    /// @dev Checks if a force transfer follows compliance.
    function _preCheckForceTransfer(
        address from,
        address to,
        euint64 encryptedAmount
    ) internal override returns (ebool) {
        return _checkAlwaysBefore(from, to, encryptedAmount);
    }

    /// @dev Peforms operations after transfer.
    function _postTransfer(address from, address to, euint64 encryptedAmount) internal override {
        _runAlwaysAfter(from, to, encryptedAmount);
        _runOnlyAfterTransfer(from, to, encryptedAmount);
    }

    /// @dev Peforms operations after force transfer.
    function _postForceTransfer(address from, address to, euint64 encryptedAmount) internal override {
        _runAlwaysAfter(from, to, encryptedAmount);
    }

    /// @dev Checks always-on compliance.
    function _checkAlwaysBefore(
        address from,
        address to,
        euint64 encryptedAmount
    ) internal virtual returns (ebool compliant) {
        if (!FHE.isInitialized(encryptedAmount)) {
            return FHE.asEbool(true);
        }
        address[] memory modules = _alwaysOnModules.values();
        uint256 modulesLength = modules.length;
        compliant = FHE.asEbool(true);
        for (uint256 i = 0; i < modulesLength; i++) {
            compliant = FHE.and(
                compliant,
                IERC7984RwaTransferComplianceModule(modules[i]).isCompliantTransfer(from, to, encryptedAmount)
            );
        }
    }

    /// @dev Checks transfer-only compliance.
    function _checkOnlyBeforeTransfer(
        address from,
        address to,
        euint64 encryptedAmount
    ) internal virtual returns (ebool compliant) {
        if (!FHE.isInitialized(encryptedAmount)) {
            return FHE.asEbool(true);
        }
        address[] memory modules = _transferOnlyModules.values();
        uint256 modulesLength = modules.length;
        compliant = FHE.asEbool(true);
        for (uint256 i = 0; i < modulesLength; i++) {
            compliant = FHE.and(
                compliant,
                IERC7984RwaTransferComplianceModule(modules[i]).isCompliantTransfer(from, to, encryptedAmount)
            );
        }
    }

    /// @dev Runs always.
    function _runAlwaysAfter(address from, address to, euint64 encryptedAmount) internal virtual {
        address[] memory modules = _alwaysOnModules.values();
        uint256 modulesLength = modules.length;
        for (uint256 i = 0; i < modulesLength; i++) {
            IERC7984RwaTransferComplianceModule(modules[i]).postTransfer(from, to, encryptedAmount);
        }
    }

    /// @dev Runs only after transfer.
    function _runOnlyAfterTransfer(address from, address to, euint64 encryptedAmount) internal virtual {
        address[] memory modules = _transferOnlyModules.values();
        uint256 modulesLength = modules.length;
        for (uint256 i = 0; i < modulesLength; i++) {
            IERC7984RwaTransferComplianceModule(modules[i]).postTransfer(from, to, encryptedAmount);
        }
    }
}
