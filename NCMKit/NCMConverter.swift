import Foundation
import NCMKit

enum NCMConversionError: LocalizedError {
    case invalidInput(String)
    case conversionFailed(String)
    case underlying(NSError)

    init(nsError: NSError) {
        guard nsError.domain == NCMKitErrorDomain else {
            self = .underlying(nsError)
            return
        }

        switch nsError.code {
        case NCMKitErrorCode.invalidInput.rawValue:
            self = .invalidInput(nsError.localizedDescription)
        case NCMKitErrorCode.conversionFailed.rawValue:
            self = .conversionFailed(nsError.localizedDescription)
        default:
            self = .underlying(nsError)
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return message
        case .conversionFailed(let message):
            return message
        case .underlying(let error):
            return error.localizedDescription
        }
    }
}

enum NCMConverter {
    @discardableResult
    static func convert(fileURL: URL, outputDirectory: URL? = nil) throws -> URL {
        do {
            let outputPath = try NCMKit.convert(
                inputPath: fileURL.path,
                outputDirectory: outputDirectory?.path
            )
            return URL(fileURLWithPath: outputPath)
        } catch let error as NSError {
            throw NCMConversionError(nsError: error)
        }
    }
}
