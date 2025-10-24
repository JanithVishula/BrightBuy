/** @type {import('next').NextConfig} */
const nextConfig = {
  // Configure image domains for external images
  images: {
    domains: ["localhost"],
    remotePatterns: [
      {
        protocol: "https",
        hostname: "**",
      },
    ],
  },

  // DO NOT use output: 'standalone' or 'export' with Netlify
  // The @netlify/plugin-nextjs handles the deployment automatically

  // Disable Turbopack for production builds (Netlify compatibility)
  // You can still use it locally with: npm run dev

  // Environment variables are automatically available via NEXT_PUBLIC_ prefix
};

export default nextConfig;
