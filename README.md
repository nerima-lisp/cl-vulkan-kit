# cl-vulkan-kit

[![CI](https://github.com/nerima-lisp/cl-vulkan-kit/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/nerima-lisp/cl-vulkan-kit/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Documentation](https://img.shields.io/badge/docs-MkDocs%20Material-0a7a5a)](https://nerima-lisp.github.io/cl-vulkan-kit/)

Common Lisp CFFI bindings for [Vulkan](https://www.vulkan.org/), targeting
SBCL. The package currently covers Vulkan loader management, instance
creation/destruction, and physical-device enumeration.

Full documentation is published at <https://nerima-lisp.github.io/cl-vulkan-kit/>.
The source for that site lives in [docs/src/](docs/src/).

## Quick Start

```lisp
(asdf:load-system "cl-vulkan-kit")

(cl-vulkan-kit:library-version)
;; => "1.0.0"

(cl-vulkan-kit:with-vulkan-loader
  (cl-vulkan-kit:with-vulkan-instance (instance)
    (cl-vulkan-kit:enumerate-physical-devices instance)))
```

## Install

```nix
# flake.nix
inputs.cl-vulkan-kit = {
  url = "github:nerima-lisp/cl-vulkan-kit/v1.0.0";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Note the pinned tag. Consumers inside this org must pin a release tag rather
than follow the default branch.

## Documentation

- [Getting started](https://nerima-lisp.github.io/cl-vulkan-kit/getting-started/)
- [API reference](https://nerima-lisp.github.io/cl-vulkan-kit/reference/api/)
- [Roadmap](https://nerima-lisp.github.io/cl-vulkan-kit/project/roadmap/)
- [Coding guidelines](https://nerima-lisp.github.io/cl-vulkan-kit/project/coding-guidelines/)

## Development

```sh
nix develop          # SBCL with CL_SOURCE_REGISTRY already set
nix run .#test       # run the test suite
nix flake check      # tests + formatting + docs, the same gate CI uses
nix fmt              # format Nix sources (treefmt)
```

Tests live in `t/`, use `cl-weave` directly through the ASDF test system, and
run with a five-second per-test timeout. The test system targets the checked-in
source tree, including the split Vulkan type, constant, function, loader,
instance, and device modules.

To enable the cl-weave coverage gate (100% expression and branch coverage), set
the coverage switch. Output paths are optional and default to a temporary
directory:

```sh
CL_VULKAN_KIT_COVERAGE=1 nix run .#test
# Equivalently, when the test app forwards arguments:
nix run .#test -- --coverage
```

## Contributing

See the org-wide [CONTRIBUTING](https://github.com/nerima-lisp/.github/blob/main/CONTRIBUTING.md)
guide and the [package standard](https://github.com/nerima-lisp/.github/blob/main/PACKAGE_STANDARD.md).

## Support

See [SUPPORT](https://github.com/nerima-lisp/.github/blob/main/SUPPORT.md).

## License

MIT. See [LICENSE](LICENSE).
