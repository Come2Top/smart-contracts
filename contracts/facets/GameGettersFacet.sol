// SPDX-License-Identifier: -- Come2Top --
pragma solidity 0.8.20;

import {ICurveStableNG} from "../interfaces/ICurveStableNG.sol";

import {GameStorageLib, GameStorage, Status, GameData, Offer, OfferorData, TicketInfo, PlayerGameBalance, StratConfig} from "../libraries/GameStorageLib.sol";
import {GameConstantsLib} from "../libraries/GameConstantsLib.sol";
import {GameImmutablesLib} from "../libraries/GameImmutablesLib.sol";
import {GameStatusLib} from "../libraries/GameStatusLib.sol";
import {GameTicketsLib} from "../libraries/GameTicketsLib.sol";
import {GameOffersLib} from "../libraries/GameOffersLib.sol";
import {CurveMooLib} from "../libraries/CurveMooLib.sol";

contract GameGettersFacet {
    /********************************\
    |-*-*-*-*-*   ERRORS   *-*-*-*-*-|
    \********************************/
    error FETCHED_CLAIMABLE_AMOUNT(
        Status stat,
        uint256 baseAmount,
        uint256 savedAmount,
        uint256 claimableAmount,
        int256 profit
    );

    /******************************\
    |-*-*-*-*-*   VIEW   *-*-*-*-*-|
    \******************************/
    // @dev Strange, isn't it? << Error Prone Getter >>
    function claimableAmount(address player, uint256 gameID) external {
        GameStorage storage gs = GameStorageLib.gameStorage();

        if (gameID > gs.currentGameID) gameID = gs.currentGameID;
        (Status stat, , , bytes memory tickets) = GameStatusLib.gameUpdate(
            gameID
        );

        uint256 playerInitialFraxBalance = gs
        .playerBalanceData[gameID][player].initialFraxBalance;
        uint256 playerLoanedFraxBalance = gs
        .playerBalanceData[gameID][player].loanedFraxBalance;

        if (
            tickets.length == 1 &&
            gs.tempTicketOwnership[gameID][uint8(tickets[0])] == player
        ) {
            playerLoanedFraxBalance += gs.gameData[gameID].virtualFraxBalance;
            delete gs.totalPlayerTickets[gameID][player];
        }

        if (
            (stat != Status.finished && stat != Status.claimable) ||
            playerInitialFraxBalance == 0
        ) revert FETCHED_CLAIMABLE_AMOUNT(stat, 0, 0, 0, 0);

        uint256 chosenConfig = gs.gameData[gameID].chosenConfig;
        uint256 mooShare = (gs.gameStratConfig[chosenConfig].beefyVault)
            .getPricePerFullShare();
        uint256 gameMooBalance = gs.gameData[gameID].mooTokenBalance;
        uint256 gameRewardedMoo = ((((gs.gameData[gameID].rewardedMoo +
            (((gameMooBalance * mooShare) / 1e18) -
                ((gameMooBalance * gs.gameData[gameID].mooShare) / 1e18))) *
            1e18) / ((gameMooBalance * mooShare) / 1e18)) *
            gs.gameData[gameID].mooTokenBalance) / 1e18;
        gameMooBalance -= gameRewardedMoo;

        uint256 gameInitialFraxBalance = gs.gameData[gameID].initialFraxBalance;
        uint256 gameLoanedFraxBalance = gs.gameData[gameID].loanedFraxBalance +
            gs.gameData[gameID].virtualFraxBalance;

        uint256 playerClaimableMooAmount;

        if (gameInitialFraxBalance == playerInitialFraxBalance) {
            playerClaimableMooAmount = gs.gameData[gameID].mooTokenBalance;

            delete gs.gameData[gameID].mooTokenBalance;
            delete gs.gameData[gameID].initialFraxBalance;
            delete gs.gameData[gameID].loanedFraxBalance;

            gs.gameData[gameID].tickets = tickets;
        } else {
            playerClaimableMooAmount =
                ((((playerInitialFraxBalance * 1e18) / gameInitialFraxBalance) *
                    (
                        gameLoanedFraxBalance == 0
                            ? gs.gameData[gameID].mooTokenBalance
                            : gameMooBalance
                    )) / 1e18) +
                (
                    gameLoanedFraxBalance == 0
                        ? 0
                        : (((playerLoanedFraxBalance * 1e18) /
                            gameLoanedFraxBalance) * gameRewardedMoo) / 1e18
                );

            gs.gameData[gameID].mooTokenBalance -= playerClaimableMooAmount;
            gs.gameData[gameID].initialFraxBalance -= playerInitialFraxBalance;
            if (gameLoanedFraxBalance != 0)
                gs.gameData[gameID].loanedFraxBalance -= gs
                .playerBalanceData[gameID][player].loanedFraxBalance;
        }

        delete gs.playerBalanceData[gameID][player];
        if (
            tickets.length == 1 &&
            gs.tempTicketOwnership[gameID][uint8(tickets[0])] == player
        ) delete gs.gameData[gameID].virtualFraxBalance;

        ICurveStableNG curveStableNG = gs
            .gameStratConfig[chosenConfig]
            .curveStableNG;
        uint256 beforeLPbalance = curveStableNG.balanceOf(
            GameImmutablesLib.THIS()
        );

        CurveMooLib.withdrawLPT(
            playerClaimableMooAmount,
            gs.gameStratConfig[chosenConfig].beefyVault
        );

        uint256 claimedAmount = CurveMooLib.burnLPT(
            curveStableNG.balanceOf(GameImmutablesLib.THIS()) - beforeLPbalance,
            msg.sender,
            gs.gameStratConfig[chosenConfig].fraxTokenPosition,
            curveStableNG
        );

        revert FETCHED_CLAIMABLE_AMOUNT(
            stat,
            playerInitialFraxBalance,
            playerLoanedFraxBalance,
            claimedAmount,
            int256(claimedAmount) - int256(playerInitialFraxBalance)
        );
    }

    /**
        @notice Returns all informations about the current game.
        @dev Usable for off-chain integrations.
        @return stat The current status of the game
            {ticketSale, commingWave, operational, finished, claimable, completed}.
        @return maxPurchasableTickets Maximum purchasable tickets for each address
            ased on {maxTicketsPerGame}.
        @return startedL1Block Started block number ofthe game, in which all tickets sold out.
        @return currentWave The current wave of the game.
        @return currentTicketValue The current value of a winning ticket in {FRAX} tokens.
        @return remainingTickets Total number of current wave winner tickets.
        @return eligibleToSell The number of eligible players to sell their tickets
            for the current wave of the game.
        @return nextWaveTicketValue The value of a winning ticket in {FRAX} tokens
            for the coming wave.
        @return nextWaveWinrate The chance of winning each ticket for the coming wave.
        @return tickets The byte array containing the winning ticket IDs for the current game.
        @return ticketsData An array of {TicketInfo} structures containing the ticket ID
            owner address and offer data for each winning ticket.
    */
    function continuesIntegration()
        external
        view
        returns (
            Status stat,
            uint256 maxPurchasableTickets,
            uint256 startedL1Block,
            uint256 currentWave,
            uint256 currentTicketValue,
            uint256 remainingTickets,
            int256 eligibleToSell,
            uint256 nextWaveTicketValue,
            uint256 nextWaveWinrate,
            bytes memory tickets,
            TicketInfo[256] memory ticketsData
        )
    {
        GameStorage storage gs = GameStorageLib.gameStorage();

        uint256 gameID = gs.currentGameID;
        maxPurchasableTickets = gs.maxTicketsPerGame;
        (stat, eligibleToSell, currentWave, tickets) = GameStatusLib.gameUpdate(
            gameID
        );

        uint256 index;

        if (stat != Status.commingWave && stat != Status.operational) {
            currentTicketValue = gs.ticketPrice;
            nextWaveTicketValue = currentTicketValue * 2;
            nextWaveWinrate = (GameConstantsLib.BASIS()**2) / 2;

            if (stat == Status.ticketSale) {
                remainingTickets =
                    GameConstantsLib.MAX_PARTIES() -
                    gs.gameData[gameID].soldTickets;
                while (index != GameConstantsLib.MAX_PARTIES()) {
                    ticketsData[index] = TicketInfo(
                        Offer(0, GameConstantsLib.ZERO_ADDRESS()),
                        index,
                        gs.tempTicketOwnership[gameID][uint8(index)]
                    );

                    unchecked {
                        index++;
                    }
                }
            } else {
                ticketsData[uint8(tickets[0])] = TicketInfo(
                    Offer(0, GameConstantsLib.ZERO_ADDRESS()),
                    uint8(tickets[0]),
                    gs.tempTicketOwnership[gameID][uint8(tickets[0])]
                );

                if (tickets.length == 2)
                    ticketsData[uint8(tickets[1])] = TicketInfo(
                        Offer(0, GameConstantsLib.ZERO_ADDRESS()),
                        uint8(tickets[1]),
                        gs.tempTicketOwnership[gameID][uint8(tickets[1])]
                    );
            }
        } else {
            remainingTickets = tickets.length;
            startedL1Block = gs.gameData[gameID].startedL1Block;
            currentTicketValue = GameTicketsLib.ticketValue(
                tickets.length,
                gameID
            );
            nextWaveTicketValue =
                gs.gameData[gameID].virtualFraxBalance /
                (tickets.length / 2);
            nextWaveWinrate =
                ((tickets.length / 2) * GameConstantsLib.BASIS()**2) /
                tickets.length;

            uint256 plus10PCT = currentTicketValue +
                (currentTicketValue *
                    GameConstantsLib.MIN_TICKET_VALUE_OFFER()) /
                GameConstantsLib.BASIS();

            while (index != tickets.length) {
                uint256 loadedOffer = gs
                .offer[gameID][uint8(tickets[index])].amount;
                ticketsData[uint8(tickets[index])] = TicketInfo(
                    Offer(
                        loadedOffer >= plus10PCT ? uint96(loadedOffer) : 0,
                        loadedOffer >= plus10PCT
                            ? gs.offer[gameID][uint8(tickets[index])].maker
                            : GameConstantsLib.ZERO_ADDRESS()
                    ),
                    uint8(tickets[index]),
                    gs.tempTicketOwnership[gameID][uint8(tickets[index])]
                );

                unchecked {
                    index++;
                }
            }

            index = 0;

            while (index != GameConstantsLib.MAX_PARTIES()) {
                if (ticketsData[index].owner == GameConstantsLib.ZERO_ADDRESS())
                    ticketsData[index].ticketID = index;

                unchecked {
                    index++;
                }
            }
        }
    }

    /**
        @notice Retrieves the latest update of the current game.
        @dev It provides essential information about the {currentGameID} game's state.
        @return stat The current status of the game
            {ticketSale, commingWave, operational, finished, claimable, completed}.
        @return eligibleToSell The number of eligible players to sell their tickets 
            for the current wave of the game.
        @return currentWave The current wave of the game.
        @return winnerTickets The byte array containing the winning ticket IDs for the {currentGameID}.
    */
    function latestGameUpdate()
        external
        view
        returns (
            Status stat,
            int256 eligibleToSell,
            uint256 currentWave,
            bytes memory winnerTickets
        )
    {
        return
            GameStatusLib.gameUpdate(
                GameStorageLib.gameStorage().currentGameID
            );
    }

    /**
        @notice Retrieves the current status and details of a specific game.
        @dev This function provides detailed information about a specific game
            including its status, eligible withdrawals, current wave, winner tickets, and game virtualFraxBalance.
        @param gameID_ The ID of the game for which the status and details are being retrieved.
        @return gameID The ID of the retrieved game.
        @return stat The current status of the game
            {ticketSale, commingWave, operational, finished, claimable, completed}.
        @return eligibleToSell The number of eligible players to sell their tickets 
            for the current wave of the game.
        @return currentWave The current wave of the game.
        @return virtualFraxBalance The balance of the game in {FRAX} tokens
            which players compete in terms of to get a {loanedFraxBalance}
            in which they will get a share of it from the yield farming protocol.
        @return winners The array containing the winner addresses for the given game ID.
        @return winnerTickets The array containing the winning ticket IDs for the given game ID.
    */
    function gameStatus(uint256 gameID_)
        external
        view
        returns (
            uint256 gameID,
            Status stat,
            int256 eligibleToSell,
            uint256 currentWave,
            uint256 virtualFraxBalance,
            address[] memory winners,
            uint256[] memory winnerTickets
        )
    {
        GameStorage storage gs = GameStorageLib.gameStorage();

        if (gameID_ > gs.currentGameID) gameID = gs.currentGameID;
        else gameID = gameID_;

        virtualFraxBalance = gs.gameData[gameID].virtualFraxBalance;

        bytes memory tickets;
        (stat, eligibleToSell, currentWave, tickets) = GameStatusLib.gameUpdate(
            gameID
        );

        winners = new address[](tickets.length);
        winnerTickets = new uint256[](tickets.length);

        for (uint256 i; i < tickets.length; ) {
            winners[i] = gs.tempTicketOwnership[gameID][
                uint8(bytes1(tickets[i]))
            ];
            winnerTickets[i] = uint8(bytes1(tickets[i]));

            unchecked {
                i++;
            }
        }
    }

    function paginatedPlayerGames(address player, uint256 page)
        external
        view
        returns (
            uint256 currentPage,
            uint256 totalPages,
            uint256[] memory paggedArray
        )
    {
        GameStorage storage gs = GameStorageLib.gameStorage();

        if (gs.playerRecentGames[player].length == 0)
            return (currentPage, totalPages, paggedArray);
        else if (gs.playerRecentGames[player].length < 11) {
            paggedArray = new uint256[](gs.playerRecentGames[player].length);

            uint256 x;
            while (true) {
                paggedArray[x] = gs.playerRecentGames[player][
                    gs.playerRecentGames[player].length - 1 - x
                ];

                if (x == gs.playerRecentGames[player].length - 1) break;

                unchecked {
                    x++;
                }
            }

            return (1, 1, paggedArray);
        }

        if (page == 0) page = 1;

        totalPages = gs.playerRecentGames[player].length / 10;

        uint256 diffLength = gs.playerRecentGames[player].length -
            (totalPages * 10);

        if (totalPages * 10 < gs.playerRecentGames[player].length) totalPages++;
        if (page > totalPages) page = totalPages;
        currentPage = page;

        uint256 firstIndex;
        uint256 lastIndex;
        if (page == 1) {
            firstIndex = gs.playerRecentGames[player].length - 1;
            lastIndex = firstIndex - 10;
        } else if (page == totalPages)
            firstIndex = diffLength == 0 ? firstIndex = 9 : diffLength - 1;
        else {
            firstIndex +=
                ((totalPages - page) * 10) +
                (diffLength != 0 ? diffLength - 1 : 0);
            lastIndex +=
                ((totalPages - page - 1) * 10) +
                (diffLength != 0 ? diffLength - 1 : 0);
        }

        paggedArray = new uint256[]((firstIndex + 1) - lastIndex);

        uint256 i;
        while (true) {
            paggedArray[i] = gs.playerRecentGames[player][firstIndex];

            if (firstIndex == lastIndex) break;
            unchecked {
                i++;
                firstIndex--;
            }
        }
    }

    /**
        @notice Retrieves the current value of a ticket in {FRAX} tokens.
        @dev Calculates and returns the current value of a ticket:
            If it was in ticket sale mode, then the ticket value is equal to {ticketPrice}
            Else by dividing the initialFraxBalance of {FRAX} tokens in the contract
                by the total number of winning tickets.
        @return The current value of a ticket in {FRAX} tokens, based on status.
    */
    function ticketValue() external view returns (uint256) {
        (Status stat, , , bytes memory tickets) = GameStatusLib.gameUpdate(
            GameStorageLib.gameStorage().currentGameID
        );

        if (stat != Status.commingWave && stat != Status.operational)
            return GameStorageLib.gameStorage().ticketPrice;

        return
            GameTicketsLib.ticketValue(
                tickets.length,
                GameStorageLib.gameStorage().currentGameID
            );
    }

    /**
        @notice Retrieves the total stale offer amount for a specific offeror.
        @param offeror The address of the offeror for whom the stale offer amount is being retrieved.
        @return totalStaleOffers The total stale offer amount for the specified offeror.
        @return claimableOffers The total claimable stale amount for the specified offeror.
    */
    function staleOffers(address offeror)
        external
        view
        returns (uint256 totalStaleOffers, uint256 claimableOffers)
    {
        totalStaleOffers = GameStorageLib
            .gameStorage()
            .offerorData[offeror]
            .totalOffersValue;
        claimableOffers = GameOffersLib.staleOffers(offeror);
    }
}
