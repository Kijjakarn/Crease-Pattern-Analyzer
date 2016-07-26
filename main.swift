/*----------------------------------------------------------------------------
                                Main Program
-----------------------------------------------------------------------------*/

var main = ReferenceFinder.singleton
makeAllPointsAndLines()

var parser = ShuntingYard()
var isParsed = false

var x = 0.0
var y = 0.0

while !isParsed {
    print("x-coordinate: ", terminator: "")
    let str = readLine(stripNewline: true)
    do {
        if let parsed = try parser.parse(str!) {
            print("x-coordinate is \(parsed)")
            x = parsed
            isParsed = true
        }
        else {
            print("Empty string")
        }
    }
    catch ParseError.NotEnoughOperands {
        print("Not enough operands")
    }
    catch ParseError.TooManyOperands {
        print("Too many operands")
    }
    catch ParseError.UnbalancedParenthesis {
        print("Unbalanced parenthesis")
    }
    catch ParseError.InvalidNumber {
        print("Invalid number")
    }
    catch ParseError.InvalidOperation {
        print("Invalid operation")
    }
    catch ParseError.ParseStackFailure {
        print("Stack failure")
    }
    catch ParseError.EmptyExpression {
        print("Cannot parse empty expression")
    }
}

isParsed = false
while !isParsed {
    print("y-coordinate: ", terminator: "")
    let str = readLine(stripNewline: true)
    do {
        if let parsed = try parser.parse(str!) {
            print("y-coordinate is \(parsed)")
            y = parsed
            isParsed = true
        }
        else {
            print("Empty string")
        }
    }
    catch ParseError.NotEnoughOperands {
        print("Not enough operands")
    }
    catch ParseError.TooManyOperands {
        print("Too many operands")
    }
    catch ParseError.UnbalancedParenthesis {
        print("Unbalanced parenthesis")
    }
    catch ParseError.InvalidNumber {
        print("Invalid number")
    }
    catch ParseError.InvalidOperation {
        print("Invalid operation")
    }
    catch ParseError.ParseStackFailure {
        print("Stack failure")
    }
    catch ParseError.EmptyExpression {
        print("Cannot parse empty expression")
    }
}

main.inputPoint = PointVector(x, y)
var matchedPts = matchedPoints()
print("There are \(matchedPts.count) matched points")
matchedPts.sortInPlace { $0.distanceError < $1.distanceError }

var i = 1
for matchedPt in matchedPts {
    print("\(i): \(matchedPt.point),\t\terror = \(matchedPt.distanceError)")
    i += 1
}

print("\nTo get \(main.inputPoint) (error = \(matchedPts[0].distanceError)),")
printInstructions(point: matchedPts[0])

clearInstructions()
