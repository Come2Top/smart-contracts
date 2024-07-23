// SPDX-License-Identifier: -- Come2Top --
pragma solidity 0.8.20;

import {IBeefyVault} from "../interfaces/IBeefyVault.sol";
import {ICurveStableNG} from "../interfaces/ICurveStableNG.sol";

enum Status {
    ticketSale,
    commingWave,
    operational,
    finished,
    claimable,
    completed
}

struct GameData {
    int8 eligibleToSell;
    uint8 soldTickets;
    uint8 updatedWave;
    uint8 chosenConfig;
    uint112 prngPeriod;
    uint112 startedL1Block;
    uint256 mooShare;
    uint256 mooTokenBalance;
    uint256 rewardedMoo;
    uint256 initialFraxBalance;
    uint256 loanedFraxBalance;
    uint256 virtualFraxBalance;
    bytes tickets;
}

struct Offer {
    uint96 amount;
    address maker;
}

struct OfferorData {
    uint96 latestGameIDoffersValue;
    uint160 latestGameID;
    uint256 totalOffersValue;
}

struct TicketInfo {
    Offer offer;
    uint256 ticketID;
    address owner;
}

struct PlayerGameBalance {
    uint120 initialFraxBalance;
    uint120 loanedFraxBalance;
}

struct StratConfig {
    uint96 fraxTokenPosition;
    ICurveStableNG curveStableNG;
    IBeefyVault beefyVault;
}

struct GameStorage {
    bool pause;
    uint8 maxTicketsPerGame;
    uint80 ticketPrice;
    uint8 currentGameStrat;
    uint248 prngPeriod;
    uint256 currentGameID;
    StratConfig[7] gameStratConfig;
    mapping(uint256 => GameData) gameData;
    mapping(address => OfferorData) offerorData;
    mapping(uint256 => mapping(uint8 => address)) tempTicketOwnership;
    mapping(uint256 => mapping(address => uint8)) totalPlayerTickets;
    mapping(uint256 => mapping(address => PlayerGameBalance)) playerBalanceData;
    mapping(uint256 => mapping(uint8 => Offer)) offer;
    mapping(address => uint256[]) playerRecentGames;
}

library GameStorageLib {
    function gameStorage() internal pure returns (GameStorage storage gs) {
        assembly {
            gs.slot := 0
        }
    }
}
