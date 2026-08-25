# Coding guidelines for the Vulkan binding

This repository is provisioning only today — see the [roadmap](roadmap.md).
Nothing here applies to existing code, because there is essentially none to
apply it to (`library-version` and one base condition). This page exists so
that whoever writes the first real binding code starts from a considered
position instead of an empty one.

Everything below restates or specializes standards that already bind this
repository as an org member: [`CODING_STANDARD.md`][coding],
[`PACKAGE_STANDARD.md`][package], and [`DEPENDENCY_POLICY.md`][dependency]
in `nerima-lisp/.github`. Where this page adds a project-specific choice on
top of the org standard, that is called out explicitly. Where this page
would contradict the org standard, the org standard wins — file a PR against
this page instead of code that follows the contradiction.

[coding]: https://github.com/nerima-lisp/.github/blob/main/CODING_STANDARD.md
[package]: https://github.com/nerima-lisp/.github/blob/main/PACKAGE_STANDARD.md
[dependency]: https://github.com/nerima-lisp/.github/blob/main/DEPENDENCY_POLICY.md

## Macros: prefer a DSL where the binding itself is repetitive, not by default

`cl-prolog-kit` ships a "macro-first rule DSL" and `cl-cc-cps` exists solely
to CPS-transform the compiler's IR — both are org precedent for macro-heavy
design, but both apply macros to a genuine generation problem: hundreds of
structurally identical rules or IR nodes.

The Vulkan C API has the same shape: hundreds of `vkCreate*`/`vkDestroy*`
pairs, struct marshalling with the same slot-copy-to-foreign-memory pattern,
and enum/flag translation repeated per type. That repetition is the
justified case for `defmacro`:

- One macro that expands to a `vkCreate*`/`vkDestroy*` CFFI wrapper pair
  plus a `with-vk-*` unwind-protect'd allocator, driven by a table of
  Vulkan function names — not one hand-written wrapper per function.
- One macro that expands a Lisp struct/slot table into the matching
  `cffi:defcstruct` and marshalling functions, so the two never drift.
- Enum/flag translation generated from a data table (see
  [Data before logic](#data-before-logic)), not hand-written `case` forms
  per enum.

Do not reach for a macro where a function would do — a single `vkCreateFoo`
wrapper with no siblings is a function, not a DSL entry. The test for
"macro-first" here is the same test `cl-prolog-kit` and `cl-cc-cps` pass:
the macro exists because dozens-to-hundreds of call sites would otherwise
duplicate the same shape, not because macros are the house style.

## CPS: apply it to genuinely continuation-shaped Vulkan operations

`cl-cc-cps` (CPS transformation for the `cl-cc` compiler) and
`cl-prolog-kit` (CPS proof search) are the org's existing CPS precedent.
Neither transforms code that has no continuation-shaped control flow —
CPS earns its complexity where the underlying operation already is a
sequence of suspend/resume points.

Vulkan has real candidates:

- **Command buffer recording.** `vkBeginCommandBuffer` /
  `vkCmd*` / `vkEndCommandBuffer` is a linear sequence of effects against
  mutable state, a natural fit for a CPS-style `with-command-buffer`
  macro that threads a continuation through each `vkCmd*` step and only
  submits at the end.
- **Async GPU work.** Fence and semaphore waits, and any future
  swapchain-present loop, are suspend points; a CPS pipeline avoids nesting
  `unwind-protect`/callback code manually.
- **Multi-step device/queue/swapchain setup**, where a failure at step N
  must unwind exactly the resources acquired in steps `1..N-1` — the same
  problem `with-vk-*` allocator macros above solve, and CPS composes with
  that rather than replacing it.

Do not CPS-transform code with no suspend points (e.g. a struct-to-foreign
copy, a version getter) merely to use the technique — that produces
harder-to-read code for zero behavioral benefit, which is the opposite of
[Human-readable code](#human-readable-code).

## Data before logic

Vulkan bindings are dominated by data: struct layouts, enum value tables,
extension name strings, function-pointer-loading tables. Keep these as
plain data (`defparameter` alists/tables, or a small `defstruct` of
metadata) separate from the macros and functions that consume them, so the
data can be inspected, tested, and regenerated (e.g. from `vk.xml`)
independently of the marshalling logic that reads it. A macro that both
declares the table and hard-codes the logic loses that separation.

## Human-readable code

Readability review criteria from `CODING_STANDARD.md` apply as written:
files target 300 lines, cap at 500; lines cap at 100 columns; predicates
end in `-p`; conditions are named for the situation
(`vk-device-lost`, `vk-out-of-host-memory`), not mechanically suffixed
`-error`. A "complex function" concern only becomes real once binding code
exists — apply extract-function and early-return restructuring then, not
speculatively now.

## Dead code and backward compatibility

Follow `CODING_STANDARD.md`'s two-stage deprecation exactly: a minor
release keeps the old API alive behind a `style-warning`, the next major
release deletes it. There is no third option — do not keep permanently
deprecated shims, and do not delete without the warning period, since
sibling packages pin this repo by tag and rely on that window to migrate.
Because nothing is released yet, this only starts applying once
`cl-vulkan-kit` has its first tagged consumer-facing API.

## Testing with cl-weave

The test package already uses cl-weave's `describe`/`it`/`expect`/`signals`
(`t/package.lisp`). As real binding surface appears, reach for cl-weave's
less-basic features rather than re-implementing them:

- **Property-based generators** (`cl-weave/src/property-generators.lisp`)
  for round-tripping struct marshalling (`decode(encode(x)) == x` across
  generated Vulkan struct values) instead of hand-picked example struct's.
- **`signals`** for every documented Vulkan error path (e.g.
  `VK_ERROR_OUT_OF_DEVICE_MEMORY` mapped to a condition), not just the
  happy path — this is also how coverage stays meaningful rather than
  just high.
- One `t/<source>-test.lisp` per `src/<source>.lisp`, per
  `CODING_STANDARD.md`'s test-file naming rule, so file layout tells you
  what's untested by what's missing a pair.

Coverage floor per org policy is 90%, non-decreasing release over release.
This repository can aim higher (100%) as a project-specific target — that
is compatible with the org rule, which explicitly allows a repository that
already holds a higher bar to keep it, it just cannot become the org-wide
floor.

## Dependencies: use nerima-lisp packages directly, no adapter layer

`DEPENDENCY_POLICY.md`'s layering means `cl-vulkan-kit` may depend on L0–L2
packages without ceremony (a same-or-lower-layer edge). The following are
directly applicable when real binding work needs them — call their public
API as-is, do not wrap them behind a local re-export or adapter:

- **`cl-log-kit`** (L1) for structured logging of Vulkan validation-layer
  messages (`VK_EXT_debug_utils` callback output).
- **`cl-boundary-kit`** (L2) to define the swap point between "the real
  Vulkan loader" and "a software ICD (lavapipe) or a test double", per the
  roadmap's headless-CI question. This is the org's existing mechanism for
  exactly this kind of effect boundary — do not invent a bespoke
  swappable-backend protocol when `cl-boundary-kit` already is one.
- **`cl-host-kit`** (L1) for pathname/environment handling (locating
  shader files, `VK_ICD_FILENAMES`, etc.) instead of raw `uiop`/`sb-posix`
  calls.
- **`cl-glfw3-kit`** (sibling repo, layer TBD) if and when the "not yet
  decided" roadmap question about `VK_KHR_surface`/windowing is resolved
  toward binding surface creation — it already exists for exactly that
  pairing.

Adding any of these is still an "org-internal dependency" under
`DEPENDENCY_POLICY.md` and needs the PR to state the four required points
(layer/depth, closure size, API surface used, `flake.lock` impact) — this
page does not pre-approve that, it only says which packages are the direct
fit so nobody reaches for an adapter to avoid stating them.

### The external dependency: cffi

`cffi` is the only viable FFI layer and is already flagged in this
repository's own `.asd` and in the roadmap as requiring the org's
four-condition external-dependency justification before it can be added,
including the "this repository is L2 or above" condition. Resolving what
layer `cl-vulkan-kit` sits at (most likely L3, domain, per the layer table
in `DEPENDENCY_POLICY.md`) is a prerequisite for that PR, not something to
decide implicitly by adding the dependency.

## Environment: flake.nix and .asd

`cl-vulkan-kit.asd` already follows `PACKAGE_STANDARD.md`'s asd
conventions (`(in-package #:asdf-user)` first, string system designator,
fixed key order, `:in-order-to` test-op wiring, matching test system). Keep
new systems, if any (`cl-vulkan-kit/<ext>`), to the same conditions the
standard sets for extension systems: they must exist only to keep the main
system's `:depends-on` from growing, add exactly one sibling dependency,
and carry an `.asd` comment explaining why.

**Known discrepancy to resolve before relying on this flake.nix as a
template:** the current `systems` list declares both `x86_64-linux` and
`aarch64-darwin`, with a comment claiming several sibling repos already
reverted the org's 2026-08-01 Linux-only decision. The canonical
`PACKAGE_STANDARD.md` fetched from `nerima-lisp/.github` as of this writing
still states `systems = [ "x86_64-linux" ]` only, with no recorded further
reversion. Verify against the cited sibling repos' actual `flake.nix`
before treating this repository's two-platform declaration as correct —
if they have not in fact reverted, this repository's `flake.nix` is out of
conformance with the org's own live standard, not ahead of it.

## Command timeouts

Every CI job must set `timeout-minutes`, per `PACKAGE_STANDARD.md`. Locally,
`run-tests.lisp` -> `cl-vulkan-kit/test`'s `run-tests` already passes
`:timeout-ms 20000` to `cl-weave`'s `run-all` — keep that as real binding
tests are added, and extend it rather than dropping it if a future
integration test (e.g. against a software ICD) needs a longer bound; do not
remove the bound to make a slow test pass.

## Refactoring tool

Once there is Lisp source with actual structure to reshape, use
`paredit-cli` for renames, extractions, and control-flow reshaping instead
of hand-editing parens — the org already pulls it in as a `flake.nix`
dev-time input for exactly this. It has nothing to operate on today.
