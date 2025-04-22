import { Account, Contract, num } from "starknet";
import { getContract, standardiseAddress } from "./utils/utils";
import { logger } from "./utils/logger";
import { appchainContract, timelockContract, tokenBridgeL2Contract, tokenBridgeL3Contract } from "./config/constants";
import { FinalRoles, L2TokenBridgeRoleIds, TimelockControllerRoleIds } from "./config/types";
import { ABI as AppchainAbi } from "./abis/starknet_bridge_appchain";
import { TypedContractV2 } from "starknet";

async function grantRoleRevokeSelf(acc_l2: Account, contract: Contract, role: L2TokenBridgeRoleIds | TimelockControllerRoleIds, address: string[] | string) {
  if (!Array.isArray(address)) {
    address = [address]
  }
  logger.info(`SUB-STEP 1: Granting role ${role} to multiple addresses`);
  logger.address("Target addresses", address.join(', '));

  for (const addr of address) {
    const call = contract.populate("grant_role", [role, addr]);
    let tx = await acc_l2.execute([call]);
    await acc_l2.waitForTransaction(tx.transaction_hash);
    logger.txHash(tx.transaction_hash);
    logger.success(`Granted role ${role} to address ${addr}`);
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
  if (!Array.isArray(address)) {
    address = [address]
  }
  logger.info(`SUB-STEP 1: Executing ${method} for multiple addresses`);
  logger.address("Target addresses", address.join(', '));

  for (const addr of address) {
    const call = contract.populate(method, [addr]);
    let tx = await acc_l3.execute([call]);
    await acc_l3.waitForTransaction(tx.transaction_hash);
    logger.txHash(tx.transaction_hash);
    logger.success(`Executed ${method} for address ${addr}`);
  }
}

async function registerOperator(acc_l2: Account, appchainContract: TypedContractV2<typeof AppchainAbi>, operators: string[] | string) {
  let currentOwner = standardiseAddress(await appchainContract.owner());
  if (!Array.isArray(operators)) {
    operators = [operators]
  }
  for (const operator of operators) {
    const isRegistered = await appchainContract.is_operator(operator);
    if (isRegistered) continue; // Skip if operator is already registered
    if (standardiseAddress(acc_l2.address) === currentOwner) {
      await changeRoleWithMethod(acc_l2, appchainContract, operator, "register_operator");
    } else {
      const error = `Cannot register operator ${operator} because current owner is ${currentOwner} and not ${acc_l2.address} from .env`;
      logger.error(error);
      throw new Error(error);
    }
  }
} 


export async function transferTokenBridgeL2Roles(acc_l2: Account, finalRoles: FinalRoles) {
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
  getContract(appchainContract);
  if (!appchainContract.address) {
    const error = "Appchain contract address not found";
    logger.error(error);
    throw new Error(error);
  }
  logger.address("Appchain contract", appchainContract.address);

  let appchainContract_l2 = new Contract(AppchainAbi, appchainContract.address, acc_l2).typedv2(AppchainAbi);
  const l2Roles_Appchain = finalRoles.l2.appchain

  // Register operators
  await registerOperator(acc_l2, appchainContract_l2, l2Roles_Appchain.operators);

  // Unregister current owner as operator if it is registered
  const isRegistered = await appchainContract_l2.is_operator(acc_l2.address);
  if (isRegistered) {
    const currentOwner = standardiseAddress(await appchainContract_l2.owner());
    if (standardiseAddress(acc_l2.address) === currentOwner) {
      await changeRoleWithMethod(acc_l2, appchainContract_l2, acc_l2.address, "unregister_operator");
    } else {
      const error = `Cannot unregister operator ${acc_l2.address} because current owner is ${l2Roles_Appchain.owner} and not ${acc_l2.address} from .env`;
      logger.error(error);
      throw new Error(error);
    }
  }

  // Transfer ownership
  {
    logger.info("SUB-STEP 1: Transferring Appchain ownership to new owner");
    const tx = await appchainContract_l2.transfer_ownership(l2Roles_Appchain.owner);
    logger.txHash(tx.transaction_hash);
    let receipt = await acc_l2.waitForTransaction(tx.transaction_hash);
    logger.success("Ownership transferred to new owner");
  }
}

export async function transferTokenBridgeL3Roles(acc_l3: Account, finalRoles: FinalRoles) {
  // L3 Token Bridge
  getContract(tokenBridgeL3Contract);
  if (!tokenBridgeL3Contract.address) {
    const error = "L3 Bridge contract address not found";
    logger.error(error);
    throw new Error(error);
  }
  logger.address("L3 Bridge contract", tokenBridgeL3Contract.address);

  let l3_tokenBridgeCls = await acc_l3.getClassAt(tokenBridgeL3Contract.address);
  let l3_tokenBridgeContract_l3 = new Contract(l3_tokenBridgeCls.abi, tokenBridgeL3Contract.address, acc_l3);

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
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, acc_l3.address, "remove_token_admin");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, acc_l3.address, "remove_app_governor");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, acc_l3.address, "remove_operator");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, acc_l3.address, "remove_app_role_admin");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, acc_l3.address, "remove_upgrade_governor");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, acc_l3.address, "remove_security_agent");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, acc_l3.address, "remove_security_admin");
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, acc_l3.address, "remove_governance_admin");

}

export async function transferRoles(acc_l2: Account, acc_l3: Account, finalRoles: FinalRoles) {
  logger.info('Starting role transfer process');

  // Execute each role transfer function sequentially
  logger.info('ROLE TRANSFER STEP 1: Configuring L2 Token Bridge Roles');
  await transferTokenBridgeL2Roles(acc_l2, finalRoles);

  logger.info('ROLE TRANSFER STEP 2: Configuring L2 Timelock Controller Roles');
  await transferTimelockL2Roles(acc_l2, finalRoles);

  logger.info('ROLE TRANSFER STEP 3: Configuring L2 Appchain Roles');
  await transferAppchainL2Roles(acc_l2, finalRoles);

  logger.info('ROLE TRANSFER STEP 4: Configuring L3 Token Bridge Roles');
  await transferTokenBridgeL3Roles(acc_l3, finalRoles);

  logger.success('Role transfer process completed successfully');
}

