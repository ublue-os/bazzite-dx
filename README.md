# Bazzite-DX Testing/Unstable Images

[![Build Bazzite DX](https://github.com/travis-fm/bazzite-dx-dev/actions/workflows/build.yml/badge.svg)](https://github.com/travis-fm/bazzite-dx-dev/actions/workflows/build.yml)

> [!IMPORTANT]
> At this time, only `unstable` images are available while the Bazzite dev team works on porting F44 to the base deck images. `testing` images will become available once deck builds are re-enabled there.

These are image builds for Bazzite-DX using the testing and unstable branches of Bazzite. If you don't know the implications of this, you should probably use the regular [Bazzite](https://github.com/ublue-os/bazzite) or [Bazzite-DX](https://github.com/ublue-os/bazzite-dx) builds instead.

Besides edits to the Github workflow to accomodate the testing/unstable tags, and cosign.pub for image signing, all code should be identical. The F44 branch is regularly merged into main during testing for ease of workflow running.

## How to rebase

`sudo bootc switch ghcr.io/travis-fm/bazzite-dx-dev-<IMAGE TYPE>:<RELEASE TAG>`

For example: `sudo bootc switch ghcr.io/travis-fm/bazzite-dx-dev-nvidia:unstable`
