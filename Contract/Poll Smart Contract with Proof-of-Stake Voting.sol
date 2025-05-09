// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PollWithPoS {
    address public owner;
    string public question;
    string[] public options;
    mapping(address => uint256) public stakes;
    mapping(uint => uint256) public votes;
    mapping(address => bool) public voted;
    mapping(address => uint256) public userVoteOption; 
    bool public votingOpen;

    event Voted(address indexed voter, uint indexed optionIndex, uint amount);
    event VotingClosed();
    event StakeWithdrawn(address indexed voter, uint amount);
    event PollUpdated(string newQuestion, string[] newOptions);
    event PollReset();
    event EmergencyClosed();
    event EmergencyWithdrawal(uint256 amount);

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
        voted[msg.sender] = true;
        userVoteOption[msg.sender] = optionIndex; 

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

    function getLeadingOption() public view returns (string memory leadingOption, uint256 voteCount) {
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

    function getTotalStake() external view returns (uint256 totalStake) {
        return address(this).balance;
    }

    function getUserVoteBalance(address user) external view returns (uint256) {
        return stakes[user];
    }

    function hasVoted(address user) external view returns (bool) {
        return voted[user];
    }

    function resetPoll(string memory newQuestion, string[] memory newOptions) external onlyOwner {
        require(!votingOpen, "Close voting before resetting");

        for (uint i = 0; i < options.length; i++) {
            votes[i] = 0;
        }

        question = newQuestion;
        delete options;
        votingOpen = true;

        for (uint i = 0; i < newOptions.length; i++) {
            options.push(newOptions[i]);
        }

        emit PollReset();
        emit PollUpdated(newQuestion, newOptions);
    }

    function getPollSummary() external view returns (
        string memory _question,
        string[] memory _options,
        uint256[] memory _votes,
        string memory _leadingOption,
        uint256 _leadingVotes
    ) {
        _question = question;
        _options = options;
        _votes = new uint256[](options.length);
        for (uint i = 0; i < options.length; i++) {
            _votes[i] = votes[i];
        }
        (_leadingOption, _leadingVotes) = getLeadingOption();
    }

    function getUserVoteDetails(address user) external view returns (uint256 stakeAmount, bool hasUserVoted) {
        return (stakes[user], voted[user]);
    }

    function getPollStatus() external view returns (bool isVotingOpen) {
        return votingOpen;
    }

    function getWinningMargin() external view returns (uint256 margin) {
        uint256 highest = 0;
        uint256 secondHighest = 0;
        for (uint i = 0; i < options.length; i++) {
            uint256 voteCount = votes[i];
            if (voteCount > highest) {
                secondHighest = highest;
                highest = voteCount;
            } else if (voteCount > secondHighest) {
                secondHighest = voteCount;
            }
        }
        margin = highest - secondHighest;
    }

    function emergencyCloseVoting() external onlyOwner votingActive {
        votingOpen = false;
        emit EmergencyClosed();
    }

    function emergencyWithdraw() external onlyOwner {
        require(!votingOpen, "Voting must be closed before emergency withdraw");
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No funds to withdraw");

        payable(owner).transfer(contractBalance);

        emit EmergencyWithdrawal(contractBalance);
    }

    
    function getUserSelectedOption(address user) external view returns (string memory option) {
        require(voted[user], "User has not voted yet");
        uint256 optionIndex = userVoteOption[user];
        require(optionIndex < options.length, "Invalid option index recorded");
        return options[optionIndex];
    }
}
