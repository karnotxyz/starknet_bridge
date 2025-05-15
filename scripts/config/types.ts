import {  selector} from 'starknet';

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

export enum TokenStatus {
  Unknown = "Unknown",
  Pending = "Pending",
  Active = "Active",
  Blocked = "Blocked",
  Deactivated = "Deactivated"
}

/// =========================== Appchain Config ===========================

export type FactRegistryChain = 'SN_MAIN' | 'SN_SEPOLIA';
export type VerificationType = 'mocked' | 'with_verification';

export interface FactRegistryOptions {
  chain: FactRegistryChain;
  verificationType: VerificationType;
}

export interface AppchainConfig {
  programInfo: ProgramInfo;
  factRegistry: {
    SN_MAIN: string;
    SN_SEPOLIA: {
      mocked: string;
      with_verification: string;
    };
  };
}

export interface ProgramInfo {
  bootloader_program_hash: string;
  snos_config_hash: string;
  snos_program_hash: string;
  layout_bridge_program_hash: string;
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
    PROPOSER_ROLE = selector.getSelectorFromName('PROPOSER_ROLE') as unknown as number,
    EXECUTOR_ROLE = selector.getSelectorFromName('EXECUTOR_ROLE') as unknown as number,
    CANCELLER_ROLE = selector.getSelectorFromName('CANCELLER_ROLE') as unknown as number,
    DEFAULT_ADMIN = "0" 
}

export interface TimelockControllerRoles {
    PROPOSER_ROLE: string[];
    EXECUTOR_ROLE: string[];
    CANCELLER_ROLE: string[];
    DEFAULT_ADMIN: string;
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

