;;;; src/instance.lisp
;;;;
;;;; VkInstance lifecycle and the instance-level enumeration functions
;;;; (version/extensions/layers) that do not need an instance to call.
(in-package #:cl-vulkan-kit)

;;; vkGetInstanceProcAddr itself is directly exported by the loader, but its
;;; signature -- returning a raw function pointer -- fits neither
;;; DEFINE-VK-GLOBAL-FUNCTION (always a checked VkResult) nor
;;; DEFINE-VK-INSTANCE-FUNCTION (resolved *through* this very function), so
;;; it is bound directly.
(sb-alien:define-alien-routine ("vkGetInstanceProcAddr" %get-instance-proc-addr)
    sb-alien:system-area-pointer
  (instance sb-alien:system-area-pointer)
  (name sb-alien:c-string))

(define-vk-global-function %vk-create-instance "vkCreateInstance"
  ((create-info (* (sb-alien:struct instance-create-info)))
   (allocator (* t))
   (out-instance (* sb-alien:system-area-pointer))))

(define-vk-global-function instance-api-version-raw "vkEnumerateInstanceVersion"
  ((out-version (* (sb-alien:unsigned 32)))))

(define-vk-global-function %vk-enumerate-instance-extension-properties
    "vkEnumerateInstanceExtensionProperties"
  ((layer-name sb-alien:c-string)
   (count (* (sb-alien:unsigned 32)))
   (properties (* (sb-alien:struct extension-properties)))))

(define-vk-global-function %vk-enumerate-instance-layer-properties
    "vkEnumerateInstanceLayerProperties"
  ((count (* (sb-alien:unsigned 32)))
   (properties (* (sb-alien:struct layer-properties)))))

(define-vk-instance-function %destroy-instance "vkDestroyInstance" :void
  ((instance sb-alien:system-area-pointer)
   (allocator (* t))))

(defun destroy-instance (instance)
  "Destroy INSTANCE, as created by CREATE-INSTANCE."
  (%destroy-instance instance (vk-null (* t))))

(defun instance-api-version ()
  "The highest Vulkan API version the installed loader/ICDs support, as
(values major minor patch)."
  (load-vulkan-loader)
  (sb-alien:with-alien ((version (sb-alien:unsigned 32) 0))
    (instance-api-version-raw (sb-alien:addr version))
    (values (ldb (byte 7 22) version) (ldb (byte 10 12) version) (ldb (byte 12 0) version))))

(defun vk-make-api-version (major minor &optional (patch 0) (variant 0))
  "VK_MAKE_API_VERSION(variant, major, minor, patch), vulkan_core.h:62-63."
  (logior (ash variant 29) (ash major 22) (ash minor 12) patch))

(defun instance-extension-properties (&optional layer-name)
  "The instance extensions available, optionally restricted to those
provided by LAYER-NAME (a string), as a list of VK-EXTENSION-PROPERTIES."
  (load-vulkan-loader)
  (vk-enumerate (sb-alien:struct extension-properties)
                (lambda (count) (%vk-enumerate-instance-extension-properties
                                   layer-name count (vk-null (* (sb-alien:struct extension-properties)))))
                (lambda (count properties) (%vk-enumerate-instance-extension-properties
                                              layer-name count properties))
                #'decode-extension-properties))

(defun instance-layer-properties ()
  "The instance layers available, as a list of VK-LAYER-PROPERTIES."
  (load-vulkan-loader)
  (vk-enumerate (sb-alien:struct layer-properties)
                (lambda (count) (%vk-enumerate-instance-layer-properties
                                   count (vk-null (* (sb-alien:struct layer-properties)))))
                (lambda (count properties) (%vk-enumerate-instance-layer-properties count properties))
                #'decode-layer-properties))

(defun %instance-extension-available-p (name)
  (find name (instance-extension-properties) :key #'vk-extension-properties-extension-name :test #'string=))

(defconstant +vk-instance-create-enumerate-portability-bit-khr+ #x00000001
  "VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR, vulkan_core.h:2834.")

(defun create-instance (&key (application-name "cl-vulkan-kit") (application-version 0)
                              (engine-name "cl-vulkan-kit") (engine-version 0)
                              (api-version (vk-make-api-version 1 0))
                              (enabled-layer-names '())
                              (enabled-extension-names '()))
  "Create a VkInstance. On a portability-only ICD (MoltenVK on macOS,
observed directly against a real loader), VK_KHR_portability_enumeration is
requested and VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR set
automatically when that extension is available -- callers do not need to
special-case that platform themselves."
  (load-vulkan-loader)
  (let* ((portability-p (%instance-extension-available-p "VK_KHR_portability_enumeration"))
         (extension-names (if portability-p
                               (cons "VK_KHR_portability_enumeration" enabled-extension-names)
                               enabled-extension-names)))
    (sb-alien:with-alien ((app-info (sb-alien:struct application-info))
                          (create-info (sb-alien:struct instance-create-info))
                          (instance-handle sb-alien:system-area-pointer))
      (initialize-application-info (sb-alien:addr app-info))
      (setf (sb-alien:slot app-info 'p-application-name) application-name
            (sb-alien:slot app-info 'application-version) application-version
            (sb-alien:slot app-info 'p-engine-name) engine-name
            (sb-alien:slot app-info 'engine-version) engine-version
            (sb-alien:slot app-info 'api-version) api-version)
      (with-vk-c-string-array (layer-names enabled-layer-names)
        (with-vk-c-string-array (extension-names-alien extension-names)
          (initialize-instance-create-info (sb-alien:addr create-info))
          (setf (sb-alien:slot create-info 'flags)
                (if portability-p +vk-instance-create-enumerate-portability-bit-khr+ 0)
                (sb-alien:slot create-info 'p-application-info) (sb-alien:addr app-info)
                (sb-alien:slot create-info 'enabled-layer-count) (length enabled-layer-names)
                (sb-alien:slot create-info 'pp-enabled-layer-names) layer-names
                (sb-alien:slot create-info 'enabled-extension-count) (length extension-names)
                (sb-alien:slot create-info 'pp-enabled-extension-names) extension-names-alien)
          (%vk-create-instance (sb-alien:addr create-info) (vk-null (* t)) (sb-alien:addr instance-handle))))
      ;; See macros.lisp's WITH-VK-FP-TRAPS-MASKED note: copy the handle out
      ;; of this WITH-ALIEN scalar slot into a plain Lisp binding before
      ;; making any further foreign calls.
      (let ((handle instance-handle))
        (%make-vk-instance
         handle
         (vk-build-instance-dispatch-table handle #'%get-instance-proc-addr))))))
