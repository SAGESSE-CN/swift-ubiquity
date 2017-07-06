//
//  PhotoLibrary.swift
//  Ubiquity-Example
//
//  Created by SAGESSE on 5/23/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

import Ubiquity

class PhotoLibraryController: UITabBarController {
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        _setup()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _setup()
    }
    
    private func _setup() {
        
        let library = PhotoLibrary()
        let container = Browser(library: library)
        
        //let vc1 = Ubiquity.BrowserAlbumZoomableController(library: library)
        let vc2 = BrowserAlbumListControllerMake(container)
            //Ubiquity.BrowserAlbumListController(library: library)
        
        //vc1.hidesBottomBarWhenPushed = true
        vc2.hidesBottomBarWhenPushed = true
        vc2.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Dismiss", style: .plain, target: self, action: #selector(dismiss(_:)))
        
//        let nav = NavigationController(navigationBarClass: nil, toolbarClass: ExtendedToolbar.self)
//        nav.viewControllers = [container.viewController]
        
        let nav1  =  NavigationControllerMake().init(navigationBarClass: nil, toolbarClass: ToolbarMake())
        nav1.viewControllers = [vc2]
        nav1.isNavigationBarHidden = false
        
        viewControllers = [
            nav1
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tabBar.isHidden = true
    }
    
    func dismiss(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
}
