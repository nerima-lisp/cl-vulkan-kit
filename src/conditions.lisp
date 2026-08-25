;;;; src/conditions.lisp
(in-package #:cl-vulkan-kit)

(define-condition cl-vulkan-kit-error (error) ()
  (:report "cl-vulkan-kit signaled an error with no more specific report.")
  (:documentation "Base condition for every error this library signals."))

(define-condition vulkan-call-failed (cl-vulkan-kit-error)
  ((function :initarg :function :reader vulkan-call-failed-function)
   (result :initarg :result :reader vulkan-call-failed-result))
  (:report (lambda (condition stream)
             (format stream "~a failed: ~a"
                     (vulkan-call-failed-function condition)
                     (vulkan-call-failed-result condition))))
  (:documentation "A Vulkan command returned a VkResult other than
VK_SUCCESS/VK_INCOMPLETE, or an instance-level command was called before
its address was resolved."))
