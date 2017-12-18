//
//  WSet.swift
//  Ubiquity
//
//  Created by sagesse on 30/08/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import Foundation

/// Weak Set
public struct WSet<Element>: Hashable, ExpressibleByArrayLiteral {
    
    /// Creates a new, empty set with at least the specified number of elements'
    /// worth of buffer.
    ///
    /// Use this initializer to avoid repeated reallocations of a set's buffer
    /// if you know you'll be adding elements to the set after creation. The
    /// actual capacity of the created set will be the smallest power of 2 that
    /// is greater than or equal to `minimumCapacity`.
    ///
    /// - Parameter minimumCapacity: The minimum number of elements that the
    ///   newly created set should be able to store without reallocating its
    ///   buffer.
    public init(minimumCapacity: Int) {
        // forward
        _observers = Set(minimumCapacity: minimumCapacity)
    }
    
    /// Creates a set containing the elements of the given array literal.
    ///
    /// Do not call this initializer directly. It is used by the compiler when
    /// you use an array literal. Instead, create a new set using an array
    /// literal as its value by enclosing a comma-separated list of values in
    /// square brackets. You can use an array literal anywhere a set is expected
    /// by the type context.
    ///
    /// Here, a set of strings is created from an array literal holding only
    /// strings.
    ///
    ///     let ingredients: Set = ["cocoa beans", "sugar", "cocoa butter", "salt"]
    ///     if ingredients.isSuperset(of: ["sugar", "salt"]) {
    ///         print("Whatever it is, it's bound to be delicious!")
    ///     }
    ///     // Prints "Whatever it is, it's bound to be delicious!"
    ///
    /// - Parameter elements: A variadic list of elements of the new set.
    public init(arrayLiteral elements: Element...) {
        // forward
        _observers = []
        _observers = Set(elements.map({ _warp($0) }))
    }

    /// Creates an empty set.
    ///
    /// This is equivalent to initializing with an empty array literal. For
    /// example:
    ///
    ///     var emptySet = Set<Int>()
    ///     print(emptySet.isEmpty)
    ///     // Prints "true"
    ///
    ///     emptySet = []
    ///     print(emptySet.isEmpty)
    ///     // Prints "true"
    public init() {
        // forward
        _observers = []
    }
    
    /// Inserts the given element in the set if it is not already present.
    ///
    /// If an element equal to `newMember` is already contained in the set, this
    /// method has no effect. In the following example, a new element is
    /// inserted into `classDays`, a set of days of the week. When an existing
    /// element is inserted, the `classDays` set does not change.
    ///
    ///     enum DayOfTheWeek: Int {
    ///         case sunday, monday, tuesday, wednesday, thursday,
    ///             friday, saturday
    ///     }
    ///
    ///     var classDays: Set<DayOfTheWeek> = [.wednesday, .friday]
    ///     print(classDays.insert(.monday))
    ///     // Prints "(true, .monday)"
    ///     print(classDays)
    ///     // Prints "[.friday, .wednesday, .monday]"
    ///
    ///     print(classDays.insert(.friday))
    ///     // Prints "(false, .friday)"
    ///     print(classDays)
    ///     // Prints "[.friday, .wednesday, .monday]"
    ///
    /// - Parameter newMember: An element to insert into the set.
    /// - Returns: `(true, newMember)` if `newMember` was not contained in the
    ///   set. If an element equal to `newMember` was already contained in the
    ///   set, the method returns `(false, oldMember)`, where `oldMember` is the
    ///   element that was equal to `newMember`. In some cases, `oldMember` may
    ///   be distinguishable from `newMember` by identity comparison or some
    ///   other means.
    @discardableResult
    public mutating func insert(_ newMember: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        let result = _observers.insert(_warp(newMember))
        return (result.inserted, _unwarp(result.memberAfterInsert))
    }

    /// Removes the specified element from the set.
    ///
    /// This example removes the element `"sugar"` from a set of ingredients.
    ///
    ///     var ingredients: Set = ["cocoa beans", "sugar", "cocoa butter", "salt"]
    ///     let toRemove = "sugar"
    ///     if let removed = ingredients.remove(toRemove) {
    ///         print("The recipe is now \(removed)-free.")
    ///     }
    ///     // Prints "The recipe is now sugar-free."
    ///
    /// - Parameter member: The element to remove from the set.
    /// - Returns: The value of the `member` parameter if it was a member of the
    ///   set; otherwise, `nil`.
    @discardableResult
    public mutating func remove(_ member: Element) -> Element? {
        return _observers.remove(_warp(member)).map {
            return _unwarp($0)
        }
    }


    /// Removes all members from the set.
    ///
    /// - Parameter keepingCapacity: If `true`, the set's buffer capacity is
    ///   preserved; if `false`, the underlying buffer is released. The
    ///   default is `false`.
    public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
        return _observers.removeAll(keepingCapacity: keepCapacity)
    }
    
    /// Returns a Boolean value that indicates whether the given element exists
    /// in the set.
    ///
    /// This example uses the `contains(_:)` method to test whether an integer is
    /// a member of a set of prime numbers.
    ///
    ///     let primes: Set = [2, 3, 5, 7]
    ///     let x = 5
    ///     if primes.contains(x) {
    ///         print("\(x) is prime!")
    ///     } else {
    ///         print("\(x). Not prime.")
    ///     }
    ///     // Prints "5 is prime!"
    ///
    /// - Parameter member: An element to look for in the set.
    /// - Returns: `true` if `member` exists in the set; otherwise, `false`.
    public func contains(_ member: Element) -> Bool {
        return _observers.contains(_warp(member))
    }

    /// The number of elements in the set.
    ///
    /// - Complexity: O(1).
    public var count: Int {
        return _observers.count
    }
    
    /// A Boolean value that indicates whether the set is empty.
    public var isEmpty: Bool {
        return _observers.isEmpty
    }

    /// The hash value.
    ///
    /// Hash values are not guaranteed to be equal across different executions of
    /// your program. Do not save hash values to use during a future execution.
    public var hashValue: Int {
        return _observers.hashValue
    }
    
    /// Returns a Boolean value indicating whether two sets have equal elements.
    ///
    /// - Parameters:
    ///   - lhs: A set.
    ///   - rhs: Another set.
    /// - Returns: `true` if the `lhs` and `rhs` have the same elements; otherwise,
    ///   `false`.
    public static func ==(lhs: WSet<Element>, rhs: WSet<Element>) -> Bool {
        return lhs._observers == rhs._observers
    }
    
    /// Calls the given closure on each element in the sequence in the same order
    /// as a `for`-`in` loop.
    ///
    /// The two loops in the following example produce the same output:
    ///
    ///     let numberWords = ["one", "two", "three"]
    ///     for word in numberWords {
    ///         print(word)
    ///     }
    ///     // Prints "one"
    ///     // Prints "two"
    ///     // Prints "three"
    ///
    ///     numberWords.forEach { word in
    ///         print(word)
    ///     }
    ///     // Same as above
    ///
    /// Using the `forEach` method is distinct from a `for`-`in` loop in two
    /// important ways:
    ///
    /// 1. You cannot use a `break` or `continue` statement to exit the current
    ///    call of the `body` closure or skip subsequent calls.
    /// 2. Using the `return` statement in the `body` closure will exit only from
    ///    the current call to `body`, not from any outer scope, and won't skip
    ///    subsequent calls.
    ///
    /// - Parameter body: A closure that takes an element of the sequence as a
    ///   parameter.
    public func forEach(_ body: (Element) throws -> Swift.Void) rethrows {
        return try _observers.forEach {
            try body(_unwarp($0))
        }
    }
    
    private typealias __Element = UnsafeMutableRawPointer
    
    private func _warp(_ element: Element) -> __Element {
        return Unmanaged<AnyObject>.passUnretained(element as AnyObject).toOpaque()
    }
    
    private func _unwarp(_ element: __Element) -> Element {
        return Unmanaged<AnyObject>.fromOpaque(element).takeUnretainedValue() as! Element
    }
    
    private var _observers: Set<__Element>
}
