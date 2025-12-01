import { Account, logger, CairoEnum, Contract as StarknetContract, TypedContractV2 } from "starknet";
import { Layer, Contract, TokenStatus } from "./config/types.ts";
import { starknetBridgePackage, tokenBridgeL2Contract } from "./config/constants.ts";
import { ABI as TokenBridgeL2ABI } from "./abis/starknet_bridge_TokenBridge.ts";
import { ABI as ERC20ABI } from "./abis/starknet_bridge_ERC20.ts";
import { getAccount, getContract, sleep } from "./utils/utils.ts";
import assert from "assert";
import { enrollToken, getL3Balance } from "./bridgeDeploy.ts";

/**
 * Utility function to execute a transaction and assert its expected outcome
 * @param account The account to execute the transaction with
 * @param transactionPromise A function that returns a transaction or a promise that resolves to a transaction
 * @param expectedSuccess Whether the transaction is expected to succeed
 * @param errorMessage Custom error message for assertion failure
 * @returns The transaction receipt if successful
 */
async function executeAndAssertTransaction(
    account: Account,
    transactionPromise: () => any,
    expectedSuccess: boolean,
    errorMessage?: string
) {
    try {
        // Execute the transaction
        const tx = await (typeof transactionPromise === 'function' ? transactionPromise() : transactionPromise);
        const receipt = await account.waitForTransaction(tx.transaction_hash);
        
        // Check if the result matches expectations
        if (expectedSuccess) {
            assert(receipt.isSuccess(), `${errorMessage} - Expected success but got failure`);
        } else {
            assert(receipt.isReverted(), `${errorMessage} - Expected failure but got success`);
        }
        
        return receipt;
    } catch (error) {
        // If we're expecting a failure and get an error during execution, that's fine
        if (!expectedSuccess && error.toString().includes(errorMessage)) {
            return null;
        }

        // Re-throw unexpected errors
        throw error;
    }
}

async function tokenAsserts(token: TypedContractV2<typeof ERC20ABI>, tokenBridgeContract: TypedContractV2<typeof TokenBridgeL2ABI>, tokenStatus: TokenStatus) {
    const result = await tokenBridgeContract.get_status(token.address);
    logger.info(`Token status: ${result.activeVariant()}`);
    if (result.activeVariant() != tokenStatus) {
        const errorMsg = `Token status mismatch: ${result.activeVariant} !== ${tokenStatus}`;
        logger.error(errorMsg);
        throw new Error(errorMsg);
    }

    const isServicingToken = await tokenBridgeContract.is_servicing_token(token.address);
    logger.info(`Is servicing token: ${isServicingToken}`);
    if (isServicingToken !== (tokenStatus === TokenStatus.Active)) {
        const errorMsg = `Is servicing token mismatch: ${isServicingToken} !== ${tokenStatus === TokenStatus.Active}`;
        logger.error(errorMsg);
        throw new Error(errorMsg);
    }

    const acc_l2 = getAccount(Layer.L2);
    
    // Approve token spending
    await executeAndAssertTransaction(
        acc_l2,
        () => token.approve(tokenBridgeContract.address, 10),
        true,
        "Token approval failed"
    );
    
    // Try to deposit token
    await executeAndAssertTransaction(
        acc_l2,
        () => tokenBridgeContract.deposit(token.address, 10, acc_l2.address),
        tokenStatus === TokenStatus.Active,
        "Only servicing tokens"
    );
}

export async function testTokenActions(acc_l2: Account, token: string = "ERC20_OZ") {
    const tokenContract: Contract = {
        name: token,
        layer: Layer.L2,
        package: starknetBridgePackage
    };
    getContract(tokenContract);

    if (!tokenContract.address) {
        const errorMsg = `Token contract ${token} address not found`;
        logger.error(errorMsg);
        throw new Error(errorMsg);
    }
    getContract(tokenBridgeL2Contract);

    if (!tokenBridgeL2Contract.address) {
        const errorMsg = "L2 Bridge contract address not found";
        logger.error(errorMsg);
        throw new Error(errorMsg);
    }

    const tokenAddress = tokenContract.address;
    const tokenStarknetContract = new StarknetContract({abi: ERC20ABI, address: tokenAddress, providerOrAccount: acc_l2}).typedv2(ERC20ABI);
    const tokenBridge = tokenBridgeL2Contract.address;

    const tokenBridgeContract = new StarknetContract({abi: TokenBridgeL2ABI, address: tokenBridge, providerOrAccount: acc_l2}).typedv2(TokenBridgeL2ABI);

    // 1. Current status: Unknown
    await tokenAsserts(tokenStarknetContract, tokenBridgeContract, TokenStatus.Unknown);

    // activate_token should fail
    await executeAndAssertTransaction(
        acc_l2,
        () => tokenBridgeContract.reactivate_token(tokenAddress),
        false,
        "Token not deactivated"
    );

    // deactivate_token should fail
    await executeAndAssertTransaction(
        acc_l2,
        () => tokenBridgeContract.deactivate_token(tokenAddress),
        false,
        "Token not active"
    );

    // unblock_token should fail
    await executeAndAssertTransaction(
        acc_l2,
        () => tokenBridgeContract.unblock_token(tokenAddress),
        false,
        "Token not blocked"
    );

    // should be blocked
    await executeAndAssertTransaction(
        acc_l2,
        () => tokenBridgeContract.block_token(tokenAddress),
        true,
        "Token not blocked"
    );

    // 2. Current status: Blocked
    await tokenAsserts(tokenStarknetContract, tokenBridgeContract, TokenStatus.Blocked);

    // block_token should fail
    await executeAndAssertTransaction(
        acc_l2,
        () => tokenBridgeContract.block_token(tokenAddress),
        false,
        "Only unknown can be blocked"
    );

    // enroll_token should fail
    await executeAndAssertTransaction(
        acc_l2,
        () => tokenBridgeContract.enroll_token(tokenAddress),
        false,
        "Token not unknown"
    );

    // activate_token should fail
    await executeAndAssertTransaction(
        acc_l2,
        () => tokenBridgeContract.reactivate_token(tokenAddress),
        false,
        "Token not deactivated"
    );

    // deactivate_token should fail
    await executeAndAssertTransaction(
        acc_l2,
        () => tokenBridgeContract.deactivate_token(tokenAddress),
        false,
        "Token not active"
    );

    // unblock_token should not fail
    await executeAndAssertTransaction(
        acc_l2,
        () => tokenBridgeContract.unblock_token(tokenAddress),
        true
    );

    // 3. Current status: Unknown
    await tokenAsserts(tokenStarknetContract, tokenBridgeContract, TokenStatus.Unknown);

    await enrollToken(acc_l2, token);
    await sleep(15000);
    await getL3Balance(
        process.env.ACCOUNT_L3_ADDRESS as string,
        "ERC20_OZ"
    );

    // 1. Current status: Pending 
    await tokenAsserts(tokenStarknetContract, tokenBridgeContract, TokenStatus.Pending);

    // activate_token should fail
    await executeAndAssertTransaction(
        acc_l2,
        () => tokenBridgeContract.reactivate_token(tokenAddress),
        false,
        "Token not deactivated"
    );

    // deactivate_token should fail
    await executeAndAssertTransaction(
        acc_l2,
        () => tokenBridgeContract.deactivate_token(tokenAddress),
        false,
        "Token not active"
    );

    // unblock_token should fail
    await executeAndAssertTransaction(
        acc_l2,
        () => tokenBridgeContract.unblock_token(tokenAddress),
        false,
        "Token not blocked"
    );

    // block_token should fail
    await executeAndAssertTransaction(
        acc_l2,
        () => tokenBridgeContract.block_token(tokenAddress),
        false,
        "Only unknown can be blocked"
    );

    // enroll_token should fail
    await executeAndAssertTransaction(
        acc_l2,
        () => tokenBridgeContract.enroll_token(tokenAddress),
        false,
        "Token not unknown"
    );
}