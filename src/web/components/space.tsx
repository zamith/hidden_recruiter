import React from "react";
import styles from "../styles/Space.module.css";

export default function Space(props) {
  const { features, x, y } = props;
  const key = `space(${x},${y})`;

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

  if (!features || features.length === 0) {
    return (
      <div className={styles.card}>
        <div
          className={`${styles.feature} ${styles.cardNoFeature}`}
          key={key}
        ></div>
      </div>
    );
  }

  return (
    <div className={styles.card}>
      {features.map((feature) => {
        return (
          <div
            className={`${styles.feature} ${styles[featureToClass[feature]]}`}
            key={key}
          ></div>
        );
      })}
    </div>
  );
}
