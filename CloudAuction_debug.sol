pragma solidity > 0.5.0;

contract AuctionManagement {

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// phase1: initialize auction contract, set auction procedures
    address payable public auctioneer;
    uint public initialTime;
    uint public registeEnd;
    uint public biddingEnd;
    uint public revealEnd;
    uint public refundEnd;
    bool public auctionStarted;
    enum AuctionState { fresh, started, publishEnd, registeEnd, bidEnd, revealEnd, monitored, finished } // update with normal auction procedures 

    constructor(uint _registeTime, uint _biddingTime, uint _revealTime, uint _refundTime) 
        public 
    {
        require (_registeTime > 0);
        require (_biddingTime > 0);
        require (_revealTime > 0);
        require (_refundTime > 0);
        
        auctioneer = msg.sender;
        initialTime = now;
        registeEnd = initialTime + _registeTime;
        biddingEnd = registeEnd + _biddingTime;
        revealEnd = biddingEnd + _revealTime;
        refundEnd = revealEnd + _refundTime;

        auctionStarted = false;
        // AuctionState = fresh;
    }
    
    function getAuctionInformation() public view returns(uint, uint, uint, uint, uint) {
        return (initialTime, registeEnd, biddingEnd, revealEnd, refundEnd);
    }
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// phase2: publish auction item.
    struct AuctionItem {
       bytes32  sealedReservePrice;
        string  auctionDetails;
        uint  customerDeposit; 
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
        AuctionItemStructs[msg.sender].customerDeposit = msg.value;
        customerAddresses.push(msg.sender);
        return true;        
    }
    function viewCustomerAddressesLength() public view returns(uint){
        return bidderAddresses.length;
    }
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// phase3: normal user register as bidders (providers).

    enum ProviderState {Ready, Candidate, Absent}
    struct Bidder {
        uint id; // the id of the provider in the address pool
        bool registered;    ///true: this provider has registered     
        int8 reputation; //the reputation of the provider, the initial value is 0
        ProviderState state;  // the current state of the provider
    }
    mapping (address => Bidder) providerCrowd;
    address [] public providerAddrs;    ////the address pool of providers, which is used for registe new providers in the auction
    
    function bidderRegister () 
        public
        // checkProviderNotRegistered(msg.sender)
        // checkAuctionPublished
        returns(bool success) 
    {
        providerCrowd[msg.sender].id = providerAddrs.length;
        providerCrowd[msg.sender].reputation = 0;
        providerCrowd[msg.sender].state = ProviderState.Ready;
        providerCrowd[msg.sender].registered = true;
        providerAddrs.push(msg.sender);
    }
    function viewProviderAddrsLength() public view returns(uint){
        return bidderAddresses.length;
    }
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// phase4: registered provoders submit sealed bids as well as deposit money.

    struct Bid {
        bytes32 sealedBid;
        string  providerName;
        uint bidderDeposit;
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
        require (bidderAddresses.length <= 20);
        bidStructs[msg.sender].sealedBid = _sealedBid;
        bidStructs[msg.sender].providerName = _providerName;
        bidStructs[msg.sender].bidderDeposit = msg.value;
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
    //     return address(auctioneer).balance;
    // }
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// phase5: reveal, sorting, and pay back the deposit money.

    function revealReservePrice (bytes32 _reservePrice, uint _customerPassword)
        public
        payable
        // checkTimeAfter(bidEnd)
        // checkTimeBefore(revealEnd)
        // checkCustomer(msg.sender)
    {
        if(keccak256(abi.encodePacked(_reservePrice, _customerPassword)) == sealedReservePrice){
            reservePrice = _reservePrice;
        }        
    }
        // TBD: check how to iterate the mapping
    function revealProvider (bytes32 _bid, uint _providerPassword)
        public
        payable
        checkTimeAfter(bidEnd)
        checkTimeBefore(revealEnd)
        checkProvider(msg.sender)
    {

        for (uint i=0; i < bidderAddresses.length; i++) {
            totalBids += bidStructs[bidderAddresses[i]];
        return totalBids;
        }

        if(keccak256(abi.encodePacked(_bid, _providerPassword)) == sealedBids[msg.sender]){
            revealedBids[msg.sender] = _bid;
        }        
    }
        /**
     * Sorting Interface::
     * This is for sorting the bidding prices by ascending of different providers
     * */

    using SortingMethods for uint[];
    uint[] bidArray;

    // this function add the bids from different providers
    function addBids (uint[] memory _ArrayToAdd) public {
        for (uint i=0; i< _ArrayToAdd.length; i++){
            bidArray.push(_ArrayToAdd[i]);
        }
    }

    function sortByPriceAscending() public returns(uint[] memory){
        bidArray = bidArray.heapSort();
        return bidArray;
    }
    
}