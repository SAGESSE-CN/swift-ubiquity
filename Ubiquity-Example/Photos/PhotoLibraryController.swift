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
