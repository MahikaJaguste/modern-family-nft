const {setupUsers, setupUser} = require('./utils');
const { expect, anyUint } = require("chai");
const { ethers, deployments, getNamedAccounts, getUnnamedAccounts } = require("hardhat");
const { networkConfig, tokenUris } = require('../helper-hardhat-config');

async function setup () {
    // it first ensures the deployment is executed and reset (use of evm_snapshot for faster tests)
    await deployments.fixture(["modernFamily", "mocks"]);
  
    // we get an instantiated contract in the form of a ethers.js Contract instance:
    const contracts = {
      ModernFamily: (await ethers.getContract('ModernFamily')),
      VRFCoordinatorV2Mock: (await ethers.getContract('VRFCoordinatorV2Mock')),
    };
  
    // we get the alice
    const {deployer, alice} = await getNamedAccounts();
  
    // Get the unnammedAccounts (which are basically all accounts not named in the config,
    // This is useful for tests as you can be sure they have noy been given tokens for example)
    // We then use the utilities function to generate user objects
    // These object allow you to write things like `users[0].ModernFamily.transfer(....)`
    const users = await setupUsers(await getUnnamedAccounts(), contracts);

    const chainId = network.config.chainId;

    // finally we return the whole object (including the alice setup as a User object)
    return {
      ...contracts,
      users,
      deployer: await setupUser(deployer, contracts),
      alice: await setupUser(alice, contracts),
      chainId
    };
  }

describe("ModernFamily contract", function() {

  describe("Deployment", function () {

    it("Should set the initial values correctly", async function () {
      // before the test, we call the fixture function.
      const { ModernFamily, chainId, deployer } = await setup();

      expect(await ModernFamily.owner()).to.equal(deployer.address);
      expect(await ModernFamily.getMintFee()).to.equal(networkConfig[chainId]["mintFee"])
      expect(await ModernFamily.getCharacterTokenUri(0)).to.equal(tokenUris[0])
      expect(await ModernFamily.getTokenCounter()).to.equal(0)
    });
  });

  describe("Only Owner", function () {

    it("Should update mint fee correctly", async function () {
      // before the test, we call the fixture function.
      const { ModernFamily, chainId, deployer, alice } = await setup();

      await expect(alice.ModernFamily.updateMintFee(networkConfig[chainId]["mintFee"] + 1)).to.be.reverted;
      await deployer.ModernFamily.updateMintFee(networkConfig[chainId]["mintFee"] + 1);
      expect(await ModernFamily.getMintFee()).to.equal(networkConfig[chainId]["mintFee"] + 1);
    });

    it("Should withdraw funds correctly", async function () {
      // before the test, we call the fixture function.
      const { chainId, deployer, alice} = await setup();

      await expect(alice.ModernFamily.requestNFT({value:networkConfig[chainId]["mintFee"]}))
      .to.changeEtherBalance(alice.address, "-".concat(networkConfig[chainId]["mintFee"]));

      await expect(alice.ModernFamily.withdraw()).to.be.reverted;
      await expect(deployer.ModernFamily.withdraw())
      .to.changeEtherBalance(deployer.address, networkConfig[chainId]["mintFee"]);
    }); 
  });

  describe("Minting", function () {

    it("Should mint only if sufficient fee is paid", async function () {
      // before the test, we call the fixture function.
      const { ModernFamily, alice } = await setup();
      await expect(alice.ModernFamily.requestNFT({value:1})).to.be.revertedWithCustomError(
        ModernFamily,
        "ModernFamily__InSufficientMintFee"
      );
    });
 
    it("emits an event and kicks off a random word request", async function () {
      const { ModernFamily, chainId, deployer } = await setup();
      await expect(ModernFamily.requestNFT({value:networkConfig[chainId]["mintFee"]}))
      .to.emit(ModernFamily, "NftRequested")
      .withArgs(() =>true, deployer.address);
    });
  });



});