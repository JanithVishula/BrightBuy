// Single source of truth for the backend API base URL.
// Configured via NEXT_PUBLIC_API_URL (frontend/.env.local); falls back to
// localhost so `npm run dev` works without extra setup.

export const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:5001/api";

// Server origin without the trailing /api — used for building image/static URLs.
export const API_SERVER_URL = API_BASE_URL.replace(/\/api\/?$/, "");
