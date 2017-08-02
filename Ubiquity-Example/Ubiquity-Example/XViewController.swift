//
//  XViewController.swift
//  Ubiquity-Example
//
//  Created by sagesse on 02/08/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

class XViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
//        self.navigationController?.isToolbarHidden = false
        //self.hidesBottomBarWhenPushed
        //self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        self.tabBarController?.tabBar.isHidden = true
//        self.tabBarController?.tabBar.alpha = 0
        //self.navigationController?.toolbar.alpha = 1
        self.navigationController?.setToolbarHidden(false, animated: animated)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //self.navigationController?.setToolbarHidden(true, animated: animated)
        
//        self.tabBarController?.tabBar.isHidden = false
//        self.tabBarController?.tabBar.alpha = 1
        //self.navigationController?.toolbar.alpha = 0
        self.navigationController?.setToolbarHidden(true, animated: animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
