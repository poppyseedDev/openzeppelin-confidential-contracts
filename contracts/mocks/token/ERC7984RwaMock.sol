// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {SepoliaConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
import {FHE, euint64, externalEuint64} from "@fhevm/solidity/lib/FHE.sol";
import {Impl} from "@fhevm/solidity/lib/Impl.sol";
import {ERC7984Rwa} from "../../token/extensions/ERC7984Rwa.sol";

// solhint-disable func-name-mixedcase
contract ERC7984RwaMock is ERC7984Rwa, SepoliaConfig {
    mapping(address account => euint64 encryptedAmount) private _frozenBalances;
    bool public compliantTransfer;

    constructor(string memory name, string memory symbol, string memory tokenUri) ERC7984Rwa(name, symbol, tokenUri) {}

    function $_mint(address to, uint64 amount) public returns (euint64 transferred) {
        return _mint(to, FHE.asEuint64(amount));
    }

    function _isCompliantTransfer(
        address /*from*/,
        address /*to*/,
        euint64 /*encryptedAmount*/
    ) internal override returns (bool) {
        return compliantTransfer;
    }

    // TODO: Remove all below
    function confidentialAvailable(address /*account*/) public override returns (euint64) {
        return FHE.asEuint64(0);
    }
    function confidentialFrozen(address account) public view override returns (euint64) {
        return _frozenBalances[account];
    }
    function setConfidentialFrozen(
        address account,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) public override {}
    function setConfidentialFrozen(address account, euint64 encryptedAmount) public override {}
}
