#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSErrorDomain const NCMKitErrorDomain;

typedef NS_ERROR_ENUM(NCMKitErrorDomain, NCMKitErrorCode) {
    NCMKitErrorCodeInvalidInput = 1,
    NCMKitErrorCodeConversionFailed = 2,
};

@interface NCMKit : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (nullable NSString *)convertFileAtPath:(NSString *)inputPath
                         outputDirectory:(nullable NSString *)outputDirectory
                                   error:(NSError * _Nullable * _Nullable)error
    NS_SWIFT_NAME(convert(inputPath:outputDirectory:));

@end

NS_ASSUME_NONNULL_END
