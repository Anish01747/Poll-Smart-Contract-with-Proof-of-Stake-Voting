// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PollWithPoS {
    address public owner;
    string public question;
    string[] public options;
    mapping(address => uint256) public stakes;
    mapping(uint => uint256) public votes; // option index => total staked votes
    bool public votingOpen;

    constructor() {
        owner = msg.sender;
        question = "Which blockchain do you prefer?";
        options.push("Ethereum");
        options.push("Solana");
        options.push("Polygon");
        votingOpen = true;
    }

    function stakeAndVote(uint optionIndex) external payable {
        require(votingOpen, "Voting has ended");
        require(msg.value > 0, "Stake some ETH to vote");
        require(optionIndex < options.length, "Invalid voting option");

        stakes[msg.sender] += msg.value;
        votes[optionIndex] += msg.value;
    }

    function closeVoting() external {
        require(msg.sender == owner, "Only the owner can close the voting");
        votingOpen = false;
    }

    function getVotes() external view returns (uint256[] memory) {
        uint256[] memory results = new uint256[](options.length);
        for (uint i = 0; i < options.length; i++) {
            results[i] = votes[i];
        }
        return results;
    }
}

