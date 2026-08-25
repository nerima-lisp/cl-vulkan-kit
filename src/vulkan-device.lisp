#.(in-package #:cl-vulkan-kit)

(defun %physical-device-attempt (instance)
  (cffi:with-foreign-object (count :uint32)
    (%check-result
     (%enumerate-physical-devices instance count (cffi:null-pointer)))
    (let ((capacity (cffi:mem-ref count :uint32)))
      (if (zerop capacity)
          (values +vk-success+ nil)
          (cffi:with-foreign-object (handles :pointer capacity)
            (let ((result (%enumerate-physical-devices instance count handles)))
              (values
               result
               (loop for index below
                     (min capacity (cffi:mem-ref count :uint32))
                     collect (cffi:mem-aref handles :pointer index)))))))))

(defun %enumerate-physical-devices* (instance max-attempts)
  "Return INSTANCE's physical devices, retrying transient VK_INCOMPLETE results."
  (check-type max-attempts (integer 1))
  (loop repeat max-attempts
        do (multiple-value-bind (result devices)
               (%physical-device-attempt instance)
             (cond
               ((zerop result) (return devices))
               ((/= result +vk-incomplete+)
                (%check-result result))))
        finally (error 'vulkan-error :result +vk-incomplete+)))
