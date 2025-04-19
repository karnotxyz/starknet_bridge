#!/usr/bin/env tsx
import * as dotenv from "dotenv";
// Load environment variables
dotenv.config({
  path:
    process.env.CI || process.env.CI == "true" || process.env.GITHUB_ACTIONS
      ? ".env.ci.test"
      : ".env",
  override: true,
});

import { Command } from "commander";
import {
  checkEnvVars,
  dumpPath,
  getAccount,
  getEthereumClient,
  setDumpPath,
  sleep,
} from "./utils/utils.ts";
import { logger } from "./utils/logger.ts";
import {
  deployCoreContract,
  deployAppchainBridge,
  deployL2Bridge,
  configureAppchainBridge,
  setL2Bridge,
  deployERC20,
  declareAndSetERC20L3,
  enrollToken,
  deposit,
  getL3Balance,
  initiateTokenL2toL3Withdrawal,
  deployTimelockContract,
} from "./bridgeDeploy.ts";
import {
  Layer
} from "./config/types.ts"
import { finalRoles } from "./config/finalRoles.ts";
import { transferRoles, transferAppchainL2Roles, transferTimelockL2Roles, transferTokenBridgeL2Roles, transferTokenBridgeL3Roles } from "./finalRoleTransfer.ts";
import { upgradeAppchain } from "./upgrades.ts";
const program = new Command();

program
  .name("bridge-cli")
  .description("CLI tool for Starknet bridge operations")
  .version("1.0.0")
  .requiredOption("--dump-path <path>", "Dump path for the script");

program.hook("preAction", (thisCommand, actionCommand) => {
  const options = program.opts();
  setDumpPath(options.dumpPath);
  logger.info(`Using dump path: ${dumpPath}`);
});

await checkEnvVars();

// Deploy Core Contract Command
program
  .command("deploy-core")
  .description("Deploy the core contract to L2")
  .action(async () => {
    const acc = getAccount(Layer.L2);
    await deployCoreContract(acc);
  });

// Deploy Appchain Bridge Command
program
  .command("deploy-appchain-bridge")
  .description("Deploy the appchain bridge to L3")
  .action(async () => {
    await deployAppchainBridge();
  });

// Deploy L2 Bridge Command
program
  .command("deploy-l2-bridge")
  .description("Deploy the bridge to L2")
  .action(async () => {
    await deployL2Bridge();
  });

// Configure Appchain Bridge Command
program
  .command("configure-appchain-bridge")
  .description("Configure the appchain bridge")
  .action(async () => {
    const acc_l3 = getAccount(Layer.L3);
    await configureAppchainBridge(acc_l3);
  });

// Set L2 Bridge Command
program
  .command("set-l2-bridge")
  .description("Set the L2 bridge in the appchain bridge")
  .action(async () => {
    const acc_l3 = getAccount(Layer.L3);
    await setL2Bridge(acc_l3);
  });

// Deploy ERC20 Command
program
  .command("deploy-erc20")
  .description("Deploy an ERC20 token to L2")
  .action(async () => {
    await deployERC20();
  });

// Declare And Set ERC20 L3 Command
program
  .command("declare-set-erc20-l3")
  .description("Declare and set ERC20 on L3")
  .action(async () => {
    const acc_l3 = getAccount(Layer.L3);
    await declareAndSetERC20L3(acc_l3);
  });

// Enroll Token Command
program
  .command("enroll-token")
  .description("Enroll a token in the bridge")
  .option("-t, --token <token>", "Token name", "L2TestToken")
  .option("-d, --deploy", "Deploy the token first", false)
  .action(async (options) => {
    const acc_l2 = getAccount(Layer.L2);
    if (options.deploy) {
      await deployERC20();
    }
    await enrollToken(acc_l2, options.token);
  });

// Deposit Command
program
  .command("deposit")
  .description("Deposit tokens from L2 to L3")
  .option("-t, --token <token>", "Token name", "ERC20_starknet_bridge")
  .option(
    "-a, --amount <amount>",
    "Amount of tokens to deposit",
    "10n * 10n ** 18n"
  )
  .action(async (options) => {
    const acc_l2 = getAccount(Layer.L2);
    await deposit(acc_l2, options.token, BigInt(options.amount));
  });

// Get L3 Balance Command
program
  .command("get-l3-balance")
  .description("Get the L3 balance for an address")
  .argument("<address>", "Address to check")
  .option("-t, --token <token>", "Token name", "ERC20")
  .action(async (address, options) => {
    await getL3Balance(address, options.token);
  });

// Initiate Withdrawal Command
program
  .command("withdraw-l3-to-l2")
  .description("Initiate a token withdrawal from L3 to L2")
  .option("-a, --amount <amount>", "Amount to withdraw (in ether)", "10")
  .option("-t, --token <token>", "Token name", "L2TestToken")
  .action(async (options) => {
    const acc_l3 = getAccount(Layer.L3);
    const amount = BigInt(options.amount) * 10n ** 18n;
    await initiateTokenL2toL3Withdrawal(acc_l3, amount, options.token);
  });

// Deploy Timelock Contract Command
program
  .command("deploy-timelock")
  .description("Deploy the timelock contract to L2")
  .option("-d, --delay <delay>", "Delay in seconds", "86400")
  .action(async (options) => {
    await deployTimelockContract(Number(options.delay));
  });

// Setup Command (Combined operations)
program
  .command("setup")
  .description("Run the full setup process")
  .action(async () => {
    const acc_l3 = getAccount(Layer.L3);
    await declareAndSetERC20L3(acc_l3);
    logger.success("Setup completed!");
  });


program.command("transfer-roles")
  .description("Transfer roles to the new owner")
  .action(async () => {
    const acc_l2 = getAccount(Layer.L2);
    const acc_l3 = getAccount(Layer.L3);
    await transferRoles(acc_l2, acc_l3, finalRoles);
  });

program.command("transfer-roles-token-bridge-l2")
  .description("Transfer roles to the new owner")
  .action(async () => {
    const acc_l2 = getAccount(Layer.L2);
    await transferTokenBridgeL2Roles(acc_l2, finalRoles);
  });

program.command("transfer-roles-timelock-l2")
  .description("Transfer roles to the new owner")
  .action(async () => {
    const acc_l2 = getAccount(Layer.L2);
    await transferTimelockL2Roles(acc_l2, finalRoles);
  });

program.command("transfer-roles-appchain-l2")
  .description("Transfer roles to the new owner")
  .action(async () => {
    const acc_l2 = getAccount(Layer.L2);
    await transferAppchainL2Roles(acc_l2, finalRoles);
  }); 

program.command("transfer-roles-token-bridge-l3")
  .description("Transfer roles to the new owner")
  .action(async () => {
    const acc_l3 = getAccount(Layer.L3);
    await transferTokenBridgeL3Roles(acc_l3, finalRoles);
  });

program.command("upgrade-appchain")
  .description("Upgrade the appchain")
  .action(async () => {
    const acc_l2 = getAccount(Layer.L2);
    await upgradeAppchain(acc_l2);
  });

// Full flow command
program
  .command("full-flow")
  .description("Run the full flow of operations")
  .action(async () => {
    const acc_l2 = getAccount(Layer.L2);
    const acc_l3 = getAccount(Layer.L3);

    logger.success("Starting full flow setup...");

    // Setup
     logger.info("MAIN STEP 1: Setting up bridges...");
    await deployAppchainBridge();
    // Deploy timelock contract with 0 `min_delay` initially
    await deployTimelockContract(0);
    await deployL2Bridge();

    logger.info("MAIN STEP 2: Configuring the bridges...");
    await configureAppchainBridge(acc_l3);
    await setL2Bridge(acc_l3);
    await declareAndSetERC20L3(acc_l3);

    // Deploy and enroll token
    logger.info("MAIN STEP 3: Deploying and enrolling token...");
    await deployERC20();
    await enrollToken(acc_l2, "ERC20_OZ");

    // Check the corresponding token and balance
    logger.info("MAIN STEP 4: Check the corresponding token and balance on l3");
    await sleep(20000);
    await getL3Balance(
      process.env.ACCOUNT_L3_ADDRESS as string,
      "ERC20_OZ"
    );

    logger.info("MAIN STEP 5: Upgrading appchain...");
    await upgradeAppchain(acc_l2);

    logger.info("MAIN STEP 6: Transferring roles...");
    await transferRoles(acc_l2, acc_l3, finalRoles);

    logger.success("Full flow completed successfully!");
  });

program.parse(process.argv);

// If no command was specified, display help
if (!process.argv.slice(2).length) {
  program.help();
}
