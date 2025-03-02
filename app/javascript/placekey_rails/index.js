// Import controllers
import "./controllers"

// Export library
export default {
  name: "PlacekeyRails",
  version: "0.1.0"
}

// Attach to window for global access (if in browser environment)
if (typeof window !== 'undefined') {
  window.PlacekeyRails = window.PlacekeyRails || {}
  window.PlacekeyRails.version = "0.1.0"
}
