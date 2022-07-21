const networkConfig = {
    31337: {
        name: "localhost",
        // can add other attributes here
    },
    4: {
        name: "rinkeby",
        // can add other attributes here
    },
    5: {
        name: "goerli",
        // can add other attributes here
    },
    80001: {
        name: "mumbai",
        // can add other attributes here
    },
}

const DECIMALS = "18"
const developmentChains = ["hardhat", "localhost"]

module.exports = {
    networkConfig,
    developmentChains,
    DECIMALS,
}