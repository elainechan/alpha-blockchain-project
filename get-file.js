async function getFileFromIPFS(hash) {
    const file = await ipfs.cat(hash);
    return file.toString();
}


// Example usage
const hash = 'Qm...';  // Replace with your IPFS hash
getFileFromIPFS(hash).then(content => {
    console.log('File content:', content);
});
