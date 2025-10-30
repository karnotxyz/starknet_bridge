All files and contracts in the erc20/ directory were adapted from the Starkgate project:
<https://github.com/starknet-io/starkgate-contracts/blob/v2.0.1/src/openzeppelin/token/erc20_v070/>

The constructor in the erc20/erc20.cairo contract has been modified to use ByteArray for name and symbol instead of felt252.
This modification addresses the felt252 limitation of 31 characters for name and symbol fields.
This approach follows current best practices and is used in OpenZeppelin contracts.
