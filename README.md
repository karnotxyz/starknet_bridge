# Starknet Bridge
`starknet_bridge` are the bridges that can be used by the appchains that will deployed using Starknet [Madara](https://github.com/keep-starknet-strange/madara) stack

This repository contains the code for the L2<>L3 bridges that can be used to bridge funds between an appchain and Starknet. This is similar to [starkgate](https://github.com/starknet-io/starkgate-contracts) which contains the bridge contracts between Ethereum and Starknet.

## Architecture
- `token_bridge.cairo`: The bridge that will be deployed on Starknet. Users can use this bridge to add tokens and deposit and withdraw funds.
- `withdrawal_limit/component.cairo`: A component used to manage the withdrawal limits for token that have this feature enabled.

The bridge relies on the core messaging contract from [piltover](https://github.com/keep-starknet-strange/piltover) which is the Cairo version of the Starknet Core Contracts.

## Build
To build the project run: 
```shell
scarb build
```

## Test
To run the testcases of the project run: 
```shell
scarb test
```
