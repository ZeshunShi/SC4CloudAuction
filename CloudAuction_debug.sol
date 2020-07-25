pragma solidity > 0.5.0;

contract AuctionManagement {

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    address payable public owner;
    address payable public customer;
    uint public initialTime;
    uint public registeEnd;
    uint public biddingEnd;
    uint public revealEnd;
    uint public refundEnd;
    bool public auctionStarted;

    constructor(address payable _customer, uint _registeTime, uint _biddingTime, uint _revealTime, uint _refundTime) 
        public 
    {
        require (_registeTime > 0);
        require (_biddingTime > 0);
        require (_revealTime > 0);
        require (_refundTime > 0);
        
        owner = msg.sender;
        customer = _customer;
        
        initialTime = now;
        registeEnd = initialTime + _registeTime;
        biddingEnd = registeEnd + _biddingTime;
        revealEnd = biddingEnd + _revealTime;
        refundEnd = revealEnd + _refundTime;

        auctionStarted = false;
        // AuctionState = fresh;
    }
    
    function getAuctionInformation() 
        public
        view
        returns(uint, uint, uint, uint, uint)
    {
        return (initialTime, registeEnd, biddingEnd, revealEnd, refundEnd);
    }
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    struct Bid {
        bytes32 sealedBid;
        uint deposit;
    }
    mapping(address => Bid) public bidStructs;
    address [] public bidderAddresses;

    function submitBids(bytes32 _sealedBid, uint _depositPrice) 
        public
        payable
        returns(bool submitSuccess)
    {
        owner.transfer(msg.value); // todo: change to deposit mapping
        // set bid valuse using our bidStructs mapping
        bidStructs[msg.sender].sealedBid = _sealedBid;
        // set bid deposit using our userStructs mapping
        bidStructs[msg.sender].deposit = _depositPrice;
        // push bidder address into bidderAddresses array
        bidderAddresses.push(msg.sender);
        return true;

        // can also put into modifier in the next phase
        // if (bidderAddresses.length > 5)
        // {
        //     // do something
        // } 
    }
    
     function getBalance() public view returns(uint){
        return address(owner).balance;
    }
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

}