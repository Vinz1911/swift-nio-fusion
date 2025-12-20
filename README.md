# Swift NIO Fusion
The `FusionBootstrap` is a custom network listener that implements the **Fusion Framing Protocol (FFP)**
It is built on top of the `Swift-NIO` library. This fast and lightweight custom framing protocol 
enables high-speed data transmission and provides fine-grained control over network flow.

# Overview
| Swift Version                                                                                                | License                                                                                                                                                   |
|--------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| [![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg?logo=swift&style=flat)](https://swift.org)   | [![License](https://img.shields.io/badge/license-MIT-blue.svg?longCache=true&style=flat)](https://github.com/Vinz1911/swift-nio-fusion/blob/main/LICENSE) |
| [![Swift 6.2](https://img.shields.io/badge/SPM-Support-orange.svg?logo=swift&style=flat)](https://swift.org) |                                                                                                                                                           |

## Installation:
### Swift Packages

```swift
// ...
dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(url: "https://github.com/Vinz1911/swift-nio-fusion", exact: "1.0.0"),
]

// in targets
dependencies: [
    .product(name: "NIOFusion", package: "swift-nio-fusion")
]
// ...
```

## Import:
```swift
// Import the Framework
import NIOFusion

// Create the bootstrap listener
let bootstrap = FusionBootstrap(from: .init(host: "0.0.0.0", port: 7878))

// ...
```

## Bind Bootstrap:
```swift
// Import the Framework
import NIOFusion

// Create the bootstrap listener
let bootstrap = FusionBootstrap(from: .init(host: "0.0.0.0", port: 7878))

// Receive result
Task {
    for try await result in bootstrap.receive() {
        // Handle `FusionResult`, simple echo server
        try await bootstrap.send(id: result.id, message: result.message)
    }
}

// bind bootstrap
try await bootstrap.bind()
```
