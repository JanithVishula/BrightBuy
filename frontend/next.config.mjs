/** @type {import('next').NextConfig} */
const nextConfig = {
  // Allow product images from the local backend and any https source.
  images: {
    remotePatterns: [
      { protocol: "http", hostname: "localhost" },
      { protocol: "https", hostname: "**" },
    ],
  },
};

export default nextConfig;
