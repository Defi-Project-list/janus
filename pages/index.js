import React, { useRef, useContext } from "react";
import Head from 'next/head';
import { useRouter } from 'next/router';
import { Flex, Input, InputGroup, InputLeftElement, InputRightElement } from "@chakra-ui/react";
import { SearchIcon } from "@chakra-ui/icons";
import { JanusIcon, WalletIcon } from "@/public/icons";
import NavBar from "@/components/Navbar";
import { Web3Context } from "@/contexts/Web3Context";

export default function Home() {

  const useFocus = () => {
    const htmlElRef = useRef(null)
    const setFocus = () => {htmlElRef.current &&  htmlElRef.current.focus()}
    return [ htmlElRef, setFocus ]
  }

  const router = useRouter();
  const web3Context = useContext(Web3Context);
  const { connectWallet } = web3Context;
  const [searchBox, setInputFocus] = useFocus();

  const handleKeyDown = (event) => {
    if (event.key === 'Enter') {
      router.push(`/${searchBox.current.value}`);
    }
  }

  async function populateAddress(){
    let add = await connectWallet();
    console.log(add);
    searchBox.current.value = add;
    setInputFocus();
  }

  return (
    <>
        <Head>
            <title>Janus</title>
            <meta name="description" content="Janus" />
            <link rel="icon" href="/favicon.ico" />
        </Head>
        <NavBar />
        <Flex direction="column" p="200px" alignItems="center" h="100vh">
          <Flex direction="column" justifyContent="center" alignItems="center" w={{base:"100vw", md:"50vw"}}>
            <JanusIcon boxSize={48} />
            <br/><br/>
            <InputGroup>
              <InputLeftElement pointerEvents="none" >
                <SearchIcon color="gray.300" mt="22px" ml="10px"/>
              </InputLeftElement>
              <Input ref={searchBox} autoFocus type="text" onKeyDown={handleKeyDown} placeholder="Ethereum Address" py="30px" px="100px" borderRadius="100px"/>
              <InputRightElement >
                <WalletIcon color="gray.300" mt="22px" mr="10px" onClick={populateAddress} cursor="pointer"/>
              </InputRightElement>
            </InputGroup>

          </Flex>
        </Flex>
    </>
  )
}
