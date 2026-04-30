#import "NCMKit.h"

#include "ncmcrypt.h"

NSErrorDomain const NCMKitErrorDomain = @"NCMKitErrorDomain";

static NSError *NCMKitMakeError(NCMKitErrorCode code, NSString *description) {
    return [NSError errorWithDomain:NCMKitErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey : description}];
}

@implementation NCMKit

+ (nullable NSString *)convertFileAtPath:(NSString *)inputPath
                         outputDirectory:(nullable NSString *)outputDirectory
                                   error:(NSError * _Nullable * _Nullable)error {
    if (error != nil) {
        *error = nil;
    }

    if (inputPath.length == 0) {
        if (error != nil) {
            *error = NCMKitMakeError(NCMKitErrorCodeInvalidInput, @"inputPath must not be empty.");
        }
        return nil;
    }

    try {
        const std::string sourcePath([inputPath UTF8String]);
        const std::string targetDirectory = outputDirectory.length > 0 ? std::string([outputDirectory UTF8String]) : std::string();

        NeteaseCrypt crypt(sourcePath);
        crypt.Dump(targetDirectory);
        crypt.FixMetadata();

        const std::string outputPath = crypt.dumpFilepath().u8string();
        return [NSString stringWithUTF8String:outputPath.c_str()];
    }
    catch (const std::invalid_argument &exception) {
        if (error != nil) {
            *error = NCMKitMakeError(NCMKitErrorCodeConversionFailed, [NSString stringWithUTF8String:exception.what()]);
        }
        return nil;
    }
    catch (const std::exception &exception) {
        if (error != nil) {
            *error = NCMKitMakeError(NCMKitErrorCodeConversionFailed, [NSString stringWithUTF8String:exception.what()]);
        }
        return nil;
    }
    catch (...) {
        if (error != nil) {
            *error = NCMKitMakeError(NCMKitErrorCodeConversionFailed, @"Unexpected failure while converting the NCM file.");
        }
        return nil;
    }
}

@end
