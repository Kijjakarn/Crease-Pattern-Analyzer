//
//  MainSplitViewController.swift
//  CreasePatternAnalyzer
//
//  Created by Kijjakarn Praditukrit on 11/19/16.
//  Copyright © 2016-2017 Kijjakarn Praditukrit. All rights reserved.
//

import Cocoa

class MainSplitViewController: NSSplitViewController,
                               MainWindowControllerDelegate,
                               PointViewControllerDelegate,
                               ConfigurationViewControllerDelegate,
                               InstructionViewControllerDelegate,
                               DiagramViewDelegate
{

    var tabVC:           NSTabViewController!
    // TODO
    // var lineVC:          LineViewController!
    var pointVC:         PointViewController!
    var configurationVC: ConfigurationViewController!
    var instructionVC:   InstructionViewController!
    var diagramView:     DiagramView!

    dynamic var hasFinishedInitialization = false

    let initializationQueue =
        (NSApplication.shared().delegate as! AppDelegate).initializationQueue

    var buttons: [NSButton]!

    override func viewDidLoad() {
        super.viewDidLoad()

        let leftPanelVC = childViewControllers[0]
            as! NSSplitViewController
        tabVC = leftPanelVC.childViewControllers[0]
            as! NSTabViewController
        pointVC = tabVC.childViewControllers[0]
            as! PointViewController
        configurationVC = leftPanelVC.childViewControllers[1]
            as! ConfigurationViewController
        instructionVC = childViewControllers[1]
            as! InstructionViewController
        diagramView = instructionVC.diagramView

        // Set the delegates
        pointVC.delegate         = self
        configurationVC.delegate = self
        instructionVC.delegate   = self

        initializationQueue.addObserver(
            self,
            forKeyPath: #keyPath(OperationQueue.operationCount),
            context: nil
        )
    }

    override func observeValue(forKeyPath keyPath: String?,
                                        of object: Any?,
                                           change: [NSKeyValueChangeKey : Any]?,
                                          context: UnsafeMutableRawPointer?) {
        // Disable all buttons if solutions are being initialized
        if keyPath == "operationCount" {
            hasFinishedInitialization = initializationQueue.operationCount == 0
            CATransaction.commit()
        }
    }

    // MARK: - MainWindowControllerDelegate

    // Load and perform Hough transform on image
    func processImage(url: URL) {
        let image: BinaryImage
        do {
            try image = BinaryImage(fileURL: url)
            try image.write(appending: " binarized")
            image.thin()
            try image.write(appending: " thinned")
            var diagram = Diagram()
            diagram.lineSegments = getLineSegments(binaryImage: image.result).map {
                (p1, p2) in
                let width  = Double(image.width)
                let height = Double(image.height)
                return (PointVector(p1.0/width, (height - p1.1)/width),
                        PointVector(p2.0/width, (height - p2.1)/width))
            }
            main.paper = Rectangle(
                width: 1,
                height: Double(image.height)/Double(image.width)
            )
            diagramView.diagram = diagram
            diagramView.drawAll()
            CATransaction.commit()
        }
        catch {
            print("Cannot process image")
        }
    }

    // MARK: - PointViewControllerDelegate

    func emptyInstructions() {
        main.diagrams.removeAll()
        main.instructions.removeAll()
        instructionVC.enableNextButton = false
        instructionVC.instruction.string = ""
        instructionVC.diagramView.diagram = Diagram()
        instructionVC.diagramView.drawAll()
    }

    // MARK: - ConfigurationViewControllerDelegate

    func reinitialize() {
        // Remove all found points in table
        pointVC.arrayController.content = nil
        pointVC.foundPoints.removeAll()

        // Update paper
        emptyInstructions()

        // Cancel current initialization
        initializationQueue.cancelAllOperations()
        initializationQueue.waitUntilAllOperationsAreFinished()
        let width  = configurationVC.width
        let height = configurationVC.height
        main.paper = Rectangle(width: 1, height: height/width)
        initializationQueue.addOperation {
            makeAllPointsAndLines()
        }
    }

    // MARK: - DiagramViewDelegate

    func update(beginPoint: PointVector) {
        if let currentVC = tabVC.tabView.selectedTabViewItem?.viewController,
           currentVC is PointViewController {
            updatePoint(withPoint: beginPoint)
        }
        else {
            // TODO
        }
    }

    func update(endPoint: PointVector) {
        if let currentVC = tabVC.tabView.selectedTabViewItem?.viewController,
           currentVC is PointViewController {
            updatePoint(withPoint: endPoint)
        }
        else {
            // TODO
        }
    }

    func update(draggedPoint: PointVector) {
        if let currentVC = tabVC.tabView.selectedTabViewItem?.viewController,
           currentVC is PointViewController {
            updatePoint(withPoint: draggedPoint)
        }
        else {
            // TODO
        }
    }

    func updatePoint(withPoint point: PointVector) {
        pointVC.xInput.stringValue = ""
        pointVC.yInput.stringValue = ""
        pointVC.x = point.x
        pointVC.y = point.y
        pointVC.isXValid = true
        pointVC.isYValid = true
    }

    func updateDiagram() {
        diagramView.drawAll()
    }
}
