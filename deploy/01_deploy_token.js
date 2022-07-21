const { network } = require("hardhat")
const { developmentChains } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")

module.exports = async ({ getNamedAccounts, deployments }) => {

    const { deploy, log } = deployments
    const { deployer, tokenOwner } = await getNamedAccounts()

    log("----------------------------------------------------")

    const arguments = [tokenOwner]

    const token = await deploy("Token", {
        from: deployer,
        args: arguments,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })

    // Deploying a different version of the same contract 
    /*
    await deploy("MyToken_1", {
        contract: 'Token',
        from: deployer,
        args: arguments,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })
    */

    // Verify the deployment
    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(token.address, arguments)
    }
}

module.exports.tags = ["all", "Token", "main"]