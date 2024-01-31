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
        uint8 soldTickets;
        uint8 lastUpdatedWave;
        uint8 eligibleWaveWithdrawns;
        uint224 startedBlockNo;
        bytes BYTES256;
    }

    /********************************\
    |-*-*-*-*-*   STATES   *-*-*-*-*-|
    \********************************/

    bool private _pausy;
    uint8 private _maxTicketsPerGame;
    uint48 private _currentGameID;
    uint64 private _neededUSDC;
    uint16[8] private _octalWavesDurations;

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
        uint8[] ticketIds
    );
    event GameFinished(
        uint256 indexed gameId,
        address indexed winner,
        uint256 indexed amount,
        uint8 ticketId
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
            gameConfig[_currentGameID].BYTES256.length == 1 && _pausy == true,
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
        uint8 maxTicketsPerGame_,
        uint64 neededUSDC_,
        uint16[8] memory octalWavesDurations_
    ) {
        require(
            usdc_ != address(0) && admin_ != address(0),
            "ZERO_ADDRESS_PROVIDED"
        );
        require(
            maxTicketsPerGame_ != 0 && neededUSDC_ != 0,
            "ZERO_UINT_PROVIDED"
        );
        _onlyPow2(maxTicketsPerGame_);

        _setOctalWavesDurations(octalWavesDurations_);

        USDC = IUSDC(usdc_);
        ADMIN = admin_;
        _maxTicketsPerGame = maxTicketsPerGame_;
        _neededUSDC = neededUSDC_;
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
        require(maxTicketsPerGame_ != 0, "ZERO_UINT_PROVIDED");
        _onlyPow2(maxTicketsPerGame_);

        _maxTicketsPerGame = maxTicketsPerGame_;
    }

    function changeNeededUSDC(uint64 neededUSDC_)
        external
        onlyAdmin
        onlyPaused
    {
        require(neededUSDC_ != 0, "ZERO_UINT_PROVIDED");

        _neededUSDC = neededUSDC_;
    }

    function changeOctalWavesDurations(uint16[8] calldata octalWavesDurations_)
        external
        onlyAdmin
        onlyPaused
    {
        _setOctalWavesDurations(octalWavesDurations_);
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

        if (gameConfig[gameId].BYTES256.length == 1 || gameId == 0) {
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
        require(GD.startedBlockNo == 0, "WAIT_FOR_NEXT_MATCH");
        require(
            totalTickets + totalPlayerTickets[gameId][sender] < ticketLimit,
            "PARTICIPATED_BEFORE"
        );
        require(totalTickets < remainingTickets, "OUT_OF_REMAINED_TICKETS");
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
            GD.BYTES256 = BYTES256;
            uint256 blockNo = block.number;
            GD.startedBlockNo = uint224(blockNo);
            emit GameStarted(gameId, blockNo, MAX_PARTIES * neededUSDC);
        }
    }

    // 256
    // wave 1: 128 => 64
    // wave 2: 32 => 16
    // wave 3: 8 => 4
    // wave 4: 2 => 1

    // function receiveLotteryWagedPrize(uint8[] memory ticketIds, uint8[] memory indexes)
    //     external
    // {
    //     address sender = msg.sender;
    //     uint256 gameId = _currentGameID;
    //     uint256 balance = USDC.balanceOf(address(this));
    //     uint256 length = ticketIds.length;

    //     require(indexes.length == length, "MISMATCHED_ARRAYS_LENGHS");

    //     if (currentWave == 8) {
    //         require(currentWave - lastChangedWave != 0, "CLAIMED_BEFORE");
    //         require(
    //             ticketOwnership[gameId][uint8(bytes1(GD.BYTES256))] == sender,
    //             "OWNERSHIP_REQUESTED"
    //         );

    //         gameConfig[gameId].BYTES256 = GD.BYTES256;

    //         uint256 winnerAmount = balance - ((balance * FEE) / BASIS);

    //         USDC.transfer(ADMIN, balance - winnerAmount);
    //         USDC.transfer(sender, winnerAmount);

    //         emit GameFinished(
    //             gameId,
    //             sender,
    //             winnerAmount,
    //             uint8(bytes1(GD.BYTES256))
    //         );
    //         return;
    //     }

    //     require(length != 0, "PROVIDE_TICKET-IDS_WITH_INDEXES");

    //     emit GameUpdated(gameId, sender, length * _neededUSDC, ticketIds);
    // }

    /******************************\
    |-*-*-*-*-*   VIEW   *-*-*-*-*-|
    \******************************/

    function getLatestUpdate()
        external
        view
        returns (
            Status,
            uint256,
            uint256,
            bytes memory
        )
    {
        uint256 gameId = _currentGameID;
        GameData memory GD = gameConfig[gameId];

        if (GD.startedBlockNo == 0 || GD.BYTES256.length == 1)
            return (
                GD.startedBlockNo == 0 ? Status.notStarted : Status.finished,
                0,
                GD.lastUpdatedWave,
                GD.BYTES256
            );

        uint256 currentWave;
        uint256 eligibleWaveWithdrawns = GD.eligibleWaveWithdrawns;
        uint256 blockNo = block.number;
        uint16[8] memory octalWavesDurations_ = _octalWavesDurations;

        for (uint256 i = GD.lastUpdatedWave; i < 8; ) {
            if (
                (blockNo + octalWavesDurations_[i] <
                    GD.startedBlockNo + octalWavesDurations_[i])
            ) break;
            else {
                unchecked {
                    blockNo += octalWavesDurations_[i];
                    currentWave++;
                }
            }

            eligibleWaveWithdrawns;

            unchecked {
                i++;
            }
        }

        return (
            Status.inProcess,
            eligibleWaveWithdrawns,
            currentWave,
            GD.BYTES256
        );
    }

    //! INCORRECT => USING LOGICS FOR UPPER FUNCTION!
    function getCurrentGameStatus()
        public
        view
        returns (
            GameData memory GD,
            uint256 currentWave,
            uint256 lastChangedWave
        )
    {
        GD = gameConfig[_currentGameID];

        if (GD.startedBlockNo != 0) {
            uint256 _lastChangedWave;
            uint256 timeStamp = block.number;
            uint16[8] memory octalWavesDurations_ = _octalWavesDurations;

            if (GD.BYTES256.length != 1) {
                for (uint256 i; i < 8; ) {
                    if (
                        (timeStamp + octalWavesDurations_[i] <
                            GD.startedBlockNo + octalWavesDurations_[i])
                    ) break;
                    unchecked {
                        timeStamp += octalWavesDurations_[i];
                        currentWave++;
                        i++;
                    }
                }

                lastChangedWave = _lastChangedWave;

                if (currentWave - _lastChangedWave != 0) {
                    uint256 to;
                    uint256 randomSeed;
                    uint256 maxWinners = GD.BYTES256.length;
                    uint256 totalScopes = currentWave - _lastChangedWave;

                    while (totalScopes != 0) {
                        _lastChangedWave++;
                        if (maxWinners > 3) to = maxWinners / 2;
                        else if (maxWinners != 1) to = 1;
                        else break;
                        randomSeed = _getRandomSeed(
                            block.number +
                                octalWavesDurations_[_lastChangedWave]
                        );
                        GD.BYTES256 = _bytedArrayShuffler(
                            GD.BYTES256,
                            randomSeed,
                            to
                        );
                        unchecked {
                            maxWinners /= 2;
                            totalScopes--;
                        }
                    }
                }
            }
        }
    }

    /*****************************\
    |-*-*-*-*   PRIVATE   *-*-*-*-|
    \*****************************/

    function _setOctalWavesDurations(uint16[8] memory octalWavesDurations_)
        private
    {
        for (uint256 i = 6; i == 0; ) {
            require(
                !(octalWavesDurations_[i] < 100) &&
                    octalWavesDurations_[i] < octalWavesDurations_[i + 1],
                "INCORRECT_OCTAL_WAVE_VALUE"
            );

            unchecked {
                i--;
            }
        }

        _octalWavesDurations = octalWavesDurations_;
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

        return this._returnBytedCalldataArray(_array, 0, _to);
    }

    function _deleteOneIndex(uint8 _index, bytes memory _bytesArray)
        private
        view
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                this._returnBytedCalldataArray(_bytesArray, 0, _index),
                this._returnBytedCalldataArray(
                    _bytesArray,
                    _index + 1,
                    _bytesArray.length
                )
            );
    }

    function _onlyPow2(uint8 number) private pure {
        require((number & (number - 1)) == 0, "NOT_IN_POW2");
    }

    function _returnBytedCalldataArray(
        bytes calldata _array,
        uint256 _from,
        uint256 _to
    ) external pure returns (bytes memory) {
        return _array[_from:_to];
    }

    function _getRandomSeed(uint256 startBlock) public view returns (uint256) {
        require(!(startBlock > block.number), "WAITING_FOR_NEXT_WAVE");

        uint256 b = 100;
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
}
