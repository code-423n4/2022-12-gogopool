# GoGoPool contest details

- Total Prize Pool: $128,000 USDC
  - HM awards: $63,750 USDC
  - QA report awards: $7,500 USDC
  - Gas report awards: $3,750 USDC
  - Judge + presort awards: $15,000
  - Scout awards: $500 USDC
  - Mitigation review contest: $37,500
- Join [C4 Discord](https://discord.gg/code4rena) to register
- Submit findings [using the C4 form](https://code4rena.com/contests/2022-12-gogopool-contest/submit)
- [Read our guidelines for more details](https://docs.code4rena.com/roles/wardens)
- Starts December 15, 2022 20:00 UTC
- Ends January 03, 2022 20:00 UTC

## C4udit / Publicly Known Issues

The C4audit output for the contest can be found [here](https://gist.github.com/Picodes/49996eaab291146dc068c56752d2d1f3) within an hour of contest opening.

_Note for C4 wardens: Anything included in the C4udit output is considered a publicly known issue and is ineligible for awards._

_Same goes for Slither output and our [known issues](https://multisiglabs.notion.site/Known-Issues-0b7ffb3ac0494f2f8d6805dcd90e774d)._

# Overview

This is a contest to evaluate the entirety of the GoGoPool Protocol, a decentralized liquid staking protocol on Avalanche. Our mission is to be the easiest way to stake AVAX. GoGoPool allows users with hardware and 1000 AVAX to create a validator node in conjunction with funds deposited by liquid staking users.

A detailed description of the protocol can be found in [Notion](https://multisiglabs.notion.site/C4-Audit-Scope-f26381cf715b41df809e0e18963baa03), but here's a short summary

The protocol consists of two user groups, **Liquid Stakers** and **Node Operators**.

## Liquid Stakers

Liquid Stakers deposit AVAX into an ERC4626 (TokenggAVAX) and receive ggAVAX in return that increases in value compared to AVAX as rewards from staking are deposited.

## Node Operators

Node Operators join the protocol by creating Minipools where they deposit AVAX, request some amount of Liquid Staker AVAX and put up 10% of the requested amount in GGP. GGP, our protocol token, is how we ensure rewards for Liquid Stakers if the Node Operator does not maintain sufficient uptime for Avalanche rewards.

Staking rewards are split between Node Operators and Liquid Stakers with Node Operators getting 50% + a variable commission fee, and Liquid Stakers receiving the remainder.

Node Operators are additionally incentivized with GGP Rewards. GGP is our protocol token that inflates 5% per year. Inflated tokens are distributed between Node Operators, Protocol DAO members and Multisig Oracle maintainers. Node Operators receive GGP proportionally to how much GGP they have staked.

[![Twitter URL](https://img.shields.io/twitter/follow/GoGoPool_?style=social)](https://twitter.com/GoGoPool_)
[![Website](https://img.shields.io/badge/Website-Check%20Us%20Out-orange)](https://www.gogopool.com/)
[![Telegram](https://img.shields.io/badge/Telegram-gray?logo=telegram)](https://t.me/GoGoPoolAnnouncements)
[![Discord chat][discord-badge]][discord-url]

[discord-badge]: https://img.shields.io/badge/Discord-Join-green
[discord-url]: https://discord.gg/7RJkvMew

# Scope

This is the complete list of what's IN scope for this contest:

<!-- prettier-ignore -->
| Contract | SLOC | Purpose | Libraries used |
| --- | :-: | --- |  --- |
| [Base.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/contract/Base.sol) | 8 | Modifiers, helper methods and storage method wrappers shared between contracts | |
| [BaseUpgradeable.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/contract/BaseUpgradeable.sol) | 9 | Openzeppelin upgradeable version of Base | @openzeppelin/Initializable |
| [BaseAbstract.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/contract/BaseAbstract.sol) | 145 | Parent contract for Base and BaseUpgradeable | |
| [ClaimNodeOp.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/contract/ClaimNodeOp.sol) | 84 | Claim contract for Node Operator GGP rewards | @solmate/ERC4626, FixedPointMathLib |
| [ClaimProtocolDAO.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/contract/ClaimProtocolDAO.sol) | 25 | Claim contract for Protocol DAO GGP rewards | |
| [MinipoolManager.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/contract/MinipoolManager.sol) | 435 | Minipool functionality, e.g. creating, initiating staking | @solmate/ERC4626, FixedPointMathLib, ReentrancyGuard, SafeTransferLib |
| [MultisigManager.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/contract/MultisigManager.sol) | 68  | Multisig management functionality, e.g. enabling and disabling multisigs |
| [Ocyticus.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/contract/Ocyticus.sol) | 49 | Protocol pause functionality |
| [Oracle.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/contract/Oracle.sol) | 41 | Price oracle for GGP token |
| [ProtocolDAO.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/contract/ProtocolDAO.sol) | 122 | Defines and allows for modifying protocol settings |
| [RewardsPool.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/contract/RewardsPool.sol) | 153 | Handles GGP reward cycles including inflation and distribution | @solmate/FixedPointMathLib |
| [Staking.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/contract/Staking.sol) | 256 | Maintains information on stakers (anyone staking GGP or AVAX) | @solmate/ERC20, FixedPointMathLib, SafeTransferLib |
| [Storage.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/contract/Storage.sol) | 113 | Implements data separation pattern and maintains storage for all netowrk contracts with generic getters/setters. Contracts are registered with storage to define their ability to interact with stored variables | |
| [Vault.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/contract/Vault.sol) | 129  | Stores AVAX/ERC20 tokens on behalf of network contracts, to maintain their upgradeability | @solmate/ERC20, ReentrancyGuard, SafeTransferLib |
| [TokenGGP.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/contract/tokens/TokenGGP.sol) | 8 | Fixed-supply, non-upgradeable ERC20 token | @solmate/ERC20 |
| [TokenggAVAX.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/contract/tokens/TokenggAVAX.sol)  | 174  | An upgradeable (via OpenZeppelin proxy) ERC4626 yield-bearing liquid staking token | @openzeppelin/Initializable, UUPSUpgradeable + @solmate/ERC20, FixedPointMathLib, SafeCastLib, SafeTransferLib |
| [ERC20Upgradeable.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/contract/tokens/upgradeable/ERC20Upgradeable.sol) | 119  | Upgradeable version of Solmate's ERC20 Token | |
| [ERC4626Upgradeable.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/contract/tokens/upgradeable/ERC4626Upgradeable.sol) | 102  | Upgradeable version of Solmate's ERC4626 Token |@solmate/ERC20, FixedPointMathLib, SafeTransferLib, Initializable |

## Out of scope

This is the complete list of what's OUT of scope for this contest:
| Contract |
| --- |
| [Multicall.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/contract/utils/Multicall.sol) |
| [Multicall3.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/contract/utils/Multicall3.sol) |
| [OneInchMock.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/contract/utils/OneInchMock.sol) |
| [RialtoSimulator.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/contract/utils/RialtoSimulator.sol) |
| [WAVAX.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/contract/utils/WAVAX.sol) |
| [IOneInch.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/interface/IOneInch.sol) |
| [IWAVAX.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/interface/IWAVAX.sol) |
| [IWithdrawer.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/interface/IWithdrawer.sol) |
| [MinipoolStatus.sol](https://github.com/code-423n4/2022-12-gogopool/blob/main/contracts/types/MinipoolStatus.sol) |

## Scoping Details

```
- If you have a public code repo, please share it here:  N/A
- How many contracts are in scope?:   18
- Total SLoC for these contracts?:  2040
- How many external imports are there?: 25 dependencies external to our code
- How many separate interfaces and struct definitions are there for the contracts within scope?:  5
- Does most of your code generally use composition or inheritance?:   inheritance
- How many external calls?:   13
- What is the overall line coverage percentage provided by your tests?:  77%
- Is there a need to understand a separate part of the codebase / get context in order to audit this part of the protocol?:   true
- Please describe required context:   Documentation at Notion: https://multisiglabs.notion.site/C4-Audit-Scope-f26381cf715b41df809e0e18963baa03
- Does it use an oracle?:  true
- Does the token conform to the ERC20 standard?:  Yes
- Are there any novel or unique curve logic or mathematical models?: No
- Does it use a timelock function?:  ggAVAX does (streams rewards over 14 days), GGP does not
- Is it an NFT?: No
- Does it have an AMM?:   No
- Is it a fork of a popular project?:   Parts are based on Ethereum's RocketPool, tailored to fit the way Avalanche works
- Does it use rollups?:   False
- Is it multi-chain?:  False
- Does it use a side-chain?: False
```

# Tests

```sh
# Install a few tools we use to run the repo
brew install just
brew install jq
curl -L https://foundry.paradigm.xyz | bash
foundryup
forge install

git clone https://github.com/code-423n4/2022-12-gogopool.git
cd 2022-12-gogopool
yarn

# FYI We use [Just](https://github.com/casey/just) as a replacement for `Make`
just build
just test
forge test --gas-report
```
