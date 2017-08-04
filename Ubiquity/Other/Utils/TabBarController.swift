//
//  TabBarController
//  Ubiquity
//
//  Created by sagesse on 01/08/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

public extension UIViewController {
    
    public var prefersTabBarHidden: Bool {
        return false
    }
    public var preferredTabBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    
    public var prefersToolbarHidden: Bool {
        return true
    }
    public var preferredToolbarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    
    public var prefersNavigationBarHidden: Bool {
        return false
    }
    public var preferredNavigationBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    
    func t_viewWillAppear(_ animated: Bool) {
        
        print(#function, animated)
        
        if let navigationController = self.navigationController {
            if prefersToolbarHidden {
                
                UIView.animate(withDuration: TimeInterval(UINavigationControllerHideShowBarDuration), animations: {
                    UIView.setAnimationBeginsFromCurrentState(true)
                    
                    navigationController.toolbar.setItems(self.toolbarItems, animated: true)
                    //navigationController.toolbar.alpha = 0
                    
                }, completion: { success in
                    
                    guard success else {
                        return
                    }
                    
                    UIView.performWithoutAnimation {
                        navigationController.setToolbarHidden(true, animated: false)
                        //navigationController.toolbar.isHidden = true
                        navigationController.toolbar.alpha = 1
                    }
                })
            } else {
                
                
//                UIView.performWithoutAnimation {
                
                    navigationController.setToolbarHidden(false, animated: false)
//                    navigationController.toolbar.frame.origin = .init(x: 0, y: navigationController.view.frame.height - navigationController.toolbar.frame.height)
//                    navigationController.toolbar.alpha = 0
//                }
                
//                if let tabbar = tabBarController?.tabBar {
//                    var nframe = tabbar.convert(tabbar.bounds, to: navigationController.view)
//                    //nframe.origin.x = 0
//                    //nframe.origin.y = navigationController.view.frame.height - nframe.height
//                    navigationController.toolbar.frame = nframe
//                }
                
//                UIView.animate(withDuration: TimeInterval(UINavigationControllerHideShowBarDuration), animations: {
//                    UIView.setAnimationBeginsFromCurrentState(true)
//                    
//                    navigationController.toolbar.setItems(self.toolbarItems, animated: true)
//                    
//                }, completion: { _ in
//                })
            }
        }
        if let tabBarController = self.tabBarController {
            if prefersTabBarHidden {
                
//                guard tabBarController.tabBar.isHidden else {
//                    return
//                }
                
                tabBarController.perform("hideBarWithTransition:", with: 0)
                tabBarController.tabBar.isHidden = false
                
                UIView.animate(withDuration: TimeInterval(UINavigationControllerHideShowBarDuration), animations: {
                    tabBarController.tabBar.alpha = 0
                }, completion: { _ in
                    tabBarController.tabBar.isHidden = true
                })
            } else {
                
//                guard !tabBarController.tabBar.isHidden else {
//                    return
//                }
                
                tabBarController.perform("showBarWithTransition:", with: 0)
                tabBarController.tabBar.isHidden = false
                
                UIView.animate(withDuration: TimeInterval(UINavigationControllerHideShowBarDuration), animations: {
                    tabBarController.tabBar.alpha = 1
                }, completion: { _ in
                    tabBarController.tabBar.alpha = 1
                })
            }
        }
    }
}

internal class TabBarController: UITabBarController, UITabBarControllerDelegate {
    
    init(container: Container) {
        _container = container
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func loadView() {
        super.loadView()
        
        // must set the background color
        view.backgroundColor = .white
        
        // set delegate
        delegate = self
        
        // all controllers
        var controllers: Array<UIViewController> = []
        
        // generate memont
        if let controller = _container.viewController(wit: .albums, source: .init(collectionType: .moment), sender: self) {
            // must show in navigation controller
            let navigation = NavigationController(navigationBarClass: nil, toolbarClass: nil)
            
            // config
            controller.title = "Moments"
            controller.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(_cancel(_:)))
            navigation.title = "Photos"
            navigation.tabBarItem.image = ub_image(named: "ubiquity_tab_photos_n")
            navigation.tabBarItem.selectedImage = ub_image(named: "ubiquity_tab_photos_s")
            navigation.viewControllers = [controller]
            
            // add to tabbar controller
            controllers.append(navigation)
        }
        
        // generate album list
        if let controller = _container.viewController(wit: .albumsList, source: .init(collectionType: .regular), sender: self) {
            // must show in navigation controller
            let navigation = NavigationController(navigationBarClass: nil, toolbarClass: nil)
            
            // config
            controller.title = "Albums"
            controller.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(_cancel(_:)))
            navigation.title = "Albums"
            navigation.tabBarItem.image = ub_image(named: "ubiquity_tab_albums_n")
            navigation.tabBarItem.selectedImage = ub_image(named: "ubiquity_tab_albums_s")
            navigation.viewControllers = [controller]
            
            // add to tabbar controller
            controllers.append(navigation)
        }
        
        // setup controller
        viewControllers = controllers
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // show fps
        UIApplication.shared.delegate?.window??.showsFPS = true
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        self.tabBar.frame.origin.x = 0
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.tabBar.frame.origin.x = 0
    }
    
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        // if multiple click, scroll to the bottom
        guard viewController === selectedViewController else {
            return true
        }
        
        // fetch top view controller
        let topViewController = (viewController as? UINavigationController)?.topViewController ?? viewController
        
        // fetch scroll view
        guard let scrollView = ((topViewController as? UITableViewController)?.tableView ?? (topViewController as? UICollectionViewController)?.collectionView) else {
            return true
        }
        // can scroll?
        let height = scrollView.frame.height - scrollView.contentInset.bottom
        guard scrollView.contentSize.height >= height else {
            return false
        }
        
        // scroll to bottom
        scrollView.setContentOffset(.init(x: 0, y: max(scrollView.contentSize.height - height, 0)), animated: true)
        return false
    }
    
    override var tabBar: UITabBar {
        return super.tabBar
    }
    
    
    private dynamic func _cancel(_ sender: Any) {
        logger.trace?.write()
        
        // hiden
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    fileprivate var _container: Container
}

