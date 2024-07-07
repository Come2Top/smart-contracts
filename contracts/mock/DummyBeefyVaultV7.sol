//  SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DummyCurveStableNG} from "./DummyCurveStableNG.sol";

contract DummyBeefyVaultV7 {
    uint8 public constant decimals = 18;
    DummyCurveStableNG public immutable CurveStableNG;

    address public come2Top;
    uint256 public totalSupply;
    uint256 public supplyWatcher;
    string public name;
    string public symbol;
    mapping(address => uint256) public balanceOf;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory csngName_,
        string memory csngSymbol_,
        address frax
    ) {
        name = name_;
        symbol = symbol_;

        CurveStableNG = new DummyCurveStableNG(csngName_, csngSymbol_, frax);
    }

    function setCome2Top(address come2Top_) external {
        require(come2Top == address(0) && come2Top_ != address(0));

        come2Top = come2Top_;
    }

    function deposit(uint256 amount) external {
        address sender = msg.sender;
        require(sender == come2Top);

        if (totalSupply == 0) supplyWatcher = block.timestamp;
        uint256 bal = balance();
        CurveStableNG.transferFrom(sender, address(this), amount);

        uint256 shares;
        totalSupply == 0 ? shares = amount : shares =
            (amount * totalSupply) /
            bal;

        totalSupply += shares;
        balanceOf[sender] += shares;
    }

    function withdraw(uint256 shares) external {
        address sender = msg.sender;
        uint256 asset = (balance() * shares) / totalSupply;

        CurveStableNG.internalBurn(shares);

        balanceOf[sender] -= shares;
        totalSupply -= shares;

        if (totalSupply == 0) delete supplyWatcher;

        CurveStableNG.transfer(sender, asset);
    }

    function getPricePerFullShare() external view returns (uint256) {
        return totalSupply == 0 ? 1e18 : (balance() * 1e18) / totalSupply;
    }

    function balance() public view returns (uint256) {
        if (totalSupply == 0) return 0;

        uint256 bal = CurveStableNG.balanceOf(address(this));

        // using simple interest for test
        uint256 n = block.timestamp - supplyWatcher;
        if (n == 0) n = 1;

        // interest rate = 115740740740/s (1e18 base -> 1% every day == 1e16 of balance)
        return bal + ((bal * n * 115740740740) / 1e18);
    }

    function want() external view returns (address) {
        return address(CurveStableNG);
    }
}
