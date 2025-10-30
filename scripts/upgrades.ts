import { Account, Contract, hash } from "starknet";
import { logger } from "./utils/logger.ts";
import { appchainContract, timelockContract, tokenBridgeL2Contract } from "./config/constants.ts";
import { ABI as AppchainABI } from "./abis/starknet_bridge_appchain.ts";
import { declareContract, getContract } from "./utils/utils.ts";
import { ABI as TimelockABI } from "./abis/starknet_bridge_TimelockController.ts";
import assert from "assert";

export async function upgradeAppchain(acc_l2: Account) {
    const appchain = getContract(appchainContract);
    if (!appchain.address) {
        const error = "Appchain contract address not found";
        logger.error(error);
        throw new Error(error);
    }

    await declareContract(appchainContract, false);

    const appchain_new = getContract(appchainContract);
    if (!appchain_new.classHash) {
        const error = "Appchain new class hash not found";
        logger.error(error);
        throw new Error(error);
    }

    const appchain_l2 = new Contract(AppchainABI, appchain.address, acc_l2).typedv2(AppchainABI);
    const tx = await appchain_l2.upgrade(appchain_new.classHash);

    const rec = await acc_l2.waitForTransaction(tx.transaction_hash);
    assert(rec.isSuccess(), "Failed to upgrade appchain");
    logger.txHash(tx.transaction_hash);
    logger.success("Upgraded appchain");
}

export async function upgradeTokenBridgeL2(acc_l2: Account) {
    getContract(tokenBridgeL2Contract);
    if (!tokenBridgeL2Contract.address) {
        const error = "TokenBridgeL2 contract address not found";
        logger.error(error);
        throw new Error(error);
    }

    getContract(timelockContract);
    if (!timelockContract.address) {
        const error = "Timelock contract address not found";
        logger.error(error);
        throw new Error(error);
    }
   
    await declareContract(tokenBridgeL2Contract, false);

    getContract(tokenBridgeL2Contract);
    if (!tokenBridgeL2Contract.classHash) {
        const error = "TokenBridgeL2 new class hash not found";
        logger.error(error);
        throw new Error(error);
    }

    
    const timelock_l2Contract = new Contract(TimelockABI, timelockContract.address, acc_l2).typedv2(TimelockABI);
    const minDelay = await timelock_l2Contract.get_min_delay();
    const proposalTx = await timelock_l2Contract.schedule(
        { 
            to: tokenBridgeL2Contract.address, 
            selector: hash.getSelectorFromName("upgrade"),
            calldata: [tokenBridgeL2Contract.classHash]
        }, 
        0, 
        0, 
        minDelay
    );

    const rec = await acc_l2.waitForTransaction(proposalTx.transaction_hash);
    assert(rec.isSuccess(), "Failed to add proposal for Upgrade");
    logger.txHash(proposalTx.transaction_hash);
    logger.success("Scheduled token bridge upgrade on timelock");

}

export async function executeUpgradeTokenBridgeL2(acc_l2: Account) {
    getContract(tokenBridgeL2Contract);
    if (!tokenBridgeL2Contract.address || !tokenBridgeL2Contract.classHash) {
        const error = "TokenBridgeL2 contract address/classHash not found";
        logger.error(error);
        throw new Error(error);
    }

    getContract(timelockContract);
    if (!timelockContract.address) {
        const error = "Timelock contract address/classHash not found";
        logger.error(error);
        throw new Error(error);
    }


    const timelock_l2Contract = new Contract({ abi: TimelockABI, address: timelockContract.address, providerOrAccount: acc_l2 }).typedv2(TimelockABI);
    const executeTx = await timelock_l2Contract.execute(
        {
            to: tokenBridgeL2Contract.address,
            selector: hash.getSelectorFromName("upgrade"),
            calldata: [tokenBridgeL2Contract.classHash]
        },
        0, 0 
    );
    const receipt = await acc_l2.waitForTransaction(executeTx.transaction_hash);
    assert(receipt.isSuccess(), "Failed to execute upgrade proposal for TokenBridgeL2");
    logger.txHash(executeTx.transaction_hash);
    logger.success("Executed token bridge upgrade on timelock");
    
    logger.success("Upgraded token bridge on l2");
}

