import * as dotenv from "dotenv";
dotenv.config();

import { deployContract, getAccount, declareContract, getContracts, getProvider, Layer } from "./utils";
import {
  Account,
  // ByteArray, RawArgs, uint256,
  // RpcProvider, TransactionExecutionStatus,
  // extractContractHashes, num hash, json, provider,
  byteArray, Contract, num
} from 'starknet'

const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

async function deployCoreContract(acc: Account) {
  await declareContract("appchain", "starknet_bridge", Layer.L2);
  console.log("Appchain core contract declared successfully !!");
  const class_hash = await getContracts().class_hashes["appchain_starknet_bridge"];
  await sleep(2000);
  const contract = await deployContract("appchain_starknet_bridge", class_hash, [
    acc.address, // owner
    1, // state_root,
    1, // block_number,
    1, // block_hash
  ], Layer.L2);

  await sleep(2000);
  console.log("Appchain core contract deployed successfully at: ", contract.address);
}

async function deployAppchainBridge() {
  await declareContract("TokenBridge", "starkgate_contracts", Layer.L3, "./starkgate-contracts/cairo_contracts");
  console.log("TokenBridge declared !!");
  const class_hash = await getContracts().class_hashes["TokenBridge_starkgate_contracts"];
  await sleep(2000);
  const contract = await deployContract("TokenBridge_starkgate_contracts", class_hash, [process.env.ACCOUNT_ADDRESS as string, "10"], Layer.L3);
  console.log("AppchainBridge deployed at: ", contract.address);
  await sleep(2000);
}

async function deployL2Brdige() {
  await declareContract("TokenBridge", "starknet_bridge", Layer.L2);
  console.log("TokenBridge declared !!");
  await sleep(1000);
  const saved_class_hash = await getContracts().class_hashes["TokenBridge_starknet_bridge"];
  const appchainBridge = getContracts().contracts["TokenBridge_starkgate_contracts"];
  const appchainContract = getContracts().contracts["appchain_starknet_bridge"];
  const contract = await deployContract("TokenBridge_starknet_bridge", saved_class_hash, [
    appchainBridge,
    appchainContract,
    process.env.ACCOUNT_ADDRESS as string
  ], Layer.L2);
  console.log("TokenBridge L2 deployed at: ", contract.address);
}


async function configureAppchainBridge(acc: Account) {
  const appchainBridge = getContracts().contracts["TokenBridge_starkgate_contracts"];
  const provider = getProvider(Layer.L3);
  const cls = await provider.getClassAt(appchainBridge);
  const appchainBridgeContract = new Contract(cls.abi, appchainBridge, provider);

  {
    const call = appchainBridgeContract.populate('register_app_role_admin', {
      account: acc.address
    });
    await acc.execute([call]);
    console.log("App role admin set successfully !!");
    await sleep(5000);
  }

  {
    const call = appchainBridgeContract.populate('register_app_governor', {
      account: acc.address
    });
    await acc.execute([call]);
    console.log("App governor set successfully !!");
    await sleep(5000);

  }

  {
    const call = appchainBridgeContract.populate('set_l2_token_governance', {
      l2_token_governance: acc.address
    });
    await acc.execute([call]);
    console.log("L2 Governance set successfully !!");
    await sleep(5000);
  }

}


async function setL2Bridge(acc: Account) {
  const tokenBridge = getContracts().contracts["TokenBridge_starknet_bridge"];

  const appchainBridge = getContracts().contracts["TokenBridge_starkgate_contracts"];
  const provider = getProvider(Layer.L3);
  const cls = await provider.getClassAt(appchainBridge);
  const appchainBridgeContract = new Contract(cls.abi, appchainBridge, provider);

  {
    const call = appchainBridgeContract.populate('set_l1_bridge', {
      l1_bridge_address: tokenBridge
    });
    await acc.execute([call]);
    console.log("L2 bridge set successfully !!");
    await sleep(1000);
  }
}

async function deployERC20() {
  await declareContract("ERC20", "starknet_bridge", Layer.L2);
  await sleep(5000);
  const saved_class_hash = await getContracts().class_hashes["ERC20_starknet_bridge"];
  const contract = await deployContract("ERC20_starknet_bridge", saved_class_hash, [
    byteArray.byteArrayFromString("Gridy Token"), // name
    byteArray.byteArrayFromString("GRD"),  // symbol
    18,  // decimals
    10000n * 10n ** 18n, // initial_supply
    0,
    "0x55be462e718c4166d656d11f89e341115b8bc82389c3762a10eade04fcb225d", // initia_recepient
    "0x55be462e718c4166d656d11f89e341115b8bc82389c3762a10eade04fcb225d", // l2_token_governance 
    "0x55be462e718c4166d656d11f89e341115b8bc82389c3762a10eade04fcb225d", // permitted_minter 
    0, // upgrade delay
  ], Layer.L2);
  await sleep(5000);
  console.log("ERC20 deployed at: ", contract.address);
}

async function declareAndSetERC20L3() {
  await declareContract("ERC20", "starknet_bridge", Layer.L3);
  console.log("ERC20 declared !!");
  await sleep(3000);

  const appchainBridge = getContracts().contracts["TokenBridge_starkgate_contracts"];
  const provider = getProvider(Layer.L3);
  const cls = await provider.getClassAt(appchainBridge);
  const appchainBridgeContract = new Contract(cls.abi, appchainBridge, provider);

  let acc = getAccount(Layer.L3);

  {
    const class_hash = await getContracts().class_hashes["ERC20_starknet_bridge"];
    const call = appchainBridgeContract.populate('set_erc20_class_hash', {
      erc20_class_hash: class_hash
    });
    let result = await acc.execute([call]);
    console.log("ERC20 class_hash set successfully !!", result);
    await sleep(5000);
  }
}

async function enrollToken(acc: Account) {
  const gridTokenAddress = getContracts().contracts["ERC20_starknet_bridge"];
  const tokenBridge = getContracts().contracts["TokenBridge_starknet_bridge"];

  const provider = getProvider(Layer.L2);
  const cls = await provider.getClassAt(tokenBridge);
  const tokenBridgeContract = new Contract(cls.abi, tokenBridge, provider);


  const call = tokenBridgeContract.populate('enroll_token', {
    token: gridTokenAddress,
  });
  let result = await acc.execute([call]);
  await sleep(5000);
  console.log("Token enrolled successfully !!", result);
}

async function getAppchainBridge() {
  const gridTokenAddress = getContracts().contracts["ERC20_starknet_bridge"];
  const tokenBridge = getContracts().contracts["TokenBridge_starknet_bridge"];

  const provider = getProvider(Layer.L2);
  const cls = await provider.getClassAt(tokenBridge);
  const tokenBridgeContract = new Contract(cls.abi, tokenBridge, provider);


  const call = await tokenBridgeContract.call('appchain_bridge');
  if (typeof call === 'bigint') {
    console.log("Appchain bridge on TokenBridge is: ", call, num.toHex(call));
  }
}

async function deposit(acc: Account) {
  const gridTokenAddress = getContracts().contracts["ERC20_starknet_bridge"];
  const tokenBridge = getContracts().contracts["TokenBridge_starknet_bridge"];

  const provider = getProvider(Layer.L2);


  // Approval
  {
    const gridCls = await provider.getClassAt(gridTokenAddress);
    const gridToken = new Contract(gridCls.abi, gridTokenAddress, provider);

    const call = gridToken.populate('approve', {
      spender: tokenBridge,
      amount: 10n * 10n ** 18n
    });
    let result = await acc.execute([call]);
    console.log("Approval success !!", result);
  }
  await sleep(4000);



  // Deposit
  {
    const Bridgecls = await provider.getClassAt(tokenBridge);
    const tokenBridgeContract = new Contract(Bridgecls.abi, tokenBridge, provider);

    const call = tokenBridgeContract.populate('deposit', {
      token: gridTokenAddress,
      amount: 10n * 10n ** 18n,
      appchain_recipient: process.env.ACCOUNT_ADDRESS as string,
      message: 0
    });
    let result = await acc.execute([call]);
    console.log("Deposit success !!", result);
    await sleep(7000);
  }
}

async function getNameAndSymbol(acc: Account) {
  const gridTokenAddress = getContracts().contracts["ERC20_starknet_bridge"];
  let provider = getProvider(Layer.L2);
  const cls = await provider.getClassAt(gridTokenAddress);
  const gridToken = new Contract(cls.abi, gridTokenAddress, provider);

  {
    const call = await gridToken.call('name');
    console.log("Name: ", call);
  }

  {
    const call = await gridToken.call('symbol');
    console.log("Symbol: ", call);
  }
}

async function deployTestingContract() {
  await declareContract("TestingContract", "starknet_bridge", Layer.L2);
  console.log("Testing contract declared !!");
  await sleep(1000);
  const class_hash = await getContracts().class_hashes["TestingContract_starknet_bridge"];
  const contract = await deployContract("TestingContract_starknet_bridge", class_hash, [], Layer.L2);
  console.log("Testing Contract deployed at: ", contract.address);
}

async function generateCalldata() {
  const testingContract = getContracts().contracts["TestingContract_starknet_bridge"];
  const provider = getProvider(Layer.L2);
  const cls = await provider.getClassAt(testingContract);
  const testingContractInstance = new Contract(cls.abi, testingContract, provider);

  const gridTokenAddress = getContracts().contracts["ERC20_starknet_bridge"];
  const call = await testingContractInstance.call('generate_calldata', [gridTokenAddress]);
  console.log("generate_calldata: ", call);

}

async function snToAppchainMessages() {
  let provider = getProvider(Layer.L2);
  const appchainContract = getContracts().contracts["appchain_starknet_bridge"];
  const cls = await provider.getClassAt(appchainContract);
  const messaging = new Contract(cls.abi, appchainContract, provider);
  const call = await messaging.call('sn_to_appchain_messages', [0]);
  console.log("sn_to_appchain_messages: ", call);
}

async function activateToken(acc: Account) {

  const tokenBridge = getContracts().contracts["TokenBridge_starknet_bridge"];
  const provider = getProvider(Layer.L2);
  const Bridgecls = await provider.getClassAt(tokenBridge);
  const tokenBridgeContract = new Contract(Bridgecls.abi, tokenBridge, provider);

  const call = tokenBridgeContract.populate('activate_token', {
    token: getContracts().contracts["ERC20_starknet_bridge"]
  });

  let result = await acc.execute([call]);
  await sleep(4000);
  console.log("Token activated successfully !!", result);

}

async function getL3Balance(address: string) {
  const gridTokenAddress = getContracts().contracts["ERC20_starknet_bridge"];
  const appchainBridge = getContracts().contracts["TokenBridge_starkgate_contracts"];
  const providerL3 = getProvider(Layer.L3);

  const appchainBridgeCls = await providerL3.getClassAt(appchainBridge);
  const appchainBridgeContract = new Contract(appchainBridgeCls.abi, appchainBridge, providerL3);

  const correspondingToken = await appchainBridgeContract.call('get_l2_token', [gridTokenAddress]);

  if (correspondingToken != 0n) {
    const correspondingTokenAddress = num.toHex(correspondingToken as any);
    console.log("Corresponding appchain token address: ", correspondingTokenAddress);
    const appchainTokenCls = await providerL3.getClassAt(correspondingTokenAddress);
    const appchainToken = new Contract(appchainTokenCls.abi, correspondingTokenAddress, providerL3);
    const balance = await appchainToken.call('balanceOf', [address]);
    console.log("Balance: ", balance);
  }
}

async function setup() {
  const acc_l3 = getAccount(Layer.L3);
  await deployAppchainBridge();
  await deployL2Brdige();

  await configureAppchainBridge(acc_l3);
  await setL2Bridge(acc_l3);
  await deployERC20();
  await declareAndSetERC20L3();

  console.log("Setup completed !!");
}

async function main() {
  const acc_l2 = getAccount(Layer.L2);
  const acc_l3 = getAccount(Layer.L3);

  // await deployCoreContract(acc_l2);

  // await setup();
  // await enrollToken(acc_l2);
  // await activateToken(acc_l2);
  // await deposit(acc_l2);
  await getL3Balance(acc_l3.address);


  // await getAppchainBridge();
  // await deployTestingContract();
  // await getNameAndSymbol(acc_l2);
  // await snToAppchainMessages();
}

main();
