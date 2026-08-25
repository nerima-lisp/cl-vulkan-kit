;;;; t/core-test.lisp
(in-package #:cl-vulkan-kit/test)

(defmacro with-function-definition ((name function) &body body)
  `(let ((original (symbol-function ',name)))
     (unwind-protect
          (progn
            (setf (symbol-function ',name) ,function)
            ,@body)
       (setf (symbol-function ',name) original))))

(describe "public API"
  (it "reports its release version"
    (expect (library-version) :to-equal "1.0.0"))
  (it "exposes the Vulkan lifecycle"
    (with-soft-assertions
      (expect (subtypep 'cl-vulkan-kit-error 'error) :to-be t)
      (expect (fboundp 'load-vulkan) :to-be-truthy)
      (expect (fboundp 'create-instance) :to-be-truthy)
      (expect (fboundp 'enumerate-physical-devices) :to-be-truthy)
      (expect (macro-function 'cl-vulkan-kit:with-vulkan-loader) :to-be-truthy)
      (expect (macro-function 'cl-vulkan-kit:with-vulkan-instance) :to-be-truthy))
    (expect-assertions 6)))

(describe "result handling"
  (it "accepts successful and incomplete Vulkan results"
    (expect (cl-vulkan-kit::%check-result 0) :to-equal 0)
    (expect (cl-vulkan-kit::%check-result 5 :allow-incomplete t) :to-equal 5))
  (it "signals a typed error for failed results"
    (let ((condition (handler-case (cl-vulkan-kit::%check-result -1)
                       (cl-vulkan-kit:vulkan-error (condition) condition))))
      (expect (typep condition 'cl-vulkan-kit:vulkan-error) :to-be t)
      (expect (cl-vulkan-kit:vulkan-error-result condition) :to-equal -1)))
  (it "requires a positive retry limit"
    (let ((condition (handler-case
                        (cl-vulkan-kit:enumerate-physical-devices nil
                                                                   :max-attempts 0)
                      (type-error (condition) condition))))
      (expect (typep condition 'type-error) :to-be t)))
  (it "returns an empty device list without a second query"
    (let ((calls 0))
      (with-function-definition
          (cl-vulkan-kit::%enumerate-physical-devices
           (lambda (instance count devices)
             (declare (ignore instance devices))
             (incf calls)
             (setf (cffi:mem-ref count :uint32) 0)
             0))
        (expect (cl-vulkan-kit:enumerate-physical-devices nil) :to-equal nil)
        (expect calls :to-equal 1))))
  (it "retries incomplete device enumeration"
    (let ((calls 0))
      (with-function-definition
          (cl-vulkan-kit::%enumerate-physical-devices
           (lambda (instance count devices)
             (declare (ignore instance))
             (incf calls)
             (if (cffi:null-pointer-p devices)
                 (progn
                   (setf (cffi:mem-ref count :uint32) 1)
                   0)
                 (if (= calls 2)
                     (progn
                       (setf (cffi:mem-ref count :uint32) 1)
                       5)
                     (progn
                       (setf (cffi:mem-ref count :uint32) 1)
                       0)))))
        (expect (length (cl-vulkan-kit:enumerate-physical-devices nil)) :to-equal 1)
        (expect calls :to-equal 4))))
  (it "bounds devices by the allocated capacity"
    (with-function-definition
        (cl-vulkan-kit::%enumerate-physical-devices
         (lambda (instance count devices)
           (declare (ignore instance))
           (setf (cffi:mem-ref count :uint32)
                 (if (cffi:null-pointer-p devices) 1 2))
           (unless (cffi:null-pointer-p devices)
             (setf (cffi:mem-aref devices :pointer 0) (cffi:make-pointer 11)))
           0))
      (let ((devices (cl-vulkan-kit:enumerate-physical-devices nil)))
        (expect (length devices) :to-equal 1)
        (expect (cffi:pointer-address (first devices)) :to-equal 11))))
  (it "signals non-incomplete enumeration failures"
    (with-function-definition
        (cl-vulkan-kit::%enumerate-physical-devices
         (lambda (instance count devices)
           (declare (ignore instance devices))
           (setf (cffi:mem-ref count :uint32) 1)
           (if (cffi:null-pointer-p devices) 0 -1)))
      (let ((condition (handler-case
                           (cl-vulkan-kit:enumerate-physical-devices nil)
                         (cl-vulkan-kit:vulkan-error (condition) condition))))
        (expect (typep condition 'cl-vulkan-kit:vulkan-error) :to-be t)
        (expect (cl-vulkan-kit:vulkan-error-result condition) :to-equal -1))))
  (it "signals incomplete after exhausting retries"
    (let ((calls 0))
      (with-function-definition
          (cl-vulkan-kit::%enumerate-physical-devices
           (lambda (instance count devices)
             (declare (ignore instance devices))
             (incf calls)
             (setf (cffi:mem-ref count :uint32) 1)
             (if (oddp calls) 0 5)))
        (let ((condition (handler-case
                             (cl-vulkan-kit:enumerate-physical-devices
                              nil :max-attempts 2)
                           (cl-vulkan-kit:vulkan-error (condition) condition))))
          (expect (typep condition 'cl-vulkan-kit:vulkan-error) :to-be t)
          (expect (cl-vulkan-kit:vulkan-error-result condition) :to-equal 5)
          (expect calls :to-equal 4))))))

(describe "resource lifecycle"
  (it "keeps loader state explicit"
    (cl-vulkan-kit:unload-vulkan)
    (expect (cl-vulkan-kit:vulkan-loaded-p) :to-be nil)
    (expect (cl-vulkan-kit:destroy-instance nil) :to-be nil)
    (expect (cl-vulkan-kit:destroy-instance (cffi:null-pointer)) :to-be nil))
  (it "reports instance creation failures as Vulkan errors"
    (with-function-definition
        (cl-vulkan-kit:load-vulkan (lambda () t))
      (with-function-definition
          (cl-vulkan-kit::%create-instance
           (lambda (create allocator result)
             (declare (ignore create allocator result))
             -1))
        (let ((condition (handler-case (cl-vulkan-kit:create-instance)
                           (cl-vulkan-kit:vulkan-error (condition) condition))))
          (expect (typep condition 'cl-vulkan-kit:vulkan-error) :to-be t)
          (expect (cl-vulkan-kit:vulkan-error-result condition) :to-equal -1)))))
  (it "creates and destroys an instance through the foreign boundary"
    (let ((destroyed nil))
      (with-function-definition
          (cl-vulkan-kit:load-vulkan (lambda () t))
        (with-function-definition
            (cl-vulkan-kit::%create-instance
             (lambda (create allocator result)
               (declare (ignore create allocator))
               (setf (cffi:mem-ref result :pointer) (cffi:make-pointer 42))
               0))
          (with-function-definition
              (cl-vulkan-kit::%destroy-instance
               (lambda (instance allocator)
                 (declare (ignore allocator))
                 (setf destroyed instance)))
            (let ((instance (cl-vulkan-kit:create-instance
                             :application-name "test"
                             :application-version 2
                             :engine-name "test-engine"
                             :engine-version 3
                             :api-version 4)))
              (expect (cffi:pointer-eq instance (cffi:make-pointer 42))
                      :to-be t)
              (expect (cl-vulkan-kit:destroy-instance instance) :to-be nil)
              (expect (cffi:pointer-eq destroyed (cffi:make-pointer 42))
                      :to-be t)))))))
  (it "destroys an instance when the CPS body signals"
    (let ((destroyed nil))
      (with-function-definition
          (cl-vulkan-kit:load-vulkan (lambda () t))
        (with-function-definition
            (cl-vulkan-kit::%create-instance
             (lambda (create allocator result)
               (declare (ignore create allocator))
               (setf (cffi:mem-ref result :pointer) (cffi:make-pointer 7))
               0))
          (with-function-definition
              (cl-vulkan-kit::%destroy-instance
               (lambda (instance allocator)
                 (declare (ignore allocator))
                 (setf destroyed instance)))
            (handler-case
                (cl-vulkan-kit:call-with-vulkan-instance
                 (lambda (instance)
                   (declare (ignore instance))
                   (error "body failure")))
              (error () nil))
            (expect (cffi:pointer-eq destroyed (cffi:make-pointer 7))
                    :to-be t))))))
  (it "returns the CPS body value and destroys a successful instance scope"
    (let ((destroyed nil))
      (with-function-definition
          (cl-vulkan-kit:load-vulkan (lambda () t))
        (with-function-definition
            (cl-vulkan-kit::%create-instance
             (lambda (create allocator result)
               (declare (ignore create allocator))
               (setf (cffi:mem-ref result :pointer) (cffi:make-pointer 9))
               0))
          (with-function-definition
              (cl-vulkan-kit::%destroy-instance
               (lambda (instance allocator)
                 (declare (ignore allocator))
                 (setf destroyed instance)))
            (expect
             (cl-vulkan-kit:call-with-vulkan-instance
              (lambda (instance)
                (declare (ignore instance))
                :success))
             :to-equal :success)
            (expect (cffi:pointer-eq destroyed (cffi:make-pointer 9))
                    :to-be t))))))
  )

(describe "loader ownership"
  (it "reports the loaded system version"
    (expect (cl-vulkan-kit:library-version)
            :to-equal (asdf:component-version
                       (asdf:find-system "cl-vulkan-kit"))))
  (it "supports the loader scope macro"
    (let ((cl-vulkan-kit::*vulkan-loaded* t))
      (expect (cl-vulkan-kit:with-vulkan-loader :macro-value)
              :to-equal :macro-value)))
  (it "loads an initially absent loader and unloads it"
    (let ((cl-vulkan-kit::*vulkan-loaded* nil)
          (loaded nil)
          (unloaded nil))
      (with-function-definition
          (cffi:load-foreign-library
           (lambda (library)
             (declare (ignore library))
             (setf loaded t)
             t))
        (with-function-definition
            (cffi:close-foreign-library
             (lambda (library)
               (declare (ignore library))
               (setf unloaded t)))
          (expect (cl-vulkan-kit:call-with-vulkan-loader (lambda () :ok))
                  :to-equal :ok)
          (expect loaded :to-be t)
          (expect unloaded :to-be t)
          (expect cl-vulkan-kit::*vulkan-loaded* :to-be nil)))))
  (it "keeps an outer loader alive for nested scopes"
    (let ((cl-vulkan-kit::*vulkan-loaded* t))
      (cl-vulkan-kit:call-with-vulkan-loader
       (lambda ()
         (cl-vulkan-kit:call-with-vulkan-loader (lambda () :nested))))
      (expect cl-vulkan-kit::*vulkan-loaded* :to-be t)))
  (it "releases a loader owned by a failing CPS body"
    (let ((cl-vulkan-kit::*vulkan-loaded* nil))
      (with-function-definition
          (cl-vulkan-kit:load-vulkan (lambda ()
                                       (setf cl-vulkan-kit::*vulkan-loaded* t)))
        (with-function-definition
            (cl-vulkan-kit:unload-vulkan (lambda ()
                                           (setf cl-vulkan-kit::*vulkan-loaded* nil)))
          (handler-case
              (cl-vulkan-kit:call-with-vulkan-loader
               (lambda () (error "body failure")))
            (error () nil))
          (expect cl-vulkan-kit::*vulkan-loaded* :to-be nil)))))
  (it "supports the instance scope macro"
    (let ((destroyed nil))
      (with-function-definition
          (cl-vulkan-kit:load-vulkan (lambda () t))
        (with-function-definition
            (cl-vulkan-kit::%create-instance
             (lambda (create allocator result)
               (declare (ignore create allocator))
               (setf (cffi:mem-ref result :pointer) (cffi:make-pointer 13))
               0))
          (with-function-definition
              (cl-vulkan-kit::%destroy-instance
               (lambda (instance allocator)
                 (declare (ignore allocator))
                 (setf destroyed instance)))
            (expect
             (cl-vulkan-kit:with-vulkan-instance (instance)
               (declare (ignore instance))
               :macro-value)
             :to-equal :macro-value)
            (expect (cffi:pointer-eq destroyed (cffi:make-pointer 13))
                    :to-be t))))))
)
