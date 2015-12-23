#ifndef	PdbReader_H //[
#define PdbReader_H



#include <stdio.h>
#include <string>
#include <vector>
#include <set>
#include <clasp/core/common.h>
#include <cando/chem/chemPackage.h>
#include <cando/adapt/stringSet.fwd.h>

namespace chem
{
  FORWARD(Atom);
    struct	AtomPdbRec
    {
	string _line;
	// pdb stuff
	string	_recordName;
	int	_serial;
	core::Symbol_sp _name;
	string	_altLoc;
	core::Symbol_sp _resName;
	string _chainId;
	int	_resSeq;
	string	_iCode;
	double	_x;
	double	_y;
	double	_z;
	double	_occupancy;
	double	_tempFactor;
	string	_element;
	string	_charge;
	// my stuff
	Atom_sp	_atom;
	int	_residueIdx;
	int	_moleculeIdx;

        AtomPdbRec() : _atom(_Nil<Atom_O>()) {};
	void write(core::T_sp stream);
	virtual ~AtomPdbRec() {};
	void parse(const string& line);
	Atom_sp createAtom();
    };


};
namespace chem
{

    SMART(Aggregate);
    SMART(Matter);

#if 0
    __ BEGIN_CLASS_DEFINITION(ChemPkg,PdbMonomerConnectivity_O,PdbMonomerConnectivity,core::T_O)
	private:
	string _PdbName;
    geom::ObjectList_sp _HetNames;
    adapt::SymbolMap<adapt::StringSet_O> _Connections;
public:

    __END_CLASS_DEFINITION(PdbMonomerConnectivity_O)


    __ BEGIN_CLASS_DEFINITION(ChemPkg,PdbMonomerDatabase_O,PdbMonomerDatabase,core::T_O)
    __END_CLASS_DEFINITION(PdbMonomerDatabase_O)
#endif





    SMART(PdbReader );
    class PdbReader_O : public core::CxxObject_O
    {
	LISP_CLASS(chem,ChemPkg,PdbReader_O,"PdbReader",core::CxxObject_O);
    public:
//	void	archive(core::ArchiveP node);
	void	initialize();
    private:
    public:
	static Aggregate_sp loadPdb(core::T_sp fileName);
	static Aggregate_sp loadPdbConnectAtoms(core::T_sp fileName);
    public:

	Aggregate_sp	parse(core::T_sp fileName);

	PdbReader_O( const PdbReader_O& ss ); //!< Copy constructor

	DEFAULT_CTOR_DTOR(PdbReader_O);
    };




    SMART(PdbWriter );
    class PdbWriter_O : public core::CxxObject_O
    {
      LISP_CLASS(chem,ChemPkg,PdbWriter_O,"PdbWriter",core::CxxObject_O);
#if INIT_TO_FACTORIES
    public:
      static PdbWriter_sp make(core::T_sp fileName);
#else
      DECLARE_INIT();
#endif
    public:
      void	initialize();
    private:
      core::T_sp      _Out;
    public:
      static void savePdb(Matter_sp matter, core::T_sp fileName);
    public:

      void open(core::T_sp fileName);
      void close();

      void write(Matter_sp matter);
      void writeModel(Matter_sp matter, int model);

      PdbWriter_O( const PdbWriter_O& ss ); //!< Copy constructor

    PdbWriter_O() :  _Out(_Nil<core::T_O>()) {};
      virtual ~PdbWriter_O() {};
    };

};
TRANSLATE(chem::PdbReader_O);
TRANSLATE(chem::PdbWriter_O);
#endif //]
