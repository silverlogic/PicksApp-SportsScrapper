//
//  ToJSON.swift
//  SportsScraper
//
//  Created by Emanuel  Guerrero on 6/21/17.
//
//

import Foundation
import SwiftyJSON

/**
    A protocol for defining how objects can 
    return a JSON representation.
*/
protocol ToJSON {
    func json() -> JSON
}
