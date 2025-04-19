import { Account, Contract } from "starknet";
import { logger } from "./utils/logger";
import { appchainContract } from "./config/constants";
import { ABI as AppchainABI } from "./abis/starknet_bridge_appchain";
import { declareContract, getContract } from "./utils/utils";

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
