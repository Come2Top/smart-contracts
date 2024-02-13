/**********************************************************************\
                         █▀▀ █   ▄▀█ █▀ █▀ █ █▀▀
                         █▄▄ █▄▄ █▀█ ▄█ ▄█ █ █▄▄
                                                        + ꓕ$ՈꓭOꓤ
                     █▀█  ▄▀█  █▄ █  █▀▄  █▀█  █▀▄▀█    + 🆂🅴🅲🆄🆁🅴
                     █▀▄  █▀█  █ ▀█  █▄▀  █▄█  █ ▀ █    + 🇦​​​​​🇺​​​​​🇹​​​​​⌖​​​​​🇲​​​​​🇦​​​​​🇹​​​​​🇪​​​​​🇩​​​​​

               █   █▀▀ ▄▀█ █▀▄ █▀▀ █▀█ █▄▄ █▀█ ▄▀█ █▀█ █▀▄
               █▄▄ ██▄ █▀█ █▄▀ ██▄ █▀▄ █▄█ █▄█ █▀█ █▀▄ █▄▀

░░░░░░░░░░░░████████████████████████████████████████████████░░░░░░░░░░░░
░░░░░░░░░░░██████████████░ Waiting For You <3 ░██████████████░░░░░░░░░░░
░░░░░░░░░░████████████████████████████████████████████████████░░░░░░░░░░
░░░░░░░░░█████████​█​█​█​█​█​█​█​█​█​█████████.------.​█​█​█​█​█​█​█​█​█​█​█​█​█​█​█​█​█​█​█░░░░░░░░░
░░░░░░░░███████████████████████████.'   .' |████████████████████░░░░░░░░
░░░░░░░███████████████,----,█████.'   .'   |█████████████████████░░░░░░░
░░░░░░██████████████.'   .' \██.----.'    .'█████,---.,███████████░░░░░░
░░░░░█████████████.----.'    |█|    |   .'██████/    / \███████████░░░░░
░░░░██████████████|    |:'.  |█|    |  |--.████/    /  /████████████░░░░
░░░███████████████|    |:/  /██|    |  |.' \██/    /  /██████████████░░░
░░████████████████'----'/  /███|    |      |█|    /  |████████████████░░
░░░█████████████████/  /  /████'----'.'\   |█|   |   \███████████████░░░
░░░░███████████████/  /  /-.█████████\  \  |█|   |    ``\███████████░░░░
░░░░░█████████████/  /  /.'|███/   /\/  /  |█|   |  /'\  \█████████░░░░░
░░░░░░███████████/__/      |██/   /  \_/   |█|   |  |█|  |████████░░░░░░
░░░░░░░█████████|   |    .'███\   \       /██|   |  \./  |███████░░░░░░░
░░░░░░░░████████|   | .'███████\   \     /███\   \      /███████░░░░░░░░
░░░░░░░░░███████'---'███████████`--`----'█████`---`--`-'███████░░░░░░░░░
░░░░░░░░░░████████████████████████████████████████████████████░░░░░░░░░░
░░░░░░░░░░░█████████████░ https://www.256.cash ░█████████████░░░░░░░░░░░
░░░░░░░░░░░░████████████████████████████████████████████████░░░░░░░░░░░░
\**********************************************************************/

// SPDX-License-Identifier: --256--
pragma solidity 0.8.18;

import {IUSDC} from "./interfaces/IUSDC.sol";
import {IERC20} from "./interfaces/IERC20.sol";

import {OfferorsTreasury} from "./OfferorsTreasury.sol";

contract TwoHundredFiftySix {
    /*******************************\
    |-*-*-*-*-*   TYPES   *-*-*-*-*-|
    \*******************************/
    enum Status {
        notStarted,
        inProcess,
        finished
    }

    struct GameData {
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
        uint96 latestGameIDoffersValue;
        uint160 latestGameID;
        uint256 totalOffersValue;
    }

    /********************************\
    |-*-*-*-*-*   STATES   *-*-*-*-*-|
    \********************************/
    bool public pause;
    uint8 public maxTicketsPerGame;
    uint80 public ticketPrice;
    uint160 public currentGameID;

    mapping(uint256 => GameData) public gameData;
    mapping(address => OfferorData) public offerorData;
    mapping(uint256 => mapping(uint8 => address)) public ticketOwnership;
    mapping(uint256 => mapping(address => uint8)) public totalPlayerTickets;
    mapping(uint256 => mapping(uint8 => Offer)) public offer;

    /********************************\
    |-*-*-*-*-*   ERRORS   *-*-*-*-*-|
    \********************************/
    string private constant _OTF_ERR = "ONLY_TREASURY_FUNCTION";
    string private constant _OAF_ERR = "ONLY_ADMIN_FUNCTION";
    string private constant _OEOAF_ERR = "ONLY_EOA_FUNCTION";
    string private constant _OIPG_ERR = "ONLY_IN_PROGRESS_GAME";
    string private constant _OPAFG_ERR = "ONLY_PAUSED_AND_FINISHED_GAME";
    string private constant _OUOIPG_ERR = "ONLY_UNPAUSED_OR_IN_PROCESS_GAME";
    string private constant _OWT_ERR = "ONLY_WINNER_TICKETS";
    string private constant _OHTCOATV_ERR =
        "ONLY_HIGHER_THAN_CURRENT_OFFER_AND_TICKET_VALUE";

    string private constant _ITAP_ERR = "INVALID_TOKEN_ADDRESS_PROVIDED";
    string private constant _OSR_ERR = "OWNERSHIP_REQUESTED";
    string private constant _IB_ERR = "INSUFFICIENT_BALANCE";
    string private constant _AN_ERR = "APPROVE_NEEDED";
    string private constant _NR_ERR = "NON_REFUNDABLE";

    string private constant _NOOTT_ERR = "NO_OFFER_ON_THIS_TICKET";
    string private constant _PB_ERR = "PARTICIPATED_BEFORE";
    string private constant _TR_ERR = "TICKET_RESERVED";
    string private constant _LT_ERR = "LOSER_TICKET";
    string private constant _NE_ERR = "NOT_ELIGIBLE";
    string private constant _NS_ERR = "NOT_STARTED";
    string private constant _GF_ERR = "GAME_FINISHED";

    string private constant _WFW1_ERR = "WAIT_FOR_WAVE_1";
    string private constant _WFNW_ERR = "WAIT_FOR_NEXT_WAVE";
    string private constant _WFNM_ERR = "WAIT_FOR_NEXT_MATCH";

    string private constant _PI_ERR = "PROVIDE_INDEXES";
    string private constant _CHA_ERR = "CHECK_TICKETS_ARRAY";
    string private constant _OOT_ERR = "OUT_OF_TICKETS";
    string private constant _IOOB_ERR = "INDEX_OUT_OF_BOUNDS";
    string private constant _OOEW_ERR = "OUT_OF_ELIGIBLE_WITHDRAWNS";

    string private constant _ZAP_ERR = "ZERO_ADDRESS_PROVIDED";
    string private constant _ZUP_ERR = "ZERO_UINT_PROVIDED";

    string private constant _NIP2_ERR = "NOT_IN_POW2";
    string private constant _NOI_ERR = "NOT_ORDERIZE_INDEXES";

    /*******************************\
    |-*-*-*-*   CONSTANTS   *-*-*-*-|
    \*******************************/
    IUSDC public immutable USDC;
    address public immutable ADMIN;
    OfferorsTreasury public immutable TREASURY;
    address private immutable $THIS = address(this);
    uint256 private constant _OFFEREE_BENEFICIARY = 950000;
    uint256 private constant _FEE = 10000;
    uint256 private constant _BASIS = 1000000;
    uint256 private constant _WAVE_DURATION = 93;
    uint256 private constant _MAX_PARTIES = 256;
    bytes private constant _TICKET256 =
        hex"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff";

    /********************************\
    |-*-*-*-*-*   EVENTS   *-*-*-*-*-|
    \********************************/
    event TicketsSold(address indexed buyer, bytes ticketIDs);

    event GameStarted(
        uint256 indexed gameID,
        uint256 indexed startedBlockNo,
        uint256 indexed prizeAmount
    );

    event GameUpdated(
        uint256 indexed gameID,
        address indexed winner,
        uint256 indexed amount,
        uint256[] ticketIDs
    );

    event GameFinished(
        uint256 indexed gameID,
        address indexed winner,
        uint256 indexed amount,
        uint256 ticketID
    );

    event GameFinished(
        uint256 indexed gameID,
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

    event StaleOffersTookBack(
        address indexed maker,
        address indexed to,
        uint256 indexed amount
    );

    /*******************************\
    |-*-*-*-*   MODIFIERS   *-*-*-*-|
    \*******************************/
    modifier only(address account, string memory error) {
        require(msg.sender == account, error);
        _;
    }

    modifier onlyPausedAndFinishedGame() {
        require(
            gameData[currentGameID].eligibleWithdrawals == -1 && pause == true,
            _OPAFG_ERR
        );

        _;
    }

    /******************************\
    |-*-*-*-*   BUILT-IN   *-*-*-*-|
    \******************************/
    constructor(
        address admin,
        address usdc,
        uint8 mtpg,
        uint80 tp
    ) {
        require(admin != address(0) && usdc != address(0), _ZAP_ERR);
        require(mtpg != 0 && tp != 0, _ZUP_ERR);
        _onlyPow2(mtpg);

        ADMIN = admin;
        USDC = IUSDC(usdc);
        maxTicketsPerGame = mtpg;
        ticketPrice = tp;

        gameData[0].tickets = _TICKET256;

        TREASURY = new OfferorsTreasury(USDC);
    }

    /*******************************\
    |-*-*-*   ADMINSTRATION   *-*-*-|
    \*******************************/
    function rescueERC20(address token, address to)
        external
        only(ADMIN, _OAF_ERR)
    {
        uint256 balance;

        require(token != address(USDC), _NR_ERR);
        try IERC20(token).balanceOf($THIS) returns (uint256 b) {
            balance = b;
        } catch {
            revert(_ITAP_ERR);
        }
        require(balance != 0, _IB_ERR);

        IERC20(token).transfer(to, balance);
    }

    function rescueMatic(address payable to) external only(ADMIN, _OAF_ERR) {
        uint256 balance = $THIS.balance;
        require(balance != 0, _IB_ERR);

        to.transfer(balance);
    }

    function togglePause() external only(ADMIN, _OAF_ERR) {
        pause = !pause;
    }

    function changeMTPG(uint8 maxTicketsPerGame_)
        external
        only(ADMIN, _OAF_ERR)
        onlyPausedAndFinishedGame
    {
        _revertOnZeroUint(maxTicketsPerGame_);
        _onlyPow2(maxTicketsPerGame_);

        maxTicketsPerGame = maxTicketsPerGame_;
    }

    function changeTP(uint80 ticketPrice_)
        external
        only(ADMIN, _OAF_ERR)
        onlyPausedAndFinishedGame
    {
        _revertOnZeroUint(ticketPrice_);

        ticketPrice = ticketPrice_;
    }

    /******************************\
    |-*-*-*-*-*   GAME   *-*-*-*-*-|
    \******************************/
    function joinGame(uint8[] calldata ticketIDs)
        external
        only(tx.origin, _OEOAF_ERR)
    {
        GameData storage GD;
        address sender = msg.sender;
        uint256 gameID = currentGameID;
        uint256 neededUSDC = ticketPrice;
        uint256 totalTickets = ticketIDs.length;
        uint256 ticketLimit = maxTicketsPerGame + 1;

        if (gameData[gameID].eligibleWithdrawals == -1) {
            unchecked {
                gameID++;
                currentGameID++;
            }
            GD = gameData[gameID];
            GD.tickets = _TICKET256;
        } else GD = gameData[gameID];

        uint256 remainingTickets = _MAX_PARTIES - GD.soldTickets;
        bytes memory tickets = GD.tickets;

        require(pause == false || GD.soldTickets != 0, _OUOIPG_ERR);
        require(totalTickets != 0 && totalTickets < ticketLimit, _CHA_ERR);
        require(GD.startedBlock == 0, _WFNM_ERR);
        require(
            totalTickets + totalPlayerTickets[gameID][sender] < ticketLimit,
            _PB_ERR
        );
        require(totalTickets < remainingTickets, _OOT_ERR);
        require(
            !(USDC.allowance(sender, $THIS) < (totalTickets * neededUSDC)),
            _AN_ERR
        );

        bytes memory realTickets;

        for (uint256 i; i < totalTickets; ) {
            if (ticketIDs[i] == 0) {
                if (tickets[0] != 0xff) {
                    tickets[0] = 0xff;
                    realTickets = abi.encodePacked(bytes1(0x00));
                }
            } else {
                if (tickets[ticketIDs[i]] != 0x00) {
                    tickets[ticketIDs[i]] = 0x00;
                    realTickets = abi.encodePacked(
                        realTickets,
                        bytes1(ticketIDs[i])
                    );
                }
            }

            unchecked {
                ticketOwnership[gameID][ticketIDs[i]] = sender;
                i++;
            }
        }
        totalTickets = realTickets.length;

        _revertOnZeroUint(totalTickets);

        totalPlayerTickets[gameID][sender] += uint8(totalTickets);

        USDC.transferFrom(sender, $THIS, (totalTickets * neededUSDC));

        GD.tickets = tickets;

        emit TicketsSold(sender, realTickets);

        if (totalTickets == remainingTickets) {
            uint256 currentBlock = block.number;
            GD.startedBlock = uint216(currentBlock);
            GD.tickets = _TICKET256;
            emit GameStarted(gameID, currentBlock, _MAX_PARTIES * neededUSDC);
        }
    }

    function receiveLotteryWagedPrize(uint8[] calldata indexes) external {
        uint256 fee;
        address sender = msg.sender;
        uint256 gameID = currentGameID;
        uint256 balance = USDC.balanceOf($THIS);
        uint256 length = indexes.length;

        (
            Status stat,
            int256 eligibleWithdrawals,
            uint256 currentWave,
            bytes memory tickets
        ) = getLatestUpdate();

        require(length != 0, _PI_ERR);
        require(stat != Status.notStarted, _NS_ERR);
        require(currentWave != 0, _WFW1_ERR);
        require(eligibleWithdrawals != 0, _NE_ERR);
        require(stat != Status.finished, _GF_ERR);
        require(length <= uint256(eligibleWithdrawals), _OOEW_ERR);

        if (tickets.length < 3) {
            fee = (balance * _FEE) / _BASIS;

            gameData[gameID].tickets = tickets;
            gameData[gameID].eligibleWithdrawals = -1;

            USDC.transfer(ADMIN, fee);

            if (tickets.length == 1) {
                address ticketOwner = ticketOwnership[gameID][
                    uint8(tickets[0])
                ];

                delete ticketOwnership[gameID][uint8(tickets[0])];

                bool isBlacklisted = USDC.isBlacklisted(ticketOwner);

                if (!isBlacklisted) USDC.transfer(ticketOwner, balance - fee);
                else USDC.transfer(ADMIN, balance - fee);

                emit GameFinished(
                    gameID,
                    ticketOwner,
                    isBlacklisted ? 0 : balance - fee,
                    uint8(tickets[0])
                );
            } else {
                require(
                    ticketOwnership[gameID][uint8(tickets[indexes[0]])] ==
                        sender,
                    _OSR_ERR
                );

                address winner1 = ticketOwnership[gameID][uint8(tickets[0])];
                address winner2 = ticketOwnership[gameID][uint8(tickets[1])];
                uint256 winner2Amount = (balance - fee) / 2;
                uint256 winner1Amount = balance - fee - winner2Amount;

                delete ticketOwnership[gameID][uint8(tickets[0])];
                delete ticketOwnership[gameID][uint8(tickets[1])];

                bool isBlacklisted1 = USDC.isBlacklisted(winner1);
                bool isBlacklisted2 = USDC.isBlacklisted(winner2);

                if (!isBlacklisted1) USDC.transfer(winner1, winner1Amount);
                else USDC.transfer(ADMIN, winner1Amount);

                if (!isBlacklisted2) USDC.transfer(winner2, winner2Amount);
                else USDC.transfer(ADMIN, winner2Amount);

                emit GameFinished(
                    gameID,
                    [winner1, winner2],
                    [
                        isBlacklisted1 ? 0 : winner1Amount,
                        isBlacklisted2 ? 0 : winner2Amount
                    ],
                    [uint256(uint8(tickets[0])), uint256(uint8(tickets[1]))]
                );
            }
        } else {
            bytes memory updatedTickets;
            uint256[] memory ticketIDs = new uint256[](length);

            require(
                ticketOwnership[gameID][uint8(tickets[indexes[0]])] == sender,
                _OSR_ERR
            );
            require(indexes[0] < tickets.length, _IOOB_ERR);

            delete ticketOwnership[gameID][uint8(tickets[indexes[0]])];

            if (length == 1) {
                ticketIDs[0] = uint8(tickets[indexes[0]]);

                updatedTickets = _deleteOneIndex(indexes[0], tickets);
            } else {
                updatedTickets = this.returnBytedCalldataArray(
                    tickets,
                    0,
                    indexes[0]
                );
                ticketIDs[0] = uint8(tickets[indexes[0]]);
                for (uint256 i = 1; i < length; ) {
                    require(indexes[i] > indexes[i - 1], _NOI_ERR);
                    require(indexes[i] < tickets.length, _IOOB_ERR);
                    require(
                        ticketOwnership[gameID][uint8(tickets[indexes[i]])] ==
                            sender,
                        _OSR_ERR
                    );

                    delete ticketOwnership[gameID][uint8(tickets[indexes[i]])];

                    ticketIDs[i] = uint8(tickets[indexes[i]]);

                    updatedTickets = abi.encodePacked(
                        updatedTickets,
                        this.returnBytedCalldataArray(
                            tickets,
                            indexes[i - 1] + 1,
                            indexes[i]
                        )
                    );

                    unchecked {
                        i++;
                    }
                }

                // Check if there are elements after the last index
                if (indexes[indexes.length - 1] < length - 1) {
                    updatedTickets = abi.encodePacked(
                        updatedTickets,
                        this.returnBytedCalldataArray(
                            tickets,
                            indexes[length - 1] + 1,
                            tickets.length
                        )
                    );
                }
            }

            uint256 idealWinnerPrize = (balance / tickets.length) * length;
            fee = (idealWinnerPrize * _FEE) / _BASIS;

            bool isBlacklisted = USDC.isBlacklisted(sender);
            if (isBlacklisted) USDC.transfer(ADMIN, idealWinnerPrize);
            else {
                USDC.transfer(ADMIN, fee);
                USDC.transfer(sender, idealWinnerPrize - fee);
            }

            unchecked {
                eligibleWithdrawals -= int256(length);
            }

            gameData[gameID].tickets = updatedTickets;
            gameData[gameID].eligibleWithdrawals = int8(eligibleWithdrawals);

            if (gameData[gameID].updatedWave != currentWave)
                gameData[gameID].updatedWave = uint8(currentWave);

            emit GameUpdated(
                gameID,
                sender,
                isBlacklisted ? 0 : idealWinnerPrize - fee,
                ticketIDs
            );
        }
    }

    function makeOffer(uint8 ticketID, uint96 amount)
        external
        only(tx.origin, _OEOAF_ERR)
    {
        (Status stat, , , bytes memory tickets) = getLatestUpdate();
        address sender = msg.sender;
        uint256 gameID = currentGameID;
        uint256 ticketValue = _currentTicketValue(tickets.length);
        Offer memory O = offer[gameID][ticketID];

        require(stat == Status.inProcess, _OIPG_ERR);
        require(amount > O.amount && amount > ticketValue, _OHTCOATV_ERR);

        require(_linearSearch(tickets, ticketID), _OWT_ERR);
        require(!(USDC.allowance(sender, $THIS) < ticketValue), _AN_ERR);

        if (O.amount != 0) {
            TREASURY.transferUSDC(O.maker, O.amount);

            unchecked {
                offerorData[O.maker].latestGameIDoffersValue -= O.amount;
                offerorData[O.maker].totalOffersValue -= O.amount;
            }
        }

        USDC.transferFrom($THIS, address(TREASURY), ticketValue);

        offer[gameID][ticketID] = Offer(amount, sender);

        unchecked {
            offerorData[sender].totalOffersValue += ticketValue;
        }

        if (offerorData[sender].latestGameID != gameID) {
            offerorData[sender].latestGameID = uint160(gameID);
            offerorData[sender].latestGameIDoffersValue = uint96(ticketValue);
        } else
            offerorData[sender].latestGameIDoffersValue += uint96(ticketValue);

        emit OfferMade(sender, ticketID, amount, O.maker);
    }

    function acceptOffers(uint8 ticketID) external {
        address sender = msg.sender;
        uint256 gameID = currentGameID;
        address ticketOwner = ticketOwnership[gameID][ticketID];
        Offer memory O = offer[gameID][ticketID];
        (Status stat, , , bytes memory tickets) = getLatestUpdate();

        require(stat == Status.inProcess, _OIPG_ERR);
        require(_linearSearch(tickets, ticketID), _OWT_ERR);
        require(O.amount != 0, _NOOTT_ERR);
        require(sender == ticketOwner, _OSR_ERR);

        offerorData[O.maker].latestGameIDoffersValue -= O.amount;
        offerorData[O.maker].totalOffersValue -= O.amount;
        delete offer[gameID][ticketID];
        ticketOwnership[gameID][ticketID] = O.maker;

        TREASURY.transferUSDC($THIS, O.amount);
        bool isBlacklisted = USDC.isBlacklisted(sender);
        if (!isBlacklisted)
            USDC.transfer(sender, (O.amount * _OFFEREE_BENEFICIARY) / _BASIS);

        emit OfferAccepted(
            O.maker,
            ticketID,
            isBlacklisted ? 0 : (O.amount * _OFFEREE_BENEFICIARY) / _BASIS,
            sender
        );
    }

    function takeBackStaleOffers(address to) external {
        address sender = msg.sender;
        if (to == address(0)) to = sender;

        uint256 refundableAmount = _getStaleOfferorAmount(sender);

        require(refundableAmount != 0, _NR_ERR);

        offerorData[sender].totalOffersValue -= refundableAmount;

        TREASURY.transferUSDC(to, refundableAmount);

        emit StaleOffersTookBack(sender, to, refundableAmount);
    }

    /******************************\
    |-*-*-*-*-*   VIEW   *-*-*-*-*-|
    \******************************/
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
        uint256 gameID = currentGameID;
        GameData memory GD = gameData[gameID];

        eligibleWithdrawals = GD.eligibleWithdrawals;
        currentWave = GD.updatedWave;
        tickets = GD.tickets;

        if (GD.startedBlock == 0 || GD.eligibleWithdrawals == -1)
            stat = GD.startedBlock == 0 ? Status.notStarted : Status.finished;
        else {
            stat = Status.inProcess;

            uint256 randomSeed;
            uint256 currentBlock = block.number;
            uint256 lastUpdatedWave = GD.updatedWave == 0
                ? 1
                : GD.updatedWave + 1;

            while (
                (lastUpdatedWave * _WAVE_DURATION) + GD.startedBlock <
                currentBlock
            ) {
                randomSeed = _getRandomSeed(
                    currentBlock + (lastUpdatedWave * _WAVE_DURATION)
                );
                tickets = _bytedArrayShuffler(
                    tickets,
                    randomSeed,
                    tickets.length / 2
                );

                unchecked {
                    lastUpdatedWave++;
                    eligibleWithdrawals = int256(tickets.length / 2);
                }

                if (eligibleWithdrawals < 2) {
                    eligibleWithdrawals = 1;
                    break;
                }
            }
        }
    }

    function currentTicketValue() external view returns (uint256) {
        (, , , bytes memory tickets) = getLatestUpdate();
        return _currentTicketValue(tickets.length);
    }

    function getStaleOfferorAmount(address account)
        external
        view
        returns (uint256)
    {
        return _getStaleOfferorAmount(account);
    }

    function returnBytedCalldataArray(
        bytes calldata array,
        uint256 from,
        uint256 to
    ) external pure returns (bytes memory) {
        return array[from:to];
    }

    /*****************************\
    |-*-*-*-*   PRIVATE   *-*-*-*-|
    \*****************************/
    function _getStaleOfferorAmount(address _account)
        private
        view
        returns (uint256)
    {
        if (offerorData[_account].latestGameID == currentGameID)
            return (offerorData[_account].totalOffersValue -
                offerorData[_account].latestGameIDoffersValue);
        return (offerorData[_account].totalOffersValue);
    }

    function _bytedArrayShuffler(
        bytes memory _array,
        uint256 _randomSeed,
        uint256 _to
    ) private view returns (bytes memory) {
        uint256 i;
        uint256 j;
        uint256 n = _array.length;
        while (i != n) {
            unchecked {
                j = uint256(keccak256(abi.encode(_randomSeed, i))) % (i + 1);
                (_array[i], _array[j]) = (_array[j], _array[i]);
                i++;
            }
        }

        return this.returnBytedCalldataArray(_array, 0, _to);
    }

    function _deleteOneIndex(uint8 _index, bytes memory _bytesArray)
        private
        view
        returns (bytes memory)
    {
        return
            _index != (_bytesArray.length - 1)
                ? abi.encodePacked(
                    this.returnBytedCalldataArray(_bytesArray, 0, _index),
                    this.returnBytedCalldataArray(
                        _bytesArray,
                        _index + 1,
                        _bytesArray.length
                    )
                )
                : this.returnBytedCalldataArray(_bytesArray, 0, _index);
    }

    function _currentTicketValue(uint256 _totalTickets)
        private
        view
        returns (uint256)
    {
        return USDC.balanceOf($THIS) / _totalTickets;
    }

    function _getRandomSeed(uint256 startBlock) private view returns (uint256) {
        require(!(startBlock > block.number), _WFNW_ERR);

        uint256 b = _WAVE_DURATION;
        uint256 index = 20;

        uint256[] memory parts = new uint256[](5);
        uint256[] memory blockHashes = new uint256[](21);

        while (blockHashes[0] == 0) {
            unchecked {
                blockHashes[index] = uint256(blockhash(startBlock - b));
                b--;
                index--;
            }
        }

        for (uint256 i; i < 10; i++) {
            unchecked {
                parts[0] += blockHashes[i];
            }
        }

        parts[2] = blockHashes[10];

        for (uint256 i = 11; i < 21; i++) {
            unchecked {
                parts[4] -= blockHashes[i];
            }
        }

        uint256 cachedNum;
        if (parts[0] > parts[2] && parts[0] > parts[4]) {
            if (parts[2] < parts[4]) {
                cachedNum = parts[2];
                parts[2] = parts[4];
                parts[4] = cachedNum;
            }
        } else {
            if (parts[4] > parts[0] && parts[4] > parts[2]) {
                cachedNum = parts[4];

                if (parts[0] > parts[2]) {
                    parts[4] = parts[2];
                    parts[2] = parts[0];
                } else parts[4] = parts[0];
            } else {
                cachedNum = parts[2];

                if (parts[0] < parts[4]) {
                    parts[2] = parts[4];
                    parts[4] = parts[0];
                } else parts[2] = parts[0];
            }
            parts[0] = cachedNum;
        }

        unchecked {
            parts[1] = (parts[0] / 2) + (parts[2] / 2);
            parts[3] = (parts[2] / 2) + (parts[4] / 2);

            return uint256(keccak256(abi.encodePacked(parts[1] * parts[3])));
        }
    }

    function _linearSearch(bytes memory tickets, uint8 ticketID)
        private
        pure
        returns (bool)
    {
        for (uint256 i = tickets.length - 1; i >= 0; ) {
            if (uint8(tickets[i]) == ticketID) {
                return true;
            }

            unchecked {
                i--;
            }
        }
        return false;
    }

    function _onlyPow2(uint8 number) private pure {
        require((number & (number - 1)) == 0, _NIP2_ERR);
    }

    function _revertOnZeroUint(uint256 integer) private pure {
        require(integer != 0, _ZUP_ERR);
    }
}
