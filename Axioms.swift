import Darwin

/*----------------------------------------------------------------------------
                    Huzita-Justin Axioms Implementations
   - All points and lines passed to these functions must be distinct
-----------------------------------------------------------------------------*/

// Axiom 1: Given two points p1 and p2, we can fold a line connecting them
func axiom1(p1: PointVector, _ p2: PointVector) -> Line? {
    let fold = Line(p1, p2)
    return main.paper.contains(fold) ? fold : nil
}

// Axiom 2: Given two points p1 and p2, we can fold p1 onto p2
func axiom2(p1: PointVector, _ p2: PointVector) -> Line? {
    let unitNormal = ((p1 - p2)/2).normalized()
    let midPoint = (p1 + p2)/2
    let fold = Line(point: midPoint, unitNormal: unitNormal)
    return main.paper.contains(fold) ? fold : nil
}

// Axiom 3: Given two lines line1 and line2, we can fold line1 onto line2
// - If lines are parallel, return one solution
// - Otherwise, return line(s) contained in the main.paper
func axiom3(line1: Line, _ line2: Line) -> [Line] {
    guard let p = intersection(line1, line2) else {
        return [Line(distance: (line1.distance + line2.distance)/2,
                     unitNormal: line1.unitNormal)]
    }
    let direction = ((line1.unitNormal
                  + line2.unitNormal)/2).normalized()
    let fold1 = Line(point: p, unitNormal: direction)
    let fold2 = Line(point: p, unitNormal: direction.rotatedBy90())
    var folds = [Line]()
    if main.paper.contains(fold1) { folds.append(fold1) }
    if main.paper.contains(fold2) { folds.append(fold2) }
    return folds
}

// Axiom 4: Given a point p and a line, we can make a fold perpendicular to the
//          line passing through the point p
func axiom4(point p: PointVector, line: Line) -> Line? {
    if main.paper.encloses(line.projectionOf(p)) {
        let fold = Line(point: p, unitNormal: line.unitNormal.rotatedBy90())
        return main.paper.contains(fold) ? fold : nil
    }
    return nil
}

// Axiom 5: Given two points p1 and p2 and a line, we can make a fold that
//          places p1 onto the line and passes through p2
// - This is the same as finding lines that go through p2 and the intersection
//   between the circle centered at p2 with radius |p2 - p1|
func axiom5(bring p1: PointVector, to line: Line, through p2: PointVector)
        -> [Line] {
    let radius = (p1 - p2).magnitude
    let centerToLine = line.unitNormal*(line.distance - line.unitNormal.dot(p2))

    // If the line does not intersect the circle
    if radius < centerToLine.magnitude {
        return []
    }
    // If the line is tangent to the circle
    if radius - centerToLine.magnitude < main.ε {
        return [Line(point: p2, unitNormal: line.unitNormal)]
    }
    let addVector = line.unitNormal.rotatedBy90()
                  * sqrt(radius*radius - centerToLine.magnitudeSquared())
    let point1 = centerToLine + p2 + addVector
    let point2 = centerToLine + p2 - addVector
    var folds = [Line]()
    if main.paper.encloses(point1) {
        let p11 = (p1 + point1)/2
        if p2 != p11 {
            folds.append(Line(p2, p11))
        }
    }
    if main.paper.encloses(point2) {
        let p12 = (p1 + point2)/2
        if p2 != p12 {
            folds.append(Line(p2, p12))
        }
    }
    return folds
}

// Axiom 6: Given two points p1 and p2 and two lines line1 and line2, we can
//          make a fold that places p1 onto line1 and places p2 onto line2
// - First transform the coordinate system by aligning line1 with the x-axis by
// - shifting and rotating, then put p1 on the y-axis by shifting
func axiom6(bring p1: PointVector, to line1: Line,
              and p2: PointVector, on line2: Line) -> [Line] {
    let u1  = line1.unitNormal
    let u2  = line2.unitNormal
    let u1P = u1.rotatedBy90()*(-1)
    let v1  = p1 - u1*line1.distance
    let v2  = p2 - u1*line1.distance
    let x1  = v1.dot(u1P)
    let x2  = v2.dot(u1P) - x1
    let y1  = v1.dot(u1)
    let y2  = v2.dot(u1)
    let u2x = u2.dot(u1P)
    let u2y = u2.dot(u1)
    let d2  = line2.distance - u2.dot(u1*line1.distance) - u2x*x1
    let yy  = 2*y2 - y1
    let z   = d2 - u2x*x2 - u2y*y2

    // Coefficients of the cubic equation
    let a   = u2x
    let b   = -(2*u2x*x2 + u2y*y1 + z)
    let c   = y1*(2*u2y*x2 + u2x*yy)
    let d   = -y1*y1*(u2y*yy + z)

    // Solve the equation and get the folded line
    let roots = solveCubic(a, b, c, d)
    var folds = [Line]()
    for root in roots {
        let p1Folded = u1*line1.distance + u1P*(root + x1)

        // If fold goes through p1 or main.paper doesn't enclose reflected point
        if p1 == p1Folded || !main.paper.encloses(p1Folded) { continue }
        let fold = Line(point: (p1 + p1Folded)/2, normal: (p1 - p1Folded))

        // If main.paper doesn't contain the fold or p1 and p2 aren't on the same
        // side of the main.paper
        if !main.paper.contains(fold) || (line1.distance - p1.dot(u1))
           * (line1.distance - p1.dot(u2)) < 0 { continue }
        let p2Folded = fold.reflectionOf(p2)

        // If fold doesn't enclose the reflected p2
        if !main.paper.encloses(p2Folded) { continue }
        folds.append(fold)
    }
    return folds
}

// Solve cubic equation of the form ax^3 + bx^2 + cx + d = 0
// - Use Cardano's formula
// - Return real solutions only
// - See https://proofwiki.org/wiki/Cardano%27s_Formula/Real_Coefficients
func solveCubic(a: Double , _ b: Double, _ c: Double, _ d: Double) -> [Double] {
    // The equation is not cubic
    if abs(a) < main.ε {
        if abs(b) < main.ε {
            // The equation is wrong or trivial
            if abs(c) < main.ε {
                return []
            }
            // The equation is linear
            return [-d/c]
        }
        // The equation is quadratic
        let discriminant = c*c - 4*b*d
        if discriminant < 0   { return [] }
        if discriminant < main.ε { return [-c/(2*b)] }
        let sqrtDiscriminant = sqrt(discriminant)
        let x1 = (-c + sqrtDiscriminant)/(2*b)
        let x2 = (-c - sqrtDiscriminant)/(2*b)
        return [x1, x2]
    }
    // The equation is cubic
    let q = (3*a*c - b*b)/(9*a*a)
    let r = (9*a*b*c - 27*a*a*d - 2*b^^3)/(54*a^^3)
    let discriminant = q^^3 + r^^2

    // All roots are real and distinct
    if discriminant < 0 {
        let θ = acos(r/sqrt(-q^^3))/3
        let e = 2*sqrt(-q)
        let f = b/(3*a)
        let x1 = e*cos(θ) - f
        let x2 = e*cos(θ + 2*π/3) - f
        let x3 = e*cos(θ + 4*π/3) - f
        return [x1, x2, x3]
    }
    // All roots are real and at least two are equal
    if discriminant < main.ε {
        // There is only one real root
        if r == 0 { return [-b/(3*a)] }
        let e = cbrt(r)
        let f = b/(3*a)
        let x1 = 2*e - f
        let x2 = -e - f
        return [x1, x2]
    }
    // There is one real root and the other two are complex conjugates
    let sqrtOfDiscriminant = sqrt(discriminant)
    let x1 = cbrt(r + sqrtOfDiscriminant)
           + cbrt(r - sqrtOfDiscriminant) - b/(3*a)
    return [x1]
}

// Axiom 7: Given a point p and two lines line1 and line2, we can make a fold
//          perpendicular to line2 that places p onto line1
func axiom7(bring p: PointVector, to line1: Line, along line2: Line) -> Line? {
    let u1  = line1.unitNormal
    let u2  = line2.unitNormal
    let u2P = u2.rotatedBy90()
    let foldDistance = (line1.distance - p.dot(u1))
                     / (2*u2P.dot(u1)) + p.dot(u2P)
    let fold = Line(distance: foldDistance, unitNormal: u2P)
    if (main.paper.encloses(fold.reflectionOf(p))
    && main.paper.contains(fold)) {
        return fold
    }
    return nil
}
