// SPDX-License-Identifier: -- Come2Top --
pragma solidity 0.8.20;

interface ICome2Top {
    enum Status {
        ticketSale,
        commingWave,
        operational,
        finished,
        claimable,
        completed
    }

    struct Offer {
        uint96 amount;
        address maker;
    }

    struct TicketInfo {
        Offer offer;
        uint256 ticketID;
        address owner;
    }

    error APROVE_OPERATION_FAILED();
    error CHECK_TICKETS_LENGTH(uint256 ticketLength);
    error FETCHED_CLAIMABLE_AMOUNT(
        Status stat, uint256 baseAmount, uint256 savedAmount, uint256 claimableAmount, int256 profit
    );
    error FRAX_TOKEN_NOT_FOUND();
    error INVALID_CURVE_PAIR();
    error NO_AMOUNT_TO_CLAIM();
    error NO_AMOUNT_TO_REFUND();
    error ONLY_CLAIMABLE_MODE(Status stat);
    error ONLY_EOA();
    error ONLY_HIGHER_THAN_CURRENT_OFFER_VALUE(uint256 offer, uint256 lastOfferValue);
    error ONLY_HIGHER_THAN_CURRENT_TICKET_VALUE(uint256 offer, uint256 ticketValue);
    error ONLY_OPERATIONAL_MODE(Status currentStat);
    error ONLY_OWNER();
    error ONLY_PAUSED_AND_FINISHED_MODE(bool isPaused, Status stat);
    error ONLY_TICKET_OWNER(uint256 ticketID);
    error ONLY_UNPAUSED_OR_TICKET_SALE_MODE(bool isPaused);
    error ONLY_WINNER_TICKET(uint256 ticketID);
    error PARTICIPATED_BEFORE();
    error SELECTED_TICKETS_SOLDOUT_BEFORE();
    error VALUE_CANT_BE_GREATER_THAN(uint256 givenValue);
    error VALUE_CANT_BE_LOWER_THAN(uint256 givenValue);
    error WAIT_FOR_FIRST_WAVE();
    error WAIT_FOR_NEXT_MATCH();
    error WAIT_FOR_NEXT_WAVE();
    error ZERO_ADDRESS_PROVIDED();
    error ZERO_UINT_PROVIDED();

    event Claimed(uint256 indexed gameID, address indexed player, uint256 amount, int256 profit);
    event GameFinished(uint256 indexed gameID, address[2] winners, uint256[2] amounts, uint256[2] ticketIDs);
    event GameStarted(uint256 indexed gameID, uint256 indexed startedBlockNo, uint256 amount);
    event GameUpdated(uint256 indexed gameID, address indexed winner, uint256 amount, uint256 ticketID);
    event OfferAccepted(address indexed newOwner, uint256 indexed ticketID, uint256 amount, address lastOwner);
    event OfferMade(address indexed maker, uint256 indexed ticketID, uint256 amount, address lastOfferor);
    event StaleOffersTookBack(address indexed maker, uint256 amount);
    event TicketsSold(address indexed buyer, bytes ticketIDs);

    function FRAX() external view returns (address);
    function FRAXTAL_L1_BLOCK() external view returns (address);
    function MAGIC_VALUE() external view returns (uint256);
    function THIS() external view returns (address);
    function TREASURY() external view returns (address);
    function changeGameStrat(uint8 newGameStrat) external;
    function changeMaxTicketsPerGame(uint8 newMTPG) external;
    function changeOwner(address newOwner) external;
    function changePRNGperiod(uint48 newPRNGP) external;
    function changeTicketPrice(uint80 newTP) external;
    function claimOperation(uint256 gameID) external;
    function claimableAmount(uint256 gameID, address player) external;
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
        );
    function currentGameID() external view returns (uint256);
    function currentGameStrat() external view returns (uint8);
    function gameData(uint256)
        external
        view
        returns (
            int8 eligibleToSell,
            uint8 soldTickets,
            uint8 updatedWave,
            uint8 chosenConfig,
            uint112 prngPeriod,
            uint112 startedL1Block,
            uint256 mooTokenBalance,
            uint256 initialFraxBalance,
            uint256 loanedFraxBalance,
            uint256 virtualFraxBalance,
            bytes memory tickets
        );
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
        );
    function gameStratConfig(uint256)
        external
        view
        returns (uint96 fraxTokenPosition, address curveStableNG, address beefyVault);
    function latestGameUpdate()
        external
        view
        returns (Status stat, int256 eligibleToSell, uint256 currentWave, bytes memory winnerTickets);
    function maxTicketsPerGame() external view returns (uint8);
    function offer(uint256, uint8) external view returns (uint96 amount, address maker);
    function offerOperation(uint8 ticketID, uint96 amount) external;
    function offerorData(address)
        external
        view
        returns (uint96 latestGameIDoffersValue, uint160 latestGameID, uint256 totalOffersValue);
    function owner() external view returns (address);
    function paginatedPlayerGames(uint256 page)
        external
        view
        returns (uint256 currentPage, uint256 totalPages, uint256[] memory paggedArray);
    function pause() external view returns (bool);
    function playerBalanceData(uint256, address)
        external
        view
        returns (uint120 initialFraxBalance, uint120 loanedFraxBalance);
    function playerRecentGames(address, uint256) external view returns (uint256);
    function prngPeriod() external view returns (uint248);
    function sliceBytedArray(bytes memory array, uint256 from, uint256 to) external pure returns (bytes memory);
    function staleOffers(address offeror) external view returns (uint256 totalStaleOffers, uint256 claimableOffers);
    function takeBackStaleOffers() external;
    function tempTicketOwnership(uint256, uint8) external view returns (address);
    function ticketPrice() external view returns (uint80);
    function ticketSaleOperation(uint8[] memory ticketIDs) external;
    function ticketValue() external view returns (uint256);
    function togglePause() external;
    function totalPlayerTickets(uint256, address) external view returns (uint8);
    function winnerOperation(uint8 ticketID) external;
}