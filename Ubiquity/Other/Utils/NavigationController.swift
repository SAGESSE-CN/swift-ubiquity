//
//  NavigationController.swift
//  Ubiquity
//
//  Created by SAGESSE on 5/16/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class NavigationController: UINavigationController {
    
    override init(navigationBarClass: Swift.AnyClass?, toolbarClass: Swift.AnyClass?) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass ?? ExtendedToolbar.self)
    }

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var childViewControllerForStatusBarStyle: UIViewController? {
        return topViewController
    }
}
