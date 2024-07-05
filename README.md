# <img src="https://github.com/DeftFinance/deft-game-contracts/blob/main/assets/COME2TOP-Logo.svg" width="32px" height="32px"> Come2Top Game

## Introduction
Come2Top operates as a decentralized, permissionless, fully on-chain, and peer-to-peer financial investing protocol. It employs a completely random process to distribute accumulated rewards from a farming campaign among investors. Unlike other reward distribution protocols, such as PoolTogether, where assets are locked until a winner is declared, Come2Top allows contributors to participate and withdraw their assets after the game’s lock period ends. By connecting to robust and trusted farming campaigns with a well-defined strategy, Come2Top offers a secure investment platform.


## important points
**Due to time constraints, fuzzy and functional tests are currently not available, although the system's operation has been ensured.**
 
**To quickly and accurately demonstrate performance under test conditions on the test network, the game concludes after an hour, unlike the mainnet system where the maximum duration is approximately 6 hours. As a result, all eligible participants can claim their base investment and saved amounts. Instead of the standard 30-day lock period required in the mainnet to ensure profitable performance and sufficient farming, the testnet awards approximately 1% profit to winners every hour.**
 
***Under these conditions, participants who do not win might experience a slight loss in their initial investment. However, in the mainnet, this potential loss is minimal and close to zero.***

## Required Feature (might be a FIP)
**Since this project works with Prevrandao (L1 block.prevrandao) for RNG, there is no other way to create it; thus, for testing purposes, we made some dummy contracts that are used ONLY for test cases to demonstrate the potential of the current project.**

**So as a result, one of the most important parts of this project that needed to be integrated on top of the Fraxtal Mainnet is the ***FraxchainL1Block*** contract, which is a systematic contract that stores the latest L1 block data.**

**Since there are some modifications on this contract by the Frax.Finance team and it's an upgradeable contract, our team thought that it would be possible and great if we had a data storage like a mapping (mapping(uint64 => bytes32) public numberToRandao) in which, every time the new L1 block arrives, the secuencer can pass it by the msg.data form within the modified version of setL1BlockValuesEcotone(), which only stores the new randao when there is a new L1 block.**

## Deployments
## Fraxtal (Main-net)
### Come2Top: ``After Mannual Tests``
### Frax:  ``After Mannual Tests``
### L1Block: ``After Mannual Tests``
### Treasury: ``After Mannual Tests``

## Fraxtal (Test-net)
### Come2Top: ``0x87ad7BCb46509B7E3369790E66A42BEd8fCCC011``
### Frax: ``0xAb2C350b83D727C1b545CF9475C543826E88270c``
### L1Block: ``0x13B43491ebf9eF28B4A306f6774C81e08A49C2BB``
### Treasury: ``0x3166d0da11b8e5C18201E199F32d69f8d1d8ec8a``


## Test: ``forge test -vv``
