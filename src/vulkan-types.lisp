#.(in-package #:cl-vulkan-kit)

(cffi:define-foreign-library vulkan
  (:darwin ("libvulkan.1.dylib" "libvulkan.dylib"))
  (:unix ("libvulkan.so.1" "libvulkan.so"))
  (:windows ("vulkan-1.dll")))

(cffi:defctype vulkan-instance :pointer)
(cffi:defctype physical-device :pointer)
(cffi:defctype vulkan-version :uint32)

(cffi:defcstruct application-info
  (s-type :uint32) (p-next :pointer) (application-name :pointer)
  (application-version :uint32) (engine-name :pointer) (engine-version :uint32)
  (api-version vulkan-version))

(cffi:defcstruct instance-create-info
  (s-type :uint32) (p-next :pointer) (flags :uint32)
  (application-info :pointer) (enabled-layer-count :uint32)
  (enabled-layers :pointer) (enabled-extension-count :uint32)
  (enabled-extensions :pointer))
