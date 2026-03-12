// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import PackageDescription

let package = Package(
    name: "NIMUIKit",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "NECoreKit", targets: ["NECoreKit"]),
        .library(name: "NECommonKit", targets: ["NECommonKitWrapper"]),
        .library(name: "NECoreIM2Kit", targets: ["NECoreIM2KitWrapper"]),
        .library(name: "NECommonUIKit", targets: ["NECommonUIKitWrapper"]),
        .library(name: "NEChatKit", targets: ["NEChatKitWrapper"]),
        .library(name: "NEChatUIKit", targets: ["NEChatUIKitWrapper"]),
        .library(name: "NEContactUIKit", targets: ["NEContactUIKitWrapper"]),
        .library(name: "NEConversationUIKit", targets: ["NEConversationUIKitWrapper"]),
        .library(name: "NELocalConversationUIKit", targets: ["NELocalConversationUIKitWrapper"]),
        .library(name: "NETeamUIKit", targets: ["NETeamUIKitWrapper"]),
        .library(name: "NEMapKit", targets: ["NEMapKitWrapper"]),
        .library(name: "NEAISearchKit", targets: ["NEAISearchKitWrapper"]),
    ],
    dependencies: [
        // 第三方依赖
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.0.0"),
        .package(url: "https://github.com/CoderMJLee/MJRefresh.git", from: "3.7.5"),
        .package(url: "https://github.com/SDWebImage/SDWebImageWebPCoder.git", from: "0.8.0"),
        .package(url: "https://github.com/SDWebImage/SDWebImageSVGKitPlugin.git", from: "1.3.0"),
    ],
    targets: [
        // ============ Binary Targets ============
        
        // NECoreKit - 核心基础库 (无依赖，直接使用 binaryTarget)
        .binaryTarget(
            name: "NECoreKit",
            url: "https://yx-web-nosdn.netease.im/xkit/IMUIKit/9.8.1/1773238359/NECoreKit_iOS_v9.8.1.framework.zip",
            checksum: "139af7ebf96c7fc15f6c24b0f14f97f05250d4fd0b166429c5ce4a15328018ef"
        ),
        
        .binaryTarget(
            name: "NECommonKit",
            url: "https://yx-web-nosdn.netease.im/xkit/IMUIKit/9.7.6/1773238398/NECommonKit_iOS_v9.7.6.framework.zip",
            checksum: "146f213e17be44c14313c7ca72157e3807d900b114a8953c039180716515759f"
        ),
        
        .binaryTarget(
            name: "NECoreIM2Kit",
            url: "https://yx-web-nosdn.netease.im/xkit/IMUIKit/1.1.7/1773238443/NECoreIM2Kit_iOS_v1.1.7.framework.zip",
            checksum: "e059285841d7cabe1191804c16c9982c101ed0e9e652049f2c9c7dcc32573801"
        ),
        
        .binaryTarget(
            name: "NECommonUIKit",
            url: "https://yx-web-nosdn.netease.im/xkit/IMUIKit/9.8.3/1773238638/NECommonUIKit_iOS_v9.8.3.framework.zip",
            checksum: "fe229fe6a3ad511e4c2ccfe22916433fd611c94321fa5748ceebc816572d6d41"
        ),
        
        .binaryTarget(
            name: "NEChatKit",
            url: "https://yx-web-nosdn.netease.im/xkit/IMUIKit/10.9.10/1773238717/NEChatKit_iOS_v10.9.10.framework.zip",
            checksum: "e7f56fba1344c9a03a9f64e52b45dafcfe42e41071ac93007b504286a7e69b35"
        ),
        
        .binaryTarget(
            name: "NEChatUIKit",
            url: "https://yx-web-nosdn.netease.im/xkit/IMUIKit/10.9.10/1773239100/NEChatUIKit_iOS_v10.9.10.framework.zip",
            checksum: "63186e8d651422ef9cf754e2594ce3343e3cdc1229ff036a54941feedb664175"
        ),
        
        .binaryTarget(
            name: "NEContactUIKit",
            url: "https://yx-web-nosdn.netease.im/xkit/IMUIKit/10.9.10/1773239406/NEContactUIKit_iOS_v10.9.10.framework.zip",
            checksum: "e609a8bd22da76b4c02aedb8fc403021bbd5ab8bb480ee4397cf97267874ec0c"
        ),
        
        .binaryTarget(
            name: "NEConversationUIKit",
            url: "https://yx-web-nosdn.netease.im/xkit/IMUIKit/10.9.10/1773239660/NEConversationUIKit_iOS_v10.9.10.framework.zip",
            checksum: "dea11ac05d16938e43f5ab329f9dd0fa82d1ee8012be46518ad9adf822edc644"
        ),
        
        .binaryTarget(
            name: "NELocalConversationUIKit",
            url: "https://yx-web-nosdn.netease.im/xkit/IMUIKit/10.9.10/1773239950/NELocalConversationUIKit_iOS_v10.9.10.framework.zip",
            checksum: "70f8e1e0e4c83eb7d642162af9ad19fc62e37d66cbd534ace886d7d8e7874d32"
        ),
        
        .binaryTarget(
            name: "NETeamUIKit",
            url: "https://yx-web-nosdn.netease.im/xkit/IMUIKit/10.9.10/1773240352/NETeamUIKit_iOS_v10.9.10.framework.zip",
            checksum: "31b0a0023f8f028cf8e92a02e35805e7656a678078fe486492ababe6ab873b34"
        ),
        
        .binaryTarget(
            name: "NEMapKit",
            url: "https://yx-web-nosdn.netease.im/xkit/IMUIKit/10.9.10/1773240722/NEMapKit_iOS_v10.9.10.framework.zip",
            checksum: "9f41a41cb0d21c1952624b6d4bd1967428c869f7f4b90d91d8eb932d6446ffed"
        ),
        
        .binaryTarget(
            name: "NEAISearchKit",
            url: "https://yx-web-nosdn.netease.im/xkit/IMUIKit/10.9.10/1773241015/NEAISearchKit_iOS_v10.9.10.framework.zip",
            checksum: "d8089a97eeab5f20c9870ce2627cb406a050cf7652edf407690223ff96679577"
        ),
        
        // ============ Wrapper Targets (for dependency management) ============
        
        .target(
            name: "NECommonKitWrapper",
            dependencies: ["NECoreKit", "NECommonKit"],
            path: "Sources/NECommonKitWrapper"
        ),
        
        .target(
            name: "NECoreIM2KitWrapper",
            dependencies: ["NECoreKit", "NECoreIM2Kit"],
            path: "Sources/NECoreIM2KitWrapper"
        ),
        
        .target(
            name: "NECommonUIKitWrapper",
            dependencies: [
                "NECommonKitWrapper",
                "NECommonUIKit",
                .product(name: "SDWebImage", package: "SDWebImage"),
            ],
            path: "Sources/NECommonUIKitWrapper"
        ),
        
        .target(
            name: "NEChatKitWrapper",
            dependencies: ["NECoreIM2KitWrapper", "NECommonKitWrapper", "NEChatKit"],
            path: "Sources/NEChatKitWrapper"
        ),
        
        .target(
            name: "NEChatUIKitWrapper",
            dependencies: [
                "NEChatKitWrapper",
                "NECommonUIKitWrapper",
                "NEChatUIKit",
                .product(name: "MJRefresh", package: "MJRefresh"),
                .product(name: "SDWebImageWebPCoder", package: "SDWebImageWebPCoder"),
                .product(name: "SDWebImageSVGKitPlugin", package: "SDWebImageSVGKitPlugin"),
            ],
            path: "Sources/NEChatUIKitWrapper"
        ),
        
        .target(
            name: "NEContactUIKitWrapper",
            dependencies: [
                "NECommonUIKitWrapper",
                "NEContactUIKit",
            ],
            path: "Sources/NEContactUIKitWrapper"
        ),
        
        .target(
            name: "NEConversationUIKitWrapper",
            dependencies: [
                "NEChatKitWrapper",
                "NECommonUIKitWrapper",
                "NEConversationUIKit",
            ],
            path: "Sources/NEConversationUIKitWrapper"
        ),
        
        .target(
            name: "NELocalConversationUIKitWrapper",
            dependencies: ["NECommonUIKitWrapper", "NELocalConversationUIKit"],
            path: "Sources/NELocalConversationUIKitWrapper"
        ),
        
        .target(
            name: "NETeamUIKitWrapper",
            dependencies: [
                "NEChatKitWrapper",
                "NECommonUIKitWrapper",
                "NETeamUIKit",
            ],
            path: "Sources/NETeamUIKitWrapper"
        ),
        
        .target(
            name: "NEMapKitWrapper",
            dependencies: ["NECommonUIKitWrapper", "NEMapKit"],
            path: "Sources/NEMapKitWrapper"
        ),
        
        .target(
            name: "NEAISearchKitWrapper",
            dependencies: ["NEChatKitWrapper", "NECommonUIKitWrapper", "NEAISearchKit"],
            path: "Sources/NEAISearchKitWrapper"
        ),
    ]
)