//
//  LeftPanelViewController.swift
//  CreasePatternAnalyzer
//
//  Created by Kijjakarn Praditukrit on 11/19/16.
//  Copyright © 2016 Kijjakarn Praditukrit. All rights reserved.
//

import Cocoa

class PointPanelViewController: NSViewController {
    var x: Double = 0
    var y: Double = 0

    var xString = ""
    var yString = ""

    @IBOutlet weak var xTextField: NSTextField!
    @IBOutlet weak var yTextField: NSTextField!

    @IBAction
    func updateCoordinates(_ sender: NSButton) {
        let parsedX = Parser.parsedString(from: xTextField.stringValue)
        let parsedY = Parser.parsedString(from: yTextField.stringValue)
        if parsedX.success { self.x = parsedX.value }
        if parsedY.success { self.y = parsedY.value }
        xString = parsedX.string
        yString = parsedY.string
    }

    override var nibName: String? {
        return "PointPanelViewController"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
