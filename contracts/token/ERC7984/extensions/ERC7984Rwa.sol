// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {FHE, euint64, ebool, externalEuint64} from "@fhevm/solidity/lib/FHE.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {TransientSlot} from "@openzeppelin/contracts/utils/TransientSlot.sol";
import {VotesConfidential} from "../../../governance/utils/VotesConfidential.sol";
import {ERC7984} from "./../ERC7984.sol";
import {ERC7984Restricted} from "./ERC7984Restricted.sol";
import {ERC7984Freezable} from "./ERC7984Freezable.sol";

/// @dev Extension of {ERC7984} that implements compliance for RWAs. Based on ERC3643.
abstract contract ERC7984Rwa is ERC7984, ERC7984Restricted, ERC7984Freezable, Pausable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using TransientSlot for TransientSlot.BooleanSlot;
    EnumerableSet.AddressSet private _complianceModules_;
    EnumerableSet.AddressSet private _forceTransferComplianceModules_;

    TransientSlot.BooleanSlot private _skipRwaRestrictionsFlag =
        TransientSlot.asBoolean(keccak256(abi.encode("skipRwaRestrictions")));

    function confidentialBurn(address from, euint64 amount) public virtual returns (euint64) {
        return _burn(from, amount);
    }

    function confidentialMint(address to, euint64 amount) public virtual returns (euint64) {
        return _mint(to, amount);
    }

    function confidentialForceTransfer(address from, address to, euint64 value) public virtual returns (euint64) {
        _skipRwaRestrictionsFlag.tstore(true);

        euint64 transferred = _update(from, to, value);

        _skipRwaRestrictionsFlag.tstore(false);

        return transferred;
    }

    function _update(
        address from,
        address to,
        euint64 value
    ) internal virtual override(ERC7984, ERC7984Restricted, ERC7984Freezable) returns (euint64) {
        ebool compliancePassed = FHE.asEbool(true);

        uint256 complianceModulesCount = _complianceModules().length();
        if (!_skipRwaRestrictionsFlag.tload()) {
            for (uint256 i = 0; i < complianceModulesCount; i++) {
                address complianceModule = _complianceModules().at(i);
                // Call the compliance module
                ebool res = FHE.asEbool(true);
                compliancePassed = FHE.and(compliancePassed, res);
            }
        }

        uint256 forceTransferComplianceModulesCount = _forceTransferComplianceModules().length();
        for (uint256 i = 0; i < forceTransferComplianceModulesCount; i++) {
            address complianceModule = _forceTransferComplianceModules().at(i);
            // Call the compliance module
            ebool res = FHE.asEbool(true);
            compliancePassed = FHE.and(compliancePassed, res);
        }

        value = FHE.select(compliancePassed, value, FHE.asEuint64(0));

        euint64 transferred = super._update(from, to, value);

        // Iterate again to allow for post-transfer side effects
        for (uint256 i = 0; i < complianceModulesCount; i++) {
            address complianceModule = _complianceModules().at(i);
            // Call the compliance module
        }

        for (uint256 i = 0; i < forceTransferComplianceModulesCount; i++) {
            address complianceModule = _forceTransferComplianceModules().at(i);
            // Call the compliance module
        }

        return transferred;
    }

    function _complianceModules() internal view virtual returns (EnumerableSet.AddressSet storage) {
        return _complianceModules_;
    }

    function _forceTransferComplianceModules() internal view virtual returns (EnumerableSet.AddressSet storage) {
        return _forceTransferComplianceModules_;
    }

    function complianceModules() public view virtual returns (address[] memory) {
        return _complianceModules().values();
    }

    function confidentialTransfer(
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) public virtual override whenNotPaused returns (euint64) {
        return super.confidentialTransfer(to, encryptedAmount, inputProof);
    }

    function confidentialTransfer(address to, euint64 amount) public virtual override whenNotPaused returns (euint64) {
        return super.confidentialTransfer(to, amount);
    }

    function confidentialTransferFrom(
        address from,
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) public virtual override whenNotPaused returns (euint64) {
        return super.confidentialTransferFrom(from, to, encryptedAmount, inputProof);
    }

    function confidentialTransferFrom(
        address from,
        address to,
        euint64 amount
    ) public virtual override whenNotPaused returns (euint64) {
        return super.confidentialTransferFrom(from, to, amount);
    }

    function confidentialTransferAndCall(
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof,
        bytes calldata data
    ) public virtual override whenNotPaused returns (euint64) {
        return super.confidentialTransferAndCall(to, encryptedAmount, inputProof, data);
    }

    function confidentialTransferAndCall(
        address to,
        euint64 amount,
        bytes calldata data
    ) public virtual override whenNotPaused returns (euint64) {
        return super.confidentialTransferAndCall(to, amount, data);
    }

    function confidentialTransferFromAndCall(
        address from,
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof,
        bytes calldata data
    ) public virtual override whenNotPaused returns (euint64) {
        return super.confidentialTransferFromAndCall(from, to, encryptedAmount, inputProof, data);
    }

    function confidentialTransferFromAndCall(
        address from,
        address to,
        euint64 amount,
        bytes calldata data
    ) public virtual override whenNotPaused returns (euint64) {
        return super.confidentialTransferFromAndCall(from, to, amount, data);
    }
}
