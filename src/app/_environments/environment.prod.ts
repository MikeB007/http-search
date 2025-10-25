// Production environment for GitHub Pages deployment
// Uses CORS proxy to avoid Mixed Content errors

export const Settings = {
  // Using corsproxy.io - supports custom headers better than allOrigins
  // Note: This is a free service and may have rate limits
  server_url: "https://corsproxy.io/?http://147.194.240.208:5000",
  useProxy: true,
  // Original backend URL (for reference)
  originalBackend: "http://147.194.240.208:5000"
}
