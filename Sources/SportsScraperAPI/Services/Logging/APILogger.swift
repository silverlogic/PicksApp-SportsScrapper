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
import LoggerAPI
import SwiftyBeaverKitura
import SwiftyBeaver

/**
    A singleton responsible for logging
    messages to the console.
*/
public final class APILogger {
    
    // MARK: - Shared Instance
    
    /// A global instance that can be used for universal logging.
    public static let shared = APILogger()
    
    
    // MARK: - Intializers
    
    /// Initializes an instance of `APILogger`.
    private init() {
        Log.logger = SwiftyBeaverKitura(destinations: [ConsoleDestination()])
    }
    
    
    // MARK: - Public Instance Methods
    
    /**
        Logs a message into the console.
     
        - Parameters:
            - message: A `String` representing the message to display.
            - logLevel: A `LogLevelType` representing the type of log.
    */
    public func log(message: String, logLevel: LogLevelType) {
        switch logLevel {
        case .verbose:
            Log.verbose(message)
            break
        case .debug:
            Log.debug(message)
            break
        case .info:
            Log.info(message)
            break
        case .warning:
            Log.warning(message)
            break
        case .error:
            Log.error(message)
            break
        }
    }
}

/**
    An enum that defines the level
    type of logging
*/
public enum LogLevelType: Int {
    case verbose
    case debug
    case info
    case warning
    case error
}
