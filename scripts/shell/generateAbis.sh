#! /bin/env 

npx abi-wan-kanabi --input ./target/dev/starknet_bridge_appchain.contract_class.json --output ./scripts/abis/starknet_bridge_appchain.ts
npx abi-wan-kanabi --input ./target/dev/starknet_bridge_ERC20_OZ.contract_class.json --output ./scripts/abis/starknet_bridge_ERC20_OZ.ts
npx abi-wan-kanabi --input ./target/dev/starknet_bridge_ERC20.contract_class.json --output ./scripts/abis/starknet_bridge_ERC20.ts
npx abi-wan-kanabi --input ./target/dev/starknet_bridge_TimelockController.contract_class.json --output ./scripts/abis/starknet_bridge_TimelockController.ts
npx abi-wan-kanabi --input ./target/dev/starknet_bridge_TokenBridge.contract_class.json --output ./scripts/abis/starknet_bridge_TokenBridge.ts

npx abi-wan-kanabi --input ./starkgate-contracts/cairo_contracts/starkgate_contracts_TokenBridge.contract_class.json --output ./scripts/abis/starkgate_contracts_TokenBridge.ts