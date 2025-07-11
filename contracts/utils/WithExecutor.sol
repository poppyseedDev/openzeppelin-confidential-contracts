// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC7821} from "@openzeppelin/contracts/account/extensions/draft-ERC7821.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

contract WithExecutor is Initializable, ERC7821 {
    using StorageSlot for bytes32;

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.WithExecutorStorage")) - 1)) & ~bytes32(uint256(0xff))
    // solhint-disable-next-line const-name-snakecase
    bytes32 private constant WithExecutorStorageLocation =
        0x910826701c864fb4af1a2cf826d3d6a3530f7bd20f3401da49228a1817886b00;

    // solhint-disable-next-line func-name-mixedcase
    function __WithExecutor_init(address executor_) internal onlyInitializing {
        WithExecutorStorageLocation.getAddressSlot().value = executor_;
    }

    /// @dev Trusted address that is able to execute arbitrary calls from the vesting wallet via {call}.
    function executor() public view virtual returns (address) {
        return WithExecutorStorageLocation.getAddressSlot().value;
    }

    function _erc7821AuthorizedExecutor(
        address caller,
        bytes32 mode,
        bytes calldata executionData
    ) internal view virtual override returns (bool) {
        return caller == executor() || super._erc7821AuthorizedExecutor(caller, mode, executionData);
    }
}
