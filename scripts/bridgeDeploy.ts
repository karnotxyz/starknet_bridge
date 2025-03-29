import { parseAbi, parseEther, WalletClient } from "viem";
import {
  deployContract,
  declareContract,
  getContracts,
  getProvider,
  Layer,
  getAccount,
} from "./utils";
import { Account, byteArray, Contract, num } from "starknet";
import { sepolia } from "viem/chains";
import { Account as EthAccount } from "viem";
import { Logger } from "./logger";

/**
 * Deploy the core contract on Starknet L2
 */
export async function deployCoreContract(acc: Account) {
  await declareContract("appchain", "starknet_bridge", Layer.L2);
  Logger.success("Appchain core contract declared successfully!");
  const class_hash = await getContracts().class_hashes[
    "appchain_starknet_bridge"
  ];
  const contract = await deployContract(
    "appchain_starknet_bridge",
    class_hash,
    [
      acc.address, // owner
      0, // state_root,
      0, // block_number,
      0, // block_hash
    ],
    Layer.L2
  );

  if (contract.address) {
    Logger.address(
      "Appchain core contract deployed at",
      contract.address as string
    );
  }
}

/**
 * Deploy the appchain bridge on L3
 */
export async function deployAppchainBridge() {
  await declareContract(
    "TokenBridge",
    "starkgate_contracts",
    Layer.L3,
    "./starkgate-contracts/cairo_contracts"
  );
  Logger.success("TokenBridge declared!");
  const class_hash = await getContracts().class_hashes[
    "TokenBridge_starkgate_contracts"
  ];
  const contract = await deployContract(
    "TokenBridge_starkgate_contracts",
    class_hash,
    [process.env.ACCOUNT_L3_ADDRESS as string, "10"],
    Layer.L3
  );
  if (contract.address) {
    Logger.address("AppchainBridge deployed at", contract.address as string);
  }
}

/**
 * Deploy the L2 bridge on Starknet
 */
export async function deployL2Brdige() {
  // await declareContract("TokenBridge", "starknet_bridge", Layer.L2);
  Logger.success("TokenBridge declared!");
  const saved_class_hash = await getContracts().class_hashes[
    "TokenBridge_starknet_bridge"
  ];
  const appchainBridge =
    getContracts().contracts["TokenBridge_starkgate_contracts"];
  const appchainContract = getContracts().contracts["appchain_starknet_bridge"];
  const contract = await deployContract(
    "TokenBridge_starknet_bridge",
    saved_class_hash,
    [
      appchainBridge,
      appchainContract,
      process.env.ACCOUNT_L2_ADDRESS as string,
    ],
    Layer.L2
  );
  if (contract.address) {
    Logger.address("TokenBridge L2 deployed at", contract.address as string);
  }
}

/**
 * Configure the appchain bridge roles and governance
 */
export async function configureAppchainBridge(acc_l3: Account) {
  const appchainBridge =
    getContracts().contracts["TokenBridge_starkgate_contracts"];
  const cls = await acc_l3.getClassAt(appchainBridge);
  const appchainBridgeContract = new Contract(cls.abi, appchainBridge, acc_l3);

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

    Logger.txHash(res.transaction_hash);
    Logger.success("App role admin set successfully !!");

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
    Logger.txHash(res.transaction_hash);
    Logger.success("L2 Governance set successfully !!");
  }
}

/**
 * Set the L2 bridge in the appchain bridge contract
 */
export async function setL2Bridge(acc_l3: Account) {
  const tokenBridge = getContracts().contracts["TokenBridge_starknet_bridge"];
  const appchainBridge =
    getContracts().contracts["TokenBridge_starkgate_contracts"];
  const cls = await acc_l3.getClassAt(appchainBridge);
  const appchainBridgeContract = new Contract(cls.abi, appchainBridge, acc_l3);

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
    Logger.txHash(res.transaction_hash);
    Logger.success("L2 bridge set successfully !!");
  }
}

/**
 * Deploy an ERC20 token on L2
 */
export async function deployERC20() {
  await declareContract("ERC20", "starknet_bridge", Layer.L2);
  const saved_class_hash = await getContracts().class_hashes[
    "ERC20_starknet_bridge"
  ];
  const contract = await deployContract(
    "ERC20_starknet_bridge",
    saved_class_hash,
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
    ],
    Layer.L2
  );
  if (contract.address) {
    Logger.address("ERC20 deployed at", contract.address as string);
  }
}

/**
 * Declare and set ERC20 token on L3
 */
export async function declareAndSetERC20L3(acc_l3: Account) {
  await declareContract("ERC20Lockable", "starkgate_contracts", Layer.L3, "./starkgate-contracts/cairo_contracts");
  // await declareContract("ERC20", "starknet_contracts", Layer.L3);
  Logger.success("ERC20 declared!");
  const l3Bridge = getContracts().contracts["TokenBridge_starkgate_contracts"];
  const cls = await acc_l3.getClassAt(l3Bridge);
  const l3BridgeContract = new Contract(cls.abi, l3Bridge, acc_l3);

  let acc = getAccount(Layer.L3);

  {
    const class_hash = await getContracts().class_hashes[
      "ERC20Lockable_starkgate_contracts"
    ];
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
  token: string = "L2TestToken"
) {
  const tokenAddress = getContracts().contracts[token];
  const tokenBridge = getContracts().contracts["TokenBridge_starknet_bridge"];

  const cls = await acc_l2.getClassAt(tokenBridge);
  const tokenBridgeContract = new Contract(cls.abi, tokenBridge, acc_l2);

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
  const tokenAddress = getContracts().contracts["ERC20_starknet_bridge"];
  const tokenBridge = getContracts().contracts["TokenBridge_starknet_bridge"];

  // Approval
  {
    const tokenCls = await acc_l2.getClassAt(tokenAddress);
    const token = new Contract(tokenCls.abi, tokenAddress, acc_l2);

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
    const tokenBridgeContract = new Contract(
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
  token: string = "L2TestToken"
) {
  const enrolledTokenAddress = getContracts().contracts[token];
  const appchainBridge =
    getContracts().contracts["TokenBridge_starkgate_contracts"];
  const providerL3 = getProvider(Layer.L3);

  const appchainBridgeCls = await providerL3.getClassAt(appchainBridge);
  const appchainBridgeContract = new Contract(
    appchainBridgeCls.abi,
    appchainBridge,
    providerL3
  );

  const correspondingToken = await appchainBridgeContract.call("get_l2_token", [
    enrolledTokenAddress,
  ]);
  Logger.info(`Finding corresponding appchain token`);

  if (correspondingToken != 0n) {
    const correspondingTokenAddress = num.toHex(correspondingToken as any);
    Logger.address(
      "Corresponding appchain token address",
      correspondingTokenAddress
    );
    const appchainTokenCls = await providerL3.getClassAt(
      correspondingTokenAddress
    );
    const appchainToken = new Contract(
      appchainTokenCls.abi,
      correspondingTokenAddress,
      providerL3
    );
    const balance = await appchainToken.call("balanceOf", [address]);
    Logger.info(`Balance: ${balance}`);
  }
}

/**
 * Deposit tokens from L1 to L3 with a message
 */
export async function depositWithMessageL1toL3(
  acc_l1: WalletClient,
  token: string = "L1TestToken"
) {
  const testToken = getContracts().contracts[token];
  const tokenBridge = getContracts().contracts["L1TokenBridge"];

  // Approval
  {
    const tokenAbi = parseAbi([
      "function approve(address spender, uint256 amount) returns (bool)",
    ]);

    const approveTx = await acc_l1.writeContract({
      address: testToken,
      abi: tokenAbi,
      functionName: "approve",
      args: [tokenBridge, 10n ** 15n],
      chain: sepolia,
      account: acc_l1.account as EthAccount,
    });

    Logger.txHash(approveTx);
  }

  // Deposit
  {
    const depositAbi = parseAbi([
      "function deposit(address token, uint256 amount, uint256 l2Recipient) external payable",
    ]);

    const depositTx = await acc_l1.writeContract({
      address: tokenBridge,
      abi: depositAbi,
      functionName: "deposit",
      args: [
        testToken,
        1n ** 15n,
        BigInt(
          "0x0463A5a7D814c754E6C3c10f9De8024B2bdF20eb56aD5168076636A858402D7e"
        ),
      ],
      value: parseEther("0.01"),
      account: acc_l1.account as EthAccount,
      chain: sepolia,
    });

    Logger.txHash(depositTx);
  }
}

/**
 * Initiate a token withdrawal from L3 to L2
 */
export async function initiateTokenL2toL3Withdrawal(
  acc_l3: Account,
  amount: BigInt,
  l2_token: string
) {
  let tokenBridge_l3 =
    getContracts().contracts["TokenBridge_starkgate_contracts"];
  let cls = await acc_l3.getClassAt(tokenBridge_l3);
  let tokenBridgeContract_l3 = new Contract(cls.abi, tokenBridge_l3, acc_l3);

  const initiateWithdrawalCall = tokenBridgeContract_l3.populate(
    "initiate_token_withdraw",
    {
      // the function arg is called the l1_token, but you have to provide l2_token
      // this is since we are reappropriated the starkgate `token_bridge.cario`
      //  to be used in l2-l3 bridge
      l1_token: getContracts().contracts[l2_token],
      l1_recipient: process.env.ACCOUNT_L2_ADDRESS as string,
      amount,
    }
  );

  let tx = await acc_l3.execute([initiateWithdrawalCall]);
  Logger.txHash(tx.transaction_hash);
}

async function setup() {
  const acc_l3 = getAccount(Layer.L3);
  await deployAppchainBridge();
  await deployL2Brdige();

  await configureAppchainBridge(acc_l3);
  await setL2Bridge(acc_l3);
  await declareAndSetERC20L3(acc_l3);

  Logger.success("Setup completed!");
}

export async function enroll(
  acc_l2: Account,
  token: string = "L1TestToken",
  deploy: boolean = false
) {
  if (deploy) {
    await deployERC20();
  }
  await enrollToken(acc_l2, token);
}
