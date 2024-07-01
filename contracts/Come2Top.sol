//  SPDX-License-Identifier: -- Come2Top --
pragma solidity 0.8.20;

import {IERC20} from "./interfaces/IERC20.sol";
import {IFraxtalL1Block} from "./interfaces/IFraxtalL1Block.sol";
import {IBeefyVault} from "./interfaces/IBeefyVault.sol";
import {ICurveStableNG} from "./interfaces/ICurveStableNG.sol";

import {CurveMooLib} from "./libraries/CurveMooLib.sol";

/**
    @author @4BitLab
    @title Come2Top System Contract.
    @notice Come2Top is a secure, automated, and fully decentralized GameFi platform
        built on top of the Fraxtal Mainnet, Curve Protocol & Beefy Yield Farming Protocol
        that works without the involvement of third parties.
        For more information & further questions, visit: https://come2.top
*/
contract Come2Top {
    using CurveMooLib for uint256;

    /*******************************\
    |-*-*-*-*-*   TYPES   *-*-*-*-*-|
    \*******************************/
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
        uint256 mooTokenBalance;
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

    /********************************\
    |-*-*-*-*-*   STATES   *-*-*-*-*-|
    \********************************/
    bool public pause;
    uint8 public maxTicketsPerGame;
    uint80 public ticketPrice;
    address public owner;
    uint8 public currentGameStrat;
    uint248 public prngPeriod;
    uint256 public currentGameID;

    StratConfig[7] public gameStratConfig;

    mapping(uint256 => GameData) public gameData;
    mapping(address => OfferorData) public offerorData;
    mapping(uint256 => mapping(uint8 => address)) public tempTicketOwnership;
    mapping(uint256 => mapping(address => uint8)) public totalPlayerTickets;
    mapping(uint256 => mapping(address => PlayerGameBalance))
        public playerBalanceData;
    mapping(uint256 => mapping(uint8 => Offer)) public offer;
    mapping(address => uint256[]) public playerRecentGames;

    /*******************************\
    |-*-*-*-*   CONSTANTS   *-*-*-*-|
    \*******************************/
    uint256 public immutable MAGIC_VALUE;
    IERC20 public immutable FRAX;
    address public immutable TREASURY;
    address public immutable THIS = address(this);
    IFraxtalL1Block public immutable FRAXTAL_L1_BLOCK;
    bytes private constant BYTE_TICKETS =
        hex"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff";
    // Mainnet
    // uint256 private constant MIN_TICKET_PRICE = 1e19;
    // Testnet
    uint256 private constant MIN_TICKET_PRICE = 1e20;
    uint256 private constant MAX_PARTIES = 256;
    // Mainnet
    // uint256 private constant WAVE_ELIGIBLES_TIME = 144;
    // Testnet
    uint256 private constant WAVE_ELIGIBLES_TIME = 24;
    // Mainnet
    // uint256 private constant SAFTY_DURATION = 48;
    // Testnet
    uint256 private constant SAFTY_DURATION = 10;
    uint256 private constant MIN_PRNG_PERIOD = 12;
    uint256 private constant BASIS = 100;
    uint256 private constant MIN_TICKET_VALUE_OFFER = 10;
    // Mainnet
    // uint256 private constant L1_BLOCK_LOCK_TIME = 207692; // l1 avg block time ˜12.5
    // Testnet
    uint256 private constant L1_BLOCK_LOCK_TIME = 50; // l1 avg block time ˜12.5
    address private constant ZERO_ADDRESS = address(0x0);
    int8 private constant N_ONE = -1;
    uint8 private constant ZERO = 0;
    uint8 private constant ONE = 1;
    uint8 private constant TWO = 2;
    uint8 private constant THREE = 3;
    uint8 private constant SIX = 6;
    uint8 private constant SEVEN = 7;
    uint8 private constant EIGHT = 8;

    /********************************\
    |-*-*-*-*-*   EVENTS   *-*-*-*-*-|
    \********************************/
    event TicketsSold(address indexed buyer, bytes ticketIDs);

    event GameStarted(
        uint256 indexed gameID,
        uint256 indexed startedBlockNo,
        uint256 amount
    );

    event GameUpdated(
        uint256 indexed gameID,
        address indexed winner,
        uint256 amount,
        uint256 ticketID
    );

    event OfferMade(
        address indexed maker,
        uint256 indexed ticketID,
        uint256 amount,
        address lastOfferor
    );

    event OfferAccepted(
        address indexed newOwner,
        uint256 indexed ticketID,
        uint256 amount,
        address lastOwner
    );

    event GameFinished(
        uint256 indexed gameID,
        address[TWO] winners,
        uint256[TWO] amounts,
        uint256[TWO] ticketIDs
    );

    event Claimed(
        uint256 indexed gameID,
        address indexed player,
        uint256 amount,
        int256 profit
    );

    event StaleOffersTookBack(address indexed maker, uint256 amount);

    /********************************\
    |-*-*-*-*-*   ERRORS   *-*-*-*-*-|
    \********************************/
    error ONLY_EOA();
    error ONLY_OWNER();
    error ONLY_TICKET_OWNER(uint256 ticketID);
    error ONLY_WINNER_TICKET(uint256 ticketID);
    error ONLY_OPERATIONAL_MODE(Status currentStat);
    error ONLY_CLAIMABLE_MODE(Status stat);
    error ONLY_PAUSED_AND_FINISHED_MODE(bool isPaused, Status stat);
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
    error FRAX_TOKEN_NOT_FOUND();
    error INVALID_CURVE_PAIR();
    error VALUE_CANT_BE_LOWER_THAN(uint256 givenValue);
    error VALUE_CANT_BE_GREATER_THAN(uint256 givenValue);
    error ZERO_ADDRESS_PROVIDED();
    error ZERO_UINT_PROVIDED();
    error CHECK_TICKETS_LENGTH(uint256 ticketLength);
    error SELECTED_TICKETS_SOLDOUT_BEFORE();
    error PARTICIPATED_BEFORE();
    error NO_AMOUNT_TO_CLAIM();
    error NO_AMOUNT_TO_REFUND();
    error WAIT_FOR_NEXT_MATCH();
    error WAIT_FOR_FIRST_WAVE();
    error WAIT_FOR_NEXT_WAVE();
    error FETCHED_CLAIMABLE_AMOUNT(
        Status stat,
        uint256 baseAmount,
        uint256 savedAmount,
        uint256 claimableAmount,
        int256 profit
    );

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

    modifier onlyPausedAndFinishedGame() {
        (Status stat, , , ) = _gameUpdate(currentGameID);

        if (!pause || uint256(stat) <= TWO)
            revert ONLY_PAUSED_AND_FINISHED_MODE(pause, stat);

        _;
    }

    /******************************\
    |-*-*-*-*   BUILT-IN   *-*-*-*-|
    \******************************/
    constructor(
        uint8 mtpg,
        uint80 tp,
        uint48 prngp,
        uint8 gameStrat,
        address frax,
        address treasury,
        address fraxtalL1Block,
        address[SEVEN] memory beefyVaults
    ) {
        _checkMTPG(mtpg);
        _checkTP(tp);
        _checkPRNGP(prngp);
        _checkGS(gameStrat);

        if (
            frax == ZERO_ADDRESS ||
            treasury == ZERO_ADDRESS ||
            fraxtalL1Block == ZERO_ADDRESS
        ) revert ZERO_ADDRESS_PROVIDED();

        owner = tx.origin;
        maxTicketsPerGame = mtpg;
        ticketPrice = tp;
        prngPeriod = prngp;
        currentGameStrat = gameStrat;
        FRAX = IERC20(frax);
        TREASURY = treasury;
        FRAXTAL_L1_BLOCK = IFraxtalL1Block(fraxtalL1Block);
        gameData[ZERO].tickets = BYTE_TICKETS;
        unchecked {
            MAGIC_VALUE = uint160(address(this)) * block.chainid;
        }

        (bool ok, ) = treasury.call(abi.encode(frax));
        if (!ok) revert APROVE_OPERATION_FAILED();

        address curveStableNG;
        uint256 fraxTokenPosition;
        for (uint256 i; i < SEVEN; ) {
            if (beefyVaults[i] == address(0)) revert ZERO_ADDRESS_PROVIDED();
            curveStableNG = IBeefyVault(beefyVaults[i]).want();

            if (ICurveStableNG(curveStableNG).N_COINS() != TWO)
                revert INVALID_CURVE_PAIR();

            IERC20(frax).approve(curveStableNG, type(uint256).max);
            ICurveStableNG(curveStableNG).approve(
                beefyVaults[i],
                type(uint256).max
            );

            fraxTokenPosition = frax ==
                ICurveStableNG(curveStableNG).coins(ZERO)
                ? ZERO
                : frax == ICurveStableNG(curveStableNG).coins(ONE)
                ? ONE
                : 404;

            if (fraxTokenPosition == 404) revert FRAX_TOKEN_NOT_FOUND();

            gameStratConfig[i] = StratConfig(
                uint96(fraxTokenPosition),
                ICurveStableNG(curveStableNG),
                IBeefyVault(beefyVaults[i])
            );

            unchecked {
                i++;
            }
        }
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
        @notice Changes the current game strategy vault.
        @dev Allows the current owner to change the current game strategy vault.
    */
    function changeGameStrat(uint8 newGameStrat) external onlyOwner {
        _checkGS(newGameStrat);

        currentGameStrat = newGameStrat;
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
        _checkTP(newTP);

        ticketPrice = newTP;
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
        _checkMTPG(newMTPG);

        maxTicketsPerGame = newMTPG;
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
        _checkPRNGP(newPRNGP);

        prngPeriod = newPRNGP;
    }

    /*********************************\
    |-*-*-*-*   GAME-LOGIC   *-*-*-*-|
    \*********************************/
    /**
        @notice Players can buy tickets to join the game.
        @dev Manages the ticket allocation, ownership, and purchase process.
            Also ensures that the maximum number of tickets specified by {maxTicketsPerGame}
                and the ticket price set by {ticketPrice} are adhered to.
            When all tickets are sold out, it will lock them for {L1_BLOCK_LOCK_TIME} time duration
                and invest them in a yield farming protocol (stables) such as Beefy.
            The player joining the game, must be an externally owned account (EOA).
        @param ticketIDs The ticket IDs that players want to buy for a game.
    */
    function ticketSaleOperation(uint8[] calldata ticketIDs) external onlyEOA {
        uint256 gameID = currentGameID;
        uint256 neededToken = ticketPrice;
        uint256 totalTickets = ticketIDs.length;
        uint256 ticketLimit = maxTicketsPerGame;
        bytes memory realTickets;
        GameData storage GD;

        (Status stat, , , ) = _gameUpdate(gameID);
        if (uint256(stat) > TWO) {
            unchecked {
                gameID++;
                currentGameID++;
            }

            GD = gameData[gameID];
            GD.tickets = BYTE_TICKETS;
        } else GD = gameData[gameID];

        uint256 remainingTickets = MAX_PARTIES - GD.soldTickets;
        bytes memory tickets = GD.tickets;

        if (pause && GD.soldTickets == ZERO)
            revert ONLY_UNPAUSED_OR_TICKET_SALE_MODE(pause);

        if (totalTickets == ZERO || totalTickets > ticketLimit)
            revert CHECK_TICKETS_LENGTH(totalTickets);

        if (GD.startedL1Block != ZERO) revert WAIT_FOR_NEXT_MATCH();

        if (totalTickets + totalPlayerTickets[gameID][msg.sender] > ticketLimit)
            revert PARTICIPATED_BEFORE();

        for (uint256 i; i < totalTickets; ) {
            if (ticketIDs[i] == ZERO) {
                if (tickets[ZERO] != 0xff) {
                    tickets[ZERO] = 0xff;
                    realTickets = abi.encodePacked(realTickets, bytes1(0x00));
                    tempTicketOwnership[gameID][ZERO] = msg.sender;
                }
            } else {
                if (tickets[ticketIDs[i]] != 0x00) {
                    tickets[ticketIDs[i]] = 0x00;
                    realTickets = abi.encodePacked(
                        realTickets,
                        bytes1(ticketIDs[i])
                    );
                    tempTicketOwnership[gameID][ticketIDs[i]] = msg.sender;
                }
            }

            unchecked {
                i++;
            }
        }

        totalTickets = realTickets.length;

        if (totalTickets == ZERO) revert SELECTED_TICKETS_SOLDOUT_BEFORE();

        _transferFromHelper(msg.sender, THIS, (totalTickets * neededToken));

        emit TicketsSold(msg.sender, realTickets);

        if (totalTickets == remainingTickets) {
            uint64 currentL1Block = FRAXTAL_L1_BLOCK.number();
            IBeefyVault beefyVault = gameStratConfig[currentGameStrat]
                .beefyVault;
            ICurveStableNG curveStableNG = gameStratConfig[currentGameStrat]
                .curveStableNG;

            GD.prngPeriod = uint112(prngPeriod);
            GD.startedL1Block = currentL1Block;
            GD.tickets = BYTE_TICKETS;
            GD.chosenConfig = currentGameStrat;
            GD.initialFraxBalance = MAX_PARTIES * neededToken;
            GD.virtualFraxBalance = MAX_PARTIES * neededToken;

            uint256 beforeBalance = beefyVault.balanceOf(THIS);

            (
                CurveMooLib.mintLPT(
                    (MAX_PARTIES * neededToken),
                    gameStratConfig[currentGameStrat].fraxTokenPosition,
                    curveStableNG
                )
            ).depositLPT(beefyVault);

            GD.mooTokenBalance = beefyVault.balanceOf(THIS) - beforeBalance;

            emit GameStarted(gameID, currentL1Block, MAX_PARTIES * neededToken);
        } else {
            GD.tickets = tickets;
            unchecked {
                GD.soldTickets += uint8(totalTickets);
            }
        }

        unchecked {
            totalPlayerTickets[gameID][msg.sender] += uint8(totalTickets);
            playerBalanceData[gameID][msg.sender].initialFraxBalance += uint120(
                totalTickets * neededToken
            );
        }

        if (
            playerRecentGames[msg.sender].length == 0 ||
            playerRecentGames[msg.sender][
                playerRecentGames[msg.sender].length - 1
            ] ==
            gameID
        ) playerRecentGames[msg.sender].push(gameID);
    }

    /**
        @notice Automatically, it saves the winning amount for the player
            and in the future, he/she will have the ability
            to claim the profit from the saved winning amount.
        @dev Automatically:
                If there is an offer for the currently winning ticket
                    the player accepts the offer and grants ownership of the currently winning ticket
                    to the offering player, and in the future, after the end of the {L1_BLOCK_LOCK_TIME} period
                    the amount of the accepted offer in terms of token {FRAX}
                    allows the player of the former owner to claim the resulting profit.
                Otherwise, if there is no offer, the owner's winning ticket will be removed
                    and he/she will be allowed to claim the interest of the winning amount
                    after the {L1_BLOCK_LOCK_TIME} time has passed.
        @param ticketID The ID of the ticket for which the offer is being accepted.
    */
    function winnerOperation(uint8 ticketID) external {
        uint256 gameID = currentGameID;
        (
            Status stat,
            int256 eligibleToSell,
            uint256 currentWave,
            bytes memory tickets
        ) = _gameUpdate(gameID);

        _onlyOperational(currentWave, stat);
        uint8 index = _onlyWinnerTicket(tickets, ticketID);

        uint256 plus10PCT = _ticketValue(tickets.length, gameID);
        plus10PCT += (plus10PCT * MIN_TICKET_VALUE_OFFER) / BASIS;

        if (
            offer[gameID][ticketID].amount >= plus10PCT &&
            offer[gameID][ticketID].maker != ZERO_ADDRESS
        ) {
            Offer memory O = offer[gameID][ticketID];
            if (msg.sender != tempTicketOwnership[gameID][ticketID])
                revert ONLY_TICKET_OWNER(ticketID);

            delete offer[gameID][ticketID].maker;

            unchecked {
                offerorData[O.maker].latestGameIDoffersValue -= O.amount;
                offerorData[O.maker].totalOffersValue -= O.amount;
                totalPlayerTickets[gameID][msg.sender]--;
                totalPlayerTickets[gameID][O.maker]++;
            }

            tempTicketOwnership[gameID][ticketID] = O.maker;

            uint256 ticketValue_ = _ticketValue(tickets.length, gameID);
            uint256 halfOfOfferProfit = (O.amount - ticketValue_) / 2;

            unchecked {
                gameData[gameID].initialFraxBalance += O.amount;
                gameData[gameID].loanedFraxBalance += (ticketValue_ +
                    halfOfOfferProfit);
                gameData[gameID].virtualFraxBalance +=
                    O.amount -
                    (ticketValue_ + halfOfOfferProfit);

                playerBalanceData[gameID][O.maker]
                    .initialFraxBalance += uint120(O.amount);
                playerBalanceData[gameID][msg.sender]
                    .loanedFraxBalance += uint120(
                    ticketValue_ + halfOfOfferProfit
                );
            }

            _transferFromHelper(TREASURY, THIS, O.amount);

            uint256 chosenConfig = gameData[gameID].chosenConfig;
            IBeefyVault beefyVault = gameStratConfig[chosenConfig].beefyVault;

            uint256 beforeBalance = beefyVault.balanceOf(THIS);

            (
                uint256(O.amount).mintLPT(
                    gameStratConfig[chosenConfig].fraxTokenPosition,
                    gameStratConfig[chosenConfig].curveStableNG
                )
            ).depositLPT(beefyVault);

            unchecked {
                gameData[gameID].mooTokenBalance +=
                    beefyVault.balanceOf(THIS) -
                    beforeBalance;
            }

            emit OfferAccepted(
                O.maker,
                ticketID,
                ticketValue_ + halfOfOfferProfit,
                msg.sender
            );

            if (
                playerRecentGames[O.maker].length == 0 ||
                playerRecentGames[O.maker][
                    playerRecentGames[O.maker].length - 1
                ] ==
                gameID
            ) playerRecentGames[O.maker].push(gameID);

            return;
        }

        if (eligibleToSell == int8(ZERO)) revert WAIT_FOR_NEXT_WAVE();

        uint256 virtualFraxBalance = gameData[gameID].virtualFraxBalance;

        if (tickets.length == TWO) {
            gameData[gameID].tickets = tickets;
            gameData[gameID].eligibleToSell = N_ONE;

            if (msg.sender != tempTicketOwnership[gameID][ticketID])
                revert ONLY_TICKET_OWNER(ticketID);

            address winner1 = tempTicketOwnership[gameID][uint8(tickets[ZERO])];
            address winner2 = tempTicketOwnership[gameID][uint8(tickets[ONE])];
            uint256 winner1Amount = virtualFraxBalance / TWO;

            delete gameData[gameID].virtualFraxBalance;
            delete totalPlayerTickets[gameID][winner1];
            delete totalPlayerTickets[gameID][winner2];

            unchecked {
                gameData[gameID].loanedFraxBalance += virtualFraxBalance;
                playerBalanceData[gameID][winner1].loanedFraxBalance += uint120(
                    winner1Amount
                );
                playerBalanceData[gameID][winner2].loanedFraxBalance += uint120(
                    virtualFraxBalance - winner1Amount
                );
            }

            emit GameFinished(
                gameID,
                [winner1, winner2],
                [winner1Amount, virtualFraxBalance - winner1Amount],
                [uint256(uint8(tickets[ZERO])), uint256(uint8(tickets[ONE]))]
            );
        } else {
            if (msg.sender != tempTicketOwnership[gameID][ticketID])
                revert ONLY_TICKET_OWNER(ticketID);

            delete tempTicketOwnership[gameID][ticketID];

            totalPlayerTickets[gameID][msg.sender]--;

            gameData[gameID].tickets = _deleteIndex(index, tickets);
            gameData[gameID].eligibleToSell = int8(eligibleToSell) + N_ONE;

            if (gameData[gameID].updatedWave != currentWave)
                gameData[gameID].updatedWave = uint8(currentWave);

            uint256 idealWinnerPrize = virtualFraxBalance / tickets.length;

            unchecked {
                gameData[gameID].loanedFraxBalance += idealWinnerPrize;
                gameData[gameID].virtualFraxBalance -= idealWinnerPrize;
                playerBalanceData[gameID][msg.sender]
                    .loanedFraxBalance += uint120(idealWinnerPrize);
            }

            emit GameUpdated(gameID, msg.sender, idealWinnerPrize, ticketID);
        }
    }

    /**
        @notice Allows a player to make an offer for a ticket.
            If the offered amount is {MIN_TICKET_VALUE_OFFER}% higher than the current ticket value
                or just higher than the last offer
                the offer is accepted and stored, or else it will be reverted.
        @dev Allows a player to make an offer for a specific ticket.
            If a higher offer is made for the same ticket
                the previous offer is refunded to the maker.
            The player making the offer, must be an externally owned account (EOA).
        @param ticketID The ID of the winning ticket for which the offer is being made.
        @param amount The amount of the offer in {FRAX} tokens.
    */
    function offerOperation(uint8 ticketID, uint96 amount) external onlyEOA {
        uint256 gameID = currentGameID;

        (
            Status stat,
            ,
            uint256 currentWave,
            bytes memory tickets
        ) = _gameUpdate(currentGameID);

        uint256 plus10PCT = _ticketValue(tickets.length, gameID);
        plus10PCT += (plus10PCT * MIN_TICKET_VALUE_OFFER) / BASIS;
        Offer memory O = offer[gameID][ticketID];
        uint256 offerorStaleAmount = _staleOffers(msg.sender);

        _onlyOperational(currentWave, stat);
        _onlyWinnerTicket(tickets, ticketID);

        if (amount < plus10PCT)
            revert ONLY_HIGHER_THAN_CURRENT_TICKET_VALUE(amount, plus10PCT);

        if (amount <= O.amount)
            revert ONLY_HIGHER_THAN_CURRENT_OFFER_VALUE(amount, O.amount);

        if (offerorStaleAmount < amount) {
            uint256 diffOfferWithStaleAmount = amount - offerorStaleAmount;

            _transferFromHelper(msg.sender, TREASURY, diffOfferWithStaleAmount);

            unchecked {
                offerorData[msg.sender]
                    .totalOffersValue += diffOfferWithStaleAmount;
            }
        }

        if (offerorData[msg.sender].latestGameID != gameID) {
            offerorData[msg.sender].latestGameID = uint160(gameID);
            offerorData[msg.sender].latestGameIDoffersValue = uint96(amount);
        } else
            offerorData[msg.sender].latestGameIDoffersValue += uint96(amount);

        if (O.maker != ZERO_ADDRESS) {
            _transferFromHelper(TREASURY, O.maker, O.amount);

            unchecked {
                offerorData[O.maker].totalOffersValue -= O.amount;
                offerorData[O.maker].latestGameIDoffersValue -= O.amount;
            }
        }

        offer[gameID][ticketID] = Offer(amount, msg.sender);

        emit OfferMade(msg.sender, ticketID, amount, O.maker);
    }

    /**
        @notice In a nutshell, it enables the players to claim the basic amount of participation
            in the game (buying tickets, offers) that they contracted
            and if they won, it also pays the player
            the profit of the winning amount of that game.
        @param gameID The ID of the game for which 
    */
    function claimOperation(uint256 gameID) external {
        if (gameID > currentGameID) gameID = currentGameID;
        (Status stat, , , bytes memory tickets) = _gameUpdate(gameID);

        if (stat != Status.claimable) revert ONLY_CLAIMABLE_MODE(stat);

        uint256 playerInitialFraxBalance = playerBalanceData[gameID][msg.sender]
            .initialFraxBalance;
        uint256 playerLoanedFraxBalance = playerBalanceData[gameID][msg.sender]
            .loanedFraxBalance;

        if (
            tickets.length == ONE &&
            tempTicketOwnership[gameID][uint8(tickets[ZERO])] == msg.sender
        ) {
            playerLoanedFraxBalance += gameData[gameID].virtualFraxBalance;
            delete totalPlayerTickets[gameID][msg.sender];
        }

        if (playerInitialFraxBalance == ZERO) revert NO_AMOUNT_TO_CLAIM();

        uint256 chosenConfig = gameData[gameID].chosenConfig;
        uint256 mooShare = (gameStratConfig[chosenConfig].beefyVault)
            .getPricePerFullShare();
        uint256 gameMooBalance = gameData[gameID].mooTokenBalance;
        uint256 gameRewardedMoo = ((gameMooBalance * mooShare) / 1e18) -
            gameMooBalance;

        uint256 gameInitialFraxBalance = gameData[gameID].initialFraxBalance;
        uint256 gameLoanedFraxBalance = gameData[gameID].loanedFraxBalance +
            gameData[gameID].virtualFraxBalance;

        uint256 playerClaimableMooAmount;

        if (gameInitialFraxBalance == playerInitialFraxBalance) {
            playerClaimableMooAmount = gameMooBalance;

            delete gameData[gameID].mooTokenBalance;
            delete gameData[gameID].initialFraxBalance;
            delete gameData[gameID].loanedFraxBalance;

            gameData[gameID].tickets = tickets;
        } else {
            playerClaimableMooAmount =
                ((((playerInitialFraxBalance * 1e18) / gameInitialFraxBalance) *
                    (
                        gameLoanedFraxBalance == ZERO
                            ? gameMooBalance
                            : (gameMooBalance - gameRewardedMoo)
                    )) / 1e18) +
                (
                    gameLoanedFraxBalance == ZERO
                        ? ZERO
                        : (((playerLoanedFraxBalance * 1e18) /
                            gameLoanedFraxBalance) * gameRewardedMoo) / 1e18
                );

            gameData[gameID].mooTokenBalance -= playerClaimableMooAmount;
            gameData[gameID].initialFraxBalance -= playerInitialFraxBalance;
            if (gameLoanedFraxBalance != ZERO)
                gameData[gameID].loanedFraxBalance -= playerBalanceData[gameID][
                    msg.sender
                ].loanedFraxBalance;
        }

        delete playerBalanceData[gameID][msg.sender];
        if (
            tickets.length == ONE &&
            tempTicketOwnership[gameID][uint8(tickets[ZERO])] == msg.sender
        ) delete gameData[gameID].virtualFraxBalance;

        ICurveStableNG curveStableNG = gameStratConfig[chosenConfig]
            .curveStableNG;
        uint256 beforeLPbalance = curveStableNG.balanceOf(THIS);

        CurveMooLib.withdrawLPT(
            playerClaimableMooAmount,
            gameStratConfig[chosenConfig].beefyVault
        );

        uint256 claimedAmount = CurveMooLib.burnLPT(
            curveStableNG.balanceOf(THIS) - beforeLPbalance,
            msg.sender,
            gameStratConfig[chosenConfig].fraxTokenPosition,
            curveStableNG
        );

        emit Claimed(
            gameID,
            msg.sender,
            claimedAmount,
            int256(claimedAmount) - int256(playerInitialFraxBalance)
        );
    }

    /**
            @notice Allows the player to take back their stale offers and receive a refund.
            @dev Enables the player to withdraw offers that have not been accepted
                    and receive a refund in return.
                If the player has made an offer or offers in the {currentGameID}
                    he/she can withdraw them only after the game is finished
                    if they are not accepted.
                Only the player who made the offers can call this function.
        */
    function takeBackStaleOffers() external {
        uint256 refundableAmount = _staleOffers(msg.sender);

        if (refundableAmount == ZERO) revert NO_AMOUNT_TO_REFUND();

        unchecked {
            offerorData[msg.sender].totalOffersValue -= refundableAmount;
        }

        _transferFromHelper(TREASURY, msg.sender, refundableAmount);

        emit StaleOffersTookBack(msg.sender, refundableAmount);
    }

    /// @dev Strange, isn't it? << Error Prone Getter >>
    function claimableAmount(uint256 gameID, address player) external {
        if (gameID > currentGameID) gameID = currentGameID;
        (Status stat, , , bytes memory tickets) = _gameUpdate(gameID);

        if (stat != Status.finished && stat != Status.claimable)
            revert FETCHED_CLAIMABLE_AMOUNT(
                stat,
                ZERO,
                ZERO,
                ZERO,
                int256(uint256(ZERO))
            );

        uint256 playerInitialFraxBalance = playerBalanceData[gameID][player]
            .initialFraxBalance;
        uint256 playerLoanedFraxBalance = playerBalanceData[gameID][player]
            .loanedFraxBalance;

        if (
            tickets.length == ONE &&
            tempTicketOwnership[gameID][uint8(tickets[ZERO])] == player
        ) {
            playerLoanedFraxBalance += gameData[gameID].virtualFraxBalance;
            delete totalPlayerTickets[gameID][player];
        }

        if (playerInitialFraxBalance == ZERO)
            revert FETCHED_CLAIMABLE_AMOUNT(
                stat,
                ZERO,
                ZERO,
                ZERO,
                int256(uint256(ZERO))
            );

        uint256 chosenConfig = gameData[gameID].chosenConfig;
        uint256 mooShare = (gameStratConfig[chosenConfig].beefyVault)
            .getPricePerFullShare();
        uint256 gameMooBalance = gameData[gameID].mooTokenBalance;
        uint256 gameRewardedMoo = ((gameMooBalance * mooShare) / 1e18) -
            gameMooBalance;

        uint256 gameInitialFraxBalance = gameData[gameID].initialFraxBalance;
        uint256 gameLoanedFraxBalance = gameData[gameID].loanedFraxBalance +
            gameData[gameID].virtualFraxBalance;

        uint256 playerClaimableMooAmount;

        if (gameInitialFraxBalance == playerInitialFraxBalance) {
            playerClaimableMooAmount = gameMooBalance;

            delete gameData[gameID].mooTokenBalance;
            delete gameData[gameID].initialFraxBalance;
            delete gameData[gameID].loanedFraxBalance;

            gameData[gameID].tickets = tickets;
        } else {
            playerClaimableMooAmount =
                ((((playerInitialFraxBalance * 1e18) / gameInitialFraxBalance) *
                    (
                        gameLoanedFraxBalance == ZERO
                            ? gameMooBalance
                            : (gameMooBalance - gameRewardedMoo)
                    )) / 1e18) +
                (
                    gameLoanedFraxBalance == ZERO
                        ? ZERO
                        : (((playerLoanedFraxBalance * 1e18) /
                            gameLoanedFraxBalance) * gameRewardedMoo) / 1e18
                );

            gameData[gameID].mooTokenBalance -= playerClaimableMooAmount;
            gameData[gameID].initialFraxBalance -= playerInitialFraxBalance;
            if (gameLoanedFraxBalance != ZERO)
                gameData[gameID].loanedFraxBalance -= playerBalanceData[gameID][
                    player
                ].loanedFraxBalance;
        }

        delete playerBalanceData[gameID][player];
        if (
            tickets.length == ONE &&
            tempTicketOwnership[gameID][uint8(tickets[ZERO])] == player
        ) delete gameData[gameID].virtualFraxBalance;

        ICurveStableNG curveStableNG = gameStratConfig[chosenConfig]
            .curveStableNG;
        uint256 beforeLPbalance = curveStableNG.balanceOf(THIS);

        playerClaimableMooAmount.withdrawLPT(
            gameStratConfig[chosenConfig].beefyVault
        );

        uint256 claimedAmount = CurveMooLib.burnLPT(
            curveStableNG.balanceOf(THIS) - beforeLPbalance,
            msg.sender,
            gameStratConfig[chosenConfig].fraxTokenPosition,
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

    /******************************\
    |-*-*-*-*-*   VIEW   *-*-*-*-*-|
    \******************************/
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
            TicketInfo[MAX_PARTIES] memory ticketsData
        )
    {
        uint256 gameID = currentGameID;
        maxPurchasableTickets = maxTicketsPerGame;
        (stat, eligibleToSell, currentWave, tickets) = _gameUpdate(gameID);

        uint256 index;

        if (stat != Status.commingWave && stat != Status.operational) {
            currentTicketValue = ticketPrice;
            nextWaveTicketValue = currentTicketValue * TWO;
            nextWaveWinrate = (BASIS**TWO) / TWO;

            if (stat == Status.ticketSale) {
                remainingTickets = MAX_PARTIES - gameData[gameID].soldTickets;
                while (index != MAX_PARTIES) {
                    ticketsData[index] = TicketInfo(
                        Offer(ZERO, ZERO_ADDRESS),
                        index,
                        tempTicketOwnership[gameID][uint8(index)]
                    );

                    unchecked {
                        index++;
                    }
                }
            } else {
                ticketsData[uint8(tickets[ZERO])] = TicketInfo(
                    Offer(ZERO, ZERO_ADDRESS),
                    uint8(tickets[ZERO]),
                    tempTicketOwnership[gameID][uint8(tickets[ZERO])]
                );

                if (tickets.length == TWO)
                    ticketsData[uint8(tickets[ONE])] = TicketInfo(
                        Offer(ZERO, ZERO_ADDRESS),
                        uint8(tickets[ONE]),
                        tempTicketOwnership[gameID][uint8(tickets[ONE])]
                    );
            }
        } else {
            remainingTickets = tickets.length;
            startedL1Block = gameData[gameID].startedL1Block;
            currentTicketValue = _ticketValue(tickets.length, gameID);
            nextWaveTicketValue =
                gameData[gameID].virtualFraxBalance /
                (tickets.length / TWO);
            nextWaveWinrate =
                ((tickets.length / TWO) * BASIS**TWO) /
                tickets.length;

            uint256 plus10PCT = currentTicketValue +
                (currentTicketValue * MIN_TICKET_VALUE_OFFER) /
                BASIS;

            while (index != tickets.length) {
                uint256 loadedOffer = offer[gameID][uint8(tickets[index])]
                    .amount;
                ticketsData[uint8(tickets[index])] = TicketInfo(
                    Offer(
                        loadedOffer >= plus10PCT ? uint96(loadedOffer) : ZERO,
                        loadedOffer >= plus10PCT
                            ? offer[gameID][uint8(tickets[index])].maker
                            : ZERO_ADDRESS
                    ),
                    uint8(tickets[index]),
                    tempTicketOwnership[gameID][uint8(tickets[index])]
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
        return _gameUpdate(currentGameID);
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
        public
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
        if (gameID_ > currentGameID) gameID = currentGameID;
        else gameID = gameID_;

        virtualFraxBalance = gameData[gameID].virtualFraxBalance;

        bytes memory tickets;
        (stat, eligibleToSell, currentWave, tickets) = _gameUpdate(gameID);

        winners = new address[](tickets.length);
        winnerTickets = new uint256[](tickets.length);

        for (uint256 i; i < tickets.length; ) {
            winners[i] = tempTicketOwnership[gameID][uint8(bytes1(tickets[i]))];
            winnerTickets[i] = uint8(bytes1(tickets[i]));

            unchecked {
                i++;
            }
        }
    }

    function paginatedPlayerGames(uint256 page)
        external
        view
        returns (
            uint256 currentPage,
            uint256 totalPages,
            uint256[] memory paggedArray
        )
    {
        if (playerRecentGames[msg.sender].length == 0)
            return (currentPage, totalPages, paggedArray);
        else if (playerRecentGames[msg.sender].length < 11) {
            paggedArray = new uint256[](playerRecentGames[msg.sender].length);

            uint256 x;
            while (true) {
                paggedArray[x] = playerRecentGames[msg.sender][
                    playerRecentGames[msg.sender].length - 1 - x
                ];

                if (x == playerRecentGames[msg.sender].length - 1) break;

                unchecked {
                    x++;
                }
            }

            return (1, 1, paggedArray);
        }

        if (page == 0) page = 1;

        totalPages = playerRecentGames[msg.sender].length / 10;

        uint256 diffLength = playerRecentGames[msg.sender].length -
            (totalPages * 10);

        if (totalPages * 10 < playerRecentGames[msg.sender].length)
            totalPages++;
        if (page > totalPages) page = totalPages;
        currentPage = page;

        uint256 firstIndex;
        uint256 lastIndex;
        if (page == 1) {
            firstIndex = playerRecentGames[msg.sender].length - 1;
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
            paggedArray[i] = playerRecentGames[msg.sender][firstIndex];

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
        (Status stat, , , bytes memory tickets) = _gameUpdate(currentGameID);

        if (stat != Status.commingWave && stat != Status.operational)
            return ticketPrice;

        return _ticketValue(tickets.length, currentGameID);
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

    /*****************************\
    |-*-*-*-*   PRIVATE   *-*-*-*-|
    \*****************************/
    /**
        @dev Allows the contract to transfer {FRAX} tokens to a specified address.
        @param to The address to which the {FRAX} tokens will be transferred.
        @param amount The amount of {FRAX} tokens to be transferred.
    */
    function _transferHelper(address to, uint256 amount) private {
        FRAX.transfer(to, amount);
    }

    /**
        @dev Allows the contract to transfer {FRAX} tokens from one address to another.
        @param from The address from which the {FRAX} tokens will be transferred.
        @param to The address to which the {FRAX} tokens will be transferred.
        @param amount The amount of {FRAX} tokens to be transferred.
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
        @return The total stale offer amount for the specified offeror.
    */
    function _staleOffers(address offeror) private view returns (uint256) {
        if (offerorData[offeror].latestGameID == currentGameID) {
            (Status stat, , , ) = _gameUpdate(currentGameID);

            if (stat != Status.commingWave && stat != Status.operational)
                return (offerorData[offeror].totalOffersValue);

            return (offerorData[offeror].totalOffersValue -
                offerorData[offeror].latestGameIDoffersValue);
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
        @return The new byte array after deleting the specified index.
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
        @notice Returns the current value of a winning ticket in {FRAX} tokens.
        @dev Calculates and returns the current value of a ticket
            by dividing the initialFraxBalance of {FRAX} tokens in the contract
            by the total number of winning tickets.
        @return The current value of a winning ticket in {FRAX} tokens.
    */
    function _ticketValue(uint256 totalTickets, uint256 gameID)
        private
        view
        returns (uint256)
    {
        return gameData[gameID].virtualFraxBalance / totalTickets;
    }

    /**
        @dev Creates a random seed value based on a series of l1 block prevrandaos.
            It selects various block prevrandaos and performs mathematical operations to calculate a random seed.
        @param startBlock The block number from where the calculation of the random seed starts.
        @return The random seed value generated based on l1 block prevrandaos.
    */
    function _createRandomSeed(uint256 startBlock, uint256 prngDuration)
        private
        view
        returns (uint256)
    {
        unchecked {
            return
                uint256(
                    keccak256(
                        abi.encodePacked(
                            uint256(
                                sha256(
                                    abi.encodePacked(
                                        FRAXTAL_L1_BLOCK.numberToRandao(
                                            uint64(
                                                startBlock -
                                                    prngDuration /
                                                    THREE
                                            )
                                        )
                                    )
                                )
                            ) +
                                FRAXTAL_L1_BLOCK.numberToRandao(
                                    uint64(startBlock - prngDuration / TWO)
                                ) +
                                uint160(
                                    ripemd160(
                                        abi.encodePacked(
                                            uint160(
                                                FRAXTAL_L1_BLOCK.numberToRandao(
                                                    uint64(
                                                        startBlock -
                                                            (prngDuration *
                                                                TWO) /
                                                            THREE
                                                    )
                                                )
                                            )
                                        )
                                    )
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
        uint256 i = tickets.length - ONE;
        while (true) {
            if (uint8(tickets[i]) == ticketID) {
                return (true, uint8(i));
            }

            if (i == ZERO) break;
            unchecked {
                i--;
            }
        }

        return (false, ZERO);
    }

    /**
        @notice Retrieves the current status and details of a specific game.
        @dev This function provides detailed information about a specific game
            including its status, eligible withdrawals, current wave, winner tickets, and game initialFraxBalance.
        @param gameID The ID of the game for which the status and details are being retrieved.
        @return stat The current status of the game
            {ticketSale, commingWave, operational, finished, claimable, completed}.
        @return eligibleToSell The number of eligible players to sell their tickets
            for the current game.
        @return currentWave The current wave of the game.
    */
    function _gameUpdate(uint256 gameID)
        private
        view
        returns (
            Status stat,
            int256 eligibleToSell,
            uint256 currentWave,
            bytes memory remainingTickets
        )
    {
        GameData memory GD = gameData[gameID];
        remainingTickets = GD.tickets;
        eligibleToSell = GD.eligibleToSell;

        uint256 currentL1Block = FRAXTAL_L1_BLOCK.number();

        if (GD.startedL1Block == ZERO) stat = Status.ticketSale;
        else if (GD.mooTokenBalance == ZERO) {
            stat = Status.completed;
            eligibleToSell = N_ONE;
        } else {
            currentWave = GD.updatedWave;
            uint256 lastUpdatedWave;
            uint256 accumulatedBlocks;
            uint256 waitingDuration = SAFTY_DURATION + GD.prngPeriod;

            if (GD.updatedWave != ZERO) {
                lastUpdatedWave = GD.updatedWave + ONE;

                for (uint256 i = ONE; i < lastUpdatedWave; ) {
                    unchecked {
                        accumulatedBlocks += WAVE_ELIGIBLES_TIME / i;
                        i++;
                    }
                }

                if (GD.eligibleToSell == N_ONE) {
                    stat = GD.startedL1Block +
                        L1_BLOCK_LOCK_TIME +
                        accumulatedBlocks +
                        currentWave *
                        waitingDuration <
                        currentL1Block
                        ? Status.claimable
                        : Status.finished;

                    return (
                        stat,
                        eligibleToSell,
                        currentWave,
                        remainingTickets
                    );
                }
            } else {
                if (!(GD.startedL1Block + waitingDuration < currentL1Block))
                    return (
                        Status.commingWave,
                        eligibleToSell,
                        currentWave,
                        remainingTickets
                    );

                lastUpdatedWave = ONE;
            }

            stat = Status.operational;
            uint256 prngDuration = GD.prngPeriod;

            while (true) {
                if (
                    GD.startedL1Block +
                        (lastUpdatedWave * waitingDuration) +
                        accumulatedBlocks <
                    currentL1Block
                ) {
                    remainingTickets = _shuffleBytedArray(
                        remainingTickets,
                        _createRandomSeed(
                            GD.startedL1Block +
                                (lastUpdatedWave * waitingDuration) +
                                accumulatedBlocks,
                            prngDuration
                        ),
                        remainingTickets.length / TWO
                    );

                    eligibleToSell = int256(remainingTickets.length / TWO);

                    if (remainingTickets.length == ONE) {
                        eligibleToSell = N_ONE;
                        currentWave = lastUpdatedWave;

                        stat = GD.startedL1Block +
                            L1_BLOCK_LOCK_TIME +
                            accumulatedBlocks +
                            currentWave *
                            waitingDuration <
                            currentL1Block
                            ? Status.claimable
                            : Status.finished;

                        break;
                    }

                    unchecked {
                        accumulatedBlocks +=
                            WAVE_ELIGIBLES_TIME /
                            lastUpdatedWave;
                        currentWave++;
                        lastUpdatedWave++;
                    }
                } else {
                    if (
                        GD.startedL1Block +
                            (currentWave * waitingDuration) +
                            accumulatedBlocks <
                        currentL1Block
                    ) stat = Status.commingWave;

                    break;
                }
            }
        }
    }

    /**
        @dev It verifies that the value is not zero
            and not greater than the maximum limit predefined as {EIGHT}.
        @param value The value to be checked for maximum tickets per game.
    */
    function _checkMTPG(uint8 value) private pure {
        _revertOnZeroUint(value);

        // if (value > EIGHT) revert VALUE_CANT_BE_GREATER_THAN(EIGHT);
    }

    /**
        @dev It verifies that the value is not zero
            and not lower than the minimum limit predefined as {MIN_PRNG_PERIOD}.
        @param value The value to be checked for maximum tickets per game.
    */
    function _checkPRNGP(uint256 value) private pure {
        _revertOnZeroUint(value);

        if (value < MIN_PRNG_PERIOD)
            revert VALUE_CANT_BE_LOWER_THAN(MIN_PRNG_PERIOD);
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
        @dev It verifies that the value is not zero
            and not greater than the maximum limit predefined as {SIX}.
        @param value The value to be checked for game strategy.
    */
    function _checkGS(uint8 value) private pure {
        if (value > SIX) revert VALUE_CANT_BE_GREATER_THAN(SIX);
    }

    /**
        @dev Checks if the provided uint value is zero and reverts the transaction if it is.
        @param uInt The uint value to be checked.
    */
    function _revertOnZeroUint(uint256 uInt) private pure {
        if (uInt == ZERO) revert ZERO_UINT_PROVIDED();
    }

    /**
        @dev Checks the current status of the game and reverts the transaction
            if the game status is not Operational.
        @param stat The current status of the game
            {ticketSale, commingWave, operational, finished, claimable, completed}.

    */
    function _onlyOperational(uint256 currentWave, Status stat) private pure {
        if (currentWave == ZERO) revert WAIT_FOR_FIRST_WAVE();

        if (stat != Status.operational) revert ONLY_OPERATIONAL_MODE(stat);
    }

    /**
        @dev Performs a linear search on the provided list of tickets to find the specific ticket ID.
            If the ticket ID is not found in the list of tickets, the transaction will be reverted.
        @param tickets The list of tickets to search within.
        @param ticketID The ticket ID to search for.
        @return The index of the found ticket ID in the list.
    */
    function _onlyWinnerTicket(bytes memory tickets, uint8 ticketID)
        private
        pure
        returns (uint8)
    {
        (bool found, uint8 index) = _findTicket(tickets, ticketID);
        if (!found) revert ONLY_WINNER_TICKET(ticketID);

        return index;
    }
}
