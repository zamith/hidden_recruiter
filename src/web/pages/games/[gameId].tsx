import type { NextPage } from "next";
import { useRouter } from "next/router";

import Layout from "../../components/layout";
import Profile from "../../components/profile";
import GameGrid from "../../components/game_grid";
import GameControls from "../../components/game_controls";
import styles from "../../styles/GamePage.module.css";

const GamePage: NextPage = () => {
  const router = useRouter();
  const { gameId } = router.query;

  if (!gameId) {
    return;
  }

  return (
    <Layout>
      <Profile />
      <div className={styles.container}>
        <GameGrid className={styles.grid} gameId={gameId} />
        <GameControls className={styles.controls} gameId={gameId} />
      </div>
    </Layout>
  );
};

export default GamePage;
