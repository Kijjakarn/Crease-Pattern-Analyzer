import Cocoa

typealias Point = (Double, Double)
typealias PointInt = (Int, Int)

extension Bool {
    var int: Int {
        return self ? 1 : 0
    }
}

enum ImageProcessingError: Error {
    case unsupportedFileType
    case fileDoesNotExist
}

class BinaryImage {
    let image: CGImage
    let name:  String
    let url:   URL

    var result: [[Bool]]
    let width:  Int
    let height: Int

    func write(appending word: String) throws {
        let rawBitmap = CFDataCreateMutable(nil, width*height)
        let fileName = url.deletingPathExtension()
                          .absoluteString
                          .replacingOccurrences(of: "file://", with: "")
                          .removingPercentEncoding!
                     + word + "." + url.pathExtension
        for j in 0..<height {
            for i in 0..<width {
                var pixelValue: UInt8 = result[i][j] ? 0 : 255
                CFDataAppendBytes(rawBitmap, &pixelValue, 1)
            }
        }
        let outputCGImage = CGImage(width: image.width,
                                   height: image.height,
                         bitsPerComponent: 8,
                             bitsPerPixel: 8,
                              bytesPerRow: image.width,
                                    space: CGColorSpaceCreateDeviceGray(),
                               bitmapInfo: CGBitmapInfo(rawValue: 0),
                                 provider: CGDataProvider(data: rawBitmap!)!,
                                   decode: nil,
                        shouldInterpolate: false,
                                   intent: CGColorRenderingIntent.defaultIntent)

        let outputNSImage  = NSImage(cgImage: outputCGImage!, size: NSSize())
        let outputTIFFData = outputNSImage.tiffRepresentation!
        let outputImageRep = NSBitmapImageRep(data: outputTIFFData)
        let fileType: NSBitmapImageRep.FileType

        switch (name as NSString).pathExtension {
        case "png" :  fileType = .png
        case "jpg" :  fileType = .jpeg
        case "jpeg":  fileType = .jpeg
        case "gif" :  fileType = .gif
        case "bmp" :  fileType = .bmp
        default    :     throw ImageProcessingError.unsupportedFileType
        }

        let outputData = outputImageRep!.representation(using: fileType,
                                                   properties: [:])!
        _ = FileManager.default.createFile(atPath: fileName,
                                         contents: outputData)
        Swift.print("\(fileName) written")
    }

    // See: http://fourier.eng.hmc.edu/e161/lectures/morphology/node2.html
    func erode() {
        for k in 0...1 {
            var shouldRemove = Array(
                repeating: Array(repeating: false, count: height),
                count: width
            )
            for i in 1..<(width - 1) {
                for j in 1..<(height - 1) {
                    if result[i][j] {
                        let p2 = result[  i  ][j - 1]
                        let p3 = result[i + 1][j - 1]
                        let p4 = result[i + 1][  j  ]
                        let p5 = result[i + 1][j + 1]
                        let p6 = result[  i  ][j + 1]
                        let p7 = result[i - 1][j + 1]
                        let p8 = result[i - 1][  j  ]
                        let p9 = result[i - 1][j - 1]
                        let s = (!p2 && p3).int + (!p3 && p4).int
                              + (!p4 && p5).int + (!p5 && p6).int
                              + (!p6 && p7).int + (!p7 && p8).int
                              + (!p8 && p9).int + (!p9 && p2).int
                        let n = p2.int + p3.int + p4.int + p5.int
                              + p6.int + p7.int + p8.int + p9.int
                        if s == 1
                        && 2 <= n && n <= 6
                        && !(k == 0 ? (p2 && p4 && p6) : (p2 && p4 && p8))
                        && !(k == 0 ? (p4 && p6 && p8) : (p2 && p6 && p8))
                        {
                            shouldRemove[i][j] = true
                        }
                    }
                }
            }
            for i in 1..<(width - 1) {
                for j in 0..<(height - 1) {
                    if shouldRemove[i][j] {
                        result[i][j] = false;
                    }
                }
            }
        }
    }

    func thin() {
        var oldResult = result
        var shouldRepeat = false
        repeat {
            shouldRepeat = false
            erode()
            outerLoop:
                for i in 0..<width {
                    for j in 0..<height {
                        if oldResult[i][j] != result[i][j] {
                            shouldRepeat = true
                            break outerLoop
                        }
                    }
                }
            oldResult = result
        }
        while shouldRepeat
    }

    // Remove pixels without an immediate neighbor
    // Won't be used anywhere
    func removeNoise() {
        for i in 1..<(width - 2) {
            for j in 1..<(height - 2) {
                if result[i][j] && !(result[  i  ][j - 1]
                                  || result[i - 1][j - 1]
                                  || result[i + 1][j - 1]
                                  || result[i - 1][  j  ]
                                  || result[i + 1][  j  ]
                                  || result[  i  ][j + 1]
                                  || result[i - 1][j + 1]
                                  || result[i + 1][j + 1])
                {
                    result[i][j] = false
                }
            }
        }
    }

    init(fileURL: URL) throws {
        // Create a CGImage through an NSImage
        guard var image = NSImage(
            byReferencing: fileURL)
            .cgImage(forProposedRect: nil,
                             context: nil,
                               hints: nil
        )
        else {
            throw ImageProcessingError.fileDoesNotExist
        }
        // Convert the image to gray scale color space
        guard let context = CGContext(
            data: nil,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: image.width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        )
        else {
            throw ImageProcessingError.unsupportedFileType
        }
        context.draw(
            image,
            in: CGRect(x: 0, y: 0, width: image.width, height: image.height)
        )
        image = context.makeImage()!

        // Perform checks on the image's file type
        guard let rawBitmap = image.dataProvider?.data else {
            throw ImageProcessingError.unsupportedFileType
        }
        self.image = image
        name   = fileURL.absoluteString
        url    = fileURL
        width  = image.width
        height = image.height
        let pixelsCount = width*height

        // Create a gray-scale image from the pixel values
        var grayImage = Array(
            repeating: Array(repeating: UInt8(0), count: height),
            count: width
        )
        var currentX = 0
        var currentY = 0
        for i in 0..<pixelsCount {
            var value: UInt8 = 0
            CFDataGetBytes(rawBitmap, CFRange(location: i, length: 1), &value)
            if Int(currentX) >= width {
                currentX = 0
                currentY += 1
            }
            grayImage[currentX][currentY] = value
            currentX += 1
        }
        let blurredImage = gaussianBlur(image: grayImage)
        // let blurredImage = grayImage

        // Find the binarization threshold using Otsu's method
        var histogram = Array(repeating: 0, count: 256)
        for i in 0..<width {
            for j in 0..<height {
                let value = blurredImage[i][j]
                histogram[Int(value)] += 1
            }
        }
        let threshold = UInt8(otsu(histogram: histogram,
                                 valuesCount: pixelsCount))

        // Count the number of pixels that have less than average pixel value
        // These pixels will be assigned to true; the others to false
        var pixelsCountLess = 0
        for i in 0..<width {
            for j in 0..<height {
                if blurredImage[i][j] < threshold {
                    pixelsCountLess += 1
                }
            }
        }
        // Remap gray values to binary
        var shouldAssignTrue: (UInt8) -> Bool = { $0 >= threshold }
        if 2*pixelsCountLess < pixelsCount {
            shouldAssignTrue = { $0 <= threshold }
        }
        result = Array(repeating: Array(repeating: false, count: image.height),
                           count: image.width)
        for i in 0..<width {
            for j in 0..<height {
                result[i][j] = shouldAssignTrue(blurredImage[i][j])
            }
        }
    }
}

func gaussianBlur(image: [[UInt8]]) -> [[UInt8]] {
    if image.isEmpty {
        return []
    }
    let width = image.count
    let height = image[0].count

    // Kernel with radius = 1 and sigma = 0.15
    let kernel: [Double] = [0.000429, 0.999142, 0.000429]

    // Kernel with radius = 1 and sigma = 0.30
    // let kernel: [Double] = [0.04779, 0.90442, 0.04779]
    let radius = (kernel.count - 1)/2
    var imageV: [[Double]] = image.map { $0.map {
        (element: UInt8) in return Double(element)
    }}
    // 1D Gausssian blur in the vertical direction
    for i in 0..<width {
        for j in radius..<(height - radius) {
            var value = 0.0
            for k in 0..<kernel.count {
                value += kernel[k]*Double(image[i][j + k - radius])
            }
            imageV[i][j] = value
        }
    }
    // 1D Gausssian blur in the horizontal direction
    var imageVH = imageV
    for j in 0..<height {
        for i in radius..<(width - radius) {
            var value = 0.0
            for k in 0..<kernel.count {
                value += kernel[k]*imageV[i + k - radius][j]
            }
            imageVH[i][j] = value
        }
    }
    return imageVH.map { $0.map {
        (element: Double) in return UInt8(element)
    }}
}

func otsu(histogram: [Int], valuesCount: Int) -> Int {
    var sum = 0
    for i in 0..<histogram.count {
        sum += i*histogram[i]
    }
    var sumB = 0
    var wB = 0
    var wF = 0
    var varianceMax = 0
    var threshold = 0
    for i in 0..<histogram.count {
        wB += histogram[i]
        if wB == 0 {
            continue
        }
        wF = valuesCount - wB
        if wF == 0 {
            break
        }
        sumB += i*histogram[i]
        let mB = sumB/wB
        let mF = (sum - sumB)/wF

        // Variance between classes
        let varianceBetween = wB*wF*(mB - mF)*(mB - mF)

        if varianceBetween > varianceMax {
            varianceMax = varianceBetween
            threshold = i
        }
    }
    return threshold
}

// For debugging only
func print<T>(_ data: [[T]]) {
    print()
    for element in data {
        print(element)
    }
    print()
}

// Find the center of a window within the array with the largest sum
func maxIndex(in accumulator: [[Int]], radius: Int) -> (Int, Int) {
    let thetasCount = accumulator.count
    let rhosCount   = accumulator[0].count

    assert(2*radius + 1 <= thetasCount && 2*radius + 1 <= rhosCount,
           "Window exceeds the bounds of the accumulator")

    // Sum the accumulator in the horizontal direction and put it in sumH
    var sumH = Array(
        repeating: Array(repeating: 0, count: rhosCount),
        count: thetasCount - 2*radius
    )
    for j in 0..<rhosCount {
        for i in 0...(2*radius) {
            sumH[0][j] += accumulator[i][j]
        }
        for i in (radius + 1)..<(thetasCount - radius) {
            sumH[i - radius][j] = sumH[i - radius - 1][j]
                                + accumulator[i + radius][j]
                                - accumulator[i - radius - 1][j]
        }
    }

    // Sum sumH in the vertical direction in and put it in sumV
    var sumV = Array(
        repeating: Array(repeating: 0, count: rhosCount - 2*radius),
        count: sumH.count
    )
    for i in 0..<sumV.count {
        for j in 0...(2*radius) {
            sumV[i][0] += sumH[i][j]
        }
        for j in (radius + 1)..<(rhosCount - radius) {
            sumV[i][j - radius] = sumV[i][j - radius - 1]
                                + sumH[i][j + radius]
                                - sumH[i][j - radius - 1]
        }
    }

    // Find the index of the maximum value in sumV
    var thetaIndex = 0
    var rhoIndex   = 0
    var maxValue   = -1
    for i in 0..<sumV.count {
        for j in 0..<sumV[i].count {
            if sumV[i][j] > maxValue {
                thetaIndex = i
                rhoIndex   = j
                maxValue   = sumV[i][j]
            }
        }
    }

    return (thetaIndex + radius, rhoIndex + radius)
}

// Return the accumulator array for the given image
// theta is in range [0º, 180º], with an increment of `thetaFraction`
// rho is in the range [-diagonal, digonal] with an increment of `rhoFraction`
func houghTransform(binaryImage image: [[Bool]],
        thetaFraction: Int, rhoFraction: Int) -> [[Int]] {
    let width       = image.count
    let height      = image[0].count
    let diagonal    = sqrt(Double(width*width + height*height))
    let rhoOffset   = Int(floor(diagonal))*rhoFraction
    let rhosCount   = 2*rhoOffset + 1
    let thetasCount = 181*thetaFraction
    var accumulator = Array(repeating: Array(repeating: 0, count: rhosCount),
                                count: thetasCount)
    for x in 0..<width {
        for y in 0..<height {
            if image[x][y] {
                for thetaIndex in 0..<thetasCount {
                    let theta = Double(thetaIndex)/Double(thetaFraction)*π/180
                    let rho = Double(x)*cos(theta) + Double(y)*sin(theta)
                    let rhoIndex = rhoOffset + Int(rho)*rhoFraction
                    accumulator[thetaIndex][rhoIndex] += 1
                }
            }
        }
    }
    return accumulator
}

// Perform Hough transform, with the origin placed at the center of the image
func houghTransformCenter(binaryImage image: [[Bool]],
        thetaFraction: Int, rhoFraction: Int) -> [[Int]] {
    let width       = image.count
    let height      = image[0].count
    let midX        = Double(width)/2
    let midY        = Double(height)/2
    let diagonal    = sqrt((Double(width*width) + Double(height*height))/4)
    let rhoOffset   = Int(floor(diagonal))*rhoFraction
    let rhosCount   = 2*rhoOffset + 1
    let thetasCount = 181*thetaFraction
    var accumulator = Array(repeating: Array(repeating: 0, count: rhosCount),
                                count: thetasCount)
    for x in 0..<width {
        for y in 0..<height {
            if image[x][y] {
                for thetaIndex in 0..<thetasCount {
                    let theta = Double(thetaIndex)/Double(thetaFraction)*π/180
                    let rho = (Double(x) - midX)*cos(theta)
                            + (Double(y) - midY)*sin(theta)
                    let rhoIndex = rhoOffset + Int(rho)*rhoFraction
                    accumulator[thetaIndex][rhoIndex] += 1
                }
            }
        }
    }
    return accumulator
}

// Find the intersections between the line defined by (theta, rho) and the
// rectangle with dimensions width × height with bottom left corner at (0, 0)
// theta is in radians
func clip(width w: Double, height h: Double,
            theta: Double, rho: Double) -> [Point] {
    var intersections = [Point]()
    let sinTheta  = sin(theta)
    let cosTheta  = cos(theta)
    let wCosTheta = w*cosTheta
    let hSinTheta = h*sinTheta

    // Check intersection with the edge ((0, 0), (w, 0))
    if cosTheta >= 0 && 0 < rho && rho <= wCosTheta
    ||         wCosTheta <= rho && rho < 0 {
        intersections.append((rho/cosTheta, 0))
    }
    // Check intersection with the edge ((0, 0), (0, h))
    if sinTheta >= 0 && 0 <= rho && rho < hSinTheta
    ||           hSinTheta < rho && rho <= 0 {
        intersections.append((0, rho/sinTheta))
    }
    // Check intersection with the edge ((0, h), (w, h))
    var parameter = rho - h*sin(theta)
    if cosTheta >= 0 && 0 <= parameter && parameter < wCosTheta
    ||           wCosTheta < parameter && parameter <= 0 {
        intersections.append((parameter/cosTheta, h))
    }
    // Check intersection with the edge ((w, 0), (w, h))
    parameter = rho - w*cos(theta)
    if sinTheta >= 0 && 0 < parameter && parameter <= hSinTheta
    ||         hSinTheta <= parameter && parameter < 0 {
        intersections.append((w, parameter/sinTheta))
    }

    return intersections
}

// Sum the pixel values of the 3 x 3 square centered at (x, y)
// A neighbor that is out of bounds is considered to have a value of 0
func neighboringPixelsValue(image: [[Bool]], x: Int, y: Int, radius: Int = 1)
        -> Int {
    let width  = image.count
    let height = image[0].count
    if x < 0 || x >= width || y < 0 || y >= height {
        return 0
    }
    var sum = 0
    for i in (x - radius)...(x + radius) {
        if 0 <= i && i < width {
            for j in (y - radius)...(y + radius) {
                if 0 <= j && j < height {
                    sum += image[i][j] ? 1 : 0
                }
            }
        }
    }
    return sum
}

/* // Sum the pixel values of the 3 x 3 square centered at (x, y)
// A neighbor that is out of bounds is considered to have a value of 0
func neighboringPixelsValue(image: [[Bool]], x: Int, y: Int, radius: Int = 1)
        -> Int {
    let width  = image.count
    let height = image[0].count

    func pixelValue(_ x: Int, _ y: Int) -> Int {
        if x < 0 || x >= width || y < 0 || y >= height {
            return 0
        }
        return image[x][y] ? 1 : 0
    }

    let sum = pixelValue(x, y)
            + pixelValue(x - 1, y)
            + pixelValue(x + 1, y)
            + pixelValue(x, y - 1)
            + pixelValue(x, y + 1)

    return (sum == 0 || sum > 3) ? 0 : 1
} */

/* // A neighbor that is out of bounds is considered to have a value of 0
// `theta` is in the range [0, 360) degrees
func neighboringPixelsValue(
        image: [[Bool]], x: Int, y: Int, theta: Double) -> Int {
    let width  = image.count
    let height = image[0].count

    func pixelValue(_ x: Int, _ y: Int) -> Int {
        if x < 0 || x >= width || y < 0 || y >= height {
            return 0
        }
        return image[x][y] ? 1 : 0
    }

    if theta <= 22.5 {
        // return pixelValue(x, y)
        //      + pixelValue(x - 1, y)
        //      + pixelValue(x - 1, y - 1)
        //      + pixelValue(x - 1, y + 1)
        return pixelValue(x, y)
             + pixelValue(x, y - 1)
             + pixelValue(x, y + 1)
             + pixelValue(x - 1, y)
             + pixelValue(x - 1, y - 1)
             + pixelValue(x - 1, y + 1)
    }
    if theta <= 67.5 {
        // return pixelValue(x, y)
        //      + pixelValue(x, y + 1)
        //      + pixelValue(x - 1, y)
        //      + pixelValue(x - 1, y + 1)
        return pixelValue(x, y)
             + pixelValue(x, y + 1)
             + pixelValue(x - 1, y)
             + pixelValue(x - 1, y + 1)
             + pixelValue(x - 1, y - 1)
             + pixelValue(x + 1, y + 1)
    }
    if theta <= 112.5 {
        return pixelValue(x, y)
             + pixelValue(x, y + 1)
             + pixelValue(x - 1, y + 1)
             + pixelValue(x + 1, y + 1)
        return pixelValue(x, y)
             + pixelValue(x, y + 1)
             + pixelValue(x - 1, y)
             + pixelValue(x - 1, y + 1)
             + pixelValue(x + 1, y)
             + pixelValue(x + 1, y + 1)
    }
    if theta <= 157.5 {
        return pixelValue(x, y)
             + pixelValue(x + 1, y + 1)
             + pixelValue(x + 1, y)
             + pixelValue(x + 1, y + 1)
        return pixelValue(x, y)
             + pixelValue(x, y + 1)
             + pixelValue(x - 1, y + 1)
             + pixelValue(x + 1, y + 1)
             + pixelValue(x + 1, y)
             + pixelValue(x + 1, y + 1)
    }
    if theta <= 202.5 {
        return pixelValue(x, y)
             + pixelValue(x + 1, y)
             + pixelValue(x + 1, y - 1)
             + pixelValue(x + 1, y + 1)
        return pixelValue(x, y)
             + pixelValue(x, y - 1)
             + pixelValue(x, y + 1)
             + pixelValue(x + 1, y)
             + pixelValue(x + 1, y - 1)
             + pixelValue(x + 1, y + 1)
    }
    if theta <= 247.5 {
        return pixelValue(x, y)
             + pixelValue(x, y - 1)
             + pixelValue(x + 1, y)
             + pixelValue(x + 1, y - 1)
        return pixelValue(x, y)
             + pixelValue(x, y - 1)
             + pixelValue(x - 1, y - 1)
             + pixelValue(x + 1, y)
             + pixelValue(x + 1, y - 1)
             + pixelValue(x + 1, y + 1)
    }
    if theta <= 292.5 {
        return pixelValue(x, y)
             + pixelValue(x, y - 1)
             + pixelValue(x - 1, y - 1)
             + pixelValue(x + 1, y - 1)
        return pixelValue(x, y)
             + pixelValue(x, y - 1)
             + pixelValue(x - 1, y)
             + pixelValue(x - 1, y - 1)
             + pixelValue(x + 1, y)
             + pixelValue(x + 1, y - 1)
    }
    if theta <= 337.5 {
        return pixelValue(x, y)
             + pixelValue(x, y - 1)
             + pixelValue(x - 1, y)
             + pixelValue(x - 1, y - 1)
        return pixelValue(x, y)
             + pixelValue(x, y - 1)
             + pixelValue(x - 1, y)
             + pixelValue(x - 1, y - 1)
             + pixelValue(x - 1, y + 1)
             + pixelValue(x + 1, y - 1)
    }
    return pixelValue(x, y)
         + pixelValue(x - 1, y)
         + pixelValue(x - 1, y - 1)
         + pixelValue(x - 1, y + 1)
    return pixelValue(x, y)
         + pixelValue(x, y - 1)
         + pixelValue(x, y + 1)
         + pixelValue(x - 1, y)
         + pixelValue(x - 1, y - 1)
         + pixelValue(x - 1, y + 1)
} */

// Return the distance between two points
func distance(_ a: Point, _ b: Point) -> Double {
    let deltaX = a.0 - b.0
    let deltaY = a.1 - b.1
    return sqrt(deltaX*deltaX + deltaY*deltaY)
}

func getLineSegments(binaryImage image: [[Bool]], comparisonImage: [[Bool]])
  -> [(Point, Point)] {
    let width         = Double(image.count)
    let height        = Double(image[0].count)
    let thetaFraction = 3.0
    let rhoFraction   = 2.0
    /* var accumulator   = houghTransform(binaryImage: image,
                                     thetaFraction: Int(thetaFraction),
                                       rhoFraction: Int(rhoFraction)) */
    var accumulator = houghTransformCenter(binaryImage: image,
                                         thetaFraction: Int(thetaFraction),
                                           rhoFraction: Int(rhoFraction))
    let thetasCount = accumulator.count
    let rhosCount   = accumulator[0].count
    let rhoOffset   = (rhosCount - 1)/2
    let iterationsCount = 50
    var allLineSegments = [(Point, Point)]()
    // print(accumulator)

    // Minimum length of each line segment
    let lengthMin = sqrt(width*width + height*height)/50

    // Extract line segments corresponding to each peak
    for i in 0..<iterationsCount {
        print("Iteration \(i)")
        // let (thetaIndex, rhoIndex) = maxIndex(in: accumulator, radius: 1)
        let (thetaIndex, rhoIndex) = maxIndex(in: accumulator, radius: 1)
        let rho   = Double(rhoIndex - rhoOffset)/rhoFraction
        let theta = Double(thetaIndex)*π/180/thetaFraction
        /* let endpoints = clip(width: width, height: height,
                             theta: theta, rho: rho) */
        let endpoints = clip(
            width: width,
            height: height,
            theta: theta,
            rho: rho + 0.5*(height*sin(theta) + width*cos(theta))
        )
        if endpoints.count < 2 {
            continue
        }
        let x0 = endpoints[0].0
        let y0 = endpoints[0].1
        let x1 = endpoints[1].0
        let y1 = endpoints[1].1
        let dx = x1 - x0
        let dy = y1 - y0
        let angle = atan2(dy, dx)*180/π
        let length = Int(sqrt(dx*dx + dy*dy))

        func xValue(_ t: Int) -> Double {
            return x0 + dx*Double(t)/Double(length)
        }
        func yValue(_ t: Int) -> Double {
            return y0 + dy*Double(t)/Double(length)
        }

        let gapMax = 3
        var gap    = 0
        var begin  = (xValue(0), yValue(0))
        var lineSegments   = [(Point, Point)]()
        var pointsToRemove = [Point]()

        for t in 0..<length {
            let x = xValue(t)
            let y = yValue(t)
            if neighboringPixelsValue(image: image, x: Int(x), y: Int(y)) > 0 {
                pointsToRemove.append((x, y))
                if gap > gapMax {
                    begin = (x, y)
                }
                if t == length - 1 {
                    let newPoint = (x, y)
                    if distance(begin, newPoint) >= lengthMin {
                        lineSegments.append((begin, newPoint))
                    }
                }
                gap = 0
            }
            else {
                if gap == gapMax {
                    let tEnd = t - gap
                    let newPoint = (xValue(tEnd), yValue(tEnd))
                    if distance(begin, newPoint) >= lengthMin {
                        lineSegments.append((begin, newPoint))
                    }
                }
                gap += 1
            }
        }

        // Remove the line segments' votes from the accumulator
        for pointToRemove in pointsToRemove {
            for thetaIndex in 0..<thetasCount {
                let theta = Double(thetaIndex)/Double(thetaFraction)*π/180
                let rho = (pointToRemove.0 -  width/2)*cos(theta)
                        + (pointToRemove.1 - height/2)*sin(theta)
                let rhoIndex = rhoOffset + Int(rho*rhoFraction)
                if accumulator[thetaIndex][rhoIndex] > 0 {
                    accumulator[thetaIndex][rhoIndex] -= 1
                }
                if rhoIndex - 1 >= 0
                && accumulator[thetaIndex][rhoIndex - 1] > 0 {
                    accumulator[thetaIndex][rhoIndex - 1] -= 1
                }
                if rhoIndex + 1 < accumulator[thetaIndex].count
                && accumulator[thetaIndex][rhoIndex + 1] > 0 {
                    accumulator[thetaIndex][rhoIndex + 1] -= 1
                }
            }
        }
        // print(accumulator)

        allLineSegments.append(contentsOf: lineSegments)
    }

    return allLineSegments
}

func houghLinesProbabilistic(binaryImage image: [[Bool]],
                               thetaResolution: Double,
                                 rhoResolution: Double,
                                     threshold: Int,
                                     minLength: Int,
                                        maxGap: Int) -> [(PointInt, PointInt)] {
    var image       = image
    var lines       = [(PointInt, PointInt)]()
    let shift       = 16
    let width       = image.count
    let height      = image[0].count
    let thetasCount = Int((Double.pi/thetaResolution).rounded())
    let rhosCount =
        Int((Double(2*(width + height) + 1)/rhoResolution).rounded())
    var accumulator = Array(repeating: Array(repeating: 0, count: rhosCount),
                                count: thetasCount)

    // Compute the sin and cosine of all theta values
    var trigTable = Array(repeating: 0.0, count: 2*rhosCount)
    for i in 0..<thetasCount {
        trigTable[2*i]     = cos(Double(i)*thetaResolution)/rhoResolution
        trigTable[2*i + 1] = sin(Double(i)*thetaResolution)/rhoResolution
    }

    // Get the array of pixel locations with value true
    var nonZeros = [PointInt]()
    for x in 0..<width {
        for y in 0..<height {
            if image[x][y] {
                nonZeros.append((x, y))
            }
        }
    }

    // Process all points in random order
    for count in stride(from: nonZeros.count, to: 0, by: -1) {
        Swift.print(count)

        let index = Int(arc4random_uniform(UInt32(count)))
        let (x, y) = nonZeros[index]
        var maxVotesCount = threshold - 1
        var maxTheta = 0
        var endPoints = [(0, 0), (0, 0)]

        // Replace the current element with the last element to remove it
        nonZeros[index] = nonZeros[count - 1]

        // If the point has already been excluded, then it belongs to some other
        // line
        if !image[x][y] {
            continue
        }

        // Update the accumulator
        for theta in 0..<thetasCount {
            let rhoDouble = Double(x)*trigTable[2*theta]
                          + Double(y)*trigTable[2*theta + 1]
            let rho = Int(rhoDouble.rounded()) + (rhosCount - 1)/2
            let votesCount = accumulator[theta][rho] + 1
            accumulator[theta][rho] = votesCount
            if maxVotesCount < votesCount {
                maxVotesCount = votesCount
                maxTheta = theta
            }
        }

        // If the point does not have enough votes, skip it
        if maxVotesCount < threshold {
            continue
        }

        let a = -trigTable[2*maxTheta + 1]  // -sin(theta)
        let b =  trigTable[2*maxTheta]      //  cos(theta)
        var x0 = x
        var y0 = y
        var dx0: Int
        var dy0: Int
        var incrementByX: Bool
        if abs(a) > abs(b) {
            incrementByX = true
            dx0 = a > 0 ? 1 : -1
            dy0 = Int((b*Double(1 << shift)/abs(a)).rounded())
            y0 = (y0 << shift) + (1 << (shift - 1))
        }
        else {
            incrementByX = false
            dx0 = Int((a*Double(1 << shift)/abs(b)).rounded())
            dy0 = b > 0 ? 1 : -1
            x0 = (x0 << shift) + (1 << (shift - 1))
        }

        // Walk along the line in each direction to extract the line segment
        var dx = dx0
        var dy = dy0
        for k in 0..<2 {
            var gap = 0
            var x = x0
            var y = y0
            while true {
                var i1: Int
                var j1: Int
                if incrementByX {
                    i1 = x
                    j1 = y >> shift
                }
                else {
                    i1 = x >> shift
                    j1 = y
                }
                if i1 < 0 || i1 >= width || j1 < 0 || j1 >= height {
                    break
                }
                if image[i1][j1] {
                    gap = 0
                    endPoints[k] = (i1, j1)
                }
                else if gap + 1 > maxGap {
                    break
                }
                x += dx
                y += dy
            }

            // Now walk in the other direction
            dx = -dx0
            dy = -dy0
        }

        let isLineGood = abs(endPoints[0].0 - endPoints[1].0) >= minLength
                      || abs(endPoints[0].1 - endPoints[1].1) >= minLength

        dx = dx0
        dy = dy0
        for k in 0..<2 {
            var x = x0
            var y = y0
            while true {
                var i1: Int
                var j1: Int
                if incrementByX {
                    i1 = x
                    j1 = y >> shift
                }
                else {
                    i1 = x >> shift
                    j1 = y
                }
                if image[i1][j1] {
                    if isLineGood {
                        for theta in 0..<thetasCount {
                            let rhoDouble = Double(i1)*trigTable[2*theta]
                                          + Double(j1)*trigTable[2*theta + 1]
                            let rho = Int(rhoDouble.rounded())
                                    + (rhosCount - 1)/2
                            accumulator[theta][rho] -= 1
                        }
                    }
                    image[i1][j1] = false
                }
                if i1 == endPoints[k].0 && j1 == endPoints[k].1 {
                    break
                }
                x += dx
                y += dy
            }

            // Now walk in the other direction
            dx = -dx0
            dy = -dy0
        }

        if isLineGood {
            lines.append((endPoints[0], endPoints[1]))
        }
    }

    return lines
}
