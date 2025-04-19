export enum Layer {
  L2 = 'l2',
  L3 = 'l3'
}

export interface Package {
  name: string;
  base_path: string;
}

export interface Contract {
  name: string;
  layer: Layer;
  package: Package;
  classHash?: string;
  address?: string;
}


/// ======================== All Roles =========================

export interface FinalRoles {
  l2: L2Roles;
  l3: L3Roles;
}

/// =========================== L2 Token Bridge Roles ===========================

export enum L2TokenBridgeRoleIds {
  UPGRADE_GOVERNOR = 'UPGRADE_GOVERNOR',
  GOVERNANCE_ADMIN = 'GOVERNANCE_ADMIN',
  APP_GOVERNOR = 'APP_GOVERNOR',
  SECURITY_ADMIN = 'SECURITY_ADMIN',
  SECURITY_AGENT = 'SECURITY_AGENT',
  TOKEN_ADMIN = 'TOKEN_ADMIN',
}

export interface L2TokenBridgeRoles {
    [L2TokenBridgeRoleIds.TOKEN_ADMIN]: string[];
    [L2TokenBridgeRoleIds.SECURITY_AGENT]: string[];
    [L2TokenBridgeRoleIds.APP_GOVERNOR]: string[];
    [L2TokenBridgeRoleIds.SECURITY_ADMIN]: string[];
    [L2TokenBridgeRoleIds.GOVERNANCE_ADMIN]: string[];
}


/// =========================== L2 Timelock Controller Roles ===========================

export interface L2Roles {
    TokenBridge: L2TokenBridgeRoles;
    TimelockController_starknet_bridge: TimelockControllerRoles;
    appchain: AppchainRoles;
}

export enum TimelockControllerRoleIds {
    PROPOSER_ROLE = 'PROPOSER_ROLE',
    EXECUTOR_ROLE = 'EXECUTOR_ROLE',
    CANCELLER_ROLE = 'CANCELLER_ROLE',
    DEFAULT_ADMIN = 0 
}

export interface TimelockControllerRoles {
    [TimelockControllerRoleIds.PROPOSER_ROLE]: string[];
    [TimelockControllerRoleIds.EXECUTOR_ROLE]: string[];
    [TimelockControllerRoleIds.CANCELLER_ROLE]: string[];
    [TimelockControllerRoleIds.DEFAULT_ADMIN]: string;
}



/// =========================== L2 Appchain(Piltover core contract) Roles ===========================

export interface AppchainRoles {
    owner: string;
    operators: string[];
}



/// =========================== L3 Token Bridge ===========================

export interface L3Roles {
  TokenBridge: L3TokenBridgeRoles;
}

export interface L3TokenBridgeRoles {
  GovernanceAdmin: string[];
  AppRoleAdmin: string[];
    AppGovernor: string[];
    Operator: string[];
    TokenAdmin: string[];
    UpgradeGovernor: string[];
    SecurityAdmin: string[];
    SecurityAgent: string[];
    L2TokenGovernance: string;
}

