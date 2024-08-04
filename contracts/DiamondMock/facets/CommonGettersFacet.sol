// SPDX-License-Identifier: -- Come2Top --
pragma solidity 0.8.20;

import {GameStorageLib, GameData, Offer, OfferorData, PlayerGameBalance, StratConfig} from "../libraries/GameStorageLib.sol";

contract CommonGettersFacet {
    /******************************\
    |-*-*-*-*-*   VIEW   *-*-*-*-*-|
    \******************************/
    function pause() external view returns (bool) {
        return GameStorageLib.gameStorage().pause;
    }

    function maxTicketsPerGame() external view returns (uint8) {
        return GameStorageLib.gameStorage().maxTicketsPerGame;
    }

    function ticketPrice() external view returns (uint80) {
        return GameStorageLib.gameStorage().ticketPrice;
    }

    function currentGameStrat() external view returns (uint8) {
        return GameStorageLib.gameStorage().currentGameStrat;
    }

    function prngPeriod() external view returns (uint248) {
        return GameStorageLib.gameStorage().prngPeriod;
    }

    function currentGameID() external view returns (uint256) {
        return GameStorageLib.gameStorage().currentGameID;
    }

    function gameStratConfig() external view returns (StratConfig[7] memory) {
        return GameStorageLib.gameStorage().gameStratConfig;
    }

    function gameData(uint256 gameID) external view returns (GameData memory) {
        return GameStorageLib.gameStorage().gameData[gameID];
    }

    function offerorData(address offeror)
        external
        view
        returns (OfferorData memory)
    {
        return GameStorageLib.gameStorage().offerorData[offeror];
    }

    function tempTicketOwnership(uint256 gameID, uint8 ticketID)
        external
        view
        returns (address)
    {
        return
            GameStorageLib.gameStorage().tempTicketOwnership[gameID][ticketID];
    }

    function totalPlayerTickets(uint256 gameID, address player)
        external
        view
        returns (uint8)
    {
        return GameStorageLib.gameStorage().totalPlayerTickets[gameID][player];
    }

    function playerBalanceData(uint256 gameID, address player)
        external
        view
        returns (PlayerGameBalance memory)
    {
        return GameStorageLib.gameStorage().playerBalanceData[gameID][player];
    }

    function offer(uint256 gameID, uint8 ticketID)
        external
        view
        returns (Offer memory)
    {
        return GameStorageLib.gameStorage().offer[gameID][ticketID];
    }

    function playerRecentGames(address player, uint256 index)
        external
        view
        returns (uint256)
    {
        return GameStorageLib.gameStorage().playerRecentGames[player][index];
    }
}
