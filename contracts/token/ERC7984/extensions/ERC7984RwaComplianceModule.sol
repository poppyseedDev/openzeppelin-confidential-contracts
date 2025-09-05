// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {IERC7984RwaComplianceModule} from "./../../../interfaces/IERC7984Rwa.sol";

/**
 * @dev A contract which allows to build a compliance module for confidential Real World Assets (RWAs).
 */
abstract contract ERC7984RwaComplianceModule is IERC7984RwaComplianceModule {}
