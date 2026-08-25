;;;; t/package.lisp
(defpackage #:cl-vulkan-kit/test
  (:use #:cl)
  (:shadowing-import-from #:cl-weave #:describe)
  (:import-from #:cl-weave #:expect #:expect-assertions #:it #:with-soft-assertions)
  (:import-from #:cl-vulkan-kit
                #:cl-vulkan-kit-error
                #:library-version
                #:load-vulkan
                #:create-instance
                #:enumerate-physical-devices))

(in-package #:cl-vulkan-kit/test)
