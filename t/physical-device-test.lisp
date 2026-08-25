;;;; t/physical-device-test.lisp
;;;;
;;;; Every test here calls into a real Vulkan loader (tagged :vulkan-icd) --
;;;; see instance-test.lisp's header for what backs that in local runs and
;;;; in CI. BEFORE-EACH/AFTER-EACH share one instance and physical device
;;;; across the IT blocks below instead of every test paying its own
;;;; create/destroy cost.
(in-package #:cl-vulkan-kit/test)

(describe
  "physical device queries"
  ;; BEFORE-EACH/AFTER-EACH have no :TAGS option of their own (unlike IT) --
  ;; each IT block below carries the tag instead, and these hooks only run
  ;; as part of running one of those.
  (before-each
    (let ((instance (create-instance)))
      (setf (gethash :instance *test-context*) instance
            (gethash :device *test-context*) (first (physical-devices instance)))))
  (after-each
    (destroy-instance (gethash :instance *test-context*)))

  (it "physical-devices returns at least one device"
    (:tags (list :vulkan-icd))
    (expect (gethash :device *test-context*) :to-be-truthy))

  (it "physical-device-properties reports a non-empty device name"
    (:tags (list :vulkan-icd))
    (let ((props (physical-device-properties (gethash :device *test-context*))))
      (expect (plusp (length (vk-physical-device-properties-device-name props))) :to-be-truthy)))

  (it "physical-device-properties reports a recognized device type"
    (:tags (list :vulkan-icd))
    (let ((props (physical-device-properties (gethash :device *test-context*))))
      (expect (vk-physical-device-properties-device-type props)
              :to-be-one-of '(:other :integrated-gpu :discrete-gpu :virtual-gpu :cpu))))

  (it "physical-device-properties' limits plist has plausible values"
    (:tags (list :vulkan-icd))
    (let* ((props (physical-device-properties (gethash :device *test-context*)))
           (limits (vk-physical-device-properties-limits props)))
      (expect (getf limits :max-image-dimension-2d) :to-be-greater-than 0)))

  (it "physical-device-queue-family-properties returns at least one family with decoded flags"
    (:tags (list :vulkan-icd))
    (let ((families (physical-device-queue-family-properties (gethash :device *test-context*))))
      (expect families :to-be-truthy)
      (expect (every (lambda (f) (listp (vk-queue-family-properties-queue-flags f))) families)
              :to-be-truthy)
      (expect (every (lambda (f) (plusp (vk-queue-family-properties-queue-count f))) families)
              :to-be-truthy))))
