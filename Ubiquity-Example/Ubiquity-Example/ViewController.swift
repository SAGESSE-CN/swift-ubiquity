//
//  ViewController.swift
//  Ubiquity-Example
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit
#if DEBUG
    @testable import Ubiquity
#else
    import Ubiquity
#endif

//import WebKit

class ViewController: UITableViewController, UIActionSheetDelegate, Ubiquity.PickerDelegate {
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if DEBUG
            UIApplication.shared.delegate?.window??.showsFPS = true
        #endif
    }
    
    @IBAction func show(_ sender: Any) {
        
        browse(sender)
//        pick(sender)
    }
    
    override func show(_ vc: UIViewController, sender: Any?) {
        vc.hidesBottomBarWhenPushed = true
        
        navigationController?.view.backgroundColor = .white
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func browse(_ sender: Any) {
        
        let browser = Ubiquity.Browser(library: Ubiquity.UHAssetLibrary())
        
        // configure
        browser.allowsCollectionTypes = [.moment]
        
        // display
        //present(browser.initialViewController(with: .albumsList), animated: true, completion: nil)
        //show(browser.initialViewController(with: .albumsList), sender: nil)
        show(browser.initialViewController(with: .albums), sender: nil)
    }
    
    @IBAction func pick(_ sender: Any) {
        
        let picker = Ubiquity.Picker(library: Ubiquity.UHAssetLibrary())
        
        // configure
        picker.delegate = self
        picker.allowsCollectionTypes = [.regular]
        
        // display
        present(picker.initialViewController(with: .albumsList), animated: true, completion: nil)
    }
    
    
    func picker(_ picker: Picker, shouldSelectItem asset: Asset) -> Bool {
        // the asset should selected
        return true
    }
    
    func picker(_ picker: Picker, didSelectItem asset: Asset) {
        // the asset did selected
    }
    
    func picker(_ picker: Picker, didDeselectItem asset: Asset) {
        // the asset did deselected
    }
}

