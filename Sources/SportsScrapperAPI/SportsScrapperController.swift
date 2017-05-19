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
public final class SportsScrapperController {
    
    // MARK: - Private Instance Atrributes
    private let sportsScrapper: SportsScrapper
    
    
    // MARK: - Public Instance Attributes
    public let router = Router()
    
    
    // MARK: - Initializers
    
    /**
        Initializes an instance of `SportsScrapperController`.
     
        - Parameter backend: A `SportsScrapper` representing
                             the scrapper used for scrapping.
    */
    public init(backend: SportsScrapper) {
        sportsScrapper = backend
        routeSetup()
    }
}


// MARK: - Private Instance Methods
fileprivate extension SportsScrapperController {
    
    /// Sets up all avaliable routes.
    func routeSetup() {
        router.all("/*", middleware: BodyParser())
    }
}
