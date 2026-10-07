import * as SecureStore from "expo-secure-store";

const TOKEN_KEY = "inklu.auth.token";
let token = null;

const decodePayload = (value) => {
  try {
    const payload = value?.split(".")[1];
    if (!payload) return null;
    const normalized = payload.replace(/-/g, "+").replace(/_/g, "/");
    const decoded = typeof atob === "function" ? atob(normalized) : globalThis.atob(normalized);
    return JSON.parse(decoded);
  } catch (error) {
    return null;
  }
};

export const isTokenExpired = (value = token) => {
  if (!value) return true;
  const payload = decodePayload(value);
  if (!payload?.exp) return true;
  return payload.exp * 1000 <= Date.now();
};

export const setSessionToken = (nextToken) => {
  token = nextToken || null;
  if (token && !isTokenExpired(token)) SecureStore.setItemAsync(TOKEN_KEY, token).catch(() => {});
};

export const restoreSessionToken = async () => {
  try {
    const storedToken = await SecureStore.getItemAsync(TOKEN_KEY);
    if (!storedToken || isTokenExpired(storedToken)) { await SecureStore.deleteItemAsync(TOKEN_KEY).catch(() => {}); token = null; return null; }
    token = storedToken;
    return token;
  } catch (error) { token = null; return null; }
};

export const clearSessionToken = async () => { token = null; await SecureStore.deleteItemAsync(TOKEN_KEY).catch(() => {}); };
export const authHeaders = () => isTokenExpired() ? {} : { Authorization: `Bearer ${token}` };
export const getSessionRole = () => isTokenExpired() ? null : decodePayload(token)?.role || null;
export const getSessionUserId = () => isTokenExpired() ? null : decodePayload(token)?.id || decodePayload(token)?._id || null;
