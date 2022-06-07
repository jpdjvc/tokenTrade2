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
    
    struct Data{
        address[] listingNftAddresses;
        uint256[] listingNftIds;
        address[] offerNftAddresses;
        uint256[] offerNftIds;
        address[] offerTokenAddresses;
        uint256[] offerTokenAmounts;
    }


    function _verifySignature(
        bytes calldata _signature, 
        bytes memory _data, 
        address _expectedAddress) public pure returns(bool) {
        
        bytes32 dataHash = keccak256(_data);
        bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);
        address recoveredAddress = ECDSA.recover(message, _signature);
        require(recoveredAddress == _expectedAddress, "Signature not verified");
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

    // function decodeData(bytes memory _data) public view {
    //     (uint listingsLength,
    //     uint offerNftLength,
    //     uint offerErc20Length,
    //     address[] memory listingNftAddresses,
    //     uint[] memory listingNftIds,
    //     address[] memory offerNftAddresses, 
    //     uint[] memory offerNftIds,
    //     address[] memory offerTokenAddresses,
    //     uint[] memory offerTokenAmounts) = abi.decode(_data, (uint, uint, uint, address[], uint[], address[], uint[], address[], uint[]));          
    // }


    function executeTrade(
        bytes calldata _sellerSignature,
        bytes calldata _offererSignature,
        address _offererAddress,
        bytes calldata _data
        ) external {        
        
        // console.log("listing length: ", listingNftIds.length);

        // bytes memory packedData = abi.encodePacked(
        //     decodedData.listingNftAddresses, 
        //     decodedData.listingNftIds, 
        //     decodedData.offerNftAddresses, 
        //     decodedData.offerNftIds, 
        //     decodedData.offerTokenAddresses, 
        //     decodedData.offerTokenAmounts);
    
        
        // console.logString("here1");
        require(_verifySignature(_sellerSignature, _data, msg.sender), "Seller signature not verified");
        // console.logString("here2");
        require(_verifySignature(_offererSignature, _data, _offererAddress), "Offerer signature not verified");
        // console.logString("here3");
        // console.logBytes(_data);
        Data memory decodedData = abi.decode(_data, (Data));
        // console.log(decodedData.);



        // uint listingsLength;
        // uint offerNftLength;
        // uint offerErc20Length;
        // uint i = 32;
        // assembly{mstore(listingsLength, add(_data, i))} //store the first uint into listings lengths
        // i+=32;
        // assembly{mstore(offerNftLength, add(_data, i))} //store second uint 
        // i+=32;
        // assembly{mstore(offerErc20Length, add(_data, i))} //store third uint
        // i+=32;

        // console.log(listingsLength);
        // console.log(offerNftLength);
        // console.log(offerErc20Length);

        // abi.decode(_data, (uint256, uint256, uint256, address[], uint[], address[], uint[], address[], uint[]));

        // uint j;
        // address[] memory listingNftAddresses = new address[](listingsLength);
        // for(j = i; i<32*listingsLength+i; j += 32){
        //     assembly {mstore(add(listingNftAddresses, j), mload(add(_data, j)))}
        // }
        // i = j;

        // uint[] memory listingNftIds = new uint[](listingsLength);
        // for (; j <= 32*listingsLength + i; j += 32) {
        //     assembly {mstore(add(listingNftIds, j), mload(add(_data, j)))}
        // }
        // i = j;

        // address[] memory offerNftAddresses = new address[](offerNftLength);
        // for(; j<20*offerNftLength + i; j+=20){
        //     assembly {mstore(add(offerNftAddresses, j), mload(add(_data, j)))}
        // }
        // i = j;

        // uint[] memory offerNftIds = new uint[](offerNftLength);
        // for (; j <= 32*offerNftLength + i; j += 32) {
        //     assembly {mstore(add(offerNftIds, j), mload(add(_data, j)))}
        // }
        // i = j;

        // address[] memory offerTokenAddresses = new address[](offerErc20Length);
        // for(; j<32*offerErc20Length + i; j+=32){
        //     assembly {mstore(add(offerTokenAddresses, j), mload(add(_data, j)))}
        // }
        // i = j;

        // uint[] memory offerTokenAmounts = new uint[](offerErc20Length);
        // for (; i <= 32*offerErc20Length + i; j += 32) {
        //     assembly {mstore(add(offerTokenAmounts, j), mload(add(_data, j)))}
        // }

        uint i;
        // transfer offerers ERC20 tokens
        for(i=0; i<decodedData.offerTokenAddresses.length; i++){
            require(ERC20(decodedData.offerTokenAddresses[i]).transferFrom(_offererAddress, msg.sender, decodedData.offerTokenAmounts[i]), "Couldnt transfer offerer's ERC20 Tokens");
        }

        // transfer Owners NFTs
        for(i=0; i<decodedData.listingNftAddresses.length; i++){
            require(ERC721(decodedData.listingNftAddresses[i]).getApproved(decodedData.listingNftIds[i]) == address(this), "contract not approved to transfer listed nft");
            ERC721(decodedData.listingNftAddresses[i]).safeTransferFrom(msg.sender, _offererAddress, decodedData.listingNftIds[i]);
        }

        // transfer offerers NFTs
        for(i=0; i<decodedData.offerNftAddresses.length; i++){
            require(ERC721(decodedData.offerNftAddresses[i]).getApproved(decodedData.offerNftIds[i])==address(this), "Seller contract not authorized to transfer ERC721 tokens from offerer");
            ERC721(decodedData.offerNftAddresses[i]).safeTransferFrom(_offererAddress, msg.sender, decodedData.offerNftIds[i]);
        }
    }
}