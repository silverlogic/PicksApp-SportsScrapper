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

/**
    A class responsible for loading mock schedules.
*/
final class MockLoader {
    
    // MARK: - Private Instance Attributes
    private var rootPath: String
    
    
    // MARK: - Initializers
    
    /// Initializes an instance of `MockLoader`.
    init() {
        rootPath = URL(fileURLWithPath: #file + "/../Mock-Schedules").standardizedFileURL.path
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: rootPath) {
            // Running in Cloud Foundary
            // Need to start at the root directory
            let workingDirectory = fileManager.currentDirectoryPath
            let mockSchedulesDirectoryPath = URL(fileURLWithPath: workingDirectory + "/Sources/SportsScraperAPI/Models/Mock-Data/Mock-Schedules").path
            rootPath = mockSchedulesDirectoryPath
            if fileManager.fileExists(atPath: rootPath) {
                APILogger.shared.log(message: "This path exists! 😀", logLevel: .info)
            }
        }
        //APILogger.shared.log(message: "Current path to use: \(rootPath)", logLevel: .info)
    }
    
    
    // MARK: - Public Instance Methods
    
    /**
        Reads a mock data file.
     
        - Parameter mockFile: A `MockFile` representing the mock data file to
                              load.
     
        - Returns: A `Data?` representing the byte stream of the file. If the
                   file couldn't be loaded, `nil` will be returned.
    */
    func readMockFile(_ mockFile: MockFile) -> Data? {
        let fileManager = FileManager.default
        let path = rootPath + mockFile.rawValue
        guard fileManager.fileExists(atPath: path) else {
            APILogger.shared.log(message: "File does not exist for \(mockFile.rawValue)",
                                 logLevel: .error)
            return nil
        }
        guard fileManager.isReadableFile(atPath: rootPath) else {
            APILogger.shared.log(message: "File can't be read due to permissions",
                                 logLevel: .error)
            return nil
        }
        return fileManager.contents(atPath: path)
    }
}


/**
    An enum that defines the different mock files
    that can be loaded.
*/
enum MockFile: String {
    case nflLiveBeginning = "/NFL-live/nfl-live-mock-beginning.html"
    case nflLiveMiddle = "/NFL-live/nfl-live-mock-middle.html"
    case nflLiveFinal = "/NFL-live/nfl-live-mock-final.html"
}
