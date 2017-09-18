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
import SwiftyJSON

/**
    A protocol that defines how HTML pulled from
    a website should be scraped
*/
protocol Scrapable {
    
    /**
        Scrapes a live schedule.
     
        - Parameters:
            - success: A closure that gets invoked when scraping was successful.
            - failure: A closure that gets invoked when scraping failed.
            - results: A `[JSON]` representing the results that were retrieved.
                       Gets passed in `success`.
            - error: A `Error?` representing the error that occured. Gets passed
                     in `failure`.
    */
    func scrapeLiveSchedule(success: @escaping (_ results: [JSON]) -> Void,
                            failure: @escaping (_ error: Error?) -> Void)
    
    /**
        Scrapes a historical schedule.
     
        - Parameters:
            - success: A closure that gets invoked when scraping was successful.
            - failure: A closure that gets invoked when scraping failed.
            - results: A `[JSON]` representing the results that were retrieved.
                       Gets passed in `success`.
            - error: A `Error?` representing the error that occured. Gets passed
                     in `failure`.
    */
    func scrapeHistoricalSchedule(success: @escaping (_ results: [JSON]) -> Void,
                                  failure: @escaping (_ error: Error?) -> Void)
    
    /**
        Calculates current position in a league.
     
        - Parameters:
            - success: A closure that gets invoked when scraping was successful.
            - failure: A closure that gets invoked when scraping failed.
            - result: A `JSON` representing the results that were retrieved.
                       Gets passed in `success`.
            - error: A `Error?` representing the error that occured. Gets passed
                     in `failure`.
    */
    func calculateCurrentPosition(success: @escaping (_ result: JSON) -> Void,
                               failure: @escaping (_ error: Error?) -> Void)
    
    /**
        Scrapes mock data for  live schedule.
     
        - Parameters:
            - timePeriod: A `TimePeriod` representing the period in time to
                          retrieve.
            - success: A closure that gets invoked when scraping was successful.
            - failure: A closure that gets invoked when scraping failed.
            - result: A `[JSON]` representing the results that were retrieved.
                      Gets passed in `success`.
            - error: A `Error?` representing the error that occured. Gets passed
                     in `failure`.
    */
    func scrapeMock(timePeriod: TimePeriod,
                    success: @escaping (_ result: [JSON]) -> Void,
                    failure: @escaping (_ error: Error?) -> Void)
}

/**
    An enum that defines the different
    time periods of a simulated week.
*/
enum TimePeriod: Int {
    case beginning
    case middle
    case final
}
