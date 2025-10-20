/** @type {import('next').NextConfig} */
const nextConfig = {
  // Configure image domains for external images
  images: {
    domains: ['localhost'],
    unoptimized: true, // Required for static export
  },
  
  // Output configuration for Netlify
  output: 'standalone',
  
  // Disable Turbopack for production builds (Netlify compatibility)
  // You can still use it locally with: npm run dev
  
  // Environment variables are automatically available via NEXT_PUBLIC_ prefix
};

export default nextConfig;
