import { useState, useEffect } from "react";
import { useGameContract } from "../contracts";

import styles from "../styles/Home.module.css";
import Space from "../components/space";

function GameGrid({ gameId }) {
  const [features, setFeatures] = useState({});
  const contract = useGameContract();

  const initGame = async () => {
    const numberOfFeatures = 5;
    const spacesPerFeature = 5;
    const featuresPositions = {};

    for (let feature = 0; feature < numberOfFeatures; feature++) {
      for (
        let featureSpace = 0;
        featureSpace < spacesPerFeature;
        featureSpace++
      ) {
        const { x, y } = await contract.features(feature, featureSpace);

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
    initGame().catch(console.error);
  }, []);

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
          <Space
            x={x}
            y={y}
            features={features[[x, y]]}
            gameId={gameId}
            key={`${x},${y}`}
          />
        );
      }
    }

    return spaces;
  };

  return <div className={styles.grid}>{renderFeatures()}</div>;
}

export default GameGrid;
