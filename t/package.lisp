;;;; t/package.lisp
(defpackage #:cl-vulkan-kit/test
  (:use #:cl)
  (:shadowing-import-from #:cl-weave #:describe)
  (:import-from #:cl-weave
                #:it #:it-isolated #:before-each #:after-each #:*test-context*
                #:expect #:signals #:run-all)
  (:import-from #:cl-vulkan-kit
                ;; version
                #:library-version
                ;; conditions
                #:cl-vulkan-kit-error #:vulkan-call-failed
                #:vulkan-call-failed-function #:vulkan-call-failed-result
                ;; instance
                #:create-instance #:destroy-instance #:with-instance
                #:instance-api-version #:instance-extension-properties #:instance-layer-properties
                #:vk-make-api-version
                ;; physical device
                #:physical-devices #:physical-device-properties #:physical-device-queue-family-properties
                ;; VkExtensionProperties / VkLayerProperties
                #:vk-extension-properties-extension-name #:vk-extension-properties-spec-version
                #:vk-layer-properties-layer-name #:vk-layer-properties-spec-version
                ;; VkExtent3D / VkQueueFamilyProperties
                #:vk-extent-3d-width #:vk-extent-3d-height #:vk-extent-3d-depth
                #:vk-queue-family-properties-queue-flags #:vk-queue-family-properties-queue-count
                #:vk-queue-family-properties-min-image-transfer-granularity
                ;; VkPhysicalDeviceProperties
                #:vk-physical-device-properties-device-name #:vk-physical-device-properties-device-type
                #:vk-physical-device-properties-api-version #:vk-physical-device-properties-limits
                #:vk-physical-device-properties-sparse-properties
                ;; internal decode/macro primitives, unit-tested directly
                #:vk-decode-c-string #:vk-decode-array #:vk-result-keyword #:check-vk-result
                #:physical-device-type-keyword #:queue-flags-keywords
                #:vk-null #:decode-extension-properties #:decode-extent-3d)
  (:export #:run-tests))

(in-package #:cl-vulkan-kit/test)

;; Real FFI calls (loading the platform Vulkan loader, creating/destroying a
;; real VkInstance) can be slower than the framework's usual default,
;; especially on a cold cache; 20s proved too tight against a real ICD.
(defun run-tests (&key (reporter :spec))
  (unless (run-all :reporter reporter :timeout-ms 60000)
    (error "cl-vulkan-kit test suite failed"))
  (format t "~&cl-vulkan-kit/test: successful completion with 0 failures~%")
  t)
