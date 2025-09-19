// Test helpers for ERC7579 functionality
// TypeScript implementations of the Solidity functions

export interface Execution {
  target: string;
  value: bigint;
  callData: string;
}

export interface ModeParams {
  callType: string;
}

// Constants
export const CALL_TYPE_BATCH = '0x01';

// Simple implementation of encodeMode
export function encodeMode(params: ModeParams): string {
  // This is a simplified implementation for testing
  // In the actual Solidity code, this would be more complex
  return '0x' + params.callType.padStart(64, '0');
}

// Simple implementation of encodeBatch
export function encodeBatch(executions: Execution | Execution[]): string {
  // This is a simplified implementation for testing
  // In the actual Solidity code, this would use abi.encode
  const execArray = Array.isArray(executions) ? executions : [executions];
  const encoded = execArray.map(exec => {
    const target = typeof exec.target === 'string' ? exec.target : exec.target.target || exec.target.address;
    const callData = exec.callData || '0x';
    return target.slice(2).padStart(64, '0') + 
           exec.value.toString(16).padStart(64, '0') + 
           callData.slice(2);
  }).join('');
  return '0x' + encoded;
}
