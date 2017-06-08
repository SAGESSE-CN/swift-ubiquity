//
//  Debugger.swift
//  Example
//
//  Created by SAGESSE on 03/11/2016.
//  Copyright © 2016-2017 SAGESSE. All rights reserved.
//

import UIKit

internal class Debugger: UIView {
    
    func addRect(_ rect: CGRect, file: String = #file, at line: Int = #line) {
        let key = "\(file.hash)-\(line)"
        rects[key] = rect
        setNeedsDisplay()
    }
    func addPoint(_ point: CGPoint, file: String = #file, at line: Int = #line) {
        let key = "\(file.hash)-\(line)"
        points[key] = point
        setNeedsDisplay()
    }
    
    func addText(_ text: String, file: String = #file, at line: Int = #line) {
        let key = "\(file.hash)-\(line)"
        texts[key] = text
        setNeedsDisplay()
    }
    
    func color(with key: String) -> UIColor {
        if let color = colors[key] {
            return color
        }
        let maxValue: UInt32 = 24
        let color = UIColor(red: CGFloat(arc4random() % maxValue) / CGFloat(maxValue),
                            green: CGFloat(arc4random() % maxValue) / CGFloat(maxValue) ,
                            blue: CGFloat(arc4random() % maxValue) / CGFloat(maxValue) ,
                            alpha: 1)
        colors[key] = color
        return color
    }
    
    override func draw(_ rect: CGRect) {
        
        let context = UIGraphicsGetCurrentContext()
        
        context?.setLineWidth(1 / UIScreen.main.scale)
        
        
        texts.forEach {
            context?.setStrokeColor(color(with: $0).cgColor)
            ($1 as NSString).draw(at: .zero)
        }
        points.forEach {
            
            context?.setStrokeColor(color(with: $0).cgColor)
            context?.beginPath()
            // x
            context?.move(to: CGPoint(x: bounds.minX, y: $1.y))
            context?.addLine(to: CGPoint(x: bounds.maxX, y: $1.y))
            // y
            context?.move(to: CGPoint(x: $1.x, y: bounds.minY))
            context?.addLine(to: CGPoint(x: $1.x, y: bounds.maxY))
            
            context?.strokePath()
        }
        rects.forEach {
            context?.setStrokeColor(color(with: $0).cgColor)
            context?.beginPath()
            
            context?.move(to: .init(x: $1.minX, y: $1.minY))
            context?.addLine(to: .init(x: $1.maxX, y: $1.minY))
            context?.addLine(to: .init(x: $1.maxX, y: $1.maxY))
            context?.addLine(to: .init(x: $1.minX, y: $1.maxY))
            context?.addLine(to: .init(x: $1.minX, y: $1.minY))
            
            context?.strokePath()
        }
    }
    
    static var toolsDebugColorViewBounds: Bool {
        set {
            UIView.self.perform(Selector(String("_enableToolsDebugColorViewBounds:")), with: newValue)
        }
        get {
            let ob = (UIView.self as Any) as AnyObject
            return ob.value(forKey: "_toolsDebugColorViewBounds") as? Bool ?? false
        }
    }
    static var toolsDebugAlignmentRects: Bool {
        set {
            UIView.self.perform(Selector(String("_enableToolsDebugAlignmentRects:")), with: newValue)
        }
        get {
            let ob = (UIView.self as Any) as AnyObject
            return ob.value(forKey: "_toolsDebugAlignmentRects") as? Bool ?? false
        }
    }
    
    lazy var texts: [String: String] = [:]
    
    lazy var rects: [String: CGRect] = [:]
    lazy var points: [String: CGPoint] = [:]
    
    lazy var colors: [String: UIColor] = [:]
}

extension NSObject {
    @NSManaged func _methodDescription() -> NSString
}

extension UIView {
    @NSManaged func recursiveDescription() -> NSString
    
    private var _debugger: Debugger? {
        set { return objc_setAssociatedObject(self, &__DEBUGGER, newValue, .OBJC_ASSOCIATION_RETAIN) }
        get { return objc_getAssociatedObject(self, &__DEBUGGER) as? Debugger }
    }
    
    var debugger: Debugger {
        if let debugger = _debugger {
            return debugger
        }
        let debugger = Debugger()
        
        debugger.frame = bounds
        debugger.backgroundColor = .clear
        debugger.isUserInteractionEnabled = false
        debugger.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        addSubview(debugger)
        
        _debugger = debugger
        return debugger
    }
}

extension UIWindow {
    // ..
    var showsFPS: Bool {
        set {
            
            let view = objc_getAssociatedObject(self, &__DEBUGGER_FPS_LABEL) as? UIView ?? {
                let label = FPSLabel()
                objc_setAssociatedObject(self, &__DEBUGGER_FPS_LABEL, label, .OBJC_ASSOCIATION_RETAIN)
                return label
            }()
            
            guard newValue else {
                // hide
                view.removeFromSuperview()
                return
            }
            // show
            
            view.frame = CGRect(x: bounds.width - 55 - 8, y: 20, width: 55, height: 20)
            view.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
            
            addSubview(view)
        }
        get {
             return (objc_getAssociatedObject(self, &__DEBUGGER_FPS_LABEL) as? UIView)?.superview == self
        }
    }
}


///
/// Show Screen FPS.
///
/// The maximum fps in OSX/iOS Simulator is 60.00.
/// The maximum fps on iPhone is 59.97.
/// The maxmium fps on iPad is 60.0.
///
public class FPSLabel: UILabel {
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        build()
    }
    
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: 55, height: 20)
    }
    public override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil {
            _link.invalidate()
        } else {
            _link.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
        }
    }
    
    @inline(__always) private func build() {
        
        text = "calc..."
        font = UIFont.systemFont(ofSize: 14)
        textColor = UIColor.white
        textAlignment = .center
        backgroundColor = UIColor(white: 0, alpha: 0.7)
        
        layer.cornerRadius = 5
        layer.masksToBounds = true
    }
    
    private dynamic func tack(_ link: CADisplayLink) {
        guard let lastTime = _lastTime else {
            _lastTime = link.timestamp
            return
        }
        _count += 1
        let delta = link.timestamp - lastTime
        guard delta >= 1 else {
            return
        }
        let fps = Double(_count) / delta + 0.03
        let progress = CGFloat(fps / 60)
        let color = UIColor(hue: 0.27 * (progress - 0.2), saturation: 1, brightness: 0.9, alpha: 1)
        
        let text = NSMutableAttributedString(string: "\(Int(fps)) FPS")
        text.addAttribute(NSForegroundColorAttributeName, value: color, range: NSMakeRange(0, text.length - 3))
        attributedText = text
        
        _count = 0
        _lastTime = link.timestamp
    }
    
    private var _count: Int = 0
    private var _lastTime: TimeInterval?
    
    private lazy var _link: CADisplayLink = {
        return CADisplayLink(target: self, selector: #selector(type(of: self).tack(_:)))
    }()
}

private var __DEBUGGER = "__DEBUGGER"
private var __DEBUGGER_FPS_LABEL = "__DEBUGGER_FPS_LABEL"

