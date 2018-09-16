[![Swift 4.2.0](https://img.shields.io/badge/Swift-4.2.0-orange.svg?style=flat)](https://developer.apple.com/swift)
![Platforms](https://img.shields.io/badge/Platform-iOS%2011%2B%20|%20macOS%2010.13+%20|%20tvOS%2011+%20|%20watchOS%204+-blue.svg) 

|Branch|TravisCI Build Status (all os)|Code Coverage
|----|----|----|
|Master|[![TravisCI](https://travis-ci.org/tinrobots/AdvancedOperation.svg?branch=master)](https://travis-ci.org/tinrobots/AdvancedOperation)|[![codecov](https://codecov.io/gh/tinrobots/AdvancedOperation/branch/master/graph/badge.svg)](https://codecov.io/gh/tinrobots/AdvancedOperation)
|Develop|![TravisCI](https://travis-ci.org/tinrobots/AdvancedOperation.svg?branch=develop)|[![codecov](https://codecov.io/gh/tinrobots/AdvancedOperation/branch/develop/graph/badge.svg)](https://codecov.io/gh/tinrobots/AdvancedOperation)

## AdvancedOperation
[![GitHub release](https://img.shields.io/github/release/tinrobots/AdvancedOperation.svg)](https://github.com/tinrobots/AdvancedOperation/releases) 

A library of Swift utils to ease your iOS, macOS, watchOS, tvOS and Linux development.

- [Requirements](#requirements)
- [Documentation](#documentation)
- [Installation](#installation)
- [License](#license)
- [Contributing](#contributing)

## Requirements

- iOS 11.0+ / macOS 10.13+ / tvOS 11.0+ / watchOS 4.0+
- Xcode 10
- Swift 4.2.0

## Documentation

Documentation is [available online](http://www.tinrobots.org/AdvancedOperation/).

> [http://www.tinrobots.org/AdvancedOperation/](http://www.tinrobots.org/AdvancedOperation/)

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 1.1.0+ is required to build AdvancedOperation 1.0.0+.

To integrate AdvancedOperation into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '11.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'AdvancedOperation', '~> 1.0.0'
end
```

Then, run the following command:

```bash
$ pod install
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate AdvancedOperation into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "tinrobots/AdvancedOperation" ~> 1.0.0
```

Run `carthage update` to build the framework and drag the built `AdvancedOperation.framework` into your Xcode project.

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. 
Once you have your Swift package set up, adding AdvancedOperation as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/tinrobots/AdvancedOperation.git", from: "1.0.0")
]
```

### Manually

If you prefer not to use either of the aforementioned dependency managers, you can integrate AdvancedOperation into your project manually.

#### Embedded Framework

- Open up Terminal, `cd` into your top-level project directory, and run the following command "if" your project is not initialized as a git repository:

```bash
$ git init
```

- Add AdvancedOperation as a git [submodule](http://git-scm.com/docs/git-submodule) by running the following command:

```bash
$ git submodule add https://github.com/tinrobots/AdvancedOperation.git
```

- Open the new `AdvancedOperation` folder, and drag the `AdvancedOperation.xcodeproj` into the Project Navigator of your application's Xcode project.

    > It should appear nested underneath your application's blue project icon. Whether it is above or below all the other Xcode groups does not matter.

- Select the `AdvancedOperation.xcodeproj` in the Project Navigator and verify the deployment target matches that of your application target.
- Next, select your application project in the Project Navigator (blue project icon) to navigate to the target configuration window and select the application target under the "Targets" heading in the sidebar.
- In the tab bar at the top of that window, open the "General" panel.
- Click on the `+` button under the "Embedded Binaries" section.
- You will see two different `AdvancedOperation.xcodeproj` folders each with two different versions of the `AdvancedOperation.framework` nested inside a `Products` folder.

    > It does not matter which `Products` folder you choose from, but it does matter whether you choose the top or bottom `AdvancedOperation.framework`.

- Select the top `AdvancedOperation.framework` for iOS and the bottom one for macOS.

    > You can verify which one you selected by inspecting the build log for your project. The build target for `AdvancedOperation` will be listed as either `AdvancedOperation iOS`, `AdvancedOperation macOS`, `AdvancedOperation tvOS` or `AdvancedOperation watchOS`.


## License

[![License MIT](https://img.shields.io/badge/License-MIT-lightgrey.svg?style=flat)](https://github.com/tinrobots/AdvancedOperation/blob/master/LICENSE.md)

AdvancedOperation is released under the MIT license. See [LICENSE](./LICENSE.md) for details.

## Contributing

Pull requests are welcome!  
[Show your ❤ with a ★](https://github.com/tinrobots/AdvancedOperation/stargazers)