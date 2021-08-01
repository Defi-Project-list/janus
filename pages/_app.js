import React from "react";
import { ChakraProvider } from "@chakra-ui/react";
import Head from 'next/head'

import customTheme from '@/styles/theme';
import { Web3ContextProvider } from '@/contexts/Web3Context';

const App = ({ Component, pageProps }) => {
  return (
    <Web3ContextProvider>
      <ChakraProvider theme={customTheme} resetCSS>
          <Head>
            <meta name="viewport" content="width=device-width, initial-scale=1" />
          </Head>
          <Component {...pageProps} />
      </ChakraProvider>
    </Web3ContextProvider>
  )
}

export default App
