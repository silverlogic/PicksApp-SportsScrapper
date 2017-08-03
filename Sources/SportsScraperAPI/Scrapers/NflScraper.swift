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
import KituraRequest
import Ji
import SwiftyJSON

/**
    A class that conforms to `Scrapable` and implements
    behavior for scraping the NFL website for schedules.
*/
final class NflScraper: Scrapable {
    
    // MARK: - Private Instance Methods
    
    /// A season in the NFL. Schedules will be retrieved based on the season.
    fileprivate let season: Int
    
    /// A week in `season`. Schedules will be retrieved based on the week.
    fileprivate let week: Int
    
    
    // MARK: - Initializers
    
    /**
        Initializes an instance of `NflScraper`.
     
        - Parameters:
            - season: A `Int` representing a season in the NFL.
            - week: A `Int` representing the week in `season`.
    */
    init(season: Int, week: Int) {
        self.season = season
        self.week = week
    }
    
    
    // MARK: - Scrapable
    func scrapeLiveSchedule(success: @escaping ([JSON]) -> Void,
                            failure: @escaping (Error?) -> Void) {
        KituraRequest.request(.get, Endpoint.nflLive + "\(season)/REG\(week)").response { (request, response, data, error) in
            guard error == nil else {
                APILogger.shared.log(message: "Error perfoming request for NFL live schedule",
                                     logLevel: .error)
                failure(error)
                return
            }
            guard let responseData = data else {
                APILogger.shared.log(message: "Error parsing response data from request for NFL live schedule",
                                     logLevel: .error)
                failure(nil)
                return
            }
            guard let html = String(data: responseData, encoding: .utf8) else {
                APILogger.shared.log(message: "Error generating HTML for NFL live schedule",
                                     logLevel: .error)
                failure(nil)
                return
            }
            self.scrapeLive(html: html, success: success, failure: failure)
        }
    }
    
    func scrapeHistoricalSchedule(success: @escaping ([JSON]) -> Void,
                                  failure: @escaping (Error?) -> Void) {
        KituraRequest.request(.get, Endpoint.nflHistorical + "\(season)/REG\(week)").response { (request, response, data, error) in
            guard error == nil else {
                APILogger.shared.log(message: "Error perfoming request for NFL historical schedule",
                                     logLevel: .error)
                failure(error)
                return
            }
            guard let responseData = data else {
                APILogger.shared.log(message: "Error parsing response data from request for NFL historical schedule",
                                     logLevel: .error)
                failure(nil)
                return
            }
            guard let html = String(data: responseData, encoding: .utf8) else {
                APILogger.shared.log(message: "Error generating HTML for NFL historical schedule",
                                     logLevel: .error)
                failure(nil)
                return
            }
            guard let jiHTML = Ji(htmlString: html) else {
                APILogger.shared.log(message: "Can't parse document for NFL historical", logLevel: .error)
                failure(nil)
                return
            }
            guard let schedulesTableNode = jiHTML.xPath("//ul[@class='schedules-table']")?.first else {
                APILogger.shared.log(message: "Can't get elements for NFL historical", logLevel: .error)
                failure(nil)
                return
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
                            APILogger.shared.log(message: "Error scraping date for NFL historical",
                                                 logLevel: .error)
                            failure(nil)
                            return
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
                            APILogger.shared.log(message: "Error scraping team data for NFL historical",
                                                 logLevel: .error)
                            failure(nil)
                            return
                    }
                    guard let awayNameNode = teamDataNode.children.filter({ $0.attributes == ["class": "team-name away lost"] || $0.attributes == ["class": "team-name away "] }).first,
                          let awayScoreNode = teamDataNode.children.filter({ $0.attributes == ["class": "team-score away lost"] || $0.attributes == ["class": "team-score away "] }).first,
                          let homeNameNode = teamDataNode.children.filter({ $0.attributes == ["class": "team-name home lost"] || $0.attributes == ["class": "team-name home "] }).first,
                          let homeScoreNode = teamDataNode.children.filter({ $0.attributes == ["class": "team-score home lost"] || $0.attributes == ["class": "team-score home "] }).first,
                          let awayName = awayNameNode.content,
                          let awayScore = awayScoreNode.content,
                          let homeName = homeNameNode.content,
                          let homeScore = homeScoreNode.content else {
                            APILogger.shared.log(message: "Error scraping names and scores for NFL historical",
                                                 logLevel: .error)
                            failure(nil)
                            return
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
                            APILogger.shared.log(message: "Error scraping game status for NFL historical",
                                                 logLevel: .error)
                            failure(nil)
                            return
                    }
                    gameStatus = content
                    // Validate that neccessary content is there
                    guard let teamHomeName = homeTeamName,
                          let teamHomeScore = homeTeamScore,
                          let teamAwayName = awayTeamName,
                          let teamAwayScore = awayTeamScore,
                          let status = gameStatus else {
                            APILogger.shared.log(message: "Values are missing for schedule",
                                                 logLevel: .error)
                            failure(nil)
                            return
                    }
                    scheduleDictionary.append(JSON(["type": ModelType.nflHistorical.rawValue,
                                                    "season": self.season,
                                                    "week": self.week,
                                                    "date": lastDateParsed,
                                                    "homeTeamName": teamHomeName,
                                                    "homeTeamScore": teamHomeScore,
                                                    "awayTeamName": teamAwayName,
                                                    "awayTeamScore": teamAwayScore,
                                                    "gameStatus": status]))
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
                            APILogger.shared.log(message: "Error scraping team data for NFL historical",
                                                 logLevel: .error)
                            failure(nil)
                            return
                    }
                    guard let awayTeamNameNode = teamDataNode.children.filter({ $0.attributes == ["class": "team-name away "] }).first,
                          let homeTeamNameNode = teamDataNode.children.filter({ $0.attributes == ["class": "team-name home "] }).first,
                          let awayName = awayTeamNameNode.content,
                          let homeName = homeTeamNameNode.content else {
                            APILogger.shared.log(message: "Error scraping names for NFL historical",
                                                 logLevel: .error)
                            failure(nil)
                            return
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
                            APILogger.shared.log(message: "Values are missing for schedule",
                                                 logLevel: .error)
                            failure(nil)
                            return
                    }
                    scheduleDictionary.append(JSON(["type": ModelType.nflHistorical.rawValue,
                                                    "season": self.season,
                                                    "week": self.week,
                                                    "date": lastDateParsed,
                                                    "homeTeamName": teamHomeName,
                                                    "homeTeamScore": teamHomeScore,
                                                    "awayTeamName": teamAwayName,
                                                    "awayTeamScore": teamAwayScore,
                                                    "gameStatus": status]))
                }
            }
            success(scheduleDictionary)
        }
    }
    
    func scrapeCurrentPosition(success: @escaping (JSON) -> Void,
                               failure: @escaping (Error?) -> Void) {
        KituraRequest.request(.get, Endpoint.nflCurrent).response { (request, response, data, error) in
            guard error == nil else {
                APILogger.shared.log(message: "Error perfoming request for current NFL season/week",
                                     logLevel: .error)
                failure(error)
                return
            }
            guard let responseData = data else {
                APILogger.shared.log(message: "Error parsing response data from request for NFL current",
                                     logLevel: .error)
                failure(nil)
                return
            }
            guard let html = String(data: responseData, encoding: .utf8) else {
                APILogger.shared.log(message: "Error generating HTML for NFL current",
                                     logLevel: .error)
                failure(nil)
                return
            }
            guard let jiHTML = Ji(htmlString: html) else {
                APILogger.shared.log(message: "Can't parse document for NFL current",
                                     logLevel: .error)
                failure(nil)
                return
            }
            var currentSeason: Int?
            var currentWeek: Int?
            // Get the current season
            guard let pageTitleNode = jiHTML.xPath("//h1[@class='pageTitle feature nfl']") else {
                APILogger.shared.log(message: "Error geting page title in NFL current",
                                     logLevel: .error)
                failure(nil)
                return
            }
            guard let seasonContent = pageTitleNode.first?.content else {
                APILogger.shared.log(message: "Error getting season content in NFL current",
                                     logLevel: .error)
                failure(nil)
                return
            }
            let lowerCasedSeason = seasonContent.lowercased()
            guard let seasonRange = lowerCasedSeason.range(of: " nfl schedule")?.lowerBound else {
                APILogger.shared.log(message: "Error getting season range in NFL current",
                                     logLevel: .error)
                failure(nil)
                return
            }
            let newSeasonContent = lowerCasedSeason.substring(to: seasonRange)
            guard let season = Int(newSeasonContent) else {
                APILogger.shared.log(message: "Error converting season content in NFL current",
                                     logLevel: .error)
                failure(nil)
                return
            }
            currentSeason = season
            // Get the current week
            guard let titleNode = jiHTML.xPath("//tr[@class='title']") else {
                APILogger.shared.log(message: "Error geting title in NFL current",
                                     logLevel: .error)
                failure(nil)
                return
            }
            guard let weekContent = titleNode.first?.children.first?.content else {
                APILogger.shared.log(message: "Error getting week content in NFL current",
                                     logLevel: .error)
                failure(nil)
                return
            }
            let lowerCasedWeek = weekContent.lowercased()
            guard let weekRange = lowerCasedWeek.range(of: "week ")?.upperBound else {
                APILogger.shared.log(message: "Error getting week range in NFL current",
                                     logLevel: .error)
                failure(nil)
                return
            }
            let newWeekContent = lowerCasedWeek.substring(from: weekRange)
            guard let week = Int(newWeekContent) else {
                APILogger.shared.log(message: "Error converting week content in NFL current",
                                     logLevel: .error)
                failure(nil)
                return
            }
            currentWeek = week
            // Validate that neccessary content is there
            guard let seasonCurrent = currentSeason,
                  let weekCurrent = currentWeek else {
                    APILogger.shared.log(message: "Values are missing for NFL current",
                                         logLevel: .error)
                    failure(nil)
                    return
            }
            success(JSON(["season": seasonCurrent, "week": weekCurrent]))
        }
    }
    
    func scrapeMock(timePeriod: TimePeriod, success: @escaping ([JSON]) -> Void, failure: @escaping (Error?) -> Void) {
        let mockLoader = MockLoader()
        let fileData: Data?
        switch timePeriod {
        case .beginning:
            fileData = mockLoader.readMockFile(.nflLiveBeginning)
            break
        case .middle:
            fileData = mockLoader.readMockFile(.nflLiveMiddle)
            break
        case .final:
            fileData = mockLoader.readMockFile(.nflLiveFinal)
            break
        }
        guard let mockData = fileData else {
            APILogger.shared.log(message: "Error loading mock data for NFL mock",
                                 logLevel: .error)
            failure(nil)
            return
        }
        guard let html = String(data: mockData, encoding: .utf8) else {
            APILogger.shared.log(message: "Error generating HTML for NFL mock",
                                 logLevel: .error)
            failure(nil)
            return
        }
        scrapeLive(html: html, success: success, failure: failure)
    }
}


// MARK: - Private Instance Methods
fileprivate extension NflScraper {
    
    /**
        Scrapes a live NFL schedule.
     
        - Parameters:
            - html: A `String` representing the HTML to scrape.
            - success: A closure that gets invoked when scraping was successful.
            - failure: A closure that gets invoked when scraping failed.
            - results: A `[JSON]` representing the results that were scraped.
                       Gets passed in `success`.
            - error: A `Error?` representing the error that occured. Gets passed
                     in `failure`.
    */
    func scrapeLive(html: String, success: @escaping (_ results: [JSON]) -> Void, failure: @escaping (_ error: Error?) -> Void) {
        guard let jiHTML = Ji(htmlString: html) else {
            APILogger.shared.log(message: "Can't parse document for NFL live", logLevel: .error)
            failure(nil)
            return
        }
        guard let scoreboxNodes = jiHTML.xPath("//div[@class='new-score-box-wrapper']") else {
            APILogger.shared.log(message: "Can't get elements for NFL live", logLevel: .error)
            failure(nil)
            return
        }
        var scheduleDictionary = [JSON]()
        for scoreboxNode in scoreboxNodes {
            var date: String?
            var homeTeamName: String?
            var homeTeamScore: Int?
            var homeTeamRecordWins: Int?
            var homeTeamRecordLosses: Int?
            var homeTeamRecordTies: Int?
            var homeTeamScoreQ1 = 0
            var homeTeamScoreQ2 = 0
            var homeTeamScoreQ3 = 0
            var homeTeamScoreQ4 = 0
            var homeTeamScoreOT = 0
            var awayTeamName: String?
            var awayTeamScore: Int?
            var awayTeamRecordWins: Int?
            var awayTeamRecordLosses: Int?
            var awayTeamRecordTies: Int?
            var awayTeamScoreQ1 = 0
            var awayTeamScoreQ2 = 0
            var awayTeamScoreQ3 = 0
            var awayTeamScoreQ4 = 0
            var awayTeamScoreOT = 0
            var gameStatus: String?
            let scoreboxChildrenNodes = scoreboxNode.children
            for scoreboxChildNode in scoreboxChildrenNodes {
                if scoreboxChildNode.attributes == ["class": "new-score-box-heading"] {
                    // Retrieve date of the game
                    guard let scoreBoxHeadingChildren = scoreboxChildNode.children.first?.children,
                          let dateNode = scoreBoxHeadingChildren.filter({ $0.attributes == ["class": "date", "title": "Date Aired"] ||
                            $0.attributes == ["class": "date", "title": "Date Airing"]}).first,
                          let content = dateNode.content else {
                            APILogger.shared.log(message: "Error scraping date for NFL live",
                                                 logLevel: .error)
                            failure(nil)
                            return
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
                                APILogger.shared.log(message: "Error scraping score box for NFL live",
                                                     logLevel: .error)
                                failure(nil)
                                return
                            }
                            if teamWrapperChild.attributes == ["class": "away-team"] {
                                // Retrieve away team info
                                let awayTeamChildren = teamWrapperChild.children
                                guard let teamDataNode = awayTeamChildren.filter({ $0.attributes == ["class": "team-data"] }).first else {
                                    APILogger.shared.log(message: "Error scraping team data for away team in NFL live",
                                                         logLevel: .error)
                                    failure(nil)
                                    return
                                }
                                let teamDataChildren = teamDataNode.children
                                for teamDataChild in teamDataChildren {
                                    if teamDataChild.attributes == ["class": "team-info"] {
                                        // Retrieve away team name
                                        guard let teamNameNode = teamDataChild.children.filter({ $0.attributes == ["class": "team-name"] }).first,
                                              let content = teamNameNode.content else {
                                                APILogger.shared.log(message: "Error scraping away team name in NFL live",
                                                                     logLevel: .error)
                                                failure(nil)
                                                return
                                        }
                                        awayTeamName = content
                                        // Retrieve away team record info
                                        if let teamRecordNode = teamDataChild.children.filter({ $0.attributes == ["class": "team-record"] }).first,
                                           let recordContent = teamRecordNode.children.first?.content {
                                            // Parse content for wins, losses and ties
                                            let trimmedString = recordContent.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
                                            let recordStrings = trimmedString.components(separatedBy: "-")
                                            guard let wins = Int(recordStrings[0]),
                                                let losses = Int(recordStrings[1]),
                                                let ties = Int(recordStrings[2]) else {
                                                    APILogger.shared.log(message: "Error scraping away team name in NFL live",
                                                                         logLevel: .error)
                                                    failure(nil)
                                                    return
                                            }
                                            awayTeamRecordWins = wins
                                            awayTeamRecordLosses = losses
                                            awayTeamRecordTies = ties
                                        } else {
                                            // This is a future game
                                            awayTeamRecordWins = 0
                                            awayTeamRecordLosses = 0
                                            awayTeamRecordTies = 0
                                        }
                                    } else if teamDataChild.attributes == ["class": "total-score"] {
                                        // Retrieve away team score
                                        guard let content = teamDataChild.content else {
                                            APILogger.shared.log(message: "Error scraping away team score in NFL live",
                                                                 logLevel: .error)
                                            failure(nil)
                                            return
                                        }
                                        // Check if the string is '--'
                                        if let awayScore = Int(content) {
                                            awayTeamScore = awayScore
                                        } else {
                                            awayTeamScore = 0
                                        }
                                    } else if teamDataChild.attributes == ["class": "quarters-score"] {
                                        // Retrieve scores for each quarter
                                        let quarterScoreChildren = teamDataChild.children
                                        for quarterScoreChild in quarterScoreChildren {
                                            var score = 0
                                            if let content = quarterScoreChild.content,
                                               let quarterScore = Int(content) {
                                                score = quarterScore
                                            }
                                            if quarterScoreChild.attributes == ["class": "first-qt"] {
                                                // Retrieve first quarter score
                                                awayTeamScoreQ1 = score
                                            } else if quarterScoreChild.attributes == ["class": "second-qt"] {
                                                // Retrieve second quarter score
                                                awayTeamScoreQ2 = score
                                            } else if quarterScoreChild.attributes == ["class": "third-qt"] {
                                                // Retrieve third quarter score
                                                awayTeamScoreQ3 = score
                                            } else if quarterScoreChild.attributes == ["class": "fourth-qt"] {
                                                // Retrieve fourth quarter score
                                                awayTeamScoreQ4 = score
                                            } else if quarterScoreChild.attributes == ["class": "ot-qt"] {
                                                // Retrieve over time score
                                                awayTeamScoreOT = score
                                            }
                                        }
                                    }
                                }
                            } else {
                                // Retrieve home team info
                                let homeTeamChildren = teamWrapperChild.children
                                guard let teamDataNode = homeTeamChildren.filter({ $0.attributes == ["class": "team-data"] }).first else {
                                    APILogger.shared.log(message: "Error scraping team data for home team in NFL live",
                                                         logLevel: .error)
                                    failure(nil)
                                    return
                                }
                                let teamDataChildren = teamDataNode.children
                                for teamDataChild in teamDataChildren {
                                    if teamDataChild.attributes == ["class": "team-info"] {
                                        // Retrieve home team name
                                        guard let teamNameNode = teamDataChild.children.filter({ $0.attributes == ["class": "team-name"] }).first,
                                              let content = teamNameNode.content else {
                                                APILogger.shared.log(message: "Error scraping home team name in NFL live",
                                                                     logLevel: .error)
                                                failure(nil)
                                                return
                                        }
                                        homeTeamName = content
                                        // Retrieve home team record info
                                        if let teamRecordNode = teamDataChild.children.filter({ $0.attributes == ["class": "team-record"] }).first,
                                           let recordContent = teamRecordNode.children.first?.content {
                                            // Parse content for wins, losses and ties
                                            let trimmedString = recordContent.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
                                            let recordStrings = trimmedString.components(separatedBy: "-")
                                            guard let wins = Int(recordStrings[0]),
                                                let losses = Int(recordStrings[1]),
                                                let ties = Int(recordStrings[2]) else {
                                                    APILogger.shared.log(message: "Error converting records of home team in NFL live",
                                                                         logLevel: .error)
                                                    failure(nil)
                                                    return
                                            }
                                            homeTeamRecordWins = wins
                                            homeTeamRecordLosses = losses
                                            homeTeamRecordTies = ties
                                        } else {
                                            // This is a future game
                                            homeTeamRecordWins = 0
                                            homeTeamRecordLosses = 0
                                            homeTeamRecordTies = 0
                                        }
                                    } else if teamDataChild.attributes == ["class": "total-score"] {
                                        // Retrieve home team score
                                        guard let content = teamDataChild.content else {
                                            APILogger.shared.log(message: "Error scraping home team score in NFL live",
                                                                 logLevel: .error)
                                            failure(nil)
                                            return
                                        }
                                        // Check if the string is '--'
                                        if let homeScore = Int(content) {
                                            homeTeamScore = homeScore
                                        } else {
                                            homeTeamScore = 0
                                        }
                                    } else if teamDataChild.attributes == ["class": "quarters-score"] {
                                        // Retrieve scores for each quarter
                                        let quarterScoreChildren = teamDataChild.children
                                        for quarterScoreChild in quarterScoreChildren {
                                            var score = 0
                                            if let content = quarterScoreChild.content,
                                               let quarterScore = Int(content) {
                                                score = quarterScore
                                            }
                                            if quarterScoreChild.attributes == ["class": "first-qt"] {
                                                // Retrieve first quarter score
                                                homeTeamScoreQ1 = score
                                            } else if quarterScoreChild.attributes == ["class": "second-qt"] {
                                                // Retrieve second quarter score
                                                homeTeamScoreQ2 = score
                                            } else if quarterScoreChild.attributes == ["class": "third-qt"] {
                                                // Retrieve third quarter score
                                                homeTeamScoreQ3 = score
                                            } else if quarterScoreChild.attributes == ["class": "fourth-qt"] {
                                                // Retrieve fourth quarter score
                                                homeTeamScoreQ4 = score
                                            } else if quarterScoreChild.attributes == ["class": "ot-qt"] {
                                                // Retrieve over time score
                                                homeTeamScoreOT = score
                                            }
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
                                    APILogger.shared.log(message: "Error scraping game status in NFL live",
                                                         logLevel: .error)
                                    failure(nil)
                                    return
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
                  let teamHomeRecordWins = homeTeamRecordWins,
                  let teamHomeRecordLosses = homeTeamRecordLosses,
                  let teamHomeRecordTies = homeTeamRecordTies,
                  let teamAwayName = awayTeamName,
                  let teamAwayScore = awayTeamScore,
                  let teamAwayRecordWins = awayTeamRecordWins,
                  let teamAwayRecordLosses = awayTeamRecordLosses,
                  let teamAwayRecordTies = awayTeamRecordTies,
                  let status = gameStatus else {
                    APILogger.shared.log(message: "Values are missing for schedule",
                                         logLevel: .error)
                    failure(nil)
                    return
            }
            // Construct schedule response
            let awayTeamRecord = ["wins": teamAwayRecordWins,
                                  "losses": teamAwayRecordLosses,
                                  "ties": teamAwayRecordTies]
            let awayTeamScoreByQuarter = ["Q1": awayTeamScoreQ1,
                                          "Q2": awayTeamScoreQ2,
                                          "Q3": awayTeamScoreQ3,
                                          "Q4": awayTeamScoreQ4,
                                          "OT": awayTeamScoreOT]
            let awayTeam: [String: Any] = ["teamName": teamAwayName,
                                           "record": awayTeamRecord,
                                           "score": teamAwayScore,
                                           "scoreByQuarter": awayTeamScoreByQuarter]
            let homeTeamRecord = ["wins": teamHomeRecordWins,
                                  "losses": teamHomeRecordLosses,
                                  "ties": teamHomeRecordTies]
            let homeTeamScoreByQuarter = ["Q1": homeTeamScoreQ1,
                                          "Q2": homeTeamScoreQ2,
                                          "Q3": homeTeamScoreQ3,
                                          "Q4": homeTeamScoreQ4,
                                          "OT": homeTeamScoreOT]
            let homeTeam: [String: Any] = ["teamName": teamHomeName,
                                           "record": homeTeamRecord,
                                           "score": teamHomeScore,
                                           "scoreByQuarter": homeTeamScoreByQuarter]
            let schedule = JSON(["type": ModelType.nflLive.rawValue,
                                 "season": self.season,
                                 "week": self.week,
                                 "date": dateStarted,
                                 "homeTeam": homeTeam,
                                 "awayTeam": awayTeam,
                                 "gameStatus": status])
            scheduleDictionary.append(schedule)
        }
        success(scheduleDictionary)
    }
}


// MARK: - Private Enums

/**
    An enum that defines the endpoints for
    different sport leagues.
*/
fileprivate enum Endpoint {
    static let nflLive = "http://www.nfl.com/scores/"
    static let nflHistorical = "http://www.nfl.com/schedules/"
    static let nflCurrent = "https://www.cbssports.com/nfl/schedules/regular"
}
