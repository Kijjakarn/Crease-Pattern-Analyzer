//
//  MainViewController.swift
//  CreasePatternAnalyzer
//
//  Created by Kijjakarn Praditukrit on 11/19/16.
//  Copyright © 2016-2017 Kijjakarn Praditukrit. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController,
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

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tabVC           = NSTabViewController()
        pointVC         = PointViewController()
        configurationVC = ConfigurationViewController()
        instructionVC   = InstructionViewController()

        diagramView = DiagramView()
        diagramView.delegate = self
        instructionVC.diagramView = diagramView

        let tabView           = tabVC.view
        let pointView         = pointVC.view
        let configurationView = configurationVC.view
        let instructionView   = instructionVC.view

        let pointVCItem = NSTabViewItem(identifier: "PointViewController")
        pointVCItem.label = "Point"
        pointVCItem.viewController = pointVC
        tabVC.addTabViewItem(pointVCItem)

        let leftPanelView = NSStackView(views: [tabView, configurationView])
        leftPanelView.orientation = .vertical
        leftPanelView.distribution = .fillEqually
        leftPanelView.alignment = .left
        view.addSubview(leftPanelView)
        view.addSubview(instructionView)

        leftPanelView.translatesAutoresizingMaskIntoConstraints     = false
        tabView.translatesAutoresizingMaskIntoConstraints           = false
        configurationView.translatesAutoresizingMaskIntoConstraints = false
        instructionView.translatesAutoresizingMaskIntoConstraints   = false
        view.translatesAutoresizingMaskIntoConstraints              = false

        leftPanelView.rightAnchor
                     .constraint(equalTo: instructionView.leftAnchor)
                     .isActive = true;

        tabView.widthAnchor
               .constraint(equalTo: configurationView.widthAnchor)
               .isActive = true;

        NSLayoutConstraint.activate([
            view.topAnchor
                .constraint(equalTo: tabView.topAnchor),
            view.topAnchor
                .constraint(equalTo: instructionView.topAnchor),
            view.bottomAnchor
                .constraint(equalTo: configurationView.bottomAnchor),
            view.bottomAnchor
                .constraint(equalTo: instructionView.bottomAnchor),
            view.leftAnchor
                .constraint(equalTo: leftPanelView.leftAnchor),
            view.rightAnchor
                .constraint(equalTo: instructionView.rightAnchor),
            view.widthAnchor
                .constraint(greaterThanOrEqualToConstant: 1000),
            view.heightAnchor
                .constraint(greaterThanOrEqualToConstant: 700),
        ])

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
            let binarizedImage = image.result
            try image.write(appending: " binarized")
            image.thin()
            try image.write(appending: " thinned")
            var diagram = Diagram()
            let width = Double(image.width)
            let height = image.height
            // diagram.lineSegments = getLineSegments(
            //     binaryImage: image.result,
            //     comparisonImage: binarizedImage
            // ).map {
            //     (p1, p2) in
            //     let width  = Double(image.width)
            //     let height = Double(image.height)
            //     return (PointVector(p1.0/width, (height - p1.1)/width),
            //             PointVector(p2.0/width, (height - p2.1)/width))
            // }
            diagram.lineSegments = houghLinesProbabilistic(
                binaryImage: binarizedImage,
                thetaResolution: Double.pi/180,
                rhoResolution: 1,
                threshold: 40,
                minLength: 3,
                maxGap: 10
            ).map { (p1, p2) in
                (PointVector(Double(p1.0)/width, Double((height - p1.1))/width),
                 PointVector(Double(p2.0)/width, Double((height - p2.1))/width))
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

    // MARK: DiagramViewDelegate

    var inputPoint: PointVector {
        return PointVector(pointVC.x, pointVC.y)
    }

    func diagramView(_: DiagramView, didUpdateBeginPoint point: PointVector) {
        if let currentVC = tabVC.tabView.selectedTabViewItem?.viewController,
           currentVC is PointViewController {
            updatePoint(withPoint: point)
        }
        else {
            // TODO
        }
    }

    func diagramView(_: DiagramView, didUpdateDraggedPoint point: PointVector) {
        if let currentVC = tabVC.tabView.selectedTabViewItem?.viewController,
           currentVC is PointViewController {
            updatePoint(withPoint: point)
        }
        else {
            // TODO
        }
    }

    func diagramView(_: DiagramView, didUpdateEndPoint point: PointVector) {
        if let currentVC = tabVC.tabView.selectedTabViewItem?.viewController,
           currentVC is PointViewController {
            updatePoint(withPoint: point)
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
