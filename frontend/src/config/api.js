// Centralized API configuration
export const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL || "https://gallant-friendship-production.up.railway.app/api";
export const API_SERVER_URL =
  process.env.NEXT_PUBLIC_API_URL?.replace("/api", "") ||
  "https://gallant-friendship-production.up.railway.app";
