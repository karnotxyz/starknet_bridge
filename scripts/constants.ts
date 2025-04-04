import { Package, Contract, Layer } from "./types";

// Define our packages
export const starknetBridgePackage: Package = {
  name: "starknet_bridge",
  base_path: "./target/dev",
};

export const starkgatePackage: Package = {
  name: "starkgate_contracts",
  base_path: "./starkgate-contracts/cairo_contracts",
};

// Define all contract instances upfront
export const appchainContract: Contract = {
  name: "appchain",
  layer: Layer.L2,
  package: starknetBridgePackage,
};

export const tokenBridgeL2Contract: Contract = {
  name: "TokenBridge",
  layer: Layer.L2,
  package: starknetBridgePackage,
};

export const tokenBridgeL3Contract: Contract = {
  name: "TokenBridge",
  layer: Layer.L3,
  package: starkgatePackage,
};

export const timelockContract: Contract = {
  name: "TimelockController",
  layer: Layer.L2,
  package: starknetBridgePackage,
}

export const erc20Contract: Contract = {
  name: "ERC20",
  layer: Layer.L2,
  package: starknetBridgePackage,
};

export const erc20LockableContract: Contract = {
  name: "ERC20Lockable",
  layer: Layer.L3,
  package: starkgatePackage,
};
