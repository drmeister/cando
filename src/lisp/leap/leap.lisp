(in-package :leap)


(defun load-amber-params (filename &optional (force-field :default))
  (let* ((fn (leap.core:ensure-path filename))
         (ff (let ((parmreader (chem:make-read-amber-parameters)))
              (with-open-file (fin fn :direction :input)
                (chem:read-parameters parmreader fin leap:*amber-system*)
                (chem:get-force-field parmreader)))))
    (chem:set-title ff filename)
    (format t "Adding force field ~a to ~a~%" ff force-field)
    (leap.core:add-force-field-or-modification ff force-field)))

(defun load-atom-type-rules (filename &optional (force-field :default))
  (let* ((path (leap.core:search-path filename))
         (fftypedb (with-open-file (fin path)
                       (leap.antechamber-type-definition-parser::read-antechamber-type-rules fin)))
         (ff (core:make-cxx-object 'chem:force-field)))
    (chem:set-title ff filename)
    (chem:set-type-db ff fftypedb)
    (leap.core:add-force-field-or-modification ff force-field)))

