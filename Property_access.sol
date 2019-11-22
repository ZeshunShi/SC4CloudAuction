pragma solidity ^0.4.4;

// public internal private

contract Person {

  uint internal _age;
  uint _weight;
  uint private _height;
  uint public _money;

  function money() constant returns (uint) {
    return 120;
  }

}
