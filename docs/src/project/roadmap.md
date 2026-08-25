# Roadmap

## Done

Instance lifecycle, instance-level enumeration (API version, extensions,
layers), and physical-device enumeration/properties/queue-family properties
are bound and tested against a real Vulkan implementation — a software ICD
(Mesa's lavapipe) in CI on `x86_64-linux`, MoltenVK locally on
`aarch64-darwin`. See the [API reference](../reference/api.md) for the full
surface and [Getting started](../getting-started.md) for a working example.

Bound via `sb-alien`, SBCL's built-in FFI — not the external `cffi` library.
`nerima-lisp/.github`'s `CODING_STANDARD.md` prefers `sb-*` over a new
external dependency whenever it can cover the gap, and `sb-alien` can here
(dynamic library loading, C structs, calling through resolved function
pointers), so this system stays at zero external Lisp dependencies.

## Not yet bound

- **Logical devices, queues, command pools/buffers.** The next natural
  slice: `vkCreateDevice`, `vkGetDeviceQueue`, and enough of the command
  buffer API to submit something. Device-level commands need the same
  per-instance-style dispatch-table treatment this system already has for
  instance-level commands, resolved through `vkGetDeviceProcAddr` instead of
  `vkGetInstanceProcAddr`.
- **Memory allocation** (`VkPhysicalDeviceMemoryProperties`,
  `vkAllocateMemory`) and **shaders/pipelines/render passes** — needed
  before anything can actually draw or compute.
- **`VK_KHR_surface` and platform surface extensions** (window/swapchain
  creation). Not yet started, and not yet decided: binding a window surface
  needs a windowing library on the other side of it, which would be a
  dependency on `cl-glfw3-kit` — an org-internal dependency, so
  straightforward under `DEPENDENCY_POLICY.md`, but a real design decision
  (which windowing surface extensions to support, how much of GLFW's
  Vulkan-specific API to lean on) that has not been made yet.

## Testing without a GPU

`pkgs.mesa`'s software Vulkan ICD (llvmpipe/"lavapipe") gives `checks.default`
on `x86_64-linux` a real, headless Vulkan implementation — no GPU, no
network, nothing that needs to run outside the Nix sandbox — so the
`:vulkan-icd`-tagged tests in `t/instance-test.lisp` and
`t/physical-device-test.lisp` exercise real `vkCreateInstance`/
`vkEnumeratePhysicalDevices`/etc. calls in CI, not just compile them. There is
no lavapipe equivalent for `aarch64-darwin` in nixpkgs; `flake.nix` wires
MoltenVK there instead, for `nix develop`/`nix build` on the maintainer's own
machine (Metal-backed, so it needs a real GPU, unlike lavapipe).
