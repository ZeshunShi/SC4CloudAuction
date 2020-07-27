contract AuctionManagement {

    struct AuctionItem {
       bytes32  sealedReservePrice;
        string  auctionDetails;
        uint  customerDeposit; 
    }
    mapping(address => AuctionItem) public auctionItemStructs;
    address [] public customerAddresses;

    function setupAuction (string memory _auctionDetails, bytes32 _sealedReservePrice) 
        public
        payable
        // checkCustomer(msg.sender)
        // checkDeposit(msg.value)
        // checkState(AuctionState.fresh)
        returns(bool setupAuctionSuccess)
    {
        require (_sealedReservePrice != 0 && bytes(_auctionDetails).length > 0);
        require (customerAddresses.length == 0);
        auctionItemStructs[msg.sender].sealedReservePrice = _sealedReservePrice;
        auctionItemStructs[msg.sender].auctionDetails = _auctionDetails;
        auctionItemStructs[msg.sender].customerDeposit = msg.value;
        customerAddresses.push(msg.sender);
        return true;        
    }

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
        require (_sealedBid != 0 && bytes(_providerName).length > 0);   
        require (bidderAddresses.length <= 20);
        bidStructs[msg.sender].sealedBid = _sealedBid;
        bidStructs[msg.sender].providerName = _providerName;
        bidStructs[msg.sender].bidderDeposit = msg.value;
        bidderAddresses.push(msg.sender);
        return true;
    }
    
    uint public reservePrice;
    function revealReservePrice (uint _reservePrice, uint _customerPassword)
        public
        payable
        // checkTimeAfter(bidEnd)
        // checkTimeBefore(revealEnd)
        // checkCustomer(msg.sender)
        // checkBidderNumber(bidderAddresses.length > 5 && customerAddresses.length == 1)
        returns(uint)
    {
        require (_reservePrice != 0 && _customerPassword != 0);
        if(keccak256(abi.encodePacked(_reservePrice, _customerPassword)) == auctionItemStructs[msg.sender].sealedReservePrice){
            reservePrice = _reservePrice;
        }
        return reservePrice;
    }
    
    address [] public revealedBidders;
    uint [] public revealedBids;
    // mapping(address => uint) public revealedBids;
    
    function revealBids (string memory _providerName, uint _bid, uint _providerPassword)
        public
        payable
        // checkTimeAfter(bidEnd)
        // checkTimeBefore(revealEnd)
        // checkProvider(msg.sender)
        // checkBidderNumber(bidderAddresses.length > 5 && customerAddresses.length == 1)
    {
        require (_bid != 0 && _providerPassword != 0);
        require (keccak256(abi.encodePacked(bidStructs[msg.sender].providerName)) == keccak256(abi.encodePacked(_providerName)));
        if(keccak256(abi.encodePacked(_bid, _providerPassword)) == bidStructs[msg.sender].sealedBid){
            // revealedBids[msg.sender] = _bid;
            revealedBidders.push(msg.sender);
            revealedBids.push(_bid);
        }
    }
    
    function test1() public view returns(address[] memory){
        return revealedBidders;
    }
    
    function test2() public view returns(uint[] memory){
        return revealedBids;
    }
        
    // function sortBidsByAscending () 
    //     public
    //     // checkTimeAfter(bidEnd)
    //     // checkTimeBefore(revealEnd)
    //     // checkProvider(msg.sender)
    //     // checkBidderNumber(revealedBidders.length > 5 && revealedBids.length > 5)
    //     returns(uint[] memory)
    // {
    //     require(revealedBidders.length > 5 && revealedBids.length > 5,"Insufficient reveledBids/revealedBidders to sort");
    //     bool swapped;
    //     uint i;
    //     uint j;  
    //     for (uint i=0; i < revealedBids.length - 1; i++) {
    //         swapped = false;
    //         for (j =0; j < revealedBids.length-i-1; j++){
    //             if (revealedBids[j] > revealedBids[j+1]){
    //                 (revealedBids[j], revealedBids[j+1]) = (revealedBids[j+1], revealedBids[j]);
    //                 (revealedBidders[j], revealedBidders[j+1]) = (revealedBidders[j+1], revealedBidders[j]);
    //                 swapped = true;
    //             }
    //         }
    //             if(swapped==false) break;
    //     }
    // }
}