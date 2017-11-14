//
//  DifferenceTestCase.swift
//  Ubiquity
//
//  Created by sagesse on 13/09/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import XCTest
@testable import Ubiquity

class DifferenceTestCase: XCTestCase {
    
    func testRemove() {
        
        XCTAssertEqual(ub_diff([1,2,3], dest: [1,2]), [.remove(from: 2, to: -1)])
        XCTAssertEqual(ub_diff([1,2,3], dest: [1,3]), [.remove(from: 1, to: -1)])
        XCTAssertEqual(ub_diff([1,2,3], dest: [2,3]), [.remove(from: 0, to: -1)])
        
        XCTAssertEqual(ub_diff([1,2,3,4], dest: [3,4]), [.remove(from: 0, to: -1), .remove(from: 1, to: -1)])
        XCTAssertEqual(ub_diff([1,2,3,4], dest: [1,2]), [.remove(from: 2, to: -1), .remove(from: 3, to: -1)])
        XCTAssertEqual(ub_diff([1,2,3,4], dest: [1,4]), [.remove(from: 1, to: -1), .remove(from: 2, to: -1)])
        
        XCTAssertEqual(ub_diff([1,2,3,4], dest: [2,3]), [.remove(from: 0, to: -1), .remove(from: 3, to: -1)])
        XCTAssertEqual(ub_diff([1,2,3,4], dest: [1,4]), [.remove(from: 1, to: -1), .remove(from: 2, to: -1)])
        XCTAssertEqual(ub_diff([1,2,3,4], dest: [2,4]), [.remove(from: 0, to: -1), .remove(from: 2, to: -1)])
        XCTAssertEqual(ub_diff([1,2,3,4], dest: [1,3]), [.remove(from: 1, to: -1), .remove(from: 3, to: -1)])
        
        XCTAssertEqual(ub_diff([1,2,3], dest: []), [.remove(from: 0, to: -1), .remove(from: 1, to: -1), .remove(from: 2, to: -1)])
    }
    func testInsert() {
        
        XCTAssertEqual(ub_diff([1,2], dest: [0,1,2]), [.insert(from: -1, to: 0)])
        XCTAssertEqual(ub_diff([1,2], dest: [1,0,2]), [.insert(from: -1, to: 1)])
        XCTAssertEqual(ub_diff([1,2], dest: [1,2,0]), [.insert(from: -1, to: 2)])
        
        XCTAssertEqual(ub_diff([1,2], dest: [0,0,1,2]), [.insert(from: -1, to: 1), .insert(from: -1, to: 0)])
        XCTAssertEqual(ub_diff([1,2], dest: [1,0,0,2]), [.insert(from: -1, to: 2), .insert(from: -1, to: 1)])
        XCTAssertEqual(ub_diff([1,2], dest: [1,2,0,0]), [.insert(from: -1, to: 3), .insert(from: -1, to: 2)])
        XCTAssertEqual(ub_diff([1,2], dest: [0,1,2,0]), [.insert(from: -1, to: 3), .insert(from: -1, to: 0)])
        XCTAssertEqual(ub_diff([1,2], dest: [0,1,0,2]), [.insert(from: -1, to: 2), .insert(from: -1, to: 0)])
        
        XCTAssertEqual(ub_diff([1,2], dest: [0,1,0,2,0]), [.insert(from: -1, to: 4), .insert(from: -1, to: 2), .insert(from: -1, to: 0)])
        
        XCTAssertEqual(ub_diff([], dest: [1,2,3]), [.insert(from: -1, to: 2), .insert(from: -1, to: 1), .insert(from: -1, to: 0)])
    }
    func testUpdate() {
        
        XCTAssertEqual(ub_diff([1,2,3], dest: [1,2,4]), [.update(from: 2, to: 2)])
        XCTAssertEqual(ub_diff([1,2,3], dest: [1,4,3]), [.update(from: 1, to: 1)])
        XCTAssertEqual(ub_diff([1,2,3], dest: [4,2,3]), [.update(from: 0, to: 0)])
        
        XCTAssertEqual(ub_diff([1,2,3,4], dest: [1,2,0,0]), [.update(from: 2, to: 2), .update(from: 3, to: 3)])
        XCTAssertEqual(ub_diff([1,2,3,4], dest: [1,0,0,4]), [.update(from: 1, to: 1), .update(from: 2, to: 2)])
        XCTAssertEqual(ub_diff([1,2,3,4], dest: [0,0,3,4]), [.update(from: 0, to: 0), .update(from: 1, to: 1)])
        XCTAssertEqual(ub_diff([1,2,3,4], dest: [0,2,3,0]), [.update(from: 0, to: 0), .update(from: 3, to: 3)])
        XCTAssertEqual(ub_diff([1,2,3,4], dest: [1,0,3,0]), [.update(from: 1, to: 1), .update(from: 3, to: 3)])
        XCTAssertEqual(ub_diff([1,2,3,4], dest: [0,2,0,4]), [.update(from: 0, to: 0), .update(from: 2, to: 2)])
    }
    
    func testInsertAndRemove() {
    }
    
    func testRemoveAndUpdate() {
        XCTAssertEqual(ub_diff([0,1,2,3,4,5,6,7,8], dest: [0,1,0,4,0,6,7,8]), [.remove(from: 2, to: -1), .update(from: 3, to: 2), .update(from: 5, to: 4)])
    }
}
