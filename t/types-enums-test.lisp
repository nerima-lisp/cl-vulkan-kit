;;;; t/types-enums-test.lisp
;;;;
;;;; Unit coverage for the DEFINE-VK-ENUM/DEFINE-VK-BITMASK-generated
;;;; decoders in src/types-enums.lisp. Pure data decoding -- no Vulkan
;;;; loader needed.
(in-package #:cl-vulkan-kit/test)

(describe
  "physical-device-type-keyword"
  (it "decodes VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU"
    (expect (physical-device-type-keyword 2) :to-equal :discrete-gpu))
  (it "decodes VK_PHYSICAL_DEVICE_TYPE_CPU"
    (expect (physical-device-type-keyword 4) :to-equal :cpu))
  (it "falls back to :UNKNOWN-ENUM-VALUE for an unrecognized value"
    (expect (physical-device-type-keyword 99) :to-equal (list :unknown-enum-value 99))))

(describe
  "queue-flags-keywords"
  (it "decodes a single bit"
    (expect (queue-flags-keywords #x00000001) :to-equal '(:graphics)))
  (it "decodes multiple set bits, in table order"
    (expect (queue-flags-keywords (logior #x00000001 #x00000002 #x00000004))
            :to-equal '(:graphics :compute :transfer)))
  (it "decodes a mask with no recognized bits as empty"
    (expect (queue-flags-keywords 0) :to-equal '()))
  (it "ignores unrecognized bits rather than raising"
    (expect (queue-flags-keywords #x00000020) :to-equal '())))
