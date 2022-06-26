import type { NextPage } from "next";
import { useRouter } from "next/router";

import Layout from "../../components/layout";
import Profile from "../../components/profile";
import GameGrid from "../../components/game_grid";
import GameControls from "../../components/game_controls";

const GamePage: NextPage = () => {
  const router = useRouter();
  const { gameId } = router.query;

  return (
    <Layout>
      <Profile />
      <GameGrid gameId={gameId} />
      <GameControls gameId={gameId} />
    </Layout>
  );
};

export default GamePage;
