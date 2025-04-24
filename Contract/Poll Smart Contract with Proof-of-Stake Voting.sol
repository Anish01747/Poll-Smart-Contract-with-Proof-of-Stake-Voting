// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PollWithPoS {
    address public owner;
    string public question;
    string[] public options;
    mapping(address => uint256) public stakes;
    mapping(uint => uint256) public votes; // option index => total staked votes
    bool public votingOpen;

    event Voted(address indexed voter, uint indexed optionIndex, uint amount);
    event VotingClosed();
    event StakeWithdrawn(address indexed voter, uint amount);
    event PollUpdated(string newQuestion, string[] newOptions);

    constructor() {
        owner = msg.sender;
        question = "Which blockchain do you prefer?";
        options.push("Ethereum");
        options.push("Solana");
        options.push("Polygon");
        votingOpen = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this");
        _;
    }

    modifier votingActive() {
        require(votingOpen, "Voting has ended");
        _;
    }

    function stakeAndVote(uint optionIndex) external payable votingActive {
        require(msg.value > 0, "Stake some ETH to vote");
        require(optionIndex < options.length, "Invalid voting option");

        stakes[msg.sender] += msg.value;
        votes[optionIndex] += msg.value;

        emit Voted(msg.sender, optionIndex, msg.value);
    }

    function closeVoting() external onlyOwner {
        votingOpen = false;
        emit VotingClosed();
    }

    function withdraw() external {
        require(!votingOpen, "Withdrawals allowed only after voting ends");
        uint256 amount = stakes[msg.sender];
        require(amount > 0, "No stake to withdraw");

        stakes[msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit StakeWithdrawn(msg.sender, amount);
    }

    function getVotes() external view returns (uint256[] memory) {
        uint256[] memory results = new uint256[](options.length);
        for (uint i = 0; i < options.length; i++) {
            results[i] = votes[i];
        }
        return results;
    }

    function getLeadingOption() external view returns (string memory leadingOption, uint256 voteCount) {
        uint256 highest = 0;
        uint256 index = 0;
        for (uint i = 0; i < options.length; i++) {
            if (votes[i] > highest) {
                highest = votes[i];
                index = i;
            }
        }
        return (options[index], highest);
    }

    function updatePoll(string memory newQuestion, string[] memory newOptions) external onlyOwner {
        require(votingOpen, "Cannot update after voting has started");

        delete options;
        question = newQuestion;

        for (uint i = 0; i < newOptions.length; i++) {
            options.push(newOptions[i]);
        }

        emit PollUpdated(newQuestion, newOptions);
    }

    function getOptions() external view returns (string[] memory) {
        return options;
    }
}
