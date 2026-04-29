import Foundation
import NCMKit

enum NCMConverter {
    @discardableResult
    static func convert(fileURL: URL, outputDirectory: URL? = nil) throws -> URL {
        let outputPath = try NCMKit.convert(
            inputPath: fileURL.path,
            outputDirectory: outputDirectory?.path
        )
        return URL(fileURLWithPath: outputPath)
    }
}
