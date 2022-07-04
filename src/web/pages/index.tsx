import type { NextPage } from "next";
import Head from "next/head";

import styles from "../styles/Home.module.css";
import Layout from "../components/layout";
import Profile from "../components/profile";
import Game from "../components/game";

const Home: NextPage = () => {
  return (
    <Layout>
      <div className={styles.container}>
        <Head>
          <title>Hidden Recruiter</title>
          <meta name="description" content="Hidden Recruiter ZK Game" />
        </Head>

        <main className={styles.main}>
          <h1 className={styles.title}>
            <a href="https://github.com/zamith/hidden_recruiter">
              Hidden Recruiter
            </a>
          </h1>

          <p className={styles.description}>
            Get started by editing creating a new game and sharing the link with
            your friends.
          </p>
          <Profile />
          <Game />
        </main>
      </div>
    </Layout>
  );
};

export default Home;
