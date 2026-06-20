// Single source of truth for the backend API base URL.
// Configured ONLY via the NEXT_PUBLIC_API_URL environment variable.
//   - Local dev:  NEXT_PUBLIC_API_URL=http://localhost:5001/api  (frontend/.env.local)
//   - Production: set in your host's dashboard (e.g. Vercel) to
//                 https://<your-backend>.onrender.com/api
//
// Falls back to localhost so `npm run dev` works without extra setup.

export const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:5001/api";

// Server origin without the trailing /api — used for building image/static URLs.
export const API_SERVER_URL = API_BASE_URL.replace(/\/api\/?$/, "");
