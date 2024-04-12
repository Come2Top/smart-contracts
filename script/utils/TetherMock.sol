// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

contract USDT {
    address public immutable OWNER = msg.sender;
    bytes32 public immutable DOMAIN_SEPARATOR =
        keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes(VERSION)),
                block.chainid,
                address(this)
            )
        );
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
    string public constant VERSION = "1";
    uint256 public constant MAX_MINT = 1e10;
    string public constant name = "Tether USD";
    string public constant symbol = "USDT";
    uint8 public constant decimals = 6;

    address public come2top;
    uint256 public totalSupply;
    mapping(address => uint256) public nonces;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function changeCome2Top(address come2top_) external {
        require(
            msg.sender == OWNER,
            "USDT::Ownership: only owner can change state"
        );

        come2top = come2top_;
    }

    function mint() external {
        address account = msg.sender;
        uint256 balance = balanceOf[account];

        require(
            balance < MAX_MINT,
            "USDT: address reached maximum mintable amount or is over that"
        );

        balance = MAX_MINT - balance;

        require(
            type(uint256).max - balance >= totalSupply,
            "USDT: mint amount exceeds MAX_UINT256"
        );

        if (allowance[account][come2top] != type(uint256).max)
            _approve(account, come2top, type(uint256).max);

        unchecked {
            totalSupply += balance;
        }
        balanceOf[account] = MAX_MINT;

        emit Transfer(address(0), account, balance);

    }

    function burn(uint256 amount) external {
        address account = msg.sender;
        uint256 accountBalance = balanceOf[account];

        require(accountBalance >= amount, "USDT: burn amount exceeds balance");

        unchecked {
            balanceOf[account] -= amount;
            totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        address owner = msg.sender;

        _transfer(owner, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        address spender = msg.sender;

        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);

        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        address owner = msg.sender;

        _approve(owner, spender, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        address owner = msg.sender;

        _approve(owner, spender, allowance[owner][spender] + addedValue);

        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        address owner = msg.sender;
        uint256 currentAllowance = allowance[owner][spender];

        require(
            currentAllowance >= subtractedValue,
            "USDT: decreased allowance below zero"
        );

        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp <= deadline, "USDT::Permit: expired permit");

        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                nonces[owner]++,
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct)
        );

        address signer = ecrecover(digest, v, r, s);
        require(
            signer != address(0) && signer == owner,
            "USDT::Permit: invalid signature"
        );

        _approve(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 fromBalance = balanceOf[from];

        require(from != address(0), "USDT: transfer from the zero address");
        require(to != address(0), "USDT: transfer to the zero address");
        require(fromBalance >= amount, "USDT: transfer amount exceeds balance");

        unchecked {
            balanceOf[from] = fromBalance - amount;
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "USDT: approve from the zero address");
        require(spender != address(0), "USDT: approve to the zero address");

        allowance[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        uint256 currentAllowance = allowance[owner][spender];

        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "USDT: insufficient allowance");

            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}
