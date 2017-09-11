//
//  TestVideoViewController.swift
//  Ubiquity-Example
//
//  Created by sagesse on 12/09/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit
import AVFoundation

@testable import Ubiquity

class TestVideoViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let contentView = PlayerView(frame: view.frame)
        
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.prepare(with: AVPlayerItem(asset: AVURLAsset(url: URL(string: "http://192.168.90.204/a.mp4")!)))
        
        view.addSubview(contentView)
        
        _contentView = contentView
    }
    
    private var _contentView: PlayerView?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        _contentView?.play()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
