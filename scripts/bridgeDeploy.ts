import * as dotenv from "dotenv";
dotenv.config();

import { deployContract, getAccount, declareContract, getContracts, getProvider, Layer, getEthereumClient } from "./utils";
import { Account, byteArray, Contract, num } from 'starknet'

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
  // await declareContract("TokenBridge", "starkgate_contracts", Layer.L3, "./starkgate-contracts/cairo_contracts");
  console.log("TokenBridge declared !!");
  const class_hash = await getContracts().class_hashes["TokenBridge_starkgate_contracts"];
  await sleep(2000);
  const contract = await deployContract("TokenBridge_starkgate_contracts", class_hash, [process.env.ACCOUNT_L3_ADDRESS as string, "10"], Layer.L3);
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
    process.env.ACCOUNT_L2_ADDRESS as string
  ], Layer.L2);
  console.log("TokenBridge L2 deployed at: ", contract.address);
}


async function configureAppchainBridge(acc_l3: Account) {
  const appchainBridge = getContracts().contracts["TokenBridge_starkgate_contracts"];
  const cls = await acc_l3.getClassAt(appchainBridge);
  const appchainBridgeContract = new Contract(cls.abi, appchainBridge, acc_l3);

  {
    const call = appchainBridgeContract.populate('register_app_role_admin', {
      account: acc_l3.address
    });
    await acc_l3.execute([call], { maxFee: 0 });
    console.log("App role admin set successfully !!");
    await sleep(5000);
  }

  {
    const call = appchainBridgeContract.populate('register_app_governor', {
      account: acc_l3.address
    });
    await acc_l3.execute([call], { maxFee: 0 });
    console.log("App governor set successfully !!");
    await sleep(5000);

  }

  {
    const call = appchainBridgeContract.populate('set_l2_token_governance', {
      l2_token_governance: acc_l3.address
    });
    await acc_l3.execute([call], { maxFee: 0 });
    console.log("L2 Governance set successfully !!");
    await sleep(5000);
  }

}


async function setL2Bridge(acc_l3: Account) {
  const tokenBridge = getContracts().contracts["TokenBridge_starknet_bridge"];

  const appchainBridge = getContracts().contracts["TokenBridge_starkgate_contracts"];
  const cls = await acc_l3.getClassAt(appchainBridge);
  const appchainBridgeContract = new Contract(cls.abi, appchainBridge, acc_l3);

  {
    const call = appchainBridgeContract.populate('set_l1_bridge', {
      l1_bridge_address: tokenBridge
    });
    await acc_l3.execute([call], { maxFee: 0 });
    console.log("L2 bridge set successfully !!");
    await sleep(1000);
  }
}

async function deployERC20() {
  // await declareContract("ERC20", "starknet_bridge", Layer.L2);
  await sleep(5000);
  const saved_class_hash = await getContracts().class_hashes["ERC20_starknet_bridge"];
  const contract = await deployContract("ERC20_starknet_bridge", saved_class_hash, [
    byteArray.byteArrayFromString("Gridy Token"), // name
    byteArray.byteArrayFromString("GRD"),  // symbol
    18,  // decimals
    10000n * 10n ** 18n, // initial_supply
    0,
    process.env.ACCOUNT_L2_ADDRESS as string, // initia_recepient
    process.env.ACCOUNT_L2_ADDRESS as string, // l2_token_governance 
    process.env.ACCOUNT_L2_ADDRESS as string, // permitted_minter 
    0, // upgrade delay
  ], Layer.L2);
  await sleep(5000);
  console.log("ERC20 deployed at: ", contract.address);
}

async function declareAndSetERC20L3(acc_l3: Account) {
  await declareContract("ERC20", "starknet_bridge", Layer.L3);
  console.log("ERC20 declared !!");
  await sleep(3000);

  const appchainBridge = getContracts().contracts["TokenBridge_starkgate_contracts"];
  const cls = await acc_l3.getClassAt(appchainBridge);
  const appchainBridgeContract = new Contract(cls.abi, appchainBridge, acc_l3);

  let acc = getAccount(Layer.L3);

  {
    const class_hash = await getContracts().class_hashes["ERC20_starknet_bridge"];
    const call = appchainBridgeContract.populate('set_erc20_class_hash', {
      erc20_class_hash: class_hash
    });
    let result = await acc.execute([call], { maxFee: 0 });
    console.log("ERC20 class_hash set successfully !!", result);
    await sleep(5000);
  }
}

async function enrollToken(acc_l2: Account, token: string = "ERC20_starknet_bridge") {
  const gridTokenAddress = getContracts().contracts[token];
  const tokenBridge = getContracts().contracts["TokenBridge_starknet_bridge"];

  const cls = await acc_l2.getClassAt(tokenBridge);
  const tokenBridgeContract = new Contract(cls.abi, tokenBridge, acc_l2);


  const call = tokenBridgeContract.populate('enroll_token', {
    token: gridTokenAddress,
  });
  let result = await acc_l2.execute([call]);
  await sleep(5000);
  console.log("Token enrolled successfully !!", result);
}



async function deposit(acc_l2: Account) {
  const gridTokenAddress = getContracts().contracts["ERC20_starknet_bridge"];
  const tokenBridge = getContracts().contracts["TokenBridge_starknet_bridge"];



  // Approval
  {
    const gridCls = await acc_l2.getClassAt(gridTokenAddress);
    const gridToken = new Contract(gridCls.abi, gridTokenAddress, acc_l2);

    const call = gridToken.populate('approve', {
      spender: tokenBridge,
      amount: 10n * 10n ** 18n
    });
    let result = await acc_l2.execute([call]);
    console.log("Approval success !!", result);
  }
  await sleep(4000);



  // Deposit
  {
    const Bridgecls = await acc_l2.getClassAt(tokenBridge);
    const tokenBridgeContract = new Contract(Bridgecls.abi, tokenBridge, acc_l2);

    const call = tokenBridgeContract.populate('deposit', {
      token: gridTokenAddress,
      amount: 10n * 10n ** 18n,
      appchain_recipient: process.env.ACCOUNT_L3_ADDRESS as string,
      message: 0
    });
    let result = await acc_l2.execute([call]);
    console.log("Deposit success !!", result);
    await sleep(10000);
  }
}




async function activateToken(acc: Account, token: string = "ERC20_starknet_bridge") {

  const tokenBridge = getContracts().contracts["TokenBridge_starknet_bridge"];
  const Bridgecls = await acc.getClassAt(tokenBridge);
  const tokenBridgeContract = new Contract(Bridgecls.abi, tokenBridge, acc);

  const call = tokenBridgeContract.populate('activate_token', {
    token: getContracts().contracts[token]
  });

  let result = await acc.execute([call]);
  await sleep(4000);
  console.log("Token activated successfully !!", result);

}

async function getL3Balance(address: string, token: string = "MyL2GameToken") {
  const gameTokenAddress = getContracts().contracts[token];
  const appchainBridge = getContracts().contracts["TokenBridge_starkgate_contracts"];
  const providerL3 = getProvider(Layer.L3);

  const appchainBridgeCls = await providerL3.getClassAt(appchainBridge);
  const appchainBridgeContract = new Contract(appchainBridgeCls.abi, appchainBridge, providerL3);

  const correspondingToken = await appchainBridgeContract.call('get_l2_token', [gameTokenAddress]);
  // console.log("Corresponding appchain token: ", num.toHex(correspondingToken as string));

  if (correspondingToken != 0n) {
    const correspondingTokenAddress = num.toHex(correspondingToken as any);
    console.log("Corresponding appchain token address: ", correspondingTokenAddress);
    const appchainTokenCls = await providerL3.getClassAt(correspondingTokenAddress);
    const appchainToken = new Contract(appchainTokenCls.abi, correspondingTokenAddress, providerL3);
    const balance = await appchainToken.call('balanceOf', [address]);
    console.log("Balance: ", balance);
  }
}

async function requestWithdrawalFromAppchain(acc_l3: Account) {
  const tokenBridge = getContracts().contracts["TokenBridge_starkgate_contracts"];
  const Bridgecls = await acc_l3.getClassAt(tokenBridge);
  const tokenBridgeContract = new Contract(Bridgecls.abi, tokenBridge, acc_l3);

  const call = tokenBridgeContract.populate('initiate_token_withdraw', {
    l1_token: getContracts().contracts["ERC20_starknet_bridge"],  // l1_token
    l1_recipient: process.env.ACCOUNT_L2_ADDRESS as string, // l1_recipient
    amount: 10n * 10n ** 18n,
  });

  let result = await acc_l3.execute([call], { maxFee: 0 });
  await sleep(4000);
  console.log("Withdrawal request success !!", result);
}

async function withdrawFromStarknet(acc_l2: Account) {
  const coreContract = getContracts().contracts["appchain_starknet_bridge"];
  const cls = await acc_l2.getClassAt(coreContract);
  const coreContractInstance = new Contract(cls.abi, coreContract, acc_l2);
  const call = coreContractInstance.populate('process_message_to_starknet', {});
}

async function setup() {
  const acc_l3 = getAccount(Layer.L3);
  await deployAppchainBridge();
  await deployL2Brdige();

  await configureAppchainBridge(acc_l3);
  await setL2Bridge(acc_l3);
  await declareAndSetERC20L3(acc_l3);

  console.log("Setup completed !!");
}

async function enrollandActivate(acc_l2: Account, token: string = "ERC20_starknet_bridge", deploy: boolean = false) {
  if (deploy) {
    await deployERC20();
  }
  await enrollToken(acc_l2, token);
  await activateToken(acc_l2, token);
}


async function main() {
  const acc_l2 = getAccount(Layer.L2);
  const acc_l3 = getAccount(Layer.L3);
  const acc_l1 = getEthereumClient();

  await deployCoreContract(acc_l2);

  await setup();
  await enrollandActivate(acc_l2, "MyL2GameToken");


  await deposit(acc_l2);
  await getL3Balance(acc_l3.address);

  await depositWithMessageL2toL3(acc_l2);
  await depositWithMessageL1toL3(acc_l1);
  await getGameState(acc_l3);
}

main();
