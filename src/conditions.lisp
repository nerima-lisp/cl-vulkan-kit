;;;; src/conditions.lisp
(in-package #:cl-vulkan-kit)

(define-condition cl-vulkan-kit-error (error) ()
  (:documentation "Base condition for every error this library signals."))
