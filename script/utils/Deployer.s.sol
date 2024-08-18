//  SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";

import {Come2TopDiamond} from "../../contracts/Come2TopDiamond.sol";
import {Treasury} from "../../contracts/Treasury.sol";
import {DummyL1Block} from "../../contracts/mock/DummyL1Block.sol";
import {DummyFraxStablecoin} from "../../contracts/mock/DummyFraxStablecoin.sol";
import {DummyBeefyVaultV7, DummyCurveStableNG} from "../../contracts/mock/DummyBeefyVaultV7.sol";

contract Deployer is Script {
    Come2TopDiamond public Come2TopSC;
    Treasury public TreasurySC;
    DummyL1Block public DummyL1BlockSC;
    DummyFraxStablecoin public DummyFraxStablecoinSC;

    function run() external {
        vmSafe.startBroadcast(
            0x7fc66c1f98a1cc8355601f5620e44328d3c7a4eff2cbf37d3705832e697c79a4
        );
        TreasurySC = new Treasury();
        DummyL1BlockSC = new DummyL1Block();
        DummyFraxStablecoinSC = new DummyFraxStablecoin(1e5);

        address[7] memory beefyVaults;
        beefyVaults[0] = address(
            new DummyBeefyVaultV7(
                "Moo Curve FRAX-sDAI",
                "mooCurveFRAX-sDAI",
                "FRAX/sDAI",
                "FRAXsDAI",
                address(DummyFraxStablecoinSC)
            )
        );

        beefyVaults[1] = address(
            new DummyBeefyVaultV7(
                "Moo Curve FRAX-PYUSD",
                "mooCurveFRAX-PYUSD",
                "FRAX/PYUSD",
                "FRAXPYUSD",
                address(DummyFraxStablecoinSC)
            )
        );
        beefyVaults[2] = address(
            new DummyBeefyVaultV7(
                "Moo Curve FRAX-USDT",
                "mooCurveFRAX-USDT",
                "FRAX/USDT",
                "FRAXUSDT",
                address(DummyFraxStablecoinSC)
            )
        );
        beefyVaults[3] = address(
            new DummyBeefyVaultV7(
                "Moo Curve FRAX-DAI",
                "mooCurveFRAX-DAI",
                "FRAX/DAI",
                "FRAXDAI",
                address(DummyFraxStablecoinSC)
            )
        );
        beefyVaults[4] = address(
            new DummyBeefyVaultV7(
                "Moo Curve crvUSD-FRAX",
                "mooCurveCrvUSD-FRAX",
                "crvUSD/Frax",
                "crvUSDFRAX",
                address(DummyFraxStablecoinSC)
            )
        );
        beefyVaults[5] = address(
            new DummyBeefyVaultV7(
                "Moo Curve FRAX-USDe",
                "mooCurveFRAX-USDe",
                "FRAX/USDe",
                "FRAXUSDe",
                address(DummyFraxStablecoinSC)
            )
        );
        beefyVaults[6] = address(
            new DummyBeefyVaultV7(
                "Moo Curve FRAX-USDC",
                "mooCurveFRAX-USDC",
                "FRAX/USDC",
                "FRAXUSDC",
                address(DummyFraxStablecoinSC)
            )
        );

        Come2TopSC = new Come2TopDiamond(
            4,
            1e20,
            12,
            4,
            address(DummyFraxStablecoinSC),
            address(TreasurySC),
            address(DummyL1BlockSC),
            beefyVaults
        );

        for (uint256 i; i < 7; ) {
            DummyBeefyVaultV7(beefyVaults[i]).setCome2Top(address(Come2TopSC));
            DummyFraxStablecoinSC.addToWhitelist(
                address(DummyBeefyVaultV7(beefyVaults[i]).CurveStableNG())
            );

            unchecked {
                i++;
            }
        }

        vmSafe.stopBroadcast();
    }
}
