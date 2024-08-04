// SPDX-License-Identifier: -- Come2Top --
pragma solidity 0.8.20;

import {DiamondLib} from "../libraries/DiamondLib.sol";
import {GameStorageLib, Status, GameData} from "../libraries/GameStorageLib.sol";
import {GameConstantsLib} from "../libraries/GameConstantsLib.sol";
import {GameUintCheckersLib} from "../libraries/GameUintCheckersLib.sol";
import {GameStatusLib} from "../libraries/GameStatusLib.sol";

contract AdminstrationFacet {
    /********************************\
    |-*-*-*-*-*   ERRORS   *-*-*-*-*-|
    \********************************/
    error ONLY_EOA();
    error ONLY_OWNER();
    error ONLY_PAUSED_AND_FINISHED_MODE(bool isPaused, Status stat);

    /*******************************\
    |-*-*-*-*   MODIFIERS   *-*-*-*-|
    \*******************************/
    modifier onlyEOA() {
        if (msg.sender != tx.origin) revert ONLY_EOA();

        _;
    }

    modifier onlyOwner() {
        DiamondLib.enforceIsContractOwner();

        _;
    }

    modifier onlyPausedAndFinishedGame() {
        (Status stat, , , ) = GameStatusLib.gameUpdate(GameStorageLib.gameStorage().currentGameID);

        if (!GameStorageLib.gameStorage().pause || uint256(stat) <= 2)
            revert ONLY_PAUSED_AND_FINISHED_MODE(
                GameStorageLib.gameStorage().pause,
                stat
            );

        _;
    }

    /*******************************\
    |-*-*-*   ADMINSTRATION   *-*-*-|
    \*******************************/
    /**
        @notice Changes the current game strategy vault.
        @dev Allows the current owner to change the current game strategy vault.
    */
    function changeGameStrat(uint8 newGameStrat) external onlyOwner {
        GameUintCheckersLib.checkGS(newGameStrat);

        GameStorageLib.gameStorage().currentGameStrat = newGameStrat;
    }

    /**
        @notice Toggles the pause state of the contract.
        @dev Allows the owner to toggle the pause state of the contract.
            When the contract is paused, certain functions may be restricted or disabled.
            Only the owner can call this function to toggle the pause state.
    */
    function togglePause() external onlyOwner {
        GameStorageLib.gameStorage().pause = !GameStorageLib.gameStorage().pause;
    }

    /**
        @notice Changes the ticket price for joining the game.
        @dev Allows the owner to change the ticket price for joining the game.
            Only the owner can call this function.
        @param newTP The new ticket price is to be set.
    */
    function changeTicketPrice(uint80 newTP)
        external
        onlyOwner
        onlyPausedAndFinishedGame
    {
        GameUintCheckersLib.checkTP(newTP);

        GameStorageLib.gameStorage().ticketPrice = newTP;
    }

    /**
        @notice Changes the maximum number of tickets allowed per game.
        @dev Allows the owner to change the maximum number of tickets allowed per game.
            Only the owner can call this function.
        @param newMTPG The new maximum number of tickets allowed per game.
    */
    function changeMaxTicketsPerGame(uint8 newMTPG)
        external
        onlyOwner
        onlyPausedAndFinishedGame
    {
        GameUintCheckersLib.checkMTPG(newMTPG);

        GameStorageLib.gameStorage().maxTicketsPerGame = newMTPG;
    }

    /**
        @notice Changes the pseudorandom number generator period time.
        @dev Allows the owner to change the pseudorandom number generator period time.
            Only the owner can call this function.
        @param newPRNGP The new pseudorandom number generator period.
    */
    function changePRNGperiod(uint48 newPRNGP)
        external
        onlyOwner
        onlyPausedAndFinishedGame
    {
        GameUintCheckersLib.checkPRNGP(newPRNGP);

        GameStorageLib.gameStorage().prngPeriod = newPRNGP;
    }
}
