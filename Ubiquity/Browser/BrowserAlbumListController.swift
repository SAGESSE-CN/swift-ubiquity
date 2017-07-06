//
//  BrowserAlbumListController.swift
//  Ubiquity
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

public func BrowserAlbumListControllerMake(_ container: Container) -> UIViewController {
    return BrowserAlbumListController(container: container)
}
public func NavigationControllerMake() -> UINavigationController.Type {
    return NavigationController.self
}
public func ToolbarMake() -> UIToolbar.Type {
    return ExtendedToolbar.self
}

/// the album list in container
internal class BrowserAlbumListController: UITableViewController {
    
    init(container: Container) {
        _container = container
        
        // continue init the UI
        super.init(nibName: nil, bundle: nil)
        
        // listen albums any change
        _container.register(self)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        // cancel listen change
        _container.unregisterObserver(self)
    }
    
    func reloadData(with auth: AuthorizationStatus) {
        
        // check for authorization status
        guard auth == .authorized else {
            // no permission
            showError(with: "No Access Permissions", subtitle: "") // 此应用程序没有权限访问您的照片\n在\"设置-隐私-图片\"中开启后即可查看
            return
        }
        // get all photo albums
        let collections = _container.request(forCollection: .regular)
        // check for photos albums count
        guard !collections.isEmpty else {
            // no data
            showError(with: "No Photos or Videos", subtitle: "")
            return
        }
        // clear error info & display album
        _collections = collections
        
        // clear all error info 
        clearError()
    }
    
    override func loadView() {
        super.loadView()
        // setup controller
        title = "Albums"
        
        // setup table view
        tableView.register(BrowserAlbumListCell.self, forCellReuseIdentifier: "ASSET")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // request permission with show
        _container.requestAuthorization  { status in
            DispatchQueue.main.async {
                self.reloadData(with: status)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // if the selected cell, need to deselect
        tableView.visibleCells.forEach { cell in
            cell.setSelected(false, animated: animated)
            cell.setHighlighted(false, animated: animated)
        }
        
        // show fps
        view.window?.showsFPS = true
        view.window?.backgroundColor = .white
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // if the info view is show, update the layout
        if let infoView = _infoView {
            infoView.frame = view.bounds
        }
    }
    
    fileprivate var _container: Container
    fileprivate var _collections: Array<Collection>?
    
    fileprivate var _infoView: ErrorInfoView?
}

/// Add data source
internal extension BrowserAlbumListController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _collections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "ASSET", for: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // try fetch cell
        // try fetch collection
        guard let collection = _collections?.ub_get(at: indexPath.row), let cell = cell as? BrowserAlbumListCell else {
            return
        }
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = .white
        // update data for displaying
        cell.willDisplay(with: collection, container: _container)
    }
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // try fetch cell
        // try fetch collection
        guard let collection = _collections?.ub_get(at: indexPath.row), let cell = cell as? BrowserAlbumListCell else {
            return
        }
        // clear data for end display
        cell.endDisplay(with: collection, container: _container)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        logger.trace?.write(indexPath)
        
        // try fetch collection
        guard let collection = _collections?.ub_get(at: indexPath.row) else {
            return
        }
        logger.debug?.write("show album with: \(collection.title ?? "")")
        
        let controller = BrowserAlbumController(source: .init(collection), container: _container)
        //let controller = PickerAlbumController(source: .init(collection), container: _container)
        // push to next page
        show(controller, sender: indexPath)
    }
}

/// Add change update support
extension BrowserAlbumListController: ChangeObserver {
    /// Tells your observer that a set of changes has occurred in the Photos library.
    func library(_ library: Library, didChange change: Change) {
        logger.debug?.write()
    }
}

/// Add library error info display support
internal extension BrowserAlbumListController {
    
    /// Show error info in view controller
    func showError(with title: String, subtitle: String) {
        
        logger.trace?.write(title, subtitle)
        
        // clear view
        _infoView?.removeFromSuperview()
        _infoView = nil
        
        let infoView = ErrorInfoView(frame: view.bounds)
        
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
    }
}
