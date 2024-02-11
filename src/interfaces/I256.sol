// SPDX-License-Identifier: --256--
pragma solidity 0.8.18;

interface I256 {
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

    function joinGame(uint8[] calldata ticketIDs) external;

    function receiveLotteryWagedPrize(uint8[] calldata indexes) external;

    function transferTicketOwnership(uint8 ticketID, address newOwner)
        external;

    function pause() external view returns (bool);

    function maxTicketsPerGame() external view returns (uint8);

    function ticketPrice() external view returns (uint80);

    function currentGameID() external view returns (uint160);

    function gameData(uint256 gameId)
        external
        view
        returns (
            int8 eligibleWithdrawals,
            uint8 soldTickets,
            uint8 updatedWave,
            uint216 startedBlock,
            bytes memory tickets
        );

    function ticketOwnership(uint256 gameID, uint8 ticketID)
        external
        view
        returns (address);

    function totalPlayerTickets(uint256 gameID, address owner)
        external
        view
        returns (uint8);

    function getLatestUpdate()
        external
        view
        returns (
            Status stat,
            int256 eligibleWithdrawals,
            uint256 currentWave,
            bytes memory tickets
        );

    function returnBytedCalldataArray(
        bytes calldata array,
        uint256 from,
        uint256 to
    ) external pure returns (bytes memory);
}
