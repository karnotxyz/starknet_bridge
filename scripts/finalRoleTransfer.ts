import { Account, Contract } from "starknet";
import { getContract } from "./utils/utils";
import { logger } from "./utils/logger";
import { appchainContract, timelockContract, tokenBridgeL2Contract, tokenBridgeL3Contract } from "./config/constants";
import { FinalRoles, L2TokenBridgeRoleIds, TimelockControllerRoleIds } from "./config/types";

async function grantRoleRevokeSelf(acc_l2: Account, contract: Contract, role: L2TokenBridgeRoleIds | TimelockControllerRoleIds, address: string[] | string) {
  if (Array.isArray(address)) {
    logger.info(`SUB-STEP 1: Granting role ${role} to multiple addresses`);
    logger.address("Target addresses", address.join(', '));

    for (const addr of address) {
      const call = contract.populate("grant_role", [role, addr]);
      let tx = await acc_l2.execute([call]);
      await acc_l2.waitForTransaction(tx.transaction_hash);
      logger.txHash(tx.transaction_hash);
      logger.success(`Granted role ${role} to address ${addr}`);
    }
  } else {
    logger.info(`SUB-STEP 1: Granting role ${role} to address`);
    logger.address("Target address", address);

    const call = contract.populate("grant_role", [role, address]);
    let tx = await acc_l2.execute([call]);
    await acc_l2.waitForTransaction(tx.transaction_hash);
    logger.txHash(tx.transaction_hash);
    logger.success(`Granted role ${role} to address ${address}`);
  }

  logger.info(`SUB-STEP 2: Revoking role ${role} from self`);
  logger.address("Self address", acc_l2.address);

  const call = contract.populate("renounce_role", [role, acc_l2.address]);
  let tx = await acc_l2.execute([call]);
  await acc_l2.waitForTransaction(tx.transaction_hash);
  logger.txHash(tx.transaction_hash);
  logger.success(`Revoked role ${role} from self`);
}

async function changeRoleWithMethod(acc_l3: Account, contract: Contract, address: string[] | string, method: string) {
  if (Array.isArray(address)) {
    logger.info(`SUB-STEP 1: Executing ${method} for multiple addresses`);
    logger.address("Target addresses", address.join(', '));

    for (const addr of address) {
      const call = contract.populate(method, [addr]);
      let tx = await acc_l3.execute([call]);
      await acc_l3.waitForTransaction(tx.transaction_hash);
      logger.txHash(tx.transaction_hash);
      logger.success(`Executed ${method} for address ${addr}`);
    }
  } else {
    logger.info(`SUB-STEP 1: Executing ${method} for address`);
    logger.address("Target address", address);

    const call = contract.populate(method, [address]);
    let tx = await acc_l3.execute([call]);
    await acc_l3.waitForTransaction(tx.transaction_hash);
    logger.txHash(tx.transaction_hash);
    logger.success(`Executed ${method} for address ${address}`);
  }
}

export async function transferTokenBridgeL2Roles(acc_l2: Account, finalRoles: FinalRoles) {
  logger.info('ROLE TRANSFER STEP 1: Configuring L2 Token Bridge Roles');
  let tokenBridgeL2 = getContract(tokenBridgeL2Contract);
  if (!tokenBridgeL2.address) {
    const error = "L2 Bridge contract address not found";
    logger.error(error);
    throw new Error(error);
  }
  logger.address("L2 Bridge contract", tokenBridgeL2.address);

  let tokenBridgeCls = await acc_l2.getClassAt(tokenBridgeL2.address);
  let tokenBridgeContract_l2 = new Contract(tokenBridgeCls.abi, tokenBridgeL2.address, acc_l2);

  const l2Roles_TokenBridge = finalRoles.l2.TokenBridge;

  await grantRoleRevokeSelf(acc_l2, tokenBridgeContract_l2, L2TokenBridgeRoleIds.TOKEN_ADMIN, l2Roles_TokenBridge.TOKEN_ADMIN);
  await grantRoleRevokeSelf(acc_l2, tokenBridgeContract_l2, L2TokenBridgeRoleIds.SECURITY_AGENT, l2Roles_TokenBridge.SECURITY_AGENT);
  await grantRoleRevokeSelf(acc_l2, tokenBridgeContract_l2, L2TokenBridgeRoleIds.APP_GOVERNOR, l2Roles_TokenBridge.APP_GOVERNOR);
  await grantRoleRevokeSelf(acc_l2, tokenBridgeContract_l2, L2TokenBridgeRoleIds.SECURITY_ADMIN, l2Roles_TokenBridge.SECURITY_ADMIN);
  await grantRoleRevokeSelf(acc_l2, tokenBridgeContract_l2, L2TokenBridgeRoleIds.GOVERNANCE_ADMIN, l2Roles_TokenBridge.GOVERNANCE_ADMIN);
}

export async function transferTimelockL2Roles(acc_l2: Account, finalRoles: FinalRoles) {
  // L2 Timelock
  logger.info('ROLE TRANSFER STEP 2: Configuring L2 Timelock Controller Roles');
  let timelock = getContract(timelockContract);
  if (!timelock.address) {
    const error = "Timelock contract address not found";
    logger.error(error);
    throw new Error(error);
  }
  logger.address("Timelock contract", timelock.address);

  let timelockCls = await acc_l2.getClassAt(timelock.address);
  let timelockContract_l2 = new Contract(timelockCls.abi, timelock.address, acc_l2);

  const l2Roles_TimelockController = finalRoles.l2.TimelockController_starknet_bridge;
  await grantRoleRevokeSelf(acc_l2, timelockContract_l2, TimelockControllerRoleIds.PROPOSER_ROLE, l2Roles_TimelockController.PROPOSER_ROLE);
  await grantRoleRevokeSelf(acc_l2, timelockContract_l2, TimelockControllerRoleIds.EXECUTOR_ROLE, l2Roles_TimelockController.EXECUTOR_ROLE);
  await grantRoleRevokeSelf(acc_l2, timelockContract_l2, TimelockControllerRoleIds.CANCELLER_ROLE, l2Roles_TimelockController.CANCELLER_ROLE);
  await grantRoleRevokeSelf(acc_l2, timelockContract_l2, TimelockControllerRoleIds.DEFAULT_ADMIN, l2Roles_TimelockController[TimelockControllerRoleIds.DEFAULT_ADMIN]);

}

export async function transferAppchainL2Roles(acc_l2: Account, finalRoles: FinalRoles) {
  // L2 Appchain
  logger.info('ROLE TRANSFER STEP 3: Configuring L2 Appchain Roles');
  const appchain = getContract(appchainContract);
  if (!appchain.address) {
    const error = "Appchain contract address not found";
    logger.error(error);
    throw new Error(error);
  }
  logger.address("Appchain contract", appchain.address);

  let appchainCls = await acc_l2.getClassAt(appchain.address);
  let appchainContract_l2 = new Contract(appchainCls.abi, appchain.address, acc_l2);

  const l2Roles_Appchain = finalRoles.l2.appchain;
  await changeRoleWithMethod(acc_l2, appchainContract_l2, l2Roles_Appchain.operators, "register_operator");
  await changeRoleWithMethod(acc_l2, appchainContract_l2, acc_l2.address, "register_operator");
  await changeRoleWithMethod(acc_l2, appchainContract_l2, acc_l2.address, "unregister_operator");
  {
    logger.info("SUB-STEP 1: Transferring Appchain ownership to new owner");
    const call = appchainContract_l2.populate("transfer_ownership", [l2Roles_Appchain.owner]);
    let tx = await acc_l2.execute([call]);
    logger.txHash(tx.transaction_hash);
    await acc_l2.waitForTransaction(tx.transaction_hash);
    logger.success("Ownership transferred to new owner");
  }
}

export async function transferTokenBridgeL3Roles(acc_l3: Account, finalRoles: FinalRoles) {
  // L3 Token Bridge
  logger.info('ROLE TRANSFER STEP 4: Configuring L3 Token Bridge Roles');
  const l3_tokenBridge = getContract(tokenBridgeL3Contract);
  if (!l3_tokenBridge.address) {
    const error = "L3 Bridge contract address not found";
    logger.error(error);
    throw new Error(error);
  }
  logger.address("L3 Bridge contract", l3_tokenBridge.address);

  let l3_tokenBridgeCls = await acc_l3.getClassAt(l3_tokenBridge.address);
  let l3_tokenBridgeContract_l3 = new Contract(l3_tokenBridgeCls.abi, l3_tokenBridge.address, acc_l3);

  const l3Roles_TokenBridge = finalRoles.l3.TokenBridge;

  // Grant roles
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.GovernanceAdmin, "register_governance_admin");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.AppRoleAdmin, "register_app_role_admin");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.AppGovernor, "register_app_governor");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.Operator, "register_operator");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.TokenAdmin, "register_token_admin");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.UpgradeGovernor, "register_upgrade_governor");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.SecurityAdmin, "register_security_admin");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.SecurityAgent, "register_security_agent");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.L2TokenGovernance, "set_l2_token_governance");

  // Revoke roles
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.TokenAdmin, "remove_token_admin");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.AppGovernor, "remove_app_governor");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.Operator, "remove_operator");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.AppRoleAdmin, "remove_app_role_admin");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.UpgradeGovernor, "remove_upgrade_governor");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.SecurityAgent, "remove_security_agent");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.SecurityAdmin, "remove_security_admin");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.GovernanceAdmin, "remove_governance_admin");

}

export async function transferRoles(acc_l2: Account, acc_l3: Account, finalRoles: FinalRoles) {
  logger.info('Starting role transfer process');

  // Execute each role transfer function sequentially
  await transferTokenBridgeL2Roles(acc_l2, finalRoles);
  await transferTimelockL2Roles(acc_l2, finalRoles);
  await transferAppchainL2Roles(acc_l2, finalRoles);
  await transferTokenBridgeL3Roles(acc_l3, finalRoles);

  logger.success('Role transfer process completed successfully');
}

