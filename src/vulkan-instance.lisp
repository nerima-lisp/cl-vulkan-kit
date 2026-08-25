#.(in-package #:cl-vulkan-kit)

(defun %check-result (result &key allow-incomplete)
  (unless (or (zerop result)
              (and allow-incomplete (= result +vk-incomplete+)))
    (error 'vulkan-error :result result))
  result)

(defun %create-instance* (application-name application-version
                          engine-name engine-version api-version)
  "Create and return a VkInstance. The caller owns it and must destroy it."
  (load-vulkan)
  (cffi:with-foreign-strings ((app application-name) (engine engine-name))
    (cffi:with-foreign-object (info '(:struct application-info))
      (cffi:with-foreign-object (create '(:struct instance-create-info))
        (cffi:with-foreign-object (result :pointer)
          (setf (cffi:foreign-slot-value info '(:struct application-info) 's-type)
                +structure-type-application-info+
                (cffi:foreign-slot-value info '(:struct application-info) 'p-next)
                (cffi:null-pointer)
                (cffi:foreign-slot-value info '(:struct application-info) 'application-name) app
                (cffi:foreign-slot-value info '(:struct application-info) 'application-version)
                application-version
                (cffi:foreign-slot-value info '(:struct application-info) 'engine-name) engine
                (cffi:foreign-slot-value info '(:struct application-info) 'engine-version)
                engine-version
                (cffi:foreign-slot-value info '(:struct application-info) 'api-version) api-version
                (cffi:foreign-slot-value create '(:struct instance-create-info) 's-type)
                +structure-type-instance-create-info+
                (cffi:foreign-slot-value create '(:struct instance-create-info) 'p-next)
                (cffi:null-pointer)
                (cffi:foreign-slot-value create '(:struct instance-create-info) 'flags) 0
                (cffi:foreign-slot-value create '(:struct instance-create-info) 'application-info) info
                (cffi:foreign-slot-value create '(:struct instance-create-info) 'enabled-layer-count) 0
                (cffi:foreign-slot-value create '(:struct instance-create-info) 'enabled-layers)
                (cffi:null-pointer)
                (cffi:foreign-slot-value create '(:struct instance-create-info) 'enabled-extension-count) 0
                (cffi:foreign-slot-value create '(:struct instance-create-info) 'enabled-extensions)
                (cffi:null-pointer))
          (%check-result (%create-instance create (cffi:null-pointer) result))
          (cffi:mem-ref result :pointer))))))

(defun destroy-instance (instance)
  "Destroy INSTANCE, a value returned by CREATE-INSTANCE."
  (when (and instance (not (cffi:null-pointer-p instance)))
    (%destroy-instance instance (cffi:null-pointer)))
  nil)

(defun call-with-vulkan-instance (thunk &rest options)
  (let ((instance (apply #'create-instance options)))
    (unwind-protect (funcall thunk instance)
      (destroy-instance instance))))
