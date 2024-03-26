//  SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC20} from "./interface/IERC20.sol";
import {Test, console2} from "forge-std/Test.sol";
import {Treasury} from "../contracts/Treasury.sol";
import "../contracts/Come2Top.sol";

contract GameLogicTest is Test {
    using console2 for *;

    Come2Top private GAME;
    address[] private TICKET_BUYERS;
    address private ADMIN = makeAddr("ADMIN");

    address private constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    uint256 WAVE_DURATION = 71;
    uint256 WAVE_ELIGIBLE_TIME = 420;
    uint8 private constant MAX_TICKET_PER_GAME = 4;
    uint80 private constant TICKET_PRICE = 2e6;
    uint256 private constant MAX_PLAYERS = 256;
    uint256 private constant MAX_UINT256 = type(uint256).max;

    function setUp() external {
        vm.createSelectFork("https://polygon.drpc.org", 53600000);

        address treasury = address(new Treasury());

        GAME = new Come2Top(MAX_TICKET_PER_GAME, TICKET_PRICE, USDT, treasury);

        while (TICKET_BUYERS.length != MAX_PLAYERS) {
            TICKET_BUYERS.push(
                makeAddr(
                    string(
                        abi.encodePacked(
                            "TICKET_BUYER_",
                            vm.toString(TICKET_BUYERS.length)
                        )
                    )
                )
            );

            deal(USDT, TICKET_BUYERS[TICKET_BUYERS.length - 1], TICKET_PRICE);
            vm.prank(TICKET_BUYERS[TICKET_BUYERS.length - 1]);
            IERC20(USDT).approve(address(GAME), MAX_UINT256);
        }

        console2.log("Treasury Deployed at:             ", treasury);
        console2.log("Game deployed at:                 ", address(GAME));
        console2.log(
            "Full allowance (Treasury => Game):",
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
            GAME.join(ticketToBuy);

            i--;
        }

        vm.roll(block.number + WAVE_DURATION + 1);

        uint8 ticketID;

        (
            Come2Top.Status stat,
            uint256 maxPurchasableTickets,
            uint256 startedBlock,
            uint256 currentWave,
            uint256 currentTicketValue,
            uint256 remainingTickets,
            int256 eligibleWithdrawals,
            uint256 nextWaveTicketValue,
            uint256 nextWaveWinrate,
            bytes memory tickets,
            Come2Top.TicketInfo[] memory winnerTicketsInfo
        ) = GAME.wagerInfo();

        string memory stringifiedStatus;

        if (stat == Come2Top.Status.ticketSale)
            stringifiedStatus = "Ticket Saling Mode";
        else if (stat == Come2Top.Status.waitForCommingWave)
            stringifiedStatus = "Wait For Next Wave";
        else if (stat == Come2Top.Status.Withdrawable)
            stringifiedStatus = "Withdrawable";
        else stringifiedStatus = "Finished";

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
        GAME.redeem(ticketID);

        (
            ,
            int256 eligibleWithdrawals_1stTx,
            ,
            bytes memory tickets_1stTx
        ) = GAME.latestUpdate();

        uint256 ticketValue_1stTx = GAME.ticketValue();

        ticketID = uint8(tickets_1stTx[tickets_1stTx.length - 1]);
        vm.prank(ticketOwnerOfLastIndex);
        GAME.redeem(ticketID);

        (
            ,
            int256 eligibleWithdrawals_2ndTx,
            ,
            bytes memory tickets_2ndTx
        ) = GAME.latestUpdate();

        uint256 ticketValue_2ndTx = GAME.ticketValue();

        vm.roll(block.number + WAVE_DURATION + WAVE_ELIGIBLE_TIME);

        (
            ,
            int256 eligibleWithdrawalsNextWave,
            uint256 nextWave,
            bytes memory ticketsNextWave
        ) = GAME.latestUpdate();

        uint256 ticketValueNextWave = GAME.ticketValue();

        "____________________________________".log();
        console2.log("Maximum Purchasable Tickets:", maxPurchasableTickets);
        console2.log("Started Block:              ", startedBlock);
        console2.log("Remaining Tickets:          ", remainingTickets - 2);
        console2.log("Status:                     ", stringifiedStatus);
        console2.log("Current Wave:               ", currentWave);
        console2.log("Next Wave:                  ", nextWave);
        console2.log("Next Wave Ticket Value:     ", nextWaveTicketValue);
        console2.log("Next Wave Ticket Winrate:   ", nextWaveWinrate);
        console2.log(
            "Game USDT Balance:          ",
            IUSDT(USDT).balanceOf(address(GAME))
        );
        console2.log(
            "Admin USDT Balance:         ",
            IUSDT(USDT).balanceOf(GAME.ADMIN())
        );

        "".log();
        "Ticket Value".log();
        console2.log("   before any withdraws:", currentTicketValue);
        console2.log("   after 1st withdraw:  ", ticketValue_1stTx);
        console2.log("   after 2nd withdraw:  ", ticketValue_2ndTx);
        console2.log("   next wave:           ", ticketValueNextWave);

        "".log();
        "First Withdrawer Balance".log();
        console2.log("   before withdraw:", balanceOfTOI1);
        console2.log(
            "   after withdraw: ",
            IUSDT(USDT).balanceOf(ticketOwnerOfIndex1)
        );
        "Second Withdrawer Balance".log();
        console2.log("   before withdraw:", balanceOfTOLI);
        console2.log(
            "   after withdraw: ",
            IUSDT(USDT).balanceOf(ticketOwnerOfLastIndex)
        );

        "".log();
        "Eligible Withdrawals".log();
        console2.log("   before any withdraws:", eligibleWithdrawals);
        console2.log("   after 1st withdraw:  ", eligibleWithdrawals_1stTx);
        console2.log(
            "   after 2nd withdraw:  ",
            uint256(eligibleWithdrawals_2ndTx)
        );
        console2.log(
            "   next wave:           ",
            uint256(eligibleWithdrawalsNextWave)
        );

        "".log();
        "Tickets".log();
        "   before any withdraws:".log();
        tickets.logBytes();
        "   after 1st withdraw:".log();
        tickets_1stTx.logBytes();
        "   after 2nd withdraw:".log();
        tickets_2ndTx.logBytes();
        "   next wave:".log();
        ticketsNextWave.logBytes();
        "____________________________________".log();
        for (uint256 x; x < winnerTicketsInfo.length; x++) {
            console2.log("Ticket ID:  ", winnerTicketsInfo[x].ticketID);
            "Ticket Owner:".log();
            winnerTicketsInfo[x].owner.log();
            console2.log("Offer:      ", winnerTicketsInfo[x].offer.amount);
            "Offeror:     ".log();
            winnerTicketsInfo[x].offer.maker.log();
            "+++++++++++++++++++++++++".log();
        }
    }
}
