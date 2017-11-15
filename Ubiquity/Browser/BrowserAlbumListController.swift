//
//  BrowserAlbumListController.swift
//  Ubiquity
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit


/// the album list in container
internal class BrowserAlbumListController: UITableViewController, Controller, ExceptionHandling, ChangeObserver {
    
    required init(container: Container, source: Source, sender: Any?) {
        // setup init data
        self.source = source
        self.container = container
        
        // continue init the UI
        super.init(style: .grouped)
        super.title = source.title
        
        // listen albums any change
        self.container.addChangeObserver(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // cancel listen change
        self.container.removeChangeObserver(self)
    }
    
    override var title: String? {
        willSet {
            _cachedTitle = newValue
        }
    }
    
    
    override func loadView() {
        super.loadView()
        // setup controller
        clearsSelectionOnViewWillAppear = false
        
        // setup table view
        tableView.register(BrowserAlbumListCell.self, forCellReuseIdentifier: "ASSET")
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "LINE")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // delay exec, order to prevent the view not initialized
        DispatchQueue.main.async {
            // initialize controller with container and source
            self.ub_initialize(with: self.container, source: self.source)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // start clear
        _selectItem.map {
            tableView?.deselectRow(at: $0, animated: animated)
        } 
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // cancel clear
        _selectItem.map {
            tableView?.selectRow(at: $0, animated: animated, scrollPosition: .none)
        }
    }
    
    // MARK: Table view
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return source.numberOfCollectionLists
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // if the section has folding item, only show folded collections
        if let folding = foldingLists?[section] {
            return folding.numberOfFoldedCollections
        }

        // in other albums, display all collection
        return source.numberOfCollections(inCollectionList: section)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88
    }
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.5
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "ASSET", for: indexPath)
    }
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // in last section, footer is hidden
        guard section < tableView.numberOfSections - 1 else {
            return nil
        }
        
        // fetch footer view for dequeue
        let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "LINE")
        footerView?.contentView.backgroundColor = .lightGray
        return footerView
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // cell must king of `BrowserAlbumListCell`
        guard let cell = cell as? BrowserAlbumListCell else {
            return
        }
        // if there is a collection in the fold, use it first
        let folded = foldingLists?[indexPath.section]?.collection(at: indexPath.item)
        guard let collection = folded ?? source.collection(at: indexPath.row, inCollectionList: indexPath.section) else {
            return
        }
        
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = .white
        
        // update data for displaying
        cell.willDisplay(with: collection, container: container)
    }
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // cell must king of `BrowserAlbumListCell`
        guard let cell = cell as? BrowserAlbumListCell else {
            return
        }
        
        // clear data for end display
        cell.endDisplay(with: container)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        logger.trace?.write(indexPath)
        
        if let target = foldingLists?[indexPath.section].map({ Source(collectionList: $0.collectionList, filter: source.filter) }) {
            // display album for collection list
            _show(with: target, at: indexPath)
            _selectItem = indexPath
            return
        }
        
        if let target = source.collection(at: indexPath.row, inCollectionList: indexPath.section).map({ Source(collection: $0) }) {
            // display album for collection
            _show(with: target, at: indexPath)
            _selectItem = indexPath
            return
        }
    }
    
    // MARK: Library change
    
    /// Tells your observer that a set of changes has occurred in the Photos library.
    func library(_ library: Library, didChange change: Change) {
        // the source is changed?
        guard let details = source.changeDetails(forCollections: change) else {
            return
        }
        logger.trace?.write()
        
        // change notifications may be made on a background queue.
        // re-dispatch to the main queue to update the UI.
        DispatchQueue.main.async {
            self.library(library, didChange: change, details: details)
        }
    }
    /// Tells your observer that a set of changes has occurred in the Photos library.
    func library(_ library: Library, didChange change: Change, details: SourceChangeDetails) {
        // get table view and new data source
        guard let tableView = tableView, let newSource = details.after else {
            return
        }
        // keep the new fetch result for future use.
        source = newSource
        foldingLists = _folding(with: newSource)
        
        logger.debug?.write(time(nil))
        
        // check new albums count
        guard newSource.numberOfCollections != 0 else {
            // display error and update tableview 
            ub_execption(with: container, source: newSource, error: Exception.notData, animated: true)
            tableView.reloadData()
            return
        }
        
        // hidden error info if needed
        ub_execption(with: container, source: newSource, error: nil, animated: true)
        
        // if there are incremental diffs, animate them in the table view.
        guard details.hasIncrementalChanges else {
            // reload the table view if incremental diffs are not available.
            tableView.reloadData()
            return
        }
        
        // if folded collection list has any change, reload all
        foldingLists?.forEach { (section, folding) in
            
            let filter = { (indexPath: IndexPath) -> Bool in
                if indexPath.section == section {
                    if details.reloadSections == nil {
                        details.reloadSections = []
                    }
                    details.reloadSections?.insert(section)
                    return false
                }
                return true
            }
            
            details.reloadItems = details.reloadItems?.filter(filter)
            details.insertItems = details.insertItems?.filter(filter)
            details.removeItems = details.removeItems?.filter(filter)
        }
        
        UIView.animate(withDuration: 0.25) {
            tableView.beginUpdates()
            
            // For indexes to make sense, updates must be in this order:
            // delete, insert, reload, move
            
            details.deleteSections.map { tableView.deleteSections($0, with: .automatic) }
            details.insertSections.map { tableView.insertSections($0, with: .automatic) }
            details.reloadSections.map { tableView.reloadSections($0, with: .automatic) }
            
            details.moveSections?.forEach { from, to in
                tableView.moveSection(from, toSection: to)
            }
            
            details.removeItems.map { tableView.deleteRows(at: $0, with: .automatic) }
            details.insertItems.map { tableView.insertRows(at: $0, with: .automatic) }
            details.reloadItems.map { tableView.reloadRows(at: $0, with: .automatic) }
            
            details.moveItems?.forEach { from, to in
                tableView.moveRow(at: from, to: to)
            }
            
            tableView.endUpdates()
        }
    }
    
    
    // MARK: Extended
    
    /// Call before request authorization
    open func container(_ container: Container, willAuthorization source: Source) {
        logger.trace?.write()
    }
    
    /// Call after completion of request authorization
    open func container(_ container: Container, didAuthorization source: Source, error: Error?) {
        // the error message has been processed by the ExceptionHandling
        guard error == nil else {
            return
        }
        logger.trace?.write(error ?? "")
    }
    
    /// Call before request load
    open func container(_ container: Container, willLoad source: Source) {
        logger.trace?.write()
    }
    
    /// Call after completion of load
    open func container(_ container: Container, didLoad source: Source, error: Error?) {
        // the error message has been processed by the ExceptionHandling
        guard error == nil else {
            return
        }
        logger.trace?.write(error ?? "")
        
        // check albums count
        guard source.numberOfCollections != 0 else {
            ub_execption(with: container, source: source, error: Exception.notData, animated: true)
            return
        }
        
        // refresh UI
        self.source = source
        self.foldingLists = _folding(with: source)
        self.tableView?.reloadData()
    }
    
    /// show alubms with source
    private func _show(with source: Source, at indexPath: IndexPath) {
        // try generate album controller for factory
        let controller = container.instantiateViewController(with: .albums, source: source, sender: indexPath)
        show(controller, sender: indexPath)
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
    
    private(set) var container: Container
    private(set) var source: Source {
        willSet {
            // only when in did not set the title will be updated
            super.title = _cachedTitle ?? newValue.title
        }
    }
    
    private var _selectItem: IndexPath?
    private var _cachedTitle: String?
}

