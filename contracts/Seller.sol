pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ERC20{
function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface ERC721{
    function getApproved(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}



contract Seller is Ownable {

    uint _listingIdCounter;

    struct Listing {
        address nftAddress;
        uint tokenId;
    }

    struct Offer {
        //TODO:: reorder for storage optimization
        address offerer;
        uint[] listingIds;
        address nftAddress;
        uint[] tokenIds;
        address[] erc20Addresses;
        uint[] erc20Amounts;
        uint weiValue;
    }

    mapping (uint => Listing) private _idToListing;
    Offer[] private _offers;

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    function createListing(address nftAddress_, uint tokenId_) public onlyOwner {
        Listing memory l = Listing(nftAddress_, tokenId_);
        _idToListing[_listingIdCounter] = l;
        _listingIdCounter++;
    }

    function makeOffer( uint[] calldata listingIds_, 
                        address nftAddress_, 
                        uint[] calldata tokenIds_,
                        address[] calldata erc20Addresses_, 
                        uint[] calldata erc20Amounts_, uint weiValue) 
                        public {

        require(erc20Addresses_.length == erc20Amounts_.length, "not same length");
        // offer validation here
        address sender = msg.sender;

        // require that Seller contract is approved to transfer all erc20 tokens
        for(uint i=0; i<erc20Addresses_.length; i++){
            ERC20 erc20 = ERC20(erc20Addresses_[i]);
            require(erc20.allowance(sender, address(this)) >= erc20Amounts_[i]);
        }

        //require that Seller contract is approved to transfer ERC721 tokens
        ERC721 erc721 = ERC721(nftAddress_);
        for(uint i=0; i<tokenIds_.length; i++){
            require(erc721.getApproved(tokenIds_[i])==address(this));
        }
        _offers.push(Offer(msg.sender, listingIds_, nftAddress_, tokenIds_, erc20Addresses_, erc20Amounts_, weiValue));
    }


    // function acceptOffer(uint offerId_) public onlyOwner{
    //     Offer memory toAccept = _offers[offerId_];
    // }

}