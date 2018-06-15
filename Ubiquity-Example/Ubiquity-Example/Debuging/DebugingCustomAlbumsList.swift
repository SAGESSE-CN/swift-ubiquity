//
//  DebugingCustomAlbumsList.swift
//  Ubiquity-Example
//
//  Created by SAGESSE on 12/23/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit
import Ubiquity

class DebuggingCustomAlbumsListCell: Ubiquity.SourceCollectionViewCell {
    
    override func prepare() {
        super.prepare()
        
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 4
        contentView.layer.masksToBounds = true
        
        _imageView.contentMode = .scaleAspectFill
        _imageView.translatesAutoresizingMaskIntoConstraints = false
        _imageView.backgroundColor = #colorLiteral(red: 0.9411764706, green: 0.937254902, blue: 0.9607843137, alpha: 1)
        
        _titleLabel.font = UIFont.systemFont(ofSize: 12)
        _titleLabel.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        _titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(_imageView)
        contentView.addSubview(_titleLabel)
        
        contentView.addConstraints([
            .ub_make(_imageView, .top, .equal, contentView, .top),
            .ub_make(_imageView, .left, .equal, contentView, .left),
            .ub_make(_imageView, .right, .equal, contentView, .right),
            .ub_make(_imageView, .width, .equal, _imageView, .height),
            
            .ub_make(_titleLabel, .top, .equal, _imageView, .bottom, 8),
            .ub_make(_titleLabel, .left, .equal, contentView, .left, 8),
            .ub_make(_titleLabel, .right, .equal, contentView, .right, -8),
            .ub_make(_titleLabel, .bottom, .equal, contentView, .bottom, -8),
        ])
    }
    
    override func willDisplay(_ container: Container, orientation: UIImageOrientation) {
        super.willDisplay(container, orientation: orientation)
        
        guard let collection = collection else {
            return
        }
        
        _titleLabel.text = collection.ub_title
        
        if collection.ub_count == 0 {
            _imageView.image = nil
        } else {
            let asset = collection.ub_asset(at: 0)
            let size = CGSize(width: frame.width * UIScreen.main.scale,
                              height: frame.height * UIScreen.main.scale)
            _request = container.library.ub_request(forImage: asset, targetSize: size, contentMode: .aspectFill, options: .image, resultHandler: { [weak self](contents, response) in
                self?._imageView.image = contents
            })
        }
    }
    
    override func endDisplay(_ container: Container) {
        super.endDisplay(container)
        
        _request.map {
            container.library.ub_cancel(with: $0)
        }
        _request = nil
    }
    
    override var accessibilityIdentifier: String? {
        set {
            return super.accessibilityIdentifier = newValue
        }
        get {
            return super.accessibilityIdentifier ?? _titleLabel.accessibilityLabel
        }
    }

    private var _request: Ubiquity.Request?
    
    private lazy var _imageView: UIImageView = UIImageView()
    private lazy var _titleLabel: UILabel = UILabel()
}
class DebuggingCustomAlbumsListLayout: UICollectionViewFlowLayout {
    override func prepare() {
        self.collectionView.map {
            
            let sp = CGFloat(8)
            let iw = ($0.frame.width - sp * 3) / 2
            self.itemSize = .init(width: iw, height: iw + 40)
            
            self.minimumLineSpacing = sp
            self.minimumInteritemSpacing = sp
            self.sectionInset = .init(top: sp, left: sp, bottom: sp, right: sp)
        }
        super.prepare()
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard super.shouldInvalidateLayout(forBoundsChange: newBounds) else {
            return false
        }
        invalidateLayout()
        return true
    }
    
    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return nil
    }
    
    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return nil
    }
}
class DebuggingCustomAlbumsListController: Ubiquity.SourceCollectionViewController {
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = #colorLiteral(red: 0.287966609, green: 0.2879741788, blue: 0.2879701257, alpha: 1)
        collectionView?.backgroundColor = #colorLiteral(red: 0.287966609, green: 0.2879741788, blue: 0.2879701257, alpha: 1)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return source.numberOfCollections
    }
    
    override func data(_ source: Source, at indexPath: IndexPath) -> Any? {
        return source.collection(at: indexPath.item)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let collection = source.collection(at: indexPath.item) else {
            return
        }
        let controller = container.instantiateViewController(with: .albums, source: .init(collection: collection), parameter: indexPath)
        show(controller, sender: indexPath)
    }
}
