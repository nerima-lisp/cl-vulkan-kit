# Getting started

## Install

Via a sibling checkout on `CL_SOURCE_REGISTRY` or ASDF's `*central-registry*`:

```lisp
(asdf:load-system "cl-vulkan-kit")
```

The Vulkan loader itself (`libvulkan.so.1` / `libvulkan.dylib`) is a native
library, not a Lisp dependency; `nix develop`/`nix build` put it on
`LD_LIBRARY_PATH`/`DYLD_LIBRARY_PATH` automatically (see `flake.nix`). Outside
Nix, make sure a Vulkan loader and at least one ICD (a GPU driver, or a
software implementation such as Mesa's lavapipe) are installed and
discoverable the normal way for your platform.

## List the GPUs on this machine

```lisp
(cl-vulkan-kit:with-instance (instance)
  (dolist (device (cl-vulkan-kit:physical-devices instance))
    (let ((properties (cl-vulkan-kit:physical-device-properties device)))
      (format t "~a (~a)~%"
              (cl-vulkan-kit:vk-physical-device-properties-device-name properties)
              (cl-vulkan-kit:vk-physical-device-properties-device-type properties))
      (dolist (family (cl-vulkan-kit:physical-device-queue-family-properties device))
        (format t "  queue family: ~a, count ~a~%"
                (cl-vulkan-kit:vk-queue-family-properties-queue-flags family)
                (cl-vulkan-kit:vk-queue-family-properties-queue-count family))))))
```

`with-instance` creates a `VkInstance` and destroys it on the way out, even
if the body signals — see [the API reference](reference/api.md) for the full
surface, and the [roadmap](project/roadmap.md) for what a logical device,
queues, and beyond would add on top of this.

## Running the tests

```sh
sbcl --script run-tests.lisp
```

expects a sibling `../cl-weave/` checkout (the test system's only
dependency; see `cl-vulkan-kit.asd`) and a working Vulkan loader + ICD --
`nix develop`/`nix flake check` provide both automatically, including a
software ICD on `x86_64-linux` so the tests need no GPU.
