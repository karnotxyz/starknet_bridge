import { Account, Contract } from "starknet";
import { getContract, getRoles } from "./utils";
import { NewRoles, Roles } from "./types";
import { logger } from "./logger";
import { timelockContract, tokenBridgeL2Contract, tokenBridgeL3Contract } from "./constants";

async function grantRole(acc_l2: Account, contract: Contract, role: Roles, address: string[] | string) {
  for (const addr of address) {
    const call = contract.populate("grant_role", [role, addr]);
    let tx = await acc_l2.execute([call]);
    await acc_l2.waitForTransaction(tx.transaction_hash);
  }
}

async function transferRoles(acc_l2: Account, acc_l3: Account) {
  const roles: NewRoles = getRoles();

  let tokenBridgeL2 = getContract(tokenBridgeL2Contract);
  if (!tokenBridgeL2.address) {
    throw new Error("L2 Bridge contract address not found");
  }

  let tokenBridgeCls = await acc_l2.getClassAt(tokenBridgeL2.address);
  let tokenBridgeContract_l2 = new Contract(tokenBridgeCls.abi, tokenBridgeL2.address, acc_l2);

  await grantRole(acc_l2, tokenBridgeContract_l2, Roles.TOKEN_ADMIN, roles.tokenAdmin);

  await grantRole(acc_l2, tokenBridgeContract_l2, Roles.SECURITY_AGENT, roles.securityAgent);

  await grantRole(acc_l2, tokenBridgeContract_l2, Roles.APP_GOVERNOR, roles.appGovernor);

  await grantRole(acc_l2, tokenBridgeContract_l2, Roles.SECURITY_ADMIN, roles.securityAdmin);

  await grantRole(acc_l2, tokenBridgeContract_l2, Roles.GOVERNANCE_ADMIN, roles.governanceAdmin);


  let timelock = getContract(timelockContract);
  if (!timelock.address) {
    throw new Error("Timelock contract address not found");
  }

  let timelockCls = await acc_l2.getClassAt(timelock.address);
  let timelockContract_l2 = new Contract(timelockCls.abi, timelock.address, acc_l2);

  await grantRole(acc_l2, timelockContract_l2, Roles.UPGRADE_GOVERNOR, roles.defaultAdminOfTimelock);
}

