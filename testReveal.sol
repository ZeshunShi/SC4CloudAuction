contract AuctionManagement {

    struct AuctionItem {
        string cutomerName;
        bytes32 sealedReservePrice;
        string auctionDetails;
        uint customerDeposit; 
    }
    mapping(address => AuctionItem) public auctionItemStructs;
    address [] public customerAddresses;

    function setupAuction (string memory _customerName, string memory _auctionDetails, bytes32 _sealedReservePrice) 
        public
        payable
        // checkCustomer(msg.sender)
        // checkDeposit(msg.value)
        // checkState(AuctionState.fresh)
        returns(bool setupAuctionSuccess)
    {
        require (_sealedReservePrice != 0 && bytes(_auctionDetails).length > 0);
        require (customerAddresses.length == 0);
        require (msg.value >= 10);
        auctionItemStructs[msg.sender].cutomerName = _customerName;
        auctionItemStructs[msg.sender].sealedReservePrice = _sealedReservePrice;
        auctionItemStructs[msg.sender].auctionDetails = _auctionDetails;
        auctionItemStructs[msg.sender].customerDeposit = msg.value;
        customerAddresses.push(msg.sender);
        return true;        
    }

    struct Bid {
        string providerName;
        bytes32 sealedBid;
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
        require (msg.value >= 10);
        bidStructs[msg.sender].sealedBid = _sealedBid;
        bidStructs[msg.sender].providerName = _providerName;
        bidStructs[msg.sender].bidderDeposit = msg.value;
        bidderAddresses.push(msg.sender);
        return true;
    }
    
    uint public reservePrice;
    function revealReservePrice (string memory _customerName, uint _reservePrice, uint _customerPassword)
        public
        payable
        // checkTimeAfter(bidEnd)
        // checkTimeBefore(revealEnd)
        // checkCustomer(msg.sender)
        // checkBidderNumber(bidderAddresses.length > 5 && customerAddresses.length == 1)
        returns(uint)
    {
        require (_reservePrice != 0 && _customerPassword != 0);
        require (keccak256(abi.encodePacked(auctionItemStructs[msg.sender].cutomerName)) == keccak256(abi.encodePacked(_customerName)));
        if (keccak256(abi.encodePacked(_reservePrice, _customerPassword)) == auctionItemStructs[msg.sender].sealedReservePrice){
            reservePrice = _reservePrice;
        }
        return reservePrice;
    }
    
    address payable [] public revealedBidders;
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
        if (keccak256(abi.encodePacked(_bid, _providerPassword)) == bidStructs[msg.sender].sealedBid){
            // revealedBids[msg.sender] = _bid;
            revealedBidders.push(msg.sender);
            revealedBids.push(_bid);
        }
    }
    
    function test1() public view returns(address payable [] memory, uint[] memory){
        return (revealedBidders,revealedBids);
    }
    
    // function test2() public view returns(uint[] memory){
    //     return revealedBids;
    // }



    address payable [] public winnerBidders;
    address payable [] public loserBidders;
    uint [] public winnerBids;
    uint [] public loserBids;
    mapping(address => uint) refund;
        
    function sortBidsByAscending () 
        public
        // checkTimeAfter(bidEnd)
        // checkTimeBefore(revealEnd)
        // checkAuctioner(msg.sender = owner)
        // checkBidderNumber(revealedBidders.length > k)
        returns(address payable [] memory)
    {
        bool exchanged;
        uint i;
        uint j;  
        for (uint i=0; i < revealedBids.length - 1; i++) {
            exchanged = false;
            for (j =0; j < revealedBids.length-i-1; j++){
                if (revealedBids[j] > revealedBids[j+1]){
                    (revealedBids[j], revealedBids[j+1]) = (revealedBids[j+1], revealedBids[j]);
                    (revealedBidders[j], revealedBidders[j+1]) = (revealedBidders[j+1], revealedBidders[j]);
                    exchanged = true;
                }
            }
                if(exchanged==false) break;
        }
        // return revealedBidders;
        
        uint m;
        uint n; 
        for (uint m=0; m < 2; m++) {
            winnerBids[m]=revealedBids[m];
            winnerBidders[m]=revealedBidders[m];
        }
        return winnerBidders;
        
        // uint sumBids;
        // for(uint t=0;t < winnerBids.length;t++){
        //     sumBids += winnerBids[t];
        // }
        // require(sumBids < reservePrice);
        // for (uint n=2; n < revealedBidders.length - 1; n++) {
        //     loserBids.push() = revealedBids[n];
        //     loserBidders.push() = revealedBidders[n];
        // }            
        // // return loserBidders;
        // for (uint o=0; o < loserBidders.length - 1; o++) {
        //     refund[loserBidders[o]] = bidStructs[loserBidders[o]].bidderDeposit;
        //     loserBidders[o].transfer(refund[loserBidders[o]]);  // check bug
        // }
    }
    
    
    
}