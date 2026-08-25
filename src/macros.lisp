;;;; src/macros.lisp
;;;;
;;;; The data/macro layer that turns Vulkan's C ABI shape into Lisp: every
;;;; enum, struct, and function binding in this system is produced by one of
;;;; the macros below, driven by plain data tables in types-enums.lisp and
;;;; types-structs.lisp. The Vulkan knowledge lives entirely in the data
;;;; those macros are handed; the generic FFI plumbing they're built on is
;;;; in ffi-primitives.lisp.
(in-package #:cl-vulkan-kit)

;;; ---------------------------------------------------------------------
;;; VkResult
;;;
;;; Deliberately not a closed SB-ALIEN enum: VkResult gains values as
;;; extensions are enabled and the spec does not promise the set is closed.
;;; Bound as a plain 32-bit signed int at the FFI boundary; +VK-RESULT-TABLE+
;;; (in types-enums.lisp) maps the codes reachable from this system's bound
;;; functions to keywords, and VK-RESULT-KEYWORD falls back to
;;; (:UNKNOWN-RESULT n) for anything else.
;;; ---------------------------------------------------------------------

;; +VK-RESULT-TABLE+ is data (types-enums.lisp), loaded after this file;
;; DECLAIM avoids a spurious forward-reference warning for that ordering.
(declaim (special +vk-result-table+))

(defun vk-result-keyword (result)
  "Decode a raw VkResult integer into a keyword, or (:UNKNOWN-RESULT n)."
  (or (cdr (assoc result +vk-result-table+))
      (list :unknown-result result)))

(defun check-vk-result (result function-name)
  "Signal VULKAN-CALL-FAILED unless RESULT decodes to :SUCCESS or
:INCOMPLETE; otherwise return the decoded keyword."
  (let ((keyword (vk-result-keyword result)))
    (if (member keyword '(:success :incomplete))
        keyword
        (error 'vulkan-call-failed :function function-name :result keyword))))

;;; ---------------------------------------------------------------------
;;; DEFINE-VK-ENUM / DEFINE-VK-BITMASK
;;;
;;; Small, closed C enums (VkPhysicalDeviceType) and flag-bit sets
;;; (VkQueueFlagBits). Each entry in TABLE is (keyword . integer).
;;; ---------------------------------------------------------------------

(defmacro define-vk-enum (name table)
  "Define <NAME>-KEYWORD, decoding an integer via TABLE, an alist of
(keyword . integer)."
  (let ((decoder (intern (format nil "~a-KEYWORD" name)))
        (table-var (intern (format nil "+~a-TABLE+" name))))
    `(progn
       (defparameter ,table-var ,table)
       (defun ,decoder (value)
         (or (cdr (assoc value ,table-var))
             (list :unknown-enum-value value))))))

(defmacro define-vk-bitmask (name table)
  "Define <NAME>-KEYWORDS, decoding a bitmask integer into a list of
keywords via TABLE, an alist of (keyword . bit-integer)."
  (let ((decoder (intern (format nil "~a-KEYWORDS" name)))
        (table-var (intern (format nil "+~a-TABLE+" name))))
    `(progn
       (defparameter ,table-var ,table)
       (defun ,decoder (mask)
         (loop for (keyword . bit) in ,table-var
               unless (zerop (logand mask bit))
                 collect keyword)))))

;;; ---------------------------------------------------------------------
;;; DEFINE-VK-STRUCT
;;;
;;; One field table produces the SB-ALIEN struct type used to talk to the C
;;; ABI, and, in :DEFSTRUCT mode, a matching immutable Lisp record plus a
;;; decoder that copies alien memory into it. :PLIST mode skips the record
;;; and decodes straight to a plist instead -- used for the two structs
;;; (VkPhysicalDeviceLimits, VkPhysicalDeviceSparseProperties) whose field
;;; count would otherwise turn into dozens of rarely-used accessor exports.
;;;
;;; Each field is (name alien-type &optional decode), decode one of:
;;;   :value                    -- copied as-is (the default)
;;;   :bool32                   -- VkBool32 (uint32 0/1) -> Lisp boolean
;;;   (:c-string length)        -- fixed char array -> Lisp string, NUL-trimmed
;;;   (:array length)           -- fixed numeric array -> Lisp vector
;;;   (:struct decoder)         -- embedded struct -> (funcall decoder slot)
;;;   (:enum decoder)           -- int -> keyword via decoder
;;;   (:bitmask decoder)        -- int -> keyword list via decoder
;;;
;;; VK-DECODE-C-STRING/VK-DECODE-ARRAY, called by the :C-STRING/:ARRAY
;;; paths below, are in ffi-primitives.lisp.
;;; ---------------------------------------------------------------------

(defun %vk-field-decode-form (slot-form decode)
  "The form that decodes one field, given SLOT-FORM (a form evaluating to
the raw alien slot access) and its DECODE tag from the field spec."
  (if (eq decode :value)
      slot-form
      (destructuring-bind (tag &optional arg) (if (listp decode) decode (list decode))
        (ecase tag
          (:bool32 (list 'not (list 'zerop slot-form)))
          (:c-string (list 'vk-decode-c-string slot-form arg))
          (:array (list 'vk-decode-array slot-form arg))
          (:struct (list arg (list 'sb-alien:addr slot-form)))
          (:enum (list arg slot-form))
          (:bitmask (list arg slot-form))))))

(defun %vk-field-plist-inits (fields alien-var)
  "The flattened (keyword decode-form keyword decode-form ...) list for
FIELDS, decoding out of ALIEN-VAR (a symbol naming the in-scope alien)."
  (loop for field in fields
        for field-name = (first field)
        for decode = (or (third field) :value)
        for slot-form = (list 'sb-alien:slot alien-var (list 'quote field-name))
        append (list (intern (string field-name) :keyword)
                      (%vk-field-decode-form slot-form decode))))

(defmacro define-vk-struct (name fields &key structure-type (representation :defstruct))
  "Define the SB-ALIEN struct type for NAME from FIELDS, plus a decoder.

STRUCTURE-TYPE, when given, is the VkStructureType integer this struct's
sType is initialized to by INITIALIZE-<NAME> (only meaningful for \"in\"
structs the caller constructs, e.g. VkApplicationInfo).

REPRESENTATION is :DEFSTRUCT (default -- generates VK-<NAME> plus reader
accessors) or :PLIST (generates only a decoder returning a plist), or NIL
(the alien struct type only, for \"in\"-only structs never decoded back)."
  (let* ((decoder (intern (format nil "DECODE-~a" name)))
         (record-name (intern (format nil "VK-~a" name)))
         (constructor (intern (format nil "%MAKE-~a" record-name)))
         (alien-fields (mapcar (lambda (f) (list (first f) (second f))) fields))
         (plist-inits (%vk-field-plist-inits fields 'alien)))
    `(progn
       (sb-alien:define-alien-type nil
         (sb-alien:struct ,name ,@alien-fields))
       ,@(when structure-type
           `((defun ,(intern (format nil "INITIALIZE-~a" name)) (alien)
               (setf (sb-alien:slot alien 's-type) ,structure-type
                     (sb-alien:slot alien 'p-next) (vk-null (* t)))
               alien)))
       ,@(case representation
           ((nil) '())
           (:plist
            `((defun ,decoder (alien) (list ,@plist-inits))))
           (:defstruct
            ;; The public constructor spelling (MAKE-VK-<name>) is
            ;; suppressed: only DECODE, reading real alien memory, builds
            ;; one of these -- there is no validated way to build one from
            ;; arbitrary Lisp values.
            `((defstruct (,record-name (:constructor ,constructor) (:copier nil))
                ,@(loop for (field-name) in fields collect (list field-name nil :read-only t)))
              (defun ,decoder (alien) (,constructor ,@plist-inits)))))
       (quote ,name))))

;;; ---------------------------------------------------------------------
;;; DEFINE-VK-GLOBAL-FUNCTION / DEFINE-VK-INSTANCE-FUNCTION
;;;
;;; Global commands (vkCreateInstance and friends) are directly exported by
;;; the loader and bound once, at load time, via SB-ALIEN:DEFINE-ALIEN-ROUTINE.
;;;
;;; Instance-level commands (vkDestroyInstance and friends) are, per the
;;; Vulkan spec's own recommended architecture, resolved per-instance
;;; through vkGetInstanceProcAddr rather than linked directly -- this is
;;; also naturally CPS: *VK-INSTANCE-FUNCTIONS* accumulates a table of
;;; (name . continuation) pairs at macroexpansion time, and
;;; VK-BUILD-INSTANCE-DISPATCH-TABLE later drives that table, handing each
;;; continuation the resolved function for it to wrap and store.
;;; ---------------------------------------------------------------------

(defmacro define-vk-global-function (lisp-name c-name args)
  "Define LISP-NAME as a checked wrapper around the directly-linked global
Vulkan command C-NAME. ARGS is a list of (arg-name alien-type); the
underlying call always returns a VkResult, checked via CHECK-VK-RESULT."
  (let ((raw-name (intern (format nil "%~a" lisp-name))))
    `(progn
       (sb-alien:define-alien-routine (,c-name ,raw-name) (sb-alien:integer 32)
         ,@args)
       (defun ,lisp-name (,@(mapcar #'first args))
         (check-vk-result (with-vk-fp-traps-masked (,raw-name ,@(mapcar #'first args)))
                           ,c-name)))))

;; An instance's dispatch table is per-instance, not global: the spec
;; permits vkGetInstanceProcAddr to answer differently for different
;; instances (multiple ICDs, layers), so caching one resolved pointer per
;; Lisp process -- rather than per instance created -- would be a real
;; correctness gap, not just untidiness.
;;
;; VkPhysicalDevice commands are dispatched through their *owning instance's*
;; table too (there is no separate physical-device-level resolution in the
;; spec), so a physical device handle carries a back-reference to it.
(defstruct (%vk-instance (:constructor %make-vk-instance (handle dispatch-table))
                          (:copier nil))
  handle
  dispatch-table)

(defstruct (%vk-physical-device (:constructor %make-vk-physical-device (handle instance))
                                 (:copier nil))
  handle
  instance)

(defun vk-handle (wrapper)
  "The raw alien handle inside a %VK-INSTANCE or %VK-PHYSICAL-DEVICE."
  (etypecase wrapper
    (%vk-instance (%vk-instance-handle wrapper))
    (%vk-physical-device (%vk-physical-device-handle wrapper))))

(defun vk-dispatch-table (wrapper)
  "The owning instance's dispatch table for a %VK-INSTANCE or
%VK-PHYSICAL-DEVICE."
  (etypecase wrapper
    (%vk-instance (%vk-instance-dispatch-table wrapper))
    (%vk-physical-device (%vk-instance-dispatch-table (%vk-physical-device-instance wrapper)))))

(defvar *vk-instance-functions* '()
  "Alist of (c-name . builder), where builder is a function from a resolved
proc-address SAP to the SAP-ALIEN-wrapped, correctly-typed callable.
Accumulated by DEFINE-VK-INSTANCE-FUNCTION at macroexpansion time (SAP-ALIEN
needs its type as a compile-time literal, hence a builder closure per
function rather than a data-driven loop), consumed by
VK-BUILD-INSTANCE-DISPATCH-TABLE.")

(defun vk-build-instance-dispatch-table (instance-handle get-instance-proc-addr)
  "Resolve every DEFINE-VK-INSTANCE-FUNCTION-registered command against
INSTANCE-HANDLE, returning a hash table from C name to callable."
  (let ((table (make-hash-table :test 'equal)))
    (dolist (entry *vk-instance-functions* table)
      (destructuring-bind (c-name . builder) entry
        (let ((proc (funcall get-instance-proc-addr instance-handle c-name)))
          (when (sb-sys:sap= proc (sb-sys:int-sap 0))
            (error 'vulkan-call-failed :function c-name :result :unresolved-address))
          (setf (gethash c-name table) (funcall builder proc)))))))

(defmacro define-vk-instance-function (lisp-name c-name return-mode args)
  "Register LISP-NAME/C-NAME as an instance-level Vulkan command, resolved
through its owning instance's dispatch table (see VK-DISPATCH-TABLE,
VK-BUILD-INSTANCE-DISPATCH-TABLE). RETURN-MODE is :VOID or :CHECKED-RESULT.
ARGS is a list of (arg-name alien-type); the first argument is a
%VK-INSTANCE or %VK-PHYSICAL-DEVICE wrapper, unwrapped to its raw handle via
VK-HANDLE before the underlying call."
  (let ((alien-return (ecase return-mode
                         (:void 'sb-alien:void)
                         (:checked-result '(sb-alien:integer 32))))
        (wrapper-arg (first (first args)))
        (arg-names (mapcar #'first args))
        ;; Gensym'd rather than a literal FN: this binding surrounds the
        ;; caller-invisible body ARGS names into, but nothing stops a future
        ;; ARGS list from itself naming a parameter FN, which a literal
        ;; binding here would silently shadow.
        (fn-var (gensym "FN")))
    `(progn
       (pushnew (cons ,c-name
                       (lambda (resolved-proc)
                         (sb-alien:sap-alien
                          resolved-proc
                          (function ,alien-return ,@(mapcar #'second args)))))
                *vk-instance-functions*
                :key #'car :test #'string=)
       (defun ,lisp-name (,@arg-names)
         (let ((,fn-var (or (gethash ,c-name (vk-dispatch-table ,wrapper-arg))
                             (error 'vulkan-call-failed :function ,c-name :result :not-loaded))))
           ,(ecase return-mode
              (:void `(with-vk-fp-traps-masked
                        (sb-alien:alien-funcall ,fn-var (vk-handle ,wrapper-arg) ,@(rest arg-names))))
              (:checked-result
               `(check-vk-result
                 (with-vk-fp-traps-masked
                   (sb-alien:alien-funcall ,fn-var (vk-handle ,wrapper-arg) ,@(rest arg-names)))
                 ,c-name))))))))

;;; ---------------------------------------------------------------------
;;; WITH-INSTANCE
;;;
;;; CPS resource-scope macro: create an instance, run BODY with it bound,
;;; destroy it unconditionally on the way out.
;;; ---------------------------------------------------------------------

(defmacro with-instance ((var &rest create-instance-args) &body body)
  `(let ((,var (create-instance ,@create-instance-args)))
     (unwind-protect (progn ,@body)
       (destroy-instance ,var))))
