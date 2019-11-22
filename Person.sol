pragma solidity ^0.4.4;

contract Person {
 uint _height;
 uint _age;
 address _owner;

 function Person() {

   _height = 180;
   _age = 29;
   _owner = msg.sender;
 }

 function owner()
   constant
   public
   returns
   (address)
 {
   return _owner;
 }

 function setHeight(uint height) {
   _height = height;
 }

 function height() constant returns (uint) {
   return _height;

 }

 function setAge(uint age) {
   _age = age;

 }
 function age() constant returns (uint) {
   return _age;
 }
 function kill()
 public
  {
   if (_owner == msg.sender) {
   // require (selfdestruct = payable)
   selfdestruct (_owner);
   }
 }

}
