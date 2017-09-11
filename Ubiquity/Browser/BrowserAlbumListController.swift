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
        super.init(nibName: nil, bundle: nil)
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
        _cachedSelectItem.map {
            tableView?.deselectRow(at: $0, animated: animated)
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // cancel clear
        _cachedSelectItem.map {
            tableView?.selectRow(at: $0, animated: animated, scrollPosition: .none)
        }
    }
    
    // MARK: Table view
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return source.numberOfCollectionLists
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return source.numberOfCollections(inCollectionList: section)
//        // if has regular albums, only display on collection in other collection list
//        guard source.numberOfCollectionLists > 1, source.collectionTypes.contains(.regular) else {
//            return source.numberOfCollections(inCollectionList: section)
//        }
//        
//        // in regular albums, display all collections
//        guard let collectionList = source.collectionList(at: section), collectionList.ub_collectionType != .regular else {
//            return source.numberOfCollections(inCollectionList: section)
//        }
//        
//        // in other albums, display on collection 
//        return min(source.numberOfCollections(inCollectionList: section), 1)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "ASSET", for: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // cell must king of `BrowserAlbumListCell`
        guard let collection = source.collection(at: indexPath.row, inCollectionList: indexPath.section), let cell = cell as? BrowserAlbumListCell else {
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
        
        // get selected collection
        guard let collection = source.collection(at: indexPath.row, inCollectionList: indexPath.section) else {
            return
        }
        logger.debug?.write("show album with: \(collection.ub_title ?? ""), at: \(indexPath)")
        
        // try generate album controller for factory
        let controller = container.instantiateViewController(with: .albums, source: .init(collection: collection), sender: indexPath)
        
        _cachedSelectItem = indexPath
       
        // show next page
        show(controller, sender: indexPath)
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
        self.tableView?.reloadData()
    }
    
    
    private(set) var container: Container
    private(set) var source: Source {
        willSet {
            // only when in did not set the title will be updated
            super.title = _cachedTitle ?? newValue.title
        }
    }
    
    private var _cachedSelectItem: IndexPath?
    private var _cachedTitle: String?
}

