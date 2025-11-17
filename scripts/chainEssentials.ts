import { byteArray, hash, num } from "starknet";
import { feeTokenContract, universalDeployerContract } from "./config/constants.ts";
import { logger } from "./utils/logger.ts";
import { declareContract, deployContract, getAccount, getContract, getContracts, saveContracts } from "./utils/utils.ts";
import { Layer } from "./config/types.ts";
import { Contract as StarknetContract } from "starknet";
import { assert } from "console";

export async function deployFeeToken(
  name: string = "Native Fee token",
  symbol: string = "FT",
  decimals: number = 18
) {
  await declareContract(feeTokenContract);
  logger.success("FeeToken declared!");
  const feeContract = getContract(feeTokenContract);

  await deployContract(feeContract, [
    byteArray.byteArrayFromString(name), // name
    byteArray.byteArrayFromString(symbol), // symbol
    decimals, // decimals
    process.env.ACCOUNT_L3_ADDRESS as string, // owner
  ]);
}

export async function deployUniversalDeployer() {
  await declareContract(universalDeployerContract);
  logger.success("Cairo 1 UniversalDeployer declared!");


  const udcContract = getContract(universalDeployerContract);
  if (udcContract.address) {
    logger.success("Cairo 1 UniversalDeployer already deployed!");
    return { transaction_hash: '', contract_address: universalDeployerContract.address };
  }

  getContract(universalDeployerContract);
  let acc_l3 = getAccount(Layer.L3);

  console.log(udcContract.classHash);
  if (!udcContract.classHash) {
    throw new Error("UDC contract class hash not found");
  }

  const acc_cls = await acc_l3.getClassAt(acc_l3.address);
  const accountContract = new StarknetContract({ abi: acc_cls.abi, address: acc_l3.address, providerOrAccount: acc_l3 });

  const txn = accountContract.populate(
    "deploy_contract", {
    class_hash: udcContract.classHash,
    salt: 0n,
    from_zero: true,
    calldata: [],
  });

  const res = await acc_l3.execute([txn], {
    tip: 0,
    resourceBounds: {
      l1_data_gas: {
        max_amount: 0n,
        max_price_per_unit: 0n,
      },
      l1_gas: {
        max_amount: 0n,
        max_price_per_unit: 0n,
      },
      l2_gas: {
        max_amount: 0n,
        max_price_per_unit: 0n,
      },
    }
  });

  const tx_receipt = await acc_l3.waitForTransaction(res.transaction_hash);
  assert(tx_receipt.isSuccess(), `Deploy contract failed`);

  logger.success("Cairo 1 UniversalDeployer deployed successfully!");
  logger.txHash(res.transaction_hash);

  if (tx_receipt.isSuccess()) {
    const events = tx_receipt.value.events;
    const contractDeployedEvent = num.toHex(hash.starknetKeccak('ContractDeployed'));
    const contract_address = events.find((e: any) => e.keys[0] === contractDeployedEvent)?.data[0];
    if (!contract_address) {
      throw new Error("Contract deployed event not found");
    }

    const contracts = getContracts();
    if (!contracts.contracts) {
      contracts['contracts'] = {};
    }
    if (!contracts.contracts[Layer.L3]) {
      contracts.contracts[Layer.L3] = {};
    }
    contracts.contracts[udcContract.layer][udcContract.name] = contract_address;
    saveContracts(contracts);
    console.log(`Contract deployed: ${udcContract.name}`)
    console.log(`Address: ${contract_address}`);
  }
}