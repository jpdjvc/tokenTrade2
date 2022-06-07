const assert = require("assert");
const { ethers, waffle, network} = require("hardhat");
const { expect } = require('chai');
// const keccak256 = require('keccak256');
// const { BigNumber } = require("ethers");
// const { it } = require("ethers/wordlists");
// const provider = waffle.provider;

// converts bigNumber array to normal array
function bigToNorm(x) {
    let res = []
    for(let i  = 0; i < x.length; i++) {
        res.push(x[i].toNumber());
    }
    return res;
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


// async function createSignature(tokens, tiers, signer) {
//     if(tokens.length != tiers.length) {
//         console.log("BAD LENGTH IN CREATESIGNATURE()");
//         return -1;
//     }

//     let types = [];
//     for(let i = 0; i < tokens.length*2; i++) {
//         types.push("uint256");
//     }

//     let values = tokens.concat(tiers);

//     let messageHash = ethers.utils.solidityKeccak256(types, values);
//     let sig = await signer.signMessage(hre.ethers.utils.arrayify(messageHash));
//     return sig;
// }


function encode(data){
    let dataTypes = ["address[]", "uint[]", "address[]", "uint[]", "address[]", "uint[]"];
    let encodedData = ethers.utils.defaultAbiCoder.encode(dataTypes, data);
    return encodedData;
}


async function createSignature(data, signer){
    if(data.length != 6){
        console.log("Data incomplete in createSignature()");
        return -1;
    }

    let dataTypes = ["address[]", "uint256[]", "address[]", "uint256[]", "address[]", "uint256[]"];
    // let encodedData = ethers.utils.defaultAbiCoder.encode(dataTypes, data);
    let encodedData = encode(data);
    let messageHash = ethers.utils.keccak256(encodedData);
    let sig = await signer.signMessage(ethers.utils.arrayify(messageHash));
    return [sig, encodedData];
}








describe('Basic Broker Testing', async function() {
    it('get factories', async function () {

        
        // get the accounts
        this.accounts = await hre.ethers.getSigners();

        const numERC20 = 5;
        const supply = 1000000;
        this.erc20s = [];

        // * Create and deploy ERC20s; store contacts in this.erc20s[]
        this.factory = await ethers.getContractFactory('JPToken')
        for(let i = 0; i < numERC20; i++) {
            let tempToken = await this.factory.deploy(supply);
            await tempToken.deployed();
            this.erc20s.push(tempToken);
        }
        
        const numNFTs = 5;
        this.nfts = [];

        // * Create and deploy NFTs; store contacts in this.nfts[]
        this.factory = await ethers.getContractFactory('NFT')
        for(let i = 0; i < numNFTs; i++) {
            let tempToken = await this.factory.deploy();
            await tempToken.deployed();
            this.nfts.push(tempToken);
        }

        // * Create and deploy the Broker
        this.factory = await ethers.getContractFactory('Broker');
        this.broker = await this.factory.deploy();


    });

    it('Single NFT swap', async function () {
        // give account[0] 1 nft from nfts[0]
        await this.nfts[0].connect(this.accounts[0]).mint();
        
        // give account[1] 1 nft from nfts[1]
        await this.nfts[0].connect(this.accounts[1]).mint();

        let sig0 = createSignature
    });


    it("Makes listing", async function(){
        this.listings = [];
        await this.nfts[0].connect(this.accounts[0]).approve(this.broker.address, 0);
        this.listings.push(([this.nfts[0].address, 0]));
    });

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
    it("Creates offer", async function(){
        // create offer by account[1] to bid on single nft from account[0]
        this.offers = [];
        let data = [            
            [this.listings[0][0]],
            [this.listings[0][1]],
            [this.nfts[0].address],
            [1],
            [this.erc20s[0].address],
            [10]
        ];

        
        await this.erc20s[0].connect(this.accounts[1]).approve(this.broker.address, 10);
        await this.nfts[0].connect(this.accounts[1]).approve(this.broker.address, 1);

        const [signedMessage, dataBytes] = await createSignature(data, this.accounts[1])
        

        this.offers.push({
            "signature":signedMessage,
            "offererAddress": this.accounts[1].address,
            "data": data,
            "dataBytes": dataBytes,
            // 'packedData': packedData
        });
        // console.log(this.offers[0]);
    });

    it("verify Offerer signature", async function(){
        expect(await this.broker.connect(this.accounts[0])._verifySignature(
            this.offers[0].signature, 
            this.offers[0].dataBytes,
            this.offers[0].offererAddress
            )).to.equal(true);
    });

    it("Verifies seller signature", async function (){
        [this.signedMessage, _] = await createSignature(this.offers[0].data, this.accounts[0])
        expect(await this.broker.connect(this.accounts[0])._verifySignature(
            this.signedMessage,
            this.offers[0].dataBytes,
            this.accounts[0].address
        )).to.equal(true, "did not verify seller signature correctly");
    });

    it("accepts offer", async function(){
        // const [signedMessage, dataBytes] = await createSignature(this.offers[0].data, this.accounts[0])
        // console.log(this.offers[0]);
        // console.log(
        //     this.signedMessage, 
        //     this.offers[0].signature,
        //     this.offers[0].offererAddress,
        //     this.offers[0].dataBytes);
        // console.log("offer: ", this.offers[0]);

        await this.broker.connect(this.accounts[0]).executeTrade(
            this.signedMessage,
            this.offers[0].signature,
            this.offers[0].offererAddress,
            this.offers[0].dataBytes,
            {gasLimit: 30000000}
        )
    });

    // it("tests decoding", async function(){
    //     console.log("Address of listing NFT: ", this.nfts[0].address);
    //     let encodedData = encode(this.offers[0].data);
    //     await this.broker.connect(this.accounts[0]).decodeData(encodedData);

    // })
    

    



        





});







