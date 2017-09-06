//
//  MainWindowController.swift
//  CreasePatternAnalyzer
//
//  Created by Kijjakarn Praditukrit on 11/19/16.
//  Copyright © 2016-2017 Kijjakarn Praditukrit. All rights reserved.
//

import Cocoa

var main = ReferenceFinder.singleton

@objc
protocol MainWindowControllerDelegate: class {
    func processImage(url: URL)
}

class MainWindowController: NSWindowController {
    let appDelegate = NSApplication.shared().delegate as! AppDelegate

    dynamic weak var delegate: MainWindowControllerDelegate!
}
