;;;; cl-vulkan-kit.asd
(in-package #:asdf-user)

(defsystem "cl-vulkan-kit"
  :description "Common Lisp bindings for the Vulkan graphics and compute API"
  :long-description "cl-vulkan-kit binds a first vertical slice of Vulkan:
instance creation/destruction, instance-level enumeration (version,
extensions, layers), and physical-device enumeration/properties/queue-family
properties. Bound via SB-ALIEN, SBCL's built-in FFI, not the external cffi
library -- nerima-lisp/.github's CODING_STANDARD.md prefers sb-* over a new
external dependency whenever it can cover the gap, and here it can, so this
system stays at zero external Lisp dependencies like every other repository
in the org. See docs/src/project/roadmap.md for what is bound and what
(logical devices, queues, command buffers, memory, swapchain/surface) is
not yet."
  :author "takeokunn <bararararatty@gmail.com>"
  :maintainer "takeokunn <bararararatty@gmail.com>"
  :license "MIT"
  :version "0.1.0"
  :homepage "https://github.com/nerima-lisp/cl-vulkan-kit"
  :bug-tracker "https://github.com/nerima-lisp/cl-vulkan-kit/issues"
  :source-control (:git "https://github.com/nerima-lisp/cl-vulkan-kit.git")
  :depends-on ()
  :pathname "src"
  :serial t
  :components
  ((:file "package")
   (:file "conditions")
   (:file "foreign-library")
   (:file "ffi-primitives")
   (:file "macros")
   (:file "types-enums")
   (:file "types-structs")
   (:file "instance")
   (:file "physical-device")
   (:file "core"))
  :in-order-to ((test-op (test-op "cl-vulkan-kit/test"))))

(defsystem "cl-vulkan-kit/test"
  :description "Test system for cl-vulkan-kit"
  :author "takeokunn <bararararatty@gmail.com>"
  :maintainer "takeokunn <bararararatty@gmail.com>"
  :license "MIT"
  :version "0.1.0"
  :homepage "https://github.com/nerima-lisp/cl-vulkan-kit"
  :bug-tracker "https://github.com/nerima-lisp/cl-vulkan-kit/issues"
  :source-control (:git "https://github.com/nerima-lisp/cl-vulkan-kit.git")
  :depends-on ("cl-vulkan-kit" "cl-weave")
  :pathname "t"
  :serial t
  :components
  ((:file "package")
   (:file "core-test")
   (:file "macros-test")
   (:file "types-enums-test")
   (:file "types-structs-test")
   (:file "instance-test")
   (:file "physical-device-test"))
  :perform (test-op (operation component)
             (declare (ignore operation component))
             (unless (funcall (symbol-function (find-symbol "RUN-TESTS" "CL-VULKAN-KIT/TEST")))
               (error "cl-vulkan-kit test suite failed"))))
