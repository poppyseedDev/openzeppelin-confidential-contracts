// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {VestingWalletCliffConfidential} from "./VestingWalletCliffConfidential.sol";
import {VestingWalletConfidential} from "./VestingWalletConfidential.sol";

// TODO: Rename to `VestingWalletCliffConfidentialUpgradeable`
contract VestingWalletCliffConfidentialInitializable is Initializable, VestingWalletCliffConfidential {
    constructor() VestingWalletCliffConfidential(0) VestingWalletConfidential(address(0), address(1), 0, 0) {}

    function initialize(
        address executor_,
        address beneficiary,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffSeconds
    ) public virtual initializer {
        require(beneficiary != address(0), Ownable.OwnableInvalidOwner(address(0)));
        _transferOwnership(beneficiary);
        __VestingWalletConfidential_init_unchained(executor_, startTimestamp, durationSeconds);
        __VestingWalletCliffConfidential_init_unchained(cliffSeconds);
    }
}
