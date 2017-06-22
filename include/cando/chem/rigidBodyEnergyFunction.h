/*
    File: energyFunction.h
*/
/*
Open Source License
Copyright (c) 2016, Christian E. Schafmeister
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
 
This is an open source license for the CANDO software from Temple University, but it is not the only one. Contact Temple University at mailto:techtransfer@temple.edu if you would like a different license.
*/
/* -^- */
       
       
#define	DEBUG_LEVEL_NONE


//
// (C) 2004 Christian E. Schafmeister
//


/*
 *	energyFunction.h
 *
 *	Maintains a database of stretch types
 */

#ifndef RigidBodyEnergyFunction_H
#define	RigidBodyEnergyFunction_H
#include <stdio.h>
#include <string>
#include <vector>
#include <set>
#include <clasp/core/common.h>
#include <cando/geom/vector3.h>
#include <cando/chem/scoringFunction.h>
#include <cando/chem/energyRigidBodyComponent.h>




#include <cando/adapt/quickDom.fwd.h>// energyFunction.h wants QDomNode needs quickDom.fwd.h
//#include "geom/render.fwd.h"// energyFunction.h wants DisplayList needs render.fwd.h
#include <clasp/core/iterator.fwd.h>// energyFunction.h wants Iterator needs iterator.fwd.h


#include <cando/chem/chemPackage.h>

namespace       chem
{


  SMART(FFParameter);
  SMART(AbstractLargeSquareMatrix);
  SMART(FFNonbondCrossTermTable);
  SMART(QDomNode);
  SMART(Atom);
  SMART(Matter);
  SMART(ForceField);
  SMART(AtomTable);

  FORWARD(RigidBodyEnergyFunction);
};


template <>
struct gctools::GCInfo<chem::RigidBodyEnergyFunction_O> {
  static bool constexpr NeedsInitialization = false;
  static bool constexpr NeedsFinalization = false;
  static GCInfo_policy constexpr Policy = normal;
};

namespace chem {
  SMART(RigidBodyEnergyFunction);
  class RigidBodyEnergyFunction_O : public ScoringFunction_O
  {
    LISP_CLASS(chem,ChemPkg,RigidBodyEnergyFunction_O,"RigidBodyEnergyFunction",ScoringFunction_O);
  public:
    static RigidBodyEnergyFunction_sp make(size_t number_of_rigid_bodies );
  public:
    size_t              _RigidBodies;
    core::List_sp       _Terms;
  public:
    CL_LISPIFY_NAME("rigid-body-energy-function-add-term");
    CL_DEFMETHOD void addTerm(EnergyRigidBodyComponent_sp comp) { this->_Terms = core::Cons_O::create(comp,this->_Terms);};
    
    CL_LISPIFY_NAME("rigid-body-energy-function-terms");
    CL_DEFMETHOD core::List_sp terms() { return this->_Terms;};
  public:
    /*! 4 quaternion and 3 cartesian coordinates for each rigid body */
    virtual size_t getNVectorSize() override { return this->_RigidBodies*7; };

    virtual void	enableDebug() override;
    /*! Disable debugging on all energy components
     */
    virtual void	disableDebug() override;

    virtual string	energyTermsEnabled() override;

    virtual void	setupHessianPreconditioner( NVector_sp pos, AbstractLargeSquareMatrix_sp hessian) override;

    virtual void	extractCoordinatesFromAtoms(NVector_sp pos);
    virtual void	writeCoordinatesToAtoms(NVector_sp pos);
    virtual void	writeCoordinatesAndForceToAtoms(NVector_sp pos, NVector_sp force);
    virtual double	evaluateRaw( NVector_sp pos, NVector_sp force ) ;
//    virtual double	evaluate( NVector_sp pos, NVector_sp force, bool calculateForce ) ;
    adapt::QDomNode_sp	identifyTermsBeyondThreshold();
//    uint	countBadVdwInteractions(double scaleSumOfVdwRadii, geom::DisplayList_sp displayIn);

    ForceMatchReport_sp checkIfAnalyticalForceMatchesNumericalForce( NVector_sp pos, NVector_sp force );

    void	useDefaultSettings();

    /*! Set a single options */
    void	setOption( core::Symbol_sp option, core::T_sp val);


    /*! Set the energy function options. List the options as a flat list of keyword/value pairs */
    void	setOptions( core::List_sp options );

    double	evaluateAll( 	NVector_sp pos,
				bool calcForce,
				gc::Nilable<NVector_sp> force,
       				bool calcDiagonalHessian,
				bool calcOffDiagonalHessian,
				gc::Nilable<AbstractLargeSquareMatrix_sp>	hessian,
				gc::Nilable<NVector_sp> hdvec,
                                gc::Nilable<NVector_sp> dvec	);

    double	evaluateEnergy( NVector_sp pos );
    double	evaluateEnergyForce( NVector_sp pos, bool calcForce, NVector_sp force );

    void	dealWithProblem(core::Symbol_sp error_symbol, core::T_sp arguments);
    void normalizePosition(NVector_sp pos);

  RigidBodyEnergyFunction_O(size_t number_of_rigid_bodies)
    : _RigidBodies(number_of_rigid_bodies),
      _Terms(_Nil<core::T_O>()) {};
  };

};

#endif
