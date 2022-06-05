pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "hardhat/console.sol";



interface ERC20{
function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface ERC721{
    function getApproved(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}




contract Broker{
    using ECDSA for bytes32;






    function _verifySignature(
        bytes calldata _signature, 
        bytes memory _data, 
        address _expectedAddress) public pure returns(bool) {

        
        // bytes32 dataHash = keccak256(abi.encodePacked(_data));
        bytes32 dataHash = keccak256(_data);

        // console.logBytes32(dataHash);
        bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);
        // console.logBytes32(message);
        address recoveredAddress = ECDSA.recover(message, _signature);
        require(recoveredAddress == _expectedAddress);
        return recoveredAddress == _expectedAddress;
    }

    /*
    _data SHOULD BE IN ORDER OF:
    uint listingsLength,
    uint offerNftLength,
    uint offerErc20Length,
    address[] listingNftAddresses,
    uint[] listingNftIds,
    address[] offerNftAddresses, 
    uint[] offerNftIds,
    address[] offerTokenAddresses,
    uint[] offerTokenAmounts
    */
    function executeTrade(
        bytes calldata _sellerSignature,
        bytes calldata _offererSignature,
        address _offererAddress,
        bytes memory _data
        ) external {
        
        // console.logString("here1");
        require(_verifySignature(_sellerSignature, _data, msg.sender));
        // console.logString("here2");
        require(_verifySignature(_offererSignature, _data, _offererAddress));
        // console.logString("here3");
        console.logBytes(_data);


        uint listingsLength;
        uint offerNftLength;
        uint offerErc20Length;
        uint i = 32;
        assembly{mstore(listingsLength, add(_data, i))} //store the first uint into listings lengths
        i+=32;
        assembly{mstore(offerNftLength, add(_data, i))} //store second uint 
        i+=32;
        assembly{mstore(offerErc20Length, add(_data, i))} //store third uint
        i+=32;

        console.log(listingsLength);
        console.log(offerNftLength);
        console.log(offerErc20Length);

        // abi.decode(_data, (uint256, uint256, uint256, address[], uint[], address[], uint[], address[], uint[]));

        uint j;
        address[] memory listingNftAddresses = new address[](listingsLength);
        for(j = i; i<32*listingsLength+i; j += 32){
            assembly {mstore(add(listingNftAddresses, j), mload(add(_data, j)))}
        }
        i = j;

        uint[] memory listingNftIds = new uint[](listingsLength);
        for (; j <= 32*listingsLength + i; j += 32) {
            assembly {mstore(add(listingNftIds, j), mload(add(_data, j)))}
        }
        i = j;

        address[] memory offerNftAddresses = new address[](offerNftLength);
        for(; j<20*offerNftLength + i; j+=20){
            assembly {mstore(add(offerNftAddresses, j), mload(add(_data, j)))}
        }
        i = j;

        uint[] memory offerNftIds = new uint[](offerNftLength);
        for (; j <= 32*offerNftLength + i; j += 32) {
            assembly {mstore(add(offerNftIds, j), mload(add(_data, j)))}
        }
        i = j;

        address[] memory offerTokenAddresses = new address[](offerErc20Length);
        for(; j<32*offerErc20Length + i; j+=32){
            assembly {mstore(add(offerTokenAddresses, j), mload(add(_data, j)))}
        }
        i = j;

        uint[] memory offerTokenAmounts = new uint[](offerErc20Length);
        for (; i <= 32*offerErc20Length + i; j += 32) {
            assembly {mstore(add(offerTokenAmounts, j), mload(add(_data, j)))}
        }

        // transfer offerers ERC20 tokens
        for(i=0; i<offerTokenAddresses.length; i++){
            require(ERC20(offerTokenAddresses[i]).transferFrom(_offererAddress, msg.sender, offerTokenAmounts[i]));
        }

        // transfer Owners NFTs
        for(i=0; i<listingNftAddresses.length; i++){
            require(ERC721(listingNftAddresses[i]).getApproved(listingNftIds[i]) == address(this), "contract not approved to transfer listed nft");
            ERC721(listingNftAddresses[i]).safeTransferFrom(msg.sender, _offererAddress, listingNftIds[i]);
        }

        // transfer offerers NFTs
        for(i=0; i<offerNftAddresses.length; i++){
            require(ERC721(offerNftAddresses[i]).getApproved(offerNftIds[i])==address(this), "Seller contract not authorized to transfer ERC721 tokens from offerer");
            ERC721(offerNftAddresses[i]).safeTransferFrom(_offererAddress, msg.sender, offerNftIds[i]);
        }


    }


    // function executeTrade(
    //     bytes calldata sellerSignature,
    //     bytes calldata offererSignature,
    //     address offererAddress,
    //     uint listingsLength,
    //     uint offerNftLength,
    //     uint offerErc20Length,
    //     uint[] calldata listingNftIds,
    //     uint[] calldata offerNftIds,
    //     uint[] calldata offerTokenAmounts,

    //     address[] calldata listingNftAddresses,
    //     address[] calldata offerNftAddresses,
    //     address[] calldata offerTokenAddresses,

    //     ) public returns (bool){

    //     _verifySignatures(
    //         sellerSignature, 
    //         offererSignature, 
    //         offererAddress, 
    //         listingNftAddresses, 
    //         listingNftIds, 
    //         offerNftAddresses, 
    //         offerNftIds, 
    //         offerTokenAddresses, 
    //         offerTokenAmounts);


    //     // transfer offerers ERC20 tokens
    //     for(uint i=0; i<offerTokenAddresses.length; i++){
    //         require(ERC20(offerTokenAddresses[i]).transferFrom(offererAddress, msg.sender, offerTokenAmounts[i]));

    //     }

    //     // transfer Owners NFTs
    //     for(uint i=0; i<listingNftAddresses.length; i++){
    //         require(ERC721(listingNftAddresses[i]).getApproved(listingNftIds[i]) == address(this), "contract not approved to transfer listed nft");
    //         ERC721(listingNftAddresses[i]).safeTransferFrom(msg.sender, offererAddress, listingNftIds[i]);
    //     }

    //     // transfer offerers NFTs
    //     for(uint i=0; i<offerNftAddresses.length; i++){
    //         require(ERC721(offerNftAddresses[i]).getApproved(offerNftIds[i])==address(this), "Seller contract not authorized to transfer ERC721 tokens from offerer");
    //         ERC721(offerNftAddresses[i]).safeTransferFrom(offererAddress, msg.sender, offerNftIds[i]);
    //     }
    //     return true;
    // }
//     function _validateTrade(
//     address offererAddress,
//     address[] calldata listingNftAddresses,
//     uint[] calldata listingNftIds,
//     address[] calldata offerNftAddresses, 
//     uint[] calldata offerNftIds,
//     address[] calldata offerTokenAddresses,
//     uint[] calldata offerTokenAmounts
//     ) internal view {
    
//     require(listingNftAddresses.length == listingNftIds.length, "Listing NFT lengths not compatible");
//     require(offerNftAddresses.length == offerNftIds.length, "Offer NFT lengths not compatible");
//     require(offerTokenAddresses.length == offerTokenAmounts.length, "Offer Token lengths not compatible");

//     // ensure listing is still valid
//     for(uint i=0; i<listingNftAddresses.length; i++){
//         require(ERC721(listingNftAddresses[i]).getApproved(listingNftIds[i]) == address(this), "contract not approved to transfer listed nft");
//     }

//     // require that Seller contract is approved to transfer all erc20 tokens
//     for(uint i=0; i<offerTokenAddresses.length; i++){
//         require(ERC20(offerTokenAddresses[i]).allowance(offererAddress, address(this)) >= offerTokenAmounts[i], "Seller contract not authorized to transfer ERC20s from offerer");
//     }

//     //require that Seller contract is approved to transfer ERC721 tokens
//     for(uint i=0; i<offerNftAddresses.length; i++){
//         require(ERC721(offerNftAddresses[i]).getApproved(offerNftIds[i])==address(this), "Seller contract not authorized to transfer ERC721 tokens from offerer");
//     }
// }
}