// EIP712 test helpers
// Simple implementations for testing purposes

export interface Delegation {
  delegatee: string;
  nonce: bigint;
  expiry: bigint;
}

export async function getDomain(contract: any, name: string = 'TestToken', version: string = '1') {
  // Simple implementation for testing
  // In a real implementation, this would use the EIP712 domain separator
  return {
    name,
    version,
    chainId: 1, // Default chain ID for testing
    verifyingContract: contract.target || contract.address,
    types: {
      Delegation: [
        { name: 'delegatee', type: 'address' },
        { name: 'nonce', type: 'uint256' },
        { name: 'expiry', type: 'uint256' }
      ]
    }
  };
}
