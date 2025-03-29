import { parseAbi, parseEther, WalletClient } from "viem";
import {
  deployContract,
  declareContract,
  getContracts,
  getProvider,
  getAccount,
  getContract,
  setDumpPath
} from "./utils";
import { Layer, Contract, Package } from "./types";
import { Account, byteArray, Contract as StarknetContract, num } from "starknet";
import { sepolia } from "viem/chains";
import { Account as EthAccount } from "viem";
import { Logger } from "./logger";

// Define our packages
const starknetBridgePackage: Package = {
  name: "starknet_bridge",
  base_path: "./target/dev"
};

const starkgatePackage: Package = {
  name: "starkgate_contracts",
  base_path: "./starkgate-contracts/cairo_contracts"
};

// Define all contract instances upfront
const appchainContract: Contract = {
  name: "appchain",
  layer: Layer.L2,
  package: starknetBridgePackage
};

const tokenBridgeL2Contract: Contract = {
  name: "TokenBridge",
  layer: Layer.L2,
  package: starknetBridgePackage
};

const tokenBridgeL3Contract: Contract = {
  name: "TokenBridge",
  layer: Layer.L3,
  package: starkgatePackage
};

const erc20Contract: Contract = {
  name: "ERC20",
  layer: Layer.L2,
  package: starknetBridgePackage
};

const erc20LockableContract: Contract = {
  name: "ERC20Lockable",
  layer: Layer.L3,
  package: starkgatePackage
};

/**
 * Deploy the core contract on Starknet L2
 */
export async function deployCoreContract(acc: Account) {
  await declareContract(appchainContract);
  Logger.success("Appchain core contract declared successfully!");
  
  await deployContract(
    appchainContract,
    [
      acc.address, // owner
      0, // state_root,
      0, // block_number,
      0, // block_hash
    ]
  );

  if (appchainContract.address) {
    Logger.address(
      "Appchain core contract deployed at",
      appchainContract.address
    );
  }
}

/**
 * Deploy the appchain bridge on L3
 */
export async function deployAppchainBridge() {
  await declareContract(tokenBridgeL3Contract);
  Logger.success("TokenBridge declared!");
  
  await deployContract(
    tokenBridgeL3Contract,
    [process.env.ACCOUNT_L3_ADDRESS as string, "10"]
  );
  
  if (tokenBridgeL3Contract.address) {
    Logger.address("AppchainBridge deployed at", tokenBridgeL3Contract.address);
  }
}

/**
 * Deploy the L2 bridge on Starknet
 */
export async function deployL2Bridge() {
  await declareContract(tokenBridgeL2Contract);
  Logger.success("TokenBridge declared!");
  
  // Get the addresses from saved contracts
  const contracts = getContracts();
  const appchainBridge = contracts.contracts["TokenBridge_starkgate_contracts"];
  const appchainContractAddr = contracts.contracts["appchain_starknet_bridge"];
  
  await deployContract(
    tokenBridgeL2Contract,
    [
      appchainBridge,
      appchainContractAddr,
      process.env.ACCOUNT_L2_ADDRESS as string,
    ]
  );
  
  if (tokenBridgeL2Contract.address) {
    Logger.address("TokenBridge L2 deployed at", tokenBridgeL2Contract.address);
  }
}

/**
 * Configure the appchain bridge roles and governance
 */
export async function configureAppchainBridge(acc_l3: Account) {
  const contracts = getContracts();
  const appchainBridge = contracts.contracts["TokenBridge_starkgate_contracts"];
  const cls = await acc_l3.getClassAt(appchainBridge);
  const appchainBridgeContract = new StarknetContract(cls.abi, appchainBridge, acc_l3);

  {
    const call = appchainBridgeContract.populate("register_app_role_admin", {
      account: acc_l3.address,
    });

    const res = await acc_l3.execute([call], {
      maxFee: 0,
      resourceBounds: {
        l1_gas: {
          max_amount: "0x0",
          max_price_per_unit: "0x0",
        },
        l2_gas: {
          max_amount: "0x0",
          max_price_per_unit: "0x0",
        },
      },
    });

    await acc_l3.waitForTransaction(res.transaction_hash);

    Logger.success("App role admin set successfully !!");
    Logger.txHash(res.transaction_hash);
  }

  {
    const call = appchainBridgeContract.populate("register_app_governor", {
      account: acc_l3.address,
    });
    const res = await acc_l3.execute([call], {
      maxFee: 0,
      resourceBounds: {
        l1_gas: {
          max_amount: "0x0",
          max_price_per_unit: "0x0",
        },
        l2_gas: {
          max_amount: "0x0",
          max_price_per_unit: "0x0",
        },
      },
    });

    await acc_l3.waitForTransaction(res.transaction_hash);

    Logger.success("App governor set successfully !!");
    Logger.txHash(res.transaction_hash);
  }

  {
    const call = appchainBridgeContract.populate("set_l2_token_governance", {
      l2_token_governance: acc_l3.address,
    });
    const res = await acc_l3.execute([call], {
      maxFee: 0,
      resourceBounds: {
        l1_gas: {
          max_amount: "0x0",
          max_price_per_unit: "0x0",
        },
        l2_gas: {
          max_amount: "0x0",
          max_price_per_unit: "0x0",
        },
      },
    });
    await acc_l3.waitForTransaction(res.transaction_hash);
    Logger.success("L2 Governance set successfully !!");
    Logger.txHash(res.transaction_hash);
  }
}

/**
 * Set the L2 bridge in the appchain bridge contract
 */
export async function setL2Bridge(acc_l3: Account) {
  const contracts = getContracts();
  const tokenBridge = contracts.contracts["TokenBridge_starknet_bridge"];
  const appchainBridge = contracts.contracts["TokenBridge_starkgate_contracts"];
  const cls = await acc_l3.getClassAt(appchainBridge);
  const appchainBridgeContract = new StarknetContract(cls.abi, appchainBridge, acc_l3);

  {
    const call = appchainBridgeContract.populate("set_l1_bridge", {
      l1_bridge_address: tokenBridge,
    });
    const res = await acc_l3.execute([call], {
      maxFee: 0,
      resourceBounds: {
        l1_gas: {
          max_amount: "0x0",
          max_price_per_unit: "0x0",
        },
        l2_gas: {
          max_amount: "0x0",
          max_price_per_unit: "0x0",
        },
      },
    });

    await acc_l3.waitForTransaction(res.transaction_hash);
    Logger.success("L2 bridge set successfully !!");
    Logger.txHash(res.transaction_hash);
  }
}

/**
 * Deploy an ERC20 token on L2
 */
export async function deployERC20() {
  await declareContract(erc20Contract);
  Logger.success("ERC20 declared!");
  
  await deployContract(
    erc20Contract,
    [
      byteArray.byteArrayFromString("My token name"), // name
      byteArray.byteArrayFromString("MTK"), // symbol
      18, // decimals
      10000n * 10n ** 18n, // initial_supply
      0,
      process.env.ACCOUNT_L2_ADDRESS as string, // initia_recepient
      process.env.ACCOUNT_L2_ADDRESS as string, // l2_token_governance
      process.env.ACCOUNT_L2_ADDRESS as string, // permitted_minter
      0, // upgrade delay
    ]
  );
  
  if (erc20Contract.address) {
    Logger.address("ERC20 deployed at", erc20Contract.address);
  }
}

/**
 * Declare and set ERC20 token on L3
 */
export async function declareAndSetERC20L3(acc_l3: Account) {
  await declareContract(erc20LockableContract);
  Logger.success("ERC20 declared!");
  
  const contracts = getContracts();
  const l3Bridge = contracts.contracts["TokenBridge_starkgate_contracts"];
  const cls = await acc_l3.getClassAt(l3Bridge);
  const l3BridgeContract = new StarknetContract(cls.abi, l3Bridge, acc_l3);

  let acc = getAccount(Layer.L3);

  {
    const class_hash = erc20LockableContract.classHash;
    if (!class_hash) {
      throw new Error("ERC20Lockable class hash not found");
    }
    
    const call = l3BridgeContract.populate("set_erc20_class_hash", {
      erc20_class_hash: class_hash,
    });
    
    let result = await acc.execute([call], {
      maxFee: 0,
      resourceBounds: {
        l1_gas: {
          max_price_per_unit: "0x1",
          max_amount: "0x0",
        },
        l2_gas: {
          max_price_per_unit: "0x0",
          max_amount: "0x0",
        },
      },
    });
    await acc.waitForTransaction(result.transaction_hash);
    Logger.success("ERC20 class_hash set successfully!");
    Logger.txHash(result.transaction_hash);
  }
}

export async function enrollToken(
  acc_l2: Account,
  token: string = "ERC20_starknet_bridge"
) {
  const contracts = getContracts();
  const tokenAddress = contracts.contracts[token];
  const tokenBridge = contracts.contracts["TokenBridge_starknet_bridge"];

  const cls = await acc_l2.getClassAt(tokenBridge);
  const tokenBridgeContract = new StarknetContract(cls.abi, tokenBridge, acc_l2);

  const call = tokenBridgeContract.populate("enroll_token", {
    token: tokenAddress,
  });
  let result = await acc_l2.execute([call]);
  await acc_l2.waitForTransaction(result.transaction_hash);
  Logger.success("Token enrolled successfully!");
  Logger.txHash(result.transaction_hash);
}

/**
 * Deposit tokens from L2 to L3
 */
export async function deposit(
  acc_l2: Account,
  amount: bigint = 10n * 10n ** 18n
) {
  const contracts = getContracts();
  const tokenAddress = contracts.contracts["ERC20_starknet_bridge"];
  const tokenBridge = contracts.contracts["TokenBridge_starknet_bridge"];

  // Approval
  {
    const tokenCls = await acc_l2.getClassAt(tokenAddress);
    const token = new StarknetContract(tokenCls.abi, tokenAddress, acc_l2);

    const call = token.populate("approve", {
      spender: tokenBridge,
      amount,
    });
    let result = await acc_l2.execute([call]);
    await acc_l2.waitForTransaction(result.transaction_hash);
    Logger.success("Approval success!");
    Logger.txHash(result.transaction_hash);
  }

  // Deposit
  {
    const Bridgecls = await acc_l2.getClassAt(tokenBridge);
    const tokenBridgeContract = new StarknetContract(
      Bridgecls.abi,
      tokenBridge,
      acc_l2
    );

    const call = tokenBridgeContract.populate("deposit", {
      token: tokenAddress,
      amount,
      appchain_recipient: process.env.ACCOUNT_L3_ADDRESS as string,
      message: 0,
    });
    let result = await acc_l2.execute([call]);

    await acc_l2.waitForTransaction(result.transaction_hash);
    Logger.success("Deposit success!");
    Logger.txHash(result.transaction_hash);
  }
}

export async function getL3Balance(
  address: string,
  token: string = "ERC20_starknet_bridge"
) {
  const contracts = getContracts();
  const enrolledTokenAddress = contracts.contracts[token];
  const appchainBridge = contracts.contracts["TokenBridge_starkgate_contracts"];
  const providerL3 = getProvider(Layer.L3);

  const appchainBridgeCls = await providerL3.getClassAt(appchainBridge);
  const appchainBridgeContract = new StarknetContract(
    appchainBridgeCls.abi,
    appchainBridge,
    providerL3
  );

  const correspondingToken = await appchainBridgeContract.call("get_l2_token", [
    enrolledTokenAddress,
  ]);
  Logger.info(`Finding corresponding appchain token`);

  if (correspondingToken != 0n) {
    Logger.error("No corresponding token found on l3");
    throw new Error("No corresponding token found on l3 ");
  }

  const correspondingTokenAddress = num.toHex(correspondingToken as any);
  Logger.address(
    "Corresponding appchain token address",
    correspondingTokenAddress
  );
  const appchainTokenCls = await providerL3.getClassAt(
    correspondingTokenAddress
  );
  const appchainToken = new StarknetContract(
    appchainTokenCls.abi,
    correspondingTokenAddress,
    providerL3
  );
  const balance = await appchainToken.call("balanceOf", [address]);
  Logger.info(`Balance: ${balance}`);
}

/**
 * Initiate a token withdrawal from L3 to L2
 */
export async function initiateTokenL2toL3Withdrawal(
  acc_l3: Account,
  amount: BigInt,
  l2_token: string
) {
  const contracts = getContracts();
  let tokenBridge_l3 = contracts.contracts["TokenBridge_starkgate_contracts"];
  let cls = await acc_l3.getClassAt(tokenBridge_l3);
  let tokenBridgeContract_l3 = new StarknetContract(cls.abi, tokenBridge_l3, acc_l3);

  const initiateWithdrawalCall = tokenBridgeContract_l3.populate(
    "initiate_token_withdraw",
    {
      // the function arg is called the l1_token, but you have to provide l2_token
      // this is since we are reappropriated the starkgate `token_bridge.cario`
      //  to be used in l2-l3 bridge
      l1_token: contracts.contracts[l2_token],
      l1_recipient: process.env.ACCOUNT_L2_ADDRESS as string,
      amount,
    }
  );

  let tx = await acc_l3.execute([initiateWithdrawalCall]);
  await acc_l3.waitForTransaction(tx.transaction_hash);
  Logger.success("Withdrawal initiated successfully!");
  Logger.txHash(tx.transaction_hash);
}

/**
 * Setup the bridge
 */
export async function setup() {
  // Set the dump path for contract information
  setDumpPath("./bridge_contracts.json");
  
  const acc_l3 = getAccount(Layer.L3);
  await deployAppchainBridge();
  await deployL2Bridge();

  await configureAppchainBridge(acc_l3);
  await setL2Bridge(acc_l3);
  await declareAndSetERC20L3(acc_l3);

  Logger.success("Setup completed!");
}

/**
 * Enroll a token in the bridge
 */
export async function enroll(
  acc_l2: Account,
  token: string = "ERC20_starknet_bridge",
  deploy: boolean = false
) {
  if (deploy) {
    await deployERC20();
  }
  await enrollToken(acc_l2, token);
}
