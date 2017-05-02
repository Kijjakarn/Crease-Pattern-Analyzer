import Cocoa

let ε = 1e-8
let εF: Float = 1e-8
let π = M_PI
let defaultDirectory =
    FileManager.default.homeDirectoryForCurrentUser.relativePath +
    "/CreasePatternAnalyzer/Hough Transform Experiment/Test Images/"

extension Bool {
    var int: Int {
        return self ? 1 : 0
    }
}

enum ImageProcessingError: Error {
    case unsupportedFileType
    case fileDoesNotExist
}

class Pixel {
    var x:     Int
    var y:     Int
    var value: UInt8

    init(value: UInt8, x: Int, y: Int) {
        self.value = value
        self.x = x
        self.y = y
    }
}

class BinaryImage {
    let image: CGImage
    let name:  String

    var result: [[Bool]]
    let width:  Int
    let height: Int

    func write(appending word: String) throws {
        let rawBitmap = CFDataCreateMutable(nil, width*height)
        let fileName = // FileManager.default.currentDirectoryPath + "/"
                        defaultDirectory
                     + (name as NSString).deletingPathExtension + word + "."
                     + (name as NSString).pathExtension
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
        case "png":  fileType = NSPNGFileType
        case "jpg":  fileType = NSJPEGFileType
        case "jpeg": fileType = NSJPEGFileType
        case "gif":  fileType = NSGIFFileType
        case "bmp":  fileType = NSBMPFileType
        default:     throw ImageProcessingError.unsupportedFileType
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

    init(imageName: String) throws {
        // Create a CGImage through an NSImage
        guard var image = NSImage(
            byReferencingFile: defaultDirectory + imageName)?
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
        name   = imageName
        width  = image.width
        height = image.height
        let numPixels = width*height

        // Create a gray-scale image from the pixel values
        var grayImage = Array(
            repeating: Array(repeating: UInt8(0), count: height),
            count: width
        )
        var currentX = 0
        var currentY = 0
        for i in 0..<numPixels {
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

        // Find the binarization threshold using Otsu's method
        var histogram = Array(repeating: 0, count: 256)
        for i in 0..<width {
            for j in 0..<height {
                let value = blurredImage[i][j]
                histogram[Int(value)] += 1
            }
        }
        let threshold = UInt8(otsu(histogram: histogram,
                                   numPixels: numPixels))

        // Count the number of pixels that have less than average pixel value
        // These pixels will be assigned to true; the others to false
        var numPixelsLess = 0
        for i in 0..<width {
            for j in 0..<height {
                if blurredImage[i][j] < threshold {
                    numPixelsLess += 1
                }
            }
        }
        // Remap gray values to binary
        var shouldAssignTrue: (UInt8) -> Bool = { $0 >= threshold }
        if 2*numPixelsLess < numPixels {
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

func otsu(histogram: [Int], numPixels: Int) -> Int {
    var sum = 0
    for i in 0..<256 {
        sum += i*histogram[i]
    }
    var sumB = 0
    var wB = 0
    var wF = 0
    var varianceMax = 0
    var threshold = 0
    for i in 0..<256 {
        wB += histogram[i]
        if wB == 0 {
            continue
        }
        wF = numPixels - wB
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

// Return an array of lines, sorted by frequency
func houghTransform(binaryImage image: [[Bool]]) -> [Line] {
    let width       = image.count
    let height      = image[0].count
    let numRhos     = Int(sqrt(Double(width*width + height*height))) + 1
    let numThetas   = 360
    var accumulator = Array(repeating: Array(repeating: 0, count: numThetas),
                                count: numRhos)
    for i in 0..<width {
        for j in 0..<height {
            if image[i][j] {
                for theta in 0..<numThetas {
                    let thetaRadians = Double(theta)*π/180
                    var rho = Int(Double(i)*sin(thetaRadians)
                                + Double(height - j)*cos(thetaRadians))
                    var newTheta = theta
                    if rho < 0 {
                        rho = -rho
                        newTheta = (180 + theta) % 360
                    }
                    accumulator[rho][newTheta] += 1
                }
            }
        }
    }
    // Make a pair of lines and their frequency of occurrence
    var linesCount = [(line: Line, count: Int)]()
    for theta in 0..<numThetas {
        for rho in 0..<numRhos {
            if accumulator[rho][theta] > 0 {
                let line = Line(distance: Double(rho),
                              unitNormal: PointVector(sin(Double(theta)*π/180),
                                                      cos(Double(theta)*π/180)))
                linesCount.append((line, accumulator[rho][theta]))
            }
        }
    }
    // Sort the pairs by count
    linesCount.sort(by: {
        return $0.count > $1.count
    })
    // Print the first 50 lines
    for i in 0..<50 {
        let (line, count) = linesCount[i]
        print("\(count): \(line)")
    }
    return linesCount.map { $0.line }
}

for i in 1..<CommandLine.arguments.count {
    let imageName = CommandLine.arguments[i]
    let image: BinaryImage
    do {
        try image = BinaryImage(imageName: imageName)
        try image.write(appending: " binarized")
        image.thin()
        try image.write(appending: " thinned")
        _ = houghTransform(binaryImage: image.result)
    }
    catch let error {
        print(error)
    }
}
