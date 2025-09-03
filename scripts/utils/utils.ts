import assert from 'assert'
import { Account, RawArgs, RpcProvider, TransactionFinalityStatus, extractContractHashes, hash, json, num, provider } from 'starknet'
import { readFileSync, existsSync, writeFileSync } from 'fs'
import { http, createWalletClient, WalletClient } from 'viem'
import { privateKeyToAccount } from 'viem/accounts';
import { logger } from "./logger.ts";
import { sepolia } from 'viem/chains'
import { Layer, Contract } from '../config/types.ts'

export async function checkEnvVars() {
  console.log('===============================')
  console.log(`L3 RPC: ${process.env.RPC_L3_URL}`);
  console.log(`L2 RPC: ${process.env.RPC_L2_URL}`);
  console.log(`L2 Account Address: ${process.env.ACCOUNT_L2_ADDRESS}`);
  console.log(`L3 Account Address: ${process.env.ACCOUNT_L3_ADDRESS}`);
  console.log('===============================')
  assert(process.env.RPC_L2_URL, 'RPC_L2_URL not set in .env');
  assert(process.env.RPC_L3_URL, 'RPC_L3_URL not set in .env');
  assert(process.env.ACCOUNT_L2_ADDRESS, 'ACCOUNT_L2_ADDRESS not set in .env');
  assert(process.env.ACCOUNT_L3_ADDRESS, 'ACCOUNT_L3_ADDRESS not set in .env');
  assert(process.env.ACCOUNT_L2_PRIVATE_KEY, 'ACCOUNT_L2_PRIVATE_KEY not set in .env');
  assert(process.env.ACCOUNT_L3_PRIVATE_KEY, 'ACCOUNT_L3_PRIVATE_KEY not set in .env');
}

export let dumpPath: string = '';

export function setDumpPath(path: string) {
  dumpPath = path;
}

// Get contract information for a specific contract
export function getContract(contract: Contract): Contract {
  const PATH = dumpPath;
  if (!existsSync(PATH)) {
    return contract;
  }

  const contracts = JSON.parse(readFileSync(PATH, { encoding: 'utf-8' }));

  // Try to get class hash if it exists in stored contracts
  if (contracts.class_hashes &&
    contracts.class_hashes[contract.layer] &&
    contracts.class_hashes[contract.layer][`${contract.name}_${contract.package.name}`]) {
    contract.classHash = contracts.class_hashes[contract.layer][`${contract.name}_${contract.package.name}`];
  }

  // Try to get contract address if it exists in stored contracts
  if (contracts.contracts && contracts.contracts[contract.layer] && contracts.contracts[contract.layer][contract.name]) {
    contract.address = contracts.contracts[contract.layer][contract.name];
  }

  return contract;
}

export function getContracts() {
  const PATH = dumpPath;
  if (existsSync(PATH)) {
    return JSON.parse(readFileSync(PATH, { encoding: 'utf-8' }))
  }
  return {}
}

function saveContracts(contracts: any) {
  const PATH = dumpPath;
  writeFileSync(PATH, JSON.stringify(contracts, null, 4));
}

export function getProvider(layer: Layer): RpcProvider {
  if (layer === Layer.L2) {
    return new RpcProvider({ nodeUrl: process.env.RPC_L2_URL as string, retries: 5 });
  } else if (layer === Layer.L3) {
    return new RpcProvider({ nodeUrl: process.env.RPC_L3_URL as string, retries: 5 });
  } else {
    throw new Error('Invalid layer');
  }
}

export function getEthereumClient(): WalletClient {
  assert(process.env.ACCOUNT_L1_PRIVATE_KEY, 'invalid ACCOUNT_L1_PRIVATE_KEY');
  const privateKey = process.env.ACCOUNT_L1_PRIVATE_KEY as string;
  const account = privateKeyToAccount(`0x${privateKey}`);
  return createWalletClient({
    chain: sepolia,
    transport: http(),
    account
  })
}

export function getAccount(layer: Layer): Account {
  // initialize provider
  const provider = getProvider(layer);
  if (layer == Layer.L2) {
    const privateKey = process.env.ACCOUNT_L2_PRIVATE_KEY as string;
    const accountAddress: string = process.env.ACCOUNT_L2_ADDRESS as string;
    return new Account(provider, accountAddress, privateKey, '1', "0x3");
  } else if (layer == Layer.L3) {
    const privateKey = process.env.ACCOUNT_L3_PRIVATE_KEY as string;
    const accountAddress: string = process.env.ACCOUNT_L3_ADDRESS as string;
    return new Account(provider, accountAddress, privateKey, '1', "0x3");
  } else {
    throw new Error('Invalid layer');
  }
}


export function standardiseAddress(address: string | bigint) {
  let _a = address;
  if (!address) {
    _a = "0";
  }
  const a = num.getHexString(num.getDecimalString(_a.toString()));
  return a;
}

/**
 * Sleep for a specified number of milliseconds
 * @param ms Number of milliseconds to sleep
 * @returns Promise that resolves after the specified time
 */
export const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

export async function declareContract(contract: Contract, skipIfPresentInDump: boolean = true) {
  // First, check if we already have the contract declared and get existing information
  getContract(contract);

  // If contract already has a class hash, it's already declared
  if (contract.classHash && skipIfPresentInDump) {
    logger.info(`Contract ${contract.name} already present in dump with class hash ${contract.classHash}`);
    return { transaction_hash: '', class_hash: contract.classHash };
  }

  const layer = contract.layer;
  const provider = getProvider(layer);
  const acc = getAccount(layer);
  const compiledSierra = json.parse(
    readFileSync(`${contract.package.base_path}/${contract.package.name}_${contract.name}.contract_class.json`).toString("ascii")
  )
  const compiledCasm = json.parse(
    readFileSync(`${contract.package.base_path}/${contract.package.name}_${contract.name}.compiled_contract_class.json`).toString("ascii")
  )

  const contracts = getContracts();
  const payload = {
    contract: compiledSierra,
    casm: compiledCasm
  };

  logger.info(`Declaring: ${contract.name}_${contract.package.name}`);
  try {
    let tx: { transaction_hash: string; class_hash: string; };
    if (layer === Layer.L3) {
      logger.info('Declaring on L3');
      tx = await acc.declareIfNot(payload, {
        maxFee: 0,
        resourceBounds: {
          l1_gas: {
            max_amount: "0x0",
            max_price_per_unit: "0x0"
          },
          l2_gas: {
            max_amount: "0x0",
            max_price_per_unit: "0x0"
          }
        }
      });
    } else {
      logger.info('Declaring on L2');
      tx = await acc.declareIfNot(payload);
    }

    if (tx.transaction_hash !== '') {
      const tx_receipt = await provider.waitForTransaction(tx.transaction_hash, {
        successStates: [TransactionFinalityStatus.ACCEPTED_ON_L2]
      })
      assert(tx_receipt.isSuccess(), `Contract ${contract.name} declaration failed`);
    } else {
      logger.info(`Contract ${contract.name} already declared with class hash ${tx.class_hash}`);
    }

    if (!contracts.class_hashes) {
      contracts['class_hashes'] = {};
    }
    if (!contracts.class_hashes[layer]) {
      contracts.class_hashes[layer] = {};
    }
    // Todo attach cairo and scarb version. and commit ID
    contracts.class_hashes[layer][`${contract.name}_${contract.package.name}`] = tx.class_hash;
    saveContracts(contracts);
    logger.info(`Contract declared: ${contract.name}_${contract.package.name}`);
    logger.info(`Class hash: ${tx.class_hash}`)

    // Update contract with class hash
    contract.classHash = tx.class_hash;

    return tx;
  } catch (e) {
    logger.error(e);
    throw e;
  }
}

export async function deployContract(contract: Contract, constructorData: RawArgs) {
  // If contract has address, it's already deployed
  if (contract.address) {
    console.log(`Contract ${contract.name} already deployed at address ${contract.address}`);
    return { transaction_hash: '', contract_address: contract.address };
  }

  const layer = contract.layer;
  const provider = getProvider(layer);
  const acc = getAccount(layer);

  if (!contract.classHash) {
    throw new Error(`Contract ${contract.name} has no class hash. Declare it first.`);
  }

  const fee = await acc.estimateDeployFee({
    classHash: contract.classHash,
    constructorCalldata: constructorData,
  })
  console.log("Deploy fee", contract.name, Number(fee.suggestedMaxFee) / 10 ** 18, 'ETH')

  let tx: { transaction_hash: any; contract_address: any; address?: string; deployer?: string; unique?: string; classHash?: string; calldata_len?: string; calldata?: string[]; salt?: string; };
  if (layer === Layer.L3) {
    tx = await acc.deployContract({
      classHash: contract.classHash,
      constructorCalldata: constructorData,
    }, {
      maxFee: 0,
      resourceBounds: {
        l1_gas: {
          max_amount: "0x0",
          max_price_per_unit: "0x0"
        },
        l2_gas: {
          max_amount: "0x0",
          max_price_per_unit: "0x0"
        }
      }
    });
  } else {
    tx = await acc.deployContract({
      classHash: contract.classHash,
      constructorCalldata: constructorData,
    });
  }
  console.log('Deploy tx: ', tx.transaction_hash);

  let tx_receipt = await provider.waitForTransaction(tx.transaction_hash, {
    // successStates: [TransactionFinalityStatus.ACCEPTED_ON_L2],
    retryInterval: 100,
  })

  assert(tx_receipt.isSuccess(), `Contract ${contract.name} deployment failed`);

  const contracts = getContracts();
  if (!contracts.contracts) {
    contracts['contracts'] = {};
  }
  if (!contracts.contracts[layer]) {
    contracts.contracts[layer] = {};
  }
  contracts.contracts[contract.layer][contract.name] = tx.contract_address;
  saveContracts(contracts);
  console.log(`Contract deployed: ${contract.name}`)
  console.log(`Address: ${tx.contract_address}`);

  // Update contract with address
  contract.address = tx.contract_address;

  return tx;
}

