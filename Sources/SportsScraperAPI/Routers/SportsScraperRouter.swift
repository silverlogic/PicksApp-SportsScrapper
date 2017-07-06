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
import ResponseTime
import SwiftyJSON
import Dispatch

/**
    A class responsible for handling
    routing in the server.
*/
public final class SportsScraperRouter {
    
    // MARK: - Private Instance Atrributes
    fileprivate let database: DatabaseConnector
    
    
    // MARK: - Public Instance Attributes
    public let router = Router()
    
    
    // MARK: - Initializers
    
    /**
        Initializes an instance of `SportsScrapperController`.
     
        - Parameter database: A `DatabaseConnector` representing
                              the scrapper used for scrapping.
    */
    public init(database: DatabaseConnector) {
        self.database = database
        routeSetup()
    }
}


// MARK: - Private Instance Methods
fileprivate extension SportsScraperRouter {
    
    /// Sets up all avaliable routes.
    func routeSetup() {
        router.all(middleware: ResponseTime())
        router.all("/*", middleware: BodyParser())
        router.get("/live-schedule/:leagueType/:year/:week",
                   handler: handleLiveScheduleRoute)
        router.get("/historical-schedule/:leagueType/:year/:week",
                   handler: handleHistoricalScheduleRoute)
        router.get("/current/:leagueType",
                   handler: handleCurrentSeasonWeekRoute)
        router.get("/mock-data/:leagueType/:timePeriod",
                   handler: handleMockDataRoute)
    }
    
    /**
        Handler for the live schedule route.
     
        - Parameters:
            - request: A `RouterRequest` representing the request
                       object sent from the client.
            - response: A `RouterResponse` representing the response
                        object to send back to the client.
            - next: A closure that gets invoked to handle the next
                    request.
    */
    func handleLiveScheduleRoute(request: RouterRequest,
                                 response: RouterResponse,
                                 next: () -> Void) {
        do {
            guard let type = request.parameters["leagueType"] else {
                try response.status(.badRequest)
                    .send(json: APIError.leagueType.json())
                    .end()
                APILogger.shared.log(message: APIError.leagueType.errorDesciption,
                                     logLevel: .error)
                return
            }
            guard let year = request.parameters["year"] else {
                try response.status(.badRequest)
                    .send(json: APIError.year.json())
                    .end()
                APILogger.shared.log(message: APIError.year.errorDesciption,
                                     logLevel: .error)
                return
            }
            guard let week = request.parameters["week"]  else {
                try response.status(.badRequest)
                    .send(json: APIError.week.json())
                    .end()
                APILogger.shared.log(message: APIError.week.errorDesciption,
                                     logLevel: .error)
                return
            }
            guard let league = Int(type),
                  let season = Int(year),
                  let weekInSeason = Int(week) else {
                    try response.status(.badRequest).end()
                    APILogger.shared.log(message: "Error casting path parameters to integers",
                                         logLevel: .error)
                    return
            }
            guard let leagueType = LeagueType(rawValue: league) else {
                try response.status(.badRequest)
                    .send(json: APIError.invalidLeague.json())
                    .end()
                APILogger.shared.log(message: APIError.invalidLeague.errorDesciption,
                                     logLevel: .error)
                return
            }
            switch leagueType {
            case .nfl:
                if season < 2001 {
                    do {
                        try response.status(.badRequest).send(json: APIError.minmumYearNotMetLive.json()).end()
                    } catch {
                        APILogger.shared.log(message: "Communications error",
                                             logLevel: .error)
                    }
                }
                database.fetchNflDocuments(type: NflLive.self,
                                           season: season,
                                           week: weekInSeason,
                                           success: { (results: [NflLive]) in
                    if results.count == 0 {
                        let nflScraper = NflScraper(season: season, week: weekInSeason)
                        nflScraper.scrapeLiveSchedule(success: { (results) in
                            do {
                                try response.status(.OK)
                                    .send(json: JSON(results))
                                    .end()
                            } catch {
                                APILogger.shared.log(message: "Communications error",
                                                     logLevel: .error)
                            }
                            let completedSchedules = results.filter {
                                return $0["gameStatus"].stringValue == "FINAL " ||
                                       $0["gameStatus"].stringValue == "FINAL OT"
                            }
                            if completedSchedules.count == results.count {
                                let dispatchQueue = DispatchQueue.global(qos: .utility)
                                let dispatchGroup = DispatchGroup()
                                var databaseError: Error?
                                for schedule in completedSchedules {
                                    dispatchGroup.enter()
                                    dispatchQueue.async {
                                        self.database.insertDocument(schedule, success: {
                                            dispatchGroup.leave()
                                        }, failure: { (error) in
                                            databaseError = error
                                            dispatchGroup.leave()
                                        })
                                    }
                                }
                                dispatchGroup.notify(queue: DispatchQueue.main) {
                                    guard databaseError == nil else {
                                        APILogger.shared.log(message: "Error inserting schedules into database",
                                                             logLevel: .error)
                                        APILogger.shared.log(message: "\((databaseError?.localizedDescription)!)",
                                                             logLevel: .error)
                                        return
                                    }
                                    APILogger.shared.log(message: "Inserted live NFL schedules for season \(season) and week \(weekInSeason)",
                                                         logLevel: .error)
                                }
                            }
                        }, failure: { (error) in
                            do {
                                if let scrapperError = error {
                                    try response.status(.internalServerError)
                                        .send(json: APIError(errorDescription: scrapperError.localizedDescription).json())
                                        .end()
                                } else {
                                    try response.status(.internalServerError)
                                        .send(json: APIError.scrapperError.json())
                                        .end()
                                }
                                APILogger.shared.log(message: APIError.scrapperError.errorDesciption,
                                                     logLevel: .error)
                            } catch {
                                APILogger.shared.log(message: "Communications error",
                                                     logLevel: .error)
                            }
                        })
                    } else {
                        let schedules: [JSON] = results.flatMap { $0.json() }
                        do {
                            try response.status(.OK)
                                .send(json: JSON(schedules))
                                .end()
                        } catch {
                            APILogger.shared.log(message: "Communications error",
                                                 logLevel: .error)
                        }
                    }
                }, failure: { (error) in
                    do {
                        if let databaseError = error {
                            try response.status(.internalServerError)
                                        .send(json: APIError(errorDescription: databaseError.localizedDescription).json())
                                        .end()
                        } else {
                            try response.status(.internalServerError)
                                        .send(json: APIError.databaseError.json())
                                        .end()
                        }
                    } catch {
                        APILogger.shared.log(message: "Communications error",
                                             logLevel: .error)
                    }
                })
                break
            }
        } catch {
            APILogger.shared.log(message: "Communications error",
                                 logLevel: .error)
        }
    }
    
    /**
        Handler for the historical schedule route.
     
        - Parameters:
            - request: A `RouterRequest` representing the request
                       object sent from the client.
            - response: A `RouterResponse` representing the response
                        object to send back to the client.
            - next: A closure that gets invoked to handle the next
                    request.
     */
    func handleHistoricalScheduleRoute(request: RouterRequest,
                                       response: RouterResponse,
                                       next: () -> Void) {
        do {
            guard let type = request.parameters["leagueType"] else {
                try response.status(.badRequest)
                    .send(json: APIError.leagueType.json())
                    .end()
                APILogger.shared.log(message: APIError.leagueType.errorDesciption,
                                     logLevel: .error)
                return
            }
            guard let year = request.parameters["year"] else {
                try response.status(.badRequest)
                    .send(json: APIError.year.json())
                    .end()
                APILogger.shared.log(message: APIError.year.errorDesciption,
                                     logLevel: .error)
                return
            }
            guard let week = request.parameters["week"]  else {
                try response.status(.badRequest)
                    .send(json: APIError.week.json())
                    .end()
                APILogger.shared.log(message: APIError.week.errorDesciption,
                                     logLevel: .error)
                return
            }
            guard let league = Int(type),
                  let season = Int(year),
                  let weekInSeason = Int(week) else {
                    try response.status(.badRequest).end()
                    APILogger.shared.log(message: "Error casting path parameters to integers",
                                         logLevel: .error)
                    return
            }
            guard let leagueType = LeagueType(rawValue: league) else {
                try response.status(.badRequest)
                    .send(json: APIError.invalidLeague.json())
                    .end()
                APILogger.shared.log(message: APIError.invalidLeague.errorDesciption,
                                     logLevel: .error)
                return
            }
            switch leagueType {
            case .nfl:
                if season < 1970 {
                    do {
                        try response.status(.badRequest)
                            .send(json: APIError.minmumYearNotMetHistorical.json())
                            .end()
                    } catch {
                        APILogger.shared.log(message: "Communications error",
                                             logLevel: .error)
                    }
                }
                database.fetchNflDocuments(type: NflHistorical.self,
                                           season: season,
                                           week: weekInSeason,
                                           success: { (results: [NflHistorical]) in
                    if results.count == 0 {
                        let nflScraper = NflScraper(season: season, week: weekInSeason)
                        nflScraper.scrapeHistoricalSchedule(success: { (results) in
                            do {
                                try response.status(.OK)
                                    .send(json: JSON(results))
                                    .end()
                            } catch {
                                APILogger.shared.log(message: "Communications error",
                                                     logLevel: .error)
                            }
                            let completedSchedules = results.filter {
                                return $0["gameStatus"].stringValue == "FINAL" ||
                                       $0["gameStatus"].stringValue == "FINAL OT"
                            }
                            if completedSchedules.count == results.count {
                                let dispatchQueue = DispatchQueue.global(qos: .utility)
                                let dispatchGroup = DispatchGroup()
                                var databaseError: Error?
                                for schedule in completedSchedules {
                                    dispatchGroup.enter()
                                    dispatchQueue.async {
                                        self.database.insertDocument(schedule, success: {
                                            dispatchGroup.leave()
                                        }, failure: { (error) in
                                            databaseError = error
                                            dispatchGroup.leave()
                                        })
                                    }
                                }
                                dispatchGroup.notify(queue: DispatchQueue.main) {
                                    guard databaseError == nil else {
                                        APILogger.shared.log(message: "Error inserting schedules into database",
                                                             logLevel: .error)
                                        APILogger.shared.log(message: "\((databaseError?.localizedDescription)!)",
                                                             logLevel: .error)
                                        return
                                    }
                                    APILogger.shared.log(message: "Inserted historical NFL schedules for season \(season) and week \(weekInSeason)",
                                                         logLevel: .error)
                                }
                            }
                        }, failure: { (error) in
                            do {
                                if let scrapperError = error {
                                    try response.status(.internalServerError)
                                        .send(json: APIError(errorDescription: scrapperError.localizedDescription).json())
                                        .end()
                                } else {
                                    try response.status(.internalServerError)
                                        .send(json: APIError.scrapperError.json())
                                        .end()
                                }
                                APILogger.shared.log(message: APIError.scrapperError.errorDesciption,
                                                     logLevel: .error)
                            } catch {
                                APILogger.shared.log(message: "Communications error",
                                                     logLevel: .error)
                            }
                        })
                    } else {
                        let schedules: [JSON] = results.flatMap { $0.json() }
                        do {
                            try response.status(.OK)
                                .send(json: JSON(schedules))
                                .end()
                        } catch {
                            APILogger.shared.log(message: "Communications error",
                                                 logLevel: .error)
                        }
                    }
                }, failure: { (error) in
                    do {
                        if let databaseError = error {
                            try response.status(.internalServerError)
                                .send(json: APIError(errorDescription: databaseError.localizedDescription).json())
                                .end()
                        } else {
                            try response.status(.internalServerError)
                                .send(json: APIError.databaseError.json())
                                .end()
                        }
                    } catch {
                        APILogger.shared.log(message: "Communications error",
                                             logLevel: .error)
                    }
                })
                break
            }
        } catch {
            APILogger.shared.log(message: "Communications error", logLevel: .error)
        }
    }
    
    /**
        Handler for the current route.
     
        - Parameters:
            - request: A `RouterRequest` representing the request
                       object sent from the client.
            - response: A `RouterResponse` representing the response
                        object to send back to the client.
            - next: A closure that gets invoked to handle the next
                    request.
    */
    func handleCurrentSeasonWeekRoute(request: RouterRequest,
                                      response: RouterResponse,
                                      next: () -> Void) {
        do {
            guard let type = request.parameters["leagueType"] else {
                try response.status(.badRequest)
                    .send(json: APIError.leagueType.json())
                    .end()
                APILogger.shared.log(message: APIError.leagueType.errorDesciption,
                                     logLevel: .error)
                return
            }
            guard let league = Int(type) else {
                try response.status(.badRequest).end()
                APILogger.shared.log(message: "Error casting path parameters to integers",
                                     logLevel: .error)
                return
            }
            guard let leagueType = LeagueType(rawValue: league) else {
                try response.status(.badRequest)
                    .send(json: APIError.invalidLeague.json())
                    .end()
                APILogger.shared.log(message: APIError.invalidLeague.errorDesciption,
                                     logLevel: .error)
                return
            }
            switch leagueType {
            case .nfl:
                let nflScraper = NflScraper(season: 0, week: 0)
                nflScraper.scrapeCurrentPosition(success: { (results) in
                    do {
                        try response.status(.OK).send(json: results).end()
                    } catch {
                        APILogger.shared.log(message: "Communications error",
                                             logLevel: .error)
                    }
                }, failure: { (error) in
                    do {
                        if let scrapperError = error {
                            try response.status(.internalServerError)
                                .send(json: APIError(errorDescription: scrapperError.localizedDescription).json())
                                .end()
                        } else {
                            try response.status(.internalServerError)
                                .send(json: APIError.scrapperError.json())
                                .end()
                        }
                        APILogger.shared.log(message: APIError.scrapperError.errorDesciption,
                                             logLevel: .error)
                    } catch {
                        APILogger.shared.log(message: "Communications error",
                                             logLevel: .error)
                    }
                })
                break
            }
        } catch {
            APILogger.shared.log(message: "Communications error",
                                 logLevel: .error)
        }
    }
    
    /**
        Handler for the mock data route.
     
        - Parameters:
            - request: A `RouterRequest` representing the request
                       object sent from the client.
            - response: A `RouterResponse` representing the response
                        object to send back to the client.
            - next: A closure that gets invoked to handle the next
                    request.
    */
    func handleMockDataRoute(request: RouterRequest,
                             response: RouterResponse,
                             next: () -> Void) {
        do {
            guard let type = request.parameters["leagueType"] else {
                try response.status(.badRequest)
                    .send(json: APIError.leagueType.json())
                    .end()
                APILogger.shared.log(message: APIError.leagueType.errorDesciption,
                                     logLevel: .error)
                return
            }
            guard let period = request.parameters["timePeriod"] else {
                try response.status(.badRequest)
                    .send(json: APIError.timePeriod.json())
                    .end()
                APILogger.shared.log(message: APIError.timePeriod.errorDesciption,
                                     logLevel: .error)
                return
            }
            guard let league = Int(type),
                  let time = Int(period) else {
                    try response.status(.badRequest).end()
                    return
            }
            guard let timePeriod = TimePeriod(rawValue: time) else {
                try response.status(.badRequest)
                    .send(json: APIError.invalidTimePeriod.json())
                    .end()
                APILogger.shared.log(message: APIError.invalidTimePeriod.errorDesciption,
                                     logLevel: .error)
                return
            }
            guard let leagueType = LeagueType(rawValue: league) else {
                try response.status(.badRequest)
                    .send(json: APIError.invalidLeague.json())
                    .end()
                APILogger.shared.log(message: APIError.invalidLeague.errorDesciption,
                                     logLevel: .error)
                return
            }
            switch leagueType {
            case .nfl:
                let nflScraper = NflScraper(season: 2016, week: 1)
                nflScraper.scrapeMock(timePeriod: timePeriod, success: { (results) in
                    do {
                        try response.status(.OK)
                            .send(json: JSON(results))
                            .end()
                    } catch {
                        APILogger.shared.log(message: "Communications error",
                                             logLevel: .error)
                    }
                }, failure: { (error) in
                    do {
                        if let scrapperError = error {
                            try response.status(.internalServerError)
                                .send(json: APIError(errorDescription: scrapperError.localizedDescription).json())
                                .end()
                        } else {
                            try response.status(.internalServerError)
                                .send(json: APIError.scrapperError.json())
                                .end()
                        }
                        APILogger.shared.log(message: APIError.scrapperError.errorDesciption,
                                             logLevel: .error)
                    } catch {
                        APILogger.shared.log(message: "Communications error",
                                             logLevel: .error)
                    }
                })
                break
            }
        } catch {
            APILogger.shared.log(message: "Communications error",
                                 logLevel: .error)
        }
    }
    
}


// MARK: - Private Enums

/**
    An enum that defines the different
    league types.
*/
fileprivate enum LeagueType: Int {
    case nfl
}
