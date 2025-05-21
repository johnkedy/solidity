// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // This Line tells the compiler the version of solidity we are coding with.

//Next, we must import all necessary libraries neede for this code to run.
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
//Now, we must create the contract itself.
contract FundMe {//is Ownable {
   // using SafeMath for uint256; // Use SafeMath for all uint256 operations
   
   // State Variables
    address public immutable i_owner;
    uint256 public s_minimumDonationAmount;
    uint256 public s_targetAmount;
    uint256 public s_totalFundsRaised;
    bool public s_campaignActive;

    mapping(address => uint256) public s_donators; // Here we map the accounts to thier amounts of donation. We can now check if an account has donated
    address[] public s_donatorsArray; // A bucket to hold all the funders addresses.

    //next we create a function to create fundMe.
    function funcdMe()payable public { // This is how we define a constructor for our public {
        //Check to make sure that the amount contibuted is hgher than the minimum deposit.
        require(msg.value >= s_minimumDonationAmount, "Amount not enough for deposit");
    }

    // Events
    event DonationReceived(address indexed donator, uint256 amount, uint256 newTotalFunds);
    event FundsWithdrawn(address indexed to, uint256 amount);
    event CampaignStarted(uint256 targetAmount, uint256 minimumDonation);
    event CampaignEnded();

    // Modifiers
    modifier onlyActiveCampaign() {
        require(s_campaignActive, "FundMe: Campaign is not active.");
        _;
    }

    modifier onlyIfTargetNotReached() {
        require(s_totalFundsRaised < s_targetAmount, "FundMe: Target amount already reached.");
        _;
    }
    // Constructor
    constructor(uint256 _targetAmount, uint256 _minimumDonationAmount) {
        i_owner = msg.sender;
        s_targetAmount = _targetAmount;
        s_minimumDonationAmount = _minimumDonationAmount;
        s_campaignActive = true;
        s_totalFundsRaised = 0;
        emit CampaignStarted(_targetAmount, _minimumDonationAmount);
    }
    // External Functions

    /// @notice Allows users to send Ether to the contract as a donation.
    function fund() external payable onlyActiveCampaign onlyIfTargetNotReached {
        require(msg.value >= s_minimumDonationAmount, "FundMe: Donation amount too low.");

        if (s_donators[msg.sender] == 0) {
            s_donatorsArray.push(msg.sender);
        }

        s_donators[msg.sender] = s_donators[msg.sender].add(msg.value);
        s_totalFundsRaised = s_totalFundsRaised.add(msg.value);

        emit DonationReceived(msg.sender, msg.value, s_totalFundsRaised);

        if (s_totalFundsRaised >= s_targetAmount) {
            s_campaignActive = false;
            emit CampaignEnded();
        }
    }
    /// @notice Allows the owner to withdraw all accumulated funds.
    function withdrawFunds() external onlyOwner {
        require(s_totalFundsRaised >= s_targetAmount || !s_campaignActive, "FundMe: Campaign still active or target not met.");
        require(address(this).balance > 0, "FundMe: No funds to withdraw.");

        uint256 amountToWithdraw = address(this).balance;

        // Reset donator amounts and clear donators array for potential future campaigns
        for (uint256 i = 0; i < s_donatorsArray.length; i++) {
            s_donators[s_donatorsArray[i]] = 0;
        }
        s_donatorsArray = new address[](0);

        s_totalFundsRaised = 0;

        (bool success, ) = payable(i_owner).call{value: amountToWithdraw}("");
        require(success, "FundMe: Transfer failed.");

        emit FundsWithdrawn(i_owner, amountToWithdraw);
    }
    

    /// @notice Allows the owner to manually end the campaign.
    function endCampaignManually() external onlyOwner onlyActiveCampaign {
        s_campaignActive = false;
        emit CampaignEnded();
    }

    /// @notice Allows the owner to start a new campaign (resetting previous data).
    function startNewCampaign(uint256 _newTargetAmount, uint256 _newMinimumDonation) external onlyOwner {
        require(!s_campaignActive, "FundMe: Cannot start new campaign while one is active. End it first.");
        require(address(this).balance == 0, "FundMe: Cannot start new campaign with funds still in contract. Withdraw them first.");

        s_targetAmount = _newTargetAmount;
        s_minimumDonationAmount = _newMinimumDonation;
        s_totalFundsRaised = 0;
        s_donatorsArray = new address[](0);

        s_campaignActive = true;
        emit CampaignStarted(_newTargetAmount, _newMinimumDonation);
    }
    // Fallback and Receive functions (important for receiving Ether)

    receive() external payable {
        fund(); // Automatically calls fund() if Ether is sent without data
    }

    fallback() external payable {
        fund(); // Automatically calls fund() if Ether is sent with data but no matching function
    }
}
}
