//
//  TestAnimatedImageViewController.swift
//  Ubiquity-Example
//
//  Created by sagesse on 06/09/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit
import Ubiquity


class TestAnimatedImageViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let path = Bundle.main.url(forResource: "019@2x", withExtension: "gif") else {
            return
        }
        guard let data = try? Data(contentsOf: path, options: .mappedIfSafe) else {
            return
        }
        
        let image = Ubiquity.Image(data: data)
        let imageView = Ubiquity.ImageView(image: image)
        imageView.frame = view.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(imageView)
    }
}
