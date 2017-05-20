import Foundation
import Kitura
import HeliumLogger
import LoggerAPI
import CloudFoundryEnv
import Configuration
import SportsScraperAPI

HeliumLogger.use()
let sportsScrapper = SportsScraper()
Log.info("Attempting init with CF environment")
let sportsScraperRouter = SportsScraperRouter(backend: sportsScrapper)
let appEnv = ConfigurationManager()
let port = appEnv.port
Log.verbose("Assigned port \(port)")
Log.info("REST API can be accessed at \(appEnv.url)")
Kitura.addHTTPServer(onPort: port, with: sportsScraperRouter.router)
Kitura.run()
