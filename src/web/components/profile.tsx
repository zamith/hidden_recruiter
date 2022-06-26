import { useAccount, useConnect, useDisconnect } from "wagmi";
import { useIsSSR } from "../utils";

function Profile() {
  const { data: account } = useAccount();
  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();
  const isSSR = useIsSSR();

  if (!isSSR && account) {
    return (
      <div>
        Connected to {account.address}
        <button onClick={() => disconnect()}>Disconnect</button>
      </div>
    );
  }

  return <button onClick={() => connect(connectors[0])}>Connect Wallet</button>;
}

export default Profile;
