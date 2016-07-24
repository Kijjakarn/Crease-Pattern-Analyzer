class ReferenceFinder {
    var ε = 1e-8
    var εF: Float = 1e-8

    var maxRank = 4
    var axioms  = 1...7
    var paper   = Rectangle(bottomLeft: PointVector(0, 0),
                              topRight: PointVector(1, 1))

    let pointLabels = Array("LKJIHGFEDCBA".characters)
    let lineLabels  = Array("ZYXWVUTSRQPO".characters)

    // Number of horizontal partitions
    var numX = 5000

    // Number of vertical partitions
    var numY = 5000

    // Number of radial partitions
    var numRadius = 5000

    // Number of angle partitions
    var numAngle  = 5000

    // Minimum angle in degree between lines to define an intersection
    var minAngle  = 20.0

    // Maximum number of matches to display
    var maxNumMatches = 15

    // Maximum aspect ratio of a triangular or quadrilateral flap
    var maxAspectRatio = 10.0

    // Maximum acceptable angle error in degrees of a line to desired line
    var maxAngleError = 2.0

    // Maximum acceptable shift distance of a line to desired line
    var maxShiftError = 0.08

    // Maximum acceptable distance of a point to desired point
    var maxDistanceError = 0.05

    // Array containing sets of points, one set for each rank
    var allPoints = [Set<PointReference>]()

    // Array containing sets of lines, one set for each rank
    var allLines  = [Set<LineReference>]()

    static var singleton = ReferenceFinder()

    var inputPoint: PointVector!
    var inputLine: Line!

    private init() { }
}
