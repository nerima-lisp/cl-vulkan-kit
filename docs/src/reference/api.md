# API reference

All symbols below are in the `cl-vulkan-kit` package.

## Version

### `library-version`

```lisp
(library-version)
```

Return this system's version string, kept in sync with `cl-vulkan-kit.asd`'s
`:version`.

## Conditions

### `cl-vulkan-kit-error`

The base condition every error this system signals derives from.

### `vulkan-call-failed`

Signaled when a Vulkan command returns a `VkResult` other than
`VK_SUCCESS`/`VK_INCOMPLETE`, or when an instance-level command is called
before its address could be resolved. Readers: `vulkan-call-failed-function`
(the C function name, a string) and `vulkan-call-failed-result` (the decoded
`VkResult` keyword, e.g. `:error-out-of-device-memory`, or
`(:unknown-result n)` for a code this system does not have a name for).

## Instance

### `create-instance`

```lisp
(create-instance &key (application-name "cl-vulkan-kit") (application-version 0)
                       (engine-name "cl-vulkan-kit") (engine-version 0)
                       (api-version (vk-make-api-version 1 0))
                       (enabled-layer-names '())
                       (enabled-extension-names '()))
```

Create a `VkInstance`. On a portability-only ICD (MoltenVK on macOS,
verified directly against a real loader), `VK_KHR_portability_enumeration`
is requested and `VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR` set
automatically when that extension is available — callers do not need to
special-case that platform. Signals `vulkan-call-failed` on failure, e.g. for
a layer name that is not installed.

### `destroy-instance`

```lisp
(destroy-instance instance)
```

Destroy an instance created by `create-instance`.

### `with-instance`

```lisp
(with-instance (var &rest create-instance-args) &body body)
```

`create-instance`, bind it to `var` for the extent of `body`, and
`destroy-instance` it unconditionally on the way out — including when `body`
signals.

### `instance-api-version`

```lisp
(instance-api-version) ; => (values major minor patch)
```

The highest Vulkan API version the installed loader/ICDs support.

### `vk-make-api-version`

```lisp
(vk-make-api-version major minor &optional (patch 0) (variant 0))
```

`VK_MAKE_API_VERSION`: pack a version into the integer form `api-version`
fields expect.

### `instance-extension-properties`

```lisp
(instance-extension-properties &optional layer-name) ; => list of VK-EXTENSION-PROPERTIES
```

The instance extensions available, optionally restricted to those provided
by `layer-name` (a string). Signals `vulkan-call-failed` if `layer-name`
names a layer that is not installed.

### `instance-layer-properties`

```lisp
(instance-layer-properties) ; => list of VK-LAYER-PROPERTIES
```

The instance layers available.

## Physical device

### `physical-devices`

```lisp
(physical-devices instance) ; => list of opaque physical-device handles
```

The physical devices available through `instance`.

### `physical-device-properties`

```lisp
(physical-device-properties physical-device) ; => VK-PHYSICAL-DEVICE-PROPERTIES
```

### `physical-device-queue-family-properties`

```lisp
(physical-device-queue-family-properties physical-device) ; => list of VK-QUEUE-FAMILY-PROPERTIES
```

## Decoded records

Every Vulkan struct this system binds is copied out of foreign memory into
one of the immutable records below immediately after the call that fills
it — none of these hold a live pointer into Vulkan-owned memory. Records are
read-only; there is no public constructor, since there is no validated way
to build one of these from arbitrary Lisp values.

### `vk-extension-properties`

`vk-extension-properties-extension-name` (string),
`vk-extension-properties-spec-version` (integer).

### `vk-layer-properties`

`vk-layer-properties-layer-name` (string),
`vk-layer-properties-spec-version` (integer),
`vk-layer-properties-implementation-version` (integer),
`vk-layer-properties-description` (string).

### `vk-extent-3d`

`vk-extent-3d-width`, `vk-extent-3d-height`, `vk-extent-3d-depth` (integers).

### `vk-queue-family-properties`

`vk-queue-family-properties-queue-flags` (a list of keywords, e.g.
`(:graphics :compute :transfer)`), `vk-queue-family-properties-queue-count`
(integer), `vk-queue-family-properties-timestamp-valid-bits` (integer),
`vk-queue-family-properties-min-image-transfer-granularity`
(a `vk-extent-3d`).

### `vk-physical-device-properties`

`vk-physical-device-properties-api-version`,
`vk-physical-device-properties-driver-version`,
`vk-physical-device-properties-vendor-id`,
`vk-physical-device-properties-device-id` (integers),
`vk-physical-device-properties-device-type` (a keyword: `:other`,
`:integrated-gpu`, `:discrete-gpu`, `:virtual-gpu`, or `:cpu`),
`vk-physical-device-properties-device-name` (string),
`vk-physical-device-properties-pipeline-cache-uuid` (a 16-element vector of
octets), `vk-physical-device-properties-limits` (a plist — see below),
`vk-physical-device-properties-sparse-properties` (a plist — see below).

`limits` and `sparse-properties` are decoded to plists rather than records:
`VkPhysicalDeviceLimits` alone has 63 fields, and turning it into a record
would mean 63 rarely-used accessor exports for a struct most callers only
ever destructure a handful of fields from. Keys match the C field names in
kebab-case, e.g. `(getf limits :max-image-dimension-2d)`,
`(getf sparse-properties :residency-standard-2d-block-shape)`.
