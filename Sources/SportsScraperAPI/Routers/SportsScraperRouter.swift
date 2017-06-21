//
//  SportsScrapperController.swift
//  PicksApp-SportsScrapper
//
//  Created by Emanuel  Guerrero on 5/19/17.
//
//

import Foundation
import Kitura
import LoggerAPI

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
                Log.error("Path parameter 'leagueType' missing")
                return
            }
            guard let year = request.parameters["year"] else {
                try response.status(.badRequest).send(json: APIError.year.json()).end()
                Log.error("Path parameter 'year' missing")
                return
            }
            guard let week = request.parameters["week"]  else {
                try response.status(.badRequest).send(json: APIError.week.json()).end()
                Log.error("Path parameter 'week' missing")
                return
            }
            guard let league = Int(type),
                  let season = Int(year),
                  let weekInSeason = Int(week) else {
                    try response.status(.badRequest).end()
                    Log.error("Error casting path parameters to integers")
                    return
            }
            guard let leagueType = LeagueType(rawValue: league) else {
                try response.status(.badRequest).send(json: APIError.invalidLeague.json()).end()
                return
            }
            switch leagueType {
            case .nfl:
                if season < 2001 {
                    do {
                        try response.status(.badRequest).send(json: APIError.minmumYearNotMetLive.json()).end()
                    } catch {
                        Log.error("Communications error")
                    }
                }
                sportsScraper.liveScheduleNFL(season: season, week: weekInSeason, success: { (results) in
                    do {
                        try response.status(.OK).send(json: results).end()
                    } catch {
                        Log.error("Communications error")
                    }
                }, failure: { (error) in
                    do {
                        if let scrapperError = error {
                            try response.status(.internalServerError).send(json: APIError(errorDescription: scrapperError.localizedDescription).json()).end()
                        } else {
                            try response.status(.internalServerError).send(json: APIError.scrapperError.json()).end()
                        }
                        Log.error("Error has occured with scrapper")
                    } catch {
                        Log.error("Communications error")
                    }
                })
                break
            }
        } catch {
            Log.error("Communications error")
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
                Log.error("Path parameter 'leagueType' missing")
                return
            }
            guard let year = request.parameters["year"] else {
                try response.status(.badRequest).send(json: APIError.year.json()).end()
                Log.error("Path parameter 'year' missing")
                return
            }
            guard let week = request.parameters["week"]  else {
                try response.status(.badRequest).send(json: APIError.week.json()).end()
                Log.error("Path parameter 'week' missing")
                return
            }
            guard let league = Int(type),
                  let season = Int(year),
                  let weekInSeason = Int(week) else {
                    try response.status(.badRequest).end()
                    Log.error("Error casting path parameters to integers")
                    return
            }
            guard let leagueType = LeagueType(rawValue: league) else {
                try response.status(.badRequest).send(json: APIError.invalidLeague.json()).end()
                return
            }
            switch leagueType {
            case .nfl:
                if season < 1970 {
                    do {
                        try response.status(.badRequest).send(json: APIError.minmumYearNotMetHistorical.json()).end()
                    } catch {
                        Log.error("Communications error")
                    }
                }
                sportsScraper.historicalScheduleNFL(season: season, week: weekInSeason, success: { (results) in
                    do {
                        try response.status(.OK).send(json: results).end()
                    } catch {
                        Log.error("Communications error")
                    }
                }, failure: { (error) in
                    do {
                        if let scrapperError = error {
                            try response.status(.internalServerError).send(json: APIError(errorDescription: scrapperError.localizedDescription).json()).end()
                        } else {
                            try response.status(.internalServerError).send(json: APIError.scrapperError.json()).end()
                        }
                        Log.error("Error has occured with scrapper")
                    } catch {
                        Log.error("Communications error")
                    }
                })
                break
            }
        } catch {
            Log.error("Communications error")
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
                Log.error("Path parameter 'leagueType' missing")
                return
            }
            guard let league = Int(type) else {
                try response.status(.badRequest).end()
                Log.error("Error casting path parameters to integers")
                return
            }
            guard let leagueType = LeagueType(rawValue: league) else {
                try response.status(.badRequest).send(json: APIError.invalidLeague.json()).end()
                return
            }
            switch leagueType {
            case .nfl:
                sportsScraper.currentSeasonWeek(success: { (results) in
                    do {
                        try response.status(.OK).send(json: results).end()
                    } catch {
                        Log.error("Communications error")
                    }
                }, failure: { (error) in
                    do {
                        if let scrapperError = error {
                            try response.status(.internalServerError).send(json: APIError(errorDescription: scrapperError.localizedDescription).json()).end()
                        } else {
                            try response.status(.internalServerError).send(json: APIError.scrapperError.json()).end()
                        }
                        Log.error("Error has occured with scrapper")
                    } catch {
                        Log.error("Communications error")
                    }
                })
                break
            }
        } catch {
            Log.error("Communications error")
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
