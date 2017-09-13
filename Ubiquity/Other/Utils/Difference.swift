//
//  Difference.swift
//  Ubiquity
//
//  Created by sagesse on 04/09/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import Foundation

/// Difference result
public enum DifferenceResult: CustomStringConvertible, Equatable {
    
    /// A moved item
    case move(from: Int, to: Int)
    
    /// A updated item
    case update(from: Int, to: Int)
    
    /// A inseted item
    case insert(from: Int, to: Int)
    
    /// A removed item
    case remove(from: Int, to: Int)
    
    /// The number of item from there
    public var from: Int {
        switch self {
        case .move(let from, _): return from
        case .insert(let from, _): return from
        case .update(let from, _): return from
        case .remove(let from, _): return from
        }
    }
    
    /// The number of item will goto
    public var to: Int {
        switch self {
        case .move(_, let to): return to
        case .insert(_, let to): return to
        case .update(_, let to): return to
        case .remove(_, let to): return to
        }
    }
    
    /// Display
    public var description: String {
        
        func c(_ value: Int) -> String {
            guard value >= 0 else {
                return "N"
            }
            return "\(value)"
        }
        
        switch self {
        case .move(let from, let to): return "M\(c(from))/\(c(to))"
        case .insert(let from, let to): return "A\(c(from))/\(c(to))"
        case .update(let from, let to): return "R\(c(from))/\(c(to))"
        case .remove(let from, let to): return "D\(c(from))/\(c(to))"
        }
    }
    
    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func ==(lhs: DifferenceResult, rhs: DifferenceResult) -> Bool {
        switch (lhs, rhs) {
        case (.remove(let f1, _), .remove(let f2, _)):
            return f1 == f2
            
        case (.move(let f1, let t1), .move(let f2, let t2)):
            return f1 == f2 && t1 == t2
            
        case (.insert(_, let t1), .insert(_, let t2)):
            return t1 == t2
            
        case (.update(let f1, let t1), .update(let f2, let t2)):
            return f1 == f2 && t1 == t2
            
        default:
            return false
        }
    }
}

/// Compare the differences between the two arrays
public func ub_diff<Element: Equatable>(_ src: Array<Element>, dest: Array<Element>) -> Array<DifferenceResult> {
    return ub_diff(src, dest: dest) {
        $0 == $1
    }
}

/// Compare the differences between the two arrays
public func ub_diff<Element>(_ src: Array<Element>, dest: Array<Element>, equal: (Element, Element) -> Bool) -> Array<DifferenceResult> {
    
    let slen = src.count
    let dlen = dest.count
    
    //
    //      a b c d
    //    0 0 0 0 0
    //  a 0 1 1 1 1
    //  d 0 1 1 1 2
    //
    // the diff result is a table
    var diffs = [[Int]](repeating: [Int](repeating: 0, count: dlen + 1), count: slen + 1)
    
    // LCS + dynamic programming
    for si in 1 ..< slen + 1 {
        for di in 1 ..< dlen + 1 {
            // comparative differences
            if equal(src[si - 1], dest[di - 1]) {
                // equal
                diffs[si][di] = diffs[si - 1][di - 1] + 1
            } else {
                // no equal
                diffs[si][di] = max(diffs[si - 1][di], diffs[si][di - 1])
            }
        }
    }
    
    var si = slen
    var di = dlen
    
    var rms: [(from: Int, to: Int)] = []
    var adds: [(from: Int, to: Int)] = []
    
    // create the optimal path
    repeat {
        guard si != 0 else {
            // the remaining is add
            while di > 0 {
                adds.append((from: si - 1, to: di - 1))
                di -= 1
            }
            break
        }
        guard di != 0 else {
            // the remaining is remove
            while si > 0 {
                rms.append((from: si - 1, to: di - 1))
                si -= 1
            }
            break
        }
        guard !equal(src[si - 1], dest[di - 1]) else {
            // no change, ignore
            si -= 1
            di -= 1
            continue
        }
        // check the weight
        if diffs[si - 1][di] > diffs[si][di - 1] {
            // is remove
            rms.append((from: si - 1, to: di - 1))
            si -= 1
        } else {
            // is add
            adds.append((from: si - 1, to: di - 1))
            di -= 1
        }
    } while si > 0 || di > 0
    
    var results: [DifferenceResult] = []
    
    results.reserveCapacity(rms.count + adds.count)
    
    // move(f,t): f = remove(f), t = insert(t), new move(f,t): f = remove(f), t = insert(f)
    // update(f,t): f = remove(f), t = insert(t), new update(f,t): f = remove(f), t = insert(f)
    
    // automatic merge delete and update items
    results.append(contentsOf: rms.map({ item in
        let from = item.from
        let delElement = src[from]
        // can't merge to move item?
        if let addIndex = adds.index(where: { equal(dest[$0.to], delElement) }) {
            let addItem = adds.remove(at: addIndex)
            return .move(from: from, to: addItem.to)
        }
        // can't merge to update item?
        if let addIndex = adds.index(where: { $0.to == from }) {
            let addItem = adds[addIndex]
            //let addElement = dest[addItem.to]
            
            // if delete and add at the same time, merged to update
            adds.remove(at: addIndex)
            return .update(from: from, to: addItem.to)
        }
        return .remove(from: item.from, to: -1)
    }))
    // automatic merge insert items
    results.append(contentsOf: adds.map({ item in
        return .insert(from: -1, to: item.to)
    }))
    
    // sort
    return results.sorted { $0.from < $1.from }
}

