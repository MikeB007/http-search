// Production environment for GitHub Pages deployment
// Uses CORS proxy to avoid Mixed Content errors

export const Settings = {
  // Using allOrigins as a free CORS proxy
  // Alternative proxies: cors-anywhere, corsproxy.io
  server_url: "https://api.allorigins.win/raw?url=http://147.194.240.208:5000",
  useProxy: true,
  // Original backend URL (for reference)
  originalBackend: "http://147.194.240.208:5000"
}
