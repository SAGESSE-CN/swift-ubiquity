//
//  RectTests.swift
//  Ubiquity.Tests
//
//  Created by sagesse on 25/12/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import XCTest
@testable import Ubiquity

func mk(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
    return .init(x: x, y: y, width: w, height: h)
}

class RectTests: XCTestCase {
    
    func testRemaining() {
        // n
        XCTAssertEqual(remaining(mk(0,0,4,4), mk(0,0,4,4)), [])
        XCTAssertEqual(remaining(mk(0,0,4,4), mk(0,4,4,4)), [mk(0,0,4,4)])

        // y
        XCTAssertEqual(remaining(mk(0,0,4,8), mk(0,8,4,4)), [mk(0,0,4,8)]) // v: ■■■■
        XCTAssertEqual(remaining(mk(0,0,4,8), mk(0,0,4,4)), [mk(0,4,4,4)]) // v: □□■■
        XCTAssertEqual(remaining(mk(0,0,4,8), mk(0,4,4,4)), [mk(0,0,4,4)]) // v: ■■□□
        XCTAssertEqual(remaining(mk(0,0,4,8), mk(0,4,4,2)), [mk(0,0,4,4),mk(0,6,4,2)]) // v: ■□□■
        
        // x
        XCTAssertEqual(remaining(mk(0,0,8,4), mk(8,0,4,4)), [mk(0,0,8,4)]) // h: ■■■■
        XCTAssertEqual(remaining(mk(0,0,8,4), mk(0,0,4,4)), [mk(4,0,4,4)]) // h: □□■■
        XCTAssertEqual(remaining(mk(0,0,8,4), mk(4,0,4,4)), [mk(0,0,4,4)]) // h: ■■□□
        XCTAssertEqual(remaining(mk(0,0,8,4), mk(4,0,2,4)), [mk(0,0,4,4),mk(6,0,2,4)]) // h: ■□□■
        
        // m
        XCTAssertEqual(remaining(mk(0,0,8,8), mk(4,4,8,8)), [mk(0,0,4,8),mk(4,0,4,4)])
        XCTAssertEqual(remaining(mk(4,4,8,8), mk(0,0,8,8)), [mk(8,4,4,8),mk(4,8,4,4)])
        
        // c
        XCTAssertEqual(remaining(mk(0,0,8,8), mk(2,2,4,4)), [mk(0,0,2,8),mk(6,0,2,8),mk(2,0,4,2),mk(2,6,4,2)])
    }
    
    func testMerging() {
        // n
        XCTAssertEqual(merging([mk(0,0,4,4), mk(0,8,4,4)]), [mk(0,0,4,4), mk(0,8,4,4)])

        // y
        XCTAssertEqual(merging([mk(0,0,4,4), mk(0,2,4,4)]), [mk(0,0,4,6)])
        XCTAssertEqual(merging([mk(0,2,4,4), mk(0,0,4,4)]), [mk(0,0,4,6)])

        // x
        XCTAssertEqual(merging([mk(0,0,4,4), mk(2,0,4,4)]), [mk(0,0,6,4)])
        XCTAssertEqual(merging([mk(2,0,4,4), mk(0,0,4,4)]), [mk(0,0,6,4)])

        // m
        XCTAssertEqual(merging([mk(0,0,4,4), mk(2,2,4,4)]), [mk(0,0,6,6)])
        XCTAssertEqual(merging([mk(2,2,4,4), mk(0,0,4,4)]), [mk(0,0,6,6)])
    }
    
    func testIntersection() {
        // n
        XCTAssertEqual(intersection([mk(0,0,4,4), mk(0,8,4,4)]), [mk(0,0,4,4), mk(0,8,4,4)])

        // y
        XCTAssertEqual(intersection([mk(0,0,4,4), mk(0,2,4,4)]), [mk(0,2,4,2)])
        XCTAssertEqual(intersection([mk(0,2,4,4), mk(0,0,4,4)]), [mk(0,2,4,2)])
        
        // x
        XCTAssertEqual(intersection([mk(0,0,4,4), mk(2,0,4,4)]), [mk(2,0,2,4)])
        XCTAssertEqual(intersection([mk(2,0,4,4), mk(0,0,4,4)]), [mk(2,0,2,4)])
        
        // m
        XCTAssertEqual(intersection([mk(0,0,4,4), mk(2,2,4,4)]), [mk(2,2,2,2)])
        XCTAssertEqual(intersection([mk(2,2,4,4), mk(0,0,4,4)]), [mk(2,2,2,2)])
    }
    
    func testOther() {
        XCTAssertEqual(remaining(mk(-150,0,600,160), mk(0,0,0,0)), [mk(-150,0,600,160)])
    }
}
