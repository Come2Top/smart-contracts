// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface Interface {
    type Status is uint8;

    struct TicketInfo {
        uint256 ticketID;
        address owner;
    }

    error APROVE_OPERATION_FAILED();
    error CHECK_TICKETS_LENGTH(uint256 ticketLength);
    error FEWER_TICKETS_LEFT(uint256 remainingTickets);
    error NO_AMOUNT_TO_REFUND();
    error OFFER_NOT_FOUND();
    error ONLY_ADMIN();
    error ONLY_EOA();
    error ONLY_HIGHER_THAN_CURRENT_OFFER_VALUE(
        uint256 offer,
        uint256 lastOfferValue
    );
    error ONLY_HIGHER_THAN_CURRENT_TICKET_VALUE(
        uint256 offer,
        uint256 ticketValue
    );
    error ONLY_PAUSED_AND_FINISHED_MODE(bool isPaused);
    error ONLY_TICKET_OWNER(uint256 ticketID);
    error ONLY_UNPAUSED_OR_TICKET_SALE_MODE(bool isPaused);
    error ONLY_WINNER_TICKET(uint256 ticketID);
    error ONLY_WITHDRAWABLE_MODE(Status currentStat);
    error PARTICIPATED_BEFORE();
    error PLAYER_HAS_NO_TICKETS();
    error SLECTED_TICKETS_SOLDOUT_BEFORE();
    error VALUE_CANT_BE_GREATER_THAN(uint256 givenValue);
    error VALUE_CANT_BE_LOWER_THAN(uint256 givenValue);
    error WAIT_FOR_FIRST_WAVE();
    error WAIT_FOR_NEXT_WAGER_MATCH();
    error ZERO_ADDRESS_PROVIDED();
    error ZERO_UINT_PROVIDED();

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
        uint256 ticketID
    );
    event WagerFinished(
        uint256 indexed wagerID,
        address[2] winners,
        uint256[2] amounts,
        uint256[2] ticketIDs
    );
    event OfferAccepted(
        address indexed newOwner,
        uint256 indexed ticketID,
        uint256 indexed amount,
        address lastOwner
    );
    event OfferMade(
        address indexed maker,
        uint256 indexed ticketID,
        uint256 indexed amount,
        address lastOfferor
    );
    event StaleOffersTookBack(
        address indexed maker,
        address indexed to,
        uint256 indexed amount
    );

    function togglePause() external;

    function changeTicketPrice(uint80 ticketPrice_) external;

    function changeMaxTicketsPerWager(uint8 maxTicketsPerWager_) external;

    function joinWager(uint8[] memory ticketIDs) external;

    function receiveWagerPrize(uint8 ticketID) external;

    function makeOffer(uint8 ticketID, uint96 amount) external;

    function acceptOffers(uint8 ticketID) external;

    function takeBackStaleOffers(address to) external;

    function ADMIN() external view returns (address);

    function MAGIC_VALUE() external view returns (uint256);

    function THIS() external view returns (address);

    function TICKET256() external view returns (bytes memory);

    function TREASURY() external view returns (address);

    function USDT() external view returns (address);

    function pause() external view returns (bool);

    function maxTicketsPerWager() external view returns (uint8);

    function currentWagerID() external view returns (uint160);

    function ticketPrice() external view returns (uint80);

    function totalPlayerTickets(uint256, address) external view returns (uint8);

    function ticketOwnership(uint256, uint8) external view returns (address);

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

    function offer(uint256, uint8)
        external
        view
        returns (uint96 amount, address maker);

    function offerorData(address)
        external
        view
        returns (
            uint96 latestWagerIDoffersValue,
            uint160 latestWagerID,
            uint256 totalOffersValue
        );

    function getLatestUpdate()
        external
        view
        returns (
            Status stat,
            int256 eligibleWithdrawals,
            uint256 currentWave,
            bytes memory tickets
        );

    function currentTicketValue() external view returns (uint256);

    function currentWinnersWithTickets()
        external
        view
        returns (int256 eligibleWithdrawals, TicketInfo[] memory);

    function playerWithWinningTickets(address player)
        external
        view
        returns (uint256 totalTicketsValue, bytes memory playerTickets);

    function getStaleOfferorAmount(address offeror)
        external
        view
        returns (uint256);

    function returnBytedCalldataArray(
        bytes memory array,
        uint256 from,
        uint256 to
    ) external pure returns (bytes memory);
}
