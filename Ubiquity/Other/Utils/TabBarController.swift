//
//  TabBarController
//  Ubiquity
//
//  Created by sagesse on 01/08/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class TabBarController: UITabBarController {
    
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
    
    private dynamic func _cancel(_ sender: Any) {
        logger.trace?.write()
        
        // hiden
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    fileprivate var _container: Container
}

