# Extensions

This repository includes several `ERC7984` extensions for common patterns.

## Freezable (`ERC7984Freezable`)

- Track a confidential frozen balance per account via `confidentialFrozen(address)`
- `confidentialAvailable(address)` returns encrypted available balance (balance minus frozen)
- Internal `_setConfidentialFrozen(address, euint64)` to update frozen amounts
- Override `_checkFreezer()` to restrict who can freeze/unfreeze
- Transfer updates respect frozen amounts by overriding `_update`

Use case: DAO/multisig can freeze a confidential amount during investigations or to implement vesting-like holds.

## Restricted (`ERC7984Restricted`)

- Model user restrictions via `Restriction` enum: `DEFAULT`, `BLOCKED`, `ALLOWED`
- `isUserAllowed(address)` returns whether an account can send/receive
- Override to implement an allowlist instead of blocklist
- Internal helpers `_blockUser`, `_allowUser`, `_resetUser`
- Transfers enforce restrictions in `_update`

Use case: compliance or phased rollouts.

## Votes (`ERC7984Votes`)

- Integrates with `VotesConfidential` to track voting units equal to encrypted balance
- Delegation flows mirror standard OZ Votes, but using encrypted units
- Overrides `_update` to move voting units when balances change

Use case: confidential governance where balances map to voting power.

## Omnibus (`ERC7984Omnibus`)

- Adds events that carry encrypted sub-account sender/recipient (`eaddress`)
- Helpers to perform omnibus transfers and emit `OmnibusConfidentialTransfer`
- Integrators keep offchain accounting for sub-accounts; onchain settlement remains standard

Use case: exchanges/custodians with omnibus wallets while preserving confidentiality of sub-accounts.

## ERC20 Wrapper (`ERC7984ERC20Wrapper`)

- Wrap a standard `ERC20` into an `ERC7984` with a conversion `rate()` and adjusted `decimals()`
- `onTransferReceived` supports `ERC1363` flows to auto-wrap on receipt
- `wrap(to, amount)` and `unwrap(from, to, euint64)` with asynchronous decryption via `finalizeUnwrap`
- Not suitable for non-standard tokens (fee-on-transfer, rebasing without care)

Use case: onboarding ERC20 liquidity into confidential tokens.