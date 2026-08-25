;;;; src/ffi-primitives.lisp
;;;;
;;;; Generic SB-ALIEN plumbing used throughout this system, independent of
;;;; the Vulkan-specific code-generation macros in macros.lisp: null
;;;; pointers, FPU trap hygiene, C string arrays, fixed-size C array
;;;; decoding, and Vulkan's count-then-fill enumeration idiom.
(in-package #:cl-vulkan-kit)

;;; ---------------------------------------------------------------------
;;; Foreign-call hygiene
;;;
;;; Two properties every call into the Vulkan loader must have, established
;;; empirically against a real ICD (MoltenVK) before any of this was written:
;;;
;;; 1. A null pointer of a specific alien type must be spelled with that type
;;;    as a compile-time literal (SAP-ALIEN's type argument is not
;;;    evaluated), so VK-NULL is a macro, not a function.
;;; 2. A native call can leave the FPU trap flags in a state SBCL does not
;;;    expect (observed as a spurious FLOATING-POINT-OVERFLOW inside
;;;    vkCreateInstance on aarch64-darwin/MoltenVK); every call into the
;;;    loader is wrapped in WITH-VK-FP-TRAPS-MASKED.
;;; ---------------------------------------------------------------------

(defmacro vk-null (alien-type)
  "A null pointer alien of ALIEN-TYPE, a literal alien type specifier."
  `(sb-alien:sap-alien (sb-sys:int-sap 0) ,alien-type))

(defmacro with-vk-fp-traps-masked (&body body)
  "Run BODY with the floating-point traps the Vulkan loader/ICD may leave
unmasked disabled around the call, matching CL-USER-observed MoltenVK
behavior on aarch64-darwin."
  `(sb-int:with-float-traps-masked (:overflow :invalid :inexact :underflow :divide-by-zero)
     ,@body))

(defmacro with-vk-c-string-array ((var strings) &body body)
  "Bind VAR, for the extent of BODY, to a (* c-string) array holding
STRINGS (a list of Lisp strings, possibly empty -- an empty list binds VAR
to a null pointer rather than a zero-length allocation, matching what
Vulkan expects when e.g. enabledExtensionCount is 0)."
  (let ((n (gensym "N")) (i (gensym "I")) (items (gensym "ITEMS")))
    `(let* ((,items ,strings)
            (,n (length ,items)))
       (if (zerop ,n)
           (let ((,var (vk-null (* sb-alien:c-string)))) ,@body)
           (let ((,var (sb-alien:make-alien sb-alien:c-string ,n)))
             (unwind-protect
                  (progn
                    (loop for ,i from 0 for item in ,items
                          do (setf (sb-alien:deref ,var ,i) item))
                    ,@body)
               (sb-alien:free-alien ,var)))))))

;;; ---------------------------------------------------------------------
;;; Fixed-size C array decoding, used by DEFINE-VK-STRUCT's generated
;;; decoders (macros.lisp) for :C-STRING and :ARRAY fields.
;;; ---------------------------------------------------------------------

(defun vk-decode-c-string (alien-char-array length)
  "Decode a fixed-size C char array into a Lisp string, stopping at the
first NUL (or LENGTH, if the array is not NUL-terminated)."
  (with-output-to-string (out)
    (dotimes (i length)
      (let ((code (sb-alien:deref alien-char-array i)))
        (when (zerop code) (return))
        (write-char (code-char code) out)))))

(defun vk-decode-array (alien-array length)
  "Decode a fixed-size numeric C array into a Lisp vector."
  (let ((result (make-array length)))
    (dotimes (i length result)
      (setf (aref result i) (sb-alien:deref alien-array i)))))

;;; ---------------------------------------------------------------------
;;; VK-ENUMERATE
;;;
;;; Vulkan's ubiquitous "call once with NULL to get a count, allocate, call
;;; again to fill" idiom, implemented once as a CPS helper: COUNT-CALL and
;;; FILL-CALL are continuations this macro drives; DECODE is applied to each
;;; raw element the second call produced. A macro, not a function, because
;;; SB-ALIEN:MAKE-ALIEN requires its element type as a compile-time literal
;;; -- ELEMENT-ALIEN-TYPE is spelled out fresh at each call site, but the
;;; count/allocate/fill/decode/free algorithm itself is written once, here.
;;; ---------------------------------------------------------------------

(defmacro vk-enumerate (element-alien-type count-call fill-call decode)
  "Run Vulkan's count-then-fill enumeration idiom and return a list.

COUNT-CALL is called with a pointer to a zeroed uint32 count; FILL-CALL is
called with that same count pointer and a pointer to a freshly allocated
array of ELEMENT-ALIEN-TYPE. Both must signal (rather than return an error
code) on failure -- the checked wrappers DEFINE-VK-GLOBAL-FUNCTION and
DEFINE-VK-INSTANCE-FUNCTION produce do exactly that. DECODE is applied to a
pointer to each element of the filled array."
  (let ((count (gensym "COUNT")) (elements (gensym "ELEMENTS")) (i (gensym "I")))
    `(sb-alien:with-alien ((,count (sb-alien:unsigned 32) 0))
       (funcall ,count-call (sb-alien:addr ,count))
       (if (zerop ,count)
           '()
           (let ((,elements (sb-alien:make-alien ,element-alien-type ,count)))
             (unwind-protect
                  (progn
                    (funcall ,fill-call (sb-alien:addr ,count) ,elements)
                    (loop for ,i below ,count
                          collect (funcall ,decode (sb-alien:addr (sb-alien:deref ,elements ,i)))))
               (sb-alien:free-alien ,elements)))))))
