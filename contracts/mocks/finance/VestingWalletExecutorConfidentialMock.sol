// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SepoliaConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
import {VestingWalletConfidential} from "../../finance/VestingWalletConfidential.sol";
import {WithExecutor} from "../../utils/WithExecutor.sol";

abstract contract VestingWalletExecutorConfidentialMock is VestingWalletConfidential, WithExecutor, SepoliaConfig {}
