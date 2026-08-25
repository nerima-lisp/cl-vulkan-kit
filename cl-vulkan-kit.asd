;;;; cl-vulkan-kit.asd
(in-package #:asdf-user)

(defsystem "cl-vulkan-kit"
  :description "Common Lisp CFFI bindings for the Vulkan graphics and compute API"
  :long-description "cl-vulkan-kit provides Common Lisp CFFI bindings for
Vulkan, including loader management, instance creation and destruction, and
physical-device enumeration. See docs/src/project/roadmap.md for coverage."
  :author "takeokunn <bararararatty@gmail.com>"
  :maintainer "takeokunn <bararararatty@gmail.com>"
  :license "MIT"
  :version "1.0.0"
  :homepage "https://github.com/nerima-lisp/cl-vulkan-kit"
  :bug-tracker "https://github.com/nerima-lisp/cl-vulkan-kit/issues"
  :depends-on ("cffi")
  :pathname "src"
  :serial t
  :components
  ((:file "package")
   (:file "conditions")
   (:file "core")
   (:file "vulkan-types")
   (:file "vulkan-constants")
   (:file "vulkan-functions")
   (:file "vulkan-loader")
   (:file "vulkan-instance")
   (:file "vulkan-device"))
  :in-order-to ((test-op (test-op "cl-vulkan-kit/test"))))

(defsystem "cl-vulkan-kit/test"
  :description "Test system for cl-vulkan-kit"
  :author "takeokunn <bararararatty@gmail.com>"
  :maintainer "takeokunn <bararararatty@gmail.com>"
  :license "MIT"
  :version "1.0.0"
  :homepage "https://github.com/nerima-lisp/cl-vulkan-kit"
  :bug-tracker "https://github.com/nerima-lisp/cl-vulkan-kit/issues"
  :depends-on ("cl-vulkan-kit" "cl-weave")
  :pathname "t"
  :serial t
  :components
  ((:file "package")
   (:file "core-test"))
  :perform (test-op (operation component)
             (declare (ignore operation component))
             (unless (uiop:symbol-call :cl-weave :run-all
                                       :reporter :spec
                                       :pass-with-no-tests nil
                                       :timeout-ms 5000)
               (error "cl-vulkan-kit test suite failed"))))
