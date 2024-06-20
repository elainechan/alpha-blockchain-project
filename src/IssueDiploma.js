import React, { useState } from 'react';
import web3 from './web3';
import DiplomaRegistry from './DiplomaRegistry';
import ipfs from './ipfs';


const IssueDiploma = () => {
  const [studentName, setStudentName] = useState('');
  const [institutionName, setInstitutionName] = useState('');
  const [degree, setDegree] = useState('');
  const [file, setFile] = useState(null);
  const [ipfsHash, setIpfsHash] = useState('');


  const onSubmit = async (event) => {
    event.preventDefault();


    const accounts = await web3.eth.getAccounts();


    const result = await ipfs.add(file);


    setIpfsHash(result.path);


    await DiplomaRegistry.methods.issueDiploma(
      studentName,
      institutionName,
      degree,
      result.path
    ).send({ from: accounts[0] });
  };


  return (
    <form onSubmit={onSubmit}>
      <h2>Issue Diploma</h2>
      <label>Student Name:</label>
      <input
        value={studentName}
        onChange={(event) => setStudentName(event.target.value)}
      />
      <label>Institution Name:</label>
      <input
        value={institutionName}
        onChange={(event) => setInstitutionName(event.target.value)}
      />
      <label>Degree:</label>
      <input
        value={degree}
        onChange={(event) => setDegree(event.target.value)}
      />
      <label>Diploma File:</label>
      <input
        type="file"
        onChange={(event) => setFile(event.target.files[0])}
      />
      <button type="submit">Issue Diploma</button>
    </form>
  );
};


export default IssueDiploma;
