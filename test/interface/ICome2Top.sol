// SPDX-License-Identifier: -- Come2Top --
pragma solidity 0.8.20;

interface ICome2Top {
    /*******************************\
    |-*-*-*-*-*   TYPES   *-*-*-*-*-|
    \*******************************/
    type Status is uint8;

    struct Offer {
        uint96 amount;
        address maker;
    }

    struct TicketInfo {
        Offer offer;
        uint256 ticketID;
        address owner;
    }

    /********************************\
    |-*-*-*-*-*   EVENTS   *-*-*-*-*-|
    \********************************/
    event TicketsSold(address indexed buyer, bytes ticketIDs);

    event WagerStarted(
        uint256 indexed wagerID,
        uint256 indexed startedBlockNo,
        uint256 indexed prizeAmount
    );

    event WagerUpdated(
        uint256 indexed wagerID,
        address indexed winner,
        uint256 indexed amount,
        uint256 ticketID
    );

    event WagerFinished(
        uint256 indexed wagerID,
        address indexed winner,
        uint256 indexed amount,
        uint256 ticketID,
        uint256 cooldown
    );

    event WagerFinished(
        uint256 indexed wagerID,
        address[2] winners,
        uint256[2] amounts,
        uint256[2] ticketIDs,
        uint256 cooldown
    );

    event OfferMade(
        address indexed maker,
        uint256 indexed ticketID,
        uint256 indexed amount,
        address lastOfferor
    );

    event OfferAccepted(
        address indexed newOwner,
        uint256 indexed ticketID,
        uint256 indexed amount,
        address lastOwner
    );

    event StaleOffersTookBack(
        address indexed maker,
        address indexed to,
        uint256 indexed amount
    );

    /********************************\
    |-*-*-*-*-*   ERRORS   *-*-*-*-*-|
    \********************************/
    error ONLY_EOA();
    error ONLY_OWNER();
    error ONLY_TICKET_OWNER(uint256 ticketID);
    error ONLY_WINNER_TICKET(uint256 ticketID);
    error ONLY_WITHDRAWABLE_MODE(Status currentStat);
    error ONLY_PAUSED_AND_FINISHED_MODE(bool isPaused);
    error ONLY_UNPAUSED_OR_TICKET_SALE_MODE(bool isPaused);
    error ONLY_HIGHER_THAN_CURRENT_TICKET_VALUE(
        uint256 offer,
        uint256 ticketValue
    );
    error ONLY_HIGHER_THAN_CURRENT_OFFER_VALUE(
        uint256 offer,
        uint256 lastOfferValue
    );
    error APROVE_OPERATION_FAILED();
    error VALUE_CANT_BE_LOWER_THAN(uint256 givenValue);
    error ZERO_ADDRESS_PROVIDED();
    error ZERO_UINT_PROVIDED();
    error CHECK_TICKETS_LENGTH(uint256 ticketLength);
    error SELECTED_TICKETS_SOLDOUT_BEFORE();
    error PARTICIPATED_BEFORE();
    error PLAYER_HAS_NO_TICKETS();
    error NO_AMOUNT_TO_REFUND();
    error COOLDOWN_NOT_YET_ENDED(uint256 cooldownBlock, uint256 currentBlock);
    error WAIT_FOR_NEXT_WAGER_MATCH();
    error WAIT_FOR_FIRST_WAVE();

    /*******************************\
    |-*-*-*   ADMINSTRATION   *-*-*-|
    \*******************************/
    function changeOwner(address newOwner) external;

    function togglePause() external;

    function changeTicketPrice(uint80 ticketPrice_) external;

    function changeMaxTicketsPerWager(uint8 maxTicketsPerWager_) external;

    /*********************************\
    |-*-*-*-*   WAGER-LOGIC   *-*-*-*-|
    \*********************************/
    function join(uint8[] memory ticketIDs) external;

    function redeem(uint8 ticketID) external;

    function makeOffer(uint8 ticketID, uint96 amount) external;

    function takeBackStaleOffers(address to) external;

    /******************************\
    |-*-*-*-*-*   VIEW   *-*-*-*-*-|
    \******************************/
    function pause() external view returns (bool);

    function maxTicketsPerWager() external view returns (uint8);

    function ticketPrice() external view returns (uint80);

    function owner() external view returns (address);

    function currentWagerID() external view returns (uint256);

    function wagerData(uint256)
        external
        view
        returns (
            int8 eligibleWithdrawals,
            uint8 soldTickets,
            uint8 updatedWave,
            uint216 startedBlock,
            bytes memory tickets
        );

    function offerorData(address)
        external
        view
        returns (
            uint96 latestWagerIDoffersValue,
            uint160 latestWagerID,
            uint256 totalOffersValue
        );

    function ticketOwnership(uint256, uint8) external view returns (address);

    function totalPlayerTickets(uint256, address) external view returns (uint8);

    function offer(uint256, uint8)
        external
        view
        returns (uint96 amount, address maker);

    function USDT() external view returns (address);

    function TREASURY() external view returns (address);

    function THIS() external view returns (address);

    function MAGIC_VALUE() external view returns (uint256);

    function wagerInfo()
        external
        view
        returns (
            Status stat,
            uint256 maxPurchasableTickets,
            uint256 startedBlock,
            uint256 currentWave,
            uint256 currentTicketValue,
            uint256 remainingTickets,
            int256 eligibleWithdrawals,
            uint256 nextWaveTicketValue,
            uint256 nextWaveWinrate,
            bytes memory tickets,
            TicketInfo[256] memory ticketsData
        );

    function ticketValue() external view returns (uint256);

    function winnersWithTickets()
        external
        view
        returns (int256 eligibleWithdrawals, TicketInfo[] memory allTicketsData);

    function playerWithWinningTickets(address player)
        external
        view
        returns (uint256 totalTicketsValue, bytes memory playerTickets);

    function staleOffers(address offeror) external view returns (uint256);

    function sliceBytedArray(
        bytes calldata array,
        uint256 from,
        uint256 to
    ) external pure returns (bytes memory);

    function latestUpdate()
        external
        view
        returns (
            Status stat,
            int256 eligibleWithdrawals,
            uint256 currentWave,
            bytes memory winnerTickets
        );
}
