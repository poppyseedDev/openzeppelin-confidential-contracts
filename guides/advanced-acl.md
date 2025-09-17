# Advanced: FHE ACL and Input Proofs

Many functions in this repo accept `externalEuint64` (and related types) plus an `inputProof`. Others accept encrypted types (`euint64`) directly and require that the caller already has ACL access to those values.

Key concepts:

- `FHE.fromExternal(externalEuint64, inputProof)`: Converts an external ciphertext to an encrypted handle, validating the input proof via the fhEVM gateway
- `FHE.isAllowed(handle, account)`: Checks whether `account` can use `handle`
- `FHE.allow(handle, account)`, `FHE.allowTransient(handle, account)`: Grants persistent or transient access to a handle
- `FHE.requestDecryption(handles, callbackSelector)`: Initiates asynchronous decryption, later completed via a finalize function
- `FHE.checkSignatures(requestId, signatures)`: Verifies the gateway signatures on decryption results

Patterns:

- Function variants: many APIs have both `externalEuint64 + inputProof` and `euint64` variants
- Use `allowTransient` for one-off internal flows (e.g., passing amount to token contract)
- When moving values across contracts, ensure appropriate `allow` calls are made for each recipient

Examples in repo:

- `ERC7984.confidentialTransfer` and `confidentialTransferFrom` function pairs
- `ERC7984.discloseEncryptedAmount` + `finalizeDiscloseEncryptedAmount`
- `ERC7984ERC20Wrapper.unwrap` + `finalizeUnwrap`
- `SwapConfidentialToERC20` using `requestDecryption`/`finalizeSwap`

Troubleshooting:

- Unauthorized use errors typically indicate missing ACL allowance or missing/invalid input proofs
- Ensure the correct contract addresses are allowed when values are passed between contracts