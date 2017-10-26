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
    @IBAction func odissmis(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func show(_ vc: UIViewController, sender: Any?) {
        vc.hidesBottomBarWhenPushed = true
        
        navigationController?.view.backgroundColor = .white
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func browse(_ sender: Any) {
        
        
        
        // create an image browser
        let browser = Ubiquity.Browser(library: Ubiquity.UHAssetLibrary())
        
        // create an view controller for albums
        let controller = browser.instantiateViewController(with: .albumsList, source: .init(collectionType: .regular))
        //let controller = browser.instantiateViewController(with: .albumsList, source: .init(collectionType: .moment))
        //let controller = browser.instantiateViewController(with: .albumsList, source: .init(collectionTypes: [.moment, .regular])) // has a bug in add section & remove section
        //let controller = browser.instantiateViewController(with: .albumsList, source: .init(collectionTypes: [.moment, .regular, .recentlyAdded]))
        //let controller = browser.instantiateViewController(with: .albumsList, source: .init(collectionType: .regular))
        //let controller = browser.instantiateViewController(with: .albumsList, source: .init(collectionType: .regular, filter: { $0.offset == 0 }))
        //let controller = browser.instantiateViewController(with: .albumsList, source: .init(collectionTypes: [.regular, .moment], filter: { $0.offset == 0 }))
        //let controller = browser.instantiateViewController(with: .albumsList, source: .init(collection: browser.request(forCollectionList: .regular).ub_collection(at: 0)))
        
        //let controller = browser.instantiateViewController(with: .albums, source: .init(collectionType: .regular))
        //let controller = browser.instantiateViewController(with: .albums, source: .init(collectionType: .moment))
        //let controller = browser.instantiateViewController(with: .albums, source: .init(collectionTypes: [.moment, .regular, .recentlyAdded]))
        //let controller = browser.instantiateViewController(with: .albums, source: .init(collectionType: .regular, filter: { $0.offset == 0 }))
        //let controller = browser.instantiateViewController(with: .albums, source: .init(collectionType: .regular, filter: { (offset, collection) in
        //    return collection.ub_collectionSubtype == .smartAlbumFavorites
        //}))

        // display controller
        show(controller, sender: nil)
    }
    
    @IBAction func pick(_ sender: Any) {
        
        let picker = Ubiquity.Picker(library: Ubiquity.UHAssetLibrary())
        
        // configure
        picker.delegate = self
        
        // display
//        let controller = picker.instantiateViewController(with: .albumsList, source: .init(collectionType: .regular))
        let controller = picker.instantiateViewController(with: .albums, source: .init(collectionType: .moment))

        controller.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(odissmis(_:)))
        
        // display controller
        present(controller, animated: true, completion: nil)
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

