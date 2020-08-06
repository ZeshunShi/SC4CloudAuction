pragma solidity > 0.5.0;

/**
 * The AuctionManagement contract manage the lifecycle of cloud auction.
 */
contract CloudAuction {

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// phase1: initialize auction contract, set auction procedures
    uint public startTime;
    uint public registeEnd;
    uint public biddingEnd;
    uint public revealEnd;
    uint public refundEnd;
    
    // this is to illustrate the state machine of the CloudAuction contract
    enum State { Fresh, Initialized, Pending, Settled, Violated, Successful, Canceled }
    State public AuctionState;

    // this is to log event that _who modified the Auction state to _newstate at time stamp _time
    event AuctionStateModified(address indexed _who, uint _time, State _newstate);
    // this is to log event that _who generate the SLA contract _contractAddr at time stamp _time
    event SLAContractGen(address indexed _who, uint _time, address _contractAddr);


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
    modifier checkState(State _state){
        require(AuctionState == _state);
        "The aution is not in the right state;
    }
    modifier checkProvider(address _user) 
    {    
        require(Provider[_user].registered);
        "The current user is not a registered provider";
    }
    modifier checkCustomer(address _user) { 
        require (customer = _user); 
        "The current user is not the correct customer";; 
    }


    /**
     * Customer Interface:
     * This is constructor for someone (Normally the customer) to initiate an the time windows of AuctionManagement contract
     * */
    constructor(uint _registeTime, uint _biddingTime, uint _revealTime, uint _withdrawTime, uint _serviceTime) 
        public 
    {
        require (_registeTime > 0);
        require (_biddingTime > 0);
        require (_revealTime > 0);
        require (_withdrawTime > 0);
        
        startTime = now;
        registeEnd = startTime + _registeTime;
        biddingEnd = registeEnd + _biddingTime;
        revealEnd = biddingEnd + _revealTime;
        refundEnd = revealEnd + _withdrawTime;

        AuctionState = State.Fresh;
        emit AuctionStateModified(msg.sender, now, State.Fresh);
    }
    
    // function getAuctionInformation() public view returns(uint, uint, uint, uint, uint) {
    //     return (startTime, registeEnd, biddingEnd, revealEnd, refundEnd);
    // }
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  
  
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// phase2: publish auction item.
    struct AuctionItem {
        string cutomerName;
        bytes32 sealedReservePrice;
        string auctionDetails;
        uint witnessFee; 
        uint8 providerNumber;
    }
    mapping(address => AuctionItem) public auctionItemStructs;
    address payable [] public customerAddresses;

    /**
     * Customer Interface:
     * This is for customer to 1) setup the auction, 2) publish the auction details, and 3) prepay the witnessfee
     * */
    function setupAuction (string memory _customerName, string memory _auctionDetails, bytes32 _sealedReservePrice, uint8 _providerNumber) 
        public
        payable
        checkState(State.Fresh)
        checkTimeAfter(startTime)
        returns(bool setupAuctionSuccess)
    {
        require (_sealedReservePrice.length != 0 && bytes(_auctionDetails).length > 0);
        require (customerAddresses.length == 0);
        require (msg.value >= 10e18);
        auctionItemStructs[msg.sender].cutomerName = _customerName;
        auctionItemStructs[msg.sender].sealedReservePrice = _sealedReservePrice;
        auctionItemStructs[msg.sender].auctionDetails = _auctionDetails;
        auctionItemStructs[msg.sender].providerNumber = _providerNumber
        auctionItemStructs[msg.sender].witnessFee = msg.value;  // todo: check the unitWitnessFee
        customerAddresses.push(msg.sender);
        return true;        
    }

    // function viewCustomerAddressesLength() public view returns(uint){
    //     return bidderAddresses.length;
    // }
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// phase3: normal user register as providers(bidders) to participant the auction.
    struct Bidder {
        uint index; // the id of the provider in the address pool
        bool registered;    ///true: this provider has registered     
    }
    mapping (address => Bidder) public providerPool;
    address [] public providerAddrs;    ////the address pool of providers, which is used for register new providers in the auction
    
    /**
     * Provider Interface:
     * This is for normal user register as providers(bidders) to participant the auction
     * */
    function bidderRegister () 
        public
        // checkProviderNotRegistered(msg.sender)
        // checkAuctionPublished
        returns(bool registerSuccess) 
    {
        require (providerPool[msg.sender].registered = false);
        providerPool[msg.sender].index = providerAddrs.length;
        providerPool[msg.sender].registered = true;
        providerAddrs.push(msg.sender);
        return true;
    }


    /**
     * Customer Interface:
     * This is for customer to check the whether the registered provider number is enough
     * */
    function checkAuctionInitialized () 
        public
        // checkCustomer
    {
        require (now > providerRegisterEnd);        
        if (providerAddrs.length >= providerNumber){
            AuctionState = State.Initialized;
            emit AuctionStateModified(msg.sender, now, State.Initialized);
        } else {
            AuctionState = State.Canceled;
            emit AuctionStateModified(msg.sender, now, State.Canceled);
        }
    }
    // function viewProviderAddrsLength() public view returns(uint){
    //     return providerAddrs.length;
    // }


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// phase4: registered providers submit sealed bids as well as witness fee.
    struct Bid {
        string providerName;
        bytes32 sealedBid;
        uint bidderDeposit;
    }
    mapping(address => Bid) public bidStructs;
    address [] public bidderAddresses;

    /**
     * Provider Interface:
     * This is for registered providers to 1) submit sealed bids and 2) prepay the witness fee
     * */
    function submitBids(string memory _providerName, bytes32 _sealedBid) 
        public
        payable
        // checkProvider(msg.sender)
        // checkDeposit(msg.value)
        // checkState(AuctionAuctionState.fresh) 
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
    // function viewBiddersLength() public view returns(uint){
    //     return bidderAddresses.length;
    // }
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// phase5: reveal, sorting, and pay back the witness fee.
    uint public reservePrice;

    /**
     * Customer Interface:
     * This is for customer to reveal the reserve price
     * */
    function revealReservePrice (string memory _customerName, uint _reservePrice, uint _customerKey)
        public
        payable
        // checkTimeAfter(bidEnd)
        // checkTimeBefore(revealEnd)
        // checkCustomer(msg.sender)
        // checkBidderNumber(bidderAddresses.length > 5 && customerAddresses.length == 1) //put into function part
        returns(uint)
    {
        require (_reservePrice > 0 && _customerKey != 0);
        require (keccak256(abi.encodePacked(auctionItemStructs[msg.sender].cutomerName)) == keccak256(abi.encodePacked(_customerName)));
        if (keccak256(abi.encodePacked(_reservePrice, _customerKey)) == auctionItemStructs[msg.sender].sealedReservePrice){
            reservePrice = _reservePrice;
        }
        return reservePrice;
    }
    
    address payable [] public revealedBidders;
    uint [] public revealedBids;
    // mapping(address => uint) public revealedBids;
    
    /**
     * Provider Interface:
     * This is for registered providers(who submitted the sealed bid) to reveal the bid
     * */
    function revealBids (string memory _providerName, uint _bid, uint _providerKey)
        public
        payable
        // checkTimeAfter(bidEnd)
        // checkTimeBefore(revealEnd)
        // checkProvider(msg.sender)
        // checkBidderNumber(bidderAddresses.length > 5 && customerAddresses.length == 1)
    {
        require (_bid > 0 && _providerKey != 0);
        require (keccak256(abi.encodePacked(bidStructs[msg.sender].providerName)) == keccak256(abi.encodePacked(_providerName)));
        if (keccak256(abi.encodePacked(_bid, _providerKey)) == bidStructs[msg.sender].sealedBid){
            // revealedBids[msg.sender] = _bid;
            revealedBidders.push(msg.sender);
            revealedBids.push(_bid);
        }
    }
    // function testReveal() public view returns(address payable [] memory, uint[] memory){
    //     return (revealedBidders,revealedBids);
    // }


    address payable [] public winnerBidders;
    address payable [] public loserBidders;
    uint [] public winnerBids;
    uint [] public loserBids;
    mapping(address => uint) refund;

    /**
     * Customer Interface:
     * This is for customer to 1) sort the bids by ascending 2) select k-th providers to form a federated cloud servcie
     * */        
    function placeBids () 
        public
        // checkTimeAfter(bidEnd)
        // checkTimeBefore(revealEnd)
        // checkAuctioner(msg.sender = owner)
        // checkBidderNumber(revealedBidders.length > providerNumber)
        returns(address payable [] memory, address payable [] memory)
    {
        bool exchanged; 
        for (uint i=0; i < revealedBids.length - 1; i++) {
            exchanged = false;
            for (j =0; j < revealedBids.length- i - 1; j++){
                if (revealedBids[j] > revealedBids[j+1]){
                    (revealedBids[j], revealedBids[j+1]) = (revealedBids[j+1], revealedBids[j]);
                    (revealedBidders[j], revealedBidders[j+1]) = (revealedBidders[j+1], revealedBidders[j]);
                    exchanged = true;
                }
            }
                if(exchanged==false) break;
        }

        uint sumBids;
        for(uint i=0; i < providerNumber; i++){
            sumBids += revealedBids[i];
        }
        
        // require(sumBids <= reservePrice, "The lowest k bids do not meet the requirements of the customer's reserve Price, auction failed."); 
        for (uint i=0; i < revealedBidders.length; i++) {
            if( i< providerNumber && sumBids <= reservePrice) {
                winnerBids.push() = revealedBids[i];
                winnerBidders.push() = revealedBidders[i];
            } else if( i >= providerNumber && sumBids <= reservePrice ){
                loserBids.push() = revealedBids[i];
                loserBidders.push() = revealedBidders[i];
            } else if( sumBids > reservePrice ){
                loserBids.push() = revealedBids[i];
                loserBidders.push() = revealedBidders[i];
            }
        }
        if (winnerBidders.length == providerNumber){
            AuctionState = State.Pending;
            emit AuctionStateModified(msg.sender, now, State.Pending);
        } else if winnerBidders.length == 0){
            AuctionState = State.Canceled;
            emit AuctionStateModified(msg.sender, now, State.Canceled);
        }
        return (winnerBidders,loserBidders);
    }

    // function testWinner() public view returns(address payable [] memory, uint[] memory){
    //     return (winnerBidders,winnerBids);
    // }
    // function testLoser() public view returns(address payable [] memory, uint[] memory){
    //     return (loserBidders,loserBids);
    // }
    
    /**
     * Provider Interface:
     * This is for loser providers to withdraw the witness fee
     * */
    function providerWithdrawWitnessFee()
        public  
        // checkTimeAfter(bidEnd)
        // checkTimeBefore(revealEnd)
        // checkAuctioner(msg.sender = owner)
    { 
        require (bidStructs[msg.sender].bidderDeposit > 0);
        require (loserBidders.length != 0);
        refund[msg.sender] = bidStructs[msg.sender].bidderDeposit;
        msg.sender.transfer(refund[msg.sender]);
        bidStructs[msg.sender].bidderDeposit = 0;
    }

    /**
     * Customer Interface:
     * This is for customer to withdraw the witness fee, if the auction is failed (3 situations)
     * */
    function customerWithdrawWitnessFee()
        public  
        // checkTimeAfter(bidEnd)
        // checkTimeBefore(revealEnd)
        // checkAuctioner(msg.sender = owner)
    {
        require (msg.sender = customerAddresses[0]);
        if (winnerBidders.length == 0) {
            refund[msg.sender] = auctionItemStructs[msg.sender].witnessFee;
            msg.sender.transfer(refund[msg.sender]);
            auctionItemStructs[msg.sender].witnessFee = 0;         
        }
    }
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// phase6: generate SLA contracts for winner providers, respectively.
    struct ContractInfo {
        uint index; // the id of the SLA contract in the address pool
        bool valid;    // true: this contract has been valided
        uint serviceFee; // the service fee should be the bidding price
    }    
    mapping(address => ContractInfo) SLAContractPool;
    address [] public SLAContractAddresses;

    /**
     * Customer Interface:
     * This is for winner providers to generate the SLA contracts
     * */
    function genSLAContract() 
        public 
        // checkWinnerProvider(msg.sender)
        // check(msg.value = winnerBids[winnerBidders[msg.sender]])  or create another mapping
        returns(address)
        
    {
        require (bidStructs[msg.sender].bidderDeposit > 0 && customerAddresses.length > 0);   
        address newSLAContract = address (new CloudSLA(this, msg.sender, customerAddresses[0]));
        SLAContractPool[newSLAContract].index = SLAContractAddresses.length;
        SLAContractPool[newSLAContract].valid = true; 
        SLAContractPool[newSLAContract].serviceFee = msg.value;
        SLAContractAddresses.push(newSLAContract);

        emit SLAContractGen(msg.sender, now, newSLAContract);
        return newSLAContract;
    }


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// phase7: normal user register as Witnesses and monitor the federated Cloud service.
    struct Witness {
        uint index;         ///the index of the witness in the address pool, if it is registered
        bool registered;    ///true: this witness has registered.
        address[] SLAContracts;    ////the address of SLA contract
    }
    mapping(address => Witness) public witnessPool;
    address [] public witnessAddrs;    ////the address pool of witnesses

    /**
     * Witness Interface:
     * This is for normal users register as witnesses to monitor the federated Cloud service.
     * */
    function witnessRegister()
        public
        checkRegister(msg.sender)
        checkReputation(msg.sender)
        checkAllSLA()
        returns(bool)
    {
        require (witnessAddrs.length <= 100);
        witnessPool[msg.sender].index = witnessAddrs.length;
        witnessPool[msg.sender].registered = true;
        witnessPool[msg.sender].SLAContracts = SLAContractAddresses;
        witnessAddrs.push(msg.sender);
        return true;
    }

    /**
     * Customer Interface:
     * This is for customer to check the whether the registered provider number is enough
     * */
    function checkAuctionSettled () 
        public
        // checkCustomer
    {
        require (now > witnessRegisterEnd);
        if (witnessAddrs.length >= 2*providerNumber && SLAContractAddresses.length == providerNumber){
            AuctionState = State.Settled;
            emit AuctionStateModified(msg.sender, now, State.Settled);
        } else {
            AuctionState = State.Canceled;
            emit AuctionStateModified(msg.sender, now, State.Canceled);
        }
    }

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// phase8: registered witnesses submit sealed monitoring messages.
    mapping (address => bytes32[]) sealedMessageArray;

    /**
     * Witness Interface:
     * This is for registered witnesses to submit the (sealed) monitoring messages array for different SLAs in the federated cloud service
     * */
    function submitMessages(bytes32[] memory _sealedResult) 
        public
        payable
        // checkWitness(msg.sender)
        // checkState(AuctionAuctionState.monitor) 
        returns(bool reportSuccess)
    {   
        require (witnessPool[msg.sender].registered = true);       
        require (_sealedResult.length == providerNumber);   
        sealedMessageArray[msg.sender] = _sealedResult;
        return true;
    }

    mapping (address => uint[]) public revealedMessageArray;
    address payable [] public revealedWitnesses; 

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// phase9: registered witnesses reveal sealed messages.

    /**
     * Witness Interface:
     * This is for registered witnesses(who submitted the sealed messages) to reveal the message array
     * */
    function revealMessages (uint[] memory _message, uint _witnessKey)
        public
        payable
        // checkTimeAfter(bidEnd)
        // checkTimeBefore(revealEnd)
        // checkState(AuctionAuctionState.monitor)
        // checkWitness(msg.sender)
        // checkBidderNumber(bidderAddresses.length > 5 && customerAddresses.length == 1)
        returns(bool revealSuccess)
    {
        require (_message.length == providerNumber && _witnessKey != 0);
        uint SLAsNumber;
        for (uint i=0; i < providerNumber; i++) {
            // check all the monitoring messages (for k SLAs) in the rang 0-10.
            require (_message[i] >= 0 && _message[i] <= 10);
            if (keccak256(abi.encodePacked(_message[i], _witnessKey)) == sealedMessageArray[msg.sender][i]){
                SLAsNumber++;
            }
        }
        // check all the monitoring messages(for k SLAs) in the array reveled successfully.
        if (SLAsNumber == providerNumber) {
            revealedMessageArray[msg.sender] = _message;
            revealedWitnesses.push(msg.sender);
            return true;
        } else if (SLAsNumber < providerNumber) {
            return false;
        }
    }
    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// phase10: withdraw witness fee.
    uint public providerNumber = 3;
    uint public uintWitnessFee = 4*100;     // To ensure each witness tell the truth, uintWitnessFee should weakly balanced with Epsilon.
    uint public Epsilon = 4;
    mapping (address => uint) witnessFee;

    // mapping (address => uint[]) public revealedMessageArray;
    // address payable [] public revealedWitnesses; 

    // function addRevealedMessageArray (uint[] memory _revealedMessageArray) 
    //     public
    // {
    //     revealedMessageArray[msg.sender] = _revealedMessageArray;
    //     revealedWitnesses.push(msg.sender);
    // }
   
    /**
     * Customer Interface:
     * This is for customer to calculate the wisness fee for all the witnesses based on their report result
     * */ 
    function placeWitnessFee ()
        public
        // checkTimeAfter(bidEnd)
        // checkTimeBefore(revealEnd)
        // checkAuctioner(msg.sender = owner)
        // checkRevealedWitnessNumber(revealedWitnesses.length >= providerNumber*10)
        // returns(address payable [] memory)
    {
        for (uint i=0; i < revealedWitnesses.length; i++) {
            uint accumulator = 0;
            for (uint j=0; j < providerNumber; j++) {
                for (uint k=0; k < revealedWitnesses.length; k++) {
                    // here need to check the divide accuracy of solidity version
                    accumulator += (revealedMessageArray[revealedWitnesses[i]][j] - revealedMessageArray[revealedWitnesses[k]][j]) ** 2;
                }
            }
            witnessFee[revealedWitnesses[i]] = providerNumber * uintWitnessFee - accumulator * Epsilon / (revealedWitnesses.length - 1);
        }
    }

    // todo: check where is the msg.value
    /**
     * Witness Interface:
     * This is for registered witnesses to withdraw the witness fee (if the message array is revealed successfully)
     * */ 
    function witnessWithdraw()
        public
        // checkState(AuctionState.Completed)
        // checkTimeOut(ServiceEnd)
        // checkWitness(msg.sender)
    {
        require(witnessFee[msg.sender] > 0);
        msg.sender.transfer(witnessFee[msg.sender]);
        witnessFee[msg.sender] = 0;
    }
    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// phase11: withdraw service fee.
    uint[] serviceFee;
    bool[] SLAviolated;


    mapping (address => uint[]) public revealedMessageArray;
    address payable [] public revealedWitnesses; 

    mapping(address => uint) public refund;
    address payable [] public SLAContractAddresses;
    address payable [] public customerAddresses;


    /**
     * Customer Interface:
     * This is for customer to calculate the service fee
     * */ 
    function  checkSLAViolation ()
        public
        payable
        // checkTimeAfter(bidEnd)
        // checkTimeBefore(revealEnd)
        // checkState(AuctionAuctionState.monitor)
        // checkProvider(msg.sender)
        returns(bool paymentSuccess)
    {   
        uint[] memory count;
        for (uint j=0; j < SLAContractAddresses.length; j++) {
            for (uint i=0; i < revealedWitnesses.length; i++) {
                // The message space is [1,10], the mean is 5
                if (revealedMessageArray[revealedWitnesses[i]][j] > 5) {
                    count[j] ++; 
                }
        }
        for (uint j=0; j < SLAContractAddresses.length; j++) {
            if (count[j] > 2/revealedWitnesses.length) {
                SLAviolated[j] = true;    //. check   push
                // transfer money(j) to customer
                refund[customerAddresses[0]] = serviceFee[j];
                // customerAddresses[0].transfer(refund[customerAddresses[0]]);
            } else if (count[j] <= 2/revealedWitnesses.length) {
                SLAviolated[j] = false;
                // transfer money to provider j
                refund[SLAContractAddresses[j]] = serviceFee[j];
                // SLAContractAddresses[j].transfer(refund[SLAContractAddresses[j]]);
            }
        }
        if (SLAviolated.length == 0){
            AuctionState = State.Successful;
            emit AuctionStateModified(msg.sender, now, State.Successful);
        } else if (SLAviolated.length != 0) {
            AuctionState = State.Violated;
            emit AuctionStateModified(msg.sender, now, State.Violated);
        }
        }   
    }

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



}


/**
 * The CloudSLA contract manage the service details between provider and customer.
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

    uint public serviceFee；
    uint public uintWitnessFee;
    uint public serviceDuration;
    uint public witnessNumber;
    string public serviceDetail;

    //// this is for Cloud provider to set up this SLA and wait for Customer to accept
    function setupSLA() 
        public 
        // checkState(AuctionState.Fresh) 
        // checkProvider
        // checkMoney(PPrepayment)
    {
        require(WitnessNumber == witnessCommittee.length);     
        SLAState = State.Init;
        AcceptTimeEnd = now + AcceptTimeWin;
    }

    //// this is for customer to put its prepaid service fee and accept the SLA    
    function acceptSLA() 
        public 
        payable 
        // checkState(AuctionState.Init) 
        // checkCustomer(msg.sender)
        // checkTimeIn(AcceptTimeEnd)
        // checkMoney(CPrepayment)
    {
        require(WitnessNumber == witnessCommittee.length);
        CustomerBalance += msg.value;
        ServiceEnd = now + ServiceDuration;
        
        ///transfer ServiceFee from customer to provider 
        ProviderBalance += ServiceFee;
        CustomerBalance -= ServiceFee;
        
        ///setup the SharedBalance
        ProviderBalance -= SharedFee;
        CustomerBalance -= SharedFee;
        SharedBalance += SharedFee*2;
    }


    /**
     * Customer Interface:
     * This is for customer to withdraw the witness fee (if the SLA[j] is violated)
     * */ 
    function customerWithdrawServiceFee()
        public
        // checkState(AuctionState.Completed)
        // checkTimeOut(ServiceEnd)
        // checkCustomer(msg.sender)
    {
        require(serviceFee[msg.sender] > 0);
        msg.sender.transfer(serviceFee[msg.sender]);
        serviceFee[msg.sender] = 0;
    }


    /**
     * Provider Interface:
     * This is for provider to withdraw the witness fee (if the SLA[j] is not violated)
     * */ 
    function providerWithdrawServiceFee()
        public
        // checkState(AuctionState.Completed)
        // checkTimeOut(ServiceEnd)
        // checkWitness(msg.sender)
    {
        require(serviceFee[msg.sender] > 0);
        msg.sender.transfer(serviceFee[msg.sender]);
        serviceFee[msg.sender] = 0;
    }

}



















