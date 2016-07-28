import Darwin

// A reference to a point obtained from an intersection of two lines
class PointReference: Hashable {
    let point: PointVector
    let firstLine: LineReference
    let secondLine: LineReference
    
    var rank = 0

    var distanceError = DBL_MAX

    var label: String = "_"

    var hashValue: Int {
        return point.hashValue
    }

    init(_ firstLine: LineReference, _ secondLine: LineReference,
         _ point: PointVector, _ rank: Int) {
        self.firstLine  = firstLine
        self.secondLine = secondLine
        self.point      = point
        self.rank       = rank
    }

    init(_ firstLine: LineReference, _ secondLine: LineReference,
         _ point: PointVector, label: String) {
        self.label      = label
        self.firstLine  = firstLine
        self.secondLine = secondLine
        self.point      = point
    }
}

class LineReference: Hashable {
    let line: Line
    let axiom: Axiom?

    var rank = 0

    var shiftError = DBL_MAX
    var angleError = DBL_MAX

    var label: String = "_"

    var hashValue: Int {
        return line.hashValue
    }

    init(_ line: Line, label: String) {
        self.line  = line
        self.axiom = nil
        self.label = label
    }

    init(_ line: Line, _ axiom: Axiom, _ rank: Int) {
        self.line  = line
        self.axiom = axiom
        self.rank  = rank
    }
}

enum Axiom {
    case A1(PointReference, PointReference)
    case A2(PointReference, PointReference)
    case A3(LineReference,  LineReference)
    case A4(PointReference, LineReference)
    case A5(PointReference, LineReference, PointReference)
    case A6(PointReference, LineReference, PointReference, LineReference)
    case A7(PointReference, LineReference, LineReference)
}

func ==(first: PointReference, second: PointReference) -> Bool {
    return first.point == second.point
}

func ==(first: LineReference, second: LineReference) -> Bool {
    return first.line == second.line
}
