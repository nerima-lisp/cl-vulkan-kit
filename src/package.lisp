;;;; src/package.lisp
(defpackage #:cl-vulkan-kit
  (:use #:cl)
  (:export
   ;; version
   #:library-version
   ;; conditions
   #:cl-vulkan-kit-error
   #:vulkan-call-failed
   #:vulkan-call-failed-function
   #:vulkan-call-failed-result
   ;; instance
   #:create-instance
   #:destroy-instance
   #:with-instance
   #:instance-api-version
   #:instance-extension-properties
   #:instance-layer-properties
   #:vk-make-api-version
   ;; physical device
   #:physical-devices
   #:physical-device-properties
   #:physical-device-queue-family-properties
   ;; VkExtensionProperties
   #:vk-extension-properties
   #:vk-extension-properties-extension-name
   #:vk-extension-properties-spec-version
   ;; VkLayerProperties
   #:vk-layer-properties
   #:vk-layer-properties-layer-name
   #:vk-layer-properties-spec-version
   #:vk-layer-properties-implementation-version
   #:vk-layer-properties-description
   ;; VkExtent3D
   #:vk-extent-3d
   #:vk-extent-3d-width
   #:vk-extent-3d-height
   #:vk-extent-3d-depth
   ;; VkQueueFamilyProperties
   #:vk-queue-family-properties
   #:vk-queue-family-properties-queue-flags
   #:vk-queue-family-properties-queue-count
   #:vk-queue-family-properties-timestamp-valid-bits
   #:vk-queue-family-properties-min-image-transfer-granularity
   ;; VkPhysicalDeviceProperties
   #:vk-physical-device-properties
   #:vk-physical-device-properties-api-version
   #:vk-physical-device-properties-driver-version
   #:vk-physical-device-properties-vendor-id
   #:vk-physical-device-properties-device-id
   #:vk-physical-device-properties-device-type
   #:vk-physical-device-properties-device-name
   #:vk-physical-device-properties-pipeline-cache-uuid
   #:vk-physical-device-properties-limits
   #:vk-physical-device-properties-sparse-properties))

(in-package #:cl-vulkan-kit)
