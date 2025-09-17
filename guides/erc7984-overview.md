# ERC7984 Overview

ERC7984 is a draft interface for confidential fungible tokens powered by the Zama fhEVM. Balances and transfers use encrypted integers (`euint64`) so amounts are not publicly visible onchain.

Core concepts:

- Confidential balances via `confidentialBalanceOf(address)`
- Confidential total supply via `confidentialTotalSupply()`
- Confidential transfers with and without input proofs
- Operators via `setOperator(holder, operator, until)` and `isOperator(holder, spender)`
- Optional transfer-and-call flow via `IERC7984Receiver`

Events:

- `ConfidentialTransfer(address from, address to, euint64 amount)`
- `OperatorSet(address holder, address operator, uint48 until)`
- `AmountDisclosed(euint64 encryptedAmount, uint64 amount)` (optional flow to disclose)

Integration notes:

- Without an input proof, callers must already have ACL access to given encrypted values
- With an input proof, the fhEVM gateway authorizes access dynamically
- When using transfer-and-call, the receiver returns an encrypted boolean (`ebool`) to indicate success

See the Quickstart for deployment and usage examples.