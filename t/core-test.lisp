;;;; t/core-test.lisp
(in-package #:cl-vulkan-kit/test)

(describe
  "cl-vulkan-kit"
  (it "reports its own version, matching the .asd :version"
    (expect (library-version) :to-equal "0.1.0"))

  (it "CL-VULKAN-KIT-ERROR is a proper ERROR subtype"
    (expect (subtypep 'cl-vulkan-kit-error 'error) :to-be-truthy)))
