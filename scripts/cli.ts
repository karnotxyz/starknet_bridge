#!/usr/bin/env tsx
import * as dotenv from 'dotenv';
// Load environment variables
dotenv.config({
  path: (process.env.CI || process.env.GITHUB_ACTIONS) ? '.env.ci.test' : '.env',
});

import { Command } from 'commander';
import { checkEnvVars, dumpPath, getAccount, getEthereumClient, Layer, setDumpPath } from './utils.ts';
import { Logger } from './logger.ts';
import {
  deployCoreContract,
  deployAppchainBridge,
  deployL2Brdige,
  configureAppchainBridge,
  setL2Bridge,
  deployERC20,
  declareAndSetERC20L3,
  enrollToken,
  deposit,
  getL3Balance,
  depositWithMessageL1toL3,
  initiateTokenL2toL3Withdrawal
} from './bridgeDeploy.ts';

const program = new Command();

program
  .name('bridge-cli')
  .description('CLI tool for Starknet bridge operations')
  .version('1.0.0')
  .requiredOption('--dump-path <path>', 'Dump path for the script');

program.hook('preAction', (thisCommand, actionCommand) => {
  const options = program.opts()
  setDumpPath(options.dumpPath);
  Logger.info(`Using dump path: ${dumpPath}`)
})

await checkEnvVars();

// Deploy Core Contract Command
program
  .command('deploy-core')
  .description('Deploy the core contract to L2')
  .action(async () => {
    const options = program.opts();
    const acc = getAccount(Layer.L2);
    await deployCoreContract(acc);
  });

// Deploy Appchain Bridge Command
program
  .command('deploy-appchain-bridge')
  .description('Deploy the appchain bridge to L3')
  .action(async () => {
    await deployAppchainBridge();
  });

// Deploy L2 Bridge Command
program
  .command('deploy-l2-bridge')
  .description('Deploy the bridge to L2')
  .action(async () => {
    await deployL2Brdige();
  });

// Configure Appchain Bridge Command
program
  .command('configure-appchain-bridge')
  .description('Configure the appchain bridge')
  .action(async () => {
    const acc_l3 = getAccount(Layer.L3);
    await configureAppchainBridge(acc_l3);
  });

// Set L2 Bridge Command
program
  .command('set-l2-bridge')
  .description('Set the L2 bridge in the appchain bridge')
  .action(async () => {
    const acc_l3 = getAccount(Layer.L3);
    await setL2Bridge(acc_l3);
  });

// Deploy ERC20 Command
program
  .command('deploy-erc20')
  .description('Deploy an ERC20 token to L2')
  .action(async () => {
    await deployERC20();
  });

// Declare And Set ERC20 L3 Command
program
  .command('declare-set-erc20-l3')
  .description('Declare and set ERC20 on L3')
  .action(async () => {
    const acc_l3 = getAccount(Layer.L3);
    await declareAndSetERC20L3(acc_l3);
  });

// Enroll Token Command
program
  .command('enroll-token')
  .description('Enroll a token in the bridge')
  .option('-t, --token <token>', 'Token name', 'ERC20_starknet_bridge')
  .option('-d, --deploy', 'Deploy the token first', false)
  .action(async (options) => {
    const acc_l2 = getAccount(Layer.L2);
    if (options.deploy) {
      await deployERC20();
    }
    await enrollToken(acc_l2, options.token);
  });

// Deposit Command
program
  .command('deposit')
  .description('Deposit tokens from L2 to L3')
  .option('-a, --amount amount', 'Amount of tokens to deposit', '10n * 10n ** 18n')
  .action(async (options) => {
    const acc_l2 = getAccount(Layer.L2);
    await deposit(acc_l2, BigInt(options.amount));
  }); // Get L3 Balance Command program .command('get-l3-balance') .description('Get the L3 balance for an address') .argument('<address>', 'Address to check') .option('-t, --token <token>', 'Token name', 'MyL2GameToken') .action(async (address, options) => { await getL3Balance(address, options.token); });

// Deposit With Message From L1 to L3 Command
program
  .command('deposit-l1-to-l3')
  .description('Deposit tokens from L1 to L3 with a message')
  .option('-t, --token <token>', 'Token name', 'MyL1GameToken')
  .action(async (options) => {
    const acc_l1 = getEthereumClient();
    await depositWithMessageL1toL3(acc_l1, options.token);
  });

// Initiate Withdrawal Command
program
  .command('withdraw-l3-to-l2')
  .description('Initiate a token withdrawal from L3 to L2')
  .option('-a, --amount <amount>', 'Amount to withdraw (in ether)', '10')
  .option('-t, --token <token>', 'Token name', 'L2TestToken')
  .action(async (options) => {
    const acc_l3 = getAccount(Layer.L3);
    const amount = BigInt(options.amount) * 10n ** 18n;
    await initiateTokenL2toL3Withdrawal(acc_l3, amount, options.token);
  });

// Setup Command (Combined operations)
program
  .command('setup')
  .description('Run the full setup process')
  .action(async () => {
    const acc_l3 = getAccount(Layer.L3);
    await declareAndSetERC20L3(acc_l3);
    Logger.success("Setup completed!");
  });

// Full flow command
program
  .command('full-flow')
  .description('Run the full flow of operations')
  .action(async () => {
    const acc_l2 = getAccount(Layer.L2);
    const acc_l3 = getAccount(Layer.L3);

    Logger.step(1, "Starting full flow setup...");

    // Deploy core contract
    Logger.step(2, "Deploying core contract...");
    await deployCoreContract(acc_l2);

    // Setup
    Logger.step(3, "Setting up bridges...");
    await deployAppchainBridge();
    await deployL2Brdige();
    await configureAppchainBridge(acc_l3);
    await setL2Bridge(acc_l3);
    await declareAndSetERC20L3(acc_l3);

    // Deploy and enroll token
    Logger.step(4, "Deploying and enrolling token...");
    await deployERC20();
    await enrollToken(acc_l2, "MyL2GameToken");

    // Deposit and check balance
    Logger.step(5, "Processing deposits and checking balances...");
    await deposit(acc_l2);
    await getL3Balance(acc_l3.address);

    // L1 to L3 deposit
    // Logger.step(6, "Processing L1 to L3 deposit...");
    // const acc_l1 = getEthereumClient();
    // await depositWithMessageL1toL3(acc_l1, "MyL1GameToken");

    // Withdrawal
    // Logger.step(7, "Initiating withdrawal...");
    // await initiateTokenL2toL3Withdrawal(acc_l3, 10n * 10n ** 18n, 'L2TestToken');

    Logger.success("Full flow completed successfully!");
  });

program.parse(process.argv);

// If no command was specified, display help
if (!process.argv.slice(2).length) {
  program.help();
}
