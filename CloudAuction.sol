pragma solidity ^0.5.0;
    /**
     * The CloudAuction contract is a smart contract on Ethereum that supports the decentralized cloud providers to auction and bid the cloud services (IaaS). 
     * examanier/auditor/arbiter
     */


// Some imported solidity libraries used in this contract.
import "./library/librarySorting.sol";


contract CloudAuction {

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    enum ProviderState { Offline, Online, Candidate, Busy }

    struct Provider {

        uint index; ///the index of the provider in the address pool, if it is registered
        bool registered;    ///true: this provider has registered.         
        int8 reputaion; //the reputation of the provider, the initial value is 0.
        ProviderState state;  // the state of the provider
    }

    mapping (address => Provider) providerCrowd;

    // mapping(address => SortitionInfo) SLAContractArray;
    address [] public providerAddrs;    ////the address pool of providers

    
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // check whether it is a registered provider
    modifier checkProvider(address _provider){
        require(providerCrowd[_provider].registered);
        _;
    }    



///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    
    constructor(uint _auctionTime, uint _revealTime, address payable _customer) 
        public 
    {
        customer = _Customer;
        auctionEnd = now + _auctionTime;
        revealEnd = auctionEnd + _revealTime;
    }

// process:
// 1. Cloud Customer upload the service information that needs to be auctioned. (and the parameters: k, reserve price U(blind))
// 2. Cloud providers register in the AuctionContract (reputation 0). If the number of registered providers achieve the condition (*2), then // event: auction start.
// 3. Registered providers submit their blinded bid + bid deposit (10%).   => function sumitBid // event: bids submitted.  // set: time window, - reputation (lazy) // only 接收到的报价的数量大于k， bidding 才能结束
// 4. Reveal the bids with keccak256 algorithm. // Sorting the bids by ascending, 只有当满足reserve price U的报价的数量大于k的，拍卖成功，选出winner和他们的报价。给没有中标的provider退还保证金。the bid deposit is only refunded if the bid is correctly revealed in the revealing phase. 
// 5. Winner bidders sign the SLAs with the user, respectively.
// 
// 
// 
// 
// 
// 
//  
//   
//     
// 
// 
// 
// [vi^max, vi^min], 
// 
//  event: auction end
// 






    function myFunction () returns(bool res) internal {
        
    }
    



    /**
     * Normal User Interface::
     * This is for the normal user to register as a Cloud provider in the auction game
     * */
    function register() 
        public 
    {
        require(!providerCrowd[_provider].registered);
        providerCrowd[msg.sender].index = providerAddrs.push(msg.sender) - 1;
        providerCrowd[msg.sender].state = ProviderState.Offline;
        providerCrowd[msg.sender].reputation = 0; 
        providerCrowd[msg.sender].registered = true;
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







