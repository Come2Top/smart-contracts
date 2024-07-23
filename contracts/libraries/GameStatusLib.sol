// SPDX-License-Identifier: -- Come2Top --
pragma solidity 0.8.20;

import {GameStorageLib, Status, GameData} from "./GameStorageLib.sol";
import {GameImmutablesLib} from "./GameImmutablesLib.sol";
import {GameConstantsLib} from "./GameConstantsLib.sol";
import {GameTicketsLib} from "./GameTicketsLib.sol";
import {GameRNGlib} from "./GameRNGlib.sol";

library GameStatusLib {
    error WAIT_FOR_FIRST_WAVE();
    error ONLY_OPERATIONAL_MODE(Status currentStat);

    /**
        @notice Retrieves the current status and details of a specific game.
        @dev This function provides detailed information about a specific game
            including its status, eligible withdrawals, current wave, winner tickets, and game initialFraxBalance.
        @param gameID The ID of the game for which the status and details are being retrieved.
        @return stat The current status of the game
            {ticketSale, commingWave, operational, finished, claimable, completed}.
        @return eligibleToSell The number of eligible players to sell their tickets
            for the current game.
        @return currentWave The current wave of the game.
    */
    function gameUpdate(uint256 gameID)
        internal
        view
        returns (
            Status stat,
            int256 eligibleToSell,
            uint256 currentWave,
            bytes memory remainingTickets
        )
    {
        GameData memory GD = GameStorageLib.gameStorage().gameData[gameID];
        remainingTickets = GD.tickets;
        eligibleToSell = GD.eligibleToSell;

        uint256 currentL1Block = GameImmutablesLib.FRAXTAL_L1_BLOCK().number();

        if (GD.startedL1Block == 0) stat = Status.ticketSale;
        else if (GD.mooTokenBalance == 0) {
            stat = Status.completed;
            eligibleToSell = -1;
        } else {
            currentWave = GD.updatedWave;
            uint256 lastUpdatedWave;
            uint256 accumulatedBlocks;
            uint256 waitingDuration = GameConstantsLib.SAFTY_DURATION() +
                GD.prngPeriod;

            if (GD.updatedWave != 0) {
                lastUpdatedWave = GD.updatedWave + 1;

                for (uint256 i = 1; i < lastUpdatedWave; ) {
                    unchecked {
                        accumulatedBlocks +=
                            GameConstantsLib.WAVE_ELIGIBLES_TIME() /
                            i;
                        i++;
                    }
                }

                if (GD.eligibleToSell == -1) {
                    stat = GD.startedL1Block +
                        GameConstantsLib.L1_BLOCK_LOCK_TIME() +
                        accumulatedBlocks +
                        currentWave *
                        waitingDuration <
                        currentL1Block
                        ? Status.claimable
                        : Status.finished;

                    return (
                        stat,
                        eligibleToSell,
                        currentWave,
                        remainingTickets
                    );
                }
            } else {
                if (!(GD.startedL1Block + waitingDuration < currentL1Block))
                    return (
                        Status.commingWave,
                        eligibleToSell,
                        currentWave,
                        remainingTickets
                    );

                lastUpdatedWave = 1;
            }

            stat = Status.operational;
            uint256 prngDuration = GD.prngPeriod;

            while (true) {
                if (
                    GD.startedL1Block +
                        (lastUpdatedWave * waitingDuration) +
                        accumulatedBlocks <
                    currentL1Block
                ) {
                    remainingTickets = GameTicketsLib.shuffleBytedArray(
                        remainingTickets,
                        GameRNGlib.createRandomSeed(
                            GD.startedL1Block +
                                (lastUpdatedWave * waitingDuration) +
                                accumulatedBlocks,
                            prngDuration
                        ),
                        remainingTickets.length / 2
                    );

                    eligibleToSell = int256(remainingTickets.length / 2);

                    if (remainingTickets.length == 1) {
                        eligibleToSell = -1;
                        currentWave = lastUpdatedWave;

                        stat = GD.startedL1Block +
                            GameConstantsLib.L1_BLOCK_LOCK_TIME() +
                            accumulatedBlocks +
                            currentWave *
                            waitingDuration <
                            currentL1Block
                            ? Status.claimable
                            : Status.finished;

                        break;
                    }

                    unchecked {
                        accumulatedBlocks +=
                            GameConstantsLib.WAVE_ELIGIBLES_TIME() /
                            lastUpdatedWave;
                        currentWave++;
                        lastUpdatedWave++;
                    }
                } else {
                    if (
                        GD.startedL1Block +
                            (currentWave * waitingDuration) +
                            accumulatedBlocks <
                        currentL1Block
                    ) stat = Status.commingWave;

                    break;
                }
            }
        }
    }

    /**
        @dev Checks the current status of the game and reverts the transaction
            if the game status is not Operational.
        @param stat The current status of the game
            {ticketSale, commingWave, operational, finished, claimable, completed}.

    */
    function onlyOperational(uint256 currentWave, Status stat) internal pure {
        if (currentWave == 0) revert WAIT_FOR_FIRST_WAVE();

        if (stat != Status.operational) revert ONLY_OPERATIONAL_MODE(stat);
    }
}
