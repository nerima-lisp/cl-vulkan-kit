# cl-vulkan-kit

Common Lisp bindings for [Vulkan](https://www.vulkan.org/), the
cross-platform, low-overhead graphics and compute API.

## Status

This system binds a first vertical slice of the Vulkan API: creating and
destroying a `VkInstance`, instance-level enumeration (API version,
extensions, layers), and physical-device enumeration, properties, and queue
family properties. That is enough to enumerate the GPUs on a machine and
inspect what they support — see [Getting started](getting-started.md).

Logical devices, queues, command buffers, memory, shaders, and the
swapchain/surface extensions are not bound yet; see the
[roadmap](project/roadmap.md) for what is next and why the surface
extensions in particular are still an open question.

Bound via [`sb-alien`](https://www.sbcl.org/manual/#Foreign-Function-Interface),
SBCL's built-in FFI, rather than an external `cffi` dependency — this system
stays at zero external Lisp dependencies, like every other repository in the
[nerima-lisp](https://github.com/orgs/nerima-lisp/repositories) org. See the
[API reference](reference/api.md) for every bound symbol.
