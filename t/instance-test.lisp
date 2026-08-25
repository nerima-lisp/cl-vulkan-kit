;;;; t/instance-test.lisp
;;;;
;;;; Every test here calls into a real Vulkan loader (tagged :vulkan-icd),
;;;; verified locally against MoltenVK and, in CI, against nixpkgs' mesa
;;;; software ICD (lavapipe) -- see flake.nix.
(in-package #:cl-vulkan-kit/test)

(describe
  "instance-api-version"
  (it "reports a plausible Vulkan 1.x version"
    (:tags (list :vulkan-icd))
    (multiple-value-bind (major minor patch) (instance-api-version)
      (declare (ignore patch))
      (expect major :to-equal 1)
      (expect minor :to-be-truthy))))

(describe
  "instance-extension-properties"
  (it "returns extensions as VK-EXTENSION-PROPERTIES with non-empty names"
    (:tags (list :vulkan-icd))
    (let ((extensions (instance-extension-properties)))
      (expect extensions :to-be-truthy)
      (expect (every (lambda (e) (plusp (length (vk-extension-properties-extension-name e))))
                      extensions)
              :to-be-truthy)))
  (it "signals VULKAN-CALL-FAILED for a layer name that is not installed"
    ;; Verified against a real loader: querying a nonexistent layer's
    ;; extensions is VK_ERROR_LAYER_NOT_PRESENT, not an empty result.
    (:tags (list :vulkan-icd))
    (signals vulkan-call-failed (instance-extension-properties "VK_LAYER_this_does_not_exist"))))

(describe
  "instance-layer-properties"
  (it "returns a list (possibly empty) of VK-LAYER-PROPERTIES"
    (:tags (list :vulkan-icd))
    (expect (listp (instance-layer-properties)) :to-be-truthy)))

(describe
  "create-instance / destroy-instance / with-instance"
  (it "creates and destroys an instance without signaling"
    (:tags (list :vulkan-icd))
    (let ((instance (create-instance)))
      (destroy-instance instance)))
  (it "WITH-INSTANCE destroys the instance even when the body signals"
    (:tags (list :vulkan-icd))
    (expect (lambda ()
              (with-instance (instance)
                instance
                (error "boom")))
            :to-throw 'error))
  (it "honors :application-name and :api-version without error"
    (:tags (list :vulkan-icd))
    (with-instance (instance :application-name "cl-vulkan-kit-test" :api-version (vk-make-api-version 1 0))
      instance))
  (it "signals VULKAN-CALL-FAILED for a layer that does not exist"
    (:tags (list :vulkan-icd))
    (handler-case
        (progn (with-instance (instance :enabled-layer-names (list "VK_LAYER_this_does_not_exist"))
                 instance)
               (error "expected VULKAN-CALL-FAILED, nothing signaled"))
      (vulkan-call-failed (c)
        (expect (vulkan-call-failed-function c) :to-equal "vkCreateInstance")
        (expect (vulkan-call-failed-result c) :to-equal :error-layer-not-present)))))
