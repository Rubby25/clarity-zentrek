import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Test session creation - owner only",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        // Create session as owner
        let block = chain.mineBlock([
            Tx.contractCall('zentrek', 'create-session', 
                [types.ascii("Morning Meditation"), types.uint(300), types.uint(10)], 
                deployer.address)
        ]);
        
        assertEquals(block.receipts.length, 1);
        block.receipts[0].result.expectOk().expectUint(1);
        
        // Try creating session as non-owner
        block = chain.mineBlock([
            Tx.contractCall('zentrek', 'create-session',
                [types.ascii("Evening Meditation"), types.uint(300), types.uint(10)],
                wallet1.address)
        ]);
        
        block.receipts[0].result.expectErr().expectUint(100);
    }
});

Clarinet.test({
    name: "Test session flow - start and complete",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        // Create session
        let block = chain.mineBlock([
            Tx.contractCall('zentrek', 'create-session',
                [types.ascii("Morning Meditation"), types.uint(300), types.uint(10)],
                deployer.address)
        ]);
        
        // Start session
        block = chain.mineBlock([
            Tx.contractCall('zentrek', 'start-session',
                [types.uint(1)],
                wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
        
        // Complete session
        block = chain.mineBlock([
            Tx.contractCall('zentrek', 'complete-session',
                [types.uint(1)],
                wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
        
        // Check stats
        const response = chain.callReadOnlyFn('zentrek', 'get-user-stats',
            [types.principal(wallet1.address)],
            wallet1.address
        );
        
        response.result.expectOk().expectSome();
    }
});
