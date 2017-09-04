//
//  Change.swift
//  Ubiquity
//
//  Created by sagesse on 04/09/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import Foundation

/// A change info
@objc public protocol Change {
    
    /// Returns detailed change information for the specified collection.
    func ub_changeDetails(forCollection collection: Collection) -> ChangeDetails?
    
    /// Returns detailed change information for the specified colleciotn list.
    func ub_changeDetails(forCollectionList collectionList: CollectionList) -> ChangeDetails?
}

/// A change details info
@objc public class ChangeDetails: NSObject {
    
    /// Generate a change details info
    public init(before: Any, after: Any?) {
        self.before = before
        self.after = after
    }
    
    /// the object in the state before this change
    var before: Any 
    /// the object in the state after this change
    var after: Any? 
    
    /// A Boolean value that indicates whether objects have been rearranged in the fetch result.
    var hasMoves: Bool = false
    /// A Boolean value that indicates whether objects have been any change in result.
    var hasAssetChanges: Bool = false
    /// A Boolean value that indicates whether changes to the fetch result can be described incrementally.
    var hasIncrementalChanges: Bool = false
    
    /// The indexes of objects in the fetch result whose content or metadata have been updated.
    var changedIndexes: IndexSet? 
    /// The indexes from which objects have been removed from the fetch result.
    var removedIndexes: IndexSet?
    /// The indexes where new objects have been inserted in the fetch result.
    var insertedIndexes: IndexSet?
    
    /// The indexes wherer new objects have been move in the fetch result.
    var movedIndexes: [(Int, Int)]?
}


/// A protocol you can implement to be notified of changes that occur in the Photos library.
public protocol ChangeObserver: class {
    
    /// Tells your observer that a set of changes has occurred in the Photos library.
    func library(_ library: Library, didChange change: Change)
}

