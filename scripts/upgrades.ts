import { Account, Contract } from "starknet";
import { logger } from "./utils/logger";
import { appchainContract, tokenBridgeL2Contract } from "./config/constants";
import { ABI as AppchainABI } from "./abis/starknet_bridge_appchain";
import { declareContract, getContract } from "./utils/utils";
import { ABI as TokenBridgeL2ABI } from "./abis/starknet_bridge_TokenBridge";


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

    await acc_l2.waitForTransaction(tx.transaction_hash);
    logger.txHash(tx.transaction_hash);
    logger.success("Upgraded appchain");
}

export async function upgradeTokenBridgeL2(acc_l2: Account) {
    const tokenBridge = getContract(tokenBridgeL2Contract);
    if (!tokenBridge.address) {
        const error = "TokenBridgeL2 contract address not found";
        logger.error(error);
        throw new Error(error);
    }

    await declareContract(tokenBridgeL2Contract, false);

    const tokenBridge_new = getContract(tokenBridgeL2Contract);
    if (!tokenBridge_new.classHash) {
        const error = "TokenBridgeL2 new class hash not found";
        logger.error(error);
        throw new Error(error);
    }

    const tokenBridge_l2 = new Contract(TokenBridgeL2ABI, tokenBridge.address, acc_l2).typedv2(TokenBridgeL2ABI);
    const tx = await tokenBridge_l2.upgrade(tokenBridge_new.classHash);

    await acc_l2.waitForTransaction(tx.transaction_hash);
    logger.txHash(tx.transaction_hash);
    logger.success("Upgraded token bridge on l2");
}