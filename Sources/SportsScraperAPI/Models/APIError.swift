//
//  APIError.swift
//  SportsScraper
//
//  Created by Emanuel  Guerrero on 6/21/17.
//
//

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
extension APIError: ToJSON {
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
