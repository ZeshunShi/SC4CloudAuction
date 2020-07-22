# Auction Contract:
---- 
## Publish Information
Cloud Customer upload the service information that needs to be auctioned and the parameters.

 - function: publishService
 - parameters: 
     - service information. //discuss: identical service vs. different services
     - k: how many providers the user need for the federated cloud service
     - blinded reserve price 
     - deposit price （10% -30% 成交保证金）
 - event: servicePublished

## Auction Start
Cloud providers register in the AuctionContract. If the number of registered providers achieve the condition (2k), then auction start.

- function: bidderRegister
- parameters:
    - initial reputation value = 0
- modifiers:
    - require (reputaion => 0) >= candidate providers 
    - require (the number of candidate providers >= 2k), otherwise auction will not start.
- event: auctionStarted. 

## Submit Bids
Registered candidate providers submit their bidding price for the target service that to be auctioned.

- function: sumitBid
- parameters:
    - blinded bid
    - bid deposit (10% -30%).
- modifiers:
    - require (time window for the bidding phase), otherwise lazy provider  => reputation - 1 
    - require (the number of bids >= k), otherwise, restart from step 2. (restart/reset function)
- event: bidsSubmitted.

## Manage Bids
Reveal the bids with keccak256 algorithm. Sorting the bids by ascending.

- function: manageBids
- parameters:
    - blinded reserve price
    - blinded bids[]
- modifiers:
    - require (the bid deposit is only refunded if the bid is correctly revealed in the revealing phase)
    - require (Only when the number of bids meeting the reserve price U >= k, the auction will succeed. The winner and their quotations are selected) // 先筛选后排序 vs. 先排序后筛选。 otherwise, refund all the deposit price and restart from step 1. (restart/reset function)
- subfunciton: refund the deposit to the provider that has not won the bid (the deposit of Customer and winner provider is temporarily reserved).
- event: bidsManaged.

## Generate SLA Contract (not valid yet)
Winner provider bidders sign the SLAs with the customer, respectively. SLA contract 的作用是1)管理SLA的状态流程；2）管理SLA的参与者

- function: generateSLAs (providers set up the SLA and wait for customer to accept, if he didn't do it, the deposit will burn. )
    - Smart Contract set up vs. provider/customer set up
- parameters: 
    - provider
    - customer
    - service information (or QoS of infrastructure, or SLO)
    - customer: pay service fee and witness fee in advanced
    - provider: pay witness fee
- subfunction: define money transfer rule (service fee + witness fee)
- subfunciton: Refund the deposit to the user and the selected providers.
- event: SLAcontractGenerated

## Generate witness contract



## Auction Ends
- require (witness ends in the Witness Contract ) 
function: transfer the service fee to providers.
function: reputation ++

---- 
# Witness Contract:
1. Witness register
2. Witness sortition
2. Monitor SLAs
3. Report message
4. Money transfer


 链上vs.链下


