pragma solidity ^0.4.4;

// public internal private

contract Animal {

  uint _weight;
  uint private _height;
  uint internal _age;
  uint public _money;

  /*int public _money will generate:
  function _money() constant returns (uint) {
    return 120;
  } */

  function test() constant returns (int) {
    return _weight;
  }

  function test1() constant public returns (int) {
    return _weight;
  }

  function test2() constant internal returns (int) {
    return _weight;
  }

  function test3() constant private returns (int) {
    return _weight;
  }

  function testInternal() constant returns () {
    return this.test()
  }

  function testInternal1() constant returns () {
    return this.test1()
  }

  function testInternal2() constant returns () {
    return test2()
  }

  function testInternal3() constant returns () {
    return test3()
  }

}
