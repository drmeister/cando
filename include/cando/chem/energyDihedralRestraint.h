/*
    File: energyDihedralRestraint.h
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
//
// (C) 2004 Christian E. Schafmeister
//



/*
 *	energyDihedralRestraint.h
 *
 *	Maintains a database of stretch types
 */

#ifndef EnergyDihedralRestraint_H  //[
#define	EnergyDihedralRestraint_H
#include <stdio.h>
#include <string>
#include <vector>
#include <set>
#include <clasp/core/common.h>
#include <cando/chem/energyComponent.h>



namespace       chem {


  FORWARD(EnergyFunction);


struct TermImproperRestraint
{
	double		K;	// Force constant
    	double		U;	// Upper bound in radians domain [-180,180]
	double		L;	// Lower bound in radians domain [-180,180]
	int		I1;
	int		I2;
	int		I3;
	int		I4;
};


class	EnergyDihedralRestraint : public EnergyTerm {
 public:
  string	className()	{ return "EnergyDihedralRestraint"; };
 public:
		// Variables
  Atom_sp      _Atom1;
  Atom_sp      _Atom2;
  Atom_sp      _Atom3;
  Atom_sp      _Atom4;
		// Threshold
  bool		_AboveThreshold;
  double		_AboveThreshold_Phi;
  TermImproperRestraint	term;
#if TURN_ENERGY_FUNCTION_DEBUG_ON
  bool		_calcForce;
  bool		_calcDiagonalHessian;
  bool		_calcOffDiagonalHessian;
#include <cando/chem/energy_functions/_ImproperRestraint_debugEvalDeclares.cc>
#endif

  Atom_sp	getAtom1() { return this->_Atom1; };
  Atom_sp	getAtom2() { return this->_Atom2; };
  Atom_sp	getAtom3() { return this->_Atom3; };
  Atom_sp	getAtom4() { return this->_Atom4; };
  double	getAngle();
 public:
  core::List_sp encode() const;
  void decode(core::List_sp alist);

};


};

namespace translate {

template <>
struct	to_object<chem::EnergyDihedralRestraint >
{
  typedef	core::Cons_sp ExpectedType;
  typedef	core::Cons_sp DeclareType;
  static core::T_sp convert(const chem::EnergyDihedralRestraint& imp)
  {
    return imp.encode();
  }
};

template <>
struct	from_object<chem::EnergyDihedralRestraint>
{
  typedef	chem::EnergyDihedralRestraint	ExpectedType;
  typedef	ExpectedType 		DeclareType;
	DeclareType _v;
	from_object(core::T_sp o)
	{
          SIMPLE_ERROR(BF("Implement me"));
        }
};
};



namespace chem {


double	_evaluateEnergyOnly_ImproperRestraint(
		double x1, double y1, double z1,
		double x2, double y2, double z2,
		double x3, double y3, double z3,
		double x4, double y4, double z4,
		double K, double L, double U );



class EnergyDihedralRestraint_O : public EnergyComponent_O
{
  LISP_CLASS(chem,ChemPkg,EnergyDihedralRestraint_O,"EnergyDihedralRestraint",EnergyComponent_O);
 public: // virtual functions inherited from Object
  void	initialize();
  bool fieldsp() const { return true; };
  void fields(core::Record_sp node);
 public:
  typedef EnergyDihedralRestraint	TermType;
 public: // instance variables
  gctools::Vec0<TermType>		_Terms;
  gctools::Vec0<TermType>	_BeyondThresholdTerms;

 public:	// Creation class functions

 public:	
  typedef gctools::Vec0<TermType>::iterator iterator;
  iterator begin() { return this->_Terms.begin(); };
  iterator end() { return this->_Terms.end(); };
//added by G 7.19.2011
 public:
  virtual size_t numberOfTerms() { return this->_Terms.size();};
 public:
  void addTerm(const TermType& term);
  void addDihedralRestraint(EnergyFunction_sp energyFunction, Atom_sp a1, Atom_sp a2, Atom_sp a3, Atom_sp a4, double minRadians, double maxRadians, double weight);

  virtual bool is_restraint() const { return true; };
  
  virtual void dumpTerms();

  virtual void setupHessianPreconditioner(NVector_sp nvPosition,
                                          AbstractLargeSquareMatrix_sp m );
  virtual double evaluateAllComponent( ScoringFunction_sp scorer,
                                       NVector_sp 	pos,
                                       bool 		calcForce,
                                       gc::Nilable<NVector_sp> 	force,
                                       bool		calcDiagonalHessian,
                                       bool		calcOffDiagonalHessian,
                                       gc::Nilable<AbstractLargeSquareMatrix_sp>	hessian,
                                       gc::Nilable<NVector_sp>	hdvec,
                                       gc::Nilable<NVector_sp> dvec);

  virtual	void	compareAnalyticalAndNumericalForceAndHessianTermByTerm(
                                                                               NVector_sp pos );

  virtual int checkForBeyondThresholdInteractions( stringstream& info, NVector_sp pos );

  virtual string	beyondThresholdInteractionsAsString();


 public:
  EnergyDihedralRestraint_O( const EnergyDihedralRestraint_O& ss ); //!< Copy constructor

  EnergyDihedralRestraint_O() {};
  virtual ~EnergyDihedralRestraint_O() {};
};

};

TRANSLATE(chem::EnergyDihedralRestraint_O);
#endif //]
