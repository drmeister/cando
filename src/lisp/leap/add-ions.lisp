(in-package :leap.add-ions)

(defun add-ions (mol ion1 ion1-number &optional ion2 ion2-number)
  (let* ((force-field (leap.core::merged-force-field))
         (nonbond-db (chem:get-nonbond-db force-field))
         (ion1-type-index (chem:find-type-index nonbond-db ion1))
         (ion1-ffnonbond (chem:get-ffnonbond-using-type-index nonbond-db ion1-type-index))
         (ion1-size (chem:get-radius-angstroms ion1-ffnonbond))
         (ion1-topology (cando:lookup-topology ion1))
         (ion1-residue (chem:build-residue-single-name ion1-topology))
         (ion1-atom (chem:content-at ion1-residue 0))
         (ion1-mol (chem:make-molecule))
         (ion1-agg (chem:make-aggregate))
         (solvent-vec (make-array 100 :fill-pointer 0 :adjustable t))
         (include-solvent 0)
         (target-charge 0)
         (ion-min-size 0.0)
         (grid-space 1.0)
         (shell-extent 4.0)
         (at-octree 1)
         (dielectric 1)
         (ion2-size 0.0) 
         (ion2-type-index 0)
         ion2-ffnonbond)
    (chem:add-matter ion1-mol ion1-residue)
    (chem:add-matter ion1-agg ion1-mol)
    (if (and ion2 (= 0 ion2-number))
        (error "'0' is not allowed as the value for the second ion."))
    ;;Make array of solvent residues
    (chem:map-residues 
     nil
     (lambda (r)
       (when (eq (chem:get-name r) :wat)
         (chem:setf-residue-type r :solvent) 
         (vector-push-extend r solvent-vec)))
     mol)
    ;;Consider target unit's charge
    (chem:map-atoms
     nil
     (lambda (r)
       (setf target-charge (+ (chem:get-charge r) target-charge)))
     mol)
    (if (and (= 0 target-charge)
             (= 0 ion1-number))
        (progn
          (format t "The total charge is ~a and so there are no charges to neutralize.~%" target-charge)
          (return-from add-ions))
        (format t "Total charge ~f~%" target-charge))
    ;;Consider neutralizetion    
    (if (= ion1-number 0)
        (progn
          (if (or (and (< (chem:get-charge ion1-atom) 0)
                       (< target-charge 0))
                  (and (> (chem:get-charge ion1-atom) 0)
                       (> target-charge 0)))
              (error "1st ion & target are same charge"))
          ;;Get the nearest integer number of ions that we need to add to get as close as possible to neutral.
          (setf ion1-number (round (/ (abs target-charge) (abs (chem:get-charge ion1-atom)))))
          (if ion2
              (error "Neutralization - can't do 2nd ion."))
          (format t "~d ~a ions required to neutraize. ~%" ion1-number (chem:get-name ion1-atom))))
    ;;Consider ion sizes and postions
    (if ion2
        (progn
          (setf ion2-type-index (chem:find-type-index nonbond-db ion2))
          (setf ion2-ffnonbond (chem:get-ffnonbond-using-type-index nonbond-db ion2-type-index))
          (setf ion2-size (chem:get-radius-angstroms ion2-ffnonbond))
          (setf ion-min-size (min ion1-size ion2-size)))
        (setf ion-min-size ion1-size))
    (format t "Adding ~d counter ions to ~a using 1A grid. ~%"
            (if ion2 (+ ion1-number ion2-number) ion1-number) (chem:get-name mol))
    (if ion2
        (if (> (+ ion1-number ion2-number) 5)
            (setf ion-min-size (if (> ion1-size ion2-size)
                                   (* ion1-size
                                      (if (> (exp (/ (log (+ ion1-number ion2-number 1.0)) 3.0)) 1.0)
                                          (exp (/ (log (+ ion1-number ion2-number 1.0)) 3.0))
                                          1.0))
                                   (* ion2-size
                                      (if (> (exp (/ (log (+ ion1-number ion2-number 1.0)) 3.0)) 1.0)
                                          (exp (/ (log (+ ion1-number ion2-number 1.0)) 3.0))
                                          1.0)))))
        (if (> ion1-number 5)
            (setf ion-min-size (* ion1-size
                                  (if (> (exp (/ (log (+ ion1-number 1.0)) 3.0)) 1.0)
                                      (exp (/ (log (+ ion1-number 1.0)) 3.0))
                                      1.0)))))
    
    ;;Build grid and calc potential on it
    (let ((oct-tree (core:make-cxx-object 'chem:octree))
          (ion2-mol (chem:make-molecule))
          (ion2-agg (chem:make-aggregate))
          ion2-topology ion2-residue ion2-atom)
      (if ion2
          (progn 
            (setf ion2-topology (cando:lookup-topology ion2)
                  ion2-residue (chem:build-residue-single-name ion2-topology)
                  ion2-atom (chem:content-at ion2-residue 0))
            (chem:add-matter ion2-mol ion2-residue)
            (chem:add-matter ion2-agg ion2-mol)))
      (format t "About to octree-create~%")
      (chem:oct-oct-tree-create oct-tree mol :shell grid-space ion-min-size shell-extent nonbond-db include-solvent t)
      (format t "Came out of octree-create~%")
      (if (aref solvent-vec 0)
          (format t " Solvent present: replacing closest with ion when steric overlaps occur~%")
          (format t "(no solvent present)~%"))
      (multiple-value-bind (min-charge-point max-charge-point)
          (chem:oct-tree-init-charges oct-tree at-octree dielectric ion1-size)
        (loop 
           for new-point = (if (< (chem:get-charge ion1-atom) 0) max-charge-point min-charge-point)
           for ion1-copy = (chem:matter-copy ion1-agg)
           for ion1-transform = (geom:make-m4-translate new-point)
           while (if ion2
                     (or (> ion1-number 0)
                            (> ion2-number 0))
                     (> ion1-number 0))
           do (if (aref solvent-vec 0)
                  (check-solvent mol solvent-vec ion1-copy new-point))  
           do (chem:apply-transform-to-atoms ion1-copy ion1-transform)
           do (chem:add-matter mol ion1-copy)
           do (format t "Placed ~a in ~a at ~a ~a ~a~%" (chem:get-name ion1-atom) 
                      (chem:get-name mol)
                      (geom:vx new-point)
                      (geom:vy new-point)
                      (geom:vz new-point))
           do (chem:oct-tree-delete-sphere oct-tree new-point (if ion2
                                                                  (+ ion1-size ion2-size)
                                                                  (+ ion1-size ion1-size)))
           do (multiple-value-bind (min-new-charge-point max-new-charge-point)
                  (chem:oct-tree-update-charge oct-tree new-point (chem:get-charge ion1-atom)
                                               (if ion2 ion2-size ion1-size))
                (setf min-charge-point min-new-charge-point)
                (setf max-charge-point max-new-charge-point))
           do (decf ion1-number)
           do (if (and ion2 (> ion2-number 0))
                   (progn 
                    (if (< (chem:get-charge ion2-atom) 0)
                        (setf new-point max-charge-point)
                        (setf new-point min-charge-point))
                    (let ((ion2-copy (chem:matter-copy ion2-agg))
                          (ion2-transform (geom:make-m4-translate new-point)))
                      (chem:apply-transform-to-atoms ion2-copy ion2-transform)
                      (chem:add-matter mol ion2-copy)
                      (format t "Placed ~a in ~a at ~a ~a ~a~%" (chem:get-name ion2-atom) 
                              (chem:get-name mol)
                              (geom:vx new-point)
                              (geom:vy new-point)
                              (geom:vz new-point))
                      (chem:oct-tree-delete-sphere oct-tree new-point (if ion1
                                                                          (+ ion2-size ion1-size)
                                                                          (+ ion2-size ion2-size)))
                      (multiple-value-bind (min-new-charge-point max-new-charge-point)
                          (chem:oct-tree-update-charge oct-tree new-point (chem:get-charge ion2-atom)
                                                       (if ion1 ion1-size ion2-size))
                        (setf min-charge-point min-new-charge-point)
                        (setf max-charge-point max-new-charge-point)))
                    (decf ion2-number))))))))


(defun add-ions-2 (mol ion1 ion1-number &optional ion2 ion2-number)
  (let* ((force-field (leap.core::merged-force-field))
         (nonbond-db (chem:get-nonbond-db force-field))
         (ion1-type-index (chem:find-type-index nonbond-db ion1))
         (ion1-ffnonbond (chem:get-ffnonbond-using-type-index nonbond-db ion1-type-index))
         (ion1-size (chem:get-radius-angstroms ion1-ffnonbond))
         (ion1-topology (cando:lookup-topology ion1))
         (ion1-residue (chem:build-residue-single-name ion1-topology))
         (ion1-atom (chem:content-at ion1-residue 0))
         (ion1-mol (chem:make-molecule))
         (ion1-agg (chem:make-aggregate))
         (include-solvent 1)
         (target-charge 0)
         (ion-min-size 0.0)
         (grid-space 1.0)
         (shell-extent 4.0)
         (at-octree 1)
         (dielectric 1)
         (ion2-size 0.0) 
         (ion2-type-index 0)
         ion2-ffnonbond)
    (chem:add-matter ion1-mol ion1-residue)
    (chem:add-matter ion1-agg ion1-mol)
    (if (and ion2 (= 0 ion2-number))
        (error "'0' is not allowed as the value for the second ion."))
    ;;Consider target unit's charge
    (chem:map-atoms
     nil
     (lambda (r)
       (setf target-charge (+ (chem:get-charge r) target-charge)))
     mol)
    (if (and (= 0 target-charge)
             (= 0 ion1-number))
        (progn
          (format t "The total charge is ~a and so there are no charges to neutralize.~%" target-charge)
          (return-from add-ions-2))
        (format t "Total charge ~f~%" target-charge))
    ;;Consider neutralizetion    
    (if (= ion1-number 0)
        (progn
          (if (or (and (< (chem:get-charge ion1-atom) 0)
                       (< target-charge 0))
                  (and (> (chem:get-charge ion1-atom) 0)
                       (> target-charge 0)))
              (error "1st ion & target are same charge"))
          ;;Get the nearest integer number of ions that we need to add to get as close as possible to neutral.
          (setf ion1-number (round (/ (abs target-charge) (abs (chem:get-charge ion1-atom)))))
          (if ion2
              (error "Neutralization - can't do 2nd ion."))
          (format t "~d ~a ions required to neutraize. ~%" ion1-number (chem:get-name ion1-atom))))
    ;;Consider ion sizes and postions
    (if ion2
        (progn
          (setf ion2-type-index (chem:find-type-index nonbond-db ion2))
          (setf ion2-ffnonbond (chem:get-ffnonbond-using-type-index nonbond-db ion2-type-index))
          (setf ion2-size (chem:get-radius-angstroms ion2-ffnonbond))
          (setf ion-min-size (min ion1-size ion2-size)))
        (setf ion-min-size ion1-size))
    (format t "Adding ~d counter ions to ~a using 1A grid. ~%"
            (if ion2 (+ ion1-number ion2-number) ion1-number) (chem:get-name mol))
    (if ion2
        (if (> (+ ion1-number ion2-number) 5)
            (setf ion-min-size (if (> ion1-size ion2-size)
                                   (* ion1-size
                                      (if (> (exp (/ (log (+ ion1-number ion2-number 1.0)) 3.0)) 1.0)
                                          (exp (/ (log (+ ion1-number ion2-number 1.0)) 3.0))
                                          1.0))
                                   (* ion2-size
                                      (if (> (exp (/ (log (+ ion1-number ion2-number 1.0)) 3.0)) 1.0)
                                          (exp (/ (log (+ ion1-number ion2-number 1.0)) 3.0))
                                          1.0)))))
        (if (> ion1-number 5)
            (setf ion-min-size (* ion1-size
                                  (if (> (exp (/ (log (+ ion1-number 1.0)) 3.0)) 1.0)
                                      (exp (/ (log (+ ion1-number 1.0)) 3.0))
                                      1.0)))))
    
    ;;Build grid and calc potential on it
    (let ((oct-tree (core:make-cxx-object 'chem:octree))
          (ion2-mol (chem:make-molecule))
          (ion2-agg (chem:make-aggregate))
          ion2-topology ion2-residue ion2-atom)
      (if ion2
          (progn 
            (setf ion2-topology (cando:lookup-topology ion2)
                  ion2-residue (chem:build-residue-single-name ion2-topology)
                  ion2-atom (chem:content-at ion2-residue 0))
            (chem:add-matter ion2-mol ion2-residue)
            (chem:add-matter ion2-agg ion2-mol)))
      (format t "About to octree-create~%")
      (chem:oct-oct-tree-create oct-tree mol :shell grid-space ion-min-size shell-extent nonbond-db include-solvent t)
      (format t "Came out of octree-create~%")
      (multiple-value-bind (min-charge-point max-charge-point)
          (chem:oct-tree-init-charges oct-tree at-octree dielectric ion1-size)
        (loop 
           for new-point = (if (< (chem:get-charge ion1-atom) 0) max-charge-point min-charge-point)
           for ion1-copy = (chem:matter-copy ion1-agg)
           for ion1-transform = (geom:make-m4-translate new-point)
           while (if ion2
                     (or (> ion1-number 0)
                            (> ion2-number 0))
                     (> ion1-number 0))
           do (chem:apply-transform-to-atoms ion1-copy ion1-transform)
           do (chem:add-matter mol ion1-copy)
           do (format t "Placed ~a in ~a at ~a ~a ~a~%" (chem:get-name ion1-atom) 
                      (chem:get-name mol)
                      (geom:vx new-point)
                      (geom:vy new-point)
                      (geom:vz new-point))
           do (chem:oct-tree-delete-sphere oct-tree new-point (if ion2
                                                                  (+ ion1-size ion2-size)
                                                                  (+ ion1-size ion1-size)))
           do (multiple-value-bind (min-new-charge-point max-new-charge-point)
                  (chem:oct-tree-update-charge oct-tree new-point (chem:get-charge ion1-atom)
                                               (if ion2 ion2-size ion1-size))
                (setf min-charge-point min-new-charge-point)
                (setf max-charge-point max-new-charge-point))
           do (decf ion1-number)
           do (if (and ion2 (> ion2-number 0))
                   (progn 
                    (if (< (chem:get-charge ion2-atom) 0)
                        (setf new-point max-charge-point)
                        (setf new-point min-charge-point))
                    (let ((ion2-copy (chem:matter-copy ion2-agg))
                          (ion2-transform (geom:make-m4-translate new-point)))
                      (chem:apply-transform-to-atoms ion2-copy ion2-transform)
                      (chem:add-matter mol ion2-copy)
                      (format t "Placed ~a in ~a at ~a ~a ~a~%" (chem:get-name ion2-atom) 
                              (chem:get-name mol)
                              (geom:vx new-point)
                              (geom:vy new-point)
                              (geom:vz new-point))
                      (chem:oct-tree-delete-sphere oct-tree new-point (if ion1
                                                                          (+ ion2-size ion1-size)
                                                                          (+ ion2-size ion2-size)))
                      (multiple-value-bind (min-new-charge-point max-new-charge-point)
                          (chem:oct-tree-update-charge oct-tree new-point (chem:get-charge ion2-atom)
                                                       (if ion1 ion1-size ion2-size))
                        (setf min-charge-point min-new-charge-point)
                        (setf max-charge-point max-new-charge-point)))
                    (decf ion2-number))))))))


(defun check-solvent (mol solvent-vec ion1-copy new-point)
  (let ((dmin2 100000000)
        (closest-atom-vector (make-array 3 :element-type 'double-float))
        (d2 0)
        (x 0)
        (y 0)
        (z 0))
    (loop for i from 0 below (length solvent-vec)
          for residue = (aref solvent-vec i)
          do (chem:map-atoms
              nil
              (lambda (a)
                (setf x (- (geom:vx new-point) (geom:vx (chem:get-position a))))
                (setf y (- (geom:vy new-point) (geom:vy (chem:get-position a))))
                (setf z (- (geom:vz new-point) (geom:vz (chem:get-position a))))
                (setf d2 (+ (* x x) (* y y) (* z z)))
                (if (< d2 dmin2)
                    (progn
                      (setf dmin2 d2)
                      (setf (aref closest-atom-vector 0) (geom:vx (chem:get-position a)))
                      (setf (aref closest-atom-vector 1) (geom:vy (chem:get-position a)))
                      (setf (aref closest-atom-vector 2) (geom:vz (chem:get-position a))))))
              residue))
     (if (< dmin2 9)
        (progn 
          (chem:map-residues 
           nil
           (lambda (r)
             (chem:map-atoms
              nil
              (lambda (a)
                (when (and (= (geom:vx (chem:get-position a)) (aref closest-atom-vector 0))
                           (= (geom:vy (chem:get-position a)) (aref closest-atom-vector 1))
                           (= (geom:vz (chem:get-position a)) (aref closest-atom-vector 2)))
                  (chem:set-name r :delete)))
              r))
           mol)
          ;; If molecule has one water residue, delete molecule.
          ;; If molecule has more than two residues, delete one residue.
          (chem:map-molecules
           nil
           (lambda (m)
             (if (= (chem:residue-count m) 1)
                   (when (eq (chem:get-name (chem:get-residue m 0)) :delete)
                     (format t "Replacing solvent molecule~%")
                     (chem:remove-molecule mol m))
                   (chem:map-residues
                    nil
                    (lambda (r)
                      (when (eq (chem:get-name r) :delete)
                        (format t "Replacing solvent molecule~%")
                        (chem:remove-residue m r)))
                    m)))
           mol)))))
