/**
* MIT License
*
* Copyright (c) 2017 The SilverLogic
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import Foundation
import Kitura
import SportsScraperAPI

APILogger.shared.log(message: "Beginning server setup", logLevel: .info)
let configuration = APIConfiguration()
let database: DatabaseConnector
do {
    APILogger.shared.log(message: "Attempting init with CF environment",
                         logLevel: .info)
    let service = try configuration.databaseConfiguration()
    database = DatabaseConnector(service: service)
} catch {
    APILogger.shared.log(message: "Could not retrieve CF env: init with defaults",
                         logLevel: .info)
    database = DatabaseConnector()
}
let sportsScraperRouter = SportsScraperRouter(database: database)
APILogger.shared.log(message: "Assigned port \(configuration.port)",
                     logLevel: .verbose)
APILogger.shared.log(message: "REST API can be accessed at \(configuration.url)",
                     logLevel: .info)
Kitura.addHTTPServer(onPort: configuration.port,
                     with: sportsScraperRouter.router)
Kitura.run()
