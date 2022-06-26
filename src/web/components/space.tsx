import React from "react";
import styles from "../styles/Space.module.css";

import { useBoardState } from "../hooks/use_board_state";

export default function Space(props) {
  const { features, x, y, gameId } = props;
  const { move } = useBoardState(gameId);

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

  function handleMove(event) {
    event.preventDefault();
    move(x, y);
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

  return (
    <a href="#" className={styles.card} onClick={(e) => handleMove(e)}>
      {features.map((feature) => {
        return (
          <div
            className={`${styles.feature} ${styles[featureToClass[feature]]}`}
            key={`space(${x},${y},${feature})`}
          ></div>
        );
      })}
    </a>
  );
}
