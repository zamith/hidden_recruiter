import {
  WagmiConfig,
  createClient,
  configureChains,
  chain,
  defaultChains,
} from "wagmi";
import { publicProvider } from "wagmi/providers/public";
import { jsonRpcProvider } from "wagmi/providers/jsonRpc";
import { InjectedConnector } from "wagmi/connectors/injected";

const { provider, chains } = configureChains(
  [chain.hardhat, ...defaultChains],
  [
    publicProvider(),
    jsonRpcProvider({
      rpc: (currentChain) => {
        if (currentChain.id !== chain.hardhat.id) return null;
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
