import { WagmiConfig, createClient, configureChains, chain } from "wagmi";
import { publicProvider } from "wagmi/providers/public";
import { jsonRpcProvider } from "wagmi/providers/jsonRpc";
import { InjectedConnector } from "wagmi/connectors/injected";

console.log(chain.polygon);

const { provider, chains } = configureChains(
  [chain.hardhat, chain.polygon],
  [
    publicProvider(),
    jsonRpcProvider({
      rpc: (currentChain) => {
        return { http: currentChain.rpcUrls.default };
      },
    }),
  ]
);

const client = createClient({
  autoConnect: true,
  connectors: [new InjectedConnector({ chains })],
  provider,
});

function Layout({ children }) {
  return <WagmiConfig client={client}>{children}</WagmiConfig>;
}

export default Layout;
