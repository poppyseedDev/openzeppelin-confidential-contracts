# Getting Started

This repository provides experimental building blocks for confidential smart contracts on the Zama fhEVM coprocessor. Contracts use homomorphically encrypted types (for example, `euint64`) from `@fhevm/solidity` to keep token amounts and other values confidential onchain.

Prerequisites:

- Node.js >= 20
- Hardhat ^2.24
- Access to an fhEVM-enabled network and the Zama gateway/relayer

Install dependencies:

```bash
npm ci
```

Compile contracts:

```bash
npm run compile
```

Run tests:

```bash
npm test
```

Key packages used:

- `@fhevm/solidity` for FHE types and operations
- `ethers` v6 and Hardhat plugins

Next steps:

- Read the ERC7984 overview to understand the confidential fungible token interface
- Follow the quickstart to deploy a token and perform confidential transfers
- Explore extensions and tutorials for common patterns

> Important: This code is experimental and unaudited. Use at your own risk.