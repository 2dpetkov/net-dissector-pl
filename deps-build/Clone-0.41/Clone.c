/*
 * This file was generated automatically by ExtUtils::ParseXS version 3.39 from the
 * contents of Clone.xs. Do not edit this file, edit Clone.xs instead.
 *
 *    ANY CHANGES MADE HERE WILL BE LOST!
 *
 */

#line 1 "Clone.xs"
#include <assert.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define CLONE_KEY(x) ((char *) &x) 

#define CLONE_STORE(x,y)						\
do {									\
    if (!hv_store(hseen, CLONE_KEY(x), PTRSIZE, SvREFCNT_inc(y), 0)) {	\
	SvREFCNT_dec(y); /* Restore the refcount */			\
	croak("Can't store clone in seen hash (hseen)");		\
    }									\
    else {	\
  TRACEME(("storing ref = 0x%x clone = 0x%x\n", ref, clone));	\
  TRACEME(("clone = 0x%x(%d)\n", clone, SvREFCNT(clone)));	\
  TRACEME(("ref = 0x%x(%d)\n", ref, SvREFCNT(ref)));	\
    }									\
} while (0)

#define CLONE_FETCH(x) (hv_fetch(hseen, CLONE_KEY(x), PTRSIZE, 0))

static SV *hv_clone (SV *, SV *, HV *, int);
static SV *av_clone (SV *, SV *, HV *, int);
static SV *sv_clone (SV *, HV *, int);
static SV *rv_clone (SV *, HV *, int);

#ifdef DEBUG_CLONE
#define TRACEME(a) printf("%s:%d: ",__FUNCTION__, __LINE__) && printf a;
#else
#define TRACEME(a)
#endif

static SV *
hv_clone (SV * ref, SV * target, HV* hseen, int depth)
{
  HV *clone = (HV *) target;
  HV *self = (HV *) ref;
  HE *next = NULL;
  int recur = depth ? depth - 1 : 0;

  assert(SvTYPE(ref) == SVt_PVHV);

  TRACEME(("ref = 0x%x(%d)\n", ref, SvREFCNT(ref)));

  hv_iterinit (self);
  while ((next = hv_iternext (self)))
    {
      SV *key = hv_iterkeysv (next);
      TRACEME(("clone item %s\n", SvPV_nolen(key) ));
      hv_store_ent (clone, key, 
                sv_clone (hv_iterval (self, next), hseen, recur), 0);
    }

  TRACEME(("clone = 0x%x(%d)\n", clone, SvREFCNT(clone)));
  return (SV *) clone;
}

static SV *
av_clone (SV * ref, SV * target, HV* hseen, int depth)
{
  AV *clone = (AV *) target;
  AV *self = (AV *) ref;
  SV **svp;
  SV *val = NULL;
  I32 arrlen = 0;
  int i = 0;
  int recur = depth ? depth - 1 : 0;

  assert(SvTYPE(ref) == SVt_PVAV);

  TRACEME(("ref = 0x%x(%d)\n", ref, SvREFCNT(ref)));

  /* The following is a holdover from a very old version */
  /* possible cause of memory leaks */
  /* if ( (SvREFCNT(ref) > 1) ) */
  /*   CLONE_STORE(ref, (SV *)clone); */

  arrlen = av_len (self);
  av_extend (clone, arrlen);

  for (i = 0; i <= arrlen; i++)
    {
      svp = av_fetch (self, i, 0);
      if (svp)
	av_store (clone, i, sv_clone (*svp, hseen, recur));
    }

  TRACEME(("clone = 0x%x(%d)\n", clone, SvREFCNT(clone)));
  return (SV *) clone;
}

static SV *
rv_clone (SV * ref, HV* hseen, int depth)
{
  SV *clone = NULL;
  SV *rv = NULL;

  assert(SvROK(ref));

  TRACEME(("ref = 0x%x(%d)\n", ref, SvREFCNT(ref)));

  if (!SvROK (ref))
    return NULL;

  if (sv_isobject (ref))
    {
      clone = newRV_noinc(sv_clone (SvRV(ref), hseen, depth));
      sv_2mortal (sv_bless (clone, SvSTASH (SvRV (ref))));
    }
  else
    clone = newRV_inc(sv_clone (SvRV(ref), hseen, depth));
    
  TRACEME(("clone = 0x%x(%d)\n", clone, SvREFCNT(clone)));
  return clone;
}

static SV *
sv_clone (SV * ref, HV* hseen, int depth)
{
  SV *clone = ref;
  SV **seen = NULL;
  UV visible;
  int magic_ref = 0;

  if (!ref)
    {
      TRACEME(("NULL\n"));
      return NULL;
    }

#if PERL_REVISION >= 5 && PERL_VERSION > 8
  /* This is a hack for perl 5.9.*, save everything */
  /* until I find out why mg_find is no longer working */
  visible = 1;
#else
  visible = (SvREFCNT(ref) > 1) || (SvMAGICAL(ref) && mg_find(ref, '<'));
#endif

  TRACEME(("ref = 0x%x(%d)\n", ref, SvREFCNT(ref)));

  if (depth == 0)
    return SvREFCNT_inc(ref);

  if (visible && (seen = CLONE_FETCH(ref)))
    {
      TRACEME(("fetch ref (0x%x)\n", ref));
      return SvREFCNT_inc(*seen);
    }

  TRACEME(("switch: (0x%x)\n", ref));
  switch (SvTYPE (ref))
    {
      case SVt_NULL:	/* 0 */
        TRACEME(("sv_null\n"));
        clone = newSVsv (ref);
        break;
      case SVt_IV:		/* 1 */
        TRACEME(("int scalar\n"));
      case SVt_NV:		/* 2 */
        TRACEME(("double scalar\n"));
        clone = newSVsv (ref);
        break;
#if PERL_VERSION <= 10
      case SVt_RV:		/* 3 */
        TRACEME(("ref scalar\n"));
        clone = newSVsv (ref);
        break;
#endif
      case SVt_PV:		/* 4 */
        TRACEME(("string scalar\n"));
/*
* Note: when using a Debug Perl with READONLY_COW
* we cannot do 'sv_buf_to_rw + sv_buf_to_ro' as these APIs calls are not exported
*/
#if PERL_VERSION >= 20 && !defined(PERL_DEBUG_READONLY_COW)
        /* only for simple PVs unblessed */
        if ( SvIsCOW(ref) && !SvOOK(ref) && SvLEN(ref) > 0
            && CowREFCNT(ref) < SV_COW_REFCNT_MAX ) {
          /* cannot use newSVpv_share as this going to use a new PV we do not want to clone it */
          /* create a fresh new PV */
          clone = newSV(0);
          sv_upgrade(clone, SVt_PV);
          SvPOK_on(clone);
          SvIsCOW_on(clone);

          /* points the str slot to the COWed one */
          SvPV_set(clone, SvPVX(ref) );
          CowREFCNT(ref)++;

          /* preserve cur, len, flags and utf8 flag */
          SvCUR_set(clone, SvCUR(ref));
          SvLEN_set(clone, SvLEN(ref));
          //SvFLAGS(clone) = SvFLAGS(ref);

          if (SvUTF8(ref))
            SvUTF8_on(clone);

        } else {
          clone = newSVsv (ref);
        }
#else
        clone = newSVsv (ref);
#endif
        break;
      case SVt_PVIV:		/* 5 */
        TRACEME (("PVIV double-type\n"));
      case SVt_PVNV:		/* 6 */
        TRACEME (("PVNV double-type\n"));
        clone = newSVsv (ref);
        break;
      case SVt_PVMG:	/* 7 */
        TRACEME(("magic scalar\n"));
        clone = newSVsv (ref);
        break;
      case SVt_PVAV:	/* 10 */
        clone = (SV *) newAV();
        break;
      case SVt_PVHV:	/* 11 */
        clone = (SV *) newHV();
        break;
      #if PERL_VERSION <= 8
      case SVt_PVBM:	/* 8 */
      #elif PERL_VERSION >= 11
      case SVt_REGEXP:	/* 8 */
      #endif
      case SVt_PVLV:	/* 9 */
      case SVt_PVCV:	/* 12 */
      case SVt_PVGV:	/* 13 */
      case SVt_PVFM:	/* 14 */
      case SVt_PVIO:	/* 15 */
        TRACEME(("default: type = 0x%x\n", SvTYPE (ref)));
        clone = SvREFCNT_inc(ref);  /* just return the ref */
        break;
      default:
        croak("unknown type: 0x%x", SvTYPE(ref));
    }

  /**
    * It is *vital* that this is performed *before* recursion,
    * to properly handle circular references. cb 2001-02-06
    */

  if ( visible && ref != clone )
      CLONE_STORE(ref,clone);

    /*
     * We'll assume (in the absence of evidence to the contrary) that A) a
     * tied hash/array doesn't store its elements in the usual way (i.e.
     * the mg->mg_object(s) take full responsibility for them) and B) that
     * references aren't tied.
     *
     * If theses assumptions hold, the three options below are mutually
     * exclusive.
     *
     * More precisely: 1 & 2 are probably mutually exclusive; 2 & 3 are 
     * definitely mutually exclusive; we have to test 1 before giving 2
     * a chance; and we'll assume that 1 & 3 are mutually exclusive unless
     * and until we can be test-cased out of our delusion.
     *
     * chocolateboy: 2001-05-29
     */
     
    /* 1: TIED */
  if (SvMAGICAL(ref) )
    {
      MAGIC* mg;
      MGVTBL *vtable = 0;

      for (mg = SvMAGIC(ref); mg; mg = mg->mg_moremagic) 
      {
        SV *obj = (SV *) NULL;
	/* we don't want to clone a qr (regexp) object */
	/* there are probably other types as well ...  */
        TRACEME(("magic type: %c\n", mg->mg_type));
        /* Some mg_obj's can be null, don't bother cloning */
        if ( mg->mg_obj != NULL )
        {
          switch (mg->mg_type)
          {
            case 'r':	/* PERL_MAGIC_qr  */
              obj = mg->mg_obj; 
              break;
            case 't':	/* PERL_MAGIC_taint */
	      continue;
              break;
            case '<':	/* PERL_MAGIC_backref */
	      continue;
              break;
            case '@':  /* PERL_MAGIC_arylen_p */
             continue;
              break;
            case 'P': /* PERL_MAGIC_tied */
            case 'p': /* PERL_MAGIC_tiedelem */
            case 'q': /* PERL_MAGIC_tiedscalar */
	      magic_ref++;
	      /* fall through */
            default:
              obj = sv_clone(mg->mg_obj, hseen, -1); 
          }
        } else {
          TRACEME(("magic object for type %c in NULL\n", mg->mg_type));
        }
	/* this is plain old magic, so do the same thing */
        sv_magic(clone, 
                 obj,
                 mg->mg_type, 
                 mg->mg_ptr, 
                 mg->mg_len);
      }
      /* major kludge - why does the vtable for a qr type need to be null? */
      if ( (mg = mg_find(clone, 'r')) )
        mg->mg_virtual = (MGVTBL *) NULL;
    }
    /* 2: HASH/ARRAY  - (with 'internal' elements) */
  if ( magic_ref )
  {
    ;;
  }
  else if ( SvTYPE(ref) == SVt_PVHV )
    clone = hv_clone (ref, clone, hseen, depth);
  else if ( SvTYPE(ref) == SVt_PVAV )
    clone = av_clone (ref, clone, hseen, depth);
    /* 3: REFERENCE (inlined for speed) */
  else if (SvROK (ref))
    {
      TRACEME(("clone = 0x%x(%d)\n", clone, SvREFCNT(clone)));
      SvREFCNT_dec(SvRV(clone));
      SvRV(clone) = sv_clone (SvRV(ref), hseen, depth); /* Clone the referent */
      if (sv_isobject (ref))
      {
          sv_bless (clone, SvSTASH (SvRV (ref)));
      }
      if (SvWEAKREF(ref)) {
          sv_rvweaken(clone);
      }
    }

  TRACEME(("clone = 0x%x(%d)\n", clone, SvREFCNT(clone)));
  return clone;
}

#line 354 "Clone.c"
#ifndef PERL_UNUSED_VAR
#  define PERL_UNUSED_VAR(var) if (0) var = var
#endif

#ifndef dVAR
#  define dVAR		dNOOP
#endif


/* This stuff is not part of the API! You have been warned. */
#ifndef PERL_VERSION_DECIMAL
#  define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#endif
#ifndef PERL_DECIMAL_VERSION
#  define PERL_DECIMAL_VERSION \
	  PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#endif
#ifndef PERL_VERSION_GE
#  define PERL_VERSION_GE(r,v,s) \
	  (PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))
#endif
#ifndef PERL_VERSION_LE
#  define PERL_VERSION_LE(r,v,s) \
	  (PERL_DECIMAL_VERSION <= PERL_VERSION_DECIMAL(r,v,s))
#endif

/* XS_INTERNAL is the explicit static-linkage variant of the default
 * XS macro.
 *
 * XS_EXTERNAL is the same as XS_INTERNAL except it does not include
 * "STATIC", ie. it exports XSUB symbols. You probably don't want that
 * for anything but the BOOT XSUB.
 *
 * See XSUB.h in core!
 */


/* TODO: This might be compatible further back than 5.10.0. */
#if PERL_VERSION_GE(5, 10, 0) && PERL_VERSION_LE(5, 15, 1)
#  undef XS_EXTERNAL
#  undef XS_INTERNAL
#  if defined(__CYGWIN__) && defined(USE_DYNAMIC_LOADING)
#    define XS_EXTERNAL(name) __declspec(dllexport) XSPROTO(name)
#    define XS_INTERNAL(name) STATIC XSPROTO(name)
#  endif
#  if defined(__SYMBIAN32__)
#    define XS_EXTERNAL(name) EXPORT_C XSPROTO(name)
#    define XS_INTERNAL(name) EXPORT_C STATIC XSPROTO(name)
#  endif
#  ifndef XS_EXTERNAL
#    if defined(HASATTRIBUTE_UNUSED) && !defined(__cplusplus)
#      define XS_EXTERNAL(name) void name(pTHX_ CV* cv __attribute__unused__)
#      define XS_INTERNAL(name) STATIC void name(pTHX_ CV* cv __attribute__unused__)
#    else
#      ifdef __cplusplus
#        define XS_EXTERNAL(name) extern "C" XSPROTO(name)
#        define XS_INTERNAL(name) static XSPROTO(name)
#      else
#        define XS_EXTERNAL(name) XSPROTO(name)
#        define XS_INTERNAL(name) STATIC XSPROTO(name)
#      endif
#    endif
#  endif
#endif

/* perl >= 5.10.0 && perl <= 5.15.1 */


/* The XS_EXTERNAL macro is used for functions that must not be static
 * like the boot XSUB of a module. If perl didn't have an XS_EXTERNAL
 * macro defined, the best we can do is assume XS is the same.
 * Dito for XS_INTERNAL.
 */
#ifndef XS_EXTERNAL
#  define XS_EXTERNAL(name) XS(name)
#endif
#ifndef XS_INTERNAL
#  define XS_INTERNAL(name) XS(name)
#endif

/* Now, finally, after all this mess, we want an ExtUtils::ParseXS
 * internal macro that we're free to redefine for varying linkage due
 * to the EXPORT_XSUB_SYMBOLS XS keyword. This is internal, use
 * XS_EXTERNAL(name) or XS_INTERNAL(name) in your code if you need to!
 */

#undef XS_EUPXS
#if defined(PERL_EUPXS_ALWAYS_EXPORT)
#  define XS_EUPXS(name) XS_EXTERNAL(name)
#else
   /* default to internal */
#  define XS_EUPXS(name) XS_INTERNAL(name)
#endif

#ifndef PERL_ARGS_ASSERT_CROAK_XS_USAGE
#define PERL_ARGS_ASSERT_CROAK_XS_USAGE assert(cv); assert(params)

/* prototype to pass -Wmissing-prototypes */
STATIC void
S_croak_xs_usage(const CV *const cv, const char *const params);

STATIC void
S_croak_xs_usage(const CV *const cv, const char *const params)
{
    const GV *const gv = CvGV(cv);

    PERL_ARGS_ASSERT_CROAK_XS_USAGE;

    if (gv) {
        const char *const gvname = GvNAME(gv);
        const HV *const stash = GvSTASH(gv);
        const char *const hvname = stash ? HvNAME(stash) : NULL;

        if (hvname)
	    Perl_croak_nocontext("Usage: %s::%s(%s)", hvname, gvname, params);
        else
	    Perl_croak_nocontext("Usage: %s(%s)", gvname, params);
    } else {
        /* Pants. I don't think that it should be possible to get here. */
	Perl_croak_nocontext("Usage: CODE(0x%" UVxf ")(%s)", PTR2UV(cv), params);
    }
}
#undef  PERL_ARGS_ASSERT_CROAK_XS_USAGE

#define croak_xs_usage        S_croak_xs_usage

#endif

/* NOTE: the prototype of newXSproto() is different in versions of perls,
 * so we define a portable version of newXSproto()
 */
#ifdef newXS_flags
#define newXSproto_portable(name, c_impl, file, proto) newXS_flags(name, c_impl, file, proto, 0)
#else
#define newXSproto_portable(name, c_impl, file, proto) (PL_Sv=(SV*)newXS(name, c_impl, file), sv_setpv(PL_Sv, proto), (CV*)PL_Sv)
#endif /* !defined(newXS_flags) */

#if PERL_VERSION_LE(5, 21, 5)
#  define newXS_deffile(a,b) Perl_newXS(aTHX_ a,b,file)
#else
#  define newXS_deffile(a,b) Perl_newXS_deffile(aTHX_ a,b)
#endif

#line 498 "Clone.c"

XS_EUPXS(XS_Clone_clone); /* prototype to pass -Wmissing-prototypes */
XS_EUPXS(XS_Clone_clone)
{
    dVAR; dXSARGS;
    if (items < 1 || items > 2)
       croak_xs_usage(cv,  "self, depth=-1");
    PERL_UNUSED_VAR(ax); /* -Wall */
    SP -= items;
    {
	SV *	self = ST(0)
;
	int	depth;
#line 353 "Clone.xs"
	SV *clone = &PL_sv_undef;
        HV *hseen = newHV();
#line 515 "Clone.c"

	if (items < 2)
	    depth = -1;
	else {
	    depth = (int)SvIV(ST(1))
;
	}
#line 356 "Clone.xs"
	TRACEME(("ref = 0x%x\n", self));
	clone = sv_clone(self, hseen, depth);
	hv_clear(hseen);  /* Free HV */
        SvREFCNT_dec((SV *)hseen);
	EXTEND(SP,1);
	PUSHs(sv_2mortal(clone));
#line 530 "Clone.c"
	PUTBACK;
	return;
    }
}

#ifdef __cplusplus
extern "C"
#endif
XS_EXTERNAL(boot_Clone); /* prototype to pass -Wmissing-prototypes */
XS_EXTERNAL(boot_Clone)
{
#if PERL_VERSION_LE(5, 21, 5)
    dVAR; dXSARGS;
#else
    dVAR; dXSBOOTARGSXSAPIVERCHK;
#endif
#if (PERL_REVISION == 5 && PERL_VERSION < 9)
    char* file = __FILE__;
#else
    const char* file = __FILE__;
#endif

    PERL_UNUSED_VAR(file);

    PERL_UNUSED_VAR(cv); /* -W */
    PERL_UNUSED_VAR(items); /* -W */
#if PERL_VERSION_LE(5, 21, 5)
    XS_VERSION_BOOTCHECK;
#  ifdef XS_APIVERSION_BOOTCHECK
    XS_APIVERSION_BOOTCHECK;
#  endif
#endif

        (void)newXSproto_portable("Clone::clone", XS_Clone_clone, file, "$;$");
#if PERL_VERSION_LE(5, 21, 5)
#  if PERL_VERSION_GE(5, 9, 0)
    if (PL_unitcheckav)
        call_list(PL_scopestack_ix, PL_unitcheckav);
#  endif
    XSRETURN_YES;
#else
    Perl_xs_boot_epilog(aTHX_ ax);
#endif
}

