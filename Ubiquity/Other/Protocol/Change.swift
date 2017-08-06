//
//  Change.swift
//  Ubiquity
//
//  Created by sagesse on 06/07/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import Foundation

/// A change info
public protocol Change {
    
    /// Returns detailed change information for the specified collection.
    func changeDetails(for collection: Collection) -> ChangeDetails?
    
    /// Returns detailed change information for the specified colleciotn list.
    func changeDetails(for collectionList: CollectionList) -> ChangeDetails?
}

/// A change detail info
public protocol ChangeDetails {
    
    /// the object in the state before this change
    var before: Any { get }
    /// the object in the state after this change
    var after: Any? { get }
    
    /// A Boolean value that indicates whether objects have been rearranged in the fetch result.
    var hasMoves: Bool { get }
    /// A Boolean value that indicates whether objects have been any change in result.
    var hasAssetChanges: Bool { get }
    /// A Boolean value that indicates whether changes to the fetch result can be described incrementally.
    var hasIncrementalChanges: Bool { get }
    
    /// The indexes of objects in the fetch result whose content or metadata have been updated.
    var changedIndexes: IndexSet? { get }
    /// The indexes from which objects have been removed from the fetch result.
    var removedIndexes: IndexSet? { get }
    /// The indexes where new objects have been inserted in the fetch result.
    var insertedIndexes: IndexSet? { get }
    
    /// Runs the specified block for each case where an object has moved from one index to another in the fetch result.
    func enumerateMoves(_ handler: @escaping (Int, Int) -> Swift.Void)
}

/// A protocol you can implement to be notified of changes that occur in the Photos library.
public protocol ChangeObserver: class {
    
    /// Tells your observer that a set of changes has occurred in the Photos library.
    func library(_ library: Library, didChange change: Change)
}
