//
//  DebugingCanvasViewController.swift
//  Example
//
//  Created by SAGESSE on 03/11/2016.
//  Copyright © 2016-2017 SAGESSE. All rights reserved.
//

import UIKit
import Ubiquity

internal class DebugingCanvasViewController: UIViewController, CanvasViewDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        let cv = CanvasView(frame: view.bounds)
        containerView = cv
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(cv, at: 0)
        
        // Do any additional setup after loading the view.
        
        imageView.frame = CGRect(x: 0, y: 0, width: 1600, height: 1200)
        imageView.image = UIImage(named: "t1_g.jpg")
//        imageView.frame = .init(x: 0, y: 0, width: 16198, height: 11674)
//        imageView.image = {
//            guard let path = Bundle.main.url(forResource: "《塞尔达传说：荒野之息》导航地图", withExtension: "jpg") else {
//                return nil
//            }
//            guard let data = try? Data(contentsOf: path, options: .mappedIfSafe) else {
//                return nil
//            }
//
//            return Ubiquity.Image(data: data)
//        }()
        
        containerView.delegate = self
        //containerView.contentSize = CGSize(width: 240, height: 180)
//        containerView.contentSize = CGSize(width: 16198, height: 11674)
        containerView.contentSize = CGSize(width: 1600, height: 1200)
        containerView.addSubview(imageView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapHandler(_:)))
        
        tap.numberOfTapsRequired = 2
        
        containerView.addGestureRecognizer(tap)
        
        ProcessInfo.processInfo.environment["XPCDebugger"].map { _ in
            XPCDebugger.shared.on("do-reload") { [weak self] _ in
                DispatchQueue.main.sync {
                    self?.rpc("do-reload")
                }
            }
            XPCDebugger.shared.on("do-reset") { [weak self] _ in
                DispatchQueue.main.sync {
                    self?.rpc("do-reset")
                }
            }
        }
    }
    
    func rpc(_ cmd: String) {
        switch cmd {
        case "do-reload":
            containerView.setZoomScale(containerView.minimumZoomScale, animated: true)

        case "do-reset":
            let x = (imageView.frame.width - containerView.frame.width) / 2
            let y = (max(imageView.frame.height, containerView.frame.height) - containerView.frame.height) / 2
            containerView.setContentOffset(.init(x: x, y: y), animated: true)

        default:
            break
        }
    }
    
    @objc func tapHandler(_ sender: UITapGestureRecognizer) {
        
        let pt = sender.location(in: imageView)
        
        if containerView.zoomScale != containerView.minimumZoomScale {
            // min
            containerView.setZoomScale(containerView.minimumZoomScale, at: pt, animated: true)
            
        } else {
            // max
            containerView.setZoomScale(containerView.maximumZoomScale, at: pt, animated: true)
        }
    }
    
     func viewForZooming(in canvasView: CanvasView) -> UIView? {
        return imageView
    }
    
    func canvasViewShouldBeginRotationing(_ canvasView: CanvasView, with view: UIView?) -> Bool {
        return true
    }
    func canvasViewDidEndRotationing(_ canvasView: CanvasView, with view: UIView?, atOrientation orientation: UIImageOrientation) {
        imageView.image = imageView.image.map {
            UIImage(cgImage: $0.cgImage!, scale: $0.scale, orientation: orientation)
        }
    }
    
    lazy var imageView: UIImageView = UIImageView()
    
    var containerView: CanvasView!
}

