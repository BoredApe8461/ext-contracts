// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Importing OpenZeppelin's SafeMath library to prevent overflow and underflow
// And Ownable for ownership control of each fundraising campaign
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

// Fundraising campaign contract
contract Fundraiser is Ownable {
    using SafeMath for uint256;

    // Variables to keep track of the goal, current amount, and contributions
    uint256 public goal;
    uint256 public totalContributed;
    bool public goalReached;
    mapping(address => uint256) public contributions;

    // Event declarations for logging activities
    event ContributionReceived(address contributor, uint256 amount);
    event GoalReached(uint256 totalContributed);
    event MoneyWithdrawn(address contributor, uint256 amount);
    event CampaignCancelled();

    // Constructor to initialize the fundraiser with a specific goal
    constructor(uint256 _goal) {
        require(_goal > 0, "Goal must be greater than 0");
        goal = _goal;
    }

    // Function to contribute to the fundraiser
    function contribute() public payable {
        require(msg.value > 0, "Contribution must be greater than 0");
        require(!goalReached, "Goal has already been reached");

        contributions[msg.sender] = contributions[msg.sender].add(msg.value);
        totalContributed = totalContributed.add(msg.value);
        emit ContributionReceived(msg.sender, msg.value);

        // Check if the goal has been reached
        if (totalContributed >= goal) {
            goalReached = true;
            emit GoalReached(totalContributed);
            // Assume purchase_core is a function that needs to be executed
            purchase_core();
        }
    }

    // Function to be executed when the goal is reached
    function purchase_core() internal {
        // Placeholder for core purchase logic
        // If this function reverts, contributions can be withdrawn
    }

    // Function for contributors to withdraw their funds if the fundraiser is cancelled or purchase_core fails
    function withdraw() public {
        require(contributions[msg.sender] > 0, "No contributions to withdraw");
        require(!goalReached, "Cannot withdraw after goal is reached");

        uint256 contributedAmount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        payable(msg.sender).transfer(contributedAmount);
        emit MoneyWithdrawn(msg.sender, contributedAmount);
    }

    // Function for the owner to cancel the fundraising campaign
    function cancelFundraiser() public onlyOwner {
        require(!goalReached, "Cannot cancel after goal is reached");
        goalReached = true; // Prevents further contributions
        emit CampaignCancelled();
    }
}

// Factory contract to manage multiple fundraising campaigns
contract FundraiserFactory {
    // Array to store instances of fundraisers
    Fundraiser[] public fundraisers;

    // Function to create a new fundraiser
    function createFundraiser(uint256 goal) public {
        Fundraiser newFundraiser = new Fundraiser(goal);
        newFundraiser.transferOwnership(msg.sender); // Transfer ownership to the creator
        fundraisers.push(newFundraiser);
    }

    // Function to get the deployed fundraisers
    function getFundraisers() public view returns (Fundraiser[] memory) {
        return fundraisers;
    }
}
