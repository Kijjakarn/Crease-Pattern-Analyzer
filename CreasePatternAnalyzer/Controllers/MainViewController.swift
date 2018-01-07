//
//  MainViewController.swift
//  CreasePatternAnalyzer
//
//  Created by Kijjakarn Praditukrit on 11/19/16.
//  Copyright © 2016-2017 Kijjakarn Praditukrit. All rights reserved.
//

import Cocoa

var main = ReferenceFinder.singleton

class MainViewController: NSViewController,
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

    let initializationQueue = DispatchQueue(label: "Initialization Queue")
    @objc dynamic var hasFinishedInitialization = false

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

        // Start the initialization
        initialize()
    }

    // MARK: - MainWindowControllerDelegate

    // Load and perform Hough transform on image
    func processImage(url: URL) {
        stopInitialization()
        DispatchQueue(label: "Open Image").async {
            let image: BinaryImage
            do {
                try image = BinaryImage(fileURL: url)
                let binarizedImage = image.result
                try image.write(appending: " binarized")
                image.thin()
                try image.write(appending: " thinned")
                var diagram = Diagram()
                diagram.lineSegments = getLineSegments (
                    binaryImage: binarizedImage,
                    comparisonImage: binarizedImage
                ).map {
                    (arg) in
                    let (p1, p2) = arg
                    let width  = Double(image.width)
                    let height = Double(image.height)
                    return (PointVector(p1.0/width, (height - p1.1)/width),
                            PointVector(p2.0/width, (height - p2.1)/width))
                }
                DispatchQueue.main.async {
                    main.paper = Rectangle(
                        width: 1,
                        height: Double(image.height)/Double(image.width)
                    )
                    self.reinitialize()
                    self.initializationQueue.async {
                        DispatchQueue.main.async {
                            self.diagramView.diagram = diagram
                            self.diagramView.drawAll()
                        }
                    }
                }
            }
            catch {
                print("Cannot process image")
            }
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
        // Stop the current initialization
        main.shouldStopInitialization = true

        initializationQueue.async {
            DispatchQueue.main.async {
                // Remove all found points in table
                self.pointVC.foundPoints.removeAll()
                self.emptyInstructions()

                // Update paper
                let width  = self.configurationVC.width
                let height = self.configurationVC.height
                main.paper = Rectangle(width: 1, height: height/width)

                self.initialize()
            }
        }
    }

    func initialize() {
        main.shouldStopInitialization = false
        hasFinishedInitialization = false
        initializationQueue.async {
            makeAllPointsAndLines()
            DispatchQueue.main.async {
                self.hasFinishedInitialization = true
            }
        }
    }

    func stopInitialization() {
        main.shouldStopInitialization = true
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
