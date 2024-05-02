// SPDX-License-Identifier: -- Come2Top --
pragma solidity 0.8.20;

interface ICome2Top {
    /*******************************\
    |-*-*-*-*-*   TYPES   *-*-*-*-*-|
    \*******************************/
    enum Status {
        ticketSale,
        waitForCommingWave,
        Withdrawable,
        finished
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
        uint256 ticketID
    );

    event WagerFinished(
        uint256 indexed wagerID,
        address[2] winners,
        uint256[2] amounts,
        uint256[2] ticketIDs
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

    event StaleOffersTookBack(address indexed maker, uint256 indexed amount);

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
    error VALUE_CANT_BE_GREATER_THAN(uint256 givenValue);
    error ZERO_ADDRESS_PROVIDED();
    error ZERO_UINT_PROVIDED();
    error CHECK_TICKETS_LENGTH(uint256 ticketLength);
    error SELECTED_TICKETS_SOLDOUT_BEFORE();
    error PARTICIPATED_BEFORE();
    error PLAYER_HAS_NO_TICKETS();
    error NO_AMOUNT_TO_REFUND();
    error WAIT_FOR_NEXT_WAGER_MATCH();
    error WAIT_FOR_FIRST_WAVE();
    error WAIT_FOR_NEXT_WAVE();
    error WAGER_FINISHED();

    /*******************************\
    |-*-*-*   ADMINSTRATION   *-*-*-|
    \*******************************/
    /**
        @notice Changes the owner of the contract.
        @dev Allows the current owner to transfer the ownership to a new address.
    */
    function changeOwner(address newOwner) external;

    /**
        @notice Toggles the pause state of the contract.
        @dev Allows the owner to toggle the pause state of the contract.
            When the contract is paused, certain functions may be restricted or disabled.
            Only the owner can call this function to toggle the pause state.
    */
    function togglePause() external;

    /**
        @notice Changes the ticket price for joining the wager.
        @dev Allows the owner to change the ticket price for joining the wager. 
            Only the owner can call this function. 
        @param ticketPrice_ The new ticket price to be set.
    */
    function changeTicketPrice(uint80 ticketPrice_) external;

    /**
        @notice Changes the maximum number of tickets allowed per wager.
        @dev Allows the owner to change the maximum number of tickets allowed per wager. 
            Only the owner can call this function.
        @param maxTicketsPerWager_ The new maximum number of tickets allowed per wager.
    */
    function changeMaxTicketsPerWager(uint8 maxTicketsPerWager_) external;

    /*********************************\
    |-*-*-*-*   WAGER-LOGIC   *-*-*-*-|
    \*********************************/
    /**
        @notice Players can buy tickets for wagering.
        @dev Manages the ticket allocation, ownership, and purchase process.
            Also ensures that the maximum number of tickets specified by {maxTicketsPerWager}
            and the ticket price set by {ticketPrice} are adhered to.
            The player joining the wager, must be an externally owned account (EOA).
        @param ticketIDs The ticket IDs that players want to buy for a wager.
    */
    function join(uint8[] calldata ticketIDs) external;

    /**
        @notice Allows the ticket owner to either accept an offer made for their ticket 
            or claim the prize for a winning lottery ticket. 
        @dev
            1. When accepting an offer:
                If the player has received an offer for their ticket
                    that is higher than the current ticket value
                    and the last offer, they can accept the offer.
                The function transfers the ownership of the ticket
                    to the offer maker and transfers the offered amount
                    to the ticket owner.

            2. When claiming a prize for a winning lottery ticket:
                If the ticket owner tries to claim the prize for a winning ticket
                    the function checks if the wager status allows for withdrawals
                    if the player owns the ticket
                    and if the ticket is eligible for withdrawals.
                If the wager has ended and there are two winners
                    the prize amount is split between them.
        @param ticketID The ID of the ticket for which the offer is being accepted.
    */
    function redeem(uint8 ticketID) external;

    /**
        @notice Allows anyone to have the prize sent to the winning ticket holder.
        @param wagerID The ID of the wager for which the owner of the winning ticket will get the prize.
    */
    function claim(uint256 wagerID) external;

    /**
        @notice Allows a player to make an offer for a ticket.
        @dev Allows a player to make an offer for a specific ticket.
            The player specifies the ticket ID and the amount of the offer.
            If the offered amount is higher than the current ticket value and the last offer
            the offer is accepted and stored.
            If a higher offer is made for the same ticket
            the previous offer is refunded to the maker.
            The player making the offer, must be an externally owned account (EOA).
        @param ticketID The ID of the ticket for which the offer is being made.
        @param amount The amount of the offer in USDT tokens.
    */
    function makeOffer(uint8 ticketID, uint96 amount) external;

    /**
        @notice Allows the offeror to take back their stale offers and receive a refund.
        @dev Enables the player to withdraw their offers that have not been accepted
            and receive a refund in return.
            Only the player who made the offers can call this function.
    */
    function takeBackStaleOffers() external;

    /******************************\
    |-*-*-*-*-*   VIEW   *-*-*-*-*-|
    \******************************/
    function pause() external view returns (bool);

    function maxTicketsPerWager() external view returns (uint8);

    function ticketPrice() external view returns (uint80);

    function owner() external view returns (address);

    function currentWagerID() external view returns (uint256);

    function wagerData(
        uint256
    )
        external
        view
        returns (
            int8 eligibleWithdrawals,
            uint8 soldTickets,
            uint8 updatedWave,
            uint96 balance,
            uint120 startedBlock,
            bytes memory tickets
        );

    function offerorData(
        address
    )
        external
        view
        returns (
            uint96 latestWagerIDoffersValue,
            uint160 latestWagerID,
            uint256 totalOffersValue
        );

    function ticketOwnership(uint256, uint8) external view returns (address);

    function totalPlayerTickets(uint256, address) external view returns (uint8);

    function offer(
        uint256,
        uint8
    ) external view returns (uint96 amount, address maker);

    function USDT() external view returns (address);

    function TREASURY() external view returns (address);

    function THIS() external view returns (address);

    function MAGIC_VALUE() external view returns (uint256);

    /**
        @notice Returns all informations about the current wager.
        @dev This function will be used in Web-2.
        @return stat The current status of the wager (ticketSale, waitForCommingWave, Withdrawable, finished).
        @return maxPurchasableTickets Maximum purchasable tickets for each address, based on {maxTicketsPerWager}.
        @return startedBlock Started block number of game, in which all tickets sold out.
        @return currentWave The current wave of the wager.
        @return currentTicketValue The current value of a winning ticket in USDT tokens.
        @return remainingTickets Total number of current wave winner tickets.
        @return eligibleWithdrawals The number of eligible withdrawals for the current wave of the wager.
        @return nextWaveTicketValue The value of a winning ticket in USDT tokens for the coming wave.
        @return nextWaveWinrate The chance of winning each ticket for the coming wave.
        @return tickets The byte array containing the winning ticket IDs for the current wager.
        @return ticketsData An array of TicketInfo structures containing the ticket ID
            owner address and offer data for each winning ticket.
    */
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

    /**
        @notice Retrieves the current value of a ticket in USDT tokens.
        @dev Calculates and returns the current value of a ticket:
            If it was in ticket sale mode, then the ticket value is equal to {ticketPrice}
            Else by dividing the balance of USDT tokens in the contract
                by the total number of winning tickets.
        @return The current value of a ticket in USDT tokens, based on status.
    */
    function ticketValue() external view returns (uint256);

    /**
        @notice Returns the current winners with their winning tickets.
        @dev Allows anyone to retrieve information about the current winners
            along with their winning tickets. It returns the number of eligible withdrawals
            and an array of TicketInfo structures containing the ticket ID and owner address
            for each winning ticket.
        @return eligibleWithdrawals The number of eligible withdrawals for the current wager.
        @return allTicketsData An array of TicketInfo structures containing the ticket ID
            owner address and offer data for each winning ticket.
    */
    function winnersWithTickets()
        external
        view
        returns (
            int256 eligibleWithdrawals,
            TicketInfo[] memory allTicketsData
        );

    /**
        @notice Retrieves the total value of winning tickets 
            and the tickets owned by a specific player.
        @dev Allows anyone to retrieve information about the total value of winning tickets
            and the tickets owned by a specific player.
            It calculates the total value of winning tickets owned by the player
            based on the current ticket value and the number of tickets owned.
        @param player The address of the player for whom the information is being retrieved.
        @return totalTicketsValue The total value of winning tickets owned by the player in USDT tokens.
        @return playerTickets A byte array containing the IDs of the winning tickets owned by the player.
    */
    function playerWithWinningTickets(
        address player
    )
        external
        view
        returns (uint256 totalTicketsValue, bytes memory playerTickets);

    /**
        @notice Retrieves the total stale offer amount for a specific offeror.
        @param offeror The address of the offeror for whom the stale offer amount is being retrieved.
        @return uint256 The total stale offer amount for the specified offeror.
    */
    function staleOffers(address offeror) external view returns (uint256);

    /**
        @notice Retrieves a portion of a byte array.
        @dev Returns a portion of a byte array specified by the start and end indices.
        @param array The byte array from which the portion is being retrieved.
        @param from The start index of the portion to be retrieved.
        @param to The end index of the portion to be retrieved.
        @return bytes The portion of the byte array specified by the start and end indices.
    */
    function sliceBytedArray(
        bytes calldata array,
        uint256 from,
        uint256 to
    ) external pure returns (bytes memory);

    /**
        @notice Retrieves the latest update of the current wager.
        @dev It provides essential information about the wager's current state.
        @return stat The current status of the wager (ticketSale, waitForCommingWave, Withdrawable, finished).
        @return eligibleWithdrawals The number of eligible withdrawals for the current wave of the wager.
        @return currentWave The current wave of the wager.
        @return winnerTickets The byte array containing the winning ticket IDs for the current wager.
    */
    function latestUpdate()
        external
        view
        returns (
            Status stat,
            int256 eligibleWithdrawals,
            uint256 currentWave,
            bytes memory winnerTickets
        );

    /**
        @notice Retrieves the current status and details of a specific wager.
        @dev This function provides detailed information about a specific wager
            including its status, eligible withdrawals, current wave, winner tickets, and wager balance.
        @param wagerID_ The ID of the wager for which the status and details are being retrieved.
        @return wagerID The ID of the retrieved wager.
        @return stat The current status of the wager (ticketSale, waitForCommingWave, Withdrawable, finished).
        @return eligibleWithdrawals The number of eligible withdrawals for the current wager.
        @return currentWave The current wave of the wager.
        @return wagerBalance The balance of the wager in USDT tokens.
        @return winnerTickets The byte array containing the winning ticket IDs for the current wager.
    */
    function wagerStatus(
        uint256 wagerID_
    )
        external
        view
        returns (
            uint256 wagerID,
            Status stat,
            int256 eligibleWithdrawals,
            uint256 currentWave,
            uint256 wagerBalance,
            bytes memory winnerTickets
        );
}
