//
//  AppDelegate.swift
//  CreasePatternAnalyzer
//
//  Created by Kijjakarn Praditukrit on 11/19/16.
//  Copyright © 2016-2017 Kijjakarn Praditukrit. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var initializationQueue = OperationQueue()

    var mainWindowController: MainWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = NSWindow(
            contentRect: NSScreen.main()!.frame,
            styleMask: [.resizable, .titled, .closable],
            backing: .retained,
            defer: false
        )
        let mainWindowController = MainWindowController(window: window)
        window.title = "Crease Pattern Analyzer"
        let mainViewController = MainViewController()
        mainWindowController.contentViewController = mainViewController
        mainWindowController.delegate = mainViewController
        mainWindowController.showWindow(self)
        self.mainWindowController = mainWindowController
        initializationQueue.addOperation {
            makeAllPointsAndLines()
        }
    }
}
