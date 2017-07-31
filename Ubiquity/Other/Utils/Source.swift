//
//  Source.swift
//  Ubiquity
//
//  Created by SAGESSE on 5/24/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class Source {
    
    init(collection: Collection) {
        _adapter = CollectionAdapter(collection: collection)
        _collectionType = collection.collectionType
        _collectionSubtype = collection.collectionSubtype
    }
    
    init(collectionType: CollectionType) {
        _collectionType = collectionType
        _collectionSubtype = .smartAlbumUserLibrary
    }
    
    private var _adapter: SourceAdapter?
    private var _collectionType: CollectionType
    private var _collectionSubtype: CollectionSubtype
    
    var title: String? {
        return _adapter?.title
    }
    
    var collectionType: CollectionType {
        return _collectionType
    }
    
    var collectionSubtype: CollectionSubtype {
        return _collectionSubtype
    }
    
    
    var count: Int {
        // adapter must be set
        guard let adapter = _adapter else {
            return 0
        }
        
        // sum
        return (0 ..< adapter.numberOfSections).reduce(0) {
            $0 + adapter.numberOfItems(inSection: $1)
        }
    }
    
    func count(with type: AssetMediaType) -> Int {
        // adapter must be set
        guard let adapter = _adapter else {
            return 0
        }
        
        // sum
        return (0 ..< adapter.numberOfSections).reduce(0) {
            $0 + adapter.collection(at: $1).count(with: type)
        }
    }
    
    func load(with container: Container) {
        // data is loaded?
        guard _adapter == nil else {
            return
        }
        
        // setup
        _adapter = CollectionListAdapter(collectionList: container.request(forCollection: _collectionType))
    }
    
    
    func changeDetails(for change: Change) -> SourceChangeDetails? {
        
        return nil
//        // fetch data source any change
//        let changes = _collections.enumerated().flatMap { offset, collection -> (Int, ChangeDetails)? in
//            // the collection has any change?
//            guard let details = change.changeDetails(for: collection) else {
//                return nil
//            }
//            // the collection is change at offset
//            return (offset, details)
//        }
//        
//        // if changes is empty, data source not any change
//        guard !changes.isEmpty else {
//            return nil // ignore
//        }
//        
//        // generate new chagne details for collectios
//        let newSource = Source(collections: _collections)
//        let newDetails = SourceChangeDetails(before: self, after: newSource)
//        
//        // update change details
//        newDetails.moveItems = []
//        newDetails.reloadItems = []
//        newDetails.insertItems = []
//        newDetails.removeItems = []
//        newDetails.reloadSections = IndexSet()
//        
//        // apply changes
//        changes.reversed().forEach { section, details in
//            
//            // keep the new fetch result for future use.
//            guard let collection = details.after as? Collection else {
//                // the collection is deleted
//                newDetails.wasDeleted = true
//                newSource._collections.remove(at: section)
//                return
//            }
//            newSource._collections[section] = collection
//            
//            // has asset changes?
//            guard details.hasAssetChanges else {
//                return
//            }
//            newDetails.hasAssetChanges = details.hasAssetChanges
//
//            // if there are incremental diffs, animate them in the table view.
//            guard details.hasIncrementalChanges else {
//                // reload the table view if incremental diffs are not available.
//                newDetails.reloadSections?.update(with: section)
//                return
//            }
//            
//            newDetails.hasIncrementalChanges = true
//            newDetails.removeItems?.append(contentsOf: details.removedIndexes?.map({ .init(item: $0, section:0) }) ?? [])
//            newDetails.insertItems?.append(contentsOf: details.insertedIndexes?.map({ .init(item: $0, section:0) }) ?? [])
//            newDetails.reloadItems?.append(contentsOf: details.changedIndexes?.map({ .init(item: $0, section:0) }) ?? [])
//            
//            details.enumerateMoves { from, to in
//                newDetails.hasMoves = true
//                newDetails.moveItems?.append((.init(row: from, section: section), .init(row: to, section: section)))
//            }
//        }
//        
//        // clean invaild index paths
//        if newDetails.reloadSections?.isEmpty ?? true {
//            newDetails.reloadSections = nil
//        }
//        if newDetails.removeItems?.isEmpty ?? false {
//            newDetails.removeItems = nil
//        }
//        if newDetails.insertItems?.isEmpty ?? false {
//            newDetails.insertItems = nil
//        }
//        if newDetails.reloadItems?.isEmpty ?? false {
//            newDetails.reloadItems = nil
//        }
//        if newDetails.moveItems?.isEmpty ?? true {
//            newDetails.moveItems = nil
//            newDetails.hasMoves = false
//        }
//        
//        return newDetails
    }
    
    
    var numberOfSections: Int {
        return _adapter?.numberOfSections ?? 0
    }
    
    func numberOfItems(inSection section: Int) -> Int {
        return _adapter?.numberOfItems(inSection: section) ?? 0
    }
    
    func asset(at indexPath: IndexPath) -> Asset? {
        return _adapter?.asset(at: indexPath)
    }
    
    func collection(at section: Int) -> Collection? {
        return _adapter?.collection(at: section)
    }
    
    
//    private var _collections: Array<Collection> = []
}

internal class SourceOptions: RequestOptions {
    
    init(isSynchronous: Bool = false, progressHandler: ((Double, Response) -> ())? = nil) {
        self.isSynchronous = isSynchronous
        self.progressHandler = progressHandler
    }
    
    /// if necessary will download the image from reomte
    var isNetworkAccessAllowed: Bool = true
    
    // return only a single result, blocking until available (or failure). Defaults to NO
    var isSynchronous: Bool = false
    
    /// provide caller a way to be told how much progress has been made prior to delivering the data when it comes from remote.
    var progressHandler: ((Double, Response) -> ())?
}

internal class SourceChangeDetails {
    
    /// Create an change detail
    init(before: Source, after: Source?) {
        self.before = before
        self.after = after
    }
    
    /// the object in the state before this change
    var before: Source
    /// the object in the state after this change
    var after: Source?
    
    /// A Boolean value that indicates whether objects have been rearranged in the fetch result.
    var hasMoves: Bool = false
    // YES if the object was deleted
    var wasDeleted: Bool = false
    /// A Boolean value that indicates whether objects have been any change in result.
    var hasAssetChanges: Bool = false
    /// A Boolean value that indicates whether changes to the fetch result can be described incrementally.
    var hasIncrementalChanges: Bool = false
    
    /// The indexes from which objects have been removed from the fetch result.
    var removeItems: [IndexPath]?
    /// The indexes of objects in the fetch result whose content or metadata have been updated.
    var reloadItems: [IndexPath]?
    /// The indexes where new objects have been inserted in the fetch result.
    var insertItems: [IndexPath]?
    
    var reloadSections: IndexSet?
    
    /// The indexs where new object have move
    var moveItems: [(IndexPath, IndexPath)]?
    
    /// Runs the specified block for each case where an object has moved from one index to another in the fetch result.
    func enumerateMoves(_ handler: @escaping (IndexPath, IndexPath) -> Swift.Void) {
        moveItems?.forEach(handler)
    }
    
}

//class Adapter {
//    
//    var numberOfSections: Int {
//        return 0
//    }
//    
//    func numberOfItems(inSection section: Int) -> Int {
//        return 0
//    }
//    
//    func object(at section: Int) -> Any? {
//        return nil
//    }
//    
//    func object(at indexPath: IndexPath) -> Any? {
//        return nil
//    }
//}

private protocol SourceAdapter {
    
    var title: String? { get }
    
    var numberOfSections: Int { get }
    
    func numberOfItems(inSection section: Int) -> Int
    
    func asset(at indexPath: IndexPath) -> Asset
    
    func collection(at section: Int) -> Collection
}

private class CollectionAdapter: SourceAdapter {
    
    init(collection: Collection) {
        _collection = collection
    }
    
    var title: String? {
        return _collection.title
    }
    
    var numberOfSections: Int {
        return 1
    }
    func numberOfItems(inSection section: Int) -> Int {
        return _collection.count
    }
    
    func collection(at section: Int) -> Collection {
        return _collection
    }
    
    func asset(at indexPath: IndexPath) -> Asset {
        return _collection[indexPath.item]
    }
    
    func changeDetails(for change: Change) -> SourceChangeDetails? {
        
        return nil
//        // fetch data source any change
//        let changes = _collections.enumerated().flatMap { offset, collection -> (Int, ChangeDetails)? in
//            // the collection has any change?
//            guard let details = change.changeDetails(for: collection) else {
//                return nil
//            }
//            // the collection is change at offset
//            return (offset, details)
//        }
//        
//        // if changes is empty, data source not any change
//        guard !changes.isEmpty else {
//            return nil // ignore
//        }
//        
//        // generate new chagne details for collectios
//        let newSource = Source(collections: _collections)
//        let newDetails = SourceChangeDetails(before: self, after: newSource)
//        
//        // update change details
//        newDetails.moveItems = []
//        newDetails.reloadItems = []
//        newDetails.insertItems = []
//        newDetails.removeItems = []
//        newDetails.reloadSections = IndexSet()
//        
//        // apply changes
//        changes.reversed().forEach { section, details in
//            
//            // keep the new fetch result for future use.
//            guard let collection = details.after as? Collection else {
//                // the collection is deleted
//                newDetails.wasDeleted = true
//                newSource._collections.remove(at: section)
//                return
//            }
//            newSource._collections[section] = collection
//            
//            // has asset changes?
//            guard details.hasAssetChanges else {
//                return
//            }
//            newDetails.hasAssetChanges = details.hasAssetChanges
//
//            // if there are incremental diffs, animate them in the table view.
//            guard details.hasIncrementalChanges else {
//                // reload the table view if incremental diffs are not available.
//                newDetails.reloadSections?.update(with: section)
//                return
//            }
//            
//            newDetails.hasIncrementalChanges = true
//            newDetails.removeItems?.append(contentsOf: details.removedIndexes?.map({ .init(item: $0, section:0) }) ?? [])
//            newDetails.insertItems?.append(contentsOf: details.insertedIndexes?.map({ .init(item: $0, section:0) }) ?? [])
//            newDetails.reloadItems?.append(contentsOf: details.changedIndexes?.map({ .init(item: $0, section:0) }) ?? [])
//            
//            details.enumerateMoves { from, to in
//                newDetails.hasMoves = true
//                newDetails.moveItems?.append((.init(row: from, section: section), .init(row: to, section: section)))
//            }
//        }
//        
//        // clean invaild index paths
//        if newDetails.reloadSections?.isEmpty ?? true {
//            newDetails.reloadSections = nil
//        }
//        if newDetails.removeItems?.isEmpty ?? false {
//            newDetails.removeItems = nil
//        }
//        if newDetails.insertItems?.isEmpty ?? false {
//            newDetails.insertItems = nil
//        }
//        if newDetails.reloadItems?.isEmpty ?? false {
//            newDetails.reloadItems = nil
//        }
//        if newDetails.moveItems?.isEmpty ?? true {
//            newDetails.moveItems = nil
//            newDetails.hasMoves = false
//        }
//        
//        return newDetails
    }
    
    
    private var _collection: Collection
}

private class CollectionListAdapter: SourceAdapter {
    
    init(collectionList: CollectionList) {
        _collectionList = collectionList
    }
    
    var title: String? {
        return nil
    }
    
    var numberOfSections: Int {
        return _collectionList.count
    }
    func numberOfItems(inSection section: Int) -> Int {
        return _collectionList[section].count
    }
    
    func collection(at section: Int) -> Collection {
        return _collectionList[section]
    }
    
    func asset(at indexPath: IndexPath) -> Asset {
        return _collectionList[indexPath.section][indexPath.item]
    }
    
    
    private var _collectionList: CollectionList
}
