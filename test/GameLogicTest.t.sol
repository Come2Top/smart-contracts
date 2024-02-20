pragma solidity 0.8.18;

import {Test, console2} from "forge-std/Test.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {IUSDT} from "../contracts/interfaces/IUSDT.sol";
import {TwoHundredFiftySix} from "../contracts/TwoHundredFiftySix.sol";

contract GameLogicTest is Test {
    using console2 for *;
    using Strings for uint256;

    TwoHundredFiftySix private GAME;
    address[] private TICKET_BUYERS;
    address private ADMIN = makeAddr("ADMIN");

    address private constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    uint8 private constant MAX_TICKET_PER_GAME = 1;
    uint80 private constant TICKET_PRICE = 1e6;
    uint256 private constant MAX_PLAYERS = 256;

    function setUp() external {
        vm.createSelectFork("https://polygon.drpc.org", 53600000);

        GAME = new TwoHundredFiftySix(
            ADMIN,
            USDT,
            MAX_TICKET_PER_GAME,
            TICKET_PRICE
        );

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
            IUSDT(USDT).approve(address(GAME), 1e6);
        }

        console2.log("Game deployed at:", address(GAME));
        console2.log("Setup completed, going for tests...");
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

        vm.roll(block.number + 280);

        (
            TwoHundredFiftySix.Status stat,
            int256 eligibleWithdrawalsB,
            uint256 currentWave,
            bytes memory ticketsB
        ) = GAME.getLatestUpdate();

        uint256 ticketValueBefore = GAME.currentTicketValue();
        uint8[] memory indexes = new uint8[](1);
        address ticketOwnerOf218 = GAME.ticketOwnership(0, 218);
        uint256 balanceOfTKO218 = IUSDT(USDT).balanceOf(ticketOwnerOf218);

        vm.prank(ticketOwnerOf218);
        GAME.receiveLotteryWagedPrize(indexes);

        (, int256 eligibleWithdrawalsA, , bytes memory ticketsA) = GAME
            .getLatestUpdate();

        "____________________________________".log();
        console2.log("Status:       ", uint8(stat));
        console2.log("Current wave: ", currentWave);

        "".log();
        console2.log(
            "Ticket value before withdraw:         ",
            ticketValueBefore
        );
        console2.log(
            "Ticket value after withdraw:          ",
            GAME.currentTicketValue()
        );

        "".log();
        console2.log("Withdrawer balance before withdraw:   ", balanceOfTKO218);
        console2.log(
            "Withdrawer balance after withdraw:    ",
            IUSDT(USDT).balanceOf(ticketOwnerOf218)
        );

        "".log();
        console2.log(
            "Eligible withdrawals before withdraw: ",
            uint256(eligibleWithdrawalsB)
        );
        // eligibleWithdrawalsB.logInt();
        console2.log(
            "Eligible withdrawals after withdraw:  ",
            uint256(eligibleWithdrawalsA)
        );
        // eligibleWithdrawalsA.logInt();

        "".log();
        console2.log("Tickets before withdraw: ");
        ticketsB.logBytes();
        console2.log("Tickets after withdraw: ");
        ticketsA.logBytes();

        "____________________________________".log();
    }
}
