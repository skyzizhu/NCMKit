# NCMKit

`NCMKit` 是一个面向 iOS 的静态库 / XCFramework 封装，用来把网易云音乐 `.ncm` 文件转换为可播放的音频文件，并尽量修复元数据与封面。

这个仓库基于以下上游项目做了 iOS 静态化改造：
- `taurusxin/ncmdump`
- `TagLib`

用途定位：
- 个人学习
- 本地研究与验证
- 不包含 App Store 上架相关处理

## 平台

当前产物为：
- `ios-arm64`
- `ios-arm64-simulator`

最终产物：
- `NCMKit.xcframework`

## 仓库内容

- `NCMKit/`
  - `NCMKit.h`
  - `NCMKit.mm`
  - `NCMConverter.swift`
  - `module.modulemap`
- `scripts/`
  - `build-ios.sh`
  - `make-xcframework.sh`
- `vendor/`
  - `ncmdump`
  - `taglib`
- `NCMKit.xcframework`

## 这个库做了什么

相对上游命令行项目，这里主要做了这些改造：

1. 移除命令行集成，只保留核心转换逻辑
2. 将 `libncmdump` 改为静态库
3. 将 `TagLib` 一并静态链接进 iOS 产物
4. 提供 Objective-C++ wrapper
5. 提供 Swift 调用示例
6. 输出可直接集成的 `NCMKit.xcframework`

## 支持的输出音频格式

当前实现只会将 `.ncm` 文件还原为以下两种音频格式之一：

- `mp3`
- `flac`

这不是一个通用音频转码器。它做的是把 `.ncm` 中原始封装的音频内容解密并恢复出来。

判定规则基于上游核心逻辑：

- 如果解密后的文件头是 `ID3`，输出为 `mp3`
- 否则按 `flac` 处理

同时元数据修复也仅针对这两种格式实现。

## 使用平台

适用于：
- iPhone 真机
- Apple Silicon 模拟器

当前不包含：
- macOS framework 发布
- CocoaPods / SPM 包装
- App Store 发布说明

## 如何集成

把 [NCMKit.xcframework](./NCMKit.xcframework) 加入你的 Xcode 工程，然后在代码里：

```swift
import Foundation
import NCMKit
```

## Swift 使用示例

参考 [NCMKit/NCMConverter.swift](./NCMKit/NCMConverter.swift)：

```swift
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
```

直接调用：

```swift
do {
    let outputURL = try NCMConverter.convert(
        fileURL: inputURL,
        outputDirectory: outputDirectoryURL
    )
    print("转换成功: \(outputURL.path)")
} catch let error as NCMConversionError {
    print("转换失败: \(error.localizedDescription)")
} catch {
    print("未知错误: \(error.localizedDescription)")
}
```

## Objective-C / Objective-C++ 接口

头文件见 [NCMKit/NCMKit.h](./NCMKit/NCMKit.h)。

核心接口：

```objc
+ (nullable NSString *)convertFileAtPath:(NSString *)inputPath
                         outputDirectory:(nullable NSString *)outputDirectory
                                   error:(NSError * _Nullable * _Nullable)error;
```

返回值为输出音频文件路径。失败时返回 `nil`，并通过 `NSError` 返回错误信息。

Objective-C 调用示例：

```objc
NSError *error = nil;
NSString *outputPath = [NCMKit convertFileAtPath:inputPath
                                 outputDirectory:outputDirectory
                                           error:&error];

if (outputPath != nil) {
    NSLog(@"转换成功: %@", outputPath);
} else {
    NSLog(@"转换失败: %@", error.localizedDescription);
}
```

## 构建方式

生成单个 slice：

```bash
scripts/build-ios.sh iphoneos
scripts/build-ios.sh iphonesimulator
```

生成最终 XCFramework：

```bash
scripts/make-xcframework.sh
```

输出位置：

```text
NCMKit.xcframework
```

## 实现说明

wrapper 最终直接调用上游 `NeteaseCrypt` 的核心流程：

1. `NeteaseCrypt` 初始化输入文件
2. `Dump(...)`
3. `FixMetadata()`
4. 返回 `dumpFilepath()`

也就是说，这里没有继续依赖命令行入口，而是直接复用核心转换类。

## 第三方依赖

本仓库包含第三方源码，请遵守它们各自的许可证：

- `vendor/ncmdump/LICENSE.txt`
- `vendor/taglib/COPYING.LGPL`
- `vendor/taglib/COPYING.MPL`

## 版权

Copyright sky
