# Vesting Wallet (Confidential)

`VestingWalletConfidential` receives `ERC7984` tokens and releases them to the beneficiary according to a confidential, linear vesting schedule.

Highlights:

- Ownable and upgradeable pattern
- Tracks released amounts per token as `euint128`
- `releasable(token)` returns encrypted amount vested so far
- `release(token)` transfers vested amount to owner and updates released total
- Designed to be deployed as clones via `VestingWalletConfidentialFactory`

## Using the Wallet

Initialization (called in your implementation):

```solidity
function __VestingWalletConfidential_init(
  address beneficiary,
  uint48 startTimestamp,
  uint48 durationSeconds
) internal onlyInitializing;
```

Vesting math:

- Linear schedule by default: vested from `start` to `end = start + duration`
- Override `_vestingSchedule(euint128 totalAllocation, uint48 timestamp)` for custom curves

Release flow:

```solidity
function release(address token) public {
  euint64 amount = releasable(token);
  FHE.allowTransient(amount, token);
  euint64 sent = IERC7984(token).confidentialTransfer(owner(), amount);
  // Update released total (encrypted) and emit event
}
```

## Factory for Batch Funding

`VestingWalletConfidentialFactory` lets you fund multiple wallets in batch and deploy clones deterministically.

Key pieces:

- `struct VestingPlan { externalEuint64 encryptedAmount; bytes initArgs; }`
- `batchFundVestingWalletConfidential(address token, VestingPlan[] plans, bytes inputProof)`
- `createVestingWalletConfidential(bytes initArgs)` and `predictVestingWalletConfidential(bytes initArgs)`

You must implement:

- `_deployVestingWalletImplementation()` once (returns implementation address)
- `_initializeVestingWallet(address wallet, bytes calldata initArgs)` to decode and initialize clones
- `_validateVestingWalletInitArgs(bytes memory initArgs)` to sanity check init args

Typical `initArgs` can be ABI-encoded `(beneficiary, start, duration)`.

### Example init args

```solidity
bytes memory initArgs = abi.encode(beneficiary, uint48(start), uint48(duration));
```

Then in your factory implementation:

```solidity
function _initializeVestingWallet(address wallet, bytes calldata initArgs) internal override {
  (address beneficiary, uint48 start, uint48 duration) = abi.decode(initArgs, (address, uint48, uint48));
  VestingWalletConfidential(payable(wallet)).__VestingWalletConfidential_init(beneficiary, start, duration);
}
```

Batch fund flow:

- Gateway provides input proof for each `VestingPlan.encryptedAmount`
- Contract transfers confidential amounts to predicted wallet addresses
- You can deploy the clones before or after funding (deterministic address)