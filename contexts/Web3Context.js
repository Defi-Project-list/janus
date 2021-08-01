import React, { useState, useEffect } from 'react'
import { ethers } from "ethers";
import Web3Modal from "web3modal";
import Portis from "@portis/web3";
import WalletConnectProvider from "@walletconnect/web3-provider";

export const Web3Context = React.createContext(undefined);

export const Web3ContextProvider = ({children}) => {

  const [web3Modal, setWeb3Modal] = useState(undefined);
  const [provider, setProvider] = useState(undefined);
  const [signerAddress, setSignerAddress] = useState("");
  const [ensAddress, setEnsAddress] = useState("");
  const [isPortisLoading, setIsPortisLoading] = useState(false);

  useEffect(() => {

    const getAddress = async () => {
      const signer = provider.getSigner();
      const address = await signer.getAddress();
      setSignerAddress(ethers.utils.getAddress(address));
      let tp = new ethers.providers.InfuraProvider("mainnet","9f34d0bf5e1b4b36914fd5bc66c50b05");
      tp.lookupAddress(address).then((ensAdd)=>{
        if(Boolean(ensAdd) == true){
          setEnsAddress(ensAdd);
        }
      });

    }
    if (provider) {
      getAddress();
    }
    else {
      setSignerAddress("");
      setEnsAddress("");
    }

  }, [provider]);

  useEffect(() => {

    const providerOptions = {
      walletconnect: {
        package: WalletConnectProvider,
        options: {
          infuraId: '9f34d0bf5e1b4b36914fd5bc66c50b05',
        },
      },
      portis: {
        display: {
          name: "Portis",
          description: "Connect with your Email and Password"
        },
        package: Portis,
        options: {
          id: "d3230cb7-51c6-414f-a47f-293364021451"
        }
      }
    };

    let w3m = new Web3Modal({
      network: "mainnet",
      cacheProvider: true,
      theme: "dark",
      providerOptions,
    })

    setWeb3Modal(w3m);

  }, []);

  async function connectWallet(choice = "") {
    console.log("choice", choice);

    try {

      if (choice === "portis") {
        setIsPortisLoading(true);
      }

      let modalProvider;

      if (choice !== "") {
        modalProvider = await web3Modal.connectTo(choice);
      }
      else {
        modalProvider = await web3Modal.connect();
      }

      if (modalProvider.on) {
        modalProvider.on("accountsChanged", () => {
          window.location.reload();
        });
        modalProvider.on("chainChanged", () => {
          window.location.reload();
        });
      }
      const ethersProvider = new ethers.providers.Web3Provider(modalProvider);

      setProvider(ethersProvider);

    } catch(e) {
      disconnectWallet();
      console.log('NO_WALLET_CONNECTED', e);
    }

    setIsPortisLoading(false);
  }

  function disconnectWallet() {
    web3Modal?.clearCachedProvider();
    setProvider(undefined);
    setSignerAddress("");
    setEnsAddress("");
  }

  return (
    <Web3Context.Provider value={{
      connectWallet,
      disconnectWallet,
      provider,
      signerAddress,
      ensAddress,
      web3Modal,
      isPortisLoading
    }}>
        {children}
    </Web3Context.Provider>
  )

}
