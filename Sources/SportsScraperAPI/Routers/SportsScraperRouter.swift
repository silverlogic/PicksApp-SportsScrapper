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

/**
    A class responsible for handling
    routing in the server.
*/
public final class SportsScraperRouter {
    
    // MARK: - Private Instance Atrributes
    fileprivate let sportsScraper: SportsScraper
    
    
    // MARK: - Public Instance Attributes
    public let router = Router()
    
    
    // MARK: - Initializers
    
    /**
        Initializes an instance of `SportsScrapperController`.
     
        - Parameter backend: A `SportsScrapper` representing
                             the scrapper used for scrapping.
    */
    public init(backend: SportsScraper) {
        sportsScraper = backend
        routeSetup()
    }
}


// MARK: - Private Instance Methods
fileprivate extension SportsScraperRouter {
    
    /// Sets up all avaliable routes.
    func routeSetup() {
        router.all("/*", middleware: BodyParser())
        router.get("/live-schedule/:leagueType/:year/:week", handler: liveSchedule)
        router.get("/historical-schedule/:leagueType/:year/:week", handler: historicalSchedule)
        router.get("/current/:leagueType", handler: currentSeasonWeek)
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
    func liveSchedule(request: RouterRequest, response: RouterResponse, next: () -> Void) {
        do {
            guard let type = request.parameters["leagueType"] else {
                try response.status(.badRequest).send(json: APIError.leagueType.json()).end()
                APILogger.shared.log(message: APIError.leagueType.errorDesciption, logLevel: .error)
                return
            }
            guard let year = request.parameters["year"] else {
                try response.status(.badRequest).send(json: APIError.year.json()).end()
                APILogger.shared.log(message: APIError.year.errorDesciption, logLevel: .error)
                return
            }
            guard let week = request.parameters["week"]  else {
                try response.status(.badRequest).send(json: APIError.week.json()).end()
                APILogger.shared.log(message: APIError.week.errorDesciption, logLevel: .error)
                return
            }
            guard let league = Int(type),
                  let season = Int(year),
                  let weekInSeason = Int(week) else {
                    try response.status(.badRequest).end()
                    APILogger.shared.log(message: "Error casting path parameters to integers", logLevel: .error)
                    return
            }
            guard let leagueType = LeagueType(rawValue: league) else {
                try response.status(.badRequest).send(json: APIError.invalidLeague.json()).end()
                APILogger.shared.log(message: APIError.invalidLeague.errorDesciption, logLevel: .error)
                return
            }
            switch leagueType {
            case .nfl:
                if season < 2001 {
                    do {
                        try response.status(.badRequest).send(json: APIError.minmumYearNotMetLive.json()).end()
                    } catch {
                        APILogger.shared.log(message: "Communications error", logLevel: .error)
                    }
                }
                sportsScraper.liveScheduleNFL(season: season, week: weekInSeason, success: { (results) in
                    do {
                        try response.status(.OK).send(json: results).end()
                    } catch {
                        APILogger.shared.log(message: "Communications error", logLevel: .error)
                    }
                }, failure: { (error) in
                    do {
                        if let scrapperError = error {
                            try response.status(.internalServerError).send(json: APIError(errorDescription: scrapperError.localizedDescription).json()).end()
                        } else {
                            try response.status(.internalServerError).send(json: APIError.scrapperError.json()).end()
                        }
                        APILogger.shared.log(message: APIError.scrapperError.errorDesciption, logLevel: .error)
                    } catch {
                        APILogger.shared.log(message: "Communications error", logLevel: .error)
                    }
                })
                break
            }
        } catch {
            APILogger.shared.log(message: "Communications error", logLevel: .error)
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
    func historicalSchedule(request: RouterRequest, response: RouterResponse, next: () -> Void) {
        do {
            guard let type = request.parameters["leagueType"] else {
                try response.status(.badRequest).send(json: APIError.leagueType.json()).end()
                APILogger.shared.log(message: APIError.leagueType.errorDesciption, logLevel: .error)
                return
            }
            guard let year = request.parameters["year"] else {
                try response.status(.badRequest).send(json: APIError.year.json()).end()
                APILogger.shared.log(message: APIError.year.errorDesciption, logLevel: .error)
                return
            }
            guard let week = request.parameters["week"]  else {
                try response.status(.badRequest).send(json: APIError.week.json()).end()
                APILogger.shared.log(message: APIError.week.errorDesciption, logLevel: .error)
                return
            }
            guard let league = Int(type),
                  let season = Int(year),
                  let weekInSeason = Int(week) else {
                    try response.status(.badRequest).end()
                    APILogger.shared.log(message: "Error casting path parameters to integers", logLevel: .error)
                    return
            }
            guard let leagueType = LeagueType(rawValue: league) else {
                try response.status(.badRequest).send(json: APIError.invalidLeague.json()).end()
                APILogger.shared.log(message: APIError.invalidLeague.errorDesciption, logLevel: .error)
                return
            }
            switch leagueType {
            case .nfl:
                if season < 1970 {
                    do {
                        try response.status(.badRequest).send(json: APIError.minmumYearNotMetHistorical.json()).end()
                    } catch {
                        APILogger.shared.log(message: "Communications error", logLevel: .error)
                    }
                }
                sportsScraper.historicalScheduleNFL(season: season, week: weekInSeason, success: { (results) in
                    do {
                        try response.status(.OK).send(json: results).end()
                    } catch {
                        APILogger.shared.log(message: "Communications error", logLevel: .error)
                    }
                }, failure: { (error) in
                    do {
                        if let scrapperError = error {
                            try response.status(.internalServerError).send(json: APIError(errorDescription: scrapperError.localizedDescription).json()).end()
                        } else {
                            try response.status(.internalServerError).send(json: APIError.scrapperError.json()).end()
                        }
                        APILogger.shared.log(message: APIError.scrapperError.errorDesciption, logLevel: .error)
                    } catch {
                        APILogger.shared.log(message: "Communications error", logLevel: .error)
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
    func currentSeasonWeek(request: RouterRequest, response: RouterResponse, next: () -> Void) {
        do {
            guard let type = request.parameters["leagueType"] else {
                try response.status(.badRequest).send(json: APIError.leagueType.json()).end()
                APILogger.shared.log(message: APIError.leagueType.errorDesciption, logLevel: .error)
                return
            }
            guard let league = Int(type) else {
                try response.status(.badRequest).end()
                APILogger.shared.log(message: "Error casting path parameters to integers", logLevel: .error)
                return
            }
            guard let leagueType = LeagueType(rawValue: league) else {
                try response.status(.badRequest).send(json: APIError.invalidLeague.json()).end()
                APILogger.shared.log(message: APIError.invalidLeague.errorDesciption, logLevel: .error)
                return
            }
            switch leagueType {
            case .nfl:
                sportsScraper.currentSeasonWeek(success: { (results) in
                    do {
                        try response.status(.OK).send(json: results).end()
                    } catch {
                        APILogger.shared.log(message: "Communications error", logLevel: .error)
                    }
                }, failure: { (error) in
                    do {
                        if let scrapperError = error {
                            try response.status(.internalServerError).send(json: APIError(errorDescription: scrapperError.localizedDescription).json()).end()
                        } else {
                            try response.status(.internalServerError).send(json: APIError.scrapperError.json()).end()
                        }
                        APILogger.shared.log(message: APIError.scrapperError.errorDesciption, logLevel: .error)
                    } catch {
                        APILogger.shared.log(message: "Communications error", logLevel: .error)
                    }
                })
                break
            }
        } catch {
            APILogger.shared.log(message: "Communications error", logLevel: .error)
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
