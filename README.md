# ✨ So you want to sponsor a contest

This `README.md` contains a set of checklists for our contest collaboration.

Your contest will use two repos:

- **a _contest_ repo** (this one), which is used for scoping your contest and for providing information to contestants (wardens)
- **a _findings_ repo**, where issues are submitted (shared with you after the contest)

Ultimately, when we launch the contest, this contest repo will be made public and will contain the smart contracts to be reviewed and all the information needed for contest participants. The findings repo will be made public after the contest report is published and your team has mitigated the identified issues.

Some of the checklists in this doc are for **C4 (🐺)** and some of them are for **you as the contest sponsor (⭐️)**.

---

# Repo setup

## ⭐️ Sponsor: Add code to this repo

- [ ] Create a PR to this repo with the below changes:
- [ ] Provide a self-contained repository with working commands that will build (at least) all in-scope contracts, and commands that will run tests producing gas reports for the relevant contracts.
- [ ] Make sure your code is thoroughly commented using the [NatSpec format](https://docs.soliditylang.org/en/v0.5.10/natspec-format.html#natspec-format).
- [ ] Please have final versions of contracts and documentation added/updated in this repo **no less than 24 hours prior to contest start time.**
- [ ] Be prepared for a 🚨code freeze🚨 for the duration of the contest — important because it establishes a level playing field. We want to ensure everyone's looking at the same code, no matter when they look during the contest. (Note: this includes your own repo, since a PR can leak alpha to our wardens!)

---

## ⭐️ Sponsor: Edit this README

Under "SPONSORS ADD INFO HERE" heading below, include the following:

- [ ] Modify the bottom of this `README.md` file to describe how your code is supposed to work with links to any relevent documentation and any other criteria/details that the C4 Wardens should keep in mind when reviewing. ([Here's a well-constructed example.](https://github.com/code-423n4/2022-08-foundation#readme))
  - [ ] When linking, please provide all links as full absolute links versus relative links
  - [ ] All information should be provided in markdown format (HTML does not render on Code4rena.com)
- [ ] Under the "Scope" heading, provide the name of each contract and:
  - [ ] source lines of code (excluding blank lines and comments) in each
  - [ ] external contracts called in each
  - [ ] libraries used in each
- [ ] Describe any novel or unique curve logic or mathematical models implemented in the contracts
- [ ] Does the token conform to the ERC-20 standard? In what specific ways does it differ?
- [ ] Describe anything else that adds any special logic that makes your approach unique
- [ ] Identify any areas of specific concern in reviewing the code
- [ ] Optional / nice to have: pre-record a high-level overview of your protocol (not just specific smart contract functions). This saves wardens a lot of time wading through documentation.
- [ ] Delete this checklist and all text above the line below when you're ready.

---

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

The C4audit output for the contest can be found [here](add link to report) within an hour of contest opening.

_Note for C4 wardens: Anything included in the C4udit output is considered a publicly known issue and is ineligible for awards._

[ ⭐️ SPONSORS ADD INFO HERE ]

# Overview

GoGoPool is a decentralized liquid staking protocol on Avalanche. Our goal is to reduce the cost of running a Validator Node from 2000 AVAX -> 1000 AVAX by pairing Node Operators (users with hardware + 1000 AVAX) with Liquid Stakers (users just depositing AVAX).

## Basic functionality rundown

Liquid Stakers deposit AVAX into an ERC4626 (TokenggAVAX) and recieve ggAVAX in return that increases in value compared to AVAX as rewards from staking are deposited.

Node Operators join the protocol by creating Minipools where they deposit AVAX, request some amount of Liquid Staker AVAX and put up 10% of the requested amount in GGP. GGP, our protocol token, is how we ensure rewards for Liquid Stakers if the Node Operator does not maintain sufficient uptime for Avalanche rewards.

Staking rewards are split between Node Operators and Liquid Stakers with Node Operators getting 50% + a variable commission fee, and Liquid Stakers receiving the remainder.

Node Operators are additionally incentivized with GGP Rewards. GGP is our protocol token that inflates 5% per year. Inflated tokens are distributed between Node Operators, Protocol DAO members and Multisig Oracle maintainers. Node Operators recieve GGP proportionally to how much GGP they have staked.

More detail can be found in our [Notion document](https://multisiglabs.notion.site/C4-Audit-Scope-f26381cf715b41df809e0e18963baa03)

# Scope

This is the complete list of what's IN scope for this contest:

<!-- prettier-ignore -->
| Contract | SLOC | Purpose | Libraries used |
| --- | :-: | --- |  --- |
| [Base.sol](https://github.com/code-432n4/2022-12-gogopool/tree/gogopoolhttps://github.com/code-432n4/2022-12-gogopool/tree/gogopool/contracts/contract/Base.sol) | 8 | Modifiers, helper methods and storage method wrappers shared between contracts |
| [BaseUpgradeable.sol](https://github.com/code-432n4/2022-12-gogopool/tree/gogopool/contracts/contract/BaseUpgradeable.sol) | 9 | Openzeppelin upgradeable version of Base |
| [BaseAbstract.sol](https://github.com/code-432n4/2022-12-gogopool/tree/gogopool/contracts/contract/BaseAbstract.sol) | 145 | Parent contract for Base and BaseUpgradeable |
| [ClaimNodeOp.sol](https://github.com/code-432n4/2022-12-gogopool/tree/gogopool/contracts/contract/ClaimNodeOp.sol) | 84 | Claim contract for Node Operator GGP rewards |
| [ClaimProtocolDAO.sol](https://github.com/code-432n4/2022-12-gogopool/tree/gogopool/contracts/contract/ClaimProtocolDAO.sol) | 25 | Claim contract for Protocol DAO GGP rewards |
| [MinipoolManager.sol](https://github.com/code-432n4/2022-12-gogopool/tree/gogopool/contracts/contract/MinipoolManager.sol) | 429  | Minipool functionality, e.g. creating, initiating staking |
| [MultisigManager.sol](https://github.com/code-432n4/2022-12-gogopool/tree/gogopool/contracts/contract/MultisigManager.sol) | 68  | Multisig management functionality, e.g. enabling and disabling multisigs |
| [Ocyticus.sol](https://github.com/code-432n4/2022-12-gogopool/tree/gogopool/contracts/contract/Ocyticus.sol) | 49 | Protocol pause functionaltiy |
| [Oracle.sol](https://github.com/code-432n4/2022-12-gogopool/tree/gogopool/contracts/contract/Oracle.sol) | 41 | Price oracle for GGP token |
| [ProtocolDAO.sol](https://github.com/code-432n4/2022-12-gogopool/tree/gogopool/contracts/contract/ProtocolDAO.sol) | 92 | Defines and allows for modifying protocol settings |
| [RewardsPool.sol](https://github.com/code-432n4/2022-12-gogopool/tree/gogopool/contracts/contract/RewardsPool.sol) | 153 | Handles GGP reward cycles including inflation and distribution |
| [Staking.sol](https://github.com/code-432n4/2022-12-gogopool/tree/gogopool/contracts/contract/Staking.sol) | 256 | Maintains information on stakers (anyone staking GGP or AVAX) |
| [Storage.sol](https://github.com/code-432n4/2022-12-gogopool/tree/gogopool/contracts/contract/Storage.sol) | 113 | Implements data separation pattern and maintains storage for all netowrk contracts with generic getters/setters. Contracts are registered with storage to define their ability to interact with stored variables |
| [Vault.sol](https://github.com/code-432n4/2022-12-gogopool/tree/gogopool/contracts/contract/Vault.sol) | 129  | Stores AVAX/ERC20 tokens on behalf of network contracts, to maintain their upgradeability |
| [TokenGGP.sol](https://github.com/code-432n4/2022-12-gogopool/tree/gogopool/contracts/contract/tokens/TokenGGP.sol) | 8 | Fixed-supply, non-upgradeable ERC20 token |
| [TokenggAVAX.sol](https://github.com/code-432n4/2022-12-gogopool/tree/gogopool/contracts/contract/tokens/TokenggAVAX.sol)  | 174  | An upgradeable (via OpenZeppelin proxy) ERC4626 yield-bearing liquid staking token |
| [ERC20Upgradeable.sol](https://github.com/code-432n4/2022-12-gogopool/tree/gogopool/contracts/contract/tokens/upgradeable/ERC20Upgradeable.sol) | 119  | Upgradeable version of Solmate's ERC20 Token | 
| [ERC4626Upgradeable.sol](https://github.com/code-432n4/2022-12-gogopool/tree/gogopool/contracts/contract/tokens/upgradeable/ERC4626Upgradeable.sol) | 102  | Upgradeable version of Solmate's ERC4626 Token |

## Out of scope

This is the complete list of what's OUT of scope for this contest:
| Contract |
| --- |
| [Multicall.sol](https://github.com/code-432n4/2022-12-gogopool/tree/gogopool/contracts/contract/utils/Multicall.sol) |
| [Multicall3.sol](https://github.com/code-432n4/2022-12-gogopool/tree/gogopool/contracts/contract/utils/Multicall3.sol) |
| [OneInchMock.sol](https://github.com/code-432n4/2022-12-gogopool/tree/gogopool/contracts/contract/utils/OneInchMock.sol) |
| [RialtoSimulator.sol](https://github.com/code-432n4/2022-12-gogopool/tree/gogopool/contracts/contract/utils/RialtoSimulator.sol) |
| [WAVAX.sol](https://github.com/code-432n4/2022-12-gogopool/tree/gogopool/contracts/contract/utils/WAVAX.sol) |
| [IOneInch.sol](/contracts/interface/IOneInch.sol) |
| [IWAVAX.sol](/contracts/interface/IWAVAX.sol) |
| [IWithdrawer.sol](/contracts/interface/IWithdrawer.sol) |
| [MinipoolStatus.sol](/contracts/types/MinipoolStatus.sol) |

# Additional Context

_Describe any novel or unique curve logic or mathematical models implemented in the contracts_

_Sponsor, please confirm/edit the information below._

## Scoping Details

```
- If you have a public code repo, please share it here:  github.com/multisiglabs/gogopool-contracts (private)
- How many contracts are in scope?:   23
- Total SLoC for these contracts?:  2063
- How many external imports are there?: 25 dependencies external to our code
- How many separate interfaces and struct definitions are there for the contracts within scope?:  5
- Does most of your code generally use composition or inheritance?:   inheritance
- How many external calls?:   0
- What is the overall line coverage percentage provided by your tests?:  77%
- Is there a need to understand a separate part of the codebase / get context in order to audit this part of the protocol?:   true
- Please describe required context:   Probably most important thing is how the tokenomics work, edge cases for it. Our current thoguhts; Litepaper: https://docs.google.com/document/d/1R6L_qEuBV0xyhl90QQxjbGjMe9Yr7RiOVDMy63SMP2o/edit Audit scope: https://multisiglabs.notion.site/C4-Audit-Scope-f26381cf715b41df809e0e18963baa03
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

```
(FYI We use [Just](https://github.com/casey/just) as a replacement for `Make`)

git clone https://github.com/code-423n4/2022-12-gogopool.git
cd 2022-12-gogopool
yarn
brew install just
brew install jq
curl -L https://foundry.paradigm.xyz | bash
foundryup
forge install

just build
just test
forge test --gas-report
```

_Note: Many wardens run Slither as a first pass for testing. Please document any known errors with no workaround._
