import { application } from "controllers/application"
import MapController from "./map_controller"
import GeneratorController from "./generator_controller"
import LookupController from "./lookup_controller"
import PreviewController from "./preview_controller"

// Register controllers with the application
application.register("placekey-map", MapController)
application.register("placekey-generator", GeneratorController)
application.register("placekey-lookup", LookupController)
application.register("placekey-preview", PreviewController)

export { 
  MapController,
  GeneratorController,
  LookupController,
  PreviewController
}
