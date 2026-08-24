# Getting started

## Install

Via a sibling checkout on `CL_SOURCE_REGISTRY` or ASDF's `*central-registry*`:

```lisp
(asdf:load-system "cl-vulkan-kit")
```

## Running the tests

```sh
sbcl --script run-tests.lisp
```

expects a sibling `../cl-weave/` checkout (the test system's only
dependency; see `cl-vulkan-kit.asd`).

There is nothing to bind to Vulkan yet — see the [roadmap](project/roadmap.md).
