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

import XCTest
@testable import SportsScraperAPI

/**
    Test suite for testing `MockLoader`.
*/
final class MockLoaderTests: XCTestCase {
    
    // MARK: - Public Class Attributes
    static var allTests = [
        ("testReadMockFile", testReadMockFile)
    ]
    
    
    // MARK: - Public Instance Attributes
    var mockLoader: MockLoader!
    
    
    // MARK: - Setup & Tear Down
    override func setUp() {
        super.setUp()
        mockLoader = MockLoader()
    }
    
    override func tearDown() {
        super.tearDown()
        mockLoader = nil
    }
    
    
    // MARK: - Test Methods
    
    /// Test retriving different mock data files.
    func testReadMockFile() {
        let nflLiveBeginningData = mockLoader.readMockFile(.nflLiveBeginning)
        XCTAssertNotNil(nflLiveBeginningData, "Value shouldn't be nil")
    }
}
