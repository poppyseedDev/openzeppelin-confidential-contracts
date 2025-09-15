// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {SepoliaConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
import {ERC7984RwaBalanceCapModule} from "../../token/ERC7984/extensions/rwa/ERC7984RwaBalanceCapModule.sol";

contract ERC7984RwaBalanceCapModuleMock is ERC7984RwaBalanceCapModule, SepoliaConfig {
    constructor(address compliance) ERC7984RwaBalanceCapModule(compliance) {}
}
