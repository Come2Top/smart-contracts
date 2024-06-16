//  SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ISuperchainL1Block} from "../interfaces/ISuperchainL1Block.sol";

import {DummyCurveStableSwapNG} from "./DummyCurveStableSwapNG.sol";

contract DummyYieldFarming {
    string public constant name = "Moo Curve crvUSD-FRAX";
    string public constant symbol = "mooCurveCrvUSD-FRAX";
    uint8 public constant decimals = 18;
    DummyCurveStableSwapNG private immutable CurveStableSwapNG;

    address public come2Top;
    mapping(address => uint256) public balanceOf;

    constructor() {
        CurveStableSwapNG = new DummyCurveStableSwapNG();
    }

    function setCome2Top(address _come2Top) external {
        require(come2Top == address(0) && _come2Top != address(0));

        come2Top = _come2Top;
    }

    function deposit(uint256 amount) external {}

    function withdraw(uint256 shares) external {}

    function getPricePerFullShare() external view returns (uint256) {}
}
