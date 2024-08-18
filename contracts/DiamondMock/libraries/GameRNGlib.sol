// SPDX-License-Identifier: -- Come2Top --
pragma solidity 0.8.20;

import {IFraxtalL1Block} from "../../interfaces/IFraxtalL1Block.sol";
import {GameImmutablesLib} from "./GameImmutablesLib.sol";

library GameRNGlib {
    /**
        @dev Creates a random seed value based on a series of l1 block prevrandaos.
            It selects various block prevrandaos and performs mathematical operations to calculate a random seed.
        @param startBlock The block number from where the calculation of the random seed starts.
        @return The random seed value generated based on l1 block prevrandaos.
    */
    function createRandomSeed(uint256 startBlock, uint256 prngDuration)
        internal
        view
        returns (uint256)
    {
        unchecked {
            return
                uint256(
                    keccak256(
                        abi.encodePacked(
                            uint256(
                                sha256(
                                    abi.encodePacked(
                                        GameImmutablesLib.FRAXTAL_L1_BLOCK().numberToRandao(
                                            uint64(
                                                startBlock - prngDuration / 3
                                            )
                                        )
                                    )
                                )
                            ) +
                                GameImmutablesLib.FRAXTAL_L1_BLOCK().numberToRandao(
                                    uint64(startBlock - prngDuration / 2)
                                ) +
                                uint160(
                                    ripemd160(
                                        abi.encodePacked(
                                            uint160(
                                                GameImmutablesLib.FRAXTAL_L1_BLOCK().numberToRandao(
                                                    uint64(
                                                        startBlock -
                                                            (prngDuration * 2) /
                                                            3
                                                    )
                                                )
                                            )
                                        )
                                    )
                                )
                        )
                    )
                ) * GameImmutablesLib.MAGIC_VALUE();
        }
    }
}
