;;;; t/types-structs-test.lisp
;;;;
;;;; Unit coverage for a representative pair of DEFINE-VK-STRUCT decoders,
;;;; exercised against synthetic alien memory (not a real Vulkan loader):
;;;; DECODE-EXTENSION-PROPERTIES for the :c-string field-decode path, and
;;;; DECODE-EXTENT-3D for the plain :value path used as a nested struct
;;;; elsewhere (VkQueueFamilyProperties). The full struct set, including the
;;;; :bool32/:enum/:bitmask/:array/:struct paths this file does not cover,
;;;; is exercised end-to-end against a real ICD in physical-device-test.lisp.
(in-package #:cl-vulkan-kit/test)

(describe
  "decode-extension-properties"
  (it "decodes the extension name and spec version"
    (sb-alien:with-alien ((props (sb-alien:struct cl-vulkan-kit::extension-properties)))
      (let ((name "VK_KHR_surface"))
        (dotimes (i (length name))
          (setf (sb-alien:deref (sb-alien:slot props 'cl-vulkan-kit::extension-name) i)
                (char-code (char name i))))
        (setf (sb-alien:deref (sb-alien:slot props 'cl-vulkan-kit::extension-name) (length name)) 0)
        (setf (sb-alien:slot props 'cl-vulkan-kit::spec-version) 25))
      (let ((decoded (decode-extension-properties (sb-alien:addr props))))
        (expect (vk-extension-properties-extension-name decoded) :to-equal "VK_KHR_surface")
        (expect (vk-extension-properties-spec-version decoded) :to-equal 25)))))

(describe
  "decode-extent-3d"
  (it "decodes width/height/depth as plain integers"
    (sb-alien:with-alien ((extent (sb-alien:struct cl-vulkan-kit::extent-3d)))
      (setf (sb-alien:slot extent 'cl-vulkan-kit::width) 1920
            (sb-alien:slot extent 'cl-vulkan-kit::height) 1080
            (sb-alien:slot extent 'cl-vulkan-kit::depth) 1)
      (let ((decoded (decode-extent-3d (sb-alien:addr extent))))
        (expect (vk-extent-3d-width decoded) :to-equal 1920)
        (expect (vk-extent-3d-height decoded) :to-equal 1080)
        (expect (vk-extent-3d-depth decoded) :to-equal 1)))))
