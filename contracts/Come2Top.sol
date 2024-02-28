//  SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface IUSDT {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract Come2Top {
    /*******************************\
    |-*-*-*-*-*   TYPES   *-*-*-*-*-|
    \*******************************/
    enum Status {
        notStarted,
        ticketSale,
        inProgress,
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

    struct TicketInfo {
        uint256 ticketID;
        address owner;
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

    /*******************************\
    |-*-*-*-*   CONSTANTS   *-*-*-*-|
    \*******************************/
    IUSDT public immutable USDT;
    address public immutable TREASURY;
    address public immutable ADMIN = tx.origin;
    address public immutable THIS = address(this);
    uint256 public constant MAX_TICKET_PRICE = 1e9;
    uint256 public constant MIN_TICKET_PRICE = 1e6;
    uint256 public constant MAX_PARTIES = 256;
    uint256 public constant BASIS = 100;
    uint256 public constant OFFEREE_BENEFICIARY = 95;
    uint256 public constant WAVE_DURATION = 93;
    uint256 public constant MAX_TICKETS_PER_GAME = 8;
    bytes public constant TICKET256 =
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
        uint256 ticketID
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

    /********************************\
    |-*-*-*-*-*   ERRORS   *-*-*-*-*-|
    \********************************/
    error ONLY_EOA();
    error ONLY_ADMIN();
    error ONLY_TICKET_OWNER(uint256 ticketID);
    error ONLY_WINNER_TICKET(uint256 ticketID);
    error ONLY_IN_PROGRESS_MODE(Status currentStat);
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
    error ZERO_ELIGIBLE_WITHDRAWALS();
    error ZERO_ADDRESS_PROVIDED();
    error ZERO_UINT_PROVIDED();
    error CHECK_TICKETS_LENGTH(uint256 ticketLength);
    error FEWER_TICKETS_LEFT(uint256 remainingTickets);
    error SLECTED_TICKETS_SOLDOUT_BEFORE();
    error PARTICIPATED_BEFORE();
    error PLAYER_HAS_NO_TICKETS();
    error NO_AMOUNT_TO_REFUND();
    error OFFER_NOT_FOUND();
    error WAIT_FOR_NEXT_GAME_MATCH();
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
        if (msg.sender != ticketOwnership[currentGameID][ticketID])
            revert ONLY_TICKET_OWNER(ticketID);

        _;
    }

    modifier onlyPausedAndFinishedGame() {
        if (!pause || gameData[currentGameID].eligibleWithdrawals != -1)
            revert ONLY_PAUSED_AND_FINISHED_MODE(pause);

        _;
    }

    /******************************\
    |-*-*-*-*   BUILT-IN   *-*-*-*-|
    \******************************/
    constructor(
        uint8 mtpg,
        uint80 tp,
        address usdt,
        address treasury
    ) {
        _checkMTPG(mtpg);
        _checkTP(tp);
        if (usdt == address(0) || treasury == address(0))
            revert ZERO_ADDRESS_PROVIDED();

        maxTicketsPerGame = mtpg;
        ticketPrice = tp;
        USDT = IUSDT(usdt);
        TREASURY = treasury;

        gameData[0].tickets = TICKET256;

        (bool ok, ) = treasury.call(abi.encode(usdt));
        if (!ok) revert APROVE_OPERATION_FAILED();
    }

    /*******************************\
    |-*-*-*   ADMINSTRATION   *-*-*-|
    \*******************************/
    function togglePause() external onlyAdmin {
        pause = !pause;
    }

    function changeMaxTicketsPerGame(uint8 maxTicketsPerGame_)
        external
        onlyAdmin
        onlyPausedAndFinishedGame
    {
        _checkMTPG(maxTicketsPerGame_);

        maxTicketsPerGame = maxTicketsPerGame_;
    }

    function changeTicketPrice(uint80 ticketPrice_)
        external
        onlyAdmin
        onlyPausedAndFinishedGame
    {
        _checkTP(ticketPrice_);

        ticketPrice = ticketPrice_;
    }

    /********************************\
    |-*-*-*-*   GAME-LOGIC   *-*-*-*-|
    \********************************/
    function joinGame(uint8[] calldata ticketIDs) external onlyEOA {
        address sender = msg.sender;
        uint256 gameID = currentGameID;
        uint256 neededUSDT = ticketPrice;
        uint256 totalTickets = ticketIDs.length;
        uint256 ticketLimit = maxTicketsPerGame;
        GameData storage GD;

        if (gameData[gameID].eligibleWithdrawals == -1) {
            unchecked {
                gameID++;
                currentGameID++;
            }
            GD = gameData[gameID];
            GD.tickets = TICKET256;
        } else GD = gameData[gameID];

        uint256 remainingTickets = MAX_PARTIES - GD.soldTickets;
        bytes memory tickets = GD.tickets;

        if (pause && GD.soldTickets == 0)
            revert ONLY_UNPAUSED_OR_TICKET_SALE_MODE(pause);
        if (totalTickets == 0 || totalTickets > ticketLimit)
            revert CHECK_TICKETS_LENGTH(totalTickets);
        if (GD.startedBlock != 0) revert WAIT_FOR_NEXT_GAME_MATCH();
        if (totalTickets + totalPlayerTickets[gameID][sender] > ticketLimit)
            revert PARTICIPATED_BEFORE();
        if (totalTickets > remainingTickets)
            revert FEWER_TICKETS_LEFT(remainingTickets);

        bytes memory realTickets;

        for (uint256 i; i < totalTickets; ) {
            if (ticketIDs[i] == 0) {
                if (tickets[0] != 0xff) {
                    tickets[0] = 0xff;

                    realTickets = abi.encodePacked(realTickets, bytes1(0x00));

                    ticketOwnership[gameID][0] = sender;
                }
            } else {
                if (tickets[ticketIDs[i]] != 0x00) {
                    tickets[ticketIDs[i]] = 0x00;

                    realTickets = abi.encodePacked(
                        realTickets,
                        bytes1(ticketIDs[i])
                    );

                    ticketOwnership[gameID][ticketIDs[i]] = sender;
                }
            }

            unchecked {
                i++;
            }
        }

        totalTickets = realTickets.length;

        if (totalTickets == 0) revert SLECTED_TICKETS_SOLDOUT_BEFORE();

        totalPlayerTickets[gameID][sender] += uint8(totalTickets);

        _transferFromHelper(sender, THIS, (totalTickets * neededUSDT));

        GD.tickets = tickets;

        emit TicketsSold(sender, realTickets);

        if (totalTickets == remainingTickets) {
            uint256 currentBlock = block.number;
            GD.startedBlock = uint216(currentBlock);
            GD.tickets = TICKET256;
            emit GameStarted(gameID, currentBlock, MAX_PARTIES * neededUSDT);
        } else GD.soldTickets += uint8(totalTickets);
    }

    function receiveLotteryWagedPrize(uint8 ticketID) external {
        uint256 fee;
        address sender = msg.sender;
        uint256 gameID = currentGameID;
        uint256 balance = USDT.balanceOf(THIS);

        (
            Status stat,
            int256 eligibleWithdrawals,
            uint256 currentWave,
            bytes memory tickets
        ) = getLatestUpdate();

        _onlyInProgressMode(stat);
        uint8 index = _onlyWinnerTicket(tickets, ticketID);
        if (currentWave == 0) revert WAIT_FOR_FIRST_WAVE();
        if (eligibleWithdrawals == 0) revert ZERO_ELIGIBLE_WITHDRAWALS();

        if (tickets.length < 3) {
            fee = balance / BASIS;

            gameData[gameID].tickets = tickets;
            gameData[gameID].eligibleWithdrawals = -1;

            _transferHelper(ADMIN, fee);

            if (tickets.length == 1) {
                address ticketOwner = ticketOwnership[gameID][ticketID];

                delete ticketOwnership[gameID][ticketID];
                delete totalPlayerTickets[gameID][ticketOwner];

                _transferHelper(ticketOwner, balance - fee);

                emit GameFinished(gameID, ticketOwner, balance - fee, ticketID);
            } else {
                if (sender != ticketOwnership[currentGameID][ticketID])
                    revert ONLY_TICKET_OWNER(ticketID);

                address winner1 = ticketOwnership[gameID][uint8(tickets[0])];
                address winner2 = ticketOwnership[gameID][uint8(tickets[1])];
                uint256 winner2Amount = (balance - fee) / 2;
                uint256 winner1Amount = balance - fee - winner2Amount;

                delete ticketOwnership[gameID][uint8(tickets[0])];
                delete ticketOwnership[gameID][uint8(tickets[1])];

                delete totalPlayerTickets[gameID][winner1];
                delete totalPlayerTickets[gameID][winner2];

                _transferHelper(winner1, winner1Amount);
                _transferHelper(winner2, winner2Amount);

                emit GameFinished(
                    gameID,
                    [winner1, winner2],
                    [winner1Amount, winner2Amount],
                    [uint256(uint8(tickets[0])), uint256(uint8(tickets[1]))]
                );
            }
        } else {
            if (sender != ticketOwnership[currentGameID][ticketID])
                revert ONLY_TICKET_OWNER(ticketID);

            delete ticketOwnership[gameID][ticketID];
            totalPlayerTickets[gameID][sender]--;

            gameData[gameID].tickets = _deleteOneIndex(index, tickets);
            gameData[gameID].eligibleWithdrawals =
                int8(eligibleWithdrawals) -
                1;

            if (gameData[gameID].updatedWave != currentWave)
                gameData[gameID].updatedWave = uint8(currentWave);

            uint256 idealWinnerPrize = balance / tickets.length;
            fee = idealWinnerPrize / BASIS;

            _transferHelper(ADMIN, fee);
            _transferHelper(sender, idealWinnerPrize - fee);

            emit GameUpdated(gameID, sender, idealWinnerPrize - fee, ticketID);
        }
    }

    function makeOffer(uint8 ticketID, uint96 amount) external onlyEOA {
        address sender = msg.sender;
        uint256 gameID = currentGameID;
        (Status stat, , , bytes memory tickets) = getLatestUpdate();
        uint256 ticketValue = _currentTicketValue(tickets.length);
        Offer memory O = offer[gameID][ticketID];
        uint256 offerorStaleAmount = _getStaleOfferorAmount(sender);

        _onlyInProgressMode(stat);
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

        if (offerorData[sender].latestGameID != gameID) {
            offerorData[sender].latestGameID = uint160(gameID);
            offerorData[sender].latestGameIDoffersValue = uint96(amount);
        } else offerorData[sender].latestGameIDoffersValue += uint96(amount);

        if (O.amount != 0) {
            _transferFromHelper(TREASURY, O.maker, O.amount);

            unchecked {
                offerorData[O.maker].totalOffersValue -= O.amount;
                offerorData[O.maker].latestGameIDoffersValue -= O.amount;
            }
        }

        offer[gameID][ticketID] = Offer(amount, sender);

        emit OfferMade(sender, ticketID, amount, O.maker);
    }

    function acceptOffers(uint8 ticketID) external onlyTicketOwner(ticketID) {
        address sender = msg.sender;
        uint256 gameID = currentGameID;
        Offer memory O = offer[gameID][ticketID];
        (Status stat, , , bytes memory tickets) = getLatestUpdate();

        _onlyInProgressMode(stat);
        _onlyWinnerTicket(tickets, ticketID);
        if (O.amount == 0) revert OFFER_NOT_FOUND();

        delete offer[gameID][ticketID];

        unchecked {
            offerorData[O.maker].latestGameIDoffersValue -= O.amount;
            offerorData[O.maker].totalOffersValue -= O.amount;
            totalPlayerTickets[gameID][sender]--;
            totalPlayerTickets[gameID][O.maker]++;
        }

        ticketOwnership[gameID][ticketID] = O.maker;

        _transferFromHelper(TREASURY, THIS, O.amount);
        _transferHelper(sender, (O.amount * OFFEREE_BENEFICIARY) / BASIS);

        emit OfferAccepted(
            O.maker,
            ticketID,
            (O.amount * OFFEREE_BENEFICIARY) / BASIS,
            sender
        );
    }

    function takeBackStaleOffers(address to) external {
        address sender = msg.sender;
        if (to == address(0)) to = sender;

        uint256 refundableAmount = _getStaleOfferorAmount(sender);

        if (refundableAmount == 0) revert NO_AMOUNT_TO_REFUND();

        offerorData[sender].totalOffersValue -= refundableAmount;

        _transferFromHelper(TREASURY, to, refundableAmount);

        emit StaleOffersTookBack(sender, to, refundableAmount);
    }

    /******************************\
    |-*-*-*-*-*   VIEW   *-*-*-*-*-|
    \******************************/
    function currentTicketValue() external view returns (uint256) {
        (, , , bytes memory tickets) = getLatestUpdate();
        return _currentTicketValue(tickets.length);
    }

    function currentWinnersWithTickets()
        external
        view
        returns (int256 eligibleWithdrawals, TicketInfo[] memory)
    {
        uint256 gameID = currentGameID;
        (
            Status stat,
            int256 _eligibleWithdrawals,
            ,
            bytes memory tickets
        ) = getLatestUpdate();

        _onlyInProgressMode(stat);

        TicketInfo[] memory allTicketsData = new TicketInfo[](tickets.length);
        uint256 index;

        while (index != tickets.length) {
            allTicketsData[index] = TicketInfo(
                uint8(tickets[index]),
                ticketOwnership[gameID][uint8(tickets[index])]
            );

            unchecked {
                index++;
            }
        }

        return (_eligibleWithdrawals, allTicketsData);
    }

    function playerWithWinningTickets(address player)
        external
        view
        returns (uint256 totalTicketsValue, bytes memory playerTickets)
    {
        if (player == address(0)) player = msg.sender;

        uint256 gameID = currentGameID;
        uint256 totalTickets = totalPlayerTickets[gameID][player];
        (Status stat, , , bytes memory tickets) = getLatestUpdate();
        uint8 latestIndex = uint8(tickets.length - 1);

        _onlyInProgressMode(stat);
        if (totalTickets == 0) revert PLAYER_HAS_NO_TICKETS();

        while (totalTickets != 0) {
            if (
                ticketOwnership[gameID][uint8(tickets[latestIndex])] == player
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

            if (latestIndex == 0) break;

            unchecked {
                latestIndex--;
            }
        }

        totalTicketsValue *= _currentTicketValue(tickets.length);
    }

    function getStaleOfferorAmount(address offeror)
        external
        view
        returns (uint256)
    {
        return _getStaleOfferorAmount(offeror);
    }

    function returnBytedCalldataArray(
        bytes calldata array,
        uint256 from,
        uint256 to
    ) external pure returns (bytes memory) {
        return array[from:to];
    }

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

        if (GD.startedBlock == 0)
            stat = GD.soldTickets != 0 ? Status.ticketSale : Status.notStarted;
        else if (GD.eligibleWithdrawals == -1) stat = Status.finished;
        else {
            bool fugaziBool;
            stat = Status.inProgress;

            uint256 currentBlock = block.number;
            uint256 lastUpdatedWave = GD.updatedWave == 0
                ? 1
                : GD.updatedWave + 1;

            while (
                GD.startedBlock + (lastUpdatedWave * WAVE_DURATION) <
                currentBlock
            ) {
                tickets = _bytedArrayShuffler(
                    tickets,
                    _getRandomSeed(
                        GD.startedBlock + (lastUpdatedWave * WAVE_DURATION)
                    ),
                    tickets.length / 2
                );

                unchecked {
                    lastUpdatedWave++;
                    currentWave++;
                    eligibleWithdrawals = int256(tickets.length / 2);
                }

                if (eligibleWithdrawals < 2) {
                    if (fugaziBool) break;
                    eligibleWithdrawals = 1;
                    fugaziBool = true;
                }
            }
        }
    }

    /*****************************\
    |-*-*-*-*   PRIVATE   *-*-*-*-|
    \*****************************/
    function _transferHelper(address to, uint256 amount) private {
        USDT.transfer(to, amount);
    }

    function _transferFromHelper(
        address from,
        address to,
        uint256 amount
    ) private {
        USDT.transferFrom(from, to, amount);
    }

    function _getStaleOfferorAmount(address offeror)
        private
        view
        returns (uint256)
    {
        if (offerorData[offeror].latestGameID == currentGameID)
            return (offerorData[offeror].totalOffersValue -
                offerorData[offeror].latestGameIDoffersValue);
        return (offerorData[offeror].totalOffersValue);
    }

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
                    (i + 1);
                (array[i], array[j]) = (array[j], array[i]);
                i++;
            }
        }

        return this.returnBytedCalldataArray(array, 0, to);
    }

    function _deleteOneIndex(uint8 index, bytes memory bytesArray)
        private
        view
        returns (bytes memory)
    {
        return
            index != (bytesArray.length - 1)
                ? abi.encodePacked(
                    this.returnBytedCalldataArray(bytesArray, 0, index),
                    this.returnBytedCalldataArray(
                        bytesArray,
                        index + 1,
                        bytesArray.length
                    )
                )
                : this.returnBytedCalldataArray(bytesArray, 0, index);
    }

    function _currentTicketValue(uint256 totalTickets)
        private
        view
        returns (uint256)
    {
        if (totalTickets == 0) return 0;
        return USDT.balanceOf(THIS) / totalTickets;
    }

    function _getRandomSeed(uint256 startBlock) private view returns (uint256) {
        uint256 b = WAVE_DURATION;
        uint256 index = 20;

        uint256[] memory parts = new uint256[](5);
        uint256[] memory blockHashes = new uint256[](21);

        while (blockHashes[0] == 0) {
            blockHashes[index] = uint256(blockhash(startBlock - b));

            if (index == 0) break;
            else {
                unchecked {
                    index--;
                    b--;
                }
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
            parts[3] = (parts[4] / 2) + (parts[2] / 2);
            return uint256(keccak256(abi.encodePacked(parts[1] * parts[3])));
        }
    }

    function _linearSearch(bytes memory tickets, uint8 ticketID)
        private
        pure
        returns (bool, uint8)
    {
        for (uint256 i = tickets.length - 1; i >= 0; ) {
            if (uint8(tickets[i]) == ticketID) {
                return (true, uint8(i));
            }

            unchecked {
                i--;
            }
        }
        return (false, 0);
    }

    function _checkMTPG(uint8 value) private pure {
        _revertOnZeroUint(value);
        if (value > MAX_TICKETS_PER_GAME)
            revert VALUE_CANT_BE_GREATER_THAN(MAX_TICKETS_PER_GAME);
    }

    function _checkTP(uint80 value) private pure {
        if (value < MIN_TICKET_PRICE)
            revert VALUE_CANT_BE_LOWER_THAN(MIN_TICKET_PRICE);
        if (value > MAX_TICKET_PRICE)
            revert VALUE_CANT_BE_GREATER_THAN(MAX_TICKET_PRICE);
    }

    function _revertOnZeroUint(uint256 uInt) private pure {
        if (uInt == 0) revert ZERO_UINT_PROVIDED();
    }

    function _onlyInProgressMode(Status stat) private pure {
        if (stat != Status.inProgress) revert ONLY_IN_PROGRESS_MODE(stat);
    }

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