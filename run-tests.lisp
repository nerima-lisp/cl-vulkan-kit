;;;; run-tests.lisp
;;;;
(defun enable-coverage-compiler ()
  #+sbcl
  (progn
    (require :sb-cover)
    (let ((policy (find-symbol "STORE-COVERAGE-DATA" "SB-COVER")))
      (unless policy
        (error "SB-COVER compiler policy is not available."))
      (proclaim `(optimize (,policy 3)))))
  #-sbcl
  (error "Coverage requires SBCL."))

(require :asdf)
(require :uiop)

(defun configure-isolated-asdf-cache ()
  (let ((cache (merge-pathnames
                (format nil "cl-vulkan-kit/asdf-cache-~D/"
                        (get-internal-real-time))
                                (funcall (symbol-function
                                          (find-symbol "TEMPORARY-DIRECTORY" "UIOP"))))))
    (funcall (symbol-function (find-symbol "ENSURE-DIRECTORIES-EXIST" "UIOP"))
             cache)
    (funcall (symbol-function (find-symbol "INITIALIZE-OUTPUT-TRANSLATIONS" "ASDF"))
             `(:output-translations
               (t ,cache)
               :ignore-inherited-configuration))))

(configure-isolated-asdf-cache)

(defun script-directory ()
  (make-pathname :name nil
                 :type nil
                 :defaults (or *load-truename*
                               *compile-file-truename*
                               (error "Unable to determine the script location"))))

(defun environment-flag (name)
  (member (string-downcase (or (funcall (symbol-function (find-symbol "GETENV" "UIOP")) name) ""))
          '("1" "true" "yes" "on")
          :test #'string=))

(defun coverage-requested-p ()
  (or (environment-flag "CL_VULKAN_KIT_COVERAGE")
      (member "--coverage"
              (funcall (symbol-function
                        (find-symbol "COMMAND-LINE-ARGUMENTS" "UIOP")))
              :test #'string=)))

(defun source-files (root)
  (sort (funcall (symbol-function (find-symbol "DIRECTORY-FILES" "UIOP"))
                (merge-pathnames "src/" root)
                "*.lisp")
        #'string<
        :key #'namestring))

(defun coverage-artifact-p (pathname)
  (and (probe-file pathname)
       (with-open-file (stream pathname :direction :input)
         (plusp (file-length stream)))))

(defun instrument-project-sources ()
  (funcall (symbol-function (find-symbol "LOAD-SYSTEM" "ASDF"))
           "cl-vulkan-kit"
           :force t))

(let ((root (script-directory)))
  (push root asdf:*central-registry*)
  (load (merge-pathnames "cl-vulkan-kit.asd" root))
  (funcall (symbol-function (find-symbol "LOAD-SYSTEM" "ASDF"))
           "cffi")
  (funcall (symbol-function (find-symbol "LOAD-SYSTEM" "ASDF"))
           "cl-weave"
           :force t)
  (let ((coverage (coverage-requested-p)))
    (when coverage
      (enable-coverage-compiler)
      (instrument-project-sources))
    (funcall (symbol-function (find-symbol "LOAD-SYSTEM" "ASDF"))
             "cl-vulkan-kit/test"
             :force coverage)
    (let* ((coverage-output (or (funcall (symbol-function (find-symbol "GETENV" "UIOP"))
                                         "CL_VULKAN_KIT_COVERAGE_OUTPUT")
                                (merge-pathnames "cl-vulkan-kit-coverage.sexp"
                                                 (funcall (symbol-function
                                                           (find-symbol "TEMPORARY-DIRECTORY" "UIOP"))))))
           (coverage-directory (or (funcall (symbol-function (find-symbol "GETENV" "UIOP"))
                                           "CL_VULKAN_KIT_COVERAGE_DIRECTORY")
                                   (merge-pathnames "cl-vulkan-kit-coverage-report/"
                                                    (funcall (symbol-function
                                                              (find-symbol "TEMPORARY-DIRECTORY" "UIOP"))))))
           (result (funcall (symbol-function (find-symbol "SYMBOL-CALL" "UIOP"))
                            :cl-weave :run-all
                            :reporter :spec
                            :pass-with-no-tests nil
                            :timeout-ms 5000
                            :max-workers (and coverage 1)
                            :coverage coverage
                            :coverage-output (and coverage coverage-output)
                            :coverage-report-directory (and coverage coverage-directory)
                            :coverage-include-pathnames (and coverage (source-files root))
                            :coverage-minimum-expression (if coverage 100 0)
                            :coverage-minimum-branch (if coverage 100 0))))
      (when (and coverage (not (coverage-artifact-p coverage-output)))
        (error "Coverage did not produce a non-empty artifact: ~A" coverage-output))
      (funcall (symbol-function (find-symbol "QUIT" "UIOP"))
               (if result 0 1)))))
