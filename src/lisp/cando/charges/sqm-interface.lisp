(in-package :charges)


(defun write-sqm-header (fout qm-theory qm-charge maxcyc &optional (header "Run a qm calculation"))
  "Arguments
fout : A stream to write the header to.
qm-theory : The level of theory ( :AM1 | :PM3 | :PM6)
qm-charge : The overall charge of the molecule"
  (format fout "~a~%" header)
  (format fout " &qmmm~%")
  (format fout "    qm_theory='~a',~%" (string qm-theory))
  (format fout "    qmcharge=~d,~%" qm-charge)
  (format fout "    maxcyc=~d,~%" maxcyc)
  (format fout " /~%"))

(defun write-sqm-molecule (fout molecule)
  (chem:map-atoms
   nil
   (lambda (atom)
     (let ((position (chem:get-position atom))
           (atom-name (cond
                        ((eq :ZA (chem:get-name atom)) :CA)
                        ((eq :ZB (chem:get-name atom)) :H)
                        (t (chem:get-name atom)))))
       (format fout "~2d ~a ~12,6f ~12,6f ~12,6f~%"
               (chem:atomic-number-for-element (chem:get-element atom))
               atom-name
               (geom:vx position)
               (geom:vy position)
               (geom:vz position))))
   molecule))

(defun write-sqm-calculation (fout molecule &key (qm-theory :am1) (qm-charge 0) (maxcyc 9999))
  (write-sqm-header fout qm-theory qm-charge maxcyc)
  (write-sqm-molecule fout molecule))


(defun generate-charge-atoms-array (pathname)
  (let ((atom-number-vec (make-array 50 :element-type '(signed-byte 32) :fill-pointer 0 :adjustable t))
        (element-vec (make-array 50 :fill-pointer 0 :adjustable t))
        (charge-vec (make-array 50 :element-type 'double-float :fill-pointer 0 :adjustable t))
        (line-charge 0))
    (with-open-file (in pathname :if-does-not-exist nil)
      (when in
        (loop for line = (read-line in nil) 
           until (and (> (length line) 22)
                      (string= (subseq line 1 22) "Total Mulliken Charge"))
           do (when (= line-charge 1)
                (multiple-value-bind (atom-number element charge)
                    (parse-mulliken-charge line)
                  (vector-push-extend atom-number atom-number-vec)
                  (vector-push-extend element element-vec)
                  (vector-push-extend charge charge-vec))) 
         do (when (string= line "  Atom    Element       Mulliken Charge")
              (setf line-charge 1)))))
    (values atom-number-vec element-vec charge-vec)))

(defun parse-mulliken-charge (line)
  (let ((atom-number (parse-integer line :start 0 :end 6))
        (element (intern (string-trim '(#\space) (subseq line 6 14)) :keyword))
        (mulliken-charge (fortran::parse-double-float line :start 14 :end 36)))
;    (format t " number ~a element ~a charge ~a~%" atom-number element mulliken-charge)
    (values atom-number element mulliken-charge)))

(defun generate-am1-correction (pathname mol)
  (let ((correction-map (make-hash-table))
        (count 0))
    (multiple-value-bind (atom-number-vec element-vec charge-vec)
        (generate-charge-atoms-array pathname) 
      (chem:map-atoms
       nil
       (lambda (a)
         (if (eq (chem:get-element a) (aref element-vec count))
             (setf (gethash a correction-map) (aref charge-vec count))
             (error "Mismatch atom name ~a element ~a element ~a" (chem:get-name a) (chem:get-element a) (aref atom-number-vec count)))
         (incf count))
       mol)
      correction-map)))
