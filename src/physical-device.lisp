;;;; src/physical-device.lisp
;;;;
;;;; Physical device enumeration and property queries.
(in-package #:cl-vulkan-kit)

(define-vk-instance-function %physical-devices "vkEnumeratePhysicalDevices" :checked-result
  ((instance sb-alien:system-area-pointer)
   (count (* (sb-alien:unsigned 32)))
   (devices (* sb-alien:system-area-pointer))))

(define-vk-instance-function %get-physical-device-properties "vkGetPhysicalDeviceProperties" :void
  ((physical-device sb-alien:system-area-pointer)
   (properties (* (sb-alien:struct physical-device-properties)))))

(define-vk-instance-function %get-physical-device-queue-family-properties
    "vkGetPhysicalDeviceQueueFamilyProperties" :void
  ((physical-device sb-alien:system-area-pointer)
   (count (* (sb-alien:unsigned 32)))
   (properties (* (sb-alien:struct queue-family-properties)))))

(defun physical-devices (instance)
  "The physical devices available through INSTANCE, as a list of opaque
handles for use with PHYSICAL-DEVICE-PROPERTIES and
PHYSICAL-DEVICE-QUEUE-FAMILY-PROPERTIES."
  (vk-enumerate sb-alien:system-area-pointer
                (lambda (count) (%physical-devices instance count (vk-null (* sb-alien:system-area-pointer))))
                (lambda (count devices) (%physical-devices instance count devices))
                (lambda (element-ptr) (%make-vk-physical-device (sb-alien:deref element-ptr) instance))))

(defun physical-device-properties (physical-device)
  "PHYSICAL-DEVICE's VK-PHYSICAL-DEVICE-PROPERTIES."
  (sb-alien:with-alien ((properties (sb-alien:struct physical-device-properties)))
    (%get-physical-device-properties physical-device (sb-alien:addr properties))
    (decode-physical-device-properties (sb-alien:addr properties))))

(defun physical-device-queue-family-properties (physical-device)
  "PHYSICAL-DEVICE's queue families, as a list of VK-QUEUE-FAMILY-PROPERTIES."
  (vk-enumerate (sb-alien:struct queue-family-properties)
                (lambda (count) (%get-physical-device-queue-family-properties
                                   physical-device count (vk-null (* (sb-alien:struct queue-family-properties)))))
                (lambda (count properties) (%get-physical-device-queue-family-properties
                                              physical-device count properties))
                #'decode-queue-family-properties))
