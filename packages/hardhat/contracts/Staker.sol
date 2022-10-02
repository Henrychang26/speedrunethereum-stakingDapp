// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;


  //Events

  event Stake(address indexed sender, uint256 amount);
  event Received(address, uint);
  event Execute(address indexed sender, uint256 amount);

  //Mappings
  mapping(address => uint256) public balance;
  mapping(address => uint256) public depositTimeStamp;


  //Variables
  uint256 public constant rewardRatePerBlock = 0.1 ether;
  uint256 public withdrawalDeadline = block.timestamp + 120 seconds;
  uint256 public claimDeadline = block.timestamp + 240 seconds;
  uint256 public currentBlock= 0;
  uint256 public threshold;


  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
      threshold = 20 ether;
  }

  //Modifiers
  modifier withdrawalDeadlineReached(bool requireReached){
    uint256 timeRemaining = withdrawalTimeLeft();
    if(requireReached){
      require( timeRemaining == 0, "Withdrawal period is not reached yet");
    }else{
      require(timeRemaining >0, "Withdrawal Period has been reached");
    }
    _;
  }

  modifier claimDeadlineReached(bool requireReached){
    uint256 timeRemaining = withdrawalTimeLeft();
    if(requireReached){
      require(timeRemaining == 0, "Claim deadline is not reached yet");
    }else{
      require(timeRemaining >0, "Claim deadline is reached");
    }
    _;
  }

  modifier thresholdNotMet (){
    require(threshold <= 20 ether);
    _;
  }

  modifier notCompleted(){
    bool completed = exampleExternalContract.completed();
    require(!completed, "Stake already completed!");
    _;
  }


  function withdrawalTimeLeft() public view returns(uint256 withdrawalTimeLeft){
    if(block.timestamp >= withdrawalDeadline){
      return(0);
      }else{
        return (withdrawalDeadline - block.timestamp);
      }
    }

  function claimPeriodLeft() public view returns(uint256 claimPeriodLeft){
    if(block.timestamp >= claimDeadline){
      return(0);
    }else{
      return(claimDeadline - block.timestamp);
    }
  }

  function stake () public payable withdrawalDeadlineReached(false) claimDeadlineReached(false){
    balance[msg.sender] = balance[msg.sender] + msg.value;
    depositTimeStamp[msg.sender] = block.timestamp;
    emit Stake(msg.sender, msg.value);
  }

  function withdraw() public withdrawalDeadlineReached(true) claimDeadlineReached(false) notCompleted{
    require(balance[msg.sender] >0, "You have no balance to withdraw");
    uint256 individualBalance = balance[msg.sender];
    uint256 indBalanceRewards = individualBalance + ((block.timestamp-depositTimeStamp[msg.sender])*rewardRatePerBlock);
    balance[msg.sender] = 0;

    //transfer all ETH via call (not transfer)

    (bool sent, bytes memory data) = msg.sender.call{value: indBalanceRewards}("");
    require(sent, "RIP; withdrawal failed");
  }

  function execute() public claimDeadlineReached(true) notCompleted{
    uint256 contractBalance = address(this).balance;
    exampleExternalContract.complete{value: address(this).balance}();
  }

  function killTime() public {
    currentBlock = block.timestamp;
  }
  receive() external payable {
      emit Received(msg.sender, msg.value);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )


  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`


  // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance

  function thresholdNotMetWithdraw() public thresholdNotMet withdrawalDeadlineReached(true){
    require(balance[msg.sender > 0]);
    uint256 individualBalance = balance[msg.sender];
    individualBalance.transfer(msg.sender);
  }


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend

  function timeLeft() public view returns (){
    return claimDeadline - block.timestamp;
  }


  // Add the `receive()` special function that receives eth and calls stake()

}
