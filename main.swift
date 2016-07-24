/*----------------------------------------------------------------------------
                                Main Program
-----------------------------------------------------------------------------*/

var main = ReferenceFinder.singleton
makeAllPointsAndLines()
main.inputPoint = PointVector(0.322, 0.322)
var matchedPts = matchedPoints()
print("There are \(matchedPts.count) matched points")
matchedPts.sortInPlace { $0.distanceError < $1.distanceError }

print("\nTo get \(main.inputPoint) (error = \(matchedPts[0].distanceError)),")
printInstructions(point: matchedPts[0])

clearInstructions()
