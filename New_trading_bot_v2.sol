// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract SimpleEtherBot is Ownable {
    ISwapRouter public immutable uniswapRouter;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 public capital;
    uint256 public profitTargetPercent = 101; // 1% profit goal (101%)
    uint256 public lastTradeDay;
    bool public paused = true;

    event TradeExecuted(uint256 amountIn, uint256 amountOut);
    event Paused();
    event Resumed();
    event ProfitTaken(uint256 amount);

    modifier onlyActive() {
        require(!paused, "Bot is paused");
        _;
    }

    constructor(address _router) Ownable(msg.sender) {
        uniswapRouter = ISwapRouter(_router);
    }

    function deposit() external payable onlyOwner {
        capital += msg.value;
    }

    function trade(
        address tokenOut, 
        uint24 poolFee, 
        uint160 sqrtPriceLimitX96
    ) external onlyOwner onlyActive {
        uint256 currentDay = block.timestamp / 1 days;
        require(currentDay > lastTradeDay, "Trade already executed today");
        require(capital > 0, "Insufficient capital");

        uint256 amountIn = capital / 100; // Trade 1% of capital
        uint256 minOut = (amountIn * profitTargetPercent) / 100;

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH,
            tokenOut: tokenOut,
            fee: poolFee,
            recipient: address(this),
            deadline: block.timestamp + 15 minutes,
            amountIn: amountIn,
            amountOutMinimum: minOut,
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });

        // Transfer WETH to contract first (needed for WETH trades)
        (bool success, ) = WETH.call{value: amountIn}("");
        require(success, "WETH deposit failed");

        try uniswapRouter.exactInputSingle(params) returns (uint256 amountOut) {
            require(amountOut >= minOut, "Profit target not met");
            capital += (amountOut - amountIn); // Update capital with net gain
            lastTradeDay = currentDay;
            emit TradeExecuted(amountIn, amountOut);
        } catch {
            paused = true;
            emit Paused();
        }
    }

    function takeProfit(uint256 amount) external onlyOwner {
        require(amount <= capital, "Exceeds capital");
        capital -= amount;
        payable(owner()).transfer(amount);
        emit ProfitTaken(amount);
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function resume() external onlyOwner {
        require(capital > 0, "Insufficient funds");
        paused = false;
        emit Resumed();
    }

    receive() external payable {
        capital += msg.value;
    }
}
