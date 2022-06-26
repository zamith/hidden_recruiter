import { Dispatch, useCallback, useEffect, useState } from "react";

export function useSSRLocalStorage(
  key: string,
  initial: string
): [string, Dispatch<string>] {
  return typeof window === "undefined"
    ? [initial, (value: string) => undefined]
    : useLocalStorage(key, initial);
}

export function useIsSSR() {
  const [isSSR, setIsSSR] = useState(true);

  useEffect(() => {
    setIsSSR(false);
  }, []);

  return isSSR;
}

function useLocalStorage(
  key: string,
  initialValue: string = ""
): [string, Dispatch<string>] {
  const [value, setValue] = useState(
    () => parseJSON(window.localStorage.getItem(key)) || initialValue
  );

  const setItem = (newValue: string) => {
    setValue(newValue);
    window.localStorage.setItem(key, stringifyJSON(newValue));
  };

  useEffect(() => {
    const newValue = window.localStorage.getItem(key);
    if (stringifyJSON(value) !== newValue) {
      setValue(parseJSON(newValue) || initialValue);
    }
  });

  const handleStorage = useCallback(
    (event: StorageEvent) => {
      if (event.key === key && event.newValue !== stringifyJSON(value)) {
        setValue(parseJSON(event.newValue) || initialValue);
      }
    },
    [value]
  );

  useEffect(() => {
    window.addEventListener("storage", handleStorage);
    return () => window.removeEventListener("storage", handleStorage);
  }, [handleStorage]);

  return [value, setItem];
}

function stringifyJSON(data) {
  return JSON.stringify(data, (key, value) =>
    typeof value === "bigint" ? value.toString() + "n" : value
  );
}

function parseJSON(json) {
  return JSON.parse(json, (key, value) => {
    if (typeof value === "string" && /^\d+n$/.test(value)) {
      return BigInt(value.substr(0, value.length - 1));
    }

    return value;
  });
}
