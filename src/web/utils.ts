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
    () => window.localStorage.getItem(key) || initialValue
  );

  const setItem = (newValue: string) => {
    setValue(newValue);
    window.localStorage.setItem(key, newValue);
  };

  useEffect(() => {
    const newValue = window.localStorage.getItem(key);
    if (value !== newValue) {
      setValue(newValue || initialValue);
    }
  });

  const handleStorage = useCallback(
    (event: StorageEvent) => {
      if (event.key === key && event.newValue !== value) {
        setValue(event.newValue || initialValue);
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
