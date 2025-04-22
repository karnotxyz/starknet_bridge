import { Account, logger, CairoEnum,  Contract as StarknetContract, TypedContractV2 } from "starknet";
import { Layer, Contract, TokenStatus } from "./config/types";
import { starknetBridgePackage, tokenBridgeL2Contract } from "./config/constants";
import { ABI as TokenBridgeL2ABI } from "./abis/starknet_bridge_TokenBridge";
import { ABI as ERC20ABI } from "./abis/starknet_bridge_ERC20";
import { getAccount, getContract } from "./utils/utils";
import assert from "assert";

async function tokenAsserts(token: TypedContractV2<typeof ERC20ABI>, tokenBridgeContract: TypedContractV2<typeof TokenBridgeL2ABI>, tokenStatus: TokenStatus) {
    const result = await tokenBridgeContract.get_status(token.address);
    logger.info(`Token status: ${result}`, result.variant);
    console.log(result.variant, result.activeVariant(), tokenStatus.toString());
    if (result.activeVariant() !== tokenStatus.toString()) {
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

    const acc_l3 = getAccount(Layer.L3);
    const tx = await token.approve(tokenBridgeContract.address, 10);
    await acc_l3.waitForTransaction(tx.transaction_hash);
    const depositTx = await tokenBridgeContract.deposit(token.address, 10, acc_l3.address);
    let receipt = await acc_l3.waitForTransaction(depositTx.transaction_hash);
    if(tokenStatus === TokenStatus.Active) {
        assert(receipt.isSuccess(), "Transaction was not successful");
    } else {
        assert(receipt.isRejected(), "Transaction was not rejected");
    }
    
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
    const tokenStarknetContract = new StarknetContract(ERC20ABI, tokenAddress, acc_l2).typedv2(ERC20ABI);
    const tokenBridge = tokenBridgeL2Contract.address;

    const tokenBridgeContract = new StarknetContract(TokenBridgeL2ABI, tokenBridge, acc_l2).typedv2(TokenBridgeL2ABI);

    // 1. Current status: Pending 
    await tokenAsserts(tokenStarknetContract, tokenBridgeContract, TokenStatus.Pending);

    // activate_token should fail
    {
        const tx = await tokenBridgeContract.activate_token(tokenAddress);
        const receipt = await acc_l2.waitForTransaction(tx.transaction_hash);
        assert(receipt.isRejected(), "Transaction was not rejected");
    }

    // deactivate_token should fail
    {
        const tx = await tokenBridgeContract.deactivate_token(tokenAddress);
        const receipt = await acc_l2.waitForTransaction(tx.transaction_hash);
        assert(receipt.isRejected(), "Transaction was not rejected");
    }

    // unblock_token should fail
    {
        const tx = await tokenBridgeContract.unblock_token(tokenAddress);
        const receipt = await acc_l2.waitForTransaction(tx.transaction_hash);
        assert(receipt.isRejected(), "Transaction was not rejected");
    }

    // block_token should fail
    {
        const tx = await tokenBridgeContract.block_token(tokenAddress);
        const receipt = await acc_l2.waitForTransaction(tx.transaction_hash);
        assert(receipt.isRejected(), "Transaction was not rejected");
    }

    // enroll_token should fail
    {
        const tx = await tokenBridgeContract.enroll_token(tokenAddress);
        const receipt = await acc_l2.waitForTransaction(tx.transaction_hash);
        assert(receipt.isRejected(), "Transaction was not rejected");
    }


    // 2. Current status: Unknown
    await tokenAsserts(tokenStarknetContract, tokenBridgeContract, TokenStatus.Unknown);

    // activate_token should fail
    {
        const tx = await tokenBridgeContract.activate_token(tokenAddress);
        const receipt = await acc_l2.waitForTransaction(tx.transaction_hash);
        assert(receipt.isRejected(), "Transaction was not rejected");
    }

    // deactivate_token should fail
    {
        const tx = await tokenBridgeContract.deactivate_token(tokenAddress);
        const receipt = await acc_l2.waitForTransaction(tx.transaction_hash);
        assert(receipt.isRejected(), "Transaction was not rejected");
    }

    // unblock_token should fail
    {
        const tx = await tokenBridgeContract.unblock_token(tokenAddress);
        const receipt = await acc_l2.waitForTransaction(tx.transaction_hash);
        assert(receipt.isRejected(), "Transaction was not rejected");
    }


    // should be blocked
    {
        const tx = await tokenBridgeContract.block_token(tokenAddress);
        const receipt = await acc_l2.waitForTransaction(tx.transaction_hash);
        assert(receipt.isSuccess(), "Transaction was not successful");
    }

    // 2. Current status: Blocked
    await tokenAsserts(tokenStarknetContract, tokenBridgeContract, TokenStatus.Blocked);

    // block_token should fail
    {
        const tx = await tokenBridgeContract.block_token(tokenAddress);
        const receipt = await acc_l2.waitForTransaction(tx.transaction_hash);
        assert(receipt.isRejected(), "Transaction was not rejected");
    }

    // enroll_token should fail
    {
        const tx = await tokenBridgeContract.enroll_token(tokenAddress);
        const receipt = await acc_l2.waitForTransaction(tx.transaction_hash);
        assert(receipt.isRejected(), "Transaction was not rejected");
    }

    // activate_token should fail
    {
        const tx = await tokenBridgeContract.activate_token(tokenAddress);
        const receipt = await acc_l2.waitForTransaction(tx.transaction_hash);
        assert(receipt.isRejected(), "Transaction was not rejected");
    }

    // deactivate_token should fail
    {
        const tx = await tokenBridgeContract.deactivate_token(tokenAddress);
        const receipt = await acc_l2.waitForTransaction(tx.transaction_hash);
        assert(receipt.isRejected(), "Transaction was not rejected");
    }

    // unblock_token should not fail
    {
        const tx = await tokenBridgeContract.unblock_token(tokenAddress);
        const receipt = await acc_l2.waitForTransaction(tx.transaction_hash);
        assert(receipt.isSuccess(), "Transaction was not successful");
    }

    // 3. Current status: Unknown
    await tokenAsserts(tokenStarknetContract, tokenBridgeContract, TokenStatus.Unknown);
}