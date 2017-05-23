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
    func liveScheduleNFL(season: Int, week: Int, success: @escaping (JSON) -> Void, failure: @escaping (Error?) -> Void) {
        KituraRequest.request(.get, Endpoint.nflLive + "\(season)/REG\(week)").response { [weak self] (request, response, data, error) in
            guard let strongSelf = self else {
                Log.error("Error with object lifetime when geting NFL live schedule")
                failure(nil)
                return
            }
            guard error == nil else {
                Log.error("Error perfoming request for NFL live schedule")
                failure(error)
                return
            }
            guard let responseData = data else {
                Log.error("Error parsing response data from request for NFL live schedule")
                failure(nil)
                return
            }
            guard let html = String(data: responseData, encoding: .utf8) else {
                Log.error("Error generating HTML for NFL live schedule")
                failure(nil)
                return
            }
            do {
                let results = try strongSelf.parseHTML(html, strategy: .nflLive)
                success(results)
            } catch {
                failure(nil)
            }
        }
    }
    
    func historicalScheduleNFL(season: Int, week: Int, success: @escaping (JSON) -> Void, failure: @escaping (Error?) -> Void) {
        KituraRequest.request(.get, Endpoint.nflHistorical + "\(season)/REG\(week)").response { [weak self] (request, response, data, error) in
            guard let strongSelf = self else {
                Log.error("Error with object lifetime when geting NFL historical schedule")
                failure(nil)
                return
            }
            guard error == nil else {
                Log.error("Error perfoming request for NFL historical schedule")
                failure(error)
                return
            }
            guard let responseData = data else {
                Log.error("Error parsing response data from request for NFL historical schedule")
                failure(nil)
                return
            }
            guard let html = String(data: responseData, encoding: .utf8) else {
                Log.error("Error generating HTML for NFL historical schedule")
                failure(nil)
                return
            }
            do {
                let results = try strongSelf.parseHTML(html, strategy: .nflHistorical)
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
        case .nflLive:
            guard let jiHTML = Ji(htmlString: html) else {
                Log.error("Can't parse document for NFL live")
                throw ScraperError.conversion
            }
            guard let scoreboxNodes = jiHTML.xPath("//div[@class='new-score-box-wrapper']") else {
                Log.error("Can't get elements for NFL live")
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
                                Log.error("Error scraping date for NFL live")
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
                                    Log.error("Error scraping score box for NFL live")
                                    throw ScraperError.parse
                                }
                                if teamWrapperChild.attributes == ["class": "away-team"] {
                                    // Retrieve away team info
                                    let awayTeamChildren = teamWrapperChild.children
                                    guard let teamDataNode = awayTeamChildren.filter({ $0.attributes == ["class": "team-data"] }).first else {
                                        Log.error("Error scraping team data for away team in NFL live")
                                        throw ScraperError.parse
                                    }
                                    let teamDataChildren = teamDataNode.children
                                    for teamDataChild in teamDataChildren {
                                        if teamDataChild.attributes == ["class": "team-info"] {
                                            // Retrieve away team name
                                            guard let teamNameNode = teamDataChild.children.filter({ $0.attributes == ["class": "team-name"] }).first,
                                                  let content = teamNameNode.content else {
                                                    Log.error("Error scraping away team name in NFL live")
                                                    throw ScraperError.parse
                                            }
                                            awayTeamName = content
                                        } else if teamDataChild.attributes == ["class": "total-score"] {
                                            // Retrieve away team score
                                            guard let content = teamDataChild.content else {
                                                Log.error("Error scraping away team score in NFL live")
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
                                        Log.error("Error scraping team data for home team in NFL live")
                                        throw ScraperError.parse
                                    }
                                    let teamDataChildren = teamDataNode.children
                                    for teamDataChild in teamDataChildren {
                                        if teamDataChild.attributes == ["class": "team-info"] {
                                            // Retrieve home team name
                                            guard let teamNameNode = teamDataChild.children.filter({ $0.attributes == ["class": "team-name"] }).first,
                                                  let content = teamNameNode.content else {
                                                    Log.error("Error scraping home team name in NFL live")
                                                    throw ScraperError.parse
                                            }
                                            homeTeamName = content
                                        } else if teamDataChild.attributes == ["class": "total-score"] {
                                            // Retrieve home team score
                                            guard let content = teamDataChild.content else {
                                                Log.error("Error scraping home team score in NFL live")
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
                                        Log.error("Error scraping game status in NFL live")
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
        case .nflHistorical:
            guard let jiHTML = Ji(htmlString: html) else {
                Log.error("Can't parse document for NFL historical")
                throw ScraperError.conversion
            }
            guard let schedulesTableNode = jiHTML.xPath("//ul[@class='schedules-table']")?.first else {
                Log.error("Can't get elements for NFL historical")
                throw ScraperError.parse
            }
            // Represents the last date that was parsed from the HTML document
            // This value will change since the content is laid out in an alernating
            // pattern.
            var lastDateParsed = ""
            var scheduleDictionary = [JSON]()
            let schedulesTableChildren = schedulesTableNode.children
            for scheduleTableChild in schedulesTableChildren {
                if scheduleTableChild.attributes == ["class": "schedules-list-date"] {
                    // Get date and set it to lastDateParsed
                    guard let dateSpan = scheduleTableChild.children.first?.children.first,
                          let content = dateSpan.content else {
                            Log.error("Error scraping date for NFL historical")
                            throw ScraperError.parse
                    }
                    lastDateParsed = content
                } else if scheduleTableChild.attributes == ["class": "schedules-list-matchup post expandable  type-reg"] ||
                          scheduleTableChild.attributes == ["class": "schedules-list-matchup post expandable primetime type-reg"] ||
                          scheduleTableChild.attributes == ["class": "schedules-list-matchup post  primetime type-reg"] ||
                          scheduleTableChild.attributes == ["class": "schedules-list-matchup post   type-reg"] {
                    // Create game object for a post game
                    var homeTeamName: String?
                    var homeTeamScore: Int?
                    var awayTeamName: String?
                    var awayTeamScore: Int?
                    var gameStatus: String?
                    guard let scheduleListPostNode = scheduleTableChild.children.filter({ $0.attributes == ["class": "schedules-list-hd post"] }).first,
                          let listMatchupRowCenterNode = scheduleListPostNode.children.filter({ $0.attributes == ["class": "list-matchup-row-center"] }).first,
                          let listMatchupRowAnimNode = listMatchupRowCenterNode.children.filter({ $0.attributes == ["class": "list-matchup-row-anim"] }).first,
                          let teamDataNode = listMatchupRowAnimNode.children.filter({ $0.attributes == ["class": "list-matchup-row-team"] }).first else {
                            Log.error("Error scraping team data for NFL historical")
                            throw ScraperError.parse
                    }
                    guard let awayNameNode = teamDataNode.children.filter({ $0.attributes == ["class": "team-name away lost"] || $0.attributes == ["class": "team-name away "] }).first,
                          let awayScoreNode = teamDataNode.children.filter({ $0.attributes == ["class": "team-score away lost"] || $0.attributes == ["class": "team-score away "] }).first,
                          let homeNameNode = teamDataNode.children.filter({ $0.attributes == ["class": "team-name home lost"] || $0.attributes == ["class": "team-name home "] }).first,
                          let homeScoreNode = teamDataNode.children.filter({ $0.attributes == ["class": "team-score home lost"] || $0.attributes == ["class": "team-score home "] }).first,
                          let awayName = awayNameNode.content,
                          let awayScore = awayScoreNode.content,
                          let homeName = homeNameNode.content,
                          let homeScore = homeScoreNode.content else {
                            Log.error("Error scraping names and scores for NFL historical")
                            throw ScraperError.parse
                    }
                    homeTeamName = homeName
                    awayTeamName = awayName
                    // Check if string is '00'
                    if let scoreAway = Int(awayScore) {
                        awayTeamScore = scoreAway
                    } else {
                        awayTeamScore = 0
                    }
                    if let scoreHome = Int(homeScore) {
                        homeTeamScore = scoreHome
                    } else {
                        homeTeamScore = 0
                    }
                    // Get game status
                    guard let listMatchupRowTimeNode = listMatchupRowCenterNode.children.filter({ $0.attributes == ["class": "list-matchup-row-time"] }).first,
                          let gameStatusNode = listMatchupRowTimeNode.children.first,
                          let content = gameStatusNode.content else {
                            Log.error("Error scraping game status for NFL historical")
                            throw ScraperError.parse
                    }
                    gameStatus = content
                    // Validate that neccessary content is there
                    guard let teamHomeName = homeTeamName,
                          let teamHomeScore = homeTeamScore,
                          let teamAwayName = awayTeamName,
                          let teamAwayScore = awayTeamScore,
                          let status = gameStatus else {
                            Log.error("Values are missing for schedule")
                            throw ScraperError.conversion
                    }
                    scheduleDictionary.append(JSON(["date": lastDateParsed, "homeTeamName": teamHomeName, "homeTeamScore": teamHomeScore, "awayTeamName": teamAwayName, "awayTeamScore": teamAwayScore, "gameStatus": status]))
                } else if scheduleTableChild.attributes == [:] {
                    continue
                } else {
                    // Create game object for upcoming game
                    var homeTeamName: String?
                    var homeTeamScore: Int?
                    var awayTeamName: String?
                    var awayTeamScore: Int?
                    var gameStatus: String?
                    guard let scheduleListHdPreNode = scheduleTableChild.children.filter({ $0.attributes == ["class": "schedules-list-hd pre"] }).first,
                          let listMatchupRowCenterNode = scheduleListHdPreNode.children.filter({ $0.attributes == ["class": "list-matchup-row-center"] }).first,
                          let listMatchupRowAnimNode = listMatchupRowCenterNode.children.filter({ $0.attributes == ["class": "list-matchup-row-anim"] }).first,
                          let teamDataNode = listMatchupRowAnimNode.children.filter({ $0.attributes == ["class": "list-matchup-row-team"] }).first else {
                            Log.error("Error scraping team data for NFL historical")
                            throw ScraperError.parse
                    }
                    guard let awayTeamNameNode = teamDataNode.children.filter({ $0.attributes == ["class": "team-name away "] }).first,
                          let homeTeamNameNode = teamDataNode.children.filter({ $0.attributes == ["class": "team-name home "] }).first,
                          let awayName = awayTeamNameNode.content,
                          let homeName = homeTeamNameNode.content else {
                            Log.error("Error scraping names for NFL historical")
                            throw ScraperError.parse
                    }
                    homeTeamName = homeName
                    awayTeamName = awayName
                    homeTeamScore = 0
                    awayTeamScore = 0
                    // Get game status would be not stated
                    gameStatus = "NOT STARTED"
                    // Validate that neccessary content is there
                    guard let teamHomeName = homeTeamName,
                          let teamHomeScore = homeTeamScore,
                          let teamAwayName = awayTeamName,
                          let teamAwayScore = awayTeamScore,
                          let status = gameStatus else {
                            Log.error("Values are missing for schedule")
                            throw ScraperError.conversion
                    }
                    scheduleDictionary.append(JSON(["date": lastDateParsed, "homeTeamName": teamHomeName, "homeTeamScore": teamHomeScore, "awayTeamName": teamAwayName, "awayTeamScore": teamAwayScore, "gameStatus": status]))
                }
            }
            return(JSON(scheduleDictionary))
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
    static let nflLive = "http://www.nfl.com/scores/"
    static let nflHistorical = "http://www.nfl.com/schedules/"
}


/**
    An enum that defines parsing strategy.
*/
fileprivate enum ParseStrategy {
    case nflLive
    case nflHistorical
}
