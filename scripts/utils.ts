import dotenv from 'dotenv';
dotenv.config();
import assert from 'assert'
import { Account, RawArgs, RpcProvider, TransactionFinalityStatus, extractContractHashes, hash, json, provider } from 'starknet'
import { readFileSync, existsSync, writeFileSync } from 'fs'
import { http, createWalletClient, WalletClient } from 'viem'
import { privateKeyToAccount } from 'viem/accounts';
import { sepolia } from 'viem/chains'



assert(process.env.RPC_L2_URL, 'RPC_L2_URL not set in .env');
assert(process.env.RPC_L3_URL, 'RPC_L3_UR not set in .env');;
assert(process.env.ACCOUNT_L2_ADDRESS, 'ACCOUNT_L2_ADDRESS not set in .env');
assert(process.env.ACCOUNT_L3_ADDRESS, 'ACCOUNT_L3_ADDRESS not set in .env');
assert(process.env.ACCOUNT_L1_PRIVATE_KEY, 'ACCOUNT_L1_PRIVATE_KEY not set in .env');
assert(process.env.ACCOUNT_L2_PRIVATE_KEY, 'ACCOUNT_L2_PRIVATE_KEY not set in .env');
assert(process.env.ACCOUNT_L3_PRIVATE_KEY, 'ACCOUNT_L3_PRIVATE_KEY not set in .env');


console.log('===============================')
console.log(`L3 RPC: ${process.env.RPC_L3_URL}`);
console.log(`L2 RPC: ${process.env.RPC_L2_URL}`);
console.log(`L2 Account Address: ${process.env.ACCOUNT_L2_ADDRESS}`);
console.log(`L3 Account Address: ${process.env.ACCOUNT_L3_ADDRESS}`);
console.log('===============================')

export enum Layer {
  L2,
  L3
}

// TODO: Add layer as a param
export function getContracts() {
  const PATH = './contracts.json'
  if (existsSync(PATH)) {
    return JSON.parse(readFileSync(PATH, { encoding: 'utf-8' }))
  }
  return {}
}

// TODO: Incorportate the layer also
// TODO: Add layer as a param
function saveContracts(contracts: any) {
  const PATH = './contracts.json'
  writeFileSync(PATH, JSON.stringify(contracts));
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



export function getAccount<T extends Layer>(layer: T): Account {
  // initialize provider
  const provider = getProvider(layer);
  if (layer == Layer.L2) {
    const privateKey = process.env.ACCOUNT_L2_PRIVATE_KEY as string;
    const accountAddress: string = process.env.ACCOUNT_L2_ADDRESS as string;
    return new Account(provider, accountAddress, privateKey, undefined, "0x3");
  } else if (layer == Layer.L3) {
    const privateKey = process.env.ACCOUNT_L3_PRIVATE_KEY as string;
    const accountAddress: string = process.env.ACCOUNT_L3_ADDRESS as string;
    return new Account(provider, accountAddress, privateKey, undefined, "0x3");
  } else {
    throw new Error('Invalid layer');
  }
}

export async function declareContract(contract_name: string, package_name: string, layer: Layer, base_path: string = './target/dev') {
  const provider = getProvider(layer);
  const acc = getAccount(layer);
  const compiledSierra = json.parse(
    readFileSync(`${base_path}/${package_name}_${contract_name}.contract_class.json`).toString("ascii")
  )
  const compiledCasm = json.parse(
    readFileSync(`${base_path}/${package_name}_${contract_name}.compiled_contract_class.json`).toString("ascii")
  )

  const contracts = getContracts();
  const payload = {
    contract: compiledSierra,
    casm: compiledCasm
  };
  //
  // const fee = await acc.estimateDeclareFee({
  //   contract: compiledSierra,
  //   casm: compiledCasm,
  // })
  // console.log('declare fee', Number(fee.suggestedMaxFee) / 10 ** 18, 'ETH')
  const result = extractContractHashes(payload);
  console.log("classhash:", result.classHash);

  try {

    let tx: { transaction_hash: string; class_hash: string; };
    if (layer === Layer.L3) {
      tx = await acc.declareIfNot(payload, { maxFee: 0 });
    } else {
      tx = await acc.declareIfNot(payload);
    }
    await provider.waitForTransaction(tx.transaction_hash, {
      successStates: [TransactionFinalityStatus.ACCEPTED_ON_L2]
    })

    console.log(`Declaring: ${contract_name}_${package_name}, tx: `, tx.transaction_hash);
    if (!contracts.class_hashes) {
      contracts['class_hashes'] = {};
    }
    // Todo attach cairo and scarb version. and commit ID
    contracts.class_hashes[`${contract_name}_${package_name}`] = tx.class_hash;
    saveContracts(contracts);
    console.log(`Contract declared: ${contract_name}_${package_name}`);
    console.log(`Class hash: ${tx.class_hash}`)

    return tx;
  } catch (e) {
    console.log(e);
  }
}

export async function deployContract(contract_name: string, classHash: string, constructorData: RawArgs, layer: Layer) {
  const provider = getProvider(layer);
  const acc = getAccount(layer);

  const fee = await acc.estimateDeployFee({
    classHash,
    constructorCalldata: constructorData,
  })
  console.log("Deploy fee", contract_name, Number(fee.suggestedMaxFee) / 10 ** 18, 'ETH')

  let tx: { transaction_hash: any; contract_address: any; address?: string; deployer?: string; unique?: string; classHash?: string; calldata_len?: string; calldata?: string[]; salt?: string; };
  if (layer === Layer.L3) {
    tx = await acc.deployContract({
      classHash,
      constructorCalldata: constructorData,
    }, { maxFee: 0 });
  } else {
    tx = await acc.deployContract({
      classHash,
      constructorCalldata: constructorData,
    });
  }
  console.log('Deploy tx: ', tx.transaction_hash);

  await provider.waitForTransaction(tx.transaction_hash, {
    // successStates: [TransactionFinalityStatus.ACCEPTED_ON_L2],
    retryInterval: 100,
  })

  const contracts = getContracts();
  if (!contracts.contracts) {
    contracts['contracts'] = {};
  }
  contracts.contracts[contract_name] = tx.contract_address;
  saveContracts(contracts);
  console.log(`Contract deployed: ${contract_name}`)
  console.log(`Address: ${tx.contract_address}`);

  return tx;
}
