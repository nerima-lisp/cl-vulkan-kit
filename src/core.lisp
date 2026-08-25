;;;; src/core.lisp
#.(in-package #:cl-vulkan-kit)

(defun library-version ()
  (asdf:component-version (asdf:find-system "cl-vulkan-kit")))
