# API reference

## `library-version`

```lisp
(library-version)
```

Return this system's ASDF version string.

## Loader and instance API

`load-vulkan` loads the platform Vulkan loader and `unload-vulkan` releases it.
`with-vulkan-loader` owns the loader only when it loaded it itself, so nested
scopes do not invalidate an outer scope.

`create-instance` creates a core Vulkan instance and `destroy-instance`
releases it. `with-vulkan-instance` provides CPS-style cleanup. Vulkan
failures signal `vulkan-error`.

`enumerate-physical-devices` returns the instance's physical-device handles.
It retries transient `VK_INCOMPLETE` results up to `:max-attempts` (default 4)
and signals `vulkan-error` when the limit is exhausted.
