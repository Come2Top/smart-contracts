/************************************************************************\
                         █▀▀ █   ▄▀█ █▀ █▀ █ █▀▀
                         █▄▄ █▄▄ █▀█ ▄█ ▄█ █ █▄▄
                                                          + ꓕ$ՈꓭOꓤ
                      █▀█  ▄▀█  █▄ █  █▀▄  █▀█  █▀▄▀█     + 🆂🅴🅲🆄🆁🅴
                      █▀▄  █▀█  █ ▀█  █▄▀  █▄█  █ ▀ █     + 🇦​​​​​🇺​​​​​🇹​​​​​⌖​​​​​🇲​​​​​🇦​​​​​🇹​​​​​🇪​​​​​🇩​​​​​

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
 ░░░░██████████████|    |  .  |█|    |  |--.████/    /  /████████████░░░░
 ░░░███████████████|    |.'  /██|    |  |.' \██/    /  /██████████████░░░
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
\************************************************************************/

// SPDX-License-Identifier: AGPL-v3
pragma solidity 0.8.18;

import {IUSDC} from "./interfaces/IUSDC.sol";

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
        int8 eligibleWaveWithdrawns;
        uint8 soldTickets;
        uint8 updatedWave;
        uint216 startedBN;
        bytes tickets;
    }

    /********************************\
    |-*-*-*-*-*   STATES   *-*-*-*-*-|
    \********************************/

    bool private _pausy;
    uint8 private _maxTicketsPerGame;
    uint80 private _neededUSDC;
    uint160 private _currentGameID;

    mapping(uint256 => GameData) private _gameConfig;
    mapping(uint256 => mapping(uint256 => address)) private _ticketOwnership;
    mapping(uint256 => mapping(address => uint256)) private _totalPlayerTickets;

    /*******************************\
    |-*-*-*-*   CONSTANTS   *-*-*-*-|
    \*******************************/

    IUSDC private immutable _usdc;
    address private immutable _admin;
    uint256 private constant _FEE = 23438;
    uint256 private constant _BASIS = 1000000;
    uint256 private constant _WAVE_DURATION = 80;
    uint256 private constant _MAX_PARTIES = 256;
    bytes private constant _TICKET256 =
        hex"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff";

    /********************************\
    |-*-*-*-*-*   EVENTS   *-*-*-*-*-|
    \********************************/

    event GameStarted(
        uint256 indexed gameId,
        uint256 indexed startedBlockNo,
        uint256 indexed prizeAmount
    );
    event GameUpdated(
        uint256 indexed gameId,
        address indexed winner,
        uint256 indexed amount,
        uint256[] ticketIds
    );
    event GameFinished(
        uint256 indexed gameId,
        address indexed winner,
        uint256 indexed amount,
        uint256 ticketId
    );

    event GameFinished(
        uint256 indexed gameId,
        address[2] winners,
        uint256[2] amounts,
        uint256[2] ticketIds
    );

    /*******************************\
    |-*-*-*-*   MODIFIERS   *-*-*-*-|
    \*******************************/

    modifier onlyAdmin() {
        require(msg.sender == _admin, "ONLY_ADMIN_FUNCTION");
        _;
    }

    modifier onlyPaused() {
        require(
            _gameConfig[_currentGameID].eligibleWaveWithdrawns == -1 &&
                _pausy == true,
            "ONLY_PAUSED"
        );

        require(_pausy == true, "ONLY_PAUSED");
        _;
    }

    /******************************\
    |-*-*-*-*   BUILT-IN   *-*-*-*-|
    \******************************/

    constructor(
        address usdc_,
        address admin_,
        uint8 mtpg_,
        uint80 neededUSDC_
    ) {
        require(
            usdc_ != address(0) && admin_ != address(0),
            "ZERO_ADDRESS_PROVIDED"
        );
        require(mtpg_ != 0 && neededUSDC_ != 0, "ZERO_UINT_PROVIDED");
        _onlyPow2(mtpg_);

        _usdc = IUSDC(usdc_);
        _admin = admin_;
        _maxTicketsPerGame = mtpg_;
        _neededUSDC = neededUSDC_;

        _gameConfig[0].tickets = _TICKET256;
    }

    /*******************************\
    |-*-*-*   ADMINSTRATION   *-*-*-|
    \*******************************/

    function togglePausy() external onlyAdmin {
        _pausy = !_pausy;
    }

    function changeMTPG(uint8 maxTicketsPerGame_)
        external
        onlyAdmin
        onlyPaused
    {
        _revertOnZeroUint(maxTicketsPerGame_);
        _onlyPow2(maxTicketsPerGame_);

        _maxTicketsPerGame = maxTicketsPerGame_;
    }

    function changeNeededUSDC(uint80 neededUSDC_)
        external
        onlyAdmin
        onlyPaused
    {
        _revertOnZeroUint(neededUSDC_);

        _neededUSDC = neededUSDC_;
    }

    /******************************\
    |-*-*-*-*-*   GAME   *-*-*-*-*-|
    \******************************/

    function joinGame(uint8[] calldata ticketIDs) external {
        GameData storage gameData;
        address sender = msg.sender;
        uint256 gameId = _currentGameID;
        uint256 ticketLimit = _maxTicketsPerGame + 1;
        uint256 neededUSDC = _neededUSDC;
        uint256 totalTickets = ticketIDs.length;

        if (_gameConfig[gameId].eligibleWaveWithdrawns == -1) {
            unchecked {
                gameId++;
                _currentGameID++;
            }
            gameData = _gameConfig[gameId];
            gameData.tickets = _TICKET256;
        } else gameData = _gameConfig[gameId];

        uint256 remainingTickets = _MAX_PARTIES - gameData.soldTickets;
        bytes memory tickets = gameData.tickets;

        require(_pausy == false || gameData.soldTickets != 0, "ONLY_UNPAUSED");
        require(
            totalTickets != 0 && totalTickets < ticketLimit,
            "CHECK_TICKETS_ARRAY"
        );
        require(gameData.startedBN == 0, "WAIT_FOR_NEXT_MATCH");
        require(
            totalTickets + _totalPlayerTickets[gameId][sender] < ticketLimit,
            "PARTICIPATED_BEFORE"
        );
        require(totalTickets < remainingTickets, "OUT_OF_TICKETS");
        require(
            !(_usdc.allowance(sender, address(this)) <
                (totalTickets * neededUSDC)),
            "APPROVE_NEEDED"
        );

        for (uint256 i; i < totalTickets; ) {
            if (ticketIDs[i] == 0) {
                require(tickets[0] != 0xff, "TICKET_RESERVED");
                tickets[0] = 0xff;
            } else {
                require(tickets[ticketIDs[i]] != 0x00, "TICKET_RESERVED");
                tickets[ticketIDs[i]] = 0x00;
            }

            unchecked {
                _ticketOwnership[gameId][ticketIDs[i]] = sender;
                i++;
            }
        }
        _totalPlayerTickets[gameId][sender] += totalTickets;

        _usdc.transferFrom(sender, address(this), (totalTickets * neededUSDC));

        gameData.tickets = tickets;

        if (totalTickets == remainingTickets) {
            uint256 blockNo = block.number;
            gameData.startedBN = uint216(blockNo);
            gameData.tickets = _TICKET256;
            emit GameStarted(gameId, blockNo, _MAX_PARTIES * neededUSDC);
        }
    }

    function receiveLotteryWagedPrize(uint8[] memory indexes) external {
        uint256 fee;
        address sender = msg.sender;
        uint256 gameId = _currentGameID;
        uint256 balance = _usdc.balanceOf(address(this));
        uint256 length = indexes.length;

        (
            Status stat,
            int256 eligibleWaveWithdrawns,
            uint256 currentWave,
            bytes memory tickets
        ) = getLatestUpdate();

        require(length != 0, "PROVIDE_INDEXES");
        require(stat != Status.notStarted, "NOT_STARTED");
        require(currentWave != 0, "WAIT_FOR_WAVE_1");
        require(eligibleWaveWithdrawns != 0, "NOT_ELIGIBLE");
        require(stat != Status.finished, "FINISHED");
        require(
            length <= uint256(eligibleWaveWithdrawns),
            "OUT_OF_ELIGIBLE_WITHDRAWNS"
        );

        if (tickets.length < 3) {
            fee = (balance * _FEE) / _BASIS;

            _gameConfig[gameId].tickets = tickets;
            _gameConfig[gameId].eligibleWaveWithdrawns = -1;

            _usdc.transfer(_admin, fee);

            if (tickets.length == 1) {
                address ticketOwner = _ticketOwnership[gameId][
                    uint8(tickets[0])
                ];

                _usdc.transfer(ticketOwner, balance - fee);

                emit GameFinished(
                    gameId,
                    ticketOwner,
                    balance - fee,
                    uint8(tickets[0])
                );
            } else {
                require(
                    _ticketOwnership[gameId][uint8(tickets[indexes[0]])] ==
                        sender,
                    "OWNERSHIP_REQUESTED"
                );

                address winner1 = _ticketOwnership[gameId][uint8(tickets[0])];
                address winner2 = _ticketOwnership[gameId][uint8(tickets[1])];
                uint256 winner2Amount = (balance - fee) / 2;
                uint256 winner1Amount = balance - fee - winner2Amount;

                _usdc.transfer(winner1, winner1Amount);
                _usdc.transfer(winner2, winner2Amount);

                emit GameFinished(
                    gameId,
                    [winner1, winner2],
                    [winner1Amount, winner2Amount],
                    [uint256(uint8(tickets[0])), uint256(uint8(tickets[1]))]
                );
            }
        } else {
            bytes memory updatedTickets;
            uint256[] memory ticketIds = new uint256[](length);

            require(
                _ticketOwnership[gameId][uint8(tickets[indexes[0]])] == sender,
                "OWNERSHIP_REQUESTED"
            );
            require(indexes[0] < tickets.length, "INDEX_OUT_OF_BOUNDS");
            if (length == 1) {
                ticketIds[0] = uint8(tickets[indexes[0]]);

                updatedTickets = _deleteOneIndex(indexes[0], tickets);
            } else {
                updatedTickets = this.returnBytedCalldataArray(
                    tickets,
                    0,
                    indexes[0]
                );
                ticketIds[0] = uint8(tickets[indexes[0]]);
                for (uint256 i = 1; i < length; ) {
                    require(
                        indexes[i] > indexes[i - 1],
                        "NOT_ORDERIZE_INDEXES"
                    );
                    require(indexes[i] < tickets.length, "INDEX_OUT_OF_BOUNDS");
                    require(
                        _ticketOwnership[gameId][uint8(tickets[indexes[i]])] ==
                            sender,
                        "OWNERSHIP_REQUESTED"
                    );

                    ticketIds[i] = uint8(tickets[indexes[i]]);

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

            _usdc.transfer(sender, idealWinnerPrize - fee);
            _usdc.transfer(_admin, fee);

            unchecked {
                eligibleWaveWithdrawns -= int256(length);
            }

            _gameConfig[gameId].tickets = updatedTickets;
            _gameConfig[gameId].eligibleWaveWithdrawns = int8(
                eligibleWaveWithdrawns
            );

            if (_gameConfig[gameId].updatedWave != currentWave)
                _gameConfig[gameId].updatedWave = uint8(currentWave);

            emit GameUpdated(gameId, sender, idealWinnerPrize - fee, ticketIds);
        }
    }

    /******************************\
    |-*-*-*-*-*   VIEW   *-*-*-*-*-|
    \******************************/

    function getLatestUpdate()
        public
        view
        returns (
            Status stat,
            int256 eligibleWaveWithdrawns,
            uint256 currentWave,
            bytes memory tickets
        )
    {
        uint256 gameId = _currentGameID;
        GameData memory gameData = _gameConfig[gameId];

        eligibleWaveWithdrawns = gameData.eligibleWaveWithdrawns;
        currentWave = gameData.updatedWave;
        tickets = gameData.tickets;

        if (gameData.startedBN == 0 || gameData.eligibleWaveWithdrawns == -1)
            stat = gameData.startedBN == 0 ? Status.notStarted : Status.finished;
        else {
            stat = Status.inProcess;

            uint256 randomSeed;
            uint256 bn = block.number;
            uint256 lastWave = gameData.updatedWave == 0 ? 1 : gameData.updatedWave + 1;

            while ((lastWave * _WAVE_DURATION) + gameData.startedBN < bn) {
                randomSeed = _getRandomSeed(bn + (lastWave * _WAVE_DURATION));
                tickets = _bytedArrayShuffler(
                    tickets,
                    randomSeed,
                    tickets.length / 2
                );

                unchecked {
                    lastWave++;
                    eligibleWaveWithdrawns = int256(tickets.length / 2);
                }

                if (eligibleWaveWithdrawns < 2) {
                    eligibleWaveWithdrawns = 1;
                    break;
                }
            }
        }
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

    function _getRandomSeed(uint256 startBlock) private view returns (uint256) {
        require(!(startBlock > block.number), "WAITING_FOR_NEXT_WAVE");

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

    function _onlyPow2(uint8 number) private pure {
        require((number & (number - 1)) == 0, "NOT_IN_POW2");
    }

    function _revertOnZeroUint(uint256 integer) private pure {
        require(integer != 0, "ZERO_UINT_PROVIDED");
    }
}
