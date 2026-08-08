![build_status](https://gitlab.com/herme5/ImageProc/badges/master/pipeline.svg)

## Introduction

ImageProc is a collection of Swift utility methods for PNG image processing through the `UIImage` native API.

Sometimes icons have to be dynamically transformed, adding to the burden of the designer that needs to duplicate its rendered assets (e.g. same icons that have different colors, diferrent sizes...). Nevertheless, remember that static processing and pre-rendering is always better for the energy footprint of your apps.

## Demo

![](Demo/ImageProcApp/benchmark.png)

## Installation

ImageProc is a Swift package and requires iOS 15 or later.

In Xcode, use *File ▸ Add Package Dependencies…* and enter `https://gitlab.com/herme5/ImageProc.git`.

Or add it to the dependencies of your own `Package.swift`:

```swift
.package(url: "https://gitlab.com/herme5/ImageProc.git", from: "2.0.0")
```

Then `import ImageProc` where you need it.

Some operations are implemented as Core Image kernels written in Metal, which the package compiles
for you through a build tool plugin. Xcode may ask you to trust and enable that plugin the first
time you build.

## Usage

All methods extend `UIImage` and `UIColor` classes.

```swift
let someImage = UIImage(named: "someImageWithTransparency")!

let someColor = UIColor(value: 0x08af76) // Color can be initialized with its hexadecimal value.
let aBitDarkerColor = someColor.darker(by: 0.1) // RGB component will be decreased by 0.1 to give a darker color.

// Fill the opaque pixels with the given color.
let coloredImage = someImage.colorized(with: someColor) 
let aBitDarkerImage = someImage.colorized(with: aBitDarkerColor) 

```
