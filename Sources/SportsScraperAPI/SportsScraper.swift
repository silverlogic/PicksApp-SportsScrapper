//
//  SportsScrapper.swift
//  PicksApp-SportsScrapper
//
//  Created by Emanuel  Guerrero on 5/19/17.
//
//

import Foundation
import LoggerAPI
import KituraRequest
import Ji
import SwiftyJSON

/**
    A class responsible for perfoming scrapping
    operations to different sport leagues. It
    conforms to `SportsScrapperAPI`.
*/
public final class SportsScraper: SportsScraperAPI {
    
    /// Initializes an instance of `SportsScrapper`.
    public init() {}
    
    
    // MARK: - SportsScrapperAPI Methods
    func scheduleNFL(season: Int, week: Int, success: @escaping (JSON) -> Void, failure: @escaping (Error?) -> Void) {
        KituraRequest.request(.get, Endpoint.nfl + "\(season)/REG\(week)").response { [weak self] (request, response, data, error) in
            guard let strongSelf = self else {
                Log.error("Error with object lifetime when geting NFL schedule")
                failure(nil)
                return
            }
            guard error == nil else {
                Log.error("Error perfoming request for NFL schedule")
                failure(error)
                return
            }
            guard let responseData = data else {
                Log.error("Error parsing response data from request")
                failure(nil)
                return
            }
            guard let html = String(data: responseData, encoding: .utf8) else {
                Log.error("Error generating HTML")
                failure(nil)
                return
            }
            do {
                let results = try strongSelf.parseHTML(html, strategy: .nfl)
                success(results)
            } catch {
                failure(nil)
            }
        }
    }
}


// MARK: - Private Instance Methods
fileprivate extension SportsScraper {
    
    /**
        Takes HTML given from a request and parses it for a list of teams
     
        - Throws: A `ScraperError` if the HTML provided can't be parsed.
     
        - Parameters: 
            - html: A `String` representing the html received from
                    a request.
            - strategy: A `ParseStrategy` representing the parsing strategy
                        to use.
     
        - Returns: A `JSON` object representing the response to send back
                   to the client.
    */
    func parseHTML(_ html: String, strategy: ParseStrategy) throws -> JSON {
        switch strategy {
        case .nfl:
            guard let jiHTML = Ji(htmlString: html) else {
                throw ScraperError.conversion
            }
            guard let scoreboxNodes = jiHTML.xPath("//div[@class='new-score-box-wrapper']") else {
                throw ScraperError.parse
            }
            var scheduleDictionary = [JSON]()
            for scoreboxNode in scoreboxNodes {
                var date: String?
                var homeTeamName: String?
                var homeTeamScore: Int?
                var awayTeamName: String?
                var awayTeamScore: Int?
                var gameStatus: String?
                let scoreboxChildrenNodes = scoreboxNode.children
                for scoreboxChildNode in scoreboxChildrenNodes {
                    if scoreboxChildNode.attributes == ["class": "new-score-box-heading"] {
                        // Retrieve date of the game
                        guard let scoreBoxHeadingChildren = scoreboxChildNode.children.first?.children,
                              let dateNode = scoreBoxHeadingChildren.filter({ $0.attributes == ["class": "date", "title": "Date Aired"] || $0.attributes == ["class": "date", "title": "Date Airing"]}).first,
                              let content = dateNode.content else {
                                Log.error("Error scraping date")
                                throw ScraperError.parse
                        }
                        date = content
                    } else {
                        // Retrieve scores, teams, calculate who won/lost
                        // and game status
                        let newScoreBoxChildren = scoreboxChildNode.children
                        for newScoreBoxChild in newScoreBoxChildren {
                            if newScoreBoxChild.attributes == ["class": "team-wrapper"] {
                                // Retrieve home and away teams
                                guard let teamWrapperChild = newScoreBoxChild.children.first else {
                                    Log.error("Error scraping score box")
                                    throw ScraperError.parse
                                }
                                if teamWrapperChild.attributes == ["class": "away-team"] {
                                    // Retrieve away team info
                                    let awayTeamChildren = teamWrapperChild.children
                                    guard let teamDataNode = awayTeamChildren.filter({ $0.attributes == ["class": "team-data"] }).first else {
                                        Log.error("Error scraping team data for away team")
                                        throw ScraperError.parse
                                    }
                                    let teamDataChildren = teamDataNode.children
                                    for teamDataChild in teamDataChildren {
                                        if teamDataChild.attributes == ["class": "team-info"] {
                                            // Retrieve away team name
                                            guard let teamNameNode = teamDataChild.children.filter({ $0.attributes == ["class": "team-name"] }).first,
                                                  let content = teamNameNode.content else {
                                                    Log.error("Error scraping away team name")
                                                    throw ScraperError.parse
                                            }
                                            awayTeamName = content
                                        } else if teamDataChild.attributes == ["class": "total-score"] {
                                            // Retrieve away team score
                                            guard let content = teamDataChild.content else {
                                                Log.error("Error scraping away team score")
                                                    throw ScraperError.parse
                                            }
                                            // Check if the string is '--'
                                            if let awayScore = Int(content) {
                                                awayTeamScore = awayScore
                                            } else {
                                                awayTeamScore = 0
                                            }
                                        }
                                    }
                                } else {
                                    // Retrieve home team info
                                    let homeTeamChildren = teamWrapperChild.children
                                    guard let teamDataNode = homeTeamChildren.filter({ $0.attributes == ["class": "team-data"] }).first else {
                                        Log.error("Error scraping team data for home team")
                                        throw ScraperError.parse
                                    }
                                    let teamDataChildren = teamDataNode.children
                                    for teamDataChild in teamDataChildren {
                                        if teamDataChild.attributes == ["class": "team-info"] {
                                            // Retrieve home team name
                                            guard let teamNameNode = teamDataChild.children.filter({ $0.attributes == ["class": "team-name"] }).first,
                                                  let content = teamNameNode.content else {
                                                    Log.error("Error scraping home team name")
                                                    throw ScraperError.parse
                                            }
                                            homeTeamName = content
                                        } else if teamDataChild.attributes == ["class": "total-score"] {
                                            // Retrieve home team score
                                            guard let content = teamDataChild.content else {
                                                Log.error("Error scraping home team score")
                                                    throw ScraperError.parse
                                            }
                                            // Check if the string is '--'
                                            if let homeScore = Int(content) {
                                                homeTeamScore = homeScore
                                            } else {
                                                homeTeamScore = 0
                                            }
                                        }
                                    }
                                }
                            } else if newScoreBoxChild.attributes == ["class": "game-center-area"] {
                                // Retrieve game status
                                let gameCenterAreaChildren = newScoreBoxChild.children
                                guard let timeLeftPElement = gameCenterAreaChildren.filter({ $0.name == "p" }).first,
                                      let timeLeftNode = timeLeftPElement.children.first,
                                      let content = timeLeftNode.content else {
                                        Log.error("Error scraping game status")
                                        throw ScraperError.parse
                                }
                                gameStatus = content
                            }
                        }
                    }
                }
                // Validate that neccessary content is there
                guard let dateStarted = date,
                      let teamHomeName = homeTeamName,
                      let teamHomeScore = homeTeamScore,
                      let teamAwayName = awayTeamName,
                      let teamAwayScore = awayTeamScore,
                      let status = gameStatus else {
                        Log.error("Values are missing for schedule")
                        throw ScraperError.conversion
                }
                scheduleDictionary.append(JSON(["date": dateStarted, "homeTeamName": teamHomeName, "homeTeamScore": teamHomeScore, "awayTeamName": teamAwayName, "awayTeamScore": teamAwayScore, "gameStatus": status]))
            }
            return JSON(scheduleDictionary)
        }
    }
    
}


// MARK: - Public Enums

/**
    An enum that defines errors
    that can occur.
*/
enum ScraperError: Error {
    case parse
    case conversion
    case objectLifetime
}



// MARK: - Private Enums

/**
    An enum that defines the endpoints for
    different sport leagues.
*/
fileprivate enum Endpoint {
    static let nfl = "http://www.nfl.com/scores/"
}


/**
    An enum that defines parsing strategy.
*/
fileprivate enum ParseStrategy {
    case nfl
}
