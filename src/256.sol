// SPDX-License-Identifier: AGPL-v3
pragma solidity 0.8.18;

import {IUSDC} from "./interfaces/IUSDC.sol";

contract $256$ {
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
        bytes BYTES256;
    }

    /********************************\
    |-*-*-*-*-*   STATES   *-*-*-*-*-|
    \********************************/

    bool private _pausy;
    uint8 private _maxTicketsPerGame;
    uint80 private _neededUSDC;
    uint160 private _currentGameID;

    mapping(uint256 => GameData) private gameConfig;
    mapping(uint256 => mapping(uint256 => address)) private ticketOwnership;
    mapping(uint256 => mapping(address => uint256)) private totalPlayerTickets;

    /*******************************\
    |-*-*-*-*   CONSTANTS   *-*-*-*-|
    \*******************************/

    IUSDC private immutable USDC;
    address private immutable ADMIN;
    uint256 private constant FEE = 23438;
    uint256 private constant BASIS = 1000000;
    uint256 private constant WAVE_DURATION = 80;
    uint256 private constant MAX_PARTIES = 256;
    bytes private constant BYTES256 =
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
        require(msg.sender == ADMIN, "ONLY_ADMIN_FUNCTION");
        _;
    }

    modifier onlyPaused() {
        require(
            gameConfig[_currentGameID].eligibleWaveWithdrawns == -1 &&
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

        USDC = IUSDC(usdc_);
        ADMIN = admin_;
        _maxTicketsPerGame = mtpg_;
        _neededUSDC = neededUSDC_;

        gameConfig[0].BYTES256 = BYTES256;
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
        GameData storage GD;
        address sender = msg.sender;
        uint256 gameId = _currentGameID;
        uint256 ticketLimit = _maxTicketsPerGame + 1;
        uint256 neededUSDC = _neededUSDC;
        uint256 totalTickets = ticketIDs.length;

        if (gameConfig[gameId].eligibleWaveWithdrawns == -1) {
            unchecked {
                gameId++;
                _currentGameID++;
            }
            GD = gameConfig[gameId];
            GD.BYTES256 = BYTES256;
        } else GD = gameConfig[gameId];

        uint256 remainingTickets = MAX_PARTIES - GD.soldTickets;
        bytes memory GDB = GD.BYTES256;

        require(_pausy == false || GD.soldTickets != 0, "ONLY_UNPAUSED");
        require(
            totalTickets != 0 && totalTickets < ticketLimit,
            "CHECK_TICKETS_ARRAY"
        );
        require(GD.startedBN == 0, "WAIT_FOR_NEXT_MATCH");
        require(
            totalTickets + totalPlayerTickets[gameId][sender] < ticketLimit,
            "PARTICIPATED_BEFORE"
        );
        require(totalTickets < remainingTickets, "OUT_OF_TICKETS");
        require(
            !(USDC.allowance(sender, address(this)) <
                (totalTickets * neededUSDC)),
            "APPROVE_NEEDED"
        );

        for (uint256 i; i < totalTickets; ) {
            if (ticketIDs[i] == 0) {
                require(GDB[0] != 0xff, "TICKET_RESERVED");
                GDB[0] = 0xff;
            } else {
                require(GDB[ticketIDs[i]] != 0x00, "TICKET_RESERVED");
                GDB[ticketIDs[i]] = 0x00;
            }

            unchecked {
                ticketOwnership[gameId][ticketIDs[i]] = sender;
                i++;
            }
        }
        totalPlayerTickets[gameId][sender] += totalTickets;

        USDC.transferFrom(sender, address(this), (totalTickets * neededUSDC));

        GD.BYTES256 = GDB;

        if (totalTickets == remainingTickets) {
            uint256 blockNo = block.number;
            GD.startedBN = uint216(blockNo);
            GD.BYTES256 = BYTES256;
            GD.eligibleWaveWithdrawns = 64;
            emit GameStarted(gameId, blockNo, MAX_PARTIES * neededUSDC);
        }
    }

    function receiveLotteryWagedPrize(uint8[] memory indexes) external {
        uint256 fee;
        address sender = msg.sender;
        uint256 gameId = _currentGameID;
        uint256 balance = USDC.balanceOf(address(this));
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
            fee = (balance * FEE) / BASIS;

            gameConfig[gameId].BYTES256 = tickets;
            gameConfig[gameId].eligibleWaveWithdrawns = -1;

            USDC.transfer(ADMIN, fee);

            if (tickets.length == 1) {
                address ticketOwner = ticketOwnership[gameId][
                    uint8(tickets[0])
                ];

                USDC.transfer(ticketOwner, balance - fee);

                emit GameFinished(
                    gameId,
                    ticketOwner,
                    balance - fee,
                    uint8(tickets[0])
                );
            } else {
                require(
                    ticketOwnership[gameId][uint8(tickets[indexes[0]])] ==
                        sender,
                    "OWNERSHIP_REQUESTED"
                );

                address winner1 = ticketOwnership[gameId][uint8(tickets[0])];
                address winner2 = ticketOwnership[gameId][uint8(tickets[1])];
                uint256 winner2Amount = (balance - fee) / 2;
                uint256 winner1Amount = balance - fee - winner2Amount;

                USDC.transfer(winner1, winner1Amount);
                USDC.transfer(winner2, winner2Amount);

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
                ticketOwnership[gameId][uint8(tickets[indexes[0]])] == sender,
                "OWNERSHIP_REQUESTED"
            );
            require(indexes[0] < tickets.length, "INDEX_OUT_OF_BOUNDS");
            if (length == 1) {
                ticketIds[0] = uint8(tickets[indexes[0]]);

                updatedTickets = _deleteOneIndex(indexes[0], tickets);
            } else {
                updatedTickets = this._returnBytedCalldataArray(
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
                        ticketOwnership[gameId][uint8(tickets[indexes[i]])] ==
                            sender,
                        "OWNERSHIP_REQUESTED"
                    );

                    ticketIds[i] = uint8(tickets[indexes[i]]);

                    updatedTickets = abi.encodePacked(
                        updatedTickets,
                        this._returnBytedCalldataArray(
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
                        this._returnBytedCalldataArray(
                            tickets,
                            indexes[length - 1] + 1,
                            tickets.length
                        )
                    );
                }
            }

            uint256 idealWinnerPrize = (balance / tickets.length) * length;
            fee = (idealWinnerPrize * FEE) / BASIS;

            USDC.transfer(sender, idealWinnerPrize - fee);
            USDC.transfer(ADMIN, fee);

            unchecked {
                eligibleWaveWithdrawns -= int256(length);
            }

            gameConfig[gameId].BYTES256 = updatedTickets;
            gameConfig[gameId].eligibleWaveWithdrawns = int8(
                eligibleWaveWithdrawns
            );

            if (gameConfig[gameId].updatedWave != currentWave)
                gameConfig[gameId].updatedWave = uint8(currentWave);

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
        GameData memory GD = gameConfig[gameId];

        eligibleWaveWithdrawns = GD.eligibleWaveWithdrawns;
        currentWave = GD.updatedWave;
        tickets = GD.BYTES256;

        if (GD.startedBN == 0 || GD.eligibleWaveWithdrawns == -1)
            stat = GD.startedBN == 0 ? Status.notStarted : Status.finished;
        else {
            stat = Status.inProcess;

            uint256 bn = block.number;
            uint256 lastWave = GD.updatedWave == 0 ? 1 : GD.updatedWave;

            if ((lastWave * WAVE_DURATION) + GD.startedBN < bn) {
                // uint256 i;
                // while (true) {
                //     unchecked {}
                // }

                eligibleWaveWithdrawns = int256(tickets.length / 2);
            }
        }
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

        return this._returnBytedCalldataArray(_array, 0, _to);
    }

    function _deleteOneIndex(uint8 _index, bytes memory _bytesArray)
        private
        view
        returns (bytes memory)
    {
        return
            _index != (_bytesArray.length - 1)
                ? abi.encodePacked(
                    this._returnBytedCalldataArray(_bytesArray, 0, _index),
                    this._returnBytedCalldataArray(
                        _bytesArray,
                        _index + 1,
                        _bytesArray.length
                    )
                )
                : this._returnBytedCalldataArray(_bytesArray, 0, _index);
    }

    function _getRandomSeed(uint256 startBlock) public view returns (uint256) {
        require(!(startBlock > block.number), "WAITING_FOR_NEXT_WAVE");

        uint256 b = WAVE_DURATION;
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

    function _returnBytedCalldataArray(
        bytes calldata _array,
        uint256 _from,
        uint256 _to
    ) external pure returns (bytes memory) {
        return _array[_from:_to];
    }
}
