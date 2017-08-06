//
//  BrowserAlbumListController.swift
//  Ubiquity
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

public func BrowserAlbumListControllerMake(_ container: Container) -> UIViewController {
    //return BrowserAlbumListController(container: container)
    return TabBarController(container: container)
}

/// the album list in container
internal class BrowserAlbumListController: UITableViewController, Controller {
    
    required init(container: Container, factory: Factory, source: Source, sender: Any) {
        // setup init data
        _source = source
        _container = container
        
        // continue init the UI
        super.init(nibName: nil, bundle: nil)
        
        // listen albums any change
        _container.addChangeObserver(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // cancel listen change
        _container.removeChangeObserver(self)
    }
    
    /// Reload all data on authorization status did change
    func reloadData(with auth: AuthorizationStatus) {
        // check for authorization status
        guard auth == .authorized else {
            // no permission
            showError(with: "No Access Permissions", subtitle: "") // 此应用程序没有权限访问您的照片\n在\"设置-隐私-图片\"中开启后即可查看
            return
        }
        
        // fet collection list with container
        let newCollectionList = _container.request(forCollection: _source.collectionType)
        _collectionList = newCollectionList
        
        // check albums count
        guard newCollectionList.count != 0 else {
            // no data
            showError(with: "No Photos or Videos", subtitle: "")
            return
        }
        
        // clear error info & display album
        clearError()
    }
    
    override func loadView() {
        super.loadView()
        // setup controller
        title = "Albums"
        clearsSelectionOnViewWillAppear = false
        
        // setup table view
        tableView.register(BrowserAlbumListCell.self, forCellReuseIdentifier: "ASSET")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // request permission with show
        _container.library.requestAuthorization  { status in
            DispatchQueue.main.async {
                self.reloadData(with: status)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // start clear
        _selectedItem.map {
            tableView?.deselectRow(at: $0, animated: animated)
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // cancel clear
        _selectedItem.map {
            tableView?.selectRow(at: $0, animated: animated, scrollPosition: .none)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // if the info view is show, update the layout
        if let infoView = _infoView {
            infoView.frame = view.bounds
        }
    }
    
    fileprivate var _source: Source
    fileprivate var _container: Container
    fileprivate var _collectionList: CollectionList?
    
    fileprivate var _selectedItem: IndexPath?
    
    fileprivate var _infoView: ErrorView?
}

/// Add data source
extension BrowserAlbumListController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _collectionList?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "ASSET", for: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // cell must king of `BrowserAlbumListCell`
        guard let cell = cell as? BrowserAlbumListCell, let collection = _collectionList?[indexPath.row] else {
            return
        }
        
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = .white
        
        // update data for displaying
        cell.willDisplay(with: collection, container: _container)
    }
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // cell must king of `BrowserAlbumListCell`
        guard let cell = cell as? BrowserAlbumListCell else {
            return
        }
        
        // clear data for end display
        cell.endDisplay(with: _container)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        logger.trace?.write(indexPath)
        
        // fetch collection
        guard let collection = _collectionList?[indexPath.row] else {
            return
        }
        logger.debug?.write("show album with: \(collection.title ?? ""), at: \(indexPath)")
        
        // create album controller
        guard let controller = _container.viewController(wit: .albums, source: .init(collection: collection), sender: indexPath) else {
            return
        }
        _selectedItem = indexPath
       
        // show next page
        show(controller, sender: indexPath)
    }
}

/// Add change update support
extension BrowserAlbumListController: ChangeObserver {
    /// Tells your observer that a set of changes has occurred in the Photos library.
    func library(_ library: Library, didChange change: Change) {
        // albums is change?
        guard let collectionList = _collectionList, let details = change.changeDetails(for: collectionList) else {
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
    func library(_ library: Library, didChange change: Change, details: ChangeDetails) {
        // get table view and new data source
        guard let tableView = tableView, let newCollectionList = details.after as? CollectionList else {
            return
        }
        // keep the new fetch result for future use.
        _collectionList = newCollectionList
        
        // if there are incremental diffs, animate them in the table view.
        guard details.hasIncrementalChanges else {
            // reload the table view if incremental diffs are not available.
            tableView.reloadData()
            return
        }
        
        
        tableView.beginUpdates()
        
        // For indexes to make sense, updates must be in this order:
        // delete, insert, reload, move
        if let rms = details.removedIndexes?.map({ IndexPath(item: $0, section:0) }) {
            tableView.deleteRows(at: rms, with: .automatic)
        }
        
        if let ins = details.insertedIndexes?.map({ IndexPath(item: $0, section:0) }) {
            tableView.insertRows(at: ins, with: .automatic)
        }
        
        if let rds = details.changedIndexes?.map({ IndexPath(item: $0, section:0) }) {
            
            tableView.reloadRows(at: rds, with: .automatic)
        }
        
        details.enumerateMoves { from, to in
            tableView.moveRow(at: .init(row: from, section: 0),
                              to: .init(row: to, section: 0))
        }
        
        tableView.endUpdates()
    }
}

/// Add library error info display support
extension BrowserAlbumListController {
    
    /// Show error info in view controller
    func showError(with title: String, subtitle: String) {
        
        logger.trace?.write(title, subtitle)
        
        // clear view
        _infoView?.removeFromSuperview()
        _infoView = nil
        
        let infoView = ErrorView(frame: view.bounds)
        
        infoView.title = title
        infoView.subtitle = subtitle
        infoView.backgroundColor = .white
        infoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // show view
        view.addSubview(infoView)
        _infoView = infoView
        
        // disable scroll
        tableView.isScrollEnabled = false
        tableView.reloadData()
    }
    
    /// Hiden all error info
    func clearError() {
        logger.trace?.write()
        
        // enable scroll
        tableView.isScrollEnabled = true
        tableView.reloadData()
        
        // clear view
        _infoView?.removeFromSuperview()
        _infoView = nil
        
        self.tableView.alpha = 0
        UIView.animate(withDuration: 0.25) {
            self.tableView.alpha = 1
        }
    }
}
