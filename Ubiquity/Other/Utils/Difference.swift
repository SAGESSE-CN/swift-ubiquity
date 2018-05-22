//
//  Difference.swift
//  Ubiquity
//
//  Created by sagesse on 04/09/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import Foundation

/// A difference node.
private class Node {
    init(insert from: Int, to: Int, _ next: Node? = nil) {
        self.mode = 1
        self.from = from
        self.to = to
        self.next = next
    }
    init(equal from: Int, to: Int, _ next: Node? = nil) {
        self.mode = 0
        self.from = from
        self.to = to
        self.next = next

    }
    init(remove from: Int, to: Int, _ next: Node? = nil) {
        self.mode = -1
        self.from = from
        self.to = to
        self.next = next
    }
    
    var mode: Int
    var from: Int
    var to: Int
    var next: Node?
}

/// A difference.
public enum Difference: CustomStringConvertible, Equatable {
    
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
    public static func ==(lhs: Difference, rhs: Difference) -> Bool {
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


// MARK: -


/// Compare the differences between the two arrays.
public func diff<S>(_ src: S, dest: S) -> Array<Difference> where S: RandomAccessCollection, S.Index == Int, S.Element: Equatable {
    return diff(src, dest: dest) {
        $0 == $1
    }
}

/// Compare the differences between the two arrays.
public func diff<S>(_ src: S, dest: S, equal: (S.Element, S.Element) -> Bool) -> Array<Difference> where S: RandomAccessCollection, S.Index == Int {
    
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
    
    //    print("  ", terminator: "")
    //    dest.forEach {
    //        print($0, terminator: " ")
    //    }
    //    print()
    //    for si in 1 ..< slen + 1 {
    //        print(src[si - 1], terminator: " ")
    //        for di in 1 ..< dlen + 1 {
    //            // comparative differences
    //            print(diffs[si][di], terminator: " ")
    //        }
    //        print()
    //    }
    
    var si = slen
    var di = dlen
    var mp = false // match a remove & add group
    
    var head: Node?
    var results: [Difference] = []

    // create the optimal path
    repeat {
        guard si != 0 else {
            // the remaining is add
            while di > 0 {
                head = .init(insert: si - 1, to: di - 1, head)
                di -= 1
            }
            break
        }
        guard di != 0 else {
            // the remaining is remove
            while si > 0 {
                head = .init(remove: si - 1, to: di - 1, head)
                si -= 1
            }
            break
        }
        // check the weight
        let weight = (x: diffs[si - 1][di], y: diffs[si][di - 1])
        
        // the item is remove?
        guard !(weight.x > weight.y) else {
            head = .init(remove: si - 1, to: di - 1, head)
            si -= 1
            mp = false
            continue
        }
        
        // the item is add?
        guard !(weight.x < weight.y) else {
            head = .init(insert: si - 1, to: di - 1, head)
            di -= 1
            mp = false
            continue
        }
        
        // the is is equal?
        guard !equal(src[si - 1], dest[di - 1]) else {
            // no change, ignore
            head = .init(equal: si - 1, to: di - 1, head)
            si -= 1
            di -= 1
            mp = false
            continue
        }
        
        // the item is automatic match
        guard !(mp) else {
            // remove
            head = .init(remove: si - 1, to: di - 1, head)
            si -= 1
            mp = false
            continue
        }
        
        // add
        head = .init(insert: si - 1, to: di - 1, head)
        di -= 1
        mp = true
        
    } while si > 0 || di > 0

    // The order of processing is from head to tail.
    while let node = head {
        switch node.mode {
        case +1: // This is insert node.
            // Skip all the same nodes.
            var current = node
            while let same = current.next, same.mode == node.mode {
                current = same
            }

            // Move: Find any of the same remove node.

            // Reload: Next is remove node. e.g. I+R
            if let remove = current.next, remove.mode == -1 {
                results.append(.update(from: remove.from, to: node.to))
                current.next = remove.next
                head = node.next
                continue
            }
            
            // Insert: Other case.
            results.append(.insert(from: -1, to: node.to))

        case -1: // This is remove node.
            // Skip all the same nodes.
            var current = node
            while let same = current.next, same.mode == node.mode {
                current = same
            }

            // Move: Find any of the same insert node.
            
            // Reload: Next is insert node. e.g. R+I
            if let insert = current.next, insert.mode == +1 {
                results.append(.update(from: node.from, to: insert.to))
                current.next = insert.next
                head = node.next
                continue
            }

            // Remove: Other case.
            results.append(.remove(from: node.from, to: -1))

        default: // This is equal node.
            break
        }
        // Processing to next node.
        head = node.next
    }

    return results
}


