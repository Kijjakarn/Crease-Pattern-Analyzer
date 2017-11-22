//
//  AppDelegate.swift
//  CreasePatternAnalyzer
//
//  Created by Kijjakarn Praditukrit on 11/19/16.
//  Copyright © 2016-2017 Kijjakarn Praditukrit. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    let applicationName = Bundle.main.infoDictionary?["CFBundleName"] as! String

    var mainViewController:   MainViewController!
    var mainWindowController: NSWindowController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = NSWindow(
            contentRect: NSScreen.main!.frame,
            styleMask: [.resizable, .titled, .closable],
            backing: .retained,
            defer: false
        )
        let mainWindowController = NSWindowController(window: window)
        window.title = applicationName
        mainViewController = MainViewController()
        mainWindowController.contentViewController = mainViewController
        mainWindowController.showWindow(self)
        self.mainWindowController = mainWindowController
        setUpMenu()
    }

    func setUpMenu() {
        let mainMenu = NSMenu()
        NSApplication.shared.mainMenu = mainMenu

        let mainMenuItem = NSMenuItem()
        mainMenu.addItem(mainMenuItem)
        let mainMenuMenu = NSMenu()
        mainMenuItem.submenu = mainMenuMenu

        let quitApplicationItem = NSMenuItem(
            title: "Quit \(applicationName)",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitApplicationItem.keyEquivalentModifierMask = .command
        quitApplicationItem.target = NSApplication.shared
        mainMenuMenu.addItem(quitApplicationItem)

        let fileMenuItem = NSMenuItem()
        mainMenu.addItem(fileMenuItem)
        let fileMenu = NSMenu(title: "File")
        fileMenuItem.submenu = fileMenu

        let openImageItem = NSMenuItem(
            title: "Load Image",
            action: #selector(AppDelegate.openImage),
            keyEquivalent: "o"
        )
        openImageItem.keyEquivalentModifierMask = .command
        openImageItem.target = self
        fileMenu.addItem(openImageItem)
    }

    @objc func openImage() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["jpg", "jpeg", "png", "bmp"]
        openPanel.beginSheetModal(for: mainWindowController.window!) {
            switch $0 {
            case .OK:
                if openPanel.urls.count == 0 {
                    break
                }
                let fileURL = openPanel.urls[0]
                self.mainViewController.processImage(url: fileURL)
            default:
                break
            }
        }
    }
}
