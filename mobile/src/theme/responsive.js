import { Dimensions, PixelRatio } from "react-native";

const { width, height } = Dimensions.get("window");
const BASE_WIDTH = 375;
const scale = width / BASE_WIDTH;

// Escala proporcionalmente sin permitir tamaños extremos en teléfonos pequeños/grandes.
export const rs = (size, min = size * 0.88, max = size * 1.12) => Math.round(Math.min(max, Math.max(min, size * scale)));
export const rw = (size, min = size * 0.9, max = size * 1.1) => Math.round(Math.min(max, Math.max(min, size * scale)));
export const rh = (size, min = size * 0.9, max = size * 1.1) => Math.round(Math.min(max, Math.max(min, size * (height / 812))));
export const font = (size) => PixelRatio.roundToNearestPixel(rs(size, size * 0.9, size * 1.08));
export const horizontalPadding = Math.max(16, Math.min(24, Math.round(width * 0.064)));
export const screenWidth = width;
export const screenHeight = height;
