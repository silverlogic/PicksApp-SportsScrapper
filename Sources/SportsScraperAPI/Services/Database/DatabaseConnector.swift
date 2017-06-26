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
import CouchDB
import CloudFoundryEnv

#if os(Linux)
    typealias ValueType = Any
#else
    typealias ValueType = AnyObject
#endif

/**
    A class responsible for interacting with
    the database.
*/
public final class DatabaseConnector {
    
    // MARK: - Internal Class Attributes
    static let defaultDBHost = "localhost"
    static let defaultDBPort = Int16(5986)
    static let defaultDBName = "sportsdata"
    static let defaultUsername = "admin"
    static let defaultPassword = "password"
    
    
    // MARK: - Private Instance Attributes
    let databaseName: String
    let databasDesignName = "sportsdatadesign"
    let connectionProperties: ConnectionProperties
    
    
    // MARK: - Initializers
    
    /**
        Initializes an instance of `DatabaseConnector` with connection
        properties.
     
        - Parameters:
            - databaseName: A `String` representing the name of the database.
            - host: A `String` representing the hostname of IP address to a
                    CouchDB server
            - port: An `UInt16` representing the port number where the CouchDB
                    server should listen for incoming connections.
            - databaseUsername: A `String` representing the CouchDB username.
            - databasePassword: A `String` representing the CouchDB admin
                                password.
    */
    public init(databaseName: String = DatabaseConnector.defaultDBName,
                host: String = DatabaseConnector.defaultDBHost,
                port: Int16 = DatabaseConnector.defaultDBPort,
                databaseUsername: String = DatabaseConnector.defaultUsername,
                databasePassword: String = DatabaseConnector.defaultPassword) {
        let secured = host == DatabaseConnector.defaultDBHost ? false : true
        connectionProperties = ConnectionProperties(host: host, port: port,
                                                    secured: secured,
                                                    username: databaseUsername,
                                                    password: databasePassword)
        self.databaseName = databaseName
        // @TODO: Call method to setup the database
    }
    
    /**
        Convenience initializer that intializes an instance of 
        `DatabaseConnector` with a service.
     
        - Parameter service: A `Service` representing the database service being
                             used with Bluemix.
    */
    public convenience init(service: Service) {
        if let credentials = service.credentials,
           let host = credentials["host"] as? String,
           let username = credentials["username"] as? String,
           let password = credentials["password"] as? String,
           let tempPort = credentials["port"] as? Int {
            let port = Int16(tempPort)
            APILogger.shared.log(message: "Using provided credentials from service",
                                 logLevel: .info)
            self.init(databaseName: DatabaseConnector.defaultDBName,
                      host: host,
                      port: port,
                      databaseUsername: username,
                      databasePassword: password)
        } else {
            APILogger.shared.log(message: "Using development credentials",
                                 logLevel: .info)
            self.init()
        }
    }
    
    
    // MARK: - Private Instance Methods
    
    /// Sets up the database.
    private func setupDatabase() {
        let couchClient = CouchDBClient(connectionProperties: connectionProperties)
        couchClient.dbExists(databaseName) { (exists, error) in
            guard error == nil else {
                APILogger.shared.log(message: error!.localizedDescription,
                                     logLevel: .error)
                return
            }
            if exists {
                APILogger.shared.log(message: "\(self.databaseName) already exists",
                                     logLevel: .info)
            } else {
                APILogger.shared.log(message: "\(self.databaseName) doesn't exist. Creating...",
                                     logLevel: .warning)
                couchClient.createDB(self.databaseName, callback: { (database, error) in
                    guard let createdDatabase = database else {
                        APILogger.shared.log(message: "Error creating \(self.databaseName)",
                                             logLevel: .error)
                        APILogger.shared.log(message: "Error: \(error!.localizedDescription)",
                                             logLevel: .error)
                        return
                    }
                    self.setupDatabaseDesign(database: createdDatabase)
                })
            }
        }
    }
    
    /**
        Sets up the database design document to use for the database.
     
        - Parameter database: A `Database` representing the database to create
                              the design document for.
    */
    private func setupDatabaseDesign(database: Database) {
        let databaseDesign: [String: Any] = [
            "_id": "-design/\(databasDesignName)",
            "views": [
                "all_documents": [
                    "map": "function(doc) { emit(doc._id, [doc._id, doc._rev]); }"
                ]
            ]
        ]
    }
}