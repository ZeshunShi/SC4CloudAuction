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

    constructor(uint _registeTime, uint _biddingTime, uint _revealTime, uint _withdrawTime) 
        public 
    {
        require (_registeTime > 0);
        require (_biddingTime > 0);
        require (_revealTime > 0);
        require (_withdrawTime > 0);
        
        auctioneer = msg.sender;
        initialTime = now;
        registeEnd = initialTime + _registeTime;
        biddingEnd = registeEnd + _biddingTime;
        revealEnd = biddingEnd + _revealTime;
        refundEnd = revealEnd + _withdrawTime;

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
        uint8 providerNumber;
    }
    mapping(address => AuctionItem) public auctionItemStructs;
    address payable [] public customerAddresses;

    function setupAuction (string memory _customerName, string memory _auctionDetails, bytes32 _sealedReservePrice, uint8 _providerNumber) 
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
        auctionItemStructs[msg.sender].providerNumber = _providerNumber
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
        uint index; // the id of the provider in the address pool
        int8 reputation; //the reputation of the provider, the initial value is 0
        bool registered;    ///true: this provider has registered     
        ProviderState state;  // the current state of the provider
    }
    mapping (address => Bidder) public providerPool;
    address [] public providerAddrs;    ////the address pool of providers, which is used for register new providers in the auction
    
    function bidderRegister () 
        public
        // checkProviderNotRegistered(msg.sender)
        // checkAuctionPublished
        returns(bool registerSuccess) 
    {
        providerPool[msg.sender].index = providerAddrs.length;
        providerPool[msg.sender].state = ProviderState.Ready;
        providerPool[msg.sender].reputation = 0;
        providerPool[msg.sender].registered = true;
        providerAddrs.push(msg.sender);
        return true;        
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
        // checkBidderNumber(revealedBidders.length > providerNumber)
        returns(address payable [] memory)
    {
        bool exchanged;
        uint i;
        uint j;  
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
        // return revealedBidders;

        uint sumBids;
        for(uint i=0; i < 5; i++){
            sumBids += revealedBids[i];
        }
        
        // require(sumBids <= reservePrice, "The lowest k bids do not meet the requirements of the customer's reserve Price, auction failed.");  // pay back to everybody, restart the auction
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
        uint index; // the id of the contract in the address pool
        bool valid;    ///true: this contract has been valided
    }    
    mapping(address => ContractInfo) SLAContractPool;
    address [] public SLAContractAddresses;


    function genSLAContract() 
        public 
        // checkWinnerProvider(msg.sender)
        returns(address)
    {
        require (bidStructs[msg.sender].bidderDeposit > 0 && customerAddresses.length > 0);   
        address newSLAContract = address (new CloudSLA(this, msg.sender, customerAddresses[0]));
        SLAContractPool[newSLAContract].valid = true; 
        SLAContractPool[newSLAContract].index = SLAContractAddresses.length;
        SLAContractAddresses.push(newSLAContract);

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
    //     witnessContractPool[msg.sender].index = witnessContractAddresses.length;
    //     witnessContractPool[newWitnessContract].valid = true; 
    //     witnessContractAddresses.push(msg.sender);
    //     emit SLAContractGen(msg.sender, now, newWitnessContract);
    //     return newWitnessContract;
    // }


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// phase7: normal user register as Witnesses and monitor the federated Cloud service.
    enum WitnessState { Offline, Online, Candidate, Busy }
    struct Witness {
        uint index;         ///the index of the witness in the address pool, if it is registered
        int8 reputation; //the reputation of the provider, the initial value is 0
        bool registered;    ///true: this witness has registered.
        WitnessState state;    ///the state of the witness       
        address[] SLAContracts;    ////the address of SLA contract
    }
    mapping(address => Witness) witnessPool;
    address [] public witnessAddrs;    ////the address pool of witnesses

    function witnessRegister()
        public
        checkRegister(msg.sender)
        checkReputation(msg.sender)
        checkAllSLA()
        returns(bool)
    {
        require (witnessAddrs.length <= 100);
        witnessPool[msg.sender].index = witnessAddrs.length;
        witnessPool[msg.sender].state = WitnessState.Offline;
        witnessPool[msg.sender].reputation = 0;
        witnessPool[msg.sender].registered = true;
        witnessPool[msg.sender].SLAContracts = SLAContractAddresses;
        witnessAddrs.push(msg.sender);
        return true;
    }
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// registered witnesses submit sealed results.
    // struct Message {
    //     uint[] result;   ///whether it has reported that the service agreement is violated 
    //     uint balance;    ///the account balance of this witness
    // }
    // uint[] witnessMessage;

    mapping (address => bytes32[]) sealedMessageArray;
    function reportResults(bytes32[] _sealedResult) 
        public
        payable
        // checkWitness(msg.sender)
        // checkState(AuctionState.monitor) 
        returns(bool reportSuccess)
    {
        require (_sealedBid.length == providerNumber);   
        sealedMessageArray[msg.sender] = _sealedResult;
        returns true;
    }

    mapping (address => uint[]) revealedMessageArray;
    address [] public revealedWitnesses; 

    function revealMessages (uint[] _message, uint _witnessKey)
        public
        payable
        // checkTimeAfter(bidEnd)
        // checkTimeBefore(revealEnd)
        // checkState(AuctionState.monitor)
        // checkWitness(msg.sender)
        // checkBidderNumber(bidderAddresses.length > 5 && customerAddresses.length == 1)
        returns(bool revealSuccess)
    {
        require (_message.length == providerNumber && _witnessKey != 0);
        for (uint i=0; i < providerNumber; i++) {
            // check all the monitoring messages (for k SLAs) in the rang 0-100.
            require (_message[i] >= 0 && _message[i] <= 100);
            if (keccak256(abi.encodePacked(_message[i], _witnessKey)) == sealedMessageArray[msg.sender][i]){
                SLAsNumber++;
            }
        }
        // check all the monitoring messages(for k SLAs) in the array reveled successfully.
        if (SLAsNumber == providerNumber) {
            revealedMessageArray[msg.sender] = _message;
            revealedWitnesses.push(msg.sender)
            return true;
        } else if (SLAsNumber < providerNumber) {
            return false;
        }
    }

    function placeMessages ()
        public
        // checkTimeAfter(bidEnd)
        // checkTimeBefore(revealEnd)
        // checkAuctioner(msg.sender = owner)
        // checkRevealedWitnessNumber(revealedWitnesses.length >= providerNumber*10)
        returns(address payable [] memory)
    {
        // 1. compare the message from one witnesses to others to define the money transfer rule.
        // 2. withdraw the witness fee.
        // uint fai;
        mapping (uint => uint) fai;
        for (uint j=0; j < providerNumber; j++) {
            for (uint i=0; i < revealedWitnesses.length; i++) {
                for (uint k=0; k < revealedWitnesses.length; k++) {
                    require (i != k);
                    fai[i][j] += (revealedMessageArray[revealedWitnesses[i]][j] - revealedMessageArray[revealedWitnesses[k]][j]) ** 2
                }
            }
        }



        // ConfirmRepCount++;
        // if( ConfirmRepCount >= ConfirmNumRequired ){
        //     SLAState = State.Violated;
        //     emit SLAStateModified(msg.sender, now, State.Violated);
        // }
    }







    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}


/**
 * The CloudSLA contract manage the service details between provider and customer.
 */
contract CloudSLA {

    enum State { Fresh, Init, Active, Violated, Completed }

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

    uint public ServiceFee；
    uint public WitnessFee;
    uint public ServiceDuration;
    uint public WitnessNumber;
    string public ServiceDetail;

    //// this is for Cloud provider to set up this SLA and wait for Customer to accept
    function setupSLA() 
        public 
        payable 
        checkState(State.Fresh) 
        checkProvider
        checkMoney(PPrepayment)
    {
        require(WitnessNumber == witnessCommittee.length);
        
        ProviderBalance += msg.value;
        SLAState = State.Init;
        AcceptTimeEnd = now + AcceptTimeWin;
        emit SLAStateModified(msg.sender, now, State.Init);
    }

    //// this is for customer to put its prepaid fee and accept the SLA    
    function acceptSLA() 
        public 
        payable 
        checkState(State.Init) 
        checkCustomer
        checkTimeIn(AcceptTimeEnd)
        checkMoney(CPrepayment)
    {
        require(WitnessNumber == witnessCommittee.length);
        
        CustomerBalance += msg.value;
        SLAState = State.Active;
        emit SLAStateModified(msg.sender, now, State.Active);
        ServiceEnd = now + ServiceDuration;
        
        ///transfer ServiceFee from customer to provider 
        ProviderBalance += ServiceFee;
        CustomerBalance -= ServiceFee;
        
        ///setup the SharedBalance
        ProviderBalance -= SharedFee;
        CustomerBalance -= SharedFee;
        SharedBalance += SharedFee*2;
    }


    
}



















