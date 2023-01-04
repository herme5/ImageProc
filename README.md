[![Build Status](https://app.travis-ci.com/herme5/ImageProc.svg?branch=master)](https://app.travis-ci.com/herme5/ImageProc)

## Introduction

ImageProc is a collection of Swift utility methods for PNG image processing through the `UIImage` native API.

Sometimes icons have to be dynamically transformed, adding to the burden of the designer that needs to duplicate its rendered assets (e.g. same icons that have different colors, diferrent sizes...). Nevertheless, remember that static processing and pre-rendering is always better for the energy footprint of your apps.

## Demo

![](https://github.com/herme5/ImageProc/blob/master/ImageProcApp/benchmark.png)

## Installation

You can either build and link the framework to your project, or directly copy paste the Swift sources.

If you choose to build and link the framework, remember to `#import ImageProc`.

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
