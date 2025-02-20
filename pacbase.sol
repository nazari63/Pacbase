// Minor update: Comment added for GitHub contributions
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountA,
        uint amountB,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountAActual, uint amountBActual, uint liquidity);
}

contract PacBase {
    string public name = "PacBase";
    string public symbol = "PBASE";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1_000_000_000 * 10 ** uint256(decimals); // 1 Billion
    uint256 public circulatingSupply = totalSupply * 95 / 100; // 95% in circulation
    address public owner;
    address public liquidityPool;
    address public uniswapRouter;
    uint256 public taxFee = 0.01 * 10 ** 2; // 0.01% tax
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(address _uniswapRouter) {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
        uniswapRouter = _uniswapRouter;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        uint256 taxAmount = (amount * taxFee) / 10000;
        uint256 amountAfterTax = amount - taxAmount;

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amountAfterTax;
        balanceOf[liquidityPool] += taxAmount; // Send tax to liquidity pool

        emit Transfer(msg.sender, to, amountAfterTax);
        emit Transfer(msg.sender, liquidityPool, taxAmount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Allowance exceeded");
        uint256 taxAmount = (amount * taxFee) / 10000;
        uint256 amountAfterTax = amount - taxAmount;

        balanceOf[from] -= amount;
        balanceOf[to] += amountAfterTax;
        balanceOf[liquidityPool] += taxAmount; // Send tax to liquidity pool
        allowance[from][msg.sender] -= amount;

        emit Transfer(from, to, amountAfterTax);
        emit Transfer(from, liquidityPool, taxAmount);
        return true;
    }

    // Add liquidity to Uniswap pool
    function addLiquidity(uint256 amountToken, uint256 amountETH) external onlyOwner {
        require(balanceOf[owner] >= amountToken, "Insufficient token balance");
        balanceOf[owner] -= amountToken;
        // Example liquidity pool contract for ETH
        IUniswapV2Router(uniswapRouter).addLiquidity(
            address(this), 
            address(0), // Assuming ETH as liquidity pair (Use actual WETH address)
            amountToken,
            amountETH,
            0, // Slippage tolerance
            0, // Slippage tolerance
            owner,
            block.timestamp
        );
    }
    
    // Set liquidity pool address
    function setLiquidityPool(address _pool) external onlyOwner {
        liquidityPool = _pool;
    }
}
