//  SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Come2Top} from "../../contracts/Come2Top.sol";
import {Treasury} from "../../contracts/Treasury.sol";
import {DummyL1Block} from "../../contracts/mock/DummyL1Block.sol";
import {DummyBeefyVaultV7, DummyCurveStableSwapNG} from "../../contracts/mock/DummyBeefyVaultV7.sol";
import {DummyFraxStablecoin} from "../../contracts/mock/DummyFraxStablecoin.sol";

contract Deployer {
    Come2Top public immutable Come2TopSC;
    Treasury public immutable TreasurySC;
    DummyL1Block public immutable DummyL1BlockSC;
    DummyBeefyVaultV7 public immutable DummyBeefyVaultV7SC;
    DummyCurveStableSwapNG public immutable DummyCurveStableSwapNGSC;
    DummyFraxStablecoin public immutable DummyFraxStablecoinSC;

    constructor() {
        TreasurySC = new Treasury();
        DummyL1BlockSC = new DummyL1Block();
        DummyBeefyVaultV7SC = new DummyBeefyVaultV7();
        DummyCurveStableSwapNGSC = DummyCurveStableSwapNG(
            DummyBeefyVaultV7SC.CurveStableSwapNG()
        );
        DummyFraxStablecoinSC = DummyCurveStableSwapNGSC.FRAX();

        Come2TopSC = new Come2Top(
            128,
            1e20,
            12,
            address(DummyFraxStablecoinSC),
            address(TreasurySC),
            address(DummyL1BlockSC),
            address(DummyBeefyVaultV7SC),
            address(DummyCurveStableSwapNGSC)
        );

        DummyBeefyVaultV7SC.setCome2Top(address(Come2TopSC));
    }
}
