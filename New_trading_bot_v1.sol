// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@aave/core-v2/contracts/flashloan/base/FlashLoanReceiverBase.sol";
import "@aave/core-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";
import "@aave/core-v2/contracts/interfaces/ILendingPool.sol";

interface IUniswapV2Router {
    function WETH() external view returns (address);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IERC20 {
    function approve(address spender, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
}

interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        );
}

contract SafeEthArbBot is FlashLoanReceiverBase {
    address public owner;
    IUniswapV2Router public router;
    AggregatorV3Interface public priceFeed;
    uint public minProfit; // in wei

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(
        address _router,
        address _priceFeed,
        ILendingPoolAddressesProvider _provider
    ) FlashLoanReceiverBase(_provider) {
        owner = msg.sender;
        router = IUniswapV2Router(_router);
        priceFeed = AggregatorV3Interface(_priceFeed);
        minProfit = 1e15; // 0.001 ETH
    }

    receive() external payable {}
    fallback() external payable {}

    function getLatestETHPrice() public view returns (int) {
        (, int price,,,) = priceFeed.latestRoundData();
        return price; // Example: 3000 * 10^8
    }

    function executeArbitrage(address asset, uint amount, address targetToken) external onlyOwner {
        bytes memory params = abi.encode(targetToken);
        uint16 referralCode = 0;

        address ;
        assets[0] = asset;

        uint256 ;
        amounts[0] = amount;

        uint256 ;
        modes[0] = 0; // No debt, flash loan

        lendingPool.flashLoan(
            address(this),
            assets,
            amounts,
            modes,
            address(this),
            params,
            referralCode
        );
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address, /* initiator */
        bytes calldata params
    ) external override returns (bool) {
        require(msg.sender == address(lendingPool), "Unauthorized");

        address token = abi.decode(params, (address));
        uint deadline = block.timestamp + 300;

        // Swap ETH → Token
        address ;
        path[0] = router.WETH();
        path[1] = token;

        router.swapExactETHForTokens{value: amounts[0]}(
            1, path, address(this), deadline
        );

        uint tokenBal = IERC20(token).balanceOf(address(this));
        IERC20(token).approve(address(router), tokenBal);

        // Swap Token → ETH
        path[0] = token;
        path[1] = router.WETH();

        uint beforeBalance = address(this).balance;

        router.swapExactTokensForETH(
            tokenBal, 1, path, address(this), deadline
        );

        uint afterBalance = address(this).balance;
        uint profit = afterBalance - beforeBalance;

        uint totalOwed = amounts[0] + premiums[0];

        require(profit > minProfit + premiums[0], "Trade not profitable");

        // Repay flash loan
        payable(address(lendingPool)).transfer(totalOwed);
        return true;
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function updateMinProfit(uint _wei) external onlyOwner {
        minProfit = _wei;
    }
}
