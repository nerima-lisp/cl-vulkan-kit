# cl-vulkan-kit

[![CI](https://github.com/nerima-lisp/cl-vulkan-kit/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/nerima-lisp/cl-vulkan-kit/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Documentation](https://img.shields.io/badge/docs-MkDocs%20Material-0a7a5a)](https://nerima-lisp.github.io/cl-vulkan-kit/)

Common Lisp bindings for [Vulkan](https://www.vulkan.org/), targeting SBCL.
Instance creation, instance-level enumeration, and physical-device
enumeration/properties are bound and tested against a real Vulkan
implementation — see
[docs/src/project/roadmap.md](docs/src/project/roadmap.md) for what is not
bound yet.

Full documentation is published at <https://nerima-lisp.github.io/cl-vulkan-kit/>.
The source for that site lives in [docs/src/](docs/src/).

## Quick Start

```lisp
(asdf:load-system "cl-vulkan-kit")

(cl-vulkan-kit:with-instance (instance)
  (dolist (device (cl-vulkan-kit:physical-devices instance))
    (format t "~a~%"
            (cl-vulkan-kit:vk-physical-device-properties-device-name
             (cl-vulkan-kit:physical-device-properties device)))))
```

## Install

```nix
# flake.nix
inputs.cl-vulkan-kit = {
  url = "github:nerima-lisp/cl-vulkan-kit/v0.1.0";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Note the pinned tag. Consumers inside this org must pin a release tag rather
than follow the default branch.

## Documentation

- [Getting started](https://nerima-lisp.github.io/cl-vulkan-kit/getting-started/)
- [API reference](https://nerima-lisp.github.io/cl-vulkan-kit/reference/api/)
- [Roadmap](https://nerima-lisp.github.io/cl-vulkan-kit/project/roadmap/)

## Development

```sh
nix develop          # SBCL with CL_SOURCE_REGISTRY already set
nix run .#test       # run the test suite
nix flake check      # tests + formatting + docs, the same gate CI uses
nix fmt              # format Nix sources (treefmt)
```

Tests live in `t/` and run under [cl-weave](https://github.com/nerima-lisp/cl-weave),
the org's test framework.

## Contributing

See the org-wide [CONTRIBUTING](https://github.com/nerima-lisp/.github/blob/main/CONTRIBUTING.md)
guide and the [package standard](https://github.com/nerima-lisp/.github/blob/main/PACKAGE_STANDARD.md).

## Support

See [SUPPORT](https://github.com/nerima-lisp/.github/blob/main/SUPPORT.md).

## License

MIT. See [LICENSE](LICENSE).
