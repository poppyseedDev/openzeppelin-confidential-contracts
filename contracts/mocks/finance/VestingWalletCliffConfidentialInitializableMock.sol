// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ZamaConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
import {FHE} from "@fhevm/solidity/lib/FHE.sol";
import {VestingWalletCliffConfidentialInitializable} from "./../../finance/VestingWalletCliffConfidentialInitializable.sol";

abstract contract VestingWalletCliffConfidentialInitializableMock is VestingWalletCliffConfidentialInitializable {
    function initialize(
        address executor_,
        address beneficiary,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffSeconds
    ) public override {
        super.initialize(executor_, beneficiary, startTimestamp, durationSeconds, cliffSeconds);

        FHE.setCoprocessor(ZamaConfig.getSepoliaConfig());
        FHE.setDecryptionOracle(ZamaConfig.getSepoliaOracleAddress());
    }
}
