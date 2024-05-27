//  SPDX-License-Identifier: -- Come2Top --
pragma solidity 0.8.20;

import {IFRAX} from "./interfaces/IFRAX.sol";
import {IL1Randao} from "./interfaces/IL1Randao.sol";

/**
    @author @4bit-lab
    @title Come2Top Main Contract.
    @notice Come2Top is a secure, automated, and fully decentralized wagering platform
        built on the Polygon Mainnet, that works without the involvement of third parties.
        For more information & further questions, visit: https://www.come2.top
*/
contract Come2Top {
    /*******************************\
    |-*-*-*-*-*   TYPES   *-*-*-*-*-|
    \*******************************/
    enum Status {
        ticketSale,
        waitForCommingWave,
        Withdrawable,
        finished
    }

    struct WagerData {
        int8 eligibleWithdrawals;
        uint8 soldTickets;
        uint8 updatedWave;
        uint96 balance;
        uint120 startedBlock;
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
        Offer offer;
        uint256 ticketID;
        address owner;
    }

    /********************************\
    |-*-*-*-*-*   STATES   *-*-*-*-*-|
    \********************************/
    bool public pause;
    uint8 public maxTicketsPerWager;
    uint80 public ticketPrice;
    address public owner;
    uint256 public currentWagerID;
    uint256 public prngPeriod;

    mapping(uint256 => WagerData) public wagerData;
    mapping(address => OfferorData) public offerorData;
    mapping(uint256 => mapping(uint8 => address)) public ticketOwnership;
    mapping(uint256 => mapping(address => uint8)) public totalPlayerTickets;
    mapping(uint256 => mapping(uint8 => Offer)) public offer;

    /*******************************\
    |-*-*-*-*   CONSTANTS   *-*-*-*-|
    \*******************************/
    IFRAX public immutable FRAX;
    address public immutable TREASURY;
    IL1Randao public immutable L1RANDAO;
    address public immutable THIS = address(this);
    uint256 public immutable MAGIC_VALUE;
    bytes private constant BYTE_TICKETS =
        hex"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff";
    address private constant ZERO_ADDRESS = address(0x0);
    uint256 private constant MIN_TICKET_PRICE = 2e18;
    uint256 private constant MAX_PARTIES = 256;
    uint256 private constant WAVE_ELIGIBLES_TIME = 240;
    uint256 private constant BASIS = 100;
    uint256 private constant OFFEREE_BENEFICIARY = 95;
    uint256 private constant SAFTY_DURATION = 100;
    int8 private constant N_ONE = -1;
    uint8 private constant ZERO = 0;
    uint8 private constant ONE = 1;
    uint8 private constant TWO = 2;
    uint8 private constant FIVE = 5;
    uint8 private constant EIGHT = 8;

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
    |-*-*-*-*   MODIFIERS   *-*-*-*-|
    \*******************************/
    modifier onlyEOA() {
        if (msg.sender != tx.origin) revert ONLY_EOA();

        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert ONLY_OWNER();

        _;
    }

    modifier onlyPausedAndFinishedWager() {
        (
            ,
            int256 eligibleWithdrawals,
            ,
            bytes memory winnerTickets
        ) = _wagerUpdate(currentWagerID);

        if (
            !pause ||
            (eligibleWithdrawals != N_ONE && winnerTickets.length != ONE)
        ) revert ONLY_PAUSED_AND_FINISHED_MODE(pause);

        _;
    }

    /******************************\
    |-*-*-*-*   BUILT-IN   *-*-*-*-|
    \******************************/
    constructor(
        uint8 mtpw,
        uint80 tp,
        uint256 prngp,
        address frax,
        address treasury,
        address l1Radndao
    ) {
        _checkMTPW(mtpw);
        _checkTP(tp);
        _checkPRNGP(prngp);

        if (
            frax == ZERO_ADDRESS ||
            treasury == ZERO_ADDRESS ||
            l1Radndao == ZERO_ADDRESS
        ) revert ZERO_ADDRESS_PROVIDED();

        owner = msg.sender;
        maxTicketsPerWager = mtpw;
        ticketPrice = tp;
        prngPeriod = prngp;
        FRAX = IFRAX(frax);
        TREASURY = treasury;
        L1RANDAO = IL1Randao(l1Radndao);
        MAGIC_VALUE = uint160(address(this));
        wagerData[ZERO].tickets = BYTE_TICKETS;

        (bool ok, ) = treasury.call(abi.encode(frax));

        if (!ok) revert APROVE_OPERATION_FAILED();
    }

    /*******************************\
    |-*-*-*   ADMINSTRATION   *-*-*-|
    \*******************************/
    /**
        @notice Changes the owner of the contract.
        @dev Allows the current owner to transfer the ownership to a new address.
    */
    function changeOwner(address newOwner) external onlyOwner {
        if (owner == ZERO_ADDRESS) revert ZERO_ADDRESS_PROVIDED();

        owner = newOwner;
    }

    /**
        @notice Toggles the pause state of the contract.
        @dev Allows the owner to toggle the pause state of the contract.
            When the contract is paused, certain functions may be restricted or disabled.
            Only the owner can call this function to toggle the pause state.
    */
    function togglePause() external onlyOwner {
        pause = !pause;
    }

    /**
        @notice Changes the ticket price for joining the wager.
        @dev Allows the owner to change the ticket price for joining the wager. 
            Only the owner can call this function. 
        @param newTP The new ticket price to be set.
    */
    function changeTicketPrice(uint80 newTP)
        external
        onlyOwner
        onlyPausedAndFinishedWager
    {
        _checkTP(newTP);

        ticketPrice = newTP;
    }

    /**
        @notice Changes the maximum number of tickets allowed per wager.
        @dev Allows the owner to change the maximum number of tickets allowed per wager. 
            Only the owner can call this function.
        @param newMTPW The new maximum number of tickets allowed per wager.
    */
    function changeMaxTicketsPerWager(uint8 newMTPW)
        external
        onlyOwner
        onlyPausedAndFinishedWager
    {
        _checkMTPW(newMTPW);

        maxTicketsPerWager = newMTPW;
    }

    /**
        @notice Changes the pseudorandom number generator period time.
        @dev Allows the owner to change the pseudorandom number generator period time. 
            Only the owner can call this function.
        @param newPRNGP The new the pseudorandom number generator period.
    */
    function changePRNGperiod(uint256 newPRNGP)
        external
        onlyOwner
        onlyPausedAndFinishedWager
    {
        _checkPRNGP(newPRNGP);

        prngPeriod = newPRNGP;
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
    function join(uint8[] calldata ticketIDs) external onlyEOA {
        address sender = msg.sender;
        uint256 wagerID = currentWagerID;
        uint256 neededFRAX = ticketPrice;
        uint256 totalTickets = ticketIDs.length;
        uint256 ticketLimit = maxTicketsPerWager;
        bytes memory realTickets;
        WagerData storage BD;

        (, , , bytes memory winnerTickets) = _wagerUpdate(wagerID);
        if (
            wagerData[wagerID].eligibleWithdrawals == N_ONE ||
            winnerTickets.length == ONE
        ) {
            unchecked {
                wagerID++;
                currentWagerID++;
            }

            BD = wagerData[wagerID];
            BD.tickets = BYTE_TICKETS;
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

        if (totalTickets == ZERO) revert SELECTED_TICKETS_SOLDOUT_BEFORE();

        totalPlayerTickets[wagerID][sender] += uint8(totalTickets);

        _transferFromHelper(sender, THIS, (totalTickets * neededFRAX));

        BD.tickets = tickets;
        BD.balance += uint96(totalTickets * neededFRAX);

        emit TicketsSold(sender, realTickets);

        if (totalTickets == remainingTickets) {
            uint64 currentL1Block = L1RANDAO.number();
            BD.startedBlock = currentL1Block;
            BD.tickets = BYTE_TICKETS;

            emit WagerStarted(
                wagerID,
                currentL1Block,
                MAX_PARTIES * neededFRAX
            );
        } else BD.soldTickets += uint8(totalTickets);
    }

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
    function redeem(uint8 ticketID) external {
        address sender = msg.sender;
        uint256 wagerID = currentWagerID;
        (
            Status stat,
            int256 eligibleWithdrawals,
            uint256 currentWave,
            bytes memory tickets
        ) = _wagerUpdate(wagerID);

        _onlyWithrawable(currentWave, stat);

        uint8 index = _onlyWinnerTicket(tickets, ticketID);
        uint256 plus5PCT = _ticketValue(tickets.length, wagerID);
        plus5PCT += (plus5PCT * FIVE) / BASIS;

        if (
            offer[wagerID][ticketID].amount >= plus5PCT &&
            offer[wagerID][ticketID].maker != ZERO_ADDRESS
        ) {
            Offer memory O = offer[wagerID][ticketID];
            if (sender != ticketOwnership[wagerID][ticketID])
                revert ONLY_TICKET_OWNER(ticketID);

            delete offer[wagerID][ticketID].maker;

            unchecked {
                offerorData[O.maker].latestWagerIDoffersValue -= O.amount;
                offerorData[O.maker].totalOffersValue -= O.amount;
                totalPlayerTickets[wagerID][sender]--;
                totalPlayerTickets[wagerID][O.maker]++;
            }

            ticketOwnership[wagerID][ticketID] = O.maker;

            uint96 offereeBeneficiary = uint96(
                (O.amount * OFFEREE_BENEFICIARY) / BASIS
            );

            wagerData[wagerID].balance += O.amount - offereeBeneficiary;

            _transferFromHelper(TREASURY, THIS, O.amount);
            _transferHelper(sender, offereeBeneficiary);

            emit OfferAccepted(O.maker, ticketID, offereeBeneficiary, sender);

            return;
        }

        if (eligibleWithdrawals == int8(ZERO)) revert WAIT_FOR_NEXT_WAVE();

        uint256 fee;
        uint256 balance = wagerData[wagerID].balance;

        if (tickets.length == TWO) {
            fee = (balance * TWO) / BASIS;
            wagerData[wagerID].tickets = tickets;
            wagerData[wagerID].eligibleWithdrawals = N_ONE;

            _transferHelper(owner, fee);

            if (sender != ticketOwnership[wagerID][ticketID])
                revert ONLY_TICKET_OWNER(ticketID);

            address winner1 = ticketOwnership[wagerID][uint8(tickets[ZERO])];
            address winner2 = ticketOwnership[wagerID][uint8(tickets[ONE])];
            uint256 winner1Amount = (balance - fee) / TWO;
            uint256 winner2Amount = balance - fee - winner1Amount;

            delete wagerData[wagerID].balance;
            delete totalPlayerTickets[wagerID][winner1];
            delete totalPlayerTickets[wagerID][winner2];

            _transferHelper(winner1, winner1Amount);
            _transferHelper(winner2, winner2Amount);

            emit WagerFinished(
                wagerID,
                [winner1, winner2],
                [winner1Amount, winner2Amount],
                [uint256(uint8(tickets[ZERO])), uint256(uint8(tickets[ONE]))]
            );
        } else {
            if (sender != ticketOwnership[wagerID][ticketID])
                revert ONLY_TICKET_OWNER(ticketID);

            delete ticketOwnership[wagerID][ticketID];

            totalPlayerTickets[wagerID][sender]--;

            wagerData[wagerID].tickets = _deleteIndex(index, tickets);
            wagerData[wagerID].eligibleWithdrawals =
                int8(eligibleWithdrawals) +
                N_ONE;

            if (wagerData[wagerID].updatedWave != currentWave)
                wagerData[wagerID].updatedWave = uint8(currentWave);

            uint256 idealWinnerPrize = balance / tickets.length;

            wagerData[wagerID].balance -= uint96(idealWinnerPrize);

            fee = (idealWinnerPrize * TWO) / BASIS;

            _transferHelper(owner, fee);
            _transferHelper(sender, idealWinnerPrize - fee);

            emit WagerUpdated(
                wagerID,
                sender,
                idealWinnerPrize - fee,
                ticketID
            );
        }
    }

    /**
        @notice Allows anyone to have the prize sent to the winning ticket holder.
        @param wagerID_ The ID of the wager for which the owner of the winning ticket will get the prize.
    */
    function claim(uint256 wagerID_) external {
        (
            uint256 wagerID,
            ,
            int256 eligibleWithdrawals,
            ,
            uint256 wagerBalance,
            ,
            uint256[] memory winnerTickets
        ) = wagerStatus(wagerID_);

        if (eligibleWithdrawals == N_ONE || winnerTickets.length != ONE)
            revert WAGER_FINISHED();

        uint256 fee = (wagerBalance * TWO) / BASIS;
        wagerData[wagerID].tickets = bytes(abi.encodePacked(winnerTickets[0]));
        wagerData[wagerID].eligibleWithdrawals = N_ONE;

        _transferHelper(owner, fee);

        address ticketOwner = ticketOwnership[wagerID][uint8(winnerTickets[0])];

        delete totalPlayerTickets[wagerID][ticketOwner];
        delete wagerData[wagerID].balance;

        _transferHelper(ticketOwner, wagerBalance - fee);

        emit WagerFinished(
            wagerID,
            ticketOwner,
            wagerBalance - fee,
            winnerTickets[0]
        );
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
        @param amount The amount of the offer in FRAX tokens.
    */
    function makeOffer(uint8 ticketID, uint96 amount) external onlyEOA {
        address sender = msg.sender;
        uint256 wagerID = currentWagerID;

        (
            Status stat,
            ,
            uint256 currentWave,
            bytes memory tickets
        ) = _wagerUpdate(currentWagerID);

        uint256 plus5PCT = _ticketValue(tickets.length, wagerID);
        plus5PCT += (plus5PCT * FIVE) / BASIS;
        Offer memory O = offer[wagerID][ticketID];
        uint256 offerorStaleAmount = _staleOffers(sender);

        _onlyWithrawable(currentWave, stat);
        _onlyWinnerTicket(tickets, ticketID);

        if (amount < plus5PCT)
            revert ONLY_HIGHER_THAN_CURRENT_TICKET_VALUE(amount, plus5PCT);

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

        if (O.maker != ZERO_ADDRESS) {
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
        @notice Allows the offeror to take back their stale offers and receive a refund.
        @dev Enables the player to withdraw their offers that have not been accepted
            and receive a refund in return.
            Only the player who made the offers can call this function.
    */
    function takeBackStaleOffers() external {
        address sender = msg.sender;

        uint256 refundableAmount = _staleOffers(sender);

        if (refundableAmount == ZERO) revert NO_AMOUNT_TO_REFUND();

        offerorData[sender].totalOffersValue -= refundableAmount;

        _transferFromHelper(TREASURY, sender, refundableAmount);

        emit StaleOffersTookBack(sender, refundableAmount);
    }

    /******************************\
    |-*-*-*-*-*   VIEW   *-*-*-*-*-|
    \******************************/
    /**
        @notice Returns all informations about the current wager.
        @dev This function will be used in Web-2.
        @return stat The current status of the wager (ticketSale, waitForCommingWave, Withdrawable, finished).
        @return maxPurchasableTickets Maximum purchasable tickets for each address, based on {maxTicketsPerWager}.
        @return startedBlock Started block number of game, in which all tickets sold out.
        @return currentWave The current wave of the wager.
        @return currentTicketValue The current value of a winning ticket in FRAX tokens.
        @return remainingTickets Total number of current wave winner tickets.
        @return eligibleWithdrawals The number of eligible withdrawals for the current wave of the wager.
        @return nextWaveTicketValue The value of a winning ticket in FRAX tokens for the coming wave.
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
            TicketInfo[MAX_PARTIES] memory ticketsData
        )
    {
        uint256 wagerID = currentWagerID;
        maxPurchasableTickets = maxTicketsPerWager;
        (stat, eligibleWithdrawals, currentWave, tickets) = _wagerUpdate(
            wagerID
        );
        remainingTickets = tickets.length;

        if (
            stat == Status.ticketSale ||
            stat == Status.finished ||
            remainingTickets == ONE
        ) currentTicketValue = ticketPrice;
        else {
            startedBlock = wagerData[wagerID].startedBlock;
            currentTicketValue = _ticketValue(tickets.length, wagerID);
        }

        if (remainingTickets != ONE && stat != Status.finished) {
            if (stat == Status.ticketSale) {
                remainingTickets = MAX_PARTIES - wagerData[wagerID].soldTickets;
                nextWaveTicketValue = ticketPrice * TWO;
                nextWaveWinrate = (BASIS**TWO) / TWO;
            } else {
                nextWaveTicketValue =
                    wagerData[wagerID].balance /
                    (tickets.length / TWO);
                nextWaveWinrate =
                    ((tickets.length / TWO) * BASIS**TWO) /
                    tickets.length;
            }
        }

        uint256 index;
        uint256 plus5pTV = currentTicketValue +
            (currentTicketValue * FIVE) /
            BASIS;

        if (stat == Status.ticketSale) {
            while (index != MAX_PARTIES) {
                uint256 loadedOffer = offer[wagerID][uint8(index)].amount;
                ticketsData[index] = TicketInfo(
                    Offer(
                        loadedOffer >= plus5pTV ? uint96(loadedOffer) : ZERO,
                        loadedOffer >= plus5pTV
                            ? offer[wagerID][uint8(index)].maker
                            : ZERO_ADDRESS
                    ),
                    index,
                    ticketOwnership[wagerID][uint8(index)]
                );

                unchecked {
                    index++;
                }
            }
        } else {
            while (index != tickets.length) {
                uint256 loadedOffer = offer[wagerID][uint8(tickets[index])]
                    .amount;
                ticketsData[uint8(tickets[index])] = TicketInfo(
                    Offer(
                        loadedOffer >= plus5pTV ? uint96(loadedOffer) : ZERO,
                        loadedOffer >= plus5pTV
                            ? offer[wagerID][uint8(tickets[index])].maker
                            : ZERO_ADDRESS
                    ),
                    uint8(tickets[index]),
                    ticketOwnership[wagerID][uint8(tickets[index])]
                );

                unchecked {
                    index++;
                }
            }

            index = ZERO;

            while (index != MAX_PARTIES) {
                if (ticketsData[index].owner == ZERO_ADDRESS)
                    ticketsData[index].ticketID = index;

                unchecked {
                    index++;
                }
            }
        }
    }

    /**
        @notice Retrieves the current value of a ticket in FRAX tokens.
        @dev Calculates and returns the current value of a ticket:
            If it was in ticket sale mode, then the ticket value is equal to {ticketPrice}
            Else by dividing the balance of FRAX tokens in the contract
                by the total number of winning tickets.
        @return The current value of a ticket in FRAX tokens, based on status.
    */
    function ticketValue() external view returns (uint256) {
        (Status stat, , , bytes memory tickets) = _wagerUpdate(currentWagerID);

        if (
            stat == Status.ticketSale ||
            stat == Status.finished ||
            (stat == Status.Withdrawable && tickets.length == ONE)
        ) return ticketPrice;

        return _ticketValue(tickets.length, currentWagerID);
    }

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
        returns (int256 eligibleWithdrawals, TicketInfo[] memory allTicketsData)
    {
        uint256 wagerID = currentWagerID;

        (
            Status stat,
            int256 _eligibleWithdrawals,
            uint256 currentWave,
            bytes memory winnerTickets
        ) = _wagerUpdate(currentWagerID);

        _onlyWithrawable(currentWave, stat);

        allTicketsData = new TicketInfo[](winnerTickets.length);
        uint256 index;

        uint256 currentTicketValue;
        if (stat == Status.ticketSale) currentTicketValue = ticketPrice;
        else currentTicketValue = _ticketValue(winnerTickets.length, wagerID);

        uint256 plus5PCT = currentTicketValue +
            (currentTicketValue / BASIS) *
            FIVE;

        while (index != winnerTickets.length) {
            uint256 loadOffer = offer[wagerID][uint8(winnerTickets[index])]
                .amount;
            allTicketsData[index] = TicketInfo(
                Offer(
                    loadOffer >= plus5PCT ? uint96(loadOffer) : ZERO,
                    loadOffer >= plus5PCT
                        ? offer[wagerID][uint8(winnerTickets[index])].maker
                        : ZERO_ADDRESS
                ),
                uint8(winnerTickets[index]),
                ticketOwnership[wagerID][uint8(winnerTickets[index])]
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
        @return totalTicketsValue The total value of winning tickets owned by the player in FRAX tokens.
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
        ) = _wagerUpdate(currentWagerID);

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

        totalTicketsValue *= _ticketValue(tickets.length, wagerID);
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
        totalStaleOffers = offerorData[offeror].totalOffersValue;
        claimableOffers = _staleOffers(offeror);
    }

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
    ) external pure returns (bytes memory) {
        return array[from:to];
    }

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
        )
    {
        return _wagerUpdate(currentWagerID);
    }

    /**
        @notice Retrieves the current status and details of a specific wager.
        @dev This function provides detailed information about a specific wager
            including its status, eligible withdrawals, current wave, winner tickets, and wager balance.
        @param wagerID_ The ID of the wager for which the status and details are being retrieved.
        @return wagerID The ID of the retrieved wager.
        @return stat The current status of the wager (ticketSale, waitForCommingWave, Withdrawable, finished).
        @return eligibleWithdrawals The number of eligible withdrawals for the current wager.
        @return currentWave The current wave of the wager.
        @return wagerBalance The balance of the wager in FRAX tokens.
        @return winners The array containing the winner addresses for the given wager ID.
        @return winnerTickets The array containing the winning ticket IDs for the given wager ID.
    */
    function wagerStatus(uint256 wagerID_)
        public
        view
        returns (
            uint256 wagerID,
            Status stat,
            int256 eligibleWithdrawals,
            uint256 currentWave,
            uint256 wagerBalance,
            address[] memory winners,
            uint256[] memory winnerTickets
        )
    {
        if (wagerID_ > currentWagerID) wagerID = currentWagerID;
        else wagerID = wagerID_;

        bytes memory tickets;
        (stat, eligibleWithdrawals, currentWave, tickets) = _wagerUpdate(
            wagerID
        );

        winners = new address[](tickets.length);
        winnerTickets = new uint256[](tickets.length);

        winners[0] = ticketOwnership[wagerID][uint8(bytes1(tickets[0]))];
        winnerTickets[0] = uint8(bytes1(tickets[0]));

        if (tickets.length != 1) {
            winners[1] = ticketOwnership[wagerID][uint8(bytes1(tickets[1]))];
            winnerTickets[0] = uint8(bytes1(tickets[1]));
        }

        wagerBalance = wagerData[wagerID].balance;
    }

    /*****************************\
    |-*-*-*-*   PRIVATE   *-*-*-*-|
    \*****************************/
    /**
        @dev Allows the contract to transfer FRAX tokens to a specified address.
        @param to The address to which the FRAX tokens will be transferred.
        @param amount The amount of FRAX tokens to be transferred.
    */
    function _transferHelper(address to, uint256 amount) private {
        FRAX.transfer(to, amount);
    }

    /**
        @dev Allows the contract to transfer FRAX tokens from one address to another.
        @param from The address from which the FRAX tokens will be transferred.
        @param to The address to which the FRAX tokens will be transferred.
        @param amount The amount of FRAX tokens to be transferred.
    */
    function _transferFromHelper(
        address from,
        address to,
        uint256 amount
    ) private {
        FRAX.transferFrom(from, to, amount);
    }

    /**
        @notice Retrieves the total stale offer amount for a specific offeror.
        @param offeror The address of the offeror for whom the stale offer amount is being retrieved.
        @return uint256 The total stale offer amount for the specified offeror.
    */
    function _staleOffers(address offeror) private view returns (uint256) {
        if (offerorData[offeror].latestWagerID == currentWagerID) {
            (
                ,
                int256 eligibleWithdrawals,
                ,
                bytes memory tickets
            ) = _wagerUpdate(currentWagerID);

            if (eligibleWithdrawals == N_ONE || tickets.length == ONE)
                return (offerorData[offeror].totalOffersValue);

            return (offerorData[offeror].totalOffersValue -
                offerorData[offeror].latestWagerIDoffersValue);
        }

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
    function _shuffleBytedArray(
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

        return this.sliceBytedArray(array, ZERO, to);
    }

    /**
        @dev Deletes a specific index from a byte array.
            It returns a new byte array excluding the element at the specified index.
        @param index The index to be deleted from the byte array.
        @param bytesArray The byte array from which the index will be deleted.
        @return bytes The new byte array after deleting the specified index.
    */
    function _deleteIndex(uint8 index, bytes memory bytesArray)
        private
        view
        returns (bytes memory)
    {
        return
            index != (bytesArray.length - ONE)
                ? abi.encodePacked(
                    this.sliceBytedArray(bytesArray, ZERO, index),
                    this.sliceBytedArray(
                        bytesArray,
                        index + ONE,
                        bytesArray.length
                    )
                )
                : this.sliceBytedArray(bytesArray, ZERO, index);
    }

    /**
        @notice Returns the current value of a winning ticket in FRAX tokens.
        @dev Calculates and returns the current value of a ticket
            by dividing the balance of FRAX tokens in the contract
            by the total number of winning tickets.
        @return uint256 The current value of a winning ticket in FRAX tokens.
    */
    function _ticketValue(uint256 totalTickets, uint256 wagerID)
        private
        view
        returns (uint256)
    {
        if (totalTickets == ZERO) return ZERO;

        return wagerData[wagerID].balance / totalTickets;
    }

    /**
        @dev Creates a random seed value based on a series of l1 block prevrandaos.
            It selects various block prevrandaos and performs mathematical operations to calculate a random seed.
        @param startBlock The block number from where the calculation of the random seed starts.
        @return uint256 The random seed value generated based on l1 block prevrandaos.
    */
    function _createRandomSeed(uint256 startBlock)
        private
        view
        returns (uint256)
    {
        unchecked {
            return
                uint256(
                    keccak256(
                        abi.encodePacked(
                            L1RANDAO.numberToRandao(
                                uint64(startBlock - SAFTY_DURATION)
                            ) +
                                L1RANDAO.numberToRandao(
                                    uint64(startBlock - SAFTY_DURATION / 2)
                                ) +
                                L1RANDAO.numberToRandao(
                                    uint64(startBlock - SAFTY_DURATION / 3)
                                )
                        )
                    )
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
    function _findTicket(bytes memory tickets, uint8 ticketID)
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
        @notice Retrieves the current status and details of a specific wager.
        @dev This function provides detailed information about a specific wager
            including its status, eligible withdrawals, current wave, winner tickets, and wager balance.
        @param wagerID The ID of the wager for which the status and details are being retrieved.
        @return stat The current status of the wager (ticketSale, waitForCommingWave, Withdrawable, finished).
        @return eligibleWithdrawals The number of eligible withdrawals for the current wager.
        @return currentWave The current wave of the wager.
    */
    function _wagerUpdate(uint256 wagerID)
        private
        view
        returns (
            Status stat,
            int256 eligibleWithdrawals,
            uint256 currentWave,
            bytes memory remainingTickets
        )
    {
        WagerData memory BD = wagerData[wagerID];
        remainingTickets = BD.tickets;
        eligibleWithdrawals = BD.eligibleWithdrawals;

        if (BD.startedBlock == ZERO) stat = Status.ticketSale;
        else if (BD.eligibleWithdrawals == N_ONE) stat = Status.finished;
        else {
            currentWave = BD.updatedWave;
            uint256 lastUpdatedWave;
            uint256 accumulatedBlocks;
            uint256 currentL1Block = L1RANDAO.number();
            uint256 waitingDuration = _wave_duration();

            if (BD.updatedWave != ZERO) {
                lastUpdatedWave = BD.updatedWave + ONE;

                for (uint256 i = ONE; i < lastUpdatedWave; ) {
                    unchecked {
                        accumulatedBlocks += WAVE_ELIGIBLES_TIME / i;
                        i++;
                    }
                }
            } else {
                if (!(BD.startedBlock + waitingDuration < currentL1Block))
                    return (
                        Status.waitForCommingWave,
                        eligibleWithdrawals,
                        currentWave,
                        remainingTickets
                    );

                lastUpdatedWave = ONE;
            }

            stat = Status.Withdrawable;

            while (true) {
                if (
                    BD.startedBlock +
                        (lastUpdatedWave * waitingDuration) +
                        accumulatedBlocks <
                    currentL1Block
                ) {
                    remainingTickets = _shuffleBytedArray(
                        remainingTickets,
                        _createRandomSeed(
                            BD.startedBlock +
                                (lastUpdatedWave * waitingDuration) +
                                accumulatedBlocks
                        ),
                        remainingTickets.length / TWO
                    );

                    unchecked {
                        accumulatedBlocks +=
                            WAVE_ELIGIBLES_TIME /
                            lastUpdatedWave;
                        currentWave++;
                        lastUpdatedWave++;
                        eligibleWithdrawals = int256(
                            remainingTickets.length / TWO
                        );
                    }

                    if (remainingTickets.length == ONE) {
                        eligibleWithdrawals = int8(ONE);

                        break;
                    }
                } else {
                    if (
                        BD.startedBlock +
                            (currentWave * waitingDuration) +
                            accumulatedBlocks <
                        currentL1Block
                    ) stat = Status.waitForCommingWave;

                    break;
                }
            }
        }
    }

    function _wave_duration() private view returns (uint256) {
        return SAFTY_DURATION + prngPeriod;
    }

    /**
        @dev It verifies that the value is not zero
            and not greater than the maximum limit predefined as {EIGHT}.
        @param value The value to be checked for maximum tickets per wager.
    */
    function _checkMTPW(uint8 value) private pure {
        _revertOnZeroUint(value);

        if (value > EIGHT) revert VALUE_CANT_BE_GREATER_THAN(EIGHT);
    }

    /**
        @dev It verifies that the value is not zero
            and not lower than the minimum limit predefined as {EIGHT}.
        @param value The value to be checked for maximum tickets per wager.
    */
    function _checkPRNGP(uint256 value) private pure {
        _revertOnZeroUint(value);

        if (value < SAFTY_DURATION)
            revert VALUE_CANT_BE_LOWER_THAN(SAFTY_DURATION);
    }

    /**
        @dev It verifies that the value is not zero
            and not lower than the minimum limit predefined as {MIN_TICKET_PRICE}.
        @param value The ticket price value to be checked
    */
    function _checkTP(uint80 value) private pure {
        _revertOnZeroUint(value);

        if (value < MIN_TICKET_PRICE)
            revert VALUE_CANT_BE_LOWER_THAN(MIN_TICKET_PRICE);
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
        @param stat The current status of the wager (ticketSale, waitForCommingWave, Withdrawable, finished).
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
        (bool found, uint8 index) = _findTicket(tickets, ticketID);

        if (!found) revert ONLY_WINNER_TICKET(ticketID);
        if (tickets.length == ONE) revert WAGER_FINISHED();

        return index;
    }
}
