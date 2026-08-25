#.(in-package #:cl-vulkan-kit)

(cffi:defcfun ("vkCreateInstance" %create-instance) :int32
  (create-info :pointer) (allocator :pointer) (instance :pointer))

(cffi:defcfun ("vkDestroyInstance" %destroy-instance) :void
  (instance vulkan-instance) (allocator :pointer))

(cffi:defcfun ("vkEnumeratePhysicalDevices" %enumerate-physical-devices) :int32
  (instance vulkan-instance) (count :pointer) (devices :pointer))
