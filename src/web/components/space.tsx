import React, { useEffect, useState } from "react";
import styles from "../styles/Space.module.css";

export default function Space(props) {
  const { features, x, y, boardState } = props;
  const [agentsHere, setAgentsHere] = useState([]);

  const featureToClass = {
    0: "cardFeatureRed",
    1: "cardFeatureBlue",
    2: "cardFeatureGreen",
    3: "cardFeatureYellow",
    4: "cardFeaturePurple",
    5: "cardFeatureOrange",
    6: "cardFeatureWhite",
    7: "cardFeatureBlack",
  };

  async function getAgentsHere() {
    setAgentsHere(await boardState.agentsAt(x, y));
  }

  useEffect(() => {
    getAgentsHere();
  }, [boardState]);

  function handleMove(event) {
    event.preventDefault();
    boardState.move(x, y);
  }

  if (!features || features.length === 0) {
    return (
      <a href="#" className={styles.card} onClick={(e) => handleMove(e)}>
        <div
          className={`${styles.feature} ${styles.cardNoFeature}`}
          key={`space(${x},${y})`}
        ></div>
      </a>
    );
  }

  const recruiterHereAt = boardState.recruiterMovesToIndex()[[x, y]];

  return (
    <a href="#" className={styles.card} onClick={(e) => handleMove(e)}>
      {features.map((feature) => {
        return (
          <div
            className={`${styles.feature} ${styles[featureToClass[feature]]}`}
            key={`space(${x},${y},${feature})`}
          >
            {recruiterHereAt && (
              <div className={styles.recruiterToken}>{recruiterHereAt}</div>
            )}

            {agentsHere.map((agent, index) => (
              <div key={index} className={styles.agentToken} title={agent}>
                {agent}
              </div>
            ))}
          </div>
        );
      })}
    </a>
  );
}
