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

    @IBAction func openImage(_ sender: NSMenuItem) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["jpg", "jpeg", "png", "bmp"]
        openPanel.beginSheetModal(for: window!) {
            switch $0 {
            case NSFileHandlingPanelOKButton:
                if openPanel.urls.count == 0 {
                    break
                }
                let fileURL = openPanel.urls[0]
                OperationQueue().addOperation {
                    self.delegate.processImage(url: fileURL)
                }
            default:
                break
            }
        }
    }
}
