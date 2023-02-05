//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract CrowdFunding {
    
    address payable public manager; // Manager for the CrowdFund
    mapping(address=>uint) public contributors;  // Mapping for the contributors for the CrowdFund 
    uint public minContro; // minimum controbution for the Fund
    uint public target; //target amout for the Fund
    uint public amtRaised; //total amount raised by the Fund 
    uint public deadline; //the end time for the Fund
    uint public noOfCrontrobutors; // this is to take the average while voting 

    // CONSTRUCTOR 

    constructor (uint _target, uint _deadline ){
        manager = payable(msg.sender);
        minContro = 1 ether;
        target = _target;
        deadline = block.timestamp + _deadline; // this will take the input in seconds and add it to the current timestamp
    }

    // STRUCT FOR THE PROPOSAL 
    
    struct ProposalForTheFund
    {
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping (address => bool) vote;
    }

    mapping (uint => ProposalForTheFund) public proposals;
    uint public numOfProposals; //this will allocate the index for the above proposals 

    //Modifiers 

    // ONLY MANAGER 
    modifier onlyManager() 
    {
        require(msg.sender == manager, "Only manager can access this function");
        _;
    }

    // Functions 

    // Contribute function for the contributors

    function contribute() public payable 
    {
        require(block.timestamp < deadline," Deadline has already passed ");
        require(msg.value > minContro , "You can contribute minimum 1 Ether");

        if(contributors[msg.sender] == 0) // this will check whereter the contributor has already in the noOfContribution variable
        {
            noOfCrontrobutors++;
        }
        contributors[msg.sender] += msg.value;
        amtRaised +=msg.value;
        
    }

    // Fuction to get the contract balance

    function contractBalance() public view returns(uint ) 
    {
        return address(this).balance; // this = the contract balance
    }

    // Function to get the Money Back if the contract does not meet the target before the deadline 

    function reFund() public 
    {
        require(block.timestamp > deadline && amtRaised < target, "You are eligible for the refund for your contribution");
        require(contributors[msg.sender] > 0, "You had not contributed for the Fund");

        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);

        contributors[msg.sender] = 0; // this will prevent the user to make repetative refund request

    }

    function createProposal(string memory _description, address payable _recipients, uint _value) public onlyManager // this will take all the required inputs for the struct
    {   
        /// @dev Uncomment the line below for the proposal time testing 
        // require(block.timestamp > deadline);// proposal can be crafted only if the deadline is passed
        ProposalForTheFund storage newProposal = proposals[numOfProposals];
        numOfProposals++ ;
        newProposal.description = _description;
        newProposal.recipient = _recipients;
        require(amtRaised > _value, "Please enter a amount less then contract balance");
        newProposal.value = _value;
        newProposal.completed = false;
        newProposal.noOfVoters = 0;

    }


    function voteForProposal(uint _proposalNum) public
    {

        require(numOfProposals > _proposalNum );//This will here ensure no one caste's vote for proposal number that is not yet proposed by the manager
        require (contributors[msg.sender] > 0 , "You must be a contributor"); //check whethere he is a contirbutor or not 
        ProposalForTheFund storage thisProposal = proposals[_proposalNum]; // create new Proposal variable for add new voters;
        require(thisProposal.vote[msg.sender] == false, " You have already casted your vote");    //checks whether the contributor has already voted for this proposal or not
        thisProposal.vote[msg.sender] = true; // this will cast the vote for the contributor.
        thisProposal.noOfVoters++; // this will increment the number of the voters if the vote is casted.
    }

    function makePayment(uint _proposalNum) public onlyManager
    {

        require(amtRaised >= target,"The target has not met yet");
        ProposalForTheFund storage thisProposal = proposals[_proposalNum];
        require(thisProposal.completed == false , " The request has been Completed");
        require(thisProposal.noOfVoters > noOfCrontrobutors/2, "Majority doesnot support the proposal");
        thisProposal.recipient.transfer(thisProposal.value);
        thisProposal.completed = true;

    }

}