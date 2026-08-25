;;;; src/conditions.lisp
(in-package #:cl-vulkan-kit)

(define-condition cl-vulkan-kit-error (error) ()
  (:documentation "Base condition for every error this library signals."))

(define-condition vulkan-error (cl-vulkan-kit-error)
  ((result :initarg :result :reader vulkan-error-result))
  (:report (lambda (condition stream)
            (format stream "Vulkan operation failed with VkResult ~D"
                    (vulkan-error-result condition)))))
