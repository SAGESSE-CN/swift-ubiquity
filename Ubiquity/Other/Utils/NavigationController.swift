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
        self.automaticallyAdjustsScrollViewInsets = false
    }

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        //logger.debug?.write()
        
        
//        guard let toolbar = toolbar else {
//            return
//        }
//        
//        var frame = toolbar.frame
//        frame.origin.y = view.bounds.height - frame.height
//
//        guard toolbar.frame.minY != frame.minY else {
//            return
//        }
//        toolbar.frame = frame
    }
    
//    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
//        
//        //self.tabBarController?.tabBar.isHidden = true
//        
//        self.isToolbarHidden = false
//        self.toolbar.frame.origin.y = self.view.frame.height - self.toolbar.frame.height
//        
//        super.pushViewController(viewController, animated: animated)
//        
//        guard let tabbar = self.tabBarController?.tabBar else {
//            return
//        }
//        
//        
////        var nframe = self.toolbar.frame
////        nframe.origin = .init(x: 0, y: self.view.frame.height - self.toolbar.frame.height)
//        
////        UIView.animate(withDuration: 0.25) {
////            tabbar.frame.origin.x = 0
////        }
////        
////        tabbar.transform = CGAffineTransform(translationX: nframe.width, y: 0)
////        tabbar.layer.removeAllAnimations()
//        
////        self.toolbar.items = viewController.toolbarItems
////        self.toolbar.frame.origin.y = self.view.frame.height - self.toolbar.frame.height
//        
//        UIView.animate(withDuration: 0.25, animations: {
//            tabbar.alpha = 0
//            //sn.frame = nframe
//        }, completion: { _ in
////            sn.removeFromSuperview()
////            tabbar.alpha = 1
////            tabbar.isHidden = true
////        tabbar.transform = .identity //CGAffineTransform(translationX: nframe.width, y: 0)
//        })
//        
//        
////        self.setToolbarHidden(false, animated: false)
////        self.toolbar.alpha = 0
////        UIView.animate(withDuration: 0.25) {
////            self.toolbar.alpha = 1
////            self.tabBarController?.tabBar.alpha = 0
////        }
//    }
//    override func popViewController(animated: Bool) -> UIViewController? {
//        
//        //self.setToolbarHidden(true, animated: animated)
//        //self.toolbar.frame.origin.y = self.view.frame.height - self.toolbar.frame.height
//        
//        let vc = super.popViewController(animated: animated)
//        
//        //self.toolbar.items = nil
////        toolbar.isHidden = false
//        
//        guard let tabbar = self.tabBarController?.tabBar else {
//            return vc
//        }
////
////        let nframe = tabbar.frame
////        
////        tabbar.frame = self.toolbar.frame
//        
//        UIView.animate(withDuration: 0.25, animations: {
//            //tabbar.frame = nframe
//            tabbar.alpha = 1
//        }, completion: { _ in
//            self.isToolbarHidden = false
//        })
//        
//        return vc
//    }
//    override func popToRootViewController(animated: Bool) -> [UIViewController]? {
//        let vc = super.popToRootViewController(animated: animated)
//        return vc
//    }
    
    override var childViewControllerForStatusBarStyle: UIViewController? {
        return topViewController
    }
}
