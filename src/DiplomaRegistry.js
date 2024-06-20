import web3 from './web3';
import DiplomaRegistry from './build/DiplomaRegistry.json';


const instance = new web3.eth.Contract(
  DiplomaRegistry.abi,
  '0x...YourDeployedContractAddress...'  // Replace with your deployed contract address
);
