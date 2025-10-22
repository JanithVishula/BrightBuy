// Centralized API configuration using links.json
import linksConfig from '../../../config/links.json';

// Determine environment based on hostname or NODE_ENV
const getEnvironment = () => {
  if (typeof window !== 'undefined') {
    // Client-side: check hostname
    const hostname = window.location.hostname;
    if (hostname.includes('railway.app') || hostname.includes('netlify.app')) {
      return 'production';
    }
  }
  // Server-side or localhost: use NODE_ENV
  return process.env.NODE_ENV === 'production' ? 'production' : 'development';
};

const env = getEnvironment();
const config = linksConfig[env];

console.log(`API Config loaded for environment: ${env}`);
console.log(`API Base URL: ${config.apiUrl}`);

export const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || config.apiUrl;
export const API_SERVER_URL = process.env.NEXT_PUBLIC_API_SERVER_URL || config.backendUrl;
