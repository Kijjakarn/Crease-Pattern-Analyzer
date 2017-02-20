import Cocoa

let ε = 1e-8
let εF: Float = 1e-8
let π = M_PI

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
    var value: UInt32

    init(value: UInt32, x: Int, y: Int) {
        self.value = value
        self.x = x
        self.y = y
    }
}

class BinaryImage {
    let image: CGImage
    let name: String

    var result: [[Bool]]
    let width:  Int
    let height: Int

    func write(appending word: String) throws {
        let rawBitmap = CFDataCreateMutable(nil, 0)
        let fileName = FileManager.default.currentDirectoryPath + "/"
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

        let outputNSImage = NSImage(cgImage: outputCGImage!, size: NSSize())
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
        guard let image = NSImage(byReferencingFile: imageName)?.cgImage(
            forProposedRect: nil,
            context: nil,
            hints: nil) else {
            throw ImageProcessingError.fileDoesNotExist
        }
        self.image = image
        name = imageName
        var mapping = [Pixel]()
        guard let rawBitmap = image.dataProvider?.data else {
            throw ImageProcessingError.unsupportedFileType
        }
        let bitsPerComponent = image.bitsPerComponent
        if bitsPerComponent != 8 {
            throw ImageProcessingError.unsupportedFileType
        }
        width  = image.width
        height = image.height
        let bitsPerPixel = image.bitsPerPixel
        let bytesPerPixel = bitsPerPixel/8
        var currentY: Int = 0
        var currentX: Int = 0
        var grayImage = Array(
            repeating: Array(repeating: UInt32(0), count: height),
            count: width
        )

        for i in stride(from: 0,
                          to: CFDataGetLength(rawBitmap),
                          by: bytesPerPixel)
        {
            var accumulated: UInt32 = 0
            for offset in 0..<bytesPerPixel {
                var component: UInt8 = 0
                CFDataGetBytes(rawBitmap,
                               CFRange(location: i + offset, length: 1),
                               &component)
                accumulated += UInt32(component)
            }
            if Int(currentX) >= width {
                currentX = 0
                currentY += 1
            }
            let grayValue = UInt32(Double(accumulated)/Double(bytesPerPixel))
            grayImage[currentX][currentY] = grayValue
            currentX += 1
        }
        let blurredImage = gaussianBlur(image: grayImage)

        var histogram = Array(repeating: 0, count: 256)
        for i in 0..<width {
            for j in 0..<height {
                let value = blurredImage[i][j]
                histogram[Int(value)] += 1
                mapping.append(Pixel(value: value, x: currentX, y: currentY))
            }
        }
        let threshold = UInt32(otsu(histogram: histogram,
                                    numPixels: width*height))

        // Count the number of pixels that have less than average pixel value
        var numPixelsLess = 0
        for pixel in mapping {
            if pixel.value < threshold {
                numPixelsLess += 1
            }
        }
        // Remapping
        var shouldAssignTrue: (UInt32) -> Bool = { $0 >= threshold }
        if 2*numPixelsLess < mapping.count {
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

func gaussianBlur(image: [[UInt32]]) -> [[UInt32]] {
    if image.isEmpty {
        return []
    }
    let width = image.count
    let height = image[0].count

    // Kernel with sigma = 0.3
    let kernel: [Double] = [0.04779, 0.90442, 0.04779]
    let radius = (kernel.count - 1)/2
    var imageV: [[Double]] = image.map { $0.map {
        (element: UInt32) in return Double(element)
    }}
    for i in 0..<width {
        for j in radius..<(height - radius) {
            var value = 0.0
            for k in 0..<kernel.count {
                value += kernel[k]*Double(image[i][j + k - radius])
            }
            imageV[i][j] = value
        }
    }
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
        (element: Double) in return UInt32(element)
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

func houghTransform(binaryImage image: [[Bool]]) {
    let rows = image.count
    let cols = image[0].count
    let numRhos   = Int(sqrt(Double(rows*rows + cols*cols))) + 1
    let numThetas = 360
    var accumulator = Array(repeating: Array(repeating: 0, count: numThetas),
                                count: numRhos)
    for i in 0..<rows {
        for j in 0..<cols {
            if image[i][j] {
                for theta in 0..<numThetas {
                    let radiansTheta = Double(theta)*π/180
                    var rho = Int(Double(i)*sin(radiansTheta)
                                + Double(cols - j)*cos(radiansTheta))
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
    var maxRhoIndex   = 0
    var maxThetaIndex = 0
    for theta in 0..<numThetas {
        for rho in 0..<numRhos {
            if accumulator[rho][theta]
             > accumulator[maxRhoIndex][maxThetaIndex] {
                maxRhoIndex = rho
                maxThetaIndex = theta
            }
        }
    }
    let bestLine = Line(distance: Double(maxRhoIndex),
                      unitNormal: PointVector(sin(Double(maxThetaIndex)*π/180),
                                              cos(Double(maxThetaIndex)*π/180)))
    print("Most prominent line: \(bestLine)")
}

let imageName = CommandLine.arguments[1]
let image: BinaryImage
do {
    try image = BinaryImage(imageName: imageName)
    try image.write(appending: " binarized")
    image.thin()
    try image.write(appending: " thinned")
}
catch {}
