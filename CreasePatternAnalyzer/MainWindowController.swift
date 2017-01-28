//
//  MainWindowController.swift
//  CreasePatternAnalyzer
//
//  Created by Kijjakarn Praditukrit on 11/19/16.
//  Copyright © 2016-2017 Kijjakarn Praditukrit. All rights reserved.
//

import Cocoa

var main = ReferenceFinder.singleton

class MainWindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        window!.title = "Crease Pattern Analyzer"

        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        appDelegate.initializationQueue.addOperation {
            makeAllPointsAndLines()
        }
    }
}
