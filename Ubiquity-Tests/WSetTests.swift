//
//  WSetTests.swift
//  Ubiquity
//
//  Created by sagesse on 18/12/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import XCTest
@testable import Ubiquity

internal class WSetTests: XCTestCase {
    internal class WSetCounter: NSObject {
        internal static var instance: Int = 0
        override init() {
            super.init()
            WSetCounter.instance += 1
        }
        deinit {
            WSetCounter.instance -= 1
        }
    }
    
    func test(_ block: () -> ()) {
        WSetCounter.instance = 0
        autoreleasepool {
            block()
        }
        WSetCounter.instance = 0
    }
    
    func testInsert() {
        
        test {
            var s = WSet<WSetCounter>()
            autoreleasepool {
                XCTAssertEqual(s.count, 0)
                s.insert(WSetCounter())
                XCTAssertEqual(s.count, 1)
            }
            XCTAssertEqual(s.count, 1)
            XCTAssertEqual(WSetCounter.instance, 0)
        }
        
        test {
            var s = WSet<WSetCounter>()
            autoreleasepool {
                XCTAssertEqual(s.count, 0)
                let ct = WSetCounter()
                s.insert(ct)
                s.insert(ct)
                XCTAssertEqual(s.count, 1)
            }
            XCTAssertEqual(s.count, 1)
            XCTAssertEqual(WSetCounter.instance, 0)
        }
        
        test {
            var s = WSet<WSetCounter>(minimumCapacity: 1)
            autoreleasepool {
                XCTAssertEqual(s.count, 0)
                let ct1 = WSetCounter()
                let ct2 = WSetCounter()
                s.insert(ct1)
                s.insert(ct2)
                XCTAssertEqual(s.count, 2)
                XCTAssertEqual(WSetCounter.instance, 2)
            }
            XCTAssertEqual(s.count, 2)
            XCTAssertEqual(WSetCounter.instance, 0)
        }
        test {
            let ct1: WSetCounter = .init()
            let ct2: WSetCounter = .init()
            
            let s1: WSet<WSetCounter> = [ct1, ct1, ct2, ct2]
            
            XCTAssertEqual(s1.count, 2)
            XCTAssertEqual(WSetCounter.instance, 2)
        }
    }
    
    func testRemove() {
        test {
            let ct1: WSetCounter = .init()
            let ct2: WSetCounter = .init()
            let ct3: WSetCounter = .init()

            var s1: WSet<WSetCounter> = [ct1, ct2, ct3]
            s1.removeAll()
            XCTAssertEqual(s1.count, 0)
            
            var s2: WSet<WSetCounter> = [ct1, ct2, ct3]
            s2.removeAll(keepingCapacity: true)
            XCTAssertEqual(s2.count, 0)

            var s3: WSet<WSetCounter> = [ct1, ct2, ct3]
            s3.remove(ct2)
            XCTAssertEqual(s3.contains(ct2), false)
        }
    }
    
    func testOther() {
        test { // hash & equal
            let ct1: WSetCounter = .init()
            let ct2: WSetCounter = .init()

            let s1: WSet<WSetCounter> = [ct1]
            let s2: WSet<WSetCounter> = [ct1]
            let s3: WSet<WSetCounter> = [ct2]

            XCTAssertEqual(s1.hashValue, s2.hashValue)
            XCTAssertNotEqual(s1.hashValue, s3.hashValue)
            
            XCTAssertEqual(s1, s2)
            XCTAssertNotEqual(s1, s3)
        }
        test { // empty
            let ct1: WSetCounter = .init()
            
            let s1: WSet<WSetCounter> = [ct1]
            let s2: WSet<WSetCounter> = []
            
            XCTAssertEqual(s2.isEmpty, true)
            XCTAssertEqual(s1.isEmpty, false)
        }
        test { // contains
            let ct1: WSetCounter = .init()
            let ct2: WSetCounter = .init()
            let ct3: WSetCounter = .init()

            let s1: WSet<WSetCounter> = [ct1, ct2]
            let s2: WSet<WSetCounter> = []
            
            XCTAssertEqual(s1.contains(ct2), true)
            XCTAssertEqual(s1.contains(ct3), false)
            XCTAssertEqual(s2.contains(ct1), false)
        }
        
        test { // foreach
            let ct1: WSetCounter = .init()
            let ct2: WSetCounter = .init()
            let ct3: WSetCounter = .init()
            
            let s1: WSet<WSetCounter> = [ct1, ct2, ct3]
            var os: [WSetCounter] = []
            s1.forEach {
                os.append($0)
            }
            XCTAssertEqual(os.contains(ct1), true)
            XCTAssertEqual(os.contains(ct2), true)
            XCTAssertEqual(os.contains(ct3), true)
        }
    }
    
}
