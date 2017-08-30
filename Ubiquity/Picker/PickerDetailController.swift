//
//  PickerDetailController.swift
//  Ubiquity
//
//  Created by sagesse on 30/08/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class PickerDetailController: BrowserDetailController {

    override func loadView() {
        super.loadView()
        
        // setup right
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
    }
    
    // MARK: Collection View Scroll
    
    /// The scrollView did scroll
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        
        
        logger.debug?.write(scrollView.contentOffset)
    }
}
