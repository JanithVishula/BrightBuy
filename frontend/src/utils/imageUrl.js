// utils/imageUrl.js
import { API_SERVER_URL } from "../config/api";

/**
 * Get the full image URL
 * @param {string} imageUrl - The image URL from the database
 * @returns {string|null} - Full image URL or null
 */
export const getImageUrl = (imageUrl) => {
  if (!imageUrl) return null;

  // If URL already starts with http/https, return as-is (CDN URL)
  if (imageUrl.startsWith("http://") || imageUrl.startsWith("https://")) {
    return imageUrl;
  }

  // Otherwise, prepend the backend server origin (local uploaded images)
  return `${API_SERVER_URL}${imageUrl}`;
};
