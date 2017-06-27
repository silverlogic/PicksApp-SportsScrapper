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
import SwiftyJSON
import Dispatch

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
    static let defaultDBPort = Int16(5984)
    static let defaultDBName = "sportsdata"
    static let defaultUsername = "admin"
    static let defaultPassword = "password"
    
    
    // MARK: - Private Instance Attributes
    fileprivate let databaseDesignName = "sportsdatadesign"
    fileprivate let connectionProperties: ConnectionProperties
    fileprivate let databaseName: String
    
    
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
        setupDatabase()
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
                let database = couchClient.database(self.databaseName)
                self.setupDesignDocument(database: database, shouldUpdate: true)
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
                    self.setupDesignDocument(database: createdDatabase,
                                             shouldUpdate: false)
                })
            }
        }
    }
    
    /**
        Sets up the database design document to use for the database.
     
        - Note: We originally had a method for just creating the design document
                which made this method a little bit cleaner. But after testing
                in Linux Ubuntu, we kept getting a consistent complier error
                with captured constant propagation.
     
        - Parameters: 
            - database: A `Database` representing the database to create
                        the design document for.
            - shouldUpdate: A `Bool` indicating if the design needs to be
                            updated.
    */
    private func setupDesignDocument(database: Database, shouldUpdate: Bool) {
        // @TODO: Implement better map fucntions so that CouchDB can query.
        let databaseDesign: [String: Any] = [
            "_id": "_design/\(databaseDesignName)",
            "views": [
                "all_documents": [
                    "map": "function(doc) { emit(doc._id, [doc._id, doc._rev]); }"
                ],
                "all_nfl_live": [
                    "map": "function(doc) { if (doc.type == \(ModelType.nflLive.rawValue)) { emit(doc.id, doc); } }"
                ],
                "all_nfl_historical": [
                    "map": "function(doc) { if (doc.type == \(ModelType.nflHistorical.rawValue)) { emit(doc.id, doc); } }"
                ]
            ]
        ]
        if shouldUpdate {
            database.retrieve("_design/\(databaseDesignName)",
                              callback: { (document, error) in
                guard error == nil else {
                    APILogger.shared.log(message: "Error retrieving design document",
                                         logLevel: .error)
                    APILogger.shared.log(message: "\((error?.localizedDescription)!)",
                                         logLevel: .error)
                    return
                }
                guard let designDocument = document else {
                    APILogger.shared.log(message: "No design document received",
                                         logLevel: .error)
                    return
                }
                let revision = designDocument["_rev"].stringValue
                database.deleteDesign(self.databaseDesignName,
                                      revision: revision,
                                      callback: { (deleteError) in
                    guard deleteError == nil else {
                        APILogger.shared.log(message: "Error deleting design document",
                                             logLevel: .error)
                        APILogger.shared.log(message: "\((deleteError?.localizedDescription)!)",
                                             logLevel: .error)
                        return
                    }
                    database.createDesign(self.databaseDesignName,
                                          document: JSON(databaseDesign),
                                          callback: { (document, error) in
                        guard error == nil else {
                            APILogger.shared.log(message: "Error creating database design",
                                                 logLevel: .error)
                            return
                        }
                        APILogger.shared.log(message: "Database design updated",
                                             logLevel: .info)
                    })
                })
            })
        } else {
            database.createDesign(self.databaseDesignName,
                                  document: JSON(databaseDesign),
                                  callback: { (document, error) in
                guard error == nil else {
                    APILogger.shared.log(message: "Error creating database design",
                                         logLevel: .error)
                    return
                }
                APILogger.shared.log(message: "Database design created",
                                     logLevel: .info)
            })
        }
    }
}


// MARK: - Public Instance Methods
extension DatabaseConnector {
    
    /**
        Clears all documents in the database.
     
        - Note: This method should only be used when running tests. It shouldn't
                be used in production.
     
        - Parameters:
            - success: A closure that gets invoked when clearing was
                       successful.
            - failure: A closure that gets invoked when clearing failed.
            - error: A `Error?` representing the error that occured. Gets passed
                     in `failure`.
    */
    func clearAll(success: @escaping () -> Void,
                  failure: @escaping (_ error: Error?) -> Void) {
        let couchClient = CouchDBClient(connectionProperties: connectionProperties)
        let database = couchClient.database(databaseName)
        database.queryByView("all_documents",
                             ofDesign: databaseDesignName,
                             usingParameters: [.descending(true), .includeDocs(true)])
        { (document, error) in
            guard error == nil else {
                APILogger.shared.log(message: "Error clearing all documents",
                                     logLevel: .error)
                APILogger.shared.log(message: "\((error?.localizedDescription)!)",
                    logLevel: .error)
                failure(error)
                return
            }
            guard let retrievedDocument = document,
                  let rows = retrievedDocument["rows"].array else {
                APILogger.shared.log(message: "No document returned",
                                     logLevel: .error)
                failure(nil)
                return
            }
            let documentIdsAndRevisionIds: [(String, String)] = rows.flatMap {
                let modelDocument = $0["doc"]
                let id = modelDocument["_id"].stringValue
                let revisionId = modelDocument["_rev"].stringValue
                return (id, revisionId)
            }
            if documentIdsAndRevisionIds.count == 0 {
                success()
            } else {
                let dispatchQueue = DispatchQueue.global(qos: .utility)
                let dispatchGroup = DispatchGroup()
                var deleteError: Error?
                for i in 0...documentIdsAndRevisionIds.count - 1 {
                    dispatchGroup.enter()
                    dispatchQueue.async {
                        let idTuple = documentIdsAndRevisionIds[i]
                        database.delete(idTuple.0, rev: idTuple.1,
                                        callback: { (error) in
                            if error != nil {
                                deleteError = error
                            }
                            dispatchGroup.leave()
                        })
                    }
                }
                dispatchGroup.notify(queue: DispatchQueue.main, execute: { 
                    guard deleteError == nil else {
                        APILogger.shared.log(message: "Error deleting documents",
                                             logLevel: .error)
                        failure(deleteError)
                        return
                    }
                    success()
                })
            }
        }
    }
    
    /**
        Generic method for retrieving all documents of a NFL model type that
        conforms to `Queryable`.
     
        - Parameters:
            - type: A `T.Type` representing the model type to retrieve.
            - season: A `Int` representing the season.
            - week: A `Int` representing the week.
            - success: A closure that gets invoked when fetcing was successful.
            - failure: A closure that gets invoked when fetching failed.
            - documents: A `[T]` representing the retrieved model type. Gets
                         passed in `success`.
            - error: A `Error` representing the error that occured. Gets passed
                     in `failure`.
    */
    func fetchNflDocuments<T: NflSchedule>(type: T.Type,
                                            season: Int,
                                            week: Int,
                                            success: @escaping (_ documents: [T]) -> Void,
                                            failure: @escaping (_ error: Error?) -> Void)
                                            where T: Queryable {
        let couchClient = CouchDBClient(connectionProperties: connectionProperties)
        let database = couchClient.database(databaseName)
        database.queryByView(type.allDocumentsViewName, ofDesign: databaseDesignName,
                             usingParameters: [.descending(true), .includeDocs(true)])
        { (document, error) in
            guard error == nil else {
                failure(error)
                return
            }
            guard let retrievedDocument = document else {
                failure(nil)
                return
            }
            guard let rows = retrievedDocument["rows"].array else {
                failure(nil)
                return
            }
            // Not the best implementation for querying based on keys. Should
            // let CouchDB handle it but not sure how to emit multiple keys.
            let items: [T] = rows.flatMap {
                var modelDocument = $0["value"]
                if modelDocument["season"].intValue == season &&
                   modelDocument["week"].intValue == week {
                    modelDocument.dictionaryObject?.removeValue(forKey: "_id")
                    modelDocument.dictionaryObject?.removeValue(forKey: "_rev")
                    let model = T(document: modelDocument)
                    return model
                } else {
                    return nil
                }
            }
            success(items)
        }
    }
    
    /**
        Inserts a new document into the database.
     
        - Parameters:
            - document: A `JSON` representing the document to insert.
            - success: A closure that gets invoke when inserting was successful.
            - failure: A closure that gets invoked when inserting failed.
            - error: A `Error?` representing the error tha occured. Gets passed
                     in `failure`.
    */
    func insertDocument(_ document: JSON,
                        success: @escaping () -> Void,
                        failure: @escaping (_ error: Error?) -> Void) {
        let couchClient = CouchDBClient(connectionProperties: connectionProperties)
        let database = couchClient.database(databaseName)
        database.create(document) { (id, revisionId, createdDocument, error) in
            guard error == nil else {
                failure(error)
                return
            }
            success()
        }
    }
}
