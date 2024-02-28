//  SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC20} from "./interface/IERC20.sol";
import {Test, console2} from "forge-std/Test.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {C2Treasury} from "../contracts/C2Treasury.sol";
import "../contracts/Come2Top.sol";

contract GameLogicTest is Test {
    using console2 for *;
    using Strings for uint256;

    Come2Top private GAME;
    address[] private TICKET_BUYERS;
    address private ADMIN = makeAddr("ADMIN");

    address private constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    uint256 WAVE_DURATION = 93;
    uint8 private constant MAX_TICKET_PER_GAME = 1;
    uint80 private constant TICKET_PRICE = 1e6;
    uint256 private constant MAX_PLAYERS = 256;
    uint256 private constant MAX_UINT256 = type(uint256).max;

    function setUp() external {
        vm.createSelectFork("https://polygon.drpc.org", 53600000);

        address treasury = address(new C2Treasury());

        GAME = new Come2Top(MAX_TICKET_PER_GAME, TICKET_PRICE, USDT, treasury);

        while (TICKET_BUYERS.length != MAX_PLAYERS) {
            TICKET_BUYERS.push(
                makeAddr(
                    string(
                        abi.encodePacked(
                            "TICKET_BUYER_",
                            (TICKET_BUYERS.length).toString()
                        )
                    )
                )
            );

            deal(USDT, TICKET_BUYERS[TICKET_BUYERS.length - 1], 1e6);
            vm.prank(TICKET_BUYERS[TICKET_BUYERS.length - 1]);
            IERC20(USDT).approve(address(GAME), MAX_UINT256);
        }

        console2.log("C2Treasury Deployed at:             ", treasury);
        console2.log("Game deployed at:                   ", address(GAME));
        console2.log(
            "Full allowance (C2Treasury => Game):",
            IERC20(USDT).allowance(treasury, address(GAME)) == MAX_UINT256
        );
        console2.log("***********************************");
        console2.log("*         Setup completed         *");
        console2.log("***********************************");
    }

    function test() external {
        uint256 i = MAX_PLAYERS;
        uint8[] memory ticketToBuy = new uint8[](1);
        while (i != 0) {
            vm.prank(TICKET_BUYERS[i - 1], TICKET_BUYERS[i - 1]);
            ticketToBuy[0] = uint8(MAX_PLAYERS - i);
            GAME.joinGame(ticketToBuy);

            i--;
        }

        vm.roll(block.number + WAVE_DURATION * 3 + 1);

        uint8 ticketID;

        (
            Come2Top.Status stat,
            int256 eligibleWithdrawals,
            ,
            bytes memory tickets
        ) = GAME.getLatestUpdate();

        string memory stringifiedStatus;

        if (stat == Come2Top.Status.notStarted)
            stringifiedStatus = "Not Started!";
        else if (stat == Come2Top.Status.ticketSale)
            stringifiedStatus = "Ticket Saling Mode $";
        else if (stat == Come2Top.Status.inProgress)
            stringifiedStatus = "In Progress...";
        else stringifiedStatus = "Finished.";

        uint256 ticketValue = GAME.currentTicketValue();

        address ticketOwnerOfIndex1 = GAME.ticketOwnership(
            0,
            uint8(tickets[0])
        );
        address ticketOwnerOfLastIndex = GAME.ticketOwnership(
            0,
            uint8(tickets[tickets.length - 1])
        );

        uint256 balanceOfTOI1 = IUSDT(USDT).balanceOf(ticketOwnerOfIndex1);
        uint256 balanceOfTOLI = IUSDT(USDT).balanceOf(ticketOwnerOfLastIndex);

        ticketID = uint8(tickets[0]);
        vm.prank(ticketOwnerOfIndex1);
        GAME.receiveLotteryWagedPrize(ticketID);

        (
            ,
            int256 eligibleWithdrawals_1stTx,
            ,
            bytes memory tickets_1stTx
        ) = GAME.getLatestUpdate();

        uint256 ticketValue_1stTx = GAME.currentTicketValue();

        ticketID = uint8(tickets_1stTx[tickets_1stTx.length - 1]);
        vm.prank(ticketOwnerOfLastIndex);
        GAME.receiveLotteryWagedPrize(ticketID);

        (
            ,
            int256 eligibleWithdrawals_2ndTx,
            ,
            bytes memory tickets_2ndTx
        ) = GAME.getLatestUpdate();

        uint256 ticketValue_2ndTx = GAME.currentTicketValue();

        vm.roll(block.number + WAVE_DURATION);

        (
            ,
            int256 eligibleWithdrawalsNextWave,
            uint256 currentWave,
            bytes memory ticketsNextWave
        ) = GAME.getLatestUpdate();

        uint256 ticketValueNextWave = GAME.currentTicketValue();

        "____________________________________".log();
        console2.log("Status:            ", stringifiedStatus);
        console2.log("Current wave:      ", currentWave);
        console2.log(
            "Game USDC balance: ",
            IUSDT(USDT).balanceOf(address(GAME))
        );
        console2.log(
            "Admin USDC balance:",
            IUSDT(USDT).balanceOf(GAME.ADMIN())
        );

        "".log();
        console2.log(
            "Ticket value before any withdraws:        ",
            ticketValue
        );
        console2.log(
            "Ticket value after 1st withdraw:          ",
            ticketValue_1stTx
        );
        console2.log(
            "Ticket value after 2nd withdraw:          ",
            ticketValue_2ndTx
        );
        console2.log(
            "Ticket value of the next wave:            ",
            ticketValueNextWave
        );

        "".log();
        console2.log(
            "Withdrawer 1 balance before withdraw:     ",
            balanceOfTOI1
        );
        console2.log(
            "Withdrawer 1 balance after withdraw:      ",
            IUSDT(USDT).balanceOf(ticketOwnerOfIndex1)
        );
        console2.log(
            "Withdrawer 2 balance before withdraw:     ",
            balanceOfTOLI
        );
        console2.log(
            "Withdrawer 2 balance after withdraw:      ",
            IUSDT(USDT).balanceOf(ticketOwnerOfLastIndex)
        );

        "".log();
        console2.log(
            "Eligible withdrawals before any withdraws:",
            uint256(eligibleWithdrawals)
        );
        console2.log(
            "Eligible withdrawals after 1st withdraw:  ",
            uint256(eligibleWithdrawals_1stTx)
        );
        console2.log(
            "Eligible withdrawals after 2nd withdraw:  ",
            uint256(eligibleWithdrawals_2ndTx)
        );
        console2.log(
            "Eligible withdrawals of the next wave:    ",
            uint256(eligibleWithdrawalsNextWave)
        );

        "".log();
        console2.log("Tickets before any withdraws:");
        tickets.logBytes();
        console2.log("Tickets after 1st withdraw:");
        tickets_1stTx.logBytes();
        console2.log("Tickets after 2nd withdraw:");
        tickets_2ndTx.logBytes();
        console2.log("Tickets of the next wave:");
        ticketsNextWave.logBytes();
        "____________________________________".log();
    }
}
