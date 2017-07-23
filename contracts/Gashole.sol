pragma solidity ^0.4.4;

contract Gashole {

  function request(uint requestId, uint blockNumber) returns (uint, uint) {
    //requestId is what type of request (max, min, avg)
    return (requestId, blockNumber);
  }

  function submit(uint answer) returns (uint) {
    return answer;
  }

  function challenge(uint answer) returns (uint) {
    return answer;
  }

}
