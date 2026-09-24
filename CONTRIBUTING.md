# Contributing to ImageProc

## Setting up

You need Xcode 26 or later with an iOS simulator installed. Since Xcode 26 the Metal compiler is a
separate component, and the package cannot compile its Core Image kernels without it:

```sh
xcodebuild -downloadComponent MetalToolchain
```

> **`swift build` does not work.** The package is iOS-only and every source imports UIKit, so it fails
on the host. Build with Xcode or `xcodebuild`.

## Building and testing

```sh
# Any available simulator works; see `xcrun simctl list devices available`
xcodebuild -scheme ImageProc -destination 'platform=iOS Simulator,name=iPad (A16)' test

# A single suite, or a single test: the identifiers are Swift Testing's type and function names
xcodebuild -scheme ImageProc -destination 'platform=iOS Simulator,name=iPad (A16)' \
  -only-testing:ImageProcTests/GeometryTests test
xcodebuild -scheme ImageProc -destination 'platform=iOS Simulator,name=iPad (A16)' \
  -only-testing:'ImageProcTests/GeometryTests/flippingHorizontallyMirrorsLeftAndRight()' test

# Without the benchmarks, as CI runs it
TEST_RUNNER_SKIP_BENCHMARKS=1 xcodebuild -scheme ImageProc \
  -destination 'platform=iOS Simulator,name=iPad (A16)' test

# A device build. The kernels are compiled per SDK, so a simulator build says nothing about a device one
xcodebuild -scheme ImageProc -destination 'generic/platform=iOS' build

# The demo app, which renders every operation with its timing
xcodebuild -project Demo/ImageProcApp.xcodeproj -scheme ImageProcApp \
  -destination 'platform=iOS Simulator,name=iPad (A16)' build

swiftlint --strict
```

## Layout

| Path | Role |
| --- | --- |
| `Sources/ImageProc` | The library. |
| `Kernels/` | The Metal kernels and the script that compiles them. |
| `Plugins/CIKernelCompiler` | The build tool plugin that runs that script. |
| `Tests/ImageProcTests` | Tests, with their fixtures in `Resources/TestAssets.xcassets`. |
| `Demo/ImageProcApp.xcodeproj` | The demo app, depending on the package by local path. |

**Keep the kernels in `Kernels/`, outside `Sources/`.** Xcode compiles any `.metal` file inside a
target without the `-fcikernel` flag, which produces a library Core Image cannot load, and SwiftPM
offers no way to add the flag. The plugin compiles them by hand instead.

The test fixtures and the demo app's assets are **two separate catalogs**, because SwiftPM cannot
share one file between targets. Keep them in sync by hand.

## Tests

The suite uses Swift Testing and is organized by topic:

| Directory | What it holds |
| --- | --- |
| `Support/` | Fixtures drawn in code, a pixel reader, tolerances, tags, and the shared operation catalog. |
| `Color/` | `UIColor`: hexadecimal codes, components, adjustments. |
| `Operations/` | What each operation does, one file per README section, asserted on real pixels and sizes. |
| `Behavior/` | The guarantees every operation owes: robustness, options, orientation, dynamic colors, chaining. |
| `Implementations/` | The internal expansion variants against each other. Package users only get Metal. |
| `Benchmarks/` | Timings, printed and never asserted. Skipped when `SKIP_BENCHMARKS` is set. Run them alone (`-only-testing:ImageProcTests/BenchmarkTests`) for numbers worth comparing, since the other suites run in parallel. |

- **`Support/Operations.swift` lists every public operation once.** The `Behavior/` suites run over
  that list, so a new operation is added there and is immediately held to every guarantee.
- **One behavior per test**, named by a sentence: `@Test("flipping horizontally mirrors left and
  right") func flippingHorizontallyMirrorsLeftAndRight()`. Cases go in `arguments:`, not loops, so a
  failure names its case.
- **Assert what the operation does, not that it returned.** Every operation returns a non-optional
  image, so a non-nil check proves nothing. Read pixels with `Bitmap` and compare them with the named
  `Tolerance`s.
- **Draw fixtures in code** where the test can be read off the drawing. The asset catalog is for tests
  about real bundled assets.
- **Tests run in parallel.** Pick an expansion variant with
  `UIImage.$_expandImplementation.withValue(…) { … }`, which is scoped to the closure. Never assign a
  global.
- A known library bug is recorded with `withKnownIssue`, which keeps the suite green and fails once the
  bug is fixed, as a reminder to remove it.

## Code conventions

- Most of the API extends **`UIImage`** and **`UIColor`**. Be careful about access modifiers to avoid unintended symbol exposure. When adding one, build with
  `BUILD_LIBRARY_FOR_DISTRIBUTION=YES SWIFT_EMIT_MODULE_INTERFACE=YES` and read the emitted
  `.swiftinterface`. It is the authoritative list of what ships.
- **Never trap.** An operation that cannot run prints why and returns the receiver unchanged.
- **Operations are non-mutating and named as past participles** (`colorized`, `expanded`, `scaled`),
  returning a new image with the receiver's options carried over.
- **Work in buffer space, not in `size`.** Using `size` applies a non-`.up` orientation twice. The
  orientation tests use non-square fixtures on purpose, because square ones hide this.
- **Every operation handles dynamic colors and images** through the `_perColorTrait` guard at its top.
  A new operation needs it too.

## Commit messages

Every commit, follows the same convention:

- **An imperative sentence** saying what the commit does: capitalized, no trailing period, at most 72
  characters. For example `Expand on the GPU, gathering instead of scattering`, not `Fixed expand.`
  or `wip`.
- **A body only when the reason is not obvious**, after a blank line and wrapped at 72 columns.
- **One logical change per commit.** Fix-ups, typos and "Fix CI" retries are squashed into the commit
  they fix before `develop` is merged.
- **Version bumps** read `Bump the version to X.Y.Z`, when the tree records a version at all.
- **Release merges** keep git's default message, `Merge branch 'develop' into 'main'`, and are always
  `--no-ff`. The tag carries the version, not the message.

## Branches

Work happens on `develop`. `main` holds only the initial commit and one merge commit per release, so
it reads as the list of releases.

`main` is protected: it cannot be force-pushed or deleted, changes arrive through a pull request that
only allows *Create a merge commit*, and the SwiftLint and Test checks must pass. Release tags cannot
be moved or deleted once pushed.

## Releasing

A git tag *is* the release. The version is not recorded anywhere in the tree, because Swift Package
Manager consumers resolve tags straight from the remote, so there is no manifest field to bump. Tags
are bare `X.Y.Z`, with no `v` prefix.

### 1. Merge `develop` into `main`

`develop` reaches `main` through a **merge commit**, never a fast-forward, so the branch point stays
visible in the history:

```sh
git checkout main
git merge --no-ff develop
git push origin main
```

Through a pull request instead, the merge method must be *Create a merge commit*.

### 2. Tag it

```sh
./Scripts/bump.sh 2.4.0
```

The script fetches and refuses a version that is already tagged. It also refuses to run until
`develop` has been merged into `main`, which matters because the next step hard-resets `develop`. It
then tags `main`, pushes the branch and the tag by name, and checks that the tag reached the remote.
Two things to know before running it:

- **It is destructive to `develop`.** It hard-resets `develop` onto `origin/main` and force-pushes
  it, discarding anything that exists only there.
- **It stashes uncommitted changes and never pops them.** Commit your own work first, or recover it
  afterwards with `git stash pop`.

### 3. What the tag triggers

Pushing the tag starts `.github/workflows/release.yml`, which runs the full suite against the tagged
commit and, **only if it passes**, creates the GitHub release with notes generated from the log since
the previous tag. A release cannot be published from a commit that does not build.

Nothing else is published. There is no package registry to push to, and consumers resolve the tag
directly.

### 4. Verify

```sh
gh run list --workflow=release.yml --limit 1     # the run that published it
gh release view 2.4.0                            # the release and its notes
git ls-remote --tags origin refs/tags/2.4.0      # the tag consumers resolve
```

## Continuous integration

Everything runs on GitHub Actions. `.github/workflows/tests.yml` runs four jobs side by side:
SwiftLint, the tests on a simulator, a device build of the package and a build of the demo app. It
runs on pushes to `develop` that touch more than documentation, on pull requests, and on demand.
`main` is not tested on push, because it only receives merges of a `develop` tip that already passed.
`release.yml` calls the same workflow for a tag rather than copying it, so the two cannot drift apart.

CI skips the `Benchmarks` suite, which only prints timings and takes over a minute on the runner.
Locally it runs as part of the suite; set `TEST_RUNNER_SKIP_BENCHMARKS=1` in front of
`xcodebuild test` to skip it there too.

The simulator is picked at run time from whatever the runner image provides, since that list changes
with every image. The demo app is built with signing disabled, because CI has no certificate for its
development team.

Until 2.3.0 the project lived on GitLab, with CI on a self-hosted macOS runner. That runner stopped
being available in August 2023, so 2.0.0 through 2.3.0 were tagged from commits no CI had built. The
GitLab repository is now archived.
