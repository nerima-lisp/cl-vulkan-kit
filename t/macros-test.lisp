;;;; t/macros-test.lisp
;;;;
;;;; Unit coverage for the foreign-call primitives in src/macros.lisp that
;;;; do not need a real Vulkan loader: VK-NULL, the VkResult decoder, and
;;;; the fixed-size C array decoders.
(in-package #:cl-vulkan-kit/test)

(describe
  "vk-null"
  (it "produces a null pointer of the requested alien type"
    (expect (sb-sys:sap= (sb-alien:alien-sap (vk-null (* t))) (sb-sys:int-sap 0))
            :to-be-truthy)))

(describe
  "vk-result-keyword"
  (it "decodes VK_SUCCESS"
    (expect (vk-result-keyword 0) :to-equal :success))
  (it "decodes VK_INCOMPLETE"
    (expect (vk-result-keyword 5) :to-equal :incomplete))
  (it "decodes a known error code"
    (expect (vk-result-keyword -9) :to-equal :error-incompatible-driver))
  (it "falls back to :UNKNOWN-RESULT for a code outside the table"
    (expect (vk-result-keyword -999999) :to-equal (list :unknown-result -999999))))

(describe
  "check-vk-result"
  (it "returns :SUCCESS without signaling"
    (expect (check-vk-result 0 "test") :to-equal :success))
  (it "returns :INCOMPLETE without signaling"
    (expect (check-vk-result 5 "test") :to-equal :incomplete))
  (it "signals VULKAN-CALL-FAILED for any other code"
    (signals vulkan-call-failed (check-vk-result -1 "vkTestFunction")))
  (it "records the failing function name and decoded result on the condition"
    (handler-case (check-vk-result -1 "vkTestFunction")
      (vulkan-call-failed (c)
        (expect (vulkan-call-failed-function c) :to-equal "vkTestFunction")
        (expect (vulkan-call-failed-result c) :to-equal :error-out-of-host-memory)))))

(describe
  "vk-decode-c-string"
  (it "stops at the first NUL"
    (sb-alien:with-alien ((chars (sb-alien:array sb-alien:char 8)))
      (loop for (code . i) in '((104 . 0) (105 . 1) (0 . 2) (99 . 3))
            do (setf (sb-alien:deref chars i) code))
      (expect (vk-decode-c-string chars 8) :to-equal "hi")))
  (it "reads up to LENGTH when there is no NUL"
    (sb-alien:with-alien ((chars (sb-alien:array sb-alien:char 3)))
      (dotimes (i 3) (setf (sb-alien:deref chars i) (+ 97 i)))
      (expect (vk-decode-c-string chars 3) :to-equal "abc")))
  (it "decodes an all-NUL array as the empty string"
    (sb-alien:with-alien ((chars (sb-alien:array sb-alien:char 4)))
      (dotimes (i 4) (setf (sb-alien:deref chars i) 0))
      (expect (vk-decode-c-string chars 4) :to-equal ""))))

(describe
  "vk-decode-array"
  (it "decodes a fixed-size numeric array into a Lisp vector, in order"
    (sb-alien:with-alien ((nums (sb-alien:array (sb-alien:unsigned 32) 3)))
      (setf (sb-alien:deref nums 0) 10 (sb-alien:deref nums 1) 20 (sb-alien:deref nums 2) 30)
      (expect (vk-decode-array nums 3) :to-equalp #(10 20 30)))))
