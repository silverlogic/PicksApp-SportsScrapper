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
}
