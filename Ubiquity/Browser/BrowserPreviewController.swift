//
//  BrowserPreviewController.swift
//  Ubiquity
//
//  Created by sagesse on 21/11/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class BrowserPreviewController: SourceController, Controller, UICollectionViewDelegateFlowLayout {
    
    required init(container: Container, source: Source, sender: Any?) {
        super.init(container: container, source: source, factory: container.factory(with: .popover))
        
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
        
        // must set up an empty view
        // otherwise in the performBatchUpdates header/footer create failure led to the crash
        collectionView?.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "Empty")
        
        // in the iOS11 must disable adjustment
        if #available(iOS 11.0, *) {
            collectionView?.contentInsetAdjustmentBehavior = .never
        }
    }
    
    // MARK: Collection View Configure
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        // generate header view.
        return collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "Empty", for: indexPath)
    }
    override func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        // hidden header view
        view.isHidden = true
        view.isUserInteractionEnabled = false
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let asset = source.asset(at: indexPath) else {
            return .zero
        }
        
        let width = CGFloat(asset.ub_pixelWidth)
        let height = CGFloat(asset.ub_pixelHeight)
        let scale = view.frame.height / max(height, 1)
        
        return CGSize(width: width * scale, height: view.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Settings.default.minimumItemSpacing
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return Settings.default.minimumItemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        // if section is empty, there is no need to fill in the blanks
        guard collectionView.numberOfItems(inSection: section) != 0 else {
            return .zero
        }
        return .init(width: Settings.default.minimumItemSpacing, height: 0)
    }
}
