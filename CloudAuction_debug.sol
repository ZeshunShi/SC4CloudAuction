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
    struct AuctionItem {
       bytes32  sealedReservePrice;
        string  auctionDetails;
        uint  guaranteeDeposit; 
    }
    mapping(address => AuctionItem) public AuctionItemStructs;
    address [] public customerAddresses;


    function setupAuction (string memory _auctionDetails, bytes32 _sealedReservePrice) 
        public
        payable
        // checkCustomer(msg.sender)
        // checkDeposit(msg.value)
        // checkState(AuctionState.fresh) 
        returns(bool setupAuctionSuccess)
    {
        require (_sealedReservePrice != 0);
        require (customerAddresses.length == 0);
        AuctionItemStructs[msg.sender].sealedReservePrice = _sealedReservePrice;
        AuctionItemStructs[msg.sender].auctionDetails = _auctionDetails;
        AuctionItemStructs[msg.sender].guaranteeDeposit = msg.value;
        customerAddresses.push(msg.sender);
        return true;        
    }
     function viewCustomerLength() public view returns(uint){
         return bidderAddresses.length;
    }
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// register
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    struct Bid {
        bytes32 sealedBid;
        string  providerName;
        uint deposit;
    }
    mapping(address => Bid) public bidStructs;
    address [] public bidderAddresses;

    function submitBids(string memory _providerName, bytes32 _sealedBid) 
        public
        payable
        // checkProvider(msg.sender)
        // checkDeposit(msg.value)
        // checkState(AuctionState.fresh) 
        returns(bool submitSuccess)
    {
        require (_sealedBid != 0);
        require (bidderAddresses.length >= 0 && bidderAddresses.length <= 20);
        bidStructs[msg.sender].sealedBid = _sealedBid;
        bidStructs[msg.sender].providerName = _providerName;
        bidStructs[msg.sender].deposit = msg.value;
        bidderAddresses.push(msg.sender);
        return true;

        // can also put into modifier in the next phase
        // if (bidderAddresses.length > 5)
        // {
        //     // do something
        // } 
    }
    
    
     function viewBiddersLength() public view returns(uint){
         return bidderAddresses.length;
    }
    //  function getBalance() public view returns(uint){
    //     return address(owner).balance;
    // }
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

}