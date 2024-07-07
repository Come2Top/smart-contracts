# <img src="https://github.com/DeftFinance/deft-game-contracts/blob/main/assets/COME2TOP-Logo.svg" width="32px" height="32px"> Come2Top Game

## Introduction
Come2Top operates as a decentralized, permissionless, fully on-chain, and peer-to-peer financial investing protocol. It employs a completely random process to distribute accumulated rewards from a farming campaign among investors. Unlike other reward distribution protocols, such as PoolTogether, where assets are locked until a winner is declared, Come2Top allows contributors to participate and withdraw their assets after the game’s lock period ends. By connecting to robust and trusted farming campaigns with a well-defined strategy, Come2Top offers a secure investment platform.

## Flow
<img src="https://github.com/DeftFinance/deft-game-contracts/blob/main/assets/Come2Top-Flow.png" width="100%" height="100%">

## important points
**Due to time constraints, fuzzy and functional tests are currently not available, although the system's operation has been ensured.**

**Everything in this game, relies on L1 Block, as a unit of time.**

**In each wave with operational status, the amount of time for that wave is based on the contracted amount divided by the wave counter, for e.g:**

*Operational Wave Period Time = 80 L1 Blocks*

*Wave 1 = 80 L1 Blocks*

*Wave 2 = 80/2 L1 Blocks*

...

*Wave 7 = 80/7 L1 Blocks*

**To quickly and accurately demonstrate performance under test conditions on the test network, the game concludes after an hour, unlike the mainnet system where the maximum duration is approximately 6 hours. As a result, all eligible participants can claim their base investment and saved amounts. Instead of the standard 30-day lock period required in the mainnet to ensure profitable performance and sufficient farming, the testnet awards approximately 1% profit to winners every day.**

## Required Feature (might be a FIP)
Since this project works with Prevrandao (L1 block.prevrandao) for RNG, there is no other way to create it; thus, for testing purposes, we made some dummy contracts that are used ONLY for test cases to demonstrate the potential of the current project.

**So as a result, one of the most important parts of this project that needed to be integrated on top of the Fraxtal Mainnet is the ***FraxchainL1Block*** contract, which is a systematic contract that stores the latest L1 block data.**

**Since there are some modifications on this contract by the Frax.Finance team and it's an upgradeable contract, our team thought that it would be possible and great if we had a data storage like a mapping (mapping(uint64 => bytes32) public numberToRandao) in which, every time the new L1 block arrives, the secuencer can pass it by the msg.data form within the modified version of setL1BlockValuesEcotone(), which only stores the new randao when there is a new L1 block.**

Also, it might be questioned how we handle the randaos in such a way that they are not gussable, since the OP-Stack chains are all 5˜7 L1 blocks posterior in storing compared to their L1, which is Ethereum here too!

**As a short answer, the randaos are required and used only BETWEEN the actionable rounds or waves on which players can act, and we call them ***ComingWave***, where we calculate the received randaos within this period of time. For safety, we have a safety duration of at least 48 L1 blocks on mainnet, and after these L1 blocks elapse, the shuffling algo finds its needed randaos and calculates so on.**

## Lite-paper
***For more information, consider reading the litepaper provided in this [link](https://github.com/DeftFinance/deft-game-contracts/blob/main/assets/Come2TopGame-Litepaper.pdf).***

## Script to start a game
```shell
forge script ./script/MultiJoin.s.sol:MultiJoin --rpc-url fraxtal-test --broadcast -vvvvv --legacy
```

## Deployments
## Fraxtal (Main-net)
### Come2Top: ``After +90% test coverage and C4/Sherlock audit``
### FraxStablecoin:  ``0xfc00000000000000000000000000000000000001``
### FraxchainL1Block: ``0x4200000000000000000000000000000000000015``
### Treasury: ``After +90% test coverage and C4/Sherlock audit``

## Fraxtal (Test-net)
### Come2Top: ``0x7f5002eD66e7759c6C05d657FC1cec8Dca66b834``
### DummyFraxStablecoin: ``0x502C17468b5d10466aBB4aB5F4E50E4c68941476``
### DummyFraxchainL1Block: ``0xD28feab50F6f4545771914FA36E2107B4e9c3928``
### Treasury: ``0x7e021A6756Db8baC4FE4731eeF41a660d27C99cc``
