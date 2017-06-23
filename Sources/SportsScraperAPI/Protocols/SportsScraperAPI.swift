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

import SwiftyJSON

/**
    A protocol that defines state and
    behavior for scrapping different
    sport leagues.
*/
protocol SportsScraperAPI {
    
    // MARK: - Public Instance Methods
    
    /**
        Retrieves the live schedule for the NFL.
     
        - Note: Can retrieve a schedule from 2001 to current.
     
        - Parameters:
            - season: An `Int` representing the season
                      in the NFL as a year.
            - week: An `Int` representing the week
                    in the season.
            - success: A closure that gets invoked
                       when the requested schedule was
                       retrieved. Passes a `JSON` to
                       send back to the client.
            - failure: A closure that gets invoked when
                       the requested schedule could not
                       be retrieved. Passes an `Error?`
                       indicating the error that occured.
    */
    func liveScheduleNFL(season: Int, week: Int, success: @escaping (JSON) -> Void, failure: @escaping (Error?) -> Void)
    
    /**
        Retrieves the historical schedule for the NFL.
     
        - Note: Can retrieve a schedule from 1970 to current.
     
        - Parameters:
            - season: An `Int` representing the season
                      in the NFL as a year.
            - week: An `Int` representing the week
                    in the season.
            - success: A closure that gets invoked
                       when the requested schedule was
                       retrieved. Passes a `JSON` to
                       send back to the client.
            - failure: A closure that gets invoked when
                       the requested schedule could not
                       be retrieved. Passes an `Error?`
                       indicating the error that occured.
    */
    func historicalScheduleNFL(season: Int, week: Int, success: @escaping (JSON) -> Void, failure: @escaping (Error?) -> Void)
    
    /**
        Retrieves the current season and week for the NFL.
     
        - Parameters:
            - success: A closure that gets invoked when
                       the requested schedule was retrieved.
                       Passes a `JSON` to send back to the
                       client.
            - failure: A closure that gets invoked when the
                       requested schedule could not be retrieved.
                       Passes an `Error?` indicating the error that
                       occured.
    */
    func currentSeasonWeek(success: @escaping (JSON) -> Void, failure: @escaping (Error?) -> Void)
}
