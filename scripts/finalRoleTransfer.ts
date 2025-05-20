import { Account, Contract, num } from "starknet";
import { getContract, standardiseAddress } from "./utils/utils.ts";
import { logger } from "./utils/logger.ts";
import { appchainContract, timelockContract, tokenBridgeL2Contract, tokenBridgeL3Contract } from "./config/constants.ts";
import { FinalRoles, L2TokenBridgeRoleIds, TimelockControllerRoleIds } from "./config/types.ts";
import { ABI as AppchainAbi } from "./abis/starknet_bridge_appchain.ts";
import assert from "assert";
import { TypedContractV2 } from "starknet";
import { ABI as TimelockAbi } from "./abis/starknet_bridge_TimelockController.ts";
import { ABI as TokenBridgeL2Abi } from "./abis/starknet_bridge_TokenBridge.ts";
import { ABI as TokenBridgeL3Abi } from "./abis/starkgate_contracts_TokenBridge.ts";

async function changeRole(acc_l2: Account, contract: TypedContractV2<typeof TimelockAbi> | TypedContractV2<typeof TokenBridgeL2Abi>, role: L2TokenBridgeRoleIds | TimelockControllerRoleIds, address: string[] | string, method: "grant_role" | "renounce_role") {
  if (!Array.isArray(address)) {
    address = [address]
  }
  logger.info(`SUB-STEP 1: Executing method ${method} for ${role} to multiple addresses`);
  logger.address("Target addresses", address.join(', '));

  for (const addr of address) {
    const hasRole = await contract.has_role(role, addr);
    if (method === "renounce_role") {
      if (!hasRole) {
        logger.info(`Skipping granting role ${role} to ${addr} as 'has_role' function returned ${hasRole}`);
        continue;
      }
      assert(acc_l2.address == addr, "Renouncing can be done for self only");
    } else if (method === "grant_role") {
      if (hasRole) {
        logger.info(`Skipping granting role ${role} to ${addr} as 'has_role' function returned ${hasRole}`);
        continue;
      }
    } else {
      const errorMsg = "Invalid contract method used";
      logger.error(errorMsg);
      throw errorMsg;
    }

    const call = contract.populate(method, [role, addr]);
    let tx = await acc_l2.execute([call]);
    let receipt = await acc_l2.waitForTransaction(tx.transaction_hash);
    assert(receipt.isSuccess(), `Failed to ${method} role ${role} to address ${addr}`);
    logger.txHash(tx.transaction_hash);
    logger.success(`${method} for role ${role} to address ${addr} successful !!`);
  }
}

async function changeRoleWithMethod(acc: Account, contract: Contract, address: string[] | string, method: string, skipIfMethod?: [string, boolean]) {
  if (!Array.isArray(address)) {
    address = [address]
  }
  logger.info(`SUB-STEP 1: Executing ${method} for multiple addresses`);
  logger.address("Target addresses", address.join(', '));

  for (const addr of address) {
    if (skipIfMethod) {
      const hasRole = await contract.call(skipIfMethod[0], [addr]);
      if (skipIfMethod[1] == hasRole) {
        logger.info(`Skipping ${method} for address ${addr} ${skipIfMethod[0]} returns ${hasRole}`);
        continue;
      }
    }

    const call = contract.populate(method, [addr]);
    let tx = await acc.execute([call]);
    let receipt = await acc.waitForTransaction(tx.transaction_hash);
    assert(receipt.isSuccess(), `Failed to execute ${method} for address ${addr}`);
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
      await changeRoleWithMethod(acc_l2, appchainContract, operator, "register_operator", ["is_operator", true]);
    } else {
      const error = `Cannot register operator ${operator} because current owner is ${currentOwner} and not ${acc_l2.address} from .env`;
      logger.error(error);
      throw new Error(error);
    }
  }
}


export async function transferTokenBridgeL2Roles(acc_l2: Account, finalRoles: FinalRoles) {
  getContract(tokenBridgeL2Contract);
  if (!tokenBridgeL2Contract.address) {
    const error = "L2 Bridge contract address not found";
    logger.error(error);
    throw new Error(error);
  }
  logger.address("L2 Bridge contract", tokenBridgeL2Contract.address);

  let tokenBridgeContract_l2 = new Contract(TokenBridgeL2Abi, tokenBridgeL2Contract.address, acc_l2).typedv2(TokenBridgeL2Abi);

  const l2Roles_TokenBridge = finalRoles.l2.TokenBridge;

  await changeRole(acc_l2, tokenBridgeContract_l2, L2TokenBridgeRoleIds.TOKEN_ADMIN, l2Roles_TokenBridge.TOKEN_ADMIN, "grant_role");
  await changeRole(acc_l2, tokenBridgeContract_l2, L2TokenBridgeRoleIds.SECURITY_AGENT, l2Roles_TokenBridge.SECURITY_AGENT, "grant_role");
  await changeRole(acc_l2, tokenBridgeContract_l2, L2TokenBridgeRoleIds.APP_GOVERNOR, l2Roles_TokenBridge.APP_GOVERNOR, "grant_role");
  await changeRole(acc_l2, tokenBridgeContract_l2, L2TokenBridgeRoleIds.SECURITY_ADMIN, l2Roles_TokenBridge.SECURITY_ADMIN, "grant_role");
  await changeRole(acc_l2, tokenBridgeContract_l2, L2TokenBridgeRoleIds.GOVERNANCE_ADMIN, l2Roles_TokenBridge.GOVERNANCE_ADMIN, "grant_role");
}

export async function transferTimelockL2Roles(acc_l2: Account, finalRoles: FinalRoles) {
  // L2 Timelock
  getContract(timelockContract);
  if (!timelockContract.address) {
    const error = "Timelock contract address not found";
    logger.error(error);
    throw new Error(error);
  }
  logger.address("Timelock contract", timelockContract.address);

  let timelockContract_l2 = new Contract(TimelockAbi, timelockContract.address, acc_l2).typedv2(TimelockAbi);

  const l2Roles_TimelockController = finalRoles.l2.TimelockController_starknet_bridge;
  await changeRole(acc_l2, timelockContract_l2, TimelockControllerRoleIds.PROPOSER_ROLE, l2Roles_TimelockController.PROPOSER_ROLE, "grant_role");
  await changeRole(acc_l2, timelockContract_l2, TimelockControllerRoleIds.EXECUTOR_ROLE, l2Roles_TimelockController.EXECUTOR_ROLE, "grant_role");
  await changeRole(acc_l2, timelockContract_l2, TimelockControllerRoleIds.CANCELLER_ROLE, l2Roles_TimelockController.CANCELLER_ROLE, "grant_role");
  await changeRole(acc_l2, timelockContract_l2, TimelockControllerRoleIds.DEFAULT_ADMIN, l2Roles_TimelockController[TimelockControllerRoleIds.DEFAULT_ADMIN], "grant_role");

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

  // Transfer ownership
  {
    logger.info("SUB-STEP 1: Transferring Appchain ownership to new owner");
    const tx = await appchainContract_l2.transfer_ownership(l2Roles_Appchain.owner);
    logger.txHash(tx.transaction_hash);
    let receipt = await acc_l2.waitForTransaction(tx.transaction_hash);
    assert(receipt.isSuccess(), `Failed to inititate transfer ownerhip to ${l2Roles_Appchain.owner} from ${acc_l2.address}`);
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
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.GovernanceAdmin, "register_governance_admin", ["is_governance_admin", true]);
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.AppRoleAdmin, "register_app_role_admin", ["is_app_role_admin", true]);
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.AppGovernor, "register_app_governor", ["is_app_governor", true]);
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.Operator, "register_operator", ["is_operator", true]);
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.TokenAdmin, "register_token_admin", ["is_token_admin", true]);
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.UpgradeGovernor, "register_upgrade_governor", ["is_upgrade_governor", true]);
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.SecurityAdmin, "register_security_admin", ["is_security_admin", true]);
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.SecurityAgent, "register_security_agent", ["is_security_agent", true]);
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, l3Roles_TokenBridge.L2TokenGovernance, "set_l2_token_governance");
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



// @dev: You can't renounce `GOVERNANCE_ADMIN` of timelock as
// @notice: It will have to be revoked by the newly granted `GOVERNANCE_ADMIN`
// it is one of the top most roles
export async function renounceTokenBridgeL2Roles(acc_l2: Account) {
  getContract(tokenBridgeL2Contract);
  if (!tokenBridgeL2Contract.address) {
    const error = "L2 Bridge contract address not found";
    logger.error(error);
    throw new Error(error);
  }
  logger.address("L2 Bridge contract", tokenBridgeL2Contract.address);

  let tokenBridgeContract_l2 = new Contract(TokenBridgeL2Abi, tokenBridgeL2Contract.address, acc_l2).typedv2(TokenBridgeL2Abi);

  await changeRole(acc_l2, tokenBridgeContract_l2, L2TokenBridgeRoleIds.TOKEN_ADMIN, acc_l2.address, "renounce_role");
  await changeRole(acc_l2, tokenBridgeContract_l2, L2TokenBridgeRoleIds.SECURITY_AGENT, acc_l2.address, "renounce_role");
  await changeRole(acc_l2, tokenBridgeContract_l2, L2TokenBridgeRoleIds.APP_GOVERNOR, acc_l2.address, "renounce_role");
  await changeRole(acc_l2, tokenBridgeContract_l2, L2TokenBridgeRoleIds.SECURITY_ADMIN, acc_l2.address, "renounce_role");
}


// @notice: It will have to be revoked by the newly granted `DEFAULT_ADMIN`
// @dev: You can't renounce `DEFAULT_ADMIN` of timelock as
// it is one of the top most roles
export async function renounceTimelockRolesRoles(acc_l2: Account) {
  // L2 Timelock
  getContract(timelockContract);
  if (!timelockContract.address) {
    const error = "Timelock contract address not found";
    logger.error(error);
    throw new Error(error);
  }
  logger.address("Timelock contract", timelockContract.address);


  let timelockContract_l2 = new Contract(TimelockAbi, timelockContract.address, acc_l2).typedv2(TimelockAbi);

  await changeRole(acc_l2, timelockContract_l2, TimelockControllerRoleIds.PROPOSER_ROLE, acc_l2.address, "renounce_role");
  await changeRole(acc_l2, timelockContract_l2, TimelockControllerRoleIds.EXECUTOR_ROLE, acc_l2.address, "renounce_role");
  await changeRole(acc_l2, timelockContract_l2, TimelockControllerRoleIds.CANCELLER_ROLE, acc_l2.address, "renounce_role");
}


export async function renounceAppchainL2Roles(acc_l2: Account) {
  // L2 Appchain
  getContract(appchainContract);
  if (!appchainContract.address) {
    const error = "Appchain contract address not found";
    logger.error(error);
    throw new Error(error);
  }
  logger.address("Appchain contract", appchainContract.address);

  let appchainContract_l2 = new Contract(AppchainAbi, appchainContract.address, acc_l2).typedv2(AppchainAbi);

  // Unregister current owner as operator if it is registered
  const isRegistered = await appchainContract_l2.is_operator(acc_l2.address);
  if (isRegistered) {
    const currentOwner = standardiseAddress(await appchainContract_l2.owner());
    if (standardiseAddress(acc_l2.address) === currentOwner) {
      await changeRoleWithMethod(acc_l2, appchainContract_l2, acc_l2.address, "unregister_operator");
    } else {
      const error = `Cannot unregister operator ${acc_l2.address} because current owner is ${currentOwner} and not ${acc_l2.address} from .env`;
      logger.error(error);
      throw new Error(error);
    }
  }
}


// @dev: You can't renounce `GOVERNANCE_ADMIN` and `SECURITY_ADMIN` of timelock as
// @notice: It will have to be revoked by the newly granted `GOVERNANCE_ADMIN` / `SECURITY_ADMIN`
// it is one of the top most roles
export async function renounceTokenBridgeL3Roles(acc_l3: Account) {
  // L3 Token Bridge
  getContract(tokenBridgeL3Contract);
  if (!tokenBridgeL3Contract.address) {
    const error = "L3 Bridge contract address not found";
    logger.error(error);
    throw new Error(error);
  }
  logger.address("L3 Bridge contract", tokenBridgeL3Contract.address);

  let l3_tokenBridgeContract_l3 = new Contract(TokenBridgeL3Abi, tokenBridgeL3Contract.address, acc_l3);

  // Revoke roles
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, acc_l3.address, "remove_token_admin", ["is_token_admin", false]);
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, acc_l3.address, "remove_app_governor", ["is_app_governor", false]);
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, acc_l3.address, "remove_operator", ["is_operator", false]);
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, acc_l3.address, "remove_app_role_admin", ["is_app_role_admin", false]);
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, acc_l3.address, "remove_upgrade_governor", ["is_upgrade_governor", false]);
  await changeRoleWithMethod(acc_l3, l3_tokenBridgeContract_l3, acc_l3.address, "remove_security_agent", ["is_security_agent", false]);
}

export async function checkTokenBridgeL2Roles(acc_l2: Account, finalRoles: FinalRoles) {
  getContract(tokenBridgeL2Contract);
  if (!tokenBridgeL2Contract.address) {
    const error = "L2 Bridge contract address not found";
    logger.error(error);
    throw new Error(error);
  }
  logger.address("L2 Bridge contract", tokenBridgeL2Contract.address);
  let tokenBridgeContract_l2 = new Contract(TokenBridgeL2Abi, tokenBridgeL2Contract.address, acc_l2).typedv2(TokenBridgeL2Abi);

  const l2Roles_TokenBridge = finalRoles.l2.TokenBridge;
  const roleChecks = [
    { role: L2TokenBridgeRoleIds.TOKEN_ADMIN, addresses: l2Roles_TokenBridge.TOKEN_ADMIN },
    { role: L2TokenBridgeRoleIds.SECURITY_AGENT, addresses: l2Roles_TokenBridge.SECURITY_AGENT },
    { role: L2TokenBridgeRoleIds.APP_GOVERNOR, addresses: l2Roles_TokenBridge.APP_GOVERNOR },
    { role: L2TokenBridgeRoleIds.SECURITY_ADMIN, addresses: l2Roles_TokenBridge.SECURITY_ADMIN },
    { role: L2TokenBridgeRoleIds.GOVERNANCE_ADMIN, addresses: l2Roles_TokenBridge.GOVERNANCE_ADMIN }
  ];

  for (const { role, addresses } of roleChecks) {
    for (const address of addresses) {
      logger.info(`Checking ${role} role for address ${address}`);
      assert(await tokenBridgeContract_l2.has_role(role, address), `${role} role not granted for address ${address}`);
    }
  }
}

export async function checkTimelockL2Roles(acc_l2: Account, finalRoles: FinalRoles) {
  getContract(timelockContract);
  if (!timelockContract.address) {
    const error = "Timelock contract address not found";
    logger.error(error);
    throw new Error(error);
  }
  logger.address("Timelock contract", timelockContract.address);

  let timelockContract_l2 = new Contract(TimelockAbi, timelockContract.address, acc_l2).typedv2(TimelockAbi);

  const l2Roles_TimelockController = finalRoles.l2.TimelockController_starknet_bridge;
  const roleChecks = [
    { role: TimelockControllerRoleIds.PROPOSER_ROLE, addresses: l2Roles_TimelockController.PROPOSER_ROLE },
    { role: TimelockControllerRoleIds.EXECUTOR_ROLE, addresses: l2Roles_TimelockController.EXECUTOR_ROLE },
    { role: TimelockControllerRoleIds.CANCELLER_ROLE, addresses: l2Roles_TimelockController.CANCELLER_ROLE },
    { role: TimelockControllerRoleIds.DEFAULT_ADMIN, addresses: [l2Roles_TimelockController[TimelockControllerRoleIds.DEFAULT_ADMIN]] }
  ];

  for (const { role, addresses } of roleChecks) {
    for (const address of addresses) {
      logger.info(`Checking ${role} role for address ${address}`);
      assert(await timelockContract_l2.has_role(role, address), `${role} role not granted for address ${address}`);
    }
  }
}

export async function checkAppchainL2Roles(acc_l2: Account, finalRoles: FinalRoles) {
  getContract(appchainContract);
  if (!appchainContract.address) {
    const error = "Appchain contract address not found";
    logger.error(error);
    throw new Error(error);
  }
  logger.address("Appchain contract", appchainContract.address);

  let appchainContract_l2 = new Contract(AppchainAbi, appchainContract.address, acc_l2).typedv2(AppchainAbi);

  const l2Roles_Appchain = finalRoles.l2.appchain;

  logger.info(`Checking appchain owner ${l2Roles_Appchain.owner}`);
  const pending_owner = await appchainContract_l2.pending_owner();
  assert(
    standardiseAddress(pending_owner) === standardiseAddress(l2Roles_Appchain.owner), 
    `Appchain pending owner not set, found ${pending_owner}`
  );

  // checking operators
  for (const operator of l2Roles_Appchain.operators) {
    logger.info(`Checking operator ${operator}`);
    assert(await appchainContract_l2.is_operator(operator), `${operator} is not an operator`);
  }
}

export async function checkTokenBridgeL3Roles(acc_l3: Account, finalRoles: FinalRoles) {
  getContract(tokenBridgeL3Contract);
  if (!tokenBridgeL3Contract.address) {
    const error = "L3 Bridge contract address not found";
    logger.error(error);
    throw new Error(error);
  }
  logger.address("L3 Bridge contract", tokenBridgeL3Contract.address);

  let tokenBridgeContract_l3 = new Contract(TokenBridgeL3Abi, tokenBridgeL3Contract.address, acc_l3);

  const l3Roles_TokenBridge = finalRoles.l3.TokenBridge;

  // Check each role
  for (const address of l3Roles_TokenBridge.GovernanceAdmin) {
    assert(await tokenBridgeContract_l3.is_governance_admin(address), `${address} is not a governance admin`);
  }

  for (const address of l3Roles_TokenBridge.AppRoleAdmin) {
    logger.info(`Checking AppRoleAdmin role for address ${address}`);
    assert(await tokenBridgeContract_l3.is_app_role_admin(address), `${address} is not an app role admin`);
  }

  for (const address of l3Roles_TokenBridge.AppGovernor) {
    logger.info(`Checking AppGovernor role for address ${address}`);
    assert(await tokenBridgeContract_l3.is_app_governor(address), `${address} is not an app governor`);
  }

  for (const address of l3Roles_TokenBridge.Operator) {
    logger.info(`Checking Operator role for address ${address}`);
    assert(await tokenBridgeContract_l3.is_operator(address), `${address} is not an operator`);
  }

  for (const address of l3Roles_TokenBridge.TokenAdmin) {
    logger.info(`Checking TokenAdmin role for address ${address}`);
    assert(await tokenBridgeContract_l3.is_token_admin(address), `${address} is not a token admin`);
  }

  for (const address of l3Roles_TokenBridge.UpgradeGovernor) {
    logger.info(`Checking UpgradeGovernor role for address ${address}`);
    assert(await tokenBridgeContract_l3.is_upgrade_governor(address), `${address} is not an upgrade governor`);
  }

  for (const address of l3Roles_TokenBridge.SecurityAdmin) {
    logger.info(`Checking SecurityAdmin role for address ${address}`);
    assert(await tokenBridgeContract_l3.is_security_admin(address), `${address} is not a security admin`);
  }

  for (const address of l3Roles_TokenBridge.SecurityAgent) {
    logger.info(`Checking SecurityAgent role for address ${address}`);
    assert(await tokenBridgeContract_l3.is_security_agent(address), `${address} is not a security agent`);
  }
}


export async function checkRolesPassed(acc_l2: Account, acc_l3: Account, finalRoles: FinalRoles) {
  logger.info('Checking roles passed');

  logger.info('Checking L2 Token Bridge roles');
  await checkTokenBridgeL2Roles(acc_l2, finalRoles);

  logger.info('Checking L2 Timelock Controller roles');
  await checkTimelockL2Roles(acc_l2, finalRoles);

  logger.info('Checking L2 Appchain roles');
  await checkAppchainL2Roles(acc_l2, finalRoles);

  logger.info('Checking L3 Token Bridge roles');
  await checkTokenBridgeL3Roles(acc_l3, finalRoles);
}

export async function renounceRoles(acc_l2: Account, acc_l3: Account) {
  logger.info('Starting role transfer process');

  // Execute each role transfer function sequentially
  logger.info('ROLE RENOUNCE STEP 1: Configuring L2 Token Bridge Roles');
  await renounceTokenBridgeL2Roles(acc_l2);

  logger.info('ROLE RENOUNCE STEP 2: Configuring L2 Timelock Controller Roles');
  await renounceTimelockRolesRoles(acc_l2);

  logger.info('ROLE RENOUNCE STEP 3: Configuring L2 Appchain Roles');
  await renounceAppchainL2Roles(acc_l2);

  logger.info('ROLE RENOUNCE STEP 4: Configuring L3 Token Bridge Roles');
  await renounceTokenBridgeL3Roles(acc_l3);

  logger.success('Role transfer process completed successfully');
}
