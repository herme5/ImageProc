# ImageProc

[![tests](https://github.com/herme5/ImageProc/actions/workflows/tests.yml/badge.svg)](https://github.com/herme5/ImageProc/actions/workflows/tests.yml)
![platform](https://img.shields.io/badge/platform-iOS%2015%2B-lightgrey)
![swift package manager](https://img.shields.io/badge/SPM-compatible-orange)
[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

Image processing for icons and other transparent PNGs, written as extensions on `UIImage` and `UIColor`.

Recolor an icon, give it an outline, blur it, rotate it or stack it on another image without asking a
designer for one more exported variant:

```swift
import ImageProc

let badge = UIImage(named: "star")!
    .colorized(with: .systemPink)
    .stroked(with: .white, size: 2)
```

Pre-rendered assets are still the better choice when the variants are known in advance. They cost
nothing at run time.

![The demo app, rendering every operation with its timing](Demo/ImageProcApp/benchmark.png)

## Installation

ImageProc is a Swift package for **iOS 15 and later**.

In Xcode, choose *File ▸ Add Package Dependencies…* and enter `https://github.com/herme5/ImageProc.git`.
In a `Package.swift`:

```swift
.package(url: "https://github.com/herme5/ImageProc.git", from: "2.3.0")
```

Some operations run as Core Image kernels written in Metal, and the package compiles them with a build
tool plugin. **The first time you build, Xcode asks you to trust and enable that plugin.**

> Earlier versions were hosted on GitLab. `gitlab.com/herme5/ImageProc.git` is archived and frozen at
> 2.3.0, so point your dependency at GitHub.

## Usage

Every operation is a method on `UIImage` or `UIColor`. It returns a new value and leaves the receiver
unchanged.

### Color

```swift
icon.colorized(with: .systemBlue)             // fill every opaque pixel with a color
icon.colorInverted()                          // invert the colors, keep the alpha
icon.withAlphaComponent(0.5)                  // cap the opacity
```

### Outline and blur

```swift
icon.expanded(bySize: 4)                      // grow the opaque silhouette by 4 points
icon.stroked(with: .white, size: 2)           // draw a border around it
icon.stroked(with: .black, size: 3, alpha: 0.4)
icon.smoothened(by: 2)                        // Gaussian blur, grown so the blur is not clipped
icon.smoothened(by: 2, sizeKept: true)        // …or cropped back to the original size
```

`expanded` and `stroked` take an optional `each:` step in degrees (default `3`), the angle between
the directions sampled around each pixel. A larger step is faster but gives a rougher outline on
curved shapes.

### Geometry

```swift
icon.scaled(to: CGSize(width: 64, height: 64))
icon.scaled(uniform: 2)
icon.scaledWidth(to: 120)                     // height follows the aspect ratio
icon.scaledHeight(to: 40, keepAspectRatio: false)
icon.cropped(to: CGRect(x: 0, y: 0, width: 32, height: 32))
icon.rotated(by: 45)                          // clockwise, in degrees
icon.flippedHorizontally()
icon.flippedVertically()
```

### Combining images

```swift
glyph.drawnAbove(image: background)           // glyph on top
glyph.drawnUnder(image: overlay)              // glyph beneath
shape.alphaExclusion(with: otherShape)        // opaque where exactly one of the two is
```

Images of different sizes are centered on each other.

### Text

```swift
let label = UIImage(text: "NEW", attributes: [.font: UIFont.boldSystemFont(ofSize: 12)])
```

### Inspecting an image

```swift
icon.sizeInPixel                              // size × scale
icon.opaquePixelDensity                       // mean opacity, from 0 (empty) to 1 (fully opaque)
icon.withBitmapAsUIColorArray { colors in colors.first }
```

### Colors

```swift
let green = UIColor(value: 0x08AF76)
let parsed = UIColor(hexCode: "#08AF76")      // optional
green.hexCode                                 // "#08AF76"
green.rgba.red; green.hsla.hue

green.lighter(by: 0.1); green.darker()
green.saturated(); green.brightened(by: -0.2)
green.hueOffset(by: 0.5)                      // complementary color
green.moreOpaque(); green.lessOpaque(by: 0.5)
UIColor.random()
```

## Chaining operations

Every `UIImage` method has to return a finished image, which means a round trip to the GPU. Chaining
four calls pays for four round trips. `processed` builds the chain as a single Core Image graph and
reads the result back once:

```swift
let badge = icon.processed {
    $0.colorized(with: .systemPink)
      .expanded(bySize: 4)
      .smoothened(by: 1)
}
```

The processor offers every operation above. `colorized`, `expanded`, `stroked`, `smoothened` and
`colorInverted` are fused into the graph. The others render what has accumulated so far and then
continue, so any chain works and the fused steps are where the savings come from. The result matches
the equivalent sequence of calls to within a unit or two out of 255, because the chain does not round
to 8 bits between steps.

## Behavior worth knowing

- **Operations never crash.** An image without bitmap data, such as one backed only by a `CIImage`,
  comes back unchanged and a message is logged. The same happens if the Metal kernels could not be
  loaded.
- **Dark mode and contrast are followed.** When the image, the color or the second image changes with
  the interface style or with increased contrast, the output is computed for each variant and keeps
  switching with the environment. Colorizing with `.systemPink` gives an image that adapts, just as
  the color does. One exception: a baseline offset cannot be kept on such an image, so it is dropped.
- **Image properties are kept.** Rendering mode, alignment insets, symbol configuration and baseline
  offset are copied from the receiver, and so is the image orientation. A rotated photo stays
  rotated.
- **Scale is preserved.** Sizes and distances are given in points, as UIKit uses them.

## Contributing

Build instructions, the commit convention and the release process are in
[CONTRIBUTING.md](CONTRIBUTING.md).

## License

ImageProc is available under the MIT license. See [LICENSE](LICENSE).
