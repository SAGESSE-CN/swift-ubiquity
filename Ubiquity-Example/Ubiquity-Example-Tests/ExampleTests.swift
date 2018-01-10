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

    func map(_ block: (XCUIElement) -> ()) {
        block(self)
    }
    
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

func equal(_ lhs: CGRect, _ rhs: CGRect, accuracy: CGFloat) -> Bool {
    return fabs(lhs.minX - rhs.minX) <= accuracy
        && fabs(lhs.minY - rhs.minY) <= accuracy
        && fabs(lhs.maxX - rhs.maxX) <= accuracy
        && fabs(lhs.maxY - rhs.maxY) <= accuracy
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

        // Confiugre remote debugger.
        RPCDebugger.shared.on("api-init") { _ in
            RPCDebugger.shared.emit("api-hook", "*")
        }

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        application.launchEnvironment = ["RPC_DEBUGGER_ADDRESS": "deubbger://127.0.0.1:\(RPCDebugger.shared.port)"]
        application.launch()

        // Click the three title to enter the debug mode.
        application.navigationBars.element.tap(withNumberOfTaps: 3, numberOfTouches: 1)

        // Reset the device orientation.
        XCUIDevice.shared.orientation = .portrait
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()

        Thread.sleep(forTimeInterval: 1)
    }

    func command(_ message: String) {
        RPCDebugger.shared.emit("do-\(message)")
        Thread.sleep(until: .init(timeIntervalSinceNow: 0.5))
    }

    func testCanvas() {
        self.application.tables.staticTexts["Canvas"].tap()

        let application = XCUIApplication()

        let scrollView = application.scrollViews.element
        let contentView = scrollView.children(matching: .image).element
        let content = contentView.frame
        let rato = content.width / max(content.height, 1)
        let mw = max(scrollView.frame.width, scrollView.frame.height)
        
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
        /*M=T*/Thread.sleep(forTimeInterval: 2)
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
        /*SD=L*/Thread.sleep(forTimeInterval: 1)
        /*SD=L*/XCTAssertEqual(contentView.frame.midX, scrollView.frame.midX, accuracy: 1)
        /*SD=L*/XCTAssertEqual(contentView.frame.midY, scrollView.frame.midY, accuracy: 1)
        /*SD=L*/XCTAssertEqual(contentView.frame.height, scrollView.frame.height, accuracy: 2)
        /*SD=L*/XCTAssertEqual(contentView.frame.width / max(contentView.frame.height, 1), rato, accuracy: 0.1)

        /*SD=P*/XCUIDevice.shared.orientation = .portrait
        /*SD=P*/Thread.sleep(forTimeInterval: 1)
        /*SD=P*/XCTAssertEqual(contentView.frame.midX, scrollView.frame.midX, accuracy: 1)
        /*SD=P*/XCTAssertEqual(contentView.frame.midY, scrollView.frame.midY, accuracy: 1)
        /*SD=P*/XCTAssertEqual(contentView.frame.width, scrollView.frame.width, accuracy: 2)
        /*SD=P*/XCTAssertEqual(contentView.frame.width / max(contentView.frame.height, 1), rato, accuracy: 0.1)

        /*SD=CC*/command("reload")
        /*SD=CC*/application.doubleTap()
        /*SD=CC*/XCTAssertEqual(contentView.frame.midX, scrollView.frame.midX, accuracy: 2)
        /*SD=CC*/XCTAssertEqual(contentView.frame.midY, scrollView.frame.midY, accuracy: 2)
        /*SD=CC*/XCTAssertEqual(contentView.frame.width / max(contentView.frame.height, 1), rato, accuracy: 0.1)
        /*SD=CC*/XCUIDevice.shared.orientation = .landscapeLeft
        /*SD=CC*/Thread.sleep(forTimeInterval: 1)
        /*SD=CC*/XCTAssertEqual(contentView.frame.midX, scrollView.frame.midX, accuracy: 2)
        /*SD=CC*/XCTAssertEqual(contentView.frame.midY, scrollView.frame.midY, accuracy: 2)
        /*SD=CC*/XCTAssertEqual(contentView.frame.width / max(contentView.frame.height, 1), rato, accuracy: 0.1)
        /*SD=CC*/XCUIDevice.shared.orientation = .portrait
        /*SD=CC*/Thread.sleep(forTimeInterval: 1)
        /*SD=CC*/XCTAssertEqual(contentView.frame.midX, scrollView.frame.midX, accuracy: 2)
        /*SD=CC*/XCTAssertEqual(contentView.frame.midY, scrollView.frame.midY, accuracy: 2)
        /*SD=CC*/XCTAssertEqual(contentView.frame.width / max(contentView.frame.height, 1), rato, accuracy: 0.1)

        /*SD=TL*/command("reload")
        /*SD=TL*/contentView.coordinate(withPosition: [.top, .left]).doubleTap()
        /*SD=TL*/XCTAssertEqual(contentView.frame.minX, 0, accuracy: 2)
        /*SD=TL*/XCTAssertEqual(contentView.frame.minY, 0, accuracy: 2)
        /*SD=TL*/XCUIDevice.shared.orientation = .landscapeLeft
        /*SD=TL*/Thread.sleep(forTimeInterval: 1)
        /*SD=TL*/XCTAssertEqual(contentView.frame.minX, 0, accuracy: 2)
        /*SD=TL*/XCTAssertEqual(contentView.frame.minY, scrollView.frame.height / 2 - mw / 2, accuracy: 2)
        /*SD=TL*/XCUIDevice.shared.orientation = .portrait
        /*SD=TL*/Thread.sleep(forTimeInterval: 1)
        /*SD=TL*/XCTAssertEqual(contentView.frame.minX, scrollView.frame.width / 2 - mw / 2, accuracy: 2)
        /*SD=TL*/XCTAssertEqual(contentView.frame.minY, 0, accuracy: 2)

        /*SD=BR*/command("reload")
        /*SD=BR*/contentView.coordinate(withPosition: [.bottom, .right]).doubleTap()
        /*SD=BR*/XCTAssertEqual(contentView.frame.maxX, scrollView.frame.width, accuracy: 1)
        /*SD=BR*/XCTAssertEqual(contentView.frame.maxY, scrollView.frame.height, accuracy: 1)
        /*SD=BR*/XCUIDevice.shared.orientation = .landscapeLeft
        /*SD=BR*/Thread.sleep(forTimeInterval: 1)
        /*SD=BR*/XCTAssertEqual(contentView.frame.maxX, scrollView.frame.width, accuracy: 2)
        /*SD=BR*/XCTAssertEqual(contentView.frame.maxY, scrollView.frame.height / 2 + mw / 2, accuracy: 2)
        /*SD=BR*/XCUIDevice.shared.orientation = .portrait
        /*SD=BR*/Thread.sleep(forTimeInterval: 1)
        /*SD=BR*/XCTAssertEqual(contentView.frame.maxX, scrollView.frame.width / 2 + mw / 2, accuracy: 2)
        /*SD=BR*/XCTAssertEqual(contentView.frame.maxY, scrollView.frame.height, accuracy: 2)

        self.application.navigationBars.buttons["Debuging"].tap()
    }

    func testBrowser() {
        self.application.tables.staticTexts["Browser"].tap()

        let window = self.application.windows.element(boundBy: 0)
        let controllers = { (page: String, block: () -> ()) -> Void in
            if !self.application.staticTexts[page].exists {
                self.application.swipeUp()
            }
            self.application.staticTexts[page].tap()
            block()
            self.application.buttons["Browser"].tap()
        }
        let cells = { (identifier: String) -> XCUIElement in
            if !window.cells[identifier].exists {
                window.swipeUp()
            }
            return window.cells[identifier]
        }

        XCTAssert(window.exists)

        controllers("Album List - Empty") {
            application.navigationBars["Album List - Empty"].map {
                XCTAssertEqual($0.exists, true)

                XCTAssertEqual(application.otherElements["ExceptionView"].exists, true)
                XCTAssertEqual(application.otherElements["ExceptionView"].frame, window.frame)

                XCTAssertEqual(application.staticTexts["No Photos or Videos"].exists, true)
                XCTAssertEqual(application.staticTexts["You can sync photos and videos onto your iPhone using iTunes."].exists, true)
            }
        }
        controllers("Album List - Error") {
            application.navigationBars["Album List - Error"].map {
                XCTAssertEqual($0.exists, true)
                
                XCTAssertEqual($0.exists, true)
                
                XCTAssertEqual(application.otherElements["ExceptionView"].exists, true)
                XCTAssertEqual(application.otherElements["ExceptionView"].frame, window.frame)
                
                XCTAssertEqual(application.staticTexts["No Access Permissions"].exists, true)
                XCTAssertEqual(application.staticTexts["Application does not have permission to access your photo."].exists, true)
            }
        }

        controllers("Album List - Regular") {
            application.navigationBars["Photos"].map {
                XCTAssertEqual($0.exists, true)
            }
            cells("Collection<0>").map {
                XCTAssertEqual($0.exists, true)
                XCTAssertEqual($0.frame.height, 88, accuracy: 0.5)

                XCTAssertEqual($0.staticTexts.element(boundBy: 0).label, "Collection<0>")
                XCTAssertEqual($0.staticTexts.element(boundBy: 1).label, "0")

                XCTAssertEqual($0.otherElements["ThumbView"].value as? String, "\(["empty","empty","empty"])")
                
                XCTAssertEqual($0.otherElements["ThumbView"].frame.width, 70, accuracy: 0.5)
                XCTAssertEqual($0.otherElements["ThumbView"].frame.height, 70, accuracy: 0.5)
                
                XCTAssertEqual($0.images["BadgeItemImageView"].exists, false)
            }
            cells("Collection<1>").map {
                XCTAssertEqual($0.exists, true)
                XCTAssertEqual($0.otherElements["ThumbView"].value as? String, "\(["t1_t","",""])")

                XCTAssertEqual($0.images["BadgeItemImageView"].exists, true)
                XCTAssertEqual($0.images["BadgeItemImageView"].identifier, "ubiquity_badge_panorama")
            }
            cells("Collection<2>").map {
                XCTAssertEqual($0.exists, true)
                XCTAssertEqual($0.otherElements["ThumbView"].value as? String, "\(["t1_t","t1_t",""])")

                XCTAssertEqual($0.images["BadgeItemImageView"].exists, true)
                XCTAssertEqual($0.images["BadgeItemImageView"].identifier, "ubiquity_badge_video")
            }
            cells("Collection<3>").map {
                XCTAssertEqual($0.exists, true)
                XCTAssertEqual($0.otherElements["ThumbView"].value as? String, "\(["t1_t","t1_t","t1_t"])")

                XCTAssertEqual($0.images["BadgeItemImageView"].exists, true)
                XCTAssertEqual($0.images["BadgeItemImageView"].identifier, "ubiquity_badge_favorites")
            }
            cells("Collection<4>").map {
                XCTAssertEqual($0.exists, true)
                XCTAssertEqual($0.otherElements["ThumbView"].value as? String, "\(["t1_t","t1_t","t1_t"])")

                XCTAssertEqual($0.images["BadgeItemImageView"].exists, true)
                XCTAssertEqual($0.images["BadgeItemImageView"].identifier, "ubiquity_badge_timelapse")

                XCTAssertEqual($0.staticTexts.element(boundBy: 0).label, "Collection<4>")
                XCTAssertEqual($0.staticTexts.element(boundBy: 1).label, "4")
            }
            cells("Collection<5>").map {
                XCTAssertEqual($0.exists, true)
                XCTAssertEqual($0.otherElements["ThumbView"].value as? String, "\(["t1_t","t1_t","t1_t"])")

                XCTAssertEqual($0.images["BadgeItemImageView"].exists, false)

                XCTAssertEqual($0.staticTexts.element(boundBy: 0).label, "Collection<5>")
                XCTAssertEqual($0.staticTexts.element(boundBy: 1).label, "5")
            }
            cells("Collection<6>").map {
                XCTAssertEqual($0.exists, true)
                XCTAssertEqual($0.otherElements["ThumbView"].value as? String, "\(["t1_t","t1_t","t1_t"])")

                XCTAssertEqual($0.images["BadgeItemImageView"].exists, false)

                XCTAssertEqual($0.staticTexts.element(boundBy: 0).label, "Collection<6>")
                XCTAssertEqual($0.staticTexts.element(boundBy: 1).label, "6")
            }
            cells("Collection<7>").map {
                XCTAssertEqual($0.exists, true)
                XCTAssertEqual($0.otherElements["ThumbView"].value as? String, "\(["t1_t","t1_t","t1_t"])")

                XCTAssertEqual($0.images["BadgeItemImageView"].exists, true)
                XCTAssertEqual($0.images["BadgeItemImageView"].identifier, "ubiquity_badge_burst")

                XCTAssertEqual($0.staticTexts.element(boundBy: 0).label, "Collection<7>")
                XCTAssertEqual($0.staticTexts.element(boundBy: 1).label, "7")
            }
            cells("Collection<8>").map {
                XCTAssertEqual($0.exists, true)
                XCTAssertEqual($0.otherElements["ThumbView"].value as? String, "\(["empty","empty","empty"])")

                XCTAssertEqual($0.images["BadgeItemImageView"].exists, true)
                XCTAssertEqual($0.images["BadgeItemImageView"].identifier, "ubiquity_badge_slomo")

                XCTAssertEqual($0.staticTexts.element(boundBy: 0).label, "Collection<8>")
                XCTAssertEqual($0.staticTexts.element(boundBy: 1).label, "0")
            }
            cells("Collection<9>").map {
                XCTAssertEqual($0.exists, true)
                XCTAssertEqual($0.otherElements["ThumbView"].value as? String, "\(["t1_t","",""])")

                XCTAssertEqual($0.staticTexts.element(boundBy: 0).label, "Collection<9>")
                XCTAssertEqual($0.staticTexts.element(boundBy: 1).label, "1")
            }
            cells("Collection<10>").map {
                XCTAssertEqual($0.exists, true)
                XCTAssertEqual($0.otherElements["ThumbView"].value as? String, "\(["t1_t","t1_t",""])")

                XCTAssertEqual($0.images["BadgeItemImageView"].exists, true)
                XCTAssertEqual($0.images["BadgeItemImageView"].identifier, "ubiquity_badge_selfies")

                XCTAssertEqual($0.staticTexts.element(boundBy: 0).label, "Collection<10>")
                XCTAssertEqual($0.staticTexts.element(boundBy: 1).label, "2")
            }
            cells("Collection<11>").map {
                XCTAssertEqual($0.exists, true)
                XCTAssertEqual($0.otherElements["ThumbView"].value as? String, "\(["t1_t","t1_t","t1_t"])")

                XCTAssertEqual($0.images["BadgeItemImageView"].exists, true)
                XCTAssertEqual($0.images["BadgeItemImageView"].identifier, "ubiquity_badge_screenshots")

                XCTAssertEqual($0.staticTexts.element(boundBy: 0).label, "Collection<11>")
                XCTAssertEqual($0.staticTexts.element(boundBy: 1).label, "3")
            }
        }
        controllers("Album List - Moments & Regular & Recently") {
            application.navigationBars["Photos"].map {
                XCTAssertEqual($0.exists, true)
            }
            window.otherElements["LINE-[1, 0]"].map {
                XCTAssertEqual($0.exists, true)
                XCTAssertEqual($0.frame.maxX, window.frame.width, accuracy: 0.5)
                XCTAssertEqual($0.frame.height, 1 / UIScreen.main.scale, accuracy: 0.5)
            }
            cells("CollectionList").map {
                XCTAssertEqual($0.exists, true)
                XCTAssertEqual($0.frame.height, 88, accuracy: 0.5)
                
                XCTAssertEqual($0.staticTexts.element(boundBy: 0).label, "CollectionList")
                XCTAssertEqual($0.staticTexts.element(boundBy: 1).label, "56")
                
                XCTAssertEqual($0.otherElements["ThumbView"].value as? String, "\(["t1_t","t1_t","t1_t"])")

                XCTAssertEqual($0.otherElements["ThumbView"].frame.width, 70, accuracy: 0.5)
                XCTAssertEqual($0.otherElements["ThumbView"].frame.height, 70, accuracy: 0.5)
            }
            cells("Collection<0>").map {
                XCTAssertEqual($0.exists, true)
                XCTAssertEqual($0.staticTexts.element(boundBy: 0).label, "Collection<0>")
                XCTAssertEqual($0.staticTexts.element(boundBy: 1).label, "0")

                XCTAssertEqual($0.otherElements["ThumbView"].value as? String, "\(["empty","empty","empty"])")
            }
        }
        controllers("Album List - Custom") {
            window.collectionViews.element.map {
                XCTAssertEqual($0.exists, true)
            }
        }
        
        window.swipeUp()
        
        
        controllers("Albums - Empty") {
            window.collectionViews.element.map {
                XCTAssertEqual($0.exists, true)
                
                XCTAssertEqual(application.otherElements["ExceptionView"].exists, true)
                XCTAssertEqual(application.otherElements["ExceptionView"].frame, window.frame)
                
                XCTAssertEqual(application.staticTexts["No Photos or Videos"].exists, true)
                XCTAssertEqual(application.staticTexts["You can sync photos and videos onto your iPhone using iTunes."].exists, true)
            }
        }
        controllers("Albums - Error") {
            window.collectionViews.element.map {
                XCTAssertEqual($0.exists, true)
                
                XCTAssertEqual($0.exists, true)
                
                XCTAssertEqual(application.otherElements["ExceptionView"].exists, true)
                XCTAssertEqual(application.otherElements["ExceptionView"].frame, window.frame)
                
                XCTAssertEqual(application.staticTexts["No Access Permissions"].exists, true)
                XCTAssertEqual(application.staticTexts["Application does not have permission to access your photo."].exists, true)
            }
        }
        controllers("Albums - Regular") {
            window.collectionViews.element.map {
                XCTAssertEqual($0.exists, true)
            }
        }
        controllers("Albums - Moments") {
            window.collectionViews.element.map {
                XCTAssertEqual($0.exists, true)
            }
        }
        controllers("Albums - Moments & Regular & Recently") {
            window.collectionViews.element.map {
                XCTAssertEqual($0.exists, true)
            }
        }


        self.application.navigationBars.buttons["Debuging"].tap()
    }

    private var application: XCUIApplication!
}
