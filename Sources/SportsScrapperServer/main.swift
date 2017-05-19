import Foundation
import Kitura
import HeliumLogger
import LoggerAPI
import CloudFoundryEnv
import Configuration
import SportsScrapperAPI

HeliumLogger.use()
let sportsScrapper = SportsScrapper()
Log.info("Attempting init with CF environment")
let controller = SportsScrapperController(backend: sportsScrapper)
let appEnv = ConfigurationManager()
let port = appEnv.port
Log.verbose("Assigned port \(port)")
Log.info("Server will start on \(appEnv.url)")
Kitura.addHTTPServer(onPort: port, with: controller.router)
Kitura.run()
