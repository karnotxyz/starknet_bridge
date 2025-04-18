import { Account, Contract } from "starknet";
import { getContract } from "./utils";
import { logger } from "./logger";
import { appchainContract, timelockContract, tokenBridgeL2Contract, tokenBridgeL3Contract } from "./constants";
import { FinalRoles, L2TokenBridgeRoleIds, TimelockControllerRoleIds } from "./types";

async function grantRoleRevokeSelf(acc_l2: Account, contract: Contract, role: L2TokenBridgeRoleIds | TimelockControllerRoleIds, address: string[] | string) {
  if (Array.isArray(address)) {
    logger.info(`Granting role ${role} to multiple addresses: ${address.join(', ')}`);
    for (const addr of address) {
      const call = contract.populate("grant_role", [role, addr]);
      let tx = await acc_l2.execute([call]);
      await acc_l2.waitForTransaction(tx.transaction_hash);
      logger.info(`Granted role ${role} to address ${addr}, tx: ${tx.transaction_hash}`);
    }
  } else {
    logger.info(`Granting role ${role} to address ${address}`);
    const call = contract.populate("grant_role", [role, address]);
    let tx = await acc_l2.execute([call]);
    await acc_l2.waitForTransaction(tx.transaction_hash);
    logger.info(`Granted role ${role} to address ${address}, tx: ${tx.transaction_hash}`);
  }
  logger.info(`Revoking role ${role} from self (${acc_l2.address})`);
  const call = contract.populate("renounce_role", [role, acc_l2.address]);
  let tx = await acc_l2.execute([call]);
  await acc_l2.waitForTransaction(tx.transaction_hash);
  logger.info(`Revoked role ${role} from self, tx: ${tx.transaction_hash}`);
}

async function changeRoleWithMethod(acc_l3: Account, contract: Contract, address: string[] | string, method: string) {
  if (Array.isArray(address)) {
    logger.info(`Executing ${method} for multiple addresses: ${address.join(', ')}`);
    for (const addr of address) {
      const call = contract.populate(method, [addr]);
      let tx = await acc_l3.execute([call]);
      await acc_l3.waitForTransaction(tx.transaction_hash);
      logger.info(`Executed ${method} for address ${addr}, tx: ${tx.transaction_hash}`);
    }
  } else {
    logger.info(`Executing ${method} for address ${address}`);
    const call = contract.populate(method, [address]);
    let tx = await acc_l3.execute([call]);
    await acc_l3.waitForTransaction(tx.transaction_hash);
    logger.info(`Executed ${method} for address ${address}, tx: ${tx.transaction_hash}`);
  }
}

export async function transferRoles(acc_l2: Account, acc_l3: Account, finalRoles: FinalRoles) {
  logger.info('Starting role transfer process');
  logger.info('=== L2 Token Bridge Roles ===');

  let tokenBridgeL2 = getContract(tokenBridgeL2Contract);
  if (!tokenBridgeL2.address) {
    const error = "L2 Bridge contract address not found";
    logger.error(error);
    throw new Error(error);
  }
  logger.info(`Using L2 Bridge contract at ${tokenBridgeL2.address}`);

  let tokenBridgeCls = await acc_l2.getClassAt(tokenBridgeL2.address);
  let tokenBridgeContract_l2 = new Contract(tokenBridgeCls.abi, tokenBridgeL2.address, acc_l2);

  const l2Roles_TokenBridge = finalRoles.l2.TokenBridge;

  await grantRoleRevokeSelf(acc_l2, tokenBridgeContract_l2, L2TokenBridgeRoleIds.TOKEN_ADMIN, l2Roles_TokenBridge.TOKEN_ADMIN);
  await grantRoleRevokeSelf(acc_l2, tokenBridgeContract_l2, L2TokenBridgeRoleIds.SECURITY_AGENT, l2Roles_TokenBridge.SECURITY_AGENT);
  await grantRoleRevokeSelf(acc_l2, tokenBridgeContract_l2, L2TokenBridgeRoleIds.APP_GOVERNOR, l2Roles_TokenBridge.APP_GOVERNOR);
  await grantRoleRevokeSelf(acc_l2, tokenBridgeContract_l2, L2TokenBridgeRoleIds.SECURITY_ADMIN, l2Roles_TokenBridge.SECURITY_ADMIN);
  await grantRoleRevokeSelf(acc_l2, tokenBridgeContract_l2, L2TokenBridgeRoleIds.GOVERNANCE_ADMIN, l2Roles_TokenBridge.GOVERNANCE_ADMIN);


  logger.info('=== L2 Timelock Controller Roles ===');
  let timelock = getContract(timelockContract);
  if (!timelock.address) {
    const error = "Timelock contract address not found";
    logger.error(error);
    throw new Error(error);
  }

  let timelockCls = await acc_l2.getClassAt(timelock.address);
  let timelockContract_l2 = new Contract(timelockCls.abi, timelock.address, acc_l2);

  const l2Roles_TimelockController = finalRoles.l2.TimelockController_starknet_bridge;
  await grantRoleRevokeSelf(acc_l2, timelockContract_l2, TimelockControllerRoleIds.PROPOSER_ROLE, l2Roles_TimelockController.PROPOSER_ROLE);
  await grantRoleRevokeSelf(acc_l2, timelockContract_l2, TimelockControllerRoleIds.EXECUTOR_ROLE, l2Roles_TimelockController.EXECUTOR_ROLE);
  await grantRoleRevokeSelf(acc_l2, timelockContract_l2, TimelockControllerRoleIds.CANCELLER_ROLE, l2Roles_TimelockController.CANCELLER_ROLE);
  await grantRoleRevokeSelf(acc_l2, timelockContract_l2, TimelockControllerRoleIds.DEFAULT_ADMIN, l2Roles_TimelockController[TimelockControllerRoleIds.DEFAULT_ADMIN]);


  logger.info('=== L2 Appchain Roles ===');
  const appchain = getContract(appchainContract);
  if (!appchain.address) {
    const error = "Appchain contract address not found";
    logger.error(error);
    throw new Error(error);
  }

  let appchainCls = await acc_l2.getClassAt(appchain.address);
  let appchainContract_l2 = new Contract(appchainCls.abi, appchain.address, acc_l2);

  const l2Roles_Appchain = finalRoles.l2.appchain;
  await changeRoleWithMethod(acc_l2, appchainContract_l2, l2Roles_Appchain.operators, "register_operators");
  await changeRoleWithMethod(acc_l2, appchainContract_l2, l2Roles_Appchain.owner, "register_operator");
  await changeRoleWithMethod(acc_l2, appchainContract_l2, l2Roles_Appchain.owner, "unregister_operator");
  {
    const call = appchainContract_l2.populate("transfer_ownership", [l2Roles_Appchain.owner]);
    let tx = await acc_l2.execute([call]);
    await acc_l2.waitForTransaction(tx.transaction_hash);
  }


  // ========================== L3 ==========================

  logger.info('=== L3 Token Bridge Roles ===');
  const l3_tokenBridge = getContract(tokenBridgeL3Contract);
  if (!l3_tokenBridge.address) {
    const error = "L3 Bridge contract address not found";
    logger.error(error);
    throw new Error(error);
  }

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
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.L2TokenGovernance, "register_l2_token_governance");

  // Revoke roles
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.TokenAdmin, "remove_token_admin");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.AppGovernor, "remove_app_governor");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.Operator, "remove_operator");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.AppRoleAdmin, "remove_app_role_admin");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.UpgradeGovernor, "remove_upgrade_governor");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.SecurityAgent, "remove_security_agent");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.SecurityAdmin, "remove_security_admin");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.GovernanceAdmin, "remove_governance_admin");

  logger.info('Role transfer process completed successfully');
}

