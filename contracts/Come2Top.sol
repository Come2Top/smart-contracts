//  SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

/**
    @author @FarajiOranj
    @title Come2Top Main Contract.
    @notice A secure, automatic 
        and fully decentralized platform
        to build an ideal wagering platform 
        without the involvement of third parties
        with a small interaction cost for users and actors.
        For more information & further questions, visit: https://www.come2.top
*/
contract Come2Top {
    /*******************************\
    |-*-*-*-*-*   TYPES   *-*-*-*-*-|
    \*******************************/
    enum Status {
        notStarted,
        ticketSale,
        waitForCommingWave,
        Withdrawable,
        finished
    }

    struct WagerData {
        int8 eligibleWithdrawals;
        uint8 soldTickets;
        uint8 updatedWave;
        uint216 startedBlock;
        bytes tickets;
    }

    struct Offer {
        uint96 amount;
        address maker;
    }

    struct OfferorData {
        uint96 latestWagerIDoffersValue;
        uint160 latestWagerID;
        uint256 totalOffersValue;
    }

    struct TicketInfo {
        uint256 ticketID;
        address owner;
    }

    /********************************\
    |-*-*-*-*-*   STATES   *-*-*-*-*-|
    \********************************/
    bool public pause;
    uint8 public maxTicketsPerWager;
    uint80 public ticketPrice;
    uint160 public currentWagerID;

    mapping(uint256 => WagerData) public wagerData;
    mapping(address => OfferorData) public offerorData;
    mapping(uint256 => mapping(uint8 => address)) public ticketOwnership;
    mapping(uint256 => mapping(address => uint8)) public totalPlayerTickets;
    mapping(uint256 => mapping(uint8 => Offer)) public offer;

    /*******************************\
    |-*-*-*-*   CONSTANTS   *-*-*-*-|
    \*******************************/
    IUSDT public immutable USDT;
    address public immutable TREASURY;
    address public immutable ADMIN = tx.origin;
    address public immutable THIS = address(this);
    uint256 public immutable MAGIC_VALUE;
    address private constant ZERO_ADDRESS = address(0x0);
    uint256 private constant MAX_TICKET_PRICE = 1e9;
    uint256 private constant MIN_TICKET_PRICE = 1e6;
    uint256 private constant MAX_PARTIES = 256;
    uint256 private constant WAVE_ELIGIBLES_TIME = 180;
    uint256 private constant BASIS = 100;
    uint256 private constant OFFEREE_BENEFICIARY = 95;
    uint256 private constant WAVE_DURATION = 71;
    uint256 private constant TOTAL_BLOCK_HASHES = 21;
    uint256 private constant MAX_TICKETS_PER_WAGER = 8;
    int8 private constant N_ONE = -1;
    uint8 private constant ZERO = 0;
    uint8 private constant ONE = 1;
    uint8 private constant TWO = 2;
    uint8 private constant THREE = 3;
    uint8 private constant FOUR = 4;
    uint8 private constant FIVE = 5;
    uint8 private constant TEN = 10;
    uint8 private constant ELEVEN = 11;
    uint8 private constant TWENTY = 20;
    bytes public constant TICKET256 =
        hex"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff";

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
        address[TWO] winners,
        uint256[TWO] amounts,
        uint256[TWO] ticketIDs
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
    error ONLY_ADMIN();
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
    error FEWER_TICKETS_LEFT(uint256 remainingTickets);
    error SLECTED_TICKETS_SOLDOUT_BEFORE();
    error PARTICIPATED_BEFORE();
    error PLAYER_HAS_NO_TICKETS();
    error NO_AMOUNT_TO_REFUND();
    error OFFER_NOT_FOUND();
    error WAIT_FOR_NEXT_WAGER_MATCH();
    error WAIT_FOR_FIRST_WAVE();

    /*******************************\
    |-*-*-*-*   MODIFIERS   *-*-*-*-|
    \*******************************/
    modifier onlyEOA() {
        if (msg.sender != tx.origin) revert ONLY_EOA();

        _;
    }

    modifier onlyAdmin() {
        if (msg.sender != ADMIN) revert ONLY_ADMIN();

        _;
    }

    modifier onlyTicketOwner(uint8 ticketID) {
        if (msg.sender != ticketOwnership[currentWagerID][ticketID])
            revert ONLY_TICKET_OWNER(ticketID);

        _;
    }

    modifier onlyPausedAndFinishedWager() {
        if (!pause || wagerData[currentWagerID].eligibleWithdrawals != N_ONE)
            revert ONLY_PAUSED_AND_FINISHED_MODE(pause);

        _;
    }

    /******************************\
    |-*-*-*-*   BUILT-IN   *-*-*-*-|
    \******************************/
    constructor(
        uint8 mtpw,
        uint80 tp,
        address usdt,
        address treasury
    ) {
        _checkMTPW(mtpw);
        _checkTP(tp);

        if (usdt == ZERO_ADDRESS || treasury == ZERO_ADDRESS)
            revert ZERO_ADDRESS_PROVIDED();

        maxTicketsPerWager = mtpw;
        ticketPrice = tp;
        USDT = IUSDT(usdt);
        TREASURY = treasury;
        MAGIC_VALUE = uint160(address(this));
        wagerData[ZERO].tickets = TICKET256;

        (bool ok, ) = treasury.call(abi.encode(usdt));

        if (!ok) revert APROVE_OPERATION_FAILED();
    }

    /*******************************\
    |-*-*-*   ADMINSTRATION   *-*-*-|
    \*******************************/
    /**
        @notice Toggles the pause state of the contract.
        @dev Allows the admin to toggle the pause state of the contract.
            When the contract is paused, certain functions may be restricted or disabled.
            Only the admin can call this function to toggle the pause state.
    */
    function togglePause() external onlyAdmin {
        pause = !pause;
    }

    /**
        @notice Changes the maximum number of tickets allowed per wager.
        @dev Allows the admin to change the maximum number of tickets allowed per wager. 
            Only the admin can call this function.
        @param maxTicketsPerWager_ The new maximum number of tickets allowed per wager.
    */
    function changeMaxTicketsPerWager(uint8 maxTicketsPerWager_)
        external
        onlyAdmin
        onlyPausedAndFinishedWager
    {
        _checkMTPW(maxTicketsPerWager_);

        maxTicketsPerWager = maxTicketsPerWager_;
    }

    /**
        @notice Changes the ticket price for joining the wager.
        @dev Allows the admin to change the ticket price for joining the wager. 
            Only the admin can call this function. 
        @param ticketPrice_ The new ticket price to be set.
    */
    function changeTicketPrice(uint80 ticketPrice_)
        external
        onlyAdmin
        onlyPausedAndFinishedWager
    {
        _checkTP(ticketPrice_);

        ticketPrice = ticketPrice_;
    }

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
    function joinWager(uint8[] calldata ticketIDs) external onlyEOA {
        address sender = msg.sender;
        uint256 wagerID = currentWagerID;
        uint256 neededUSDT = ticketPrice;
        uint256 totalTickets = ticketIDs.length;
        uint256 ticketLimit = maxTicketsPerWager;
        bytes memory realTickets;
        WagerData storage BD;

        if (wagerData[wagerID].eligibleWithdrawals == N_ONE) {
            unchecked {
                wagerID++;
                currentWagerID++;
            }

            BD = wagerData[wagerID];
            BD.tickets = TICKET256;
        } else BD = wagerData[wagerID];

        uint256 remainingTickets = MAX_PARTIES - BD.soldTickets;
        bytes memory tickets = BD.tickets;

        if (pause && BD.soldTickets == ZERO)
            revert ONLY_UNPAUSED_OR_TICKET_SALE_MODE(pause);

        if (totalTickets == ZERO || totalTickets > ticketLimit)
            revert CHECK_TICKETS_LENGTH(totalTickets);

        if (BD.startedBlock != ZERO) revert WAIT_FOR_NEXT_WAGER_MATCH();

        if (totalTickets + totalPlayerTickets[wagerID][sender] > ticketLimit)
            revert PARTICIPATED_BEFORE();

        if (totalTickets > remainingTickets)
            revert FEWER_TICKETS_LEFT(remainingTickets);

        for (uint256 i; i < totalTickets; ) {
            if (ticketIDs[i] == ZERO) {
                if (tickets[ZERO] != 0xff) {
                    tickets[ZERO] = 0xff;
                    realTickets = abi.encodePacked(realTickets, bytes1(0x00));
                    ticketOwnership[wagerID][ZERO] = sender;
                }
            } else {
                if (tickets[ticketIDs[i]] != 0x00) {
                    tickets[ticketIDs[i]] = 0x00;
                    realTickets = abi.encodePacked(
                        realTickets,
                        bytes1(ticketIDs[i])
                    );
                    ticketOwnership[wagerID][ticketIDs[i]] = sender;
                }
            }

            unchecked {
                i++;
            }
        }

        totalTickets = realTickets.length;

        if (totalTickets == ZERO) revert SLECTED_TICKETS_SOLDOUT_BEFORE();

        totalPlayerTickets[wagerID][sender] += uint8(totalTickets);

        _transferFromHelper(sender, THIS, (totalTickets * neededUSDT));

        BD.tickets = tickets;

        emit TicketsSold(sender, realTickets);

        if (totalTickets == remainingTickets) {
            uint256 currentBlock = block.number;
            BD.startedBlock = uint216(currentBlock);
            BD.tickets = TICKET256;

            emit WagerStarted(wagerID, currentBlock, MAX_PARTIES * neededUSDT);
        } else BD.soldTickets += uint8(totalTickets);
    }

    /**
        @notice Allows a player to receive the prize for a winning lottery ticket.
        @dev This function is used by a player to claim the prize for a winning lottery ticket.
            It checks various conditions such as the wager status, ticket ownership
            and eligibility for withdrawals before transferring the prize amount to the player.
            If the wager has ended and there are two winners
            the prize amount is split between them.
        @param ticketID The ID of the winning ticket for which the player wants to receive the prize.
    */
    function receiveLotteryWagedPrize(uint8 ticketID) external {
        address sender = msg.sender;
        uint256 wagerID = currentWagerID;
        uint256 balance = USDT.balanceOf(THIS);
        uint256 fee;

        (
            Status stat,
            int256 eligibleWithdrawals,
            uint256 currentWave,
            bytes memory tickets
        ) = getLatestUpdate();

        _onlyWithrawable(currentWave, stat);

        uint8 index = _onlyWinnerTicket(tickets, ticketID);

        if (tickets.length < THREE) {
            fee = balance / BASIS;
            wagerData[wagerID].tickets = tickets;
            wagerData[wagerID].eligibleWithdrawals = N_ONE;

            _transferHelper(ADMIN, fee);

            if (tickets.length == ONE) {
                address ticketOwner = ticketOwnership[wagerID][ticketID];

                delete ticketOwnership[wagerID][ticketID];
                delete totalPlayerTickets[wagerID][ticketOwner];

                _transferHelper(ticketOwner, balance - fee);

                emit WagerFinished(wagerID, ticketOwner, balance - fee, ticketID);
            } else {
                if (sender != ticketOwnership[currentWagerID][ticketID])
                    revert ONLY_TICKET_OWNER(ticketID);

                address winner1 = ticketOwnership[wagerID][uint8(tickets[ZERO])];
                address winner2 = ticketOwnership[wagerID][uint8(tickets[ONE])];
                uint256 winner2Amount = (balance - fee) / TWO;
                uint256 winner1Amount = balance - fee - winner2Amount;

                delete ticketOwnership[wagerID][uint8(tickets[ZERO])];
                delete ticketOwnership[wagerID][uint8(tickets[ONE])];

                delete totalPlayerTickets[wagerID][winner1];
                delete totalPlayerTickets[wagerID][winner2];

                _transferHelper(winner1, winner1Amount);
                _transferHelper(winner2, winner2Amount);

                emit WagerFinished(
                    wagerID,
                    [winner1, winner2],
                    [winner1Amount, winner2Amount],
                    [
                        uint256(uint8(tickets[ZERO])),
                        uint256(uint8(tickets[ONE]))
                    ]
                );
            }
        } else {
            if (sender != ticketOwnership[currentWagerID][ticketID])
                revert ONLY_TICKET_OWNER(ticketID);

            delete ticketOwnership[wagerID][ticketID];

            totalPlayerTickets[wagerID][sender]--;

            wagerData[wagerID].tickets = _deleteOneIndex(index, tickets);
            wagerData[wagerID].eligibleWithdrawals =
                int8(eligibleWithdrawals) +
                N_ONE;

            if (wagerData[wagerID].updatedWave != currentWave)
                wagerData[wagerID].updatedWave = uint8(currentWave);

            uint256 idealWinnerPrize = balance / tickets.length;
            fee = idealWinnerPrize / BASIS;

            _transferHelper(ADMIN, fee);
            _transferHelper(sender, idealWinnerPrize - fee);

            emit WagerUpdated(wagerID, sender, idealWinnerPrize - fee, ticketID);
        }
    }

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
    function makeOffer(uint8 ticketID, uint96 amount) external onlyEOA {
        address sender = msg.sender;
        uint256 wagerID = currentWagerID;

        (
            Status stat,
            ,
            uint256 currentWave,
            bytes memory tickets
        ) = getLatestUpdate();

        uint256 ticketValue = _currentTicketValue(tickets.length);
        Offer memory O = offer[wagerID][ticketID];
        uint256 offerorStaleAmount = _getStaleOfferorAmount(sender);

        _onlyWithrawable(currentWave, stat);
        _onlyWinnerTicket(tickets, ticketID);

        if (amount < ticketValue)
            revert ONLY_HIGHER_THAN_CURRENT_TICKET_VALUE(amount, ticketValue);

        if (amount <= O.amount)
            revert ONLY_HIGHER_THAN_CURRENT_OFFER_VALUE(amount, O.amount);

        if (offerorStaleAmount < amount) {
            uint256 diffOfferWithStaleAmount = amount - offerorStaleAmount;

            _transferFromHelper(sender, TREASURY, diffOfferWithStaleAmount);

            unchecked {
                offerorData[sender]
                    .totalOffersValue += diffOfferWithStaleAmount;
            }
        }

        if (offerorData[sender].latestWagerID != wagerID) {
            offerorData[sender].latestWagerID = uint160(wagerID);
            offerorData[sender].latestWagerIDoffersValue = uint96(amount);
        } else offerorData[sender].latestWagerIDoffersValue += uint96(amount);

        if (O.amount != ZERO) {
            _transferFromHelper(TREASURY, O.maker, O.amount);

            unchecked {
                offerorData[O.maker].totalOffersValue -= O.amount;
                offerorData[O.maker].latestWagerIDoffersValue -= O.amount;
            }
        }

        offer[wagerID][ticketID] = Offer(amount, sender);

        emit OfferMade(sender, ticketID, amount, O.maker);
    }

    /**
        @notice Allows the ticket owner to accept offers made for a specific ticket.
        @dev Allows the ticket owner to accept an offer made by an offeror for their benefit.
            It checks various conditions such as:
            the wager status, ownership of the ticket, existence of an offer for the ticket
            and the amount of the offer before transferring ownership of the ticket to the offer maker.
            Only the ticket owner can call this function.
        @param ticketID The ID of the ticket for which the offer is being accepted.
    */
    function acceptOffers(uint8 ticketID) external onlyTicketOwner(ticketID) {
        address sender = msg.sender;
        uint256 wagerID = currentWagerID;
        Offer memory O = offer[wagerID][ticketID];

        (Status stat, , , bytes memory tickets) = getLatestUpdate();

        _onlyWithrawable(ONE, stat);
        _onlyWinnerTicket(tickets, ticketID);

        if (O.amount == ZERO) revert OFFER_NOT_FOUND();

        delete offer[wagerID][ticketID];

        unchecked {
            offerorData[O.maker].latestWagerIDoffersValue -= O.amount;
            offerorData[O.maker].totalOffersValue -= O.amount;
            totalPlayerTickets[wagerID][sender]--;
            totalPlayerTickets[wagerID][O.maker]++;
        }

        ticketOwnership[wagerID][ticketID] = O.maker;

        _transferFromHelper(TREASURY, THIS, O.amount);
        _transferHelper(sender, (O.amount * OFFEREE_BENEFICIARY) / BASIS);

        emit OfferAccepted(
            O.maker,
            ticketID,
            (O.amount * OFFEREE_BENEFICIARY) / BASIS,
            sender
        );
    }

    /**
        @notice Allows the offeror to take back their stale offers and receive a refund.
        @dev Enables the player to withdraw their offers that have not been accepted
            and receive a refund in return.
            Only the player who made the offers can call this function.
        @param to The address to which the refund amount will be transferred.
            If not provided, the refund will be sent to the caller.
    */
    function takeBackStaleOffers(address to) external {
        address sender = msg.sender;

        if (to == ZERO_ADDRESS) to = sender;

        uint256 refundableAmount = _getStaleOfferorAmount(sender);

        if (refundableAmount == ZERO) revert NO_AMOUNT_TO_REFUND();

        offerorData[sender].totalOffersValue -= refundableAmount;

        _transferFromHelper(TREASURY, to, refundableAmount);

        emit StaleOffersTookBack(sender, to, refundableAmount);
    }

    /******************************\
    |-*-*-*-*-*   VIEW   *-*-*-*-*-|
    \******************************/
    /// @custom:see {_currentTicketValue()}
    function currentTicketValue() external view returns (uint256) {
        (Status stat, , , bytes memory tickets) = getLatestUpdate();

        if (stat == Status.ticketSale) return ticketPrice;

        return _currentTicketValue(tickets.length);
    }

    /**
        @notice Returns the current winners with their winning tickets.
        @dev Allows anyone to retrieve information about the current winners
            along with their winning tickets. It returns the number of eligible withdrawals
            and an array of TicketInfo structures containing the ticket ID and owner address
            for each winning ticket.
        @return eligibleWithdrawals The number of eligible withdrawals for the current wager.
        @return allTicketsData An array of TicketInfo structures containing the ticket ID
            and owner address for each winning ticket.
    */
    function currentWinnersWithTickets()
        external
        view
        returns (int256 eligibleWithdrawals, TicketInfo[] memory)
    {
        uint256 wagerID = currentWagerID;

        (
            Status stat,
            int256 _eligibleWithdrawals,
            uint256 currentWave,
            bytes memory tickets
        ) = getLatestUpdate();

        _onlyWithrawable(currentWave, stat);

        TicketInfo[] memory allTicketsData = new TicketInfo[](tickets.length);
        uint256 index;

        while (index != tickets.length) {
            allTicketsData[index] = TicketInfo(
                uint8(tickets[index]),
                ticketOwnership[wagerID][uint8(tickets[index])]
            );

            unchecked {
                index++;
            }
        }

        return (_eligibleWithdrawals, allTicketsData);
    }

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
    function playerWithWinningTickets(address player)
        external
        view
        returns (uint256 totalTicketsValue, bytes memory playerTickets)
    {
        if (player == ZERO_ADDRESS) player = msg.sender;

        uint256 wagerID = currentWagerID;
        uint256 totalTickets = totalPlayerTickets[wagerID][player];

        (
            Status stat,
            ,
            uint256 currentWave,
            bytes memory tickets
        ) = getLatestUpdate();

        uint8 latestIndex = uint8(tickets.length - ONE);

        _onlyWithrawable(currentWave, stat);

        if (totalTickets == ZERO) revert PLAYER_HAS_NO_TICKETS();

        while (totalTickets != ZERO) {
            if (
                ticketOwnership[wagerID][uint8(tickets[latestIndex])] == player
            ) {
                playerTickets = abi.encodePacked(
                    playerTickets,
                    tickets[latestIndex]
                );

                unchecked {
                    totalTicketsValue++;
                    totalTickets--;
                }
            }

            if (latestIndex == ZERO) break;

            unchecked {
                latestIndex--;
            }
        }

        totalTicketsValue *= _currentTicketValue(tickets.length);
    }

    /// @custom:see {_getStaleOfferorAmount()}
    function getStaleOfferorAmount(address offeror)
        external
        view
        returns (uint256)
    {
        return _getStaleOfferorAmount(offeror);
    }

    /**
        @notice Retrieves a portion of a byte array.
        @dev Returns a portion of a byte array specified by the start and end indices.
        @param array The byte array from which the portion is being retrieved.
        @param from The start index of the portion to be retrieved.
        @param to The end index of the portion to be retrieved.
        @return bytes The portion of the byte array specified by the start and end indices.
    */
    function returnBytedCalldataArray(
        bytes calldata array,
        uint256 from,
        uint256 to
    ) external pure returns (bytes memory) {
        return array[from:to];
    }

    /**
        @notice Retrieves the latest update of the current wager.
        @dev It provides essential information about the wager's current state.
        @return stat The current status of the wager (notStarted, ticketSale, waitForCommingWave, Withdrawable, finished).
        @return eligibleWithdrawals The number of eligible withdrawals for the current wave of the wager.
        @return currentWave The current wave of the wager.
        @return tickets The byte array containing the winning ticket IDs for the current wager.
    */
    function getLatestUpdate()
        public
        view
        returns (
            Status stat,
            int256 eligibleWithdrawals,
            uint256 currentWave,
            bytes memory tickets
        )
    {
        uint256 wagerID = currentWagerID;
        WagerData memory BD = wagerData[wagerID];
        tickets = BD.tickets;
        currentWave = BD.updatedWave;
        eligibleWithdrawals = BD.eligibleWithdrawals;

        if (BD.startedBlock == ZERO)
            stat = BD.soldTickets != ZERO
                ? Status.ticketSale
                : Status.notStarted;
        else if (BD.eligibleWithdrawals == N_ONE) stat = Status.finished;
        else {
            uint256 lastUpdatedWave;
            uint256 accumulatedBlocks;
            uint256 currentBlock = block.number;

            if (BD.updatedWave != ZERO) {
                lastUpdatedWave = BD.updatedWave + ONE;

                for (uint256 i = ONE; i < lastUpdatedWave; ) {
                    unchecked {
                        accumulatedBlocks += WAVE_ELIGIBLES_TIME / i;
                        i++;
                    }
                }
            } else {
                if (!(BD.startedBlock + WAVE_DURATION < currentBlock))
                    return (
                        Status.waitForCommingWave,
                        eligibleWithdrawals,
                        currentWave,
                        tickets
                    );

                lastUpdatedWave = ONE;
            }

            stat = Status.Withdrawable;

            while (true) {
                if (
                    BD.startedBlock +
                        (lastUpdatedWave * WAVE_DURATION) +
                        accumulatedBlocks <
                    currentBlock
                ) {
                    tickets = _bytedArrayShuffler(
                        tickets,
                        _getRandomSeed(
                            BD.startedBlock +
                                (lastUpdatedWave * WAVE_DURATION) +
                                accumulatedBlocks
                        ),
                        tickets.length / TWO
                    );

                    unchecked {
                        accumulatedBlocks +=
                            WAVE_ELIGIBLES_TIME /
                            lastUpdatedWave;
                        currentWave++;
                        lastUpdatedWave++;
                        eligibleWithdrawals = int256(tickets.length / TWO);
                    }

                    if (tickets.length == ONE) {
                        eligibleWithdrawals = int8(ONE);

                        break;
                    }
                } else {
                    if (
                        BD.startedBlock +
                            (currentWave * WAVE_DURATION) +
                            accumulatedBlocks <
                        currentBlock ||
                        uint256(eligibleWithdrawals) == ZERO
                    ) stat = Status.waitForCommingWave;

                    break;
                }
            }
        }
    }

    /*****************************\
    |-*-*-*-*   PRIVATE   *-*-*-*-|
    \*****************************/
    /**
        @dev Allows the contract to transfer USDT tokens to a specified address.
        @param to The address to which the USDT tokens will be transferred.
        @param amount The amount of USDT tokens to be transferred.
    */
    function _transferHelper(address to, uint256 amount) private {
        USDT.transfer(to, amount);
    }

    /**
        @dev Allows the contract to transfer USDT tokens from one address to another.
        @param from The address from which the USDT tokens will be transferred.
        @param to The address to which the USDT tokens will be transferred.
        @param amount The amount of USDT tokens to be transferred.
    */
    function _transferFromHelper(
        address from,
        address to,
        uint256 amount
    ) private {
        USDT.transferFrom(from, to, amount);
    }

    /**
        @notice Retrieves the total stale offer amount for a specific offeror.
        @param offeror The address of the offeror for whom the stale offer amount is being retrieved.
        @return uint256 The total stale offer amount for the specified offeror.
    */
    function _getStaleOfferorAmount(address offeror)
        private
        view
        returns (uint256)
    {
        if (offerorData[offeror].latestWagerID == currentWagerID)
            return (offerorData[offeror].totalOffersValue -
                offerorData[offeror].latestWagerIDoffersValue);

        return (offerorData[offeror].totalOffersValue);
    }

    /**
        @dev Shuffles a byte array by swapping elements based on a random seed value. 
            It iterates through the array and generates a random index to swap elements
            ensuring that the seed value influences the shuffling process.
            ( Modified version of Fisher-Yates Algo )
        @param array The byte array to be shuffled.
        @param randomSeed The random seed value used for shuffling.
        @param to The index until which shuffling should be performed.
        @return The shuffled byte array.
    */
    function _bytedArrayShuffler(
        bytes memory array,
        uint256 randomSeed,
        uint256 to
    ) private view returns (bytes memory) {
        uint256 i;
        uint256 j;
        uint256 n = array.length;
        while (i != n) {
            unchecked {
                j =
                    uint256(keccak256(abi.encodePacked(randomSeed, i))) %
                    (i + ONE);
                (array[i], array[j]) = (array[j], array[i]);
                i++;
            }
        }

        return this.returnBytedCalldataArray(array, ZERO, to);
    }

    /**
        @dev Deletes a specific index from a byte array.
            It returns a new byte array excluding the element at the specified index.
        @param index The index to be deleted from the byte array.
        @param bytesArray The byte array from which the index will be deleted.
        @return bytes The new byte array after deleting the specified index.
    */
    function _deleteOneIndex(uint8 index, bytes memory bytesArray)
        private
        view
        returns (bytes memory)
    {
        return
            index != (bytesArray.length - ONE)
                ? abi.encodePacked(
                    this.returnBytedCalldataArray(bytesArray, ZERO, index),
                    this.returnBytedCalldataArray(
                        bytesArray,
                        index + ONE,
                        bytesArray.length
                    )
                )
                : this.returnBytedCalldataArray(bytesArray, ZERO, index);
    }

    /**
        @notice Returns the current value of a winning ticket in USDT tokens.
        @dev Calculates and returns the current value of a ticket
            by dividing the balance of USDT tokens in the contract
            by the total number of winning tickets.
        @return uint256 The current value of a winning ticket in USDT tokens.
    */
    function _currentTicketValue(uint256 totalTickets)
        private
        view
        returns (uint256)
    {
        if (totalTickets == ZERO) return ZERO;

        return USDT.balanceOf(THIS) / totalTickets;
    }

    /**
        @dev Calculates a random seed value based on a series of block hashes.
            It selects various block hashes retrieved from previous block numbers and performs
            mathematical operations to calculate a random seed.
        @param startBlock The block number from where the calculation of the random seed starts.
        @return uint256 The random seed value generated based on block hashes.
    */
    function _getRandomSeed(uint256 startBlock) private view returns (uint256) {
        uint256 b = WAVE_DURATION;
        uint256 index = TWENTY;

        uint256[] memory parts = new uint256[](FIVE);
        uint256[] memory blockHashes = new uint256[](TOTAL_BLOCK_HASHES);

        while (blockHashes[ZERO] == ZERO) {
            blockHashes[index] = uint256(blockhash(startBlock - b));

            if (index == ZERO) break;
            else {
                unchecked {
                    index--;
                    b--;
                }
            }
        }

        for (uint256 i; i < TEN; ) {
            unchecked {
                parts[ZERO] += blockHashes[i];
                i++;
            }
        }

        parts[TWO] = blockHashes[TEN];

        for (uint256 i = ELEVEN; i < TOTAL_BLOCK_HASHES; ) {
            unchecked {
                parts[FOUR] -= blockHashes[i];
                i++;
            }
        }

        uint256 cachedNum;
        if (parts[ZERO] > parts[TWO] && parts[ZERO] > parts[FOUR]) {
            if (parts[TWO] < parts[FOUR]) {
                cachedNum = parts[TWO];
                parts[TWO] = parts[FOUR];
                parts[FOUR] = cachedNum;
            }
        } else {
            if (parts[FOUR] > parts[ZERO] && parts[FOUR] > parts[TWO]) {
                cachedNum = parts[FOUR];

                if (parts[ZERO] > parts[TWO]) {
                    parts[FOUR] = parts[TWO];
                    parts[TWO] = parts[ZERO];
                } else parts[FOUR] = parts[ZERO];
            } else {
                cachedNum = parts[TWO];

                if (parts[ZERO] < parts[FOUR]) {
                    parts[TWO] = parts[FOUR];
                    parts[FOUR] = parts[ZERO];
                } else parts[TWO] = parts[ZERO];
            }

            parts[ZERO] = cachedNum;
        }

        unchecked {
            parts[ONE] = (parts[ZERO] / TWO) + (parts[TWO] / TWO);
            parts[THREE] = (parts[FOUR] / TWO) + (parts[TWO] / TWO);

            return
                uint256(
                    keccak256(abi.encodePacked(parts[ONE] * parts[THREE]))
                ) * MAGIC_VALUE;
        }
    }

    /**
        @dev Performs a linear search on the provided list of tickets
            to find a specific ticket ID.
        @param tickets The list of tickets to search within.
        @param ticketID The ticket ID to search for.
        @return bool True if the ticket ID is found in the list, false otherwise.
        @return uint8 The index of the found ticket ID in the list.
    */
    function _linearSearch(bytes memory tickets, uint8 ticketID)
        private
        pure
        returns (bool, uint8)
    {
        for (uint256 i = tickets.length - ONE; i >= ZERO; ) {
            if (uint8(tickets[i]) == ticketID) {
                return (true, uint8(i));
            }

            unchecked {
                i--;
            }
        }

        return (false, ZERO);
    }

    /**
        @dev It verifies that the value is not zero
            and not greater than the maximum limit predefined as {MAX_TICKETS_PER_WAGER}.
        @param value The value to be checked for maximum tickets per wager.
    */
    function _checkMTPW(uint8 value) private pure {
        _revertOnZeroUint(value);

        if (value > MAX_TICKETS_PER_WAGER)
            revert VALUE_CANT_BE_GREATER_THAN(MAX_TICKETS_PER_WAGER);
    }

    /**
        @dev Checks if the provided ticket price value is within the valid range.
            It verifies that the ticket price value is not lower than the {MIN_TICKET_PRICE} 
            and not higher than the {MAX_TICKET_PRICE}.
            If the value is outside the valid range
            it reverts the transaction with an appropriate error message.
        @param value The ticket price value to be checked
    */
    function _checkTP(uint80 value) private pure {
        if (value < MIN_TICKET_PRICE)
            revert VALUE_CANT_BE_LOWER_THAN(MIN_TICKET_PRICE);

        if (value > MAX_TICKET_PRICE)
            revert VALUE_CANT_BE_GREATER_THAN(MAX_TICKET_PRICE);
    }

    /**
        @dev Checks if the provided uint value is zero and reverts the transaction if it is.
        @param uInt The uint value to be checked.
    */
    function _revertOnZeroUint(uint256 uInt) private pure {
        if (uInt == ZERO) revert ZERO_UINT_PROVIDED();
    }

    /**
        @dev Checks the current status of the wager and reverts the transaction
            if the wager status is not withrawable.
        @param stat The current status of the wager (notStarted, ticketSale, waitForCommingWave, Withdrawable, finished).
    */
    function _onlyWithrawable(uint256 currentWave, Status stat) private pure {
        if (currentWave == ZERO) revert WAIT_FOR_FIRST_WAVE();

        if (stat != Status.Withdrawable) revert ONLY_WITHDRAWABLE_MODE(stat);
    }

    /**
        @dev Performs a linear search on the provided list of tickets to find the specific ticket ID.
            If the ticket ID is not found in the list of tickets, the transaction will be reverted.
        @param tickets The list of tickets to search within.
        @param ticketID The ticket ID to search for.
        @return uint8 The index of the found ticket ID in the list.
    */
    function _onlyWinnerTicket(bytes memory tickets, uint8 ticketID)
        private
        pure
        returns (uint8)
    {
        (bool found, uint8 index) = _linearSearch(tickets, ticketID);

        if (!found) revert ONLY_WINNER_TICKET(ticketID);

        return index;
    }
}

/// @notice IUSDT interface, which is used for easier interactions with USDT contracts.
interface IUSDT {
    /**
        @notice Allows the contract to transfer USDT tokens to a specified address.
        @dev Allows the contract to transfer USDT tokens to a specified address.
        @param to The address to which the USDT tokens will be transferred.
        @param amount The amount of USDT tokens to be transferred.
    */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
        @notice Allows the contract to transfer USDT tokens from one address to another.
        @dev Allows the contract to transfer USDT tokens from one address to another.
        @param from The address from which the USDT tokens will be transferred.
        @param to The address to which the USDT tokens will be transferred.
        @param amount The amount of USDT tokens to be transferred.
        @return bool indicating if the transfer was successful or not.
    */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
        @notice Retrieves the balance of USDT tokens for a specific account.
        @dev Allows anyone to retrieve the balance of USDT tokens 
            for a specific account by calling the balanceOf function of the IUSDT interface.
        @param account The address of the account for which the balance is being retrieved.
        @return uint256 The balance of USDT tokens for the specified account.
    */
    function balanceOf(address account) external view returns (uint256);
}
