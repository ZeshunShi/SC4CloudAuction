pragma solidity ^0.5.0;
    /**
     * The CloudAuction contract is a smart contract on Ethereum that supports the decentralized cloud providers to auction and bid the cloud services (IaaS). 
     * examanier/auditor/arbiter
     */


// Some imported solidity libraries used in this contract.
import "./library/librarySorting.sol";


contract MultiCloudAuction {


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    string public auctionDetails; // the details of the service requirements that need to be auctioned
    uint8 public amount; // how many providers the customer need for the auction game
    
    bytes32 public sealedBid; // the sealed bidding price of the provider 
    bytes32 public sealedReservePrice; // the sealed reservce price of the customer
    uint public guaranteeDeposit; // this is the deposit money to guarantee providers/customer will sign the SLA after win the bids, avoids bad intention bids or publish

    enum ProviderState {Ready, Busy, Absent} //{ Offline, Online, Candidate, Busy }

    struct Provider {
        uint index; // the index of the provider in the address pool, if it is registered
        bool registered;    ///true: this provider has registered.         
        int8 reputation; //the reputation of the provider, the initial value is 0.
        ProviderState state;  // the current state of the provider
    }

    mapping (address => Provider) providerCrowd;

    address [] public providerAddrs;    ////the address pool of providers, which is used for registe new providers in the auction 

    bool public auctionStarted; 



    enum AuctionState { fresh, started, publishEnd, registeEnd, bidEnd, revealEnd, monitored, finished }
  
    ////this is to log event that _who modified the Auction state to _newstate at time stamp _time
    event AuctionStateModified(address indexed _who, uint _time, State _newstate);
    emit AuctionStateModified(msg.sender, now, State.started);    
    emit AuctionStateModified(msg.sender, now, State.registEnd);
    emit AuctionStateModified(msg.sender, now, State.bidEnd);
    emit AuctionStateModified(msg.sender, now, State.revealEnd);
    emit AuctionStateModified(msg.sender, now, State.monitored);
    emit AuctionStateModified(msg.sender, now, State.finished);




///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    address payable public customer;
    uint public registeEnd;
    uint public biddingEnd;
    uint public revealEnd;
    uint public withdrawEnd;
    //  the constructors for the auction smart contract.
    constructor(address payable _customer, uint _registeTime, uint _biddingTime, uint _revealTime, uint _refundTime) 
        public 
    {
        require (_inviteTime > 0);
        require (_biddingTime > 0);
        require (_revealTime > 0);
        require (_withdrawTime > 0);    

        customer = _customer;

        registeEnd = now + _registeTime
        biddingEnd = registeEnd + _biddingTime;
        revealEnd = biddingEnd + _revealTime;
        refundEnd = revealEnd + _refundTime;

        auctionStarted = false;
        AuctionState = fresh;
    }


   /**
     * Customer Interface:
     * This is for the customer to set up the auction and wait for the providers to bid. The customer need to place a blinded reserve price with keccak256(abi.encodePacked(_reservePrice, _customerPassword))
     * */
    function setupAuction (string _auctionDetails, uint _sealedReservePrice) 
        public
        payable
        checkCustomer(msg.sender)
        checkDeposit(depositPrice)
        checkState(AuctionState.fresh) 
    {
        require (_sealedReservePrice > 0);  
        sealedReservePrice = _sealedReservePrice;  
        auctionDetails = _auctionDetails;
        guaranteeDeposit += msg.value;  // customize the value
        AuctionState = State.published;
        emit AuctionStateModified(msg.sender, now, State.published);
    }

   /**
     * Customer Interface::
     * This is for the customer to cancel the auction
     * */
    function cancelAuction () 
        public
        payable
        checkState(AuctionState.fresh)
        checkCustomer(msg.sender)
        checkTimeBefore(started)
    {
        if(depositPrice > 0)
        {
            msg.sender.transfer(depositPrice);
            depositPrice = 0;
        }      
        AuctionState = State.Fresh;
    }

    /**
     * Normal User Interface::
     * This is for the normal user to register as a Cloud provider in the auction game
     * */
    function bidderRegister () 
        public
        checkProviderNotRegistered(msg.sender)
        checkServiceInformation
        view
        returns(bool success) 
    {
        providerCrowd[msg.sender].index = providerAddrs.push(msg.sender) - 1; // check why -1
        providerCrowd[msg.sender].reputation = 0;
        providerCrowd[msg.sender].state = ProviderState.Ready;
        providerCrowd[msg.sender].registered = true;
        return true;
    }
    

    function auctionStart () 
        public
        checkServiceInformation
        checkBidderNumber(2*k)
    {
        require (!auctionStarted);
        if (providerAddrs.length <= 2*k && providerAddrs.length >= k)
        {
            auctionStarted = true; 
        }
        emit AuctionStateModified(msg.sender, now, State.started);    
    }

   /**
     * Providers Interface::
     * This is for the providers to bid (sealed) for the auction goods (service). Place a blinded bid with keccak256(abi.encodePacked(_bid, _providerPassword)), this action can be done off chain.
     * */
    function submitBids (bytes32 _sealedBid) 
        public
        payable
        checkTimeAfter(registeEnd)
        checkTimeBefore(bidEnd)
        checkProvider(msg.sender)
    {
        
        require (_sealedBid > 0);
        sealedBids[msg.sender].push = _sealedBid;
        deposit[msg.sender] = msg.value;   // check how to define the amount msg.value

        if (sealedBids.length >= k)
        {
            emit AuctionStateModified(msg.sender, now, State.bidEnd);
        }       
    }

    function revealCustomer (byte32 _reservePrice, uint _customerPassword)
        public
        payable
        checkTimeAfter(bidEnd)
        checkTimeBefore(revealEnd)
        checkCustomer(msg.sender)
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
        for () {

        }
        if(keccak256(abi.encodePacked(_bid, _providerPassword)) == sealedBids[msg.sender]){
            revealedBids[msg.sender] = _bid;
        }        
    }


    /**
     * Sorting Interface::
     * This is for sorting the bidding prices by ascending of  different providers
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



        





    


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // check whether the servide information has been published
    modifier checkServiceInformation () 
    { 
        require (auctionDetails != null && auctionDetails.length() != 0); 
        "The auction service information has not been uploaded by customer"; 
    }
    
    // check whether it is a registered provider
    modifier checkProviderNotRegistered(address _provider)
    {
        require(!providerCrowd[_provider].registered);
        "The provider is not registered for the auction";
    }

    // check the Provider's Reputation
    modifier checkProviderReputation () 
    { 
        require (reputation >= 0); 
        "The provider is not qualified to participate the auction due to bad reputation; 
    }

    // check the bidders number. The minimum biiders number is set to 2*k and can be customized later 
    modifier checkBidderNumber(uint _amount) 
    { 
        require (providerAddrs.length > _amount); 
        "The number of registered providers (bidders) is not enough to start the auction";
    }

    modifier checkTimeBefore(uint _time) 
    {   
        require(now < _time);
         "The time is not before the time point"; 
    }

    modifier checkTimeAfter(uint _time)
    {    
        require(now > _time);
        "The time is not after the time point"; 
    }

    modifier checkProvider(address _user) 
    {    
        require(Provider[_user].registered);
        "The current user is not a registered provider";
    }

    modifier checkCustomer(address _user) { 
        require (customer = _user); 
        "The current user is not a customer";; 
    }
    
    modifier checkDeposit(uint _money) {
        require(msg.value == _money);
        _;
    }

    modifier checkDeposit(uint _money) {
        require(msg.value == _money);
        _;
    }


    

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    event AuctionStarted(address _who, uint _time)
    event AuctionEnded(address winner, uint highestBid);


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  the constructors for two contracts respectively.
    constructor(uint _auctionTime, uint _revealTime, address payable _customer) 
        public 
    {
        customer = _customer;
        auctionEnd = now + _auctionTime;
        revealEnd = auctionEnd + _revealTime;
    }


    constructor(uint _witnessTime, uint _revealTime,  address payable _witness) 
        public 
    {
        witness = _witness;
        witnessEnd = now + _witnessTime;
        revealEnd = auctionEnd + _revealTime;
    }

// process:
// 1. Cloud Customer upload the service information that needs to be auctioned. (and the parameters: k, reserve price U(blind))
// 2. Cloud providers register in the AuctionContract (reputation 0). If the number of registered providers achieve the condition (*2), then // event: auction start.
// 3. Registered providers submit their sealed bid + bid deposit (10%).   => function sumitBid // event: bids submitted.  // set: time window, - reputation (lazy) // only 接收到的报价的数量大于k， bidding 才能结束
// 4. Reveal the bids with keccak256 algorithm. // Sorting the bids by ascending, 只有当满足reserve price U的报价的数量大于k的，拍卖成功，选出winner和他们的报价。给没有中标的provider退还保证金。the bid deposit is only refunded if the bid is correctly revealed in the revealing phase. 
// 5. Winner bidders sign the SLAs with the user, respectively.
// 
// 
//



    /**
     * Provider Interface::
     * This is for the winner provider to generate a SLA contract
     * */
    function genSLAContract() 
        public
        returns
        (address)
    {
        address newSLAContract = new CloudSLA(this, msg.sender, 0x0);
        SLAContractPool[newSLAContract].valid = true; 
        emit SLAContractGen(msg.sender, now, newSLAContract);
        return newSLAContract;
    }    
}




/**
 * The witness contract does this and that...
 */
contract witness {
  constructor() public {
    
  }
}









