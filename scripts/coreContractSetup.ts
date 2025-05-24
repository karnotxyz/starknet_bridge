import {
  deployContract,
  declareContract,
  getProvider,
  getAccount,
  getContract,
  setDumpPath
} from "./utils/utils.ts";
import { Layer, ProgramInfo, FactRegistryOptions } from "./config/types.ts";
import { Account, Contract as StarknetContract } from "starknet";
import { logger } from "./utils/logger.ts";
import {
    appchainConfig,
  appchainContract,
} from "./config/constants.ts";
import { ABI as AppchainABI } from "./abis/starknet_bridge_appchain.ts";
import assert from "assert";

/**
 * Deploy the core contract on Starknet L2
 */
export async function deployCoreContract(acc: Account) {
    await declareContract(appchainContract);
    logger.success("Appchain core contract declared successfully!");
  
    await deployContract(
      appchainContract,
      [
        acc.address, // owner
        0, // state_root,
        "0x800000000000011000000000000000000000000000000000000000000000000", // block_number,
        0, // block_hash
      ]
    );
  
    if (appchainContract.address) {
      logger.address(
        "Appchain core contract deployed at",
        appchainContract.address
      );
    }
}

export async function setProgramInfo(acc_l2: Account, programInfo?: ProgramInfo) {
    const provider = getProvider(Layer.L2);
    getContract(appchainContract);

    // Verify we have the required addresses
    if (!appchainContract.address) {
        const errorMsg = "Appchain core contract address not found, deploy core contract first";
        logger.error(errorMsg);
        throw new Error(errorMsg);
    }

    const appchainContractInstance = new StarknetContract(AppchainABI, appchainContract.address, acc_l2).typedv2(AppchainABI);
    if (!programInfo) {
        programInfo = appchainConfig.programInfo;
    }
    let tx = await appchainContractInstance.set_program_info(programInfo);
    const tx_receipt = await acc_l2.waitForTransaction(tx.transaction_hash);
    assert(tx_receipt.isSuccess(), `Set program info failed`);

    logger.success("Program info set successfully!");
    logger.txHash(tx.transaction_hash);
}

export async function setFactRegistry(
  acc_l2: Account, 
  options: FactRegistryOptions | string
) {
  let factRegistryAddress: string;

  if (typeof options === 'string') {
    // If a direct address is provided
    factRegistryAddress = options;
  } else {
    // If options object is provided
    switch (options.chain) {
      case 'SN_MAIN':
        factRegistryAddress = appchainConfig.factRegistry.SN_MAIN;
        break;
      case 'SN_SEPOLIA':
        factRegistryAddress = appchainConfig.factRegistry.SN_SEPOLIA[options.verificationType];
        break;
    }
  }
  
  getContract(appchainContract);
  // Verify we have the required addresses
  if (!appchainContract.address) {
      const errorMsg = "Appchain core contract address not found, deploy core contract first";
      logger.error(errorMsg);
      throw new Error(errorMsg);
  }

  const appchainContractInstance = new StarknetContract(AppchainABI, appchainContract.address, acc_l2).typedv2(AppchainABI);
  let tx = await appchainContractInstance.set_facts_registry(factRegistryAddress);
  const tx_receipt = await acc_l2.waitForTransaction(tx.transaction_hash);
  assert(tx_receipt.isSuccess(), `Set fact registry failed`);

  logger.success("Fact registry set successfully!");
  logger.txHash(tx.transaction_hash);
}