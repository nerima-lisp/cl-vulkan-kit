;;;; cl-vulkan-kit.asd
(in-package #:asdf-user)

(defsystem "cl-vulkan-kit"
  :description "Common Lisp CFFI bindings for the Vulkan graphics and compute API"
  :long-description "cl-vulkan-kit will provide Common Lisp bindings for
Vulkan, the cross-platform low-level graphics and compute API. The actual
CFFI bindings are not implemented yet -- this repository is provisioning
only. See docs/src/project/roadmap.md, and DEPENDENCY_POLICY.md's
4-condition external-dependency test in nerima-lisp/.github, which the PR
that adds a real cffi :depends-on must satisfy explicitly (cffi is only
precedented for cl-tmux today, an L4 repository)."
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
   (:file "core-test"))
  :perform (test-op (operation component)
             (declare (ignore operation component))
             (unless (funcall (symbol-function (find-symbol "RUN-TESTS" "CL-VULKAN-KIT/TEST")))
               (error "cl-vulkan-kit test suite failed"))))
