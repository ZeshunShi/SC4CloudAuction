pragma solidity ^0.5.0;
/**
 * The CloudAuction contract is a smart contract on Ethereum that supports the decentralized cloud providers to auction and bid the cloud services (IaaS). 
 * examanier/auditor/arbiter
 */


// Some solidity libraries used in this contract.
import "./library/librarySorting.sol";


contract CloudAuction {
  constructor() 
		public 
  {
    
  }



    /**
     * Sorting Interface::
     * This is for sorting the bidding price of different providers
     * */

    using SortingMethods for uint[];
    uint[] bidArray;

   // this function add the bids from different providers
    function addBids (uint[] memory _ArrayToAdd) public {
        for (uint i=0; i< _ArrayToAdd.length; i++){
            bidArray.push(_ArrayToAdd[i]);
        }
    }

    function sortArray() public returns(uint[] memory){
        bidArray = bidArray.heapSort();
        return bidArray;
    }


    /**
     * Provider Interface::
     * This is for the provider to generate a SLA contract
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



