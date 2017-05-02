import Cocoa

typealias Point = (Double, Double)

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
        let fileType: NSBitmapImageFileType

        switch (name as NSString).pathExtension {
        case "png" :  fileType = NSPNGFileType
        case "jpg" :  fileType = NSJPEGFileType
        case "jpeg":  fileType = NSJPEGFileType
        case "gif" :  fileType = NSGIFFileType
        case "bmp" :  fileType = NSBMPFileType
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
    if x < 0 || x >= width {
        return 0
    }
    if y < 0 || y >= height {
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

func getLineSegments(binaryImage image: [[Bool]]) -> [(Point, Point)] {
    let width         = Double(image.count)
    let height        = Double(image[0].count)
    let thetaFraction = 1.0
    let rhoFraction   = 1.0
    /* var accumulator   = houghTransform(binaryImage: image,
                                     thetaFraction: Int(thetaFraction),
                                       rhoFraction: Int(rhoFraction)) */
    var accumulator   = houghTransformCenter(binaryImage: image,
                                           thetaFraction: Int(thetaFraction),
                                             rhoFraction: Int(rhoFraction))
    let thetasCount = accumulator.count
    let rhosCount   = accumulator[0].count
    let rhoOffset   = (rhosCount - 1)/2
    let iterationsCount = 1
    var allLineSegments = [(Point, Point)]()

    // Extract line segments corresponding to each peak
    for i in 0..<iterationsCount {
        // let (thetaIndex, rhoIndex) = maxIndex(in: accumulator, radius: 1)
        let (thetaIndex, rhoIndex) = maxIndex(in: accumulator, radius: 1)
        let rho   = Double(rhoIndex - rhoOffset)/rhoFraction
        let theta = Double(thetaIndex)*π/180/thetaFraction
        /* let endpoints = clip(width: width, height: height,
                             theta: theta, rho: rho) */
        let endpoints = clip(width: width,
                            height: height,
                             theta: theta,
                               rho: rho + 0.5*(height*sin(theta)
                                              + width*cos(theta)))
        if endpoints.count < 2 {
            continue
        }
        let x0 = endpoints[0].0
        let y0 = endpoints[0].1
        let x1 = endpoints[1].0
        let y1 = endpoints[1].1
        let dx = x1 - x0
        let dy = y1 - y0
        let length = Int(sqrt(dx*dx + dy*dy))

        func xValue(_ t: Int) -> Double {
            return x0 + dx*Double(t)/Double(length)
        }
        func yValue(_ t: Int) -> Double {
            return y0 + dy*Double(t)/Double(length)
        }

        let gapMax = 2
        var gap    = 0
        var begin  = (xValue(0), yValue(0))
        var lineSegments = [(Point, Point)]()
        for t in 0..<length {
            let x = xValue(t)
            let y = yValue(t)
            if neighboringPixelsValue(image: image, x: Int(x), y: Int(y)) > 0 {
                if gap > gapMax {
                    begin = (x, y)
                }
                if t == length - 1 {
                    lineSegments.append((begin, (x, y)))
                }
                gap = 0
            }
            else {
                if gap == gapMax {
                    let tEnd = t - gap
                    lineSegments.append((begin, (xValue(tEnd), yValue(tEnd))))
                }
                gap += 1
            }
        }

        // TODO: Remove the line segments' votes from the accumulator

        // printEachLine(lineSegments)
        allLineSegments.append(contentsOf: lineSegments)
    }

    return allLineSegments
}
