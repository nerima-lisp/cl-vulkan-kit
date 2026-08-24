# Roadmap

This repository is provisioning only today: GitHub repo, Cachix cache, CI,
and this documentation site exist; no Vulkan binding does.

## What implementing the binding requires

- **External dependency justification.** `cffi` is the obvious FFI layer,
  but nerima-lisp/.github's `DEPENDENCY_POLICY.md` defaults to rejecting a
  new external dependency. All four conditions in its "外部依存を追加する手続き"
  section need to be satisfied explicitly in the PR body, including that
  this repository is L2 or above (`cffi` is precedented only in `cl-tmux`,
  an L4 repository, today).
- **A nixpkgs package for the C library.** `pkgs.vulkan-loader` and
  `pkgs.vulkan-headers` exist in nixpkgs, so `nix flake check` can stay
  network-free — but a real *device* for tests needs either a software
  Vulkan implementation (nixpkgs' `mesa` provides the `lavapipe` /
  `llvmpipe` software ICD) or `continue-on-error` scoping like
  `cl-tty-kit`'s `contrib` job.
- **A headless CI testing strategy.** `nix flake check` runs on
  `ubuntu-latest` with no display server and no real GPU.
  `vkEnumeratePhysicalDevices` needs an ICD loader to find *something*
  (lavapipe covers that) even with zero real hardware; window/surface
  creation (`VK_KHR_surface` plus a windowing extension) additionally needs
  a display, the same constraint as `cl-glfw3-kit`.

## Not yet decided

- Whether this binds core Vulkan only, or also `VK_KHR_surface` /
  platform-surface extensions (which would create a dependency on
  windowing, i.e. on `cl-glfw3-kit`).
- Whether tests run against lavapipe in CI or stay at the marshalling layer.
