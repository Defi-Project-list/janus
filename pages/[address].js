import React, { useState, useEffect, useContext } from 'react';
import Head from 'next/head';
import { useRouter } from 'next/router';
import Image from 'next/image';
import { Wrap, WrapItem, Heading, Button, Text, chakra, Box, Flex, useColorModeValue, useColorMode,useClipboard, InputGroup, Input, InputRightElement, Image as ChakraImage } from "@chakra-ui/react";
import { useDisclosure, Modal, ModalOverlay, ModalContent, ModalFooter, ModalHeader, ModalBody, ModalCloseButton} from "@chakra-ui/react"
import { ExternalLinkIcon } from '@chakra-ui/icons';
import useSWR from 'swr';
import QRCode from "react-qr-code";
import { Web3Context } from "@/contexts/Web3Context";
import { ethers } from 'ethers';
import { isAddress } from 'ethers/lib/utils';

import fetcher from 'designsystem/utils/fetcher';
import { VerifiedIcon } from '@/public/icons';
import { prettifyNumber, truncateAddress } from 'designsystem/utils/stringUtils';
import NavBar from '@/components/Navbar';
import { janusContractAbi, janusContractAddress} from '@/lib/constants';

const IdentitySection = () => {

    const router = useRouter();
    const { address } = router.query;

    const [trustScoreData, setTrustScoreData] = useState(null);
    const [trustScore, setTrustScore] = useState("...");

    const web3Context = useContext(Web3Context);
    const { connectWallet, signerAddress, provider } = web3Context;

    useEffect(() => {
        if (isAddress(address) === true){
            fetcher(`/api/identity?address=${address}`).then((data)=>{
                setTrustScore(data?.score?.toString());
                setTrustScoreData(data);
            });
        }
    }, [address]);

    async function tokenize(){
      connectWallet();

      const chainId = await ethereum.request({ method: 'eth_chainId' });
      if (parseInt(chainId) !== 80001) {
        alert("Switch network to Matic Mumbai Testnet");
      }
      else {
        const signer = provider.getSigner();
        console.log(janusContractAddress, janusContractAbi, signer);
        let janus = new ethers.Contract(janusContractAddress, janusContractAbi, signer);
        try {
          let result = await janus.updateScoreManual(signerAddress);
          console.log(result);
          alert("Done!");
        } catch (error) {
          alert(error?.message);
        }
      }

    }

    return (
        <Flex direction="column">
              <NavBar/>
              <br/>
              <br/>
              <br/>
                <Head>
                    <title>Janus</title>
                    <meta name="description" content="Janus" />
                    <link rel="icon" href="/favicon.ico" />
                </Head>
                <Flex direction="column" w="100%" align="center" alignItems="center">
                    <Flex
                        direction="column"
                        w={{base:"100%"}}
                        maxW="500px"
                        m={4}
                        padding={8}
                        color={useColorModeValue("black", "white")}
                        backgroundColor={useColorModeValue("#ececec30", "#3c3c3c30")}
                        borderColor={useColorModeValue("gray.200", "#121212")}
                        borderWidth="1px"
                        borderRadius="10px"
                        _hover={{
                            boxShadow: "2xl"
                        }}
                        cursor="pointer"
                        alignItems="center"
                        justifyContent="center"
                        textAlign="center"
                    >
                        <Heading
                        bgClip="text"
                        backgroundImage="url('/images/gradient.webp')"
                        backgroundSize="cover"
                        >
                        {address !== null ? truncateAddress(address) : ""}
                        <br/>
                        Your Trust Score is {trustScore}
                        </Heading>
                        <Button w="fit-content" variant="ghost" mt={2} onClick={tokenize}>
                          Tokenize it
                        </Button>
                    </Flex>
                </Flex>
                <Wrap spacing={1} display="flex" direction={{base:"column", md: "row"}} w="98%" justifyContent="center" alignItems="center">
                    <WrapItem>
                        <UnmarshalCard trustScoreData={trustScoreData} />
                    </WrapItem>
                    <WrapItem>
                        <SybilCard trustScoreData={trustScoreData} />
                    </WrapItem>
                    <WrapItem>
                        <PoHCard  trustScoreData={trustScoreData} />
                    </WrapItem>
                    <WrapItem>
                        <BrightIdCard address={address}/>
                    </WrapItem>
                    <WrapItem>
                        <DeepdaoCard trustScoreData={trustScoreData} />
                    </WrapItem>
                    <WrapItem>
                        <RabbitholeCard trustScoreData={trustScoreData} />
                    </WrapItem>
                    <WrapItem>
                        <ENSCard trustScoreData={trustScoreData} />
                    </WrapItem>
                    <WrapItem>
                        <UdCard trustScoreData={trustScoreData} />
                    </WrapItem>
                    <WrapItem>
                        <IdenaCard trustScoreData={trustScoreData} />
                    </WrapItem>
                    <WrapItem>
                        <MirrorCard trustScoreData={trustScoreData} />
                    </WrapItem>
                    <WrapItem>
                        <RaribleCard trustScoreData={trustScoreData} />
                    </WrapItem>
                    <WrapItem>
                        <SuperrareCard trustScoreData={trustScoreData} />
                    </WrapItem>
                    <WrapItem>
                        <FoundationCard trustScoreData={trustScoreData} />
                    </WrapItem>
                    <WrapItem>
                        <AsyncartCard trustScoreData={trustScoreData} />
                    </WrapItem>
                    <WrapItem>
                        <KnownoriginCard trustScoreData={trustScoreData} />
                    </WrapItem>
                    <br/>
                    <PoapSection mt={2} address={address}/>
                </Wrap>
          </Flex>
    )

}

export default IdentitySection;

const UnmarshalCard = ({trustScoreData}) => {

  return (
    <IdentityCard image_url="/images/unmarshal.webp">
      {
        trustScoreData === null ? "Loading" : Boolean(trustScoreData.unmarshal) === false ? (<><chakra.p size="xs" as="a" target="_blank" href="https://unmarshal.io/">Discover on Unmarshal</chakra.p></>) : (<><Text mr={1}>Verified</Text><VerifiedIcon color="blue.400"/></>)
      }
    </IdentityCard>
  );
};

const SybilCard = ({trustScoreData}) => {

    return (
      <IdentityCard image_url="/images/sybil.webp">
        {
          trustScoreData === null ? "Loading" : Boolean(trustScoreData.uniswapSybil) === false ? (<><chakra.p size="xs" as="a" target="_blank" href="https://sybil.org/">Verify on Uniswap Sybil</chakra.p></>) : (<><Text mr={1}>Verified</Text><VerifiedIcon color="blue.400"/></>)
        }
      </IdentityCard>
    );
};

const DeepdaoCard = ({trustScoreData}) => {

    return (
      <IdentityCard image_url="/images/deepdao.webp">
        {
          trustScoreData === null ? "Loading" : Boolean(trustScoreData.deepdao) === false ? (<><chakra.p size="xs" as="a" target="_blank" href="https://deepdao.io/">Explore on Deepdao</chakra.p></>) : (<><Text mr={1}>Verified</Text><VerifiedIcon color="blue.400"/></>)
        }
      </IdentityCard>
    );
};

const MirrorCard = ({trustScoreData}) => {

  return (
    <IdentityCard image_url="/images/mirror.webp">
      {
        trustScoreData === null ? "Loading" : Boolean(trustScoreData?.mirror) === false ? (<><chakra.p size="xs" as="a" target="_blank" href="https://mirror.xyz/">Join the $WRITE Race</chakra.p></>) : (<><Text mr={1}>Verified</Text><VerifiedIcon color="blue.400"/></>)
      }
    </IdentityCard>
  );
};

const PoHCard = ({trustScoreData}) => {

    return (
      <IdentityCard image_url="/images/poh.webp">
        {
          trustScoreData === null ? "Loading" : Boolean(trustScoreData?.poh) === false ? (<><chakra.p size="xs" as="a" target="_blank" href="https://app.proofofhumanity.id/">Click to Verify</chakra.p></>) : (<><Text mr={1}>Verified</Text><VerifiedIcon color="blue.400"/></>)
        }
      </IdentityCard>
    );
};

const ENSCard = ({ trustScoreData }) => {

    return (
      <IdentityCard image_url="/images/ens.webp">
        {
          trustScoreData === null ? (<><chakra.p size="xs" as="a" target="_blank" href="https://app.ens.domains/">Get your ENS</chakra.p></>) : (<><Text mr={1}>Connected</Text><VerifiedIcon color="blue.400"/></>)
        }
      </IdentityCard>
    );
};

const UdCard = ({ trustScoreData }) => {

    return (
      <IdentityCard image_url="/images/unstoppable.webp">
        {
          trustScoreData === null ? "Loading" : Boolean(trustScoreData?.unstoppableDomains) === false ? (<><chakra.p size="xs" as="a" target="_blank" href="https://unstoppabledomains.com/">Get your domain</chakra.p></>) : (<><Text mr={1}>Connected</Text><VerifiedIcon color="blue.400"/></>)
        }
      </IdentityCard>
    );
};

const IdenaCard = ({ trustScoreData }) => {

    return (
      <IdentityCard image_url="/images/idena.webp">
        {
          trustScoreData === null ? "Loading" : Boolean(trustScoreData?.idena) === false ? (<><chakra.p size="xs" as="a" target="_blank" href="https://www.idena.io/">Verify on Idena</chakra.p></>) : (<><Text mr={1}>Verified</Text><VerifiedIcon color="blue.400"/></>)
        }
      </IdentityCard>
    );
};

const RabbitholeCard = ({ trustScoreData }) => {

    return (
      <IdentityCard image_url="/images/rabbithole.webp">
        {
          trustScoreData === null ? "Loading" : Boolean(trustScoreData?.rabbitHole) === false ? (<><chakra.p size="xs" as="a" target="_blank" href="https://app.rabbithole.gg/">Explore on RabbitHole</chakra.p></>) : (<><Text mr={1}>Explorer on RabbitHole</Text><VerifiedIcon color="blue.400"/></>)
        }
      </IdentityCard>
    );
};

const BrightIdCard = ({ address }) => {

  const { isOpen, onOpen, onClose } = useDisclosure();
  const { hasCopied, onCopy } = useClipboard(`brightid://link-verification/http:%2f%2fnode.brightid.org/Convo/${address}`)
  const { colorMode } = useColorMode();

  const { data } = useSWR(
    address !== null ? [`https://app.brightid.org/node/v5/verifications/Convo/${address}`, "GET"] : null,
    fetcher
  );

  async function startVerify(){
    onOpen();
  }

  async function openInApp(){
    window.open(`brightid://link-verification/http:%2f%2fnode.brightid.org/Convo/${address}`, '_blank');
  }

  return (
    <IdentityCard image_url="/images/brightid.webp">
        <>
          {
            data === undefined ? "Loading" : Boolean(data?.error) === true ? (<><chakra.p size="sm" onClick={startVerify} cursor="pointer">Click to Verify</chakra.p></>) : (<><Text mr={1}>Verified</Text><VerifiedIcon color="blue.400"/></>)
          }
          <Modal isOpen={isOpen} onClose={onClose}>
            <ModalOverlay backdropFilter="blur(10px)"/>
            <ModalContent>
              <ModalHeader>Scan QR</ModalHeader>
              <ModalCloseButton />
              <ModalBody align="center">
                <chakra.h3
                  py={2}
                  textAlign="center"
                  fontWeight="bold"
                  color={colorMode === "light" ? "gray.800" : "white"}
                  letterSpacing={1}
                >
                  Scan the QR Code in your Bright ID App.
                </chakra.h3>
                <QRCode value={`brightid://link-verification/http:%2f%2fnode.brightid.org/Convo/${address}`} bgColor="transparent" fgColor={useColorModeValue("black","white")}/>
                <br/>
                <Button size="md" onClick={openInApp}>
                  Open in App
                </Button>
                <br/><br/>
                <InputGroup size="md">
                  <Input
                    pr="4.5rem"
                    type="text"
                    readOnly
                    value={`brightid://link-verification/http:%2f%2fnode.brightid.org/Convo/${address}`}
                  />
                  <InputRightElement width="4.5rem">
                    <Button h="1.75rem" size="sm" onClick={onCopy} >
                      {hasCopied? "Copied" : "Copy"}
                    </Button>
                  </InputRightElement>
                </InputGroup>
                <br/>
              </ModalBody>
            </ModalContent>
          </Modal>
        </>
    </IdentityCard>
    );
};

const PoapSection = ({address}) => {

    const [poaps, setPoaps] = useState(null);

    const { isOpen, onOpen, onClose } = useDisclosure();
    const [poapDetails, setPoapDetails] = useState(null);

    useEffect(() => {
        if (Boolean(address) === true) {
            fetcher(`https://api.poap.xyz/actions/scan/${address}`, "GET", {}).then(setPoaps);
        }
    }, [address]);

    function showDetails(id) {
        setPoapDetails({
        'eventName':poaps[id].event.name,
        'description':poaps[id].event.description,
        'tokenId':poaps[id].tokenId,
        'eventLink':poaps[id].event.event_url,
        });
        onOpen();
    }

  if (poaps && poaps.length > 0){
    return (
      <Wrap>
        <Modal isOpen={isOpen} onClose={onClose}>
          <ModalOverlay backdropFilter="blur(10px)"/>
          <ModalContent>
            <ModalHeader>{poapDetails?.eventName}</ModalHeader>
            <ModalCloseButton />
            <ModalBody>
            {poapDetails?.description}
            </ModalBody>
            <ModalFooter>
              <Button as="a" href={poapDetails?.eventLink} target="_blank" variant="ghost" size="sm">
                View Event <ExternalLinkIcon ml={2}/>
              </Button>
            </ModalFooter>
          </ModalContent>
        </Modal>
        {
          poaps.map((poap, index)=>{
            return (
              <WrapItem key={poap.tokenId}>
                <ChakraImage
                  h={40}
                  w={40}
                  fit="contain"
                  p={1}
                  src={poap.event.image_url}
                  alt={poap.event.name}
                  onClick={()=>{showDetails(index)}}
                  cursor="pointer"
                  _hover={{
                    transform:"scale(1.01)"
                  }}
                />
              </WrapItem>
            );
          })
        }
      </Wrap>
    )
  }
  else {
    return ( <></> )
  }
};

const RaribleCard = ({trustScoreData}) => {

    return (
      <IdentityCard image_url="/images/rarible.webp">
        {
          trustScoreData === null ? "Loading" :
          trustScoreData?.rarible?.totalCountSold === 0 ? (
              <chakra.p size="xs" as="a" target="_blank" href="https://rarible.com/">
                Create on Rarible
              </chakra.p>
            ) : (
              <>
                <Text mr={1}>
                  {trustScoreData.rarible.totalCountSold + " sold for $" + prettifyNumber(trustScoreData.rarible.totalAmountSold)}
                </Text>
                <VerifiedIcon color="blue.400"/>
              </>
            )
        }
      </IdentityCard>
    );
};

const SuperrareCard = ({trustScoreData}) => {

    return (
      <IdentityCard image_url="/images/superrare.webp">
        {
          trustScoreData === null ? "Loading" :
          trustScoreData?.superrare?.totalCountSold === 0 ? (
              <chakra.p size="xs" as="a" target="_blank" href="https://superrare.com/">
                Create on SuperRare
              </chakra.p>
            ) : (
              <>
                <Text mr={1}>
                  {trustScoreData.superrare.totalCountSold + " sold for $" + prettifyNumber(trustScoreData.superrare.totalAmountSold)}
                </Text>
                <VerifiedIcon color="blue.400"/>
              </>
            )
        }
      </IdentityCard>
    );
};

const KnownoriginCard = ({trustScoreData}) => {

    return (
      <IdentityCard image_url="/images/knownorigin.webp">
        {
          trustScoreData === null ? "Loading" :
          trustScoreData?.knownorigin?.totalCountSold === 0 ? (
              <chakra.p size="xs" as="a" target="_blank" href="https://knownorigin.io/">
                Create on KnownOrigin
              </chakra.p>
            ) : (
              <>
                <Text mr={1}>
                  {trustScoreData?.knownorigin?.totalCountSold + " sold for $" + prettifyNumber(trustScoreData?.knownorigin?.totalAmountSold)}
                </Text>
                <VerifiedIcon color="blue.400"/>
              </>
            )
        }
      </IdentityCard>
    );
};

const FoundationCard = ({trustScoreData}) => {

    return (
      <IdentityCard image_url="/images/foundation.webp">
        {
          trustScoreData === null ? "Loading" :
          trustScoreData?.foundation?.totalCountSold === 0 ? (
              <chakra.p size="xs" as="a" target="_blank" href="https://foundation.app/">
                Create on Foundation
              </chakra.p>
            ) : (
              <>
                <Text mr={1}>
                  {trustScoreData.foundation.totalCountSold + " sold for $" + prettifyNumber(trustScoreData.foundation.totalAmountSold)}
                </Text>
                <VerifiedIcon color="blue.400"/>
              </>
            )
        }
      </IdentityCard>
    );
};

const AsyncartCard = ({trustScoreData}) => {

    return (
      <IdentityCard image_url="/images/asyncart.webp">
        {
          trustScoreData === null ? "Loading" :
          trustScoreData?.asyncart?.totalCountSold === 0 ? (
              <chakra.p size="xs" as="a" target="_blank" href="https://async.art/">
                Create on AsyncArt
              </chakra.p>
            ) : (
              <>
                <Text mr={1}>
                  {trustScoreData.asyncart.totalCountSold + " sold for $" + prettifyNumber(trustScoreData.asyncart.totalAmountSold)}
                </Text>
                <VerifiedIcon color="blue.400"/>
              </>
            )
        }
      </IdentityCard>
    );
};

const IdentityCard = (props) => {

    const { colorMode } = useColorMode();
    return (
        <Flex
          direction="column"
          justifyContent="center"
          alignItems="center"
          w="100%"
          m={1}
        >
          <Image src={props.image_url} alt="" width="288px" height="162px" className="br-10" />

          <Box
            w={{ base: 56, md: 64 }}
            bg={colorMode === "light" ? "white" : "gray.800"}
            mt={-6}
            shadow="lg"
            rounded="lg"
            overflow="hidden"
          >
            <Flex
              alignItems="center"
              justifyContent="center"
              py={2}
              px={3}
              backdropFilter="blur(300px) opacity(1)"
            >
              {props.children}
            </Flex>
          </Box>
        </Flex>
    );
  }
