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
        // init data
        _adapter = CollectionAdapter(collection: collection)
        _collectionType = collection.collectionType
        _collectionSubtype = collection.collectionSubtype
        
        // config
        title = collection.title
    }
    
    init(collectionType: CollectionType) {
        // init data
        _collectionType = collectionType
        _collectionSubtype = .smartAlbumUserLibrary
    }
    
    var title: String?
    
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
        // adapter must be set
        guard let adapter = _adapter else {
            return nil
        }
        
        // check sections change
        guard let details = adapter.changeDetails(for: change) else {
            return nil
        }
        
        // check items change
        let changes = (0 ..< adapter.numberOfSections).flatMap { section -> (Int, ChangeDetails)? in
            // the adapter is `CollectionAdapter`
            guard !(details.before is Collection) else {
                return (section, details)
            }
            
            // the section is deleted
            guard !(details.removedIndexes?.contains(section) ?? false) else {
                return nil
            }
            
            // the collection has any change?
            guard let details = change.changeDetails(for: adapter.collection(at: section)) else {
                return nil
            }
            
            // the collection is change at offset
            return (section, details)
        }
        
        // generate new chagne details for collectios
        let newDetails = SourceChangeDetails(before: self, after: {
            
            let source = Source(collectionType: collectionType)
            
            // config title
            source.title = title
            
            // only singe collection
            if let collection = details.after as? Collection {
                return Source(collection: collection)
            }
            // has more collections
            if let collectionList = details.after as? CollectionList {
                source._adapter = CollectionListAdapter(collectionList: collectionList)
            }
            
            return source
        }())
        
        // has more collections
        if details.before is CollectionList {
            // update section changes
            newDetails.insertSections = details.insertedIndexes
            newDetails.deleteSections = details.removedIndexes
            
            // has insert or delete? 
            newDetails.hasAssetChanges = !(newDetails.insertSections?.isEmpty ?? true && newDetails.deleteSections?.isEmpty ?? true)
        }
        
        // was deleted?
        if details.after == nil {
            newDetails.wasDeleted = true
        }
        
        // apply changes
        changes.reversed().forEach { section, details in
            
            // keep the new fetch result for future use.
            guard details.after != nil else {
                // the section is deleted
                newDetails.deleteSections?.update(with: section)
                return
            }
            
            // has asset changes?
            guard details.hasAssetChanges else {
                return
            }
            newDetails.hasAssetChanges = true

            // if there are incremental diffs, animate them in the table view.
            guard details.hasIncrementalChanges else {
                // reload the table view if incremental diffs are not available.
                newDetails.reloadSections?.update(with: section)
                return
            }
            newDetails.hasIncrementalChanges = true
            
            // merge items changes
            newDetails.removeItems?.append(contentsOf: details.removedIndexes?.map({ .init(item: $0, section: section) }) ?? [])
            newDetails.insertItems?.append(contentsOf: details.insertedIndexes?.map({ .init(item: $0, section: section) }) ?? [])
            newDetails.reloadItems?.append(contentsOf: details.changedIndexes?.map({ .init(item: $0, section: section) }) ?? [])
            
            details.enumerateMoves { from, to in
                newDetails.hasMoves = true
                newDetails.moveItems?.append((.init(row: from, section: section), .init(row: to, section: section)))
            }
        }
        
        // clear invaild index path
        newDetails.clear()
        
        // success
        return newDetails
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
        // check boundary
        guard section < numberOfSections else {
            return nil
        }
        return _adapter?.collection(at: section)
    }
    
    private func _copy(with data: Any) -> Source? {
        return nil
    }
    
    private var _adapter: SourceAdapter?
    
    private var _collectionType: CollectionType
    private var _collectionSubtype: CollectionSubtype
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
    var removeItems: [IndexPath]? = []
    /// The indexes of objects in the fetch result whose content or metadata have been updated.
    var reloadItems: [IndexPath]? = []
    /// The indexes where new objects have been inserted in the fetch result.
    var insertItems: [IndexPath]? = []
    
    var insertSections: IndexSet? = IndexSet()
    var deleteSections: IndexSet? = IndexSet()
    var reloadSections: IndexSet? = IndexSet()
    
    /// The indexs where new object have move
    var moveItems: [(IndexPath, IndexPath)]?
    
    /// Runs the specified block for each case where an object has moved from one index to another in the fetch result.
    func enumerateMoves(_ handler: @escaping (IndexPath, IndexPath) -> Swift.Void) {
        moveItems?.forEach(handler)
    }
    
    func clear() {
        if insertSections?.isEmpty ?? true {
            insertSections = nil
        }
        if deleteSections?.isEmpty ?? true {
            deleteSections = nil
        }
        if reloadSections?.isEmpty ?? true {
            reloadSections = nil
        }
        if removeItems?.isEmpty ?? false {
            removeItems = nil
        }
        if insertItems?.isEmpty ?? false {
            insertItems = nil
        }
        if reloadItems?.isEmpty ?? false {
            reloadItems = nil
        }
        if moveItems?.isEmpty ?? true {
            moveItems = nil
            hasMoves = false
        }
    }
    
}

private protocol SourceAdapter {
    
    var title: String? { get }
    
    var numberOfSections: Int { get }
    
    func numberOfItems(inSection section: Int) -> Int
    
    func asset(at indexPath: IndexPath) -> Asset
    
    func collection(at section: Int) -> Collection
    
    func changeDetails(for change: Change) -> ChangeDetails?
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
    
    func changeDetails(for change: Change) -> ChangeDetails? {
        return change.changeDetails(for: _collection)
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
    
    func changeDetails(for change: Change) -> ChangeDetails? {
        return change.changeDetails(for: _collectionList)
    }
    
    private var _collectionList: CollectionList
}
