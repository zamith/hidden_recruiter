import React, { useEffect, useState } from "react";
import { useContractRead } from "wagmi";

import { gameContractInfoNoSigner } from "../contracts";
import styles from "../styles/Space.module.css";

export default function Space(props) {
  const { features, x, y, boardState, gameId } = props;
  const [agentsHere, setAgentsHere] = useState([]);
  const [recruiterHereAt, setRecruiterHereAt] = useState();

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

  const token = useContractRead(gameContractInfoNoSigner(), "tokens", {
    args: [gameId, x, y],
  });

  useEffect(() => {
    const moves = boardState.recruiterMovesToIndex();
    setRecruiterHereAt(moves[JSON.stringify([x, y])]);
  }, [boardState.recruiterMoves]);

  useEffect(() => {
    const position = boardState.agentPositions[JSON.stringify([x, y])];
    if (position) {
      setAgentsHere(position);
    }
  }, [boardState.agentPositions, boardState.agentLocation]);

  async function handleMove(event) {
    event.preventDefault();
    await boardState.move(x, y);
  }

  if (!features || features.length === 0) {
    return (
      <a href="#" className={styles.card} onClick={(e) => handleMove(e)}>
        <div
          className={`${styles.feature} ${styles.cardNoFeature}`}
          key={`space(${x},${y})`}
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
      </a>
    );
  }

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

            {token.data && token.data.revealed && (
              <div className={styles.token}>
                {token.data.numberRevelead && token.data.number.toString()}
              </div>
            )}
          </div>
        );
      })}
    </a>
  );
}
