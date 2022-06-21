import type { NextPage } from "next";
import { useState, useEffect } from "react";
import detectEthereumProvider from "@metamask/detect-provider";
import { providers, Contract, utils } from "ethers";
import Head from "next/head";
import Image from "next/image";
import styles from "../styles/Home.module.css";
import Game from "../../../artifacts/src/contracts/Game.sol/Game.json";
import Space from "../components/space";

const Home: NextPage = () => {
  const [contracts, setContracts] = useState({});
  const [features, setFeatures] = useState({});

  const initContracts = async () => {
    const provider = (await detectEthereumProvider()) as any;
    const ethers = new providers.Web3Provider(provider);

    const gameContract = new Contract(
      "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
      Game.abi,
      ethers
    );

    setContracts({ game: gameContract });
  };

  const initGame = async () => {
    if (!contracts?.game) {
      return;
    }

    const numberOfFeatures = 5;
    const spacesPerFeature = 5;
    const featuresPositions = {};

    for (let feature = 0; feature < numberOfFeatures; feature++) {
      for (
        let featureSpace = 0;
        featureSpace < spacesPerFeature;
        featureSpace++
      ) {
        const { x, y } = await contracts.game.features(feature, featureSpace);

        if (featuresPositions[[x, y]]) {
          featuresPositions[[x, y]].push(feature);
        } else {
          featuresPositions[[x, y]] = [feature];
        }
      }
    }

    setFeatures(featuresPositions);
  };

  useEffect(() => {
    initContracts().catch(console.error);
  }, []);

  useEffect(() => {
    initGame().catch(console.error);
  }, [contracts]);

  const renderFeatures = () => {
    if (features.length === 0) {
      return;
    }

    const horizontalSpaces = 6;
    const verticalSpaces = 7;
    const spaces = [];

    for (let y = verticalSpaces - 1; y >= 0; y--) {
      for (let x = 0; x < horizontalSpaces; x++) {
        spaces.push(
          <Space x={x} y={y} features={features[[x, y]]} key={`${x},${y}`} />
        );
      }
    }

    console.log(spaces);

    return spaces;
  };

  return (
    <div className={styles.container}>
      <Head>
        <title>Create Next App</title>
        <meta name="description" content="Generated by create next app" />
      </Head>

      <main className={styles.main}>
        <h1 className={styles.title}>
          Welcome to <a href="https://nextjs.org">Next.js!</a>
        </h1>

        <p className={styles.description}>
          Get started by editing{" "}
          <code className={styles.code}>pages/index.tsx</code>
        </p>

        <div className={styles.grid}>{renderFeatures()}</div>
      </main>
    </div>
  );
};

export default Home;
