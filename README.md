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

https://multisiglabs.notion.site/C4-Audit-Scope-f26381cf715b41df809e0e18963baa03

# Scope

This is the complete list of what's IN scope for this contest:

| Contract                                                                                | SLOC | Purpose                                                                                                                                                                                                   | Libraries used |
| --------------------------------------------------------------------------------------- | ---- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- |
| [contracts/contract/Base.sol](/contracts/contract/Base.sol)                             | 8    | Foundation contract for network contracts                                                                                                                                                                 |
| [contracts/contract/BaseAbstract.sol](/contracts/contract/BaseAbstract.sol)             | 145  | Abstract foundation contract for network contracts                                                                                                                                                        |
| [contracts/contract/BaseUpgradeable.sol](/contracts/contract/BaseUpgradeable.sol)       | 9    |
| [contracts/contract/ClaimNodeOp.sol](/contracts/contract/ClaimNodeOp.sol)               | 84   | Allows node operators to claim their GGP rewards                                                                                                                                                          |
| [contracts/contract/ClaimProtocolDAO.sol](/contracts/contract/ClaimProtocolDAO.sol)     | 25   | Holds the Protocol DAOs GGP rewards                                                                                                                                                                       |
| [contracts/contract/MinipoolManager.sol](/contracts/contract/MinipoolManager.sol)       | 429  | All functionality for creating and finishing a minipool                                                                                                                                                   |
| [contracts/contract/MultisigManager.sol](/contracts/contract/MultisigManager.sol)       | 68   |
| [contracts/contract/Ocyticus.sol](/contracts/contract/Ocyticus.sol)                     | 49   | Implements a protocol emergency pause feature                                                                                                                                                             |
| [contracts/contract/Oracle.sol](/contracts/contract/Oracle.sol)                         | 41   |
| [contracts/contract/ProtocolDAO.sol](/contracts/contract/ProtocolDAO.sol)               | 92   | Defines settings for the protocol                                                                                                                                                                         |
| [contracts/contract/RewardsPool.sol](/contracts/contract/RewardsPool.sol)               | 153  | Holds the unreleased GGP tokens to be distributed each rewards cycle                                                                                                                                      |
| [contracts/contract/Staking.sol](/contracts/contract/Staking.sol)                       | 256  | Allows a user to stake their GGP                                                                                                                                                                          |
| [contracts/contract/Storage.sol](/contracts/contract/Storage.sol)                       | 113  | Contains generic getters/setters to access it's storage. Other contracts are "registered" with the storage contract as a "Network Contract", and can then use it to read and write typed key/value pairs. |
| [contracts/contract/Vault.sol](/contracts/contract/Vault.sol)                           | 129  | Stores AVAX/ERC20 tokens on behalf of other network contracts                                                                                                                                             |
| [contracts/contract/tokens/TokenGGP.sol](/contracts/contract/tokens/TokenGGP.sol)       | 8    | Implements a fixed-supply, non-upgradeable GGP utility token                                                                                                                                              |
| [contracts/contract/tokens/TokenggAVAX.sol](/contracts/contract/tokens/TokenggAVAX.sol) | 174  | Implements an upgradeable (via OpenZeppelin proxy) ERC4626 yield-bearing liquid staking token                                                                                                             |

## Out of scope

This is the complete list of what's OUT of scope for this contest:
| Contract | SLOC |
| ----------------------------------------------------------------------------------------------------------------------------- | ---- |
| [contracts/contract/tokens/upgradeable/ERC20Upgradeable.sol](/contracts/contract/tokens/upgradeable/ERC20Upgradeable.sol) | 119 |
| [contracts/contract/tokens/upgradeable/ERC4626Upgradeable.sol](/contracts/contract/tokens/upgradeable/ERC4626Upgradeable.sol) | 102 |
| [contracts/contract/utils/Multicall.sol](/contracts/contract/utils/Multicall.sol) | 37 |
| [contracts/contract/utils/Multicall3.sol](/contracts/contract/utils/Multicall3.sol) | 157 |
| [contracts/contract/utils/OneInchMock.sol](/contracts/contract/utils/OneInchMock.sol) | 13 |
| [contracts/contract/utils/RialtoSimulator.sol](/contracts/contract/utils/RialtoSimulator.sol) | 91 |
| [contracts/contract/utils/WAVAX.sol](/contracts/contract/utils/WAVAX.sol) | 20 |
| [contracts/interface/IOneInch.sol](/contracts/interface/IOneInch.sol) | 5 |
| [contracts/interface/IWAVAX.sol](/contracts/interface/IWAVAX.sol) | 13 |
| [contracts/interface/IWithdrawer.sol](/contracts/interface/IWithdrawer.sol) | 4 |
| [contracts/types/MinipoolStatus.sol](/contracts/types/MinipoolStatus.sol) | 10 |

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
curl -L https://foundry.paradigm.xyz | bash
foundryup
forge install

just build
just test
forge test --gas-report
```

_Note: Many wardens run Slither as a first pass for testing. Please document any known errors with no workaround._
