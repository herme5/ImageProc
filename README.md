[![tests](https://github.com/herme5/ImageProc/actions/workflows/tests.yml/badge.svg)](https://github.com/herme5/ImageProc/actions/workflows/tests.yml)

## Introduction

ImageProc is a collection of Swift utility methods for PNG image processing through the `UIImage` native API.

Sometimes icons have to be dynamically transformed, adding to the burden of the designer that needs to duplicate its rendered assets (e.g. same icons that have different colors, diferrent sizes...). Nevertheless, remember that static processing and pre-rendering is always better for the energy footprint of your apps.

## Demo

![](Demo/ImageProcApp/benchmark.png)

## Installation

ImageProc is a Swift package and requires iOS 15 or later.

In Xcode, use *File ▸ Add Package Dependencies…* and enter `https://github.com/herme5/ImageProc.git`.

Or add it to the dependencies of your own `Package.swift`:

```swift
.package(url: "https://github.com/herme5/ImageProc.git", from: "2.3.0")
```

> The package used to be hosted on GitLab, and `gitlab.com/herme5/ImageProc.git` still resolves from
> the archived repository. It is frozen at 2.3.0 and will not receive anything further — point your
> dependency at the GitHub URL above.

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

## Releasing

A git tag *is* the release. The version is not recorded anywhere in the tree — there is no manifest
field to bump — because Swift Package Manager consumers resolve tags straight from the remote. Tags
are bare `X.Y.Z`, with no `v` prefix.

### 1. Merge `develop` into `main`

Work happens on `develop` and reaches `main` through a **merge commit**, never a fast-forward, so
that the branch point stays visible in the history:

```sh
git checkout main
git merge --no-ff develop
git push origin main
```

Through a pull request instead, the merge method must be *Create a merge commit*, not squash or
rebase.

### 2. Tag it

```sh
./Scripts/bump.sh 2.4.0
```

The script fetches, refuses a version that is already tagged, and refuses to run at all until
`develop` has been merged into `main` — that last guard matters, because the step after it
hard-resets `develop`. It then tags `main`, pushes the branch and the tag by name, and verifies the
tag actually landed on the remote. Two things worth knowing before running it:

- **It is destructive to `develop`.** It hard-resets `develop` onto `origin/main` and force-pushes
  it, discarding anything that exists only there.
- **It stashes uncommitted changes and never pops them.** Commit your own work first, or recover it
  afterwards with `git stash pop`.

### 3. What the tag triggers

Pushing the tag starts `.github/workflows/release.yml`, which runs the full suite against the tagged
commit and, **only if it passes**, creates the GitHub release entry with notes generated from the log
since the previous tag. A release therefore cannot be published from a commit that does not build.

Nothing else is published: there is no package registry to push to, and consumers resolve the tag.
The entry is a record, which is why the releases tagged while CI had no runner installed perfectly
well without one.

### 4. Verify

```sh
gh run list --workflow=release.yml --limit 1     # the run that published it
gh release view 2.4.0                            # the entry and its notes
git ls-remote --tags origin refs/tags/2.4.0      # the tag consumers resolve
```

## Continuous integration

**Everything runs on GitHub Actions.** `.github/workflows/tests.yml` holds the suite: SwiftLint, the
tests on a simulator, a device build of the package — the kernel is compiled per-SDK, so a simulator
build says nothing about a device one — and a build of the demo app. It runs on pushes to `main` and
`develop`, on pull requests, and on demand.

The simulator is chosen at run time from whatever the runner image provides rather than named, because
that list changes with every image. Demo app signing is disabled rather than configured: the app
carries a development team so it can run on a device, and CI has no certificate for it.

`.github/workflows/release.yml` calls that same workflow for a tag instead of copying it, so the two
cannot drift, and publishes the release entry afterwards.

The project was hosted on GitLab until 2.3.0, with GitHub as a push mirror, and CI ran on a
self-hosted macOS runner. That runner stopped being available in August 2023 and every job since
ended as `stuck_pending_no_matching_runners`, which is how 2.0.0 through 2.3.0 came to be tagged from
commits nothing had built. Hosted macOS runners, free for public repositories, are what replaced it.
The GitLab repository is archived and read-only.
