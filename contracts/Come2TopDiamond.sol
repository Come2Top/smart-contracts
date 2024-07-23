// SPDX-License-Identifier: -- Come2Top --
pragma solidity 0.8.20;

import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IFraxtalL1Block} from "./interfaces/IFraxtalL1Block.sol";
import {IBeefyVault} from "./interfaces/IBeefyVault.sol";
import {ICurveStableNG} from "./interfaces/ICurveStableNG.sol";

import {DiamondLib} from "./libraries/DiamondLib.sol";
import {GameStorageLib, GameStorage, StratConfig} from "./libraries/GameStorageLib.sol";
import {GameConstantsLib} from "./libraries/GameConstantsLib.sol";
import {GameUintCheckersLib} from "./libraries/GameUintCheckersLib.sol";

import {DiamondCutFacet} from "./facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "./facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "./facets/OwnershipFacet.sol";
import {AdminstrationFacet} from "./facets/AdminstrationFacet.sol";
import {GameActionsFacet} from "./facets/GameActionsFacet.sol";
import {CommonGettersFacet} from "./facets/CommonGettersFacet.sol";
import {GameGettersFacet} from "./facets/GameGettersFacet.sol";

contract Come2TopDiamond {
    /*******************************\
    |-*-*-*-*   CONSTANTS   *-*-*-*-|
    \*******************************/
    uint256 public immutable MAGIC_VALUE;
    IERC20 public immutable FRAX;
    address public immutable TREASURY;
    address public immutable THIS = address(this);
    IFraxtalL1Block public immutable FRAXTAL_L1_BLOCK;

    /********************************\
    |-*-*-*-*-*   ERRORS   *-*-*-*-*-|
    \********************************/
    error APROVE_OPERATION_FAILED();
    error FRAX_TOKEN_NOT_FOUND();
    error INVALID_CURVE_PAIR();
    error ZERO_ADDRESS_PROVIDED();

    /******************************\
    |-*-*-*-*   BUILT-IN   *-*-*-*-|
    \******************************/
    constructor(
        uint8 mtpg,
        uint80 tp,
        uint48 prngp,
        uint8 gameStrat,
        address frax,
        address treasury,
        address fraxtalL1Block,
        address[7] memory beefyVaults
    ) {
        GameUintCheckersLib.checkMTPG(mtpg);
        GameUintCheckersLib.checkTP(tp);
        GameUintCheckersLib.checkPRNGP(prngp);
        GameUintCheckersLib.checkGS(gameStrat);

        if (
            frax == GameConstantsLib.ZERO_ADDRESS() ||
            treasury == GameConstantsLib.ZERO_ADDRESS() ||
            fraxtalL1Block == GameConstantsLib.ZERO_ADDRESS()
        ) revert ZERO_ADDRESS_PROVIDED();

        GameStorage storage gs = GameStorageLib.gameStorage();

        gs.maxTicketsPerGame = mtpg;
        gs.ticketPrice = tp;
        gs.prngPeriod = prngp;
        gs.currentGameStrat = gameStrat;
        FRAX = IERC20(frax);
        TREASURY = treasury;
        FRAXTAL_L1_BLOCK = IFraxtalL1Block(fraxtalL1Block);
        gs.gameData[0].tickets = GameConstantsLib.BYTE_TICKETS();
        unchecked {
            MAGIC_VALUE = uint160(address(this)) * block.chainid;
        }

        (bool ok, ) = treasury.call(abi.encode(frax));
        if (!ok) revert APROVE_OPERATION_FAILED();

        address curveStableNG;
        uint256 fraxTokenPosition;
        for (uint256 i; i < 7; ) {
            if (beefyVaults[i] == GameConstantsLib.ZERO_ADDRESS())
                revert ZERO_ADDRESS_PROVIDED();
            curveStableNG = IBeefyVault(beefyVaults[i]).want();

            if (ICurveStableNG(curveStableNG).N_COINS() != 2)
                revert INVALID_CURVE_PAIR();

            IERC20(frax).approve(curveStableNG, type(uint256).max);
            ICurveStableNG(curveStableNG).approve(
                beefyVaults[i],
                type(uint256).max
            );

            fraxTokenPosition = frax == ICurveStableNG(curveStableNG).coins(0)
                ? 0
                : frax == ICurveStableNG(curveStableNG).coins(1)
                ? 1
                : 404;

            if (fraxTokenPosition == 404) revert FRAX_TOKEN_NOT_FOUND();

            gs.gameStratConfig[i] = StratConfig(
                uint96(fraxTokenPosition),
                ICurveStableNG(curveStableNG),
                IBeefyVault(beefyVaults[i])
            );

            unchecked {
                i++;
            }
        }

        DiamondLib.setContractOwner(tx.origin);
        DiamondLib.addDiamondFunctions(
            address(new DiamondCutFacet()),
            address(new DiamondLoupeFacet()),
            address(new OwnershipFacet())
        );

        {
            IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](4);

            bytes4[] memory functionSelectors = new bytes4[](5);
            functionSelectors[0] = AdminstrationFacet.changeGameStrat.selector;
            functionSelectors[1] = AdminstrationFacet.togglePause.selector;
            functionSelectors[2] = AdminstrationFacet.changeTicketPrice.selector;
            functionSelectors[3] = AdminstrationFacet.changeMaxTicketsPerGame.selector;
            functionSelectors[4] = AdminstrationFacet.changePRNGperiod.selector;
            cut[0] = IDiamondCut.FacetCut({
                facetAddress: address(new AdminstrationFacet()),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectors
            });

            functionSelectors = new bytes4[](5);
            functionSelectors[0] = GameActionsFacet.ticketSaleOperation.selector;
            functionSelectors[1] = GameActionsFacet.winnerOperation.selector;
            functionSelectors[2] = GameActionsFacet.offerOperation.selector;
            functionSelectors[3] = GameActionsFacet.claimOperation.selector;
            functionSelectors[4] = GameActionsFacet.takeBackStaleOffers.selector;
            cut[1] = IDiamondCut.FacetCut({
                facetAddress: address(new GameActionsFacet()),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectors
            });

            functionSelectors = new bytes4[](14);
            functionSelectors[0] = CommonGettersFacet.pause.selector;
            functionSelectors[1] = CommonGettersFacet.maxTicketsPerGame.selector;
            functionSelectors[2] = CommonGettersFacet.ticketPrice.selector;
            functionSelectors[3] = CommonGettersFacet.currentGameStrat.selector;
            functionSelectors[4] = CommonGettersFacet.prngPeriod.selector;
            functionSelectors[5] = CommonGettersFacet.currentGameID.selector;
            functionSelectors[6] = CommonGettersFacet.gameStratConfig.selector;
            functionSelectors[7] = CommonGettersFacet.gameData.selector;
            functionSelectors[8] = CommonGettersFacet.offerorData.selector;
            functionSelectors[9] = CommonGettersFacet.tempTicketOwnership.selector;
            functionSelectors[10] = CommonGettersFacet.totalPlayerTickets.selector;
            functionSelectors[11] = CommonGettersFacet.playerBalanceData.selector;
            functionSelectors[12] = CommonGettersFacet.offer.selector;
            functionSelectors[13] = CommonGettersFacet.playerRecentGames.selector;
            cut[2] = IDiamondCut.FacetCut({
                facetAddress: address(new CommonGettersFacet()),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectors
            });

            functionSelectors = new bytes4[](7);
            functionSelectors[0] = GameGettersFacet.claimableAmount.selector;
            functionSelectors[1] = GameGettersFacet.continuesIntegration.selector;
            functionSelectors[2] = GameGettersFacet.latestGameUpdate.selector;
            functionSelectors[3] = GameGettersFacet.gameStatus.selector;
            functionSelectors[4] = GameGettersFacet.paginatedPlayerGames.selector;
            functionSelectors[5] = GameGettersFacet.ticketValue.selector;
            functionSelectors[6] = GameGettersFacet.staleOffers.selector;
            cut[3] = IDiamondCut.FacetCut({
                facetAddress: address(new GameGettersFacet()),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectors
            });

            DiamondLib.diamondCut(cut, address(0), "");
        }
    }

    fallback() external payable {
        DiamondLib.DiamondStorage storage ds;
        bytes32 position = DiamondLib.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(
            facet != address(0),
            "Come2TopDiamond: Function does not exist"
        );
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {
        revert();
    }
}
