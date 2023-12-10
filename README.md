# Aori Vaults Template

![.](assets/aori-vault-template.svg)

This boilerplate is a simple smart contract vault template that can be used to store and manage assets programmatically. Flash loans are also supported through the use of Balancer.

An executor wallet must be provided in order to execute `Instruction`s against the vault, but managers can be added to sign off on signature requests.

## Deployments

Below is a list of deployments used by the Aori team to help bootstrap liquidity through DEX aggregators.

Deployed and executed by `0xD2e31e651C5EdD8743355A9B29AeFb993880d14C`:

| Network | Address |
|---------|---------|
| `Goerli (5)` | [0x11530084405184b1BE7CAd29c9fa0626bcDBe6A3](https://goerli.etherscan.io/address/0x11530084405184b1BE7CAd29c9fa0626bcDBe6A3) |
| `Arbitrum (42161)` | [0x11530084405184b1BE7CAd29c9fa0626bcDBe6A3](https://arbiscan.io/address/0x11530084405184b1BE7CAd29c9fa0626bcDBe6A3) |

## Usage

To run the tests, run:
```
forge test --via-ir --fork-url $YOUR_RPC_URL
```


