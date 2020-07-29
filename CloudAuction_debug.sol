pragma solidity > 0.5.0;

/**
 * The AuctionManagement contract manage the lifecycle of cloud auction.
 */
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
        string cutomerName;
        bytes32 sealedReservePrice;
        string auctionDetails;
        uint customerDeposit; 
    }
    mapping(address => AuctionItem) public auctionItemStructs;
    address payable [] public customerAddresses;

    function setupAuction (string memory _customerName, string memory _auctionDetails, bytes32 _sealedReservePrice) 
        public
        payable
        // checkCustomer(msg.sender)
        // checkDeposit(msg.value)
        // checkState(AuctionState.fresh)
        returns(bool setupAuctionSuccess)
    {
        require (_sealedReservePrice.length != 0 && bytes(_auctionDetails).length > 0);
        require (customerAddresses.length == 0);
        require (msg.value >= 10e18);
        auctionItemStructs[msg.sender].cutomerName = _customerName;
        auctionItemStructs[msg.sender].sealedReservePrice = _sealedReservePrice;
        auctionItemStructs[msg.sender].auctionDetails = _auctionDetails;
        auctionItemStructs[msg.sender].customerDeposit = msg.value;
        customerAddresses.push(msg.sender);
        return true;        
    }
    function viewCustomerAddressesLength() public view returns(uint){
        return bidderAddresses.length;
    }
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// phase3: normal user register as bidders (providers).
    enum ProviderState { Ready, Candidate, Absent }
    struct Bidder {
        uint id; // the id of the provider in the address pool
        bool registered;    ///true: this provider has registered     
        int8 reputation; //the reputation of the provider, the initial value is 0
        ProviderState state;  // the current state of the provider
    }
    mapping (address => Bidder) public providerCrowd;
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
        return providerAddrs.length;
    }
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// phase4: registered provoders submit sealed bids as well as deposit money.
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
        require (_sealedBid.length != 0 && bytes(_providerName).length > 0);   
        require (bidderAddresses.length <= 20);
        require (msg.value >= 10e18);
        bidStructs[msg.sender].sealedBid = _sealedBid;
        bidStructs[msg.sender].providerName = _providerName;
        bidStructs[msg.sender].bidderDeposit = msg.value;
        bidderAddresses.push(msg.sender);
        return true;
    }
    function viewBiddersLength() public view returns(uint){
        return bidderAddresses.length;
    }
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// phase5: reveal, sorting, and pay back the deposit money.
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
        require (_reservePrice > 0 && _customerPassword != 0);
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
        require (_bid > 0 && _providerPassword != 0);
        require (keccak256(abi.encodePacked(bidStructs[msg.sender].providerName)) == keccak256(abi.encodePacked(_providerName)));
        if (keccak256(abi.encodePacked(_bid, _providerPassword)) == bidStructs[msg.sender].sealedBid){
            // revealedBids[msg.sender] = _bid;
            revealedBidders.push(msg.sender);
            revealedBids.push(_bid);
        }
    }
    function testReveal() public view returns(address payable [] memory, uint[] memory){
        return (revealedBidders,revealedBids);
    }
    
    address payable [] public winnerBidders;
    address payable [] public loserBidders;
    uint [] public winnerBids;
    uint [] public loserBids;
    mapping(address => uint) refund;
        
    function placeBids () 
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

        uint sumBids;
        for(uint i=0; i < 5; i++){
            sumBids += revealedBids[i];
        }
        
        // require(sumBids <= reservePrice, "The lowest k bids do not meet the requirements of the customer's reserve Price, auction failed.");  // pay back to everybody, restart the auction
        for (uint i=0; i < revealedBidders.length; i++) {
            if( i< 5 && sumBids <= reservePrice) {
                winnerBids.push() = revealedBids[i];
                winnerBidders.push() = revealedBidders[i];
            } else if( i >= 5 && sumBids <= reservePrice ){
                loserBids.push() = revealedBids[i];
                loserBidders.push() = revealedBidders[i];
            } else if( sumBids > reservePrice ){
                loserBids.push() = revealedBids[i];
                loserBidders.push() = revealedBidders[i];
            }
        }
        return loserBidders;
        return winnerBidders;
    }

    function testWinner() public view returns(address payable [] memory, uint[] memory){
        return (winnerBidders,winnerBids);
    }
    function testLoser() public view returns(address payable [] memory, uint[] memory){
        return (loserBidders,loserBids);
    }
    
    function refundDeposit()
        public  
    {
        for (uint i=0; i < loserBidders.length; i++) {
            if (bidStructs[loserBidders[i]].bidderDeposit > 0){
                refund[loserBidders[i]] = bidStructs[loserBidders[i]].bidderDeposit;
                loserBidders[i].transfer(refund[loserBidders[i]]);
                bidStructs[loserBidders[i]].bidderDeposit = 0;
            }
        }
        if (winnerBidders.length == 0) {
            refund[customerAddresses[0]] = auctionItemStructs[customerAddresses[0]].customerDeposit;
            customerAddresses[0].transfer(refund[customerAddresses[0]]);
            auctionItemStructs[customerAddresses[0]].customerDeposit = 0;
        }
    }
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// phase6: generate SLA and witness contract.
    struct ContractInfo {
        uint id; // the id of the contract in the address pool
        bool valid;    ///true: this contract has been valided
    }    
    mapping(address => ContractInfo) SLAContractPool;
    address payable [] public SLAContractAddresses;


    function genSLAContract() 
        public 
        // checkWinnerProvider(msg.sender)
        returns(address)
    {
        require (bidStructs[msg.sender].bidderDeposit > 0);      
        address newSLAContract = address (new CloudSLA(this, msg.sender, customerAddresses[0]));
        SLAContractPool[msg.sender].id = SLAContractAddresses.length;
        SLAContractPool[newSLAContract].valid = true; 
        SLAContractAddresses.push(msg.sender);
        emit SLAContractGen(msg.sender, now, newSLAContract);
        return newSLAContract;
    }

    // mapping(address => ContractInfo) witnessContractPool;
    // address payable [] public witnessContractAddresses;
    // function genWitnessContract() 
    //     public 
    //     // checkWinnerProvider(msg.sender)
    //     returns(address)
    // {
    //     require (SLAContractPool[msg.sender].valid = true);        
    //     address newWitnessContract = new CloudSLA(this, msg.sender, 0x0);
    //     witnessContractPool[msg.sender].id = witnessContractAddresses.length;
    //     witnessContractPool[newWitnessContract].valid = true; 
    //     witnessContractAddresses.push(msg.sender);
    //     emit SLAContractGen(msg.sender, now, newWitnessContract);
    //     return newWitnessContract;
    // }


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

}


/**
 * The CloudSLA contract does this and that...
 */
contract CloudSLA {
    address public customer;
    address public provider;
    AuctionManagement public MainContract;
    constructor(AuctionManagement _auctionManagement, address _provider, address _customer)
        public
    {
        provider = _provider;
        customer = _customer;
        MainContract = _auctionManagement;
    }
}
