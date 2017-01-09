//
//  MainWindowController.swift
//  CreasePatternAnalyzer
//
//  Created by Kijjakarn Praditukrit on 11/19/16.
//  Copyright © 2016 Kijjakarn Praditukrit. All rights reserved.
//

import Cocoa

var main: ReferenceFinder = ReferenceFinder.singleton

class MainWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()

        // Display initialization status

        makeAllPointsAndLines()
    }

}
