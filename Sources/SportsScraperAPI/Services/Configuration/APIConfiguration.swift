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
import Configuration
import CloudFoundryEnv

/**
    A class responsible for retrieving
    configurations used in the server.
*/
public final class APIConfiguration {
    
    // MARK: - Private Instance Attributes
    private let configurationManager = ConfigurationManager()
    
    
    // MARK: - Getters & Setters
    
    /// The port being used for listening.
    public var port: Int { return configurationManager.port }
    
    /// The url where the API can be accessed at.
    public var url: String { return configurationManager.url }
    
    
    // MARK: - Initialiers
    
    /// Initializes an instance of `APIConfiguration`.
    public init() {}
    
    
    // MARK: - Public Instance Methods
    
    /**
        Retrieves the configuration for setting up
        the database.
     
        - Throws: A `ConfigurationError` specifying the
                  error that has occured.
     
        - Returns: A `Service` that represents the database
                   service being used.
    */
    public func databaseConfiguration() throws -> Service {
        APILogger.shared.log(message: "Attempting to retrieve Cloud Foundary environment", logLevel: .warning)
        do {
            configurationManager.load(.environmentVariables)
            let services = configurationManager.getServices()
            let servicePair = services
                .filter({ $0.value.label == "cloudantNoSQLDB" }).first
            guard let service = servicePair?.value else {
                throw ConfigurationError.databaseConfiguration
            }
            return service
        } catch {
            APILogger.shared.log(message: "Error occured while retrieving database configuration", logLevel: .warning)
            throw ConfigurationError.databaseConfiguration
        }
    }
}


/**
    An enum that defines errors that can
    occur when working with configurations.
*/
public enum ConfigurationError: Error {
    case databaseConfiguration
}
