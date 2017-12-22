//
//  BrowserAlbumListController.swift
//  Ubiquity
//
//  Created by sagesse on 21/12/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class BrowserAlbumListController: SourceCollectionViewController, UICollectionViewDelegateFlowLayout {
    
    required init(container: Container, source: Source, factory: Factory, parameter: Any?) {
        super.init(container: container, source: source, factory: factory, parameter: parameter)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /// Specify the caching item size.
    override var cachingItemSize: CGSize {
        return BrowserAlbumLayout.thumbnailItemSize
    }

    override func loadView() {
        super.loadView()
        
        // Registered separation line.
        collectionView?.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "LINE")
    }
    
    // MARK: Collection View Configure
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return source.numberOfCollectionLists
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // if the section has folding item, only show folded collections
        if let folding = foldingLists?[section] {
            return folding.numberOfFoldedCollections
        }
        
        // in other albums, display all collection
        return source.numberOfCollections(inCollectionList: section)
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let target = foldingLists?[indexPath.section].map({ Source(collectionList: $0.collectionList, filter: source.filter) }) {
            // display album for collection list
            _show(with: target, at: indexPath)
            return
        }
        
        if let target = source.collection(at: indexPath.row, inCollectionList: indexPath.section).map({ Source(collection: $0) }) {
            // display album for collection
            _show(with: target, at: indexPath)
            return
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "LINE", for: indexPath)
        view.backgroundColor = .lightGray
        return view
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        // The first section does not display the line 
        guard section != 0 else {
            return .zero
        }
        
        return .init(width: 0, height: 1 / UIScreen.main.scale)
    }
    
    override func reuseIdentifier(_ source: Source, at indexPath: IndexPath) -> String {
        return "ASSET"
    }
    
    override func data(_ source: Source, at indexPath: IndexPath) -> Any? {
        return _collection(at: indexPath)
    }
    
    override func cachingItems(at indexPaths: [IndexPath]) -> [Asset] {
        return indexPaths.flatMap {
            return _collection(at: $0).flatMap { collection in
                return (max(collection.ub_count - 3, 0) ..< collection.ub_count).map {
                    return collection.ub_asset(at: $0)
                }
            } ?? []
        }
    }
    
    override func library(_ library: Library, change: Change, fetch source: Source) -> SourceChangeDetails? {
        return source.changeDetails(forCollections: change)
    }
    
    override func library(_ library: Library, change: Change, source: Source, apply changeDetails: SourceChangeDetails) {
        // Calculation of the collection after folding.
        self.foldingLists = _folding(with: source)
        
        // If folded collection list has any change, reload all
        self.foldingLists?.forEach { (section, folding) in
            
            let filter = { (indexPath: IndexPath) -> Bool in
                if indexPath.section == section {
                    if changeDetails.reloadSections == nil {
                        changeDetails.reloadSections = []
                    }
                    changeDetails.reloadSections?.insert(section)
                    return false
                }
                return true
            }
            
            changeDetails.reloadItems = changeDetails.reloadItems?.filter(filter)
            changeDetails.insertItems = changeDetails.insertItems?.filter(filter)
            changeDetails.removeItems = changeDetails.removeItems?.filter(filter)
        }

        
        // Continue to apply.
        super.library(library, change: change, source: source, apply: changeDetails)
    }

    override func controller(_ container: Container, didLoad source: Source, error: Error?) {
        logger.trace?.write(error ?? "")
        
        // The error message has been processed by the ExceptionHandling
        guard error == nil else {
            return
        }
        
        // check albums count
        guard source.numberOfCollections != 0 else {
            ub_execption(with: container, source: source, error: Exception.notData, animated: true)
            return
        }
        
        super.controller(container, didLoad: source, error: error)
    }
    
    override func controller(_ container: Container, willPrepare source: Source) {
        // Calculation of the collection after folding.
        self.foldingLists = _folding(with: source)
        
        // Continue to prepare.
        super.controller(container, willPrepare: source)
    }
    
    /// show alubms with source
    private func _show(with source: Source, at indexPath: IndexPath) {
        // try generate album controller for factory
        let controller = container.instantiateViewController(with: .albums, source: source, parameter: indexPath)
        show(controller, sender: indexPath)
    }
    
    private func _collection(at indexPath: IndexPath) -> Collection? {
        // If there is a collection in the fold, use it first
        if let folded = foldingLists?[indexPath.section]?.collection(at: indexPath.item) {
            return folded
        }
        
        return source.collection(at: indexPath.row, inCollectionList: indexPath.section)
    }
    
    /// generate folding lists
    private func _folding(with source: Source) -> [Int: SourceFolding] {
        var folding = [Int: SourceFolding]()

        // do not fold when there is only one list
        guard source.numberOfCollectionLists > 1 else {
            return folding
        }

        // foreach all collection list
        for section in 0 ..< source.numberOfCollectionLists {
            // if collectoin list is empty, ignore
            guard let collectionList = source.collectionList(at: section) else {
                continue
            }

            // if collection list is regular, ignore
            guard collectionList.ub_collectionType != .regular else {
                continue
            }

            // generate a list folding
            folding[section] = SourceFolding(collectionList: collectionList)
        }

        return folding
    }

    private(set) var foldingLists: [Int: SourceFolding]?
}
