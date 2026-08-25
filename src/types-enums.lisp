;;;; src/types-enums.lisp
;;;;
;;;; Plain data: every table here is transcribed from
;;;; KhronosGroup/Vulkan-Headers/include/vulkan/vulkan_core.h
;;;; (VK_HEADER_VERSION 360, Vulkan 1.4), not recalled from memory. The
;;;; DEFINE-VK-ENUM/DEFINE-VK-BITMASK macros in macros.lisp turn each table
;;;; into a decoder; see this file's docstrings for the header line ranges.
(in-package #:cl-vulkan-kit)

;;; VkResult (vulkan_core.h:140-204) is intentionally NOT one of these --
;;; it is open-ended (extensions add codes) and is handled separately by
;;; VK-RESULT-KEYWORD in macros.lisp. This table lists only the codes the
;;; functions this system binds can actually return, per their "Return
;;; Codes" spec sections.
(defparameter +vk-result-table+
  '((0 . :success)                            ; VK_SUCCESS
    (1 . :not-ready)                          ; VK_NOT_READY
    (5 . :incomplete)                         ; VK_INCOMPLETE
    (-1 . :error-out-of-host-memory)          ; VK_ERROR_OUT_OF_HOST_MEMORY
    (-2 . :error-out-of-device-memory)        ; VK_ERROR_OUT_OF_DEVICE_MEMORY
    (-3 . :error-initialization-failed)       ; VK_ERROR_INITIALIZATION_FAILED
    (-6 . :error-layer-not-present)           ; VK_ERROR_LAYER_NOT_PRESENT
    (-7 . :error-extension-not-present)       ; VK_ERROR_EXTENSION_NOT_PRESENT
    (-9 . :error-incompatible-driver)))       ; VK_ERROR_INCOMPATIBLE_DRIVER

;; VkPhysicalDeviceType (vulkan_core.h:2226-2233)
(define-vk-enum physical-device-type
  '((0 . :other)
    (1 . :integrated-gpu)
    (2 . :discrete-gpu)
    (3 . :virtual-gpu)
    (4 . :cpu)))

;; VkQueueFlagBits (vulkan_core.h:2862-2873) -- only the 5 core-spec bits;
;; VK_QUEUE_VIDEO_*_BIT_KHR/VK_QUEUE_OPTICAL_FLOW_BIT_NV/
;; VK_QUEUE_DATA_GRAPH_BIT_ARM require extensions this system does not
;; enable, so a set bit there would be meaningless to decode.
(define-vk-bitmask queue-flags
  '((:graphics . #x00000001)
    (:compute . #x00000002)
    (:transfer . #x00000004)
    (:sparse-binding . #x00000008)
    (:protected . #x00000010)))
