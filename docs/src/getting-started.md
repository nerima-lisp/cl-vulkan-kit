# Getting started

## Install

With the Nix development shell, dependencies and ASDF discovery are configured
automatically:

```lisp
(asdf:load-system "cl-vulkan-kit")
```

## Running the tests

```sh
nix run .#test
```

The test system declares `cl-weave` directly and applies a five-second timeout
to each test. Vulkan loader discovery is handled by CFFI and uses the
platform's standard Vulkan library name.

```lisp
(let ((instance (cl-vulkan-kit:create-instance
                 :application-name "sample")))
  (unwind-protect
       (format t "Physical devices: ~D~%"
               (length (cl-vulkan-kit:enumerate-physical-devices instance)))
    (cl-vulkan-kit:destroy-instance instance)))
```
