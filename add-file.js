const ipfsClient = require('ipfs-http-client');
const ipfs = ipfsClient({ host: 'ipfs.infura.io', port: '5001', protocol: 'https' });


async function addFileToIPFS(fileContent) {
    const { path } = await ipfs.add(fileContent);
    return path;
}


// Example usage
const fileContent = "Your diploma content here";
addFileToIPFS(fileContent).then(hash => {
    console.log('IPFS Hash:', hash);
});
