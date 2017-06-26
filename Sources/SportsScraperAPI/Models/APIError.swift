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
    A struct representing an API error.
*/
struct APIError {
    
    // MARK: - Public Instance Attributes
    let errorDesciption: String
    
    
    // MARK: - Initializers
    
    /**
        Initializes an instance of `APIError`.
     
        - Parameter errorDescription: A `String` representing the description
                                      of the error that occured.
    */
    init(errorDescription: String) {
        self.errorDesciption = errorDescription
    }
}


// MARK: - ToJSON
extension APIError: Serializable {
    func json() -> JSON {
        return JSON(["Error": errorDesciption])
    }
}


// MARK: - Public Class Attributes
extension APIError {
    static var leagueType: APIError = {
        return APIError(errorDescription: "'leagueType' must be specified in path")
    }()
    
    static var year: APIError = {
        return APIError(errorDescription: "'year' must be specified in path")
    }()
    
    static var week: APIError = {
        return APIError(errorDescription: "'week' must be specified in path")
    }()
    
    static var invalidLeague: APIError = {
        return APIError(errorDescription: "Invalid league type selected")
    }()
    
    static var minmumYearNotMetLive: APIError = {
        return APIError(errorDescription: "'year' must be greater than 2001")
    }()
    
    static var minmumYearNotMetHistorical: APIError = {
        return APIError(errorDescription: "'year' must be greater than 1970")
    }()
    
    static var scrapperError: APIError = {
        return APIError(errorDescription: "scrapper error occured")
    }()
}
