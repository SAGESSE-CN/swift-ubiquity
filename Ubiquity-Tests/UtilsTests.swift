//
//  UtilsTests.swift
//  Ubiquity.Tests
//
//  Created by sagesse on 18/12/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import XCTest
@testable import Ubiquity

internal class UtilsTests: XCTestCase {
    
    

    func testConvertDate() {
    
        let t = 24 * 3600
        let x = TimeInterval((time(nil) / t) * t) + TimeInterval(TimeZone.current.secondsFromGMT())
    
        XCTAssertEqual(ub_string(for: .init(timeIntervalSince1970: x)), "Today")
        XCTAssertEqual(ub_string(for: .init(timeIntervalSince1970: x + 24 * 3600)), "Tomorrow")
        XCTAssertEqual(ub_string(for: .init(timeIntervalSince1970: x - 24 * 3600)), "Yesterday")

        XCTAssertNotEqual(ub_string(for: .init(timeIntervalSince1970: x - 3 * 24 * 3600)), "")
        XCTAssertNotEqual(ub_string(for: .init(timeIntervalSince1970: x - 7 * 24 * 3600)), "")
        XCTAssertNotEqual(ub_string(for: .init(timeIntervalSince1970: x - 156 * 24 * 3600)), "")
        XCTAssertNotEqual(ub_string(for: .init(timeIntervalSince1970: x - 365 * 24 * 3600)), "")
        XCTAssertNotEqual(ub_string(for: .init(timeIntervalSince1970: x - 432 * 24 * 3600)), "")
    }

}
