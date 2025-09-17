// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {SepoliaConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
import {ERC7984Rwa} from "../../token/ERC7984/extensions/ERC7984Rwa.sol";
import {ERC7984RwaCompliance} from "../../token/ERC7984/extensions/rwa/ERC7984RwaCompliance.sol";

contract ERC7984RwaModularComplianceMock is ERC7984RwaCompliance, SepoliaConfig {
    constructor(string memory name, string memory symbol, string memory tokenUri) ERC7984Rwa(name, symbol, tokenUri) {}
}
