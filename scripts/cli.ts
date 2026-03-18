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
  setDumpPath,
  calculateConfigHash,
  getContract,
} from "./utils/utils.ts";
import { logger } from "./utils/logger.ts";
import {
  deployAppchainBridge,
  deployL2Bridge,
  configureAppchainBridge,
  setL2Bridge,
  deployERC20,
  declareAndSetERC20L3,
  enrollToken,
  deposit,
  getL3Balance,
  initiateTokenL3toL2Withdrawal,
  deployTimelockContract,
  configurePermissionedEnrollment,
  waitForCorrespondingL3Token,
} from "./bridgeDeploy.ts";
import { Layer, ProgramInfo, FactRegistryOptions, FactRegistryChain, VerificationType } from "./config/types.ts";
import { finalRoles } from "./config/newRoles.ts";
import {
  transferRoles,
  transferAppchainL2Roles,
  transferTimelockL2Roles,
  transferTokenBridgeL2Roles,
  transferTokenBridgeL3Roles,
  renounceRoles,
  renounceTimelockRolesRoles,
  renounceAppchainL2Roles,
  renounceTokenBridgeL2Roles,
  renounceTokenBridgeL3Roles,
  checkRolesPassed,
  checkTokenBridgeL2Roles,
  checkTimelockL2Roles,
  checkAppchainL2Roles,
  checkTokenBridgeL3Roles,
} from "./finalRoleTransfer.ts";
import { executeUpgradeTokenBridgeL2, upgradeAppchain, upgradeTokenBridgeL2 } from "./upgrades.ts";
import { testTokenActions } from "./tokenActions.ts";
import { deployCoreContract, setFactRegistry, setProgramInfo, setUseKzgDa } from "./coreContractSetup.ts";
import { appchainConfig, feeTokenContract } from "./config/constants.ts";
import { deployFeeToken, deployUniversalDeployer } from "./chainEssentials.ts";
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

program
  .command("set-program-info")
  .description("Set the program info for the core contract")
  .option("--bootloader-hash <hash>", "Bootloader program hash")
  .option("--snos-config-hash <hash>", "SNOS config hash (if not provided, will be generated from fee token and chain ID)")
  .option("--snos-program-hash <hash>", "SNOS program hash")
  .option("--layout-bridge-hash <hash>", "Layout bridge program hash")
  .option("--chain-id <chainId>", "Chain ID of the L3 network (required if --snos-config-hash is not provided)")
  .option("--config-hash-version <version>", "Config hash version string (default: StarknetOsConfig2, can be set via CONFIG_HASH_VERSION env var)")
  .action(async (options) => {
    const acc_l2 = getAccount(Layer.L2);
    
    // Get config hash version from env or option, defaulting to "StarknetOsConfig2"
    const configHashVersion = options.configHashVersion || process.env.CONFIG_HASH_VERSION || "StarknetOsConfig2";
    
    // If snos_config_hash is not provided, generate it dynamically
    let snosConfigHash: string;
    if (options.snosConfigHash) {
      snosConfigHash = options.snosConfigHash;
      logger.info("Using provided SNOS config hash");
    } else {
      // Assert that chain ID is provided when snos_config_hash is not provided
      if (!options.chainId) {
        throw new Error("--chain-id must be provided when --snos-config-hash is not specified");
      }
      
      logger.info("Generating SNOS config hash from fee token and chain ID...");
      
      // Get fee token address from deployed contract
      const feeToken = getContract(feeTokenContract);
      if (!feeToken.address) {
        throw new Error("Fee token not deployed. Please deploy the fee token first using 'deploy-fee-token' command.");
      }
      
      // Generate the config hash
      snosConfigHash = calculateConfigHash(
        configHashVersion,
        options.chainId,
        feeToken.address,
      );
    }
    
    const programInfo: ProgramInfo = {
      bootloader_program_hash: options.bootloaderHash || appchainConfig.programInfo.bootloader_program_hash,
      snos_config_hash: snosConfigHash,
      snos_program_hash: options.snosProgramHash || appchainConfig.programInfo.snos_program_hash,
      layout_bridge_program_hash: options.layoutBridgeHash || appchainConfig.programInfo.layout_bridge_program_hash
    };
    await setProgramInfo(acc_l2, programInfo);
  });

program
  .command("set-fact-registry")
  .description("Set the fact registry for the core contract")
  .option("-c, --chain <chain>", "Chain to set the fact registry for, can be SN_MAIN or SN_SEPOLIA", "SN_MAIN")
  .option("-v, --verification-type <verification-type>", "Verification type to set the fact registry for, can be mocked or with_verification", "mocked")
  .action(async (options) => {
    const acc_l2 = getAccount(Layer.L2);
    const factRegistryOptions: FactRegistryOptions = {
      chain: options.chain as FactRegistryChain,
      verificationType: options.verificationType as VerificationType
    };
    await setFactRegistry(acc_l2, factRegistryOptions);
  });

// Deploy Universal Deployer Command
program
  .command("deploy-universal-deployer")
  .description("Deploy the universal deployer to L3")
  .action(async () => {
    await deployUniversalDeployer();
  });

program
  .command("deploy-fee-token")
  .description("Deploy fee token")
  .option("-n, --fee-token-name <name>", "Fee token name", "Native Fee token")
  .option("-s, --fee-token-symbol <symbol>", "Fee token symbol", "FT")
  .option("-d, --fee-token-decimals <decimals>", "Fee token decimals", "18")
  .action(async (options) => {
    await deployFeeToken(options.feeTokenName, options.feeTokenSymbol, parseInt(options.feeTokenDecimals, 10));
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
  .option("-n, --name <name>", "Token name", "Token name")
  .option("-s, --symbol <symbol>", "Token symbol", "TST")
  .option("-d, --decimals <decimals>", "Number of decimals", "18")
  .action(async (options) => {
    await deployERC20(
      options.name,
      options.symbol,
      parseInt(options.decimals, 10)
    );
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
    await initiateTokenL3toL2Withdrawal(acc_l3, amount, options.token);
  });

// Deploy Timelock Contract Command
program
  .command("deploy-timelock")
  .description("Deploy the timelock contract to L2")
  .option("-d, --delay <delay>", "Delay in seconds", "86400")
  .action(async (options) => {
    await deployTimelockContract(Number(options.delay));
  });

// Configure Permissionless Enrollment Command
program
  .command("configure-permissionless-enrollment")
  .argument("<permissioned>", "Configure permissionless enrollment for tokens (true/false)")
  .description("Configure permissionless enrollment for tokens")
  .action(async (permissioned) => {
    const acc_l2 = getAccount(Layer.L2);
    await configurePermissionedEnrollment(acc_l2, Boolean(permissioned));
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

program
  .command("transfer-roles")
  .description("Transfer roles to the new owner")
  .action(async () => {
    const acc_l2 = getAccount(Layer.L2);
    const acc_l3 = getAccount(Layer.L3);
    await transferRoles(acc_l2, acc_l3, finalRoles);
  });

program
  .command("transfer-roles-token-bridge-l2")
  .description("Transfer roles to the new addresses")
  .action(async () => {
    const acc_l2 = getAccount(Layer.L2);
    await transferTokenBridgeL2Roles(acc_l2, finalRoles);
  });

program
  .command("transfer-roles-timelock-l2")
  .description("Transfer roles to the new addresses")
  .action(async () => {
    const acc_l2 = getAccount(Layer.L2);
    await transferTimelockL2Roles(acc_l2, finalRoles);
  });

program
  .command("transfer-roles-appchain-l2")
  .description("Transfer roles to the new addresses")
  .action(async () => {
    const acc_l2 = getAccount(Layer.L2);
    await transferAppchainL2Roles(acc_l2, finalRoles);
  });

program
  .command("transfer-roles-token-bridge-l3")
  .description("Transfer roles to the new addresses")
  .action(async () => {
    const acc_l3 = getAccount(Layer.L3);
    await transferTokenBridgeL3Roles(acc_l3, finalRoles);
  });

program
  .command("check-roles")
  .description("Check roles for the new addresses")
  .action(async () => {
    const acc_l2 = getAccount(Layer.L2);
    const acc_l3 = getAccount(Layer.L3);
    await checkRolesPassed(acc_l2, acc_l3, finalRoles);
  });

program
  .command("check-roles-token-bridge-l2")
  .description("Check roles for the new addresses")
  .action(async () => {
    const acc_l2 = getAccount(Layer.L2);
    await checkTokenBridgeL2Roles(acc_l2, finalRoles);
  });

program
  .command("check-roles-timelock-l2")
  .description("Check roles for the new addresses")
  .action(async () => {
    const acc_l2 = getAccount(Layer.L2);
    await checkTimelockL2Roles(acc_l2, finalRoles);
  });

program
  .command("check-roles-appchain-l2")
  .description("Check roles for the new addresses")
  .action(async () => {
    const acc_l2 = getAccount(Layer.L2);
    await checkAppchainL2Roles(acc_l2, finalRoles);
  });

program
  .command("check-roles-token-bridge-l3")
  .description("Check roles for the new addresses")
  .action(async () => {
    const acc_l3 = getAccount(Layer.L3);
    await checkTokenBridgeL3Roles(acc_l3, finalRoles);
  });

program
  .command("renounce-roles")
  .description("Renounce roles from deployer")
  .action(async () => {
    const acc_l2 = getAccount(Layer.L2);
    const acc_l3 = getAccount(Layer.L3);
    await renounceRoles(acc_l2, acc_l3);
  })

program
  .command("renounce-roles-token-bridge-l2")
  .description("Renounce roles from deployer")
  .action(async () => {
    const acc_l2 = getAccount(Layer.L2);
    await renounceTokenBridgeL2Roles(acc_l2);
  })


program
  .command("renounce-roles-timelock-l2")
  .description("Transfer roles to the new addresses")
  .action(async () => {
    const acc_l2 = getAccount(Layer.L2);
    await renounceTimelockRolesRoles(acc_l2);
  });

program
  .command("renounce-roles-appchain-l2")
  .description("Renounce roles from deployer")
  .action(async () => {
    const acc_l2 = getAccount(Layer.L2);
    await renounceAppchainL2Roles(acc_l2);
  })

program
  .command("renounce-roles-token-bridge-l3")
  .description("Transfer roles to the new addresses")
  .action(async () => {
    const acc_l3 = getAccount(Layer.L3);
    await renounceTokenBridgeL3Roles(acc_l3);
  });

program
  .command("upgrade-appchain")
  .description("Upgrade the appchain")
  .action(async () => {
    const acc_l2 = getAccount(Layer.L2);
    await upgradeAppchain(acc_l2);
  });

program
  .command("set-use-kzg-da")
  .option("-u, --use-kzg-da <useKzgDa>", "Use KZG DA flag", "true")
  .description("Set the use KZG DA flag for the core contract")
  .action(async (options) => {
    const acc_l2 = getAccount(Layer.L2);
    await setUseKzgDa(acc_l2, Boolean(options.useKzgDa));
  });

program
  .command("upgrade-token-bridge-l2")
  .description("Upgrade the token bridge on L2")
  .option("--only-schedule", "Only schedule the upgrade without executing", false)
  .action(async (options) => {
    const acc_l2 = getAccount(Layer.L2);
    await upgradeTokenBridgeL2(acc_l2);
    if (!options.onlySchedule) {
      await executeUpgradeTokenBridgeL2(acc_l2);
    }
  });

program
  .command("execute-bridge-l2-upgrade")
  .description("Execute token bridge upgrade proposal")
  .action(async () => {
    const acc_l2 = getAccount(Layer.L2);
    await executeUpgradeTokenBridgeL2(acc_l2);
  })

program
  .command("token-actions")
  .description("Perform actions on a token")
  .option("-t, --token <token>", "Token name", "ERC20_OZ")
  .action(async (options) => {
    const acc_l2 = getAccount(Layer.L2);
    await testTokenActions(acc_l2, options.token);
  });

// Full flow command
program
  .command("full-flow")
  .description("Run the full flow of operations")
  .option(
    "-e, --with-enroll",
    "To deploy a token and ernroll post the setup",
    false
  )
  .option("-n, --fee-token-name <name>", "Fee token name", "Native Fee token")
  .option("-s, --fee-token-symbol <symbol>", "Fee token symbol", "FT")
  .option("-d, --fee-token-decimals <decimals>", "Fee token decimals", "18")
  .action(async (options) => {
    const acc_l2 = getAccount(Layer.L2);
    const acc_l3 = getAccount(Layer.L3);

    logger.success("Starting full flow setup...");

    // Setup
    logger.info("MAIN STEP 1: Setting up bridges...");

    await deployAppchainBridge();
    // Deploy timelock contract with 0 `min_delay` initially
    await deployTimelockContract(0);
    await deployL2Bridge();
    await deployFeeToken(options.feeTokenName, options.feeTokenSymbol, parseInt(options.feeTokenDecimals, 10));

    logger.info("MAIN STEP 2: Configuring the bridges...");
    await configureAppchainBridge(acc_l3);
    await setL2Bridge(acc_l3);
    await deployUniversalDeployer();
    await declareAndSetERC20L3(acc_l3);

    if (options.withEnroll) {
      // Deploy and enroll token
      logger.info("MAIN STEP 3: Deploying and enrolling token...");
      await deployERC20();
      await enrollToken(acc_l2, "ERC20_OZ");

      // Check the corresponding token and balance
      logger.info(
        "MAIN STEP 4: Check the corresponding token and balance on l3"
      );
      await waitForCorrespondingL3Token("ERC20_OZ");
      await getL3Balance(process.env.ACCOUNT_L3_ADDRESS as string, "ERC20_OZ");
    }

    logger.success("Full flow completed successfully!");
  });

program.parse(process.argv);

// If no command was specified, display help
if (!process.argv.slice(2).length) {
  program.help();
}
