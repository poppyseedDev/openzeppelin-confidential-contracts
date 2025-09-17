# Getting started with OpenZepplin's confidential SC library

Prerequisites:

- Node.js >= 20
- Hardhat ^2.24
- Access to an FHEVM-enabled network and the Zama gateway/relayer

## Project Setup

First, you need to install a new project by cloning [Zama's Hardhat template](https://github.com/zama-ai/fhevm-hardhat-template) repository:

```bash
git clone https://github.com/zama-ai/fhevm-hardhat-template conf-token
cd conf-token
```

Install dependencies:
```bash
npm ci
```

Install OpenZeppelin's smart contract library:
```bash
npm i @openzeppelin/confidential-contracts
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