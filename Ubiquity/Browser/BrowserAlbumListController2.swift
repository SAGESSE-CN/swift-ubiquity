//
//  BrowserAlbumListController2.swift
//  Ubiquity
//
//  Created by sagesse on 21/12/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class BrowserAlbumListController2: Source.CollectionViewController {
//
//    required init(container: Container, source: Source, sender: Any?) {
//        // setup init data
//        self.source = source
//        self.container = container
//
//        super.init(factory: container.factory(with: .albumsList))
//        super.title = source.title
//
//        // listen albums any change
//        self.container.addChangeObserver(self)
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    deinit {
//        // cancel listen change
//        self.container.removeChangeObserver(self)
//    }
//
//    /// The current using of the data source.
//    private(set) var source: Source {
//        willSet {
//            // only when in did not set the title will be updated
//            super.title = _title ?? newValue.title
//        }
//    }
//    /// The current using of the user container.
//    private(set) var container: Container
//
//    /// Whether the current library has been prepared.
//    private(set) var prepared: Bool = false
//    /// Whether the current library has been authorization.
//    private(set) var authorized: Bool = false
//
//
//    override var title: String? {
//        willSet {
//            _title = newValue
//        }
//    }
//
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        ub_initialize(with: self.container, source: self.source)
//    }
//
//    // MARK: UICollectionViewDataSource
//
//    override func numberOfSections(in collectionView: UICollectionView) -> Int {
//        return source.numberOfCollectionLists
//    }
//
//    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        // if the section has folding item, only show folded collections
//        if let folding = foldingLists?[section] {
//            return folding.numberOfFoldedCollections
//        }
//
//        // in other albums, display all collection
//        return source.numberOfCollections(inCollectionList: section)
//    }
//
//    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ASSET", for: indexPath)
//
//        // Configure the cell
//
//        return cell
//    }
//
//    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        cell.contentView.backgroundColor = .random
//    }
//
//    // MARK: Library change
//
//    /// Tells your observer that a set of changes has occurred in the Photos library.
//    func ub_library(_ library: Library, didChange change: Change) {
//        // the source is changed?
//        guard let changeDetails = source.changeDetails(forCollections: change) else {
//            return
//        }
//
//        // change notifications may be made on a background queue.
//        // re-dispatch to the main queue to update the UI.
//        DispatchQueue.main.async {
//            self.ub_library(library, didChange: change, changeDetails: changeDetails)
//        }
//    }
//    /// Tells your observer that a set of changes has occurred in the Photos library.
//    func ub_library(_ library: Library, didChange change: Change, changeDetails: SourceChangeDetails) {
//        logger.trace?.write(changeDetails)
////
////        // get table view and new data source
////        guard let tableView = tableView, let newSource = changeDetails.after else {
////            return
////        }
////        // keep the new fetch result for future use.
////        source = newSource
////        foldingLists = _folding(with: newSource)
////
////        logger.debug?.write(time(nil))
////
////        // check new albums count
////        guard newSource.numberOfCollections != 0 else {
////            // display error and update tableview
////            ub_execption(with: container, source: newSource, error: Exception.notData, animated: true)
////            tableView.reloadData()
////            return
////        }
////
////        // hidden error info if needed
////        ub_execption(with: container, source: newSource, error: nil, animated: true)
////
////        // if there are incremental diffs, animate them in the table view.
////        guard changeDetails.hasIncrementalChanges else {
////            // reload the table view if incremental diffs are not available.
////            tableView.reloadData()
////            return
////        }
////
////        // if folded collection list has any change, reload all
////        foldingLists?.forEach { (section, folding) in
////
////            let filter = { (indexPath: IndexPath) -> Bool in
////                if indexPath.section == section {
////                    if changeDetails.reloadSections == nil {
////                        changeDetails.reloadSections = []
////                    }
////                    changeDetails.reloadSections?.insert(section)
////                    return false
////                }
////                return true
////            }
////
////            changeDetails.reloadItems = changeDetails.reloadItems?.filter(filter)
////            changeDetails.insertItems = changeDetails.insertItems?.filter(filter)
////            changeDetails.removeItems = changeDetails.removeItems?.filter(filter)
////        }
////
////        UIView.animate(withDuration: 0.25) {
////            tableView.beginUpdates()
////
////            // For indexes to make sense, updates must be in this order:
////            // delete, insert, reload, move
////
////            changeDetails.deleteSections.map { tableView.deleteSections($0, with: .automatic) }
////            changeDetails.insertSections.map { tableView.insertSections($0, with: .automatic) }
////            changeDetails.reloadSections.map { tableView.reloadSections($0, with: .automatic) }
////
////            changeDetails.moveSections?.forEach { from, to in
////                tableView.moveSection(from, toSection: to)
////            }
////
////            changeDetails.removeItems.map { tableView.deleteRows(at: $0, with: .automatic) }
////            changeDetails.insertItems.map { tableView.insertRows(at: $0, with: .automatic) }
////            changeDetails.reloadItems.map { tableView.reloadRows(at: $0, with: .automatic) }
////
////            changeDetails.moveItems?.forEach { from, to in
////                tableView.moveRow(at: from, to: to)
////            }
////
////            tableView.endUpdates()
////        }
//    }
//
//
//    // MARK: Extended
//
//    /// Call before request authorization
//    open func ub_container(_ container: Container, willAuthorization source: Source) {
//        logger.trace?.write()
//    }
//
//    /// Call after completion of request authorization
//    open func ub_container(_ container: Container, didAuthorization source: Source, error: Error?) {
//        // the error message has been processed by the ExceptionHandling
//        guard error == nil else {
//            return
//        }
//        logger.trace?.write(error ?? "")
//    }
//
//    /// Call before request load
//    open func ub_container(_ container: Container, willLoad source: Source) {
//        logger.trace?.write()
//    }
//
//    /// Call after completion of load
//    open func ub_container(_ container: Container, didLoad source: Source, error: Error?) {
//        // the error message has been processed by the ExceptionHandling
//        guard error == nil else {
//            return
//        }
//        logger.trace?.write(error ?? "")
//
//        // check albums count
//        guard source.numberOfCollections != 0 else {
//            ub_execption(with: container, source: source, error: Exception.notData, animated: true)
//            return
//        }
//
//        // refresh UI
//        self.source = source
//        self.foldingLists = _folding(with: source)
//        self.collectionView?.reloadData()
//    }
//
//    /// generate folding lists
//    private func _folding(with source: Source) -> [Int: SourceFolding] {
//        var folding = [Int: SourceFolding]()
//
//        // do not fold when there is only one list
//        guard source.numberOfCollectionLists > 1 else {
//            return folding
//        }
//
//        // foreach all collection list
//        for section in 0 ..< source.numberOfCollectionLists {
//            // if collectoin list is empty, ignore
//            guard let collectionList = source.collectionList(at: section) else {
//                continue
//            }
//
//            // if collection list is regular, ignore
//            guard collectionList.ub_collectionType != .regular else {
//                continue
//            }
//
//            // generate a list folding
//            folding[section] = SourceFolding(collectionList: collectionList)
//        }
//
//        return folding
//    }
//
//    private(set) var foldingLists: [Int: SourceFolding]?
//
//    private var _selectItem: IndexPath?
//    private var _title: String?
}
