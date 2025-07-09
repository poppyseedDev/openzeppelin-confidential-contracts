// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {euint64} from "@fhevm/solidity/lib/FHE.sol";
import {VestingWalletConfidential} from "./VestingWalletConfidential.sol";

/**
 * @dev An extension of {VestingWalletConfidential} that adds a cliff to the vesting schedule. The cliff is `cliffSeconds` long and
 * starts at the vesting start timestamp (see {VestingWalletConfidential}).
 */
abstract contract VestingWalletCliffConfidential is VestingWalletConfidential {
    uint64 private _cliff;

    /// @dev The specified cliff duration is larger than the vesting duration.
    error InvalidCliffDuration(uint64 cliffSeconds, uint64 durationSeconds);

    // solhint-disable-next-line func-name-mixedcase
    function __VestingWalletCliffConfidential_init(uint64 cliffSeconds) internal onlyInitializing {
        if (cliffSeconds > duration()) {
            revert InvalidCliffDuration(cliffSeconds, duration());
        }
        _cliff = start() + cliffSeconds;
    }

    /**
     * @dev Getter for the cliff timestamp.
     */
    function cliff() public view virtual returns (uint64) {
        return _cliff;
    }

    /**
     * @dev Virtual implementation of the vesting formula. This returns the amount vested, as a function of time, for
     * an asset given its total historical allocation. Returns 0 if the {cliff} timestamp is not met.
     *
     * IMPORTANT: The cliff not only makes the schedule return 0, but it also ignores every possible side
     * effect from calling the inherited implementation (i.e. `super._vestingSchedule`). Carefully consider
     * this caveat if the overridden implementation of this function has any (e.g. writing to memory or reverting).
     */
    function _vestingSchedule(euint64 totalAllocation, uint64 timestamp) internal virtual override returns (euint64) {
        return timestamp < cliff() ? euint64.wrap(0) : super._vestingSchedule(totalAllocation, timestamp);
    }
}
