async function fetchPDF() {
    console.log('Fetch PDF button clicked');
    
    // Initialize Web3
    if (window.ethereum) {
        window.web3 = new Web3(window.ethereum);
        await window.ethereum.enable();
    } else if (window.web3) {
        window.web3 = new Web3(window.web3.currentProvider);
    } else {
        console.log("Non-Ethereum browser detected. You should consider trying MetaMask!");
        return;
    }

    // Contract ABI and Address
    const abi = [
						{
							"inputs": [],
							"name": "getHash",
							"outputs": [
								{
									"internalType": "string",
									"name": "",
									"type": "string"
								}
							],
							"stateMutability": "view",
							"type": "function"
						},
						{
							"inputs": [],
							"name": "ipfsHash",
							"outputs": [
								{
									"internalType": "string",
									"name": "",
									"type": "string"
								}
							],
							"stateMutability": "view",
							"type": "function"
						},
						{
							"inputs": [
								{
									"internalType": "string",
									"name": "_hash",
									"type": "string"
								}
							],
							"name": "setHash",
							"outputs": [],
							"stateMutability": "nonpayable",
							"type": "function"
						}
					];
    const contractAddress = '0xc14c380268bba363106d31dc4812b02d7e2d8946';

    // Create contract instance
    const contract = new web3.eth.Contract(abi, contractAddress);
    console.log('Contract instance created');

    try {
      // Call the getHash function to retrieve the IPFS hash
      const ipfsHash = await contract.methods.getHash().call();
      console.log('IPFS Hash:', ipfsHash);
    
      // Fetch the PDF from IPFS using the hash
      const pdfUrl = `https://gateway.pinata.cloud/ipfs/${ipfsHash}`;
      console.log('PDF URL:', pdfUrl);
      
      const response = await fetch(pdfUrl);
      const blob = await response.blob();
      const blobUrl = URL.createObjectURL(blob);
        
      // Display the PDF in the iframe
      const pdfFrame = document.getElementById('pdf-frame');
      pdfFrame.src = blobUrl;
      
    } catch (error) {
      console.error('Error fetching PDF: ', error);
    }

    // Fetch the file from IPFS using the hash
    //const response = await fetch(`https://gateway.pinata.cloud/ipfs/${ipfsHash}`);
    //const fileContent = await response.text();

    // Display the file content
    //document.getElementById('file-content').innerText = fileContent;
}
