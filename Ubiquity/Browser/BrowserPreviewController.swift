//
//  BrowserPreviewController.swift
//  Ubiquity
//
//  Created by sagesse on 21/11/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class BrowserPreviewController: SourceCollectionViewController, UICollectionViewDelegateFlowLayout {

    required init(container: Container, source: Source, factory: Factory, parameter: Any?) {
        super.init(container: container, source: source, factory: factory, parameter: parameter)

        // if the navigation bar disable translucent will have an error offset, enabled `extendedLayoutIncludesOpaqueBars` can solve the problem
        self.extendedLayoutIncludesOpaqueBars = true
        self.automaticallyAdjustsScrollViewInsets = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()

        collectionView?.showsVerticalScrollIndicator = false
        collectionView?.showsHorizontalScrollIndicator = false
        collectionView?.scrollsToTop = false
        collectionView?.allowsSelection = false
        collectionView?.allowsMultipleSelection = false
        collectionView?.alwaysBounceHorizontal = true
        collectionView?.contentInset = UIEdgeInsetsMake(0, 0, 0, Settings.default.minimumItemSpacing)

        // in the iOS11 must disable adjustment
        if #available(iOS 11.0, *) {
            collectionView?.contentInsetAdjustmentBehavior = .never
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        // if section is empty, there is no need to fill in the blanks
        guard let collectionViewLayout = collectionViewLayout as? UICollectionViewFlowLayout, collectionView.numberOfItems(inSection: section) != 0 else {
            return .zero
        }
        return collectionViewLayout.sectionInset
    }
    
    override func controller(_ container: Container, didLoad source: Source, error: Error?) {
        guard source.numberOfAssets != 0 else {
            self.ub_execption(with: container, source: source, error: Exception.notData, animated: true)
            return
        }
        super.controller(container, didLoad: source, error: error)
    }    
}
