//
//  Change.swift
//  Ubiquity
//
//  Created by sagesse on 04/09/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import Foundation

/// A change info
public protocol Change {
    
    /// Returns detailed change information for the specified collection.
    func ub_changeDetails(_ change: Change, collection: Collection) -> ChangeDetails?
    /// Returns detailed change information for the specified colleciotn list.
    func ub_changeDetails(_ change: Change, collectionList: CollectionList) -> ChangeDetails?
}

/// A change details info
public class ChangeDetails: NSObject {
    
    /// Generate a change details info
    public init(before: Any, after: Any?) {
        self.before = before
        self.after = after
    }
    
    /// the object in the state before this change
    public var before: Any 
    /// the object in the state after this change
    public var after: Any? 
    
    /// A Boolean value that indicates whether objects have been rearranged in the fetch result.
    public var hasMoves: Bool = false
    /// A Boolean value that indicates whether objects have been any change in result.
    public var hasItemChanges: Bool = false
    /// A Boolean value that indicates whether changes to the fetch result can be described incrementally.
    public var hasIncrementalChanges: Bool = false
    
    /// The indexes of objects in the fetch result whose content or metadata have been updated.
    public var changedIndexes: IndexSet? 
    /// The indexes from which objects have been removed from the fetch result.
    public var removedIndexes: IndexSet?
    /// The indexes where new objects have been inserted in the fetch result.
    public var insertedIndexes: IndexSet?
    
    /// The indexes wherer new objects have been move in the fetch result.
    public var movedIndexes: [(Int, Int)]?
    
    /// Display debug info
    public override var description: String {
        // fetch all change
        let tmp = [
            insertedIndexes?.map { index -> Difference in .insert(from: -1, to: index) },
            removedIndexes?.map { index -> Difference in .remove(from: index, to: -1) },
            changedIndexes?.map { index -> Difference in .update(from: index, to: index) },
            movedIndexes?.map { from, to -> Difference in .update(from: from, to: to) }
        ]
        
        // map
        let diffs = tmp.compactMap { $0 }.compactMap { $0 }
        
        return "\(super.description), diffs: \(diffs)"
    }
}

/// A protocol you can implement to be notified of changes that occur in the Photos library.
public protocol ChangeObserver: class {
    
    /// Tells your observer that a set of changes has occurred in the Photos library.
    func library(_ library: Library, didChange change: Change)
}


