//  SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ICurveStableSwapNG} from "../interfaces/ICurveStableSwapNG.sol";
import {DummyFraxStablecoin} from "./DummyFraxStablecoin.sol";

interface IOwner {
    function come2Top() external view returns (address);
}

contract DummyCurveStableSwapNG is ICurveStableSwapNG {
    string public constant name = "crvUSD/Frax";
    string public constant symbol = "crvUSDFRAX";
    uint8 public constant decimals = 18;
    uint256 private constant _MAX_UINT256 = type(uint256).max;
    IOwner private immutable OWNER = IOwner(msg.sender);
    DummyFraxStablecoin public immutable FRAX;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor() {
        FRAX = new DummyFraxStablecoin(1e5);
    }

    function add_liquidity(
        uint256[8] memory deposit_amounts,
        uint256 min_mint_amount,
        address receiver
    ) external returns (uint256) {
        min_mint_amount;
        receiver;

        address sender = msg.sender;

        require(sender == OWNER.come2Top());
        FRAX.transferFrom(sender, address(this), deposit_amounts[1]);

        totalSupply += deposit_amounts[1];
        balanceOf[sender] += deposit_amounts[1];

        return deposit_amounts[1];
    }

    function remove_liquidity_one_coin(
        uint256 burn_amount,
        int128 i,
        uint256 min_received,
        address receiver
    ) external returns (uint256) {
        i;
        min_received;

        require(msg.sender == OWNER.come2Top());

        totalSupply -= burn_amount;
        balanceOf[OWNER.come2Top()] -= burn_amount;
        FRAX.internalMint(receiver, burn_amount);

        return burn_amount;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        address sender = msg.sender;
        require(sender == address(OWNER));

        totalSupply += amount;
        balanceOf[to] += amount;

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        from;
        to;

        address sender = msg.sender;
        require(sender == address(OWNER));

        balanceOf[OWNER.come2Top()] -= amount;
        balanceOf[address(OWNER)] += amount;

        return true;
    }

    function internalBurn(uint256 amount) external {
        address sender = msg.sender;
        require(sender == address(OWNER));

        balanceOf[sender] -= amount;
        totalSupply -= amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        address owner = msg.sender;

        _approve(owner, spender, amount);

        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowance[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        uint256 currentAllowance = allowance[owner][spender];

        if (currentAllowance != _MAX_UINT256) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );

            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}
