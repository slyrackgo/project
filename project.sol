pragma solidity ^0.8.0;

contract StartupInvestment {
    address payable public startup;
    address payable public investor;
    uint public fundingGoal;
    uint public investmentDeadline;
    uint public amountRaised;
    mapping(address => uint) public balanceOf;
    bool public fundingGoalReached = false;
    bool public investmentClosed = false;

    event FundingGoalReached(address recipient, uint totalAmountRaised);
    event InvestmentReceived(address backer, uint amount, bool isContribution);
    event InvestmentRefunded(address backer, uint amount);

    /* Constructor */
    constructor(
        address payable startupAddress,
        uint fundingGoalInEthers,
        uint investmentPeriodInDays
    ) {
        startup = startupAddress;
        fundingGoal = fundingGoalInEthers * 1 ether;
        investmentDeadline = block.timestamp + (investmentPeriodInDays * 1 days);
    }

    /* The function that investors will call to invest in the startup */
    function invest() public payable {
        require(!investmentClosed);
        require(block.timestamp <= investmentDeadline);
        require(msg.value > 0);

        balanceOf[msg.sender] += msg.value;
        amountRaised += msg.value;
        emit InvestmentReceived(msg.sender, msg.value, true);
    }

    /* The function that the startup will call to withdraw funds after the investment period has ended */
    function withdraw() public {
        require(investmentClosed);
        require(fundingGoalReached);
        require(msg.sender == startup);

        startup.transfer(amountRaised);
    }

    /* The function that investors will call to request a refund if the funding goal has not been reached */
    function refund() public {
        require(investmentClosed);
        require(!fundingGoalReached);
        require(balanceOf[msg.sender] > 0);

        uint amountToRefund = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        msg.sender.transfer(amountToRefund);
        emit InvestmentRefunded(msg.sender, amountToRefund);
    }

    /* The function that will close the investment period and distribute funds to the startup if the funding goal has been reached */
    function close() public {
        require(!investmentClosed);
        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
            emit FundingGoalReached(startup, amountRaised);
            startup.transfer(amountRaised);
        } else {
            fundingGoalReached = false;
        }
        investmentClosed = true;
    }

    /* The function that will return the time remaining until the investment period ends */
    function getTimeRemaining() public view returns (uint) {
        if (block.timestamp >= investmentDeadline) {
            return 0;
        } else {
            return investmentDeadline - block.timestamp;
        }
    }
}
