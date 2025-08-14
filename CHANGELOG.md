# openzeppelin-confidential-contracts


## 0.2.0 (2025-08-14)

- `ConfidentialFungibleToken`: Change the default decimals from 9 to 6. ([#74](https://github.com/OpenZeppelin/openzeppelin-confidential-contracts/pull/74))
- `VestingWalletConfidential`: A vesting wallet that releases confidential tokens owned by it according to a defined vesting schedule. ([#145](https://github.com/OpenZeppelin/openzeppelin-confidential-contracts/pull/145))
  `VestingWalletCliffConfidential`: A variant of `VestingWalletConfidential` which adds a cliff period to the vesting schedule.
  `VestingWalletExecutorConfidential`: A variant of `VestingWalletConfidential` which allows a trusted executor to execute arbitrary calls from the vesting wallet.

- `ConfidentialFungibleTokenVotes`: Add an extension of `ConfidentialFungibleToken` that implements `VotesConfidential`.
- `HandleAccessManager`: Minimal contract that adds a function to give allowance to callers for a given ciphertext handle. ([#145](https://github.com/OpenZeppelin/openzeppelin-confidential-contracts/pull/145))
- `CheckpointsConfidential`: Add a library for handling checkpoints with confidential value types. ([#77](https://github.com/OpenZeppelin/openzeppelin-confidential-contracts/pull/77))
- `IConfidentialFungibleToken`: Prefix `totalSupply` and `balanceOf` functions with confidential. ([#145](https://github.com/OpenZeppelin/openzeppelin-confidential-contracts/pull/145))
- `VestingWalletCliffExecutorConfidentialFactory`: Renamed to `VestingWalletConfidentialFactory` and default implementation removed in favor of a user-defined vesting wallet implementation. ([#145](https://github.com/OpenZeppelin/openzeppelin-confidential-contracts/pull/145))
- `ERC7821WithExecutor`: Add an abstract contract that inherits from `ERC7821` and adds an `executor` role. ([#145](https://github.com/OpenZeppelin/openzeppelin-confidential-contracts/pull/145))
- Upgrade all contracts to use `@fhevm/solidity` 0.7.0. ([#77](https://github.com/OpenZeppelin/openzeppelin-confidential-contracts/pull/77))
- `VotesConfidential`: Add votes governance utility for keeping track of FHE vote delegations.
- `ConfidentialFungibleTokenERC20Wrapper`: Add an internal function to allow overriding the maximum decimals value. ([#145](https://github.com/OpenZeppelin/openzeppelin-confidential-contracts/pull/145))
- `VestingWalletCliffExecutorConfidentialFactory`: Fund multiple `VestingWalletCliffExecutorConfidential` in batch. ([#145](https://github.com/OpenZeppelin/openzeppelin-confidential-contracts/pull/145))

## 0.2.0-rc.0 (2025-07-04)

- Upgrade all contracts to use `@fhevm/solidity` 0.7.0. ([#27](https://github.com/OpenZeppelin/openzeppelin-confidential-contracts/pull/27))
- `ConfidentialFungibleToken`: Change the default decimals from 9 to 6. ([#74](https://github.com/OpenZeppelin/openzeppelin-confidential-contracts/pull/74))
- `ConfidentialFungibleTokenVotes`: Add an extension of `ConfidentialFungibleToken` that implements `VotesConfidential`. ([#40](https://github.com/OpenZeppelin/openzeppelin-confidential-contracts/pull/40))
- `VotesConfidential`: Add votes governance utility for keeping track of FHE vote delegations. ([#40](https://github.com/OpenZeppelin/openzeppelin-confidential-contracts/pull/40))
- `CheckpointsConfidential`: Add a library for handling checkpoints with confidential value types. ([#60](https://github.com/OpenZeppelin/openzeppelin-confidential-contracts/pull/60))
