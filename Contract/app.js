import React, { useEffect, useState } from "react";
import { ethers } from "ethers";
import PollABI from "./PollWithPoS_ABI.json";

const CONTRACT_ADDRESS = "0x50db3e12E4CC885CE00aFE08a85f58BB2F08D31D";

function App() {
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [contract, setContract] = useState(null);
  const [question, setQuestion] = useState("");
  const [options, setOptions] = useState([]);
  const [selectedOption, setSelectedOption] = useState(null);
  const [stakeAmount, setStakeAmount] = useState("0.01");
  const [message, setMessage] = useState("");

  useEffect(() => {
    const init = async () => {
      try {
        if (!window.ethereum) {
          alert("Please install MetaMask.");
          return;
        }

        await window.ethereum.request({ method: "eth_requestAccounts" });
        const _provider = new ethers.providers.Web3Provider(window.ethereum);
        const _signer = _provider.getSigner();
        const _contract = new ethers.Contract(CONTRACT_ADDRESS, PollABI, _signer);

        setProvider(_provider);
        setSigner(_signer);
        setContract(_contract);

        const pollQuestion = await _contract.question();
        const pollOptions = await _contract.getOptions();

        setQuestion(pollQuestion);
        setOptions(pollOptions);
      } catch (error) {
        console.error("Initialization error:", error);
        setMessage("Failed to load contract or connect to wallet.");
      }
    };

    init();
  }, []);

  const handleVote = async () => {
    if (selectedOption === null) {
      setMessage("Please select a voting option.");
      return;
    }

    let value;
    try {
      value = ethers.utils.parseEther(stakeAmount);
    } catch {
      setMessage("Invalid ETH amount.");
      return;
    }

    try {
      const tx = await contract.stakeAndVote(selectedOption, { value });
      setMessage("Waiting for transaction to confirm...");
      await tx.wait();
      setMessage("Your vote has been submitted!");
    } catch (err) {
      console.error(err);
      setMessage("Transaction failed. See console for details.");
    }
  };

  return (
    <div style={{ padding: 20 }}>
      <h2>📊 {question || "Loading..."}</h2>

      {options.map((opt, i) => (
        <div key={i}>
          <label>
            <input
              type="radio"
              name="vote"
              value={i}
              checked={selectedOption === i}
              onChange={() => setSelectedOption(i)}
            />
            {opt}
          </label>
        </div>
      ))}

      <input
        type="text"
        placeholder="ETH to stake"
        value={stakeAmount}
        onChange={(e) => setStakeAmount(e.target.value)}
        style={{ marginTop: 10 }}
      />
      <br />

      <button onClick={handleVote} style={{ marginTop: 10 }}>
        Submit Vote
      </button>

      <p style={{ marginTop: 10, color: "green" }}>{message}</p>
    </div>
  );
}

export default App;
