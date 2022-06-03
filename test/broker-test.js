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

async function createSignature(tokens, tiers, signer) {
    if(tokens.length != tiers.length) {
        console.log("BAD LENGTH IN CREATESIGNATURE()")
        return -1;
    }

    let types = []
    for(let i = 0; i < tokens.length*2; i++) {
        types.push("uint256");
    }

    let values = tokens.concat(tiers);

    let messageHash = ethers.utils.solidityKeccak256(types, values)
    let sig = await signer.signMessage(hre.ethers.utils.arrayify(messageHash));
    return sig;
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
        for(let i = 0; i < numERC20; i++) {
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


    })


});







