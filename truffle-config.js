const HDWalletProvider = require('@truffle/hdwallet-provider');
const mnemonic = 'your mnemonic here';  // Replace with your MetaMask mnemonic


module.exports = {
  networks: {
    sepolia: {
      provider: () => new HDWalletProvider(mnemonic, `https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID`),
      network_id: 11155111,       // Sepolia's id
      gas: 5500000,        // Sepolia has a lower block limit than mainnet
      confirmations: 2,    // # of confirmations to wait between deployments
      timeoutBlocks: 200,  // # of blocks before a deployment times out
      skipDryRun: true     // Skip dry run before migrations
    },
  },
  compilers: {
    solc: {
      version: "0.8.0",    // Fetch exact version from solc-bin
    }
  }
};
