//
//  Ubiquity_Example_Tests.swift
//  Ubiquity-Example-Tests
//
//  Created by sagesse on 23/11/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import XCTest

@testable import Ubiquity_Example

struct Position: OptionSet {
    
    let rawValue: Int

    static let left     = Position(rawValue: 1 << 0)
    static let right    = Position(rawValue: 1 << 1)
    static let center   = Position(rawValue: 1 << 2)
    static let top      = Position(rawValue: 1 << 3)
    static let bottom   = Position(rawValue: 1 << 4)
}

extension XCUIElement {

    func coordinate(withPosition position: Position) -> XCUICoordinate {
        
        let x: CGFloat
        let y: CGFloat
        
        if position.contains(.left) {
            x = 0.00
        } else if position.contains(.right) {
            x = 1.00
        } else {
            x = 0.50
        }
        
        if position.contains(.top) {
            y = 0.00
        } else if position.contains(.bottom) {
            y = 1.00
        } else {
            y = 0.50
        }
        
        return coordinate(withNormalizedOffset: .init(dx: x, dy: y))
    }
}

class ExampleTests: XCTestCase {
    
    
    override func setUp() {
        super.setUp()
        
        guard application == nil else {
            return
        }
        application = XCUIApplication()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = true
        
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        application.launch()

        // Create shared data.
        shared = Shared.default

        // Click the three title to enter the debug mode
        application.navigationBars.element.tap(withNumberOfTaps: 3, numberOfTouches: 1)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func command(_ message: String) {
        shared["Command"] = message
        application.navigationBars.buttons["Refresh"].tap()
    }
    
    func testCanvas() {
        self.application.tables/*@START_MENU_TOKEN@*/.staticTexts["Canvas"]/*[[".cells.staticTexts[\"Canvas\"]",".staticTexts[\"Canvas\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        let application = XCUIApplication()
        
        let scrollView = application.scrollViews.element
        let contentView = scrollView.children(matching: .image).element
        let content = contentView.frame
        let rato = content.width / max(content.height, 1)
        
        XCTAssert(scrollView.exists)
        XCTAssert(contentView.exists)
        
        
        // ======== Move ========
        
        /*M=0*/command("reload")
        /*M=0*/XCTAssertEqual(contentView.frame.minX, content.minX, accuracy: 1)
        /*M=0*/XCTAssertEqual(contentView.frame.minY, content.minY, accuracy: 1)
        /*M=0*/XCTAssertEqual(contentView.frame.maxX, content.maxX, accuracy: 1)
        /*M=0*/XCTAssertEqual(contentView.frame.maxY, content.maxY, accuracy: 1)
        
        /*M=0*/application.doubleTap()
        /*M=0*/XCTAssertEqual(contentView.frame.midX, scrollView.frame.midX, accuracy: 1)
        /*M=0*/XCTAssertEqual(contentView.frame.midY, scrollView.frame.midY, accuracy: 1)
        /*M=0*/XCTAssertEqual(contentView.frame.width / max(contentView.frame.height, 1), rato, accuracy: 0.1)

        /*M=BC*/command("reset")
        /*M=BC*/scrollView.swipeUp()
        /*M=BC*/scrollView.swipeUp()
        /*M=BC*/XCTAssertEqual(contentView.frame.midX, scrollView.frame.width / 2, accuracy: 1)
        /*M=BC*/XCTAssertEqual(contentView.frame.maxY, scrollView.frame.height, accuracy: 1)

        /*M=TC*/command("reset")
        /*M=TC*/scrollView.swipeDown()
        /*M=TC*/scrollView.swipeDown()
        /*M=TC*/XCTAssertEqual(contentView.frame.midX, scrollView.frame.width / 2, accuracy: 1)
        /*M=TC*/XCTAssertEqual(contentView.frame.minY, 0, accuracy: 1)
        
        /*M=CL*/command("reset")
        /*M=CL*/scrollView.swipeRight()
        /*M=CL*/scrollView.swipeRight()
        /*M=CL*/XCTAssertEqual(contentView.frame.minX, 0, accuracy: 1)
        /*M=CL*/XCTAssertEqual(contentView.frame.midY, scrollView.frame.height / 2, accuracy: 1)

        /*M=CR*/command("reset")
        /*M=CR*/scrollView.swipeLeft()
        /*M=CR*/scrollView.swipeLeft()
        /*M=CR*/XCTAssertEqual(contentView.frame.maxX, scrollView.frame.width, accuracy: 1)
        /*M=CR*/XCTAssertEqual(contentView.frame.midY, scrollView.frame.height / 2, accuracy: 1)
        
        /*M=T*/command("reset")
        /*M=T*/scrollView.coordinate(withPosition: .top).tap()
        /*M=T*/scrollView.coordinate(withPosition: .top).tap()
        /*M=T*/XCTAssertEqual(contentView.frame.midX, scrollView.frame.width / 2, accuracy: 1)
        /*M=T*/XCTAssertEqual(contentView.frame.minY, 0, accuracy: 1)
        
        // ======== Zoom Scale ========
        
        /*ZS=0*/command("reload")
        /*ZS=0*/XCTAssertEqual(contentView.frame.minX, content.minX, accuracy: 1)
        /*ZS=0*/XCTAssertEqual(contentView.frame.minY, content.minY, accuracy: 1)
        /*ZS=0*/XCTAssertEqual(contentView.frame.maxX, content.maxX, accuracy: 1)
        /*ZS=0*/XCTAssertEqual(contentView.frame.maxY, content.maxY, accuracy: 1)
        
        /*ZS=5*/command("reload")
        /*ZS=5*/contentView.pinch(withScale: 5.0, velocity: +2)
        /*ZS=5*/XCTAssertEqual(contentView.frame.midX, scrollView.frame.midX, accuracy: 1)
        /*ZS=5*/XCTAssertEqual(contentView.frame.midY, scrollView.frame.midY, accuracy: 1)
        /*ZS=5*/XCTAssertEqual(contentView.frame.width / max(contentView.frame.height, 1), rato, accuracy: 0.1)

        /*ZS=1*/command("reload")
        /*ZS=1*/contentView.pinch(withScale: 0.5, velocity: -2)
        /*ZS=1*/XCTAssertEqual(contentView.frame.minX, content.minX, accuracy: 1)
        /*ZS=1*/XCTAssertEqual(contentView.frame.minY, content.minY, accuracy: 1)
        /*ZS=1*/XCTAssertEqual(contentView.frame.maxX, content.maxX, accuracy: 1)
        /*ZS=1*/XCTAssertEqual(contentView.frame.maxY, content.maxY, accuracy: 1)

        /*ZS=TL*/command("reload")
        /*ZS=TL*/contentView.coordinate(withPosition: [.top, .left]).doubleTap()
        /*ZS=TL*/XCTAssertEqual(contentView.frame.minX, 0, accuracy: 1)
        /*ZS=TL*/XCTAssertEqual(contentView.frame.minY, 0, accuracy: 1)

        /*ZS=TC*/command("reload")
        /*ZS=TC*/contentView.coordinate(withPosition: [.top, .center]).doubleTap()
        /*ZS=TC*/XCTAssertEqual(contentView.frame.midX, scrollView.frame.width / 2, accuracy: 1)
        /*ZS=TC*/XCTAssertEqual(contentView.frame.minY, 0, accuracy: 1)

        /*ZS=TR*/command("reload")
        /*ZS=TR*/contentView.coordinate(withPosition: [.top, .right]).doubleTap()
        /*ZS=TR*/XCTAssertEqual(contentView.frame.maxX, scrollView.frame.width, accuracy: 1)
        /*ZS=TR*/XCTAssertEqual(contentView.frame.minY, 0, accuracy: 1)

        /*ZS=CL*/command("reload")
        /*ZS=CL*/contentView.coordinate(withPosition: [.center, .left]).doubleTap()
        /*ZS=CL*/XCTAssertEqual(contentView.frame.minX, 0, accuracy: 1)
        /*ZS=CL*/XCTAssertEqual(contentView.frame.midY, scrollView.frame.height / 2, accuracy: 1)

        /*ZS=CC*/command("reload")
        /*ZS=CC*/contentView.coordinate(withPosition: [.center, .center]).doubleTap()
        /*ZS=CC*/XCTAssertEqual(contentView.frame.midX, scrollView.frame.width / 2, accuracy: 1)
        /*ZS=CC*/XCTAssertEqual(contentView.frame.midY, scrollView.frame.height / 2, accuracy: 1)

        /*ZS=CR*/command("reload")
        /*ZS=CR*/contentView.coordinate(withPosition: [.center, .right]).doubleTap()
        /*ZS=CR*/XCTAssertEqual(contentView.frame.maxX, scrollView.frame.width, accuracy: 1)
        /*ZS=CR*/XCTAssertEqual(contentView.frame.midY, scrollView.frame.height / 2, accuracy: 1)

        /*ZS=BL*/command("reload")
        /*ZS=BL*/contentView.coordinate(withPosition: [.bottom, .left]).doubleTap()
        /*ZS=BL*/XCTAssertEqual(contentView.frame.minX, 0, accuracy: 1)
        /*ZS=BL*/XCTAssertEqual(contentView.frame.maxY, scrollView.frame.height, accuracy: 1)

        /*ZS=BC*/command("reload")
        /*ZS=BC*/contentView.coordinate(withPosition: [.bottom, .center]).doubleTap()
        /*ZS=BC*/XCTAssertEqual(contentView.frame.midX, scrollView.frame.width / 2, accuracy: 1)
        /*ZS=BC*/XCTAssertEqual(contentView.frame.maxY, scrollView.frame.height, accuracy: 1)

        /*ZS=BR*/command("reload")
        /*ZS=BR*/contentView.coordinate(withPosition: [.bottom, .right]).doubleTap()
        /*ZS=BR*/XCTAssertEqual(contentView.frame.maxX, scrollView.frame.width, accuracy: 1)
        /*ZS=BR*/XCTAssertEqual(contentView.frame.maxY, scrollView.frame.height, accuracy: 1)

        /*ZS=TCE*/command("reload")
        /*ZS=TCE*/contentView.coordinate(withPosition: [.top, .center]).withOffset(.init(dx: CGFloat(0), dy: CGFloat(-0.1))).doubleTap()
        /*ZS=TCE*/XCTAssertEqual(contentView.frame.midX, scrollView.frame.width / 2, accuracy: 1)
        /*ZS=TCE*/XCTAssertEqual(contentView.frame.minY, 0, accuracy: 1)

        /*ZS=BCE*/command("reload")
        /*ZS=BCE*/contentView.coordinate(withPosition: [.bottom, .center]).withOffset(.init(dx: CGFloat(0), dy: CGFloat(+0.1))).doubleTap()
        /*ZS=BCE*/XCTAssertEqual(contentView.frame.midX, scrollView.frame.width / 2, accuracy: 1)
        /*ZS=BCE*/XCTAssertEqual(contentView.frame.maxY, scrollView.frame.height, accuracy: 1)

        // ======== Rotation ========
        
        /*R=0*/command("reload")
        /*R=0*/XCTAssertEqual(contentView.frame.minX, content.minX, accuracy: 1)
        /*R=0*/XCTAssertEqual(contentView.frame.minY, content.minY, accuracy: 1)
        /*R=0*/XCTAssertEqual(contentView.frame.maxX, content.maxX, accuracy: 1)
        /*R=0*/XCTAssertEqual(contentView.frame.maxY, content.maxY, accuracy: 1)
        
        /*R=90*/contentView.rotate(CGFloat.pi / 2, withVelocity: 5)
        /*R=90*/XCTAssertEqual(contentView.frame.midX, scrollView.frame.midX, accuracy: 1)
        /*R=90*/XCTAssertEqual(contentView.frame.midY, scrollView.frame.midY, accuracy: 1)
        /*R=90*/XCTAssertEqual(contentView.frame.width, scrollView.frame.width, accuracy: 2)
        /*R=90*/XCTAssertEqual(contentView.frame.height / max(contentView.frame.width, 1), rato, accuracy: 0.1)
        
        /*R=180*/contentView.rotate(CGFloat.pi / 2, withVelocity: 5)
        /*R=180*/XCTAssertEqual(contentView.frame.midX, scrollView.frame.midX, accuracy: 1)
        /*R=180*/XCTAssertEqual(contentView.frame.midY, scrollView.frame.midY, accuracy: 1)
        /*R=180*/XCTAssertEqual(contentView.frame.width, scrollView.frame.width, accuracy: 2)
        /*R=180*/XCTAssertEqual(contentView.frame.width / max(contentView.frame.height, 1), rato, accuracy: 0.1)
        
        /*R=270*/contentView.rotate(CGFloat.pi / 2, withVelocity: 5)
        /*R=270*/XCTAssertEqual(contentView.frame.midX, scrollView.frame.midX, accuracy: 1)
        /*R=270*/XCTAssertEqual(contentView.frame.midY, scrollView.frame.midY, accuracy: 1)
        /*R=270*/XCTAssertEqual(contentView.frame.width, scrollView.frame.width, accuracy: 2)
        /*R=270*/XCTAssertEqual(contentView.frame.height / max(contentView.frame.width, 1), rato, accuracy: 0.1)
        
        /*R=360*/contentView.rotate(CGFloat.pi / 2, withVelocity: 5)
        /*R=360*/XCTAssertEqual(contentView.frame.midX, scrollView.frame.midX, accuracy: 1)
        /*R=360*/XCTAssertEqual(contentView.frame.midY, scrollView.frame.midY, accuracy: 1)
        /*R=360*/XCTAssertEqual(contentView.frame.width, scrollView.frame.width, accuracy: 2)
        /*R=360*/XCTAssertEqual(contentView.frame.width / max(contentView.frame.height, 1), rato, accuracy: 0.1)
        
        /*R=270*/contentView.rotate(-CGFloat.pi / 2, withVelocity: -5)
        /*R=270*/XCTAssertEqual(contentView.frame.midX, scrollView.frame.midX, accuracy: 1)
        /*R=270*/XCTAssertEqual(contentView.frame.midY, scrollView.frame.midY, accuracy: 1)
        /*R=270*/XCTAssertEqual(contentView.frame.width, scrollView.frame.width, accuracy: 2)
        /*R=270*/XCTAssertEqual(contentView.frame.height / max(contentView.frame.width, 1), rato, accuracy: 0.1)
        
        /*R=180*/contentView.rotate(-CGFloat.pi / 2, withVelocity: -5)
        /*R=180*/XCTAssertEqual(contentView.frame.midX, scrollView.frame.midX, accuracy: 1)
        /*R=180*/XCTAssertEqual(contentView.frame.midY, scrollView.frame.midY, accuracy: 1)
        /*R=180*/XCTAssertEqual(contentView.frame.width, scrollView.frame.width, accuracy: 2)
        /*R=180*/XCTAssertEqual(contentView.frame.width / max(contentView.frame.height, 1), rato, accuracy: 0.1)
        
        /*R=0*/contentView.rotate(-CGFloat.pi, withVelocity: -5)
        /*R=0*/XCTAssertEqual(contentView.frame.midX, scrollView.frame.midX, accuracy: 1)
        /*R=0*/XCTAssertEqual(contentView.frame.midY, scrollView.frame.midY, accuracy: 1)
        /*R=0*/XCTAssertEqual(contentView.frame.width, scrollView.frame.width, accuracy: 2)
        /*R=0*/XCTAssertEqual(contentView.frame.width / max(contentView.frame.height, 1), rato, accuracy: 0.1)
        
        /*R=0*/contentView.rotate(CGFloat.pi / 4, withVelocity: 5)
        /*R=0*/XCTAssertEqual(contentView.frame.midX, scrollView.frame.midX, accuracy: 1)
        /*R=0*/XCTAssertEqual(contentView.frame.midY, scrollView.frame.midY, accuracy: 1)
        /*R=0*/XCTAssertEqual(contentView.frame.width, scrollView.frame.width, accuracy: 2)
        /*R=0*/XCTAssertEqual(contentView.frame.width / max(contentView.frame.height, 1), rato, accuracy: 0.1)

        // ========  Screen Direction  ========
        
        /*SD=0*/command("reload")
        /*SD=0*/XCTAssertEqual(contentView.frame.minX, content.minX, accuracy: 1)
        /*SD=0*/XCTAssertEqual(contentView.frame.minY, content.minY, accuracy: 1)
        /*SD=0*/XCTAssertEqual(contentView.frame.maxX, content.maxX, accuracy: 1)
        /*SD=0*/XCTAssertEqual(contentView.frame.maxY, content.maxY, accuracy: 1)
        
        /*SD=L*/XCUIDevice.shared.orientation = .landscapeLeft
        /*SD=L*/XCTAssertEqual(contentView.frame.midX, scrollView.frame.midX, accuracy: 1)
        /*SD=L*/XCTAssertEqual(contentView.frame.midY, scrollView.frame.midY, accuracy: 1)
        /*SD=L*/XCTAssertEqual(contentView.frame.height, scrollView.frame.height, accuracy: 2)
        /*SD=L*/XCTAssertEqual(contentView.frame.width / max(contentView.frame.height, 1), rato, accuracy: 0.1)
        
        /*SD=P*/XCUIDevice.shared.orientation = .portrait
        /*SD=P*/XCTAssertEqual(contentView.frame.midX, scrollView.frame.midX, accuracy: 1)
        /*SD=P*/XCTAssertEqual(contentView.frame.midY, scrollView.frame.midY, accuracy: 1)
        /*SD=P*/XCTAssertEqual(contentView.frame.width, scrollView.frame.width, accuracy: 2)
        /*SD=P*/XCTAssertEqual(contentView.frame.width / max(contentView.frame.height, 1), rato, accuracy: 0.1)

        self.application.navigationBars.buttons["Debuging"].tap()
    }
    
    private var application: XCUIApplication!
    private var shared: Shared!
}
