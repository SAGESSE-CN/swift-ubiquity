//
//  ViewController.swift
//  Ubiquity-Example
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit
//@testable import Ubiquity
import Ubiquity

import WebKit

class ViewController: UITableViewController, UIActionSheetDelegate {
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func show(_ sender: Any) {
        
        //let browser = Ubiquity.Browser(library: Ubiquity.SandboxLibrary())
        let browser = Ubiquity.Picker(library: Ubiquity.SystemLibrary())
        
        // configure
        browser.allowsCollectionTypes = [.moment, .regular]
        
        //browser.register(UIView.self, for: .video, type: .albums)
        //browser.register(UIView.self, for: .video, type: .albumsList)
        //browser.register(UIView.self, for: .video, type: .detail)
        //browser.register(UIViewController.self, for: .albums)
        //browser.register(UIViewController.self, for: .albumsList)
        //browser.register(UIViewController.self, for: .detail)
        
        // display
        present(browser.initialViewController(with: .albumsList), animated: true, completion: nil)
        //present(browser.initialViewController(with: .albums), animated: true, completion: nil)
    }
}

