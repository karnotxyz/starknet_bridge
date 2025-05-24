import { Package, Contract, Layer, AppchainConfig } from "./types.ts";

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
  name: "ERC20_OZ",
  layer: Layer.L2,
  package: starknetBridgePackage,
};

export const erc20L3Contract: Contract = {
  name: "ERC20",
  layer: Layer.L3,
  package: starknetBridgePackage,
};

// =========================== appchainContract Config ===========================
export const appchainConfig: AppchainConfig = {
  programInfo: {
    bootloader_program_hash : "0x5ab580b04e3532b6b18f81cfa654a05e29dd8e2352d88df1e765a84072db07",
    snos_config_hash: "0x3ebcaa0cab0f8640a41ef3296b83af23086a4d215ea7bf26652181fb0ad24c3",
    snos_program_hash: "0x54d3603ed14fb897d0925c48f26330ea9950bd4ca95746dad4f7f09febffe0d",
    layout_bridge_program_hash: "0x193641eb151b0f41674641089952e60bc3aded26e3cf42793655c562b8c3aa0",
  },
  factRegistry: {
    SN_MAIN: "0xcc63a1e8e7824642b89fa6baf996b8ed21fa4707be90ef7605570ca8e4f00b",
    SN_SEPOLIA: {
      mocked: "0x02fd1f617a9caeeeadd0cd7da2d99391ee9dd9ad6c5cd1960e3034ffdfad3ae1",
      with_verification: "0x4ce7851f00b6c3289674841fd7a1b96b6fd41ed1edc248faccd672c26371b8c"
    }
  }
};
