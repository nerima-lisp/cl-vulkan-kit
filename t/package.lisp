;;;; t/package.lisp
(defpackage #:cl-vulkan-kit/test
  (:use #:cl)
  (:shadowing-import-from #:cl-weave #:describe)
  (:import-from #:cl-weave #:it #:expect #:signals #:run-all)
  (:import-from #:cl-vulkan-kit #:library-version #:cl-vulkan-kit-error)
  (:export #:run-tests))

(in-package #:cl-vulkan-kit/test)

(defun run-tests (&key (reporter :spec))
  (unless (run-all :reporter reporter :timeout-ms 20000)
    (error "cl-vulkan-kit test suite failed"))
  (format t "~&cl-vulkan-kit/test: successful completion with 0 failures~%")
  t)
