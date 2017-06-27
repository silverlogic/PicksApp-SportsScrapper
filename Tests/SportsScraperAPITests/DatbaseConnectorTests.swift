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

import XCTest
import SwiftyJSON
@testable import SportsScraperAPI

/**
    Test suite for testing `DatabaseConnector`.
*/
class DatabaseConnectorTests: XCTestCase {
    
    // MARK: - Public Class Attributes
    static var allTests = [
        ("testInsertAndQueryNflLive", testInsertAndQueryNflLive),
        ("testInsertAndQueryNflHistorical", testInsertAndQueryNflHistorical)
    ]
    
    
    // MARK: - Public Instance Attributes
    var database: DatabaseConnector?
    
    
    // MARK: - Setup & Tear Down
    override func setUp() {
        database = DatabaseConnector(databaseName: "testdatabasesports")
        super.setUp()
    }
    
    override func tearDown() {
        guard let database = database else {
            preconditionFailure("No datbase instance exists")
        }
        database.clearAll(success: { 
            APILogger.shared.log(message: "All documents have been cleared for tests",
                                 logLevel: .warning)
        }) { (error) in
            APILogger.shared.log(message: "Error clearing all documents",
                                 logLevel: .warning)
        }
    }
    
    
    // MARK: - Test Methods
    
    /// Tests inserting a `NflLive` model instance and querying it.
    func testInsertAndQueryNflLive() {
        let homeTeamScoreByQuarter = ["Q1": 7, "Q2": 6, "Q3": 0, "Q4": 8]
        let homeTeamRecord = ["wins": 0, "losses": 1, "ties": 0]
        let homeTeam: [String: Any] = ["teamName": "Texans",
                                       "score": 19,
                                       "scoreByQuarter": homeTeamScoreByQuarter,
                                       "record": homeTeamRecord]
        let awayTeamScoreByQuarter = ["Q1": 7, "Q2": 6, "Q3": 1, "Q4": 8]
        let awayTeamRecord = ["wins": 1, "losses": 1, "ties": 0]
        let awayTeam: [String: Any] = ["teamName": "Chiefs",
                                       "score": 20,
                                       "scoreByQuarter": awayTeamScoreByQuarter,
                                       "record": awayTeamRecord]
        let game: [String: Any] = ["homeTeam": homeTeam,
                                   "gameStatus": "FINAL ",
                                   "week": 2,
                                   "date": "Sun, Sep 18",
                                   "type": ModelType.nflLive.rawValue,
                                   "season": 2016,
                                   "awayTeam": awayTeam]
        let json = JSON(game)
        let insertGameExpectation = expectation(description: "Add NflLive model instance")
        let queryNflLiveExpectation = expectation(description: "Query NflLive model instance")
        database?.insertDocument(json, success: { 
            self.database?.fetchNflDocuments(type: NflLive.self,
                                        season: 2016,
                                        week: 2,
                                        success: { (results: [NflLive]) in
                XCTAssertTrue(results.count == 1, "Results for NflLive are empty")
                queryNflLiveExpectation.fulfill()
            }, failure: { (error) in
                XCTFail("Error retrieving NflLive model instance")
                queryNflLiveExpectation.fulfill()
            })
            insertGameExpectation.fulfill()
        }, failure: { (error) in
            XCTFail("Error insserting NflLive model instance")
            insertGameExpectation.fulfill()
            queryNflLiveExpectation.fulfill()
        })
        waitForExpectations(timeout: 5) { (error) in
            XCTAssertNil(error, "Timeout error occured with testInsertAndRetrieveNflLive")
        }
    }
    
    /// Test inserting a `NflHistorical` model instance and querying it.
    func testInsertAndQueryNflHistorical() {
        let game: [String: Any] = ["homeTeamScore": 42,
                    "gameStatus": "FINAL",
                    "week": 11,
                    "date": "Sunday, November 20",
                    "homeTeamName": "Redskins",
                    "awayTeamName": "Packers",
                    "type": 1, "season": 2016,
                    "awayTeamScore": 24]
        let json = JSON(game)
        let insertGameExpectation = expectation(description: "Add NflHistorical model instance")
        let queryNflHistoricalExpectation = expectation(description: "Query NflHistorical model instance")
        database?.insertDocument(json, success: {
            self.database?.fetchNflDocuments(type: NflHistorical.self, season: 2016, week: 11, success: { (results: [NflHistorical]) in
                XCTAssertTrue(results.count == 1, "Results for NflHistorical are empty")
                queryNflHistoricalExpectation.fulfill()
            }, failure: { (error) in
                XCTFail("Error retrieving NflHistorical model instance")
                queryNflHistoricalExpectation.fulfill()
            })
            insertGameExpectation.fulfill()
        }, failure: { (error) in
            XCTFail("Error inserting NflHistorical model instance")
            insertGameExpectation.fulfill()
            queryNflHistoricalExpectation.fulfill()
        })
        waitForExpectations(timeout: 5) { (error) in
            XCTAssertNil(error, "Timeour error occured with testInsertAndQueryNflHistorical")
        }
    }
}
