#=
Low-level wrapper for PCRE2 library

Copyright 2018 Gandalf Software, Inc., Scott P. Jones, and other contributors to the Julia language
Licensed under MIT License, see LICENSE.md
Based in part on julia/base/pcre.jl, and on pcre2.h (copyright University of Cambridge)
=#

__precompile__()
module PCRE2

const CodeUnitTypes = Union{UInt8, UInt16, UInt32}

@static if VERSION < v"v0.7.0-DEV"
    macro preserve(args...)
        syms = args[1:end-1]
        for x in syms
            isa(x, Symbol) || error("Preserved variable must be a symbol")
        end
        esc(quote ; $(args[end]) ; end)
    end
    ev(s) = eval(parse(s))
    const Nothing = Void
    const Cvoid   = Void
    _ncodeunits(::Type{UInt8}, s)  = sizeof(s)
    _ncodeunits(::Type{UInt16}, s) = sizeof(s)>>>1
    _ncodeunits(::Type{UInt32}, s) = sizeof(s)>>>2
    _ncodeunits(s) = _ncodeunits(codeunit(s), s)
    create_vector(T, len) = Vector{T}(len)
else # !V6_COMPAT
    import Base.GC: @preserve
    ev(s) = eval(Meta.parse(s))
    const _ncodeunits = ncodeunits
    create_vector(T, len)  = Vector{T}(undef, len)
end

import Base: RefValue

# The following option bits can be passed to pcre2_compile(), pcre2_match(), or pcre2_dfa_match().
# PCRE2_NO_UTF_CHECK affects only the function to which it is passed. Put these bits at the most
# significant end of the options word so others can be added next to them

const ANCHORED            = 0x80000000
const NO_UTF_CHECK        = 0x40000000
const ENDANCHORED         = 0x20000000

# The following option bits can be passed only to pcre2_compile().
# However, they may affect compilation, JIT compilation, and/or interpretive execution.
# The following tags indicate which:

# C   alters what is compiled by pcre2_compile()
# J   alters what is compiled by pcre2_jit_compile()
# M   is inspected during pcre2_match() execution
# D   is inspected during pcre2_dfa_match() execution

const ALLOW_EMPTY_CLASS   = 0x00000001  # C
const ALT_BSUX            = 0x00000002  # C
const AUTO_CALLOUT        = 0x00000004  # C
const CASELESS            = 0x00000008  # C
const DOLLAR_ENDONLY      = 0x00000010  #   J M D
const DOTALL              = 0x00000020  # C
const DUPNAMES            = 0x00000040  # C
const EXTENDED            = 0x00000080  # C
const FIRSTLINE           = 0x00000100  #   J M D
const MATCH_UNSET_BACKREF = 0x00000200  # C J M
const MULTILINE           = 0x00000400  # C
const NEVER_UCP           = 0x00000800  # C
const NEVER_UTF           = 0x00001000  # C
const NO_AUTO_CAPTURE     = 0x00002000  # C
const NO_AUTO_POSSESS     = 0x00004000  # C
const NO_DOTSTAR_ANCHOR   = 0x00008000  # C
const NO_START_OPTIMIZE   = 0x00010000  #   J M D
const UCP                 = 0x00020000  # C J M D
const UNGREEDY            = 0x00040000  # C
const UTF                 = 0x00080000  # C J M D
const NEVER_BACKSLASH_C   = 0x00100000  # C
const ALT_CIRCUMFLEX      = 0x00200000  #   J M D
const ALT_VERBNAMES       = 0x00400000  # C
const USE_OFFSET_LIMIT    = 0x00800000  #   J M D
const EXTENDED_MORE       = 0x01000000  # C
const LITERAL             = 0x02000000  # C

## An additional compile options word is available in the compile context.

const EXTRA_ALLOW_SURROGATE_ESCAPES  = 0x00000001  # C
const EXTRA_BAD_ESCAPE_IS_LITERAL    = 0x00000002  # C
const EXTRA_MATCH_WORD               = 0x00000004  # C
const EXTRA_MATCH_LINE               = 0x00000008  # C

## These are for pcre2_jit_compile().

const JIT_COMPLETE        = 0x00000001  # For full matching */
const JIT_PARTIAL_SOFT    = 0x00000002
const JIT_PARTIAL_HARD    = 0x00000004

## These are for pcre2_match(), pcre2_dfa_match(), and pcre2_jit_match().
## Note that PCRE2_ANCHORED and PCRE2_NO_UTF_CHECK can also be passed to these functions
## (though pcre2_jit_match() ignores the latter since it bypasses all sanity checks).

const NOTBOL              = 0x00000001
const NOTEOL              = 0x00000002
const NOTEMPTY            = 0x00000004  # ) These two must be kept
const NOTEMPTY_ATSTART    = 0x00000008  # ) adjacent to each other
const PARTIAL_SOFT        = 0x00000010
const PARTIAL_HARD        = 0x00000020

## These are additional options for pcre2_dfa_match()

const DFA_RESTART         = 0x00000040
const DFA_SHORTEST        = 0x00000080

## These are additional options for substitute(), which passes any others through to match()

const SUBSTITUTE_GLOBAL           = 0x00000100
const SUBSTITUTE_EXTENDED         = 0x00000200
const SUBSTITUTE_UNSET_EMPTY      = 0x00000400
const SUBSTITUTE_UNKNOWN_UNSET    = 0x00000800
const SUBSTITUTE_OVERFLOW_LENGTH  = 0x00001000

## A further option for match(), not allowed for dfa_match(), ignored for jit_match()

const NO_JIT              = 0x00002000

## Options for pattern_convert()

const CONVERT_UTF                    = 0x00000001
const CONVERT_NO_UTF_CHECK           = 0x00000002
const CONVERT_POSIX_BASIC            = 0x00000004
const CONVERT_POSIX_EXTENDED         = 0x00000008
const CONVERT_GLOB                   = 0x00000010
const CONVERT_GLOB_NO_WILD_SEPARATOR = 0x00000030
const CONVERT_GLOB_NO_STARSTAR       = 0x00000050

## Newline and \R settings, for use in compile contexts. The newline values must be kept in step
## with values set in config.h and both sets must all be greater than zero.

const NEWLINE_CR          = 1
const NEWLINE_LF          = 2
const NEWLINE_CRLF        = 3
const NEWLINE_ANY         = 4
const NEWLINE_ANYCRLF     = 5
const NEWLINE_NUL         = 6

const BSR_UNICODE         = 1
const BSR_ANYCRLF         = 2

## Request types for pattern_info()

@enum(INFO::Int32,
      INFO_ALLOPTIONS = 0,
      INFO_ARGOPTIONS,
      INFO_BACKREFMAX,
      INFO_BSR,
      INFO_CAPTURECOUNT,
      INFO_FIRSTCODEUNIT,
      INFO_FIRSTCODETYPE,
      INFO_FIRSTBITMAP,
      INFO_HASCRORLF,
      INFO_JCHANGED,
      INFO_JITSIZE,
      INFO_LASTCODEUNIT,
      INFO_LASTCODETYPE,
      INFO_MATCHEMPTY,
      INFO_MATCHLIMIT,
      INFO_MAXLOOKBEHIND,
      INFO_MINLENGTH,
      INFO_NAMECOUNT,
      INFO_NAMEENTRYSIZE,
      INFO_NAMETABLE,
      INFO_NEWLINE,
      INFO_DEPTHLIMIT,
      INFO_SIZE,
      INFO_HASBACKSLASHC,
      INFO_FRAMESIZE,
      INFO_HEAPLIMIT,
      INFO_EXTRAOPTIONS)

## Request types for config()

@enum(CONFIG::Int32,
      CONFIG_BSR = 0,
      CONFIG_JIT,
      CONFIG_JITTARGET,
      CONFIG_LINKSIZE,
      CONFIG_MATCHLIMIT,
      CONFIG_NEWLINE,
      CONFIG_PARENSLIMIT,
      CONFIG_DEPTHLIMIT,
      CONFIG_STACKRECURSE,  # Obsolete
      CONFIG_UNICODE,
      CONFIG_UNICODE_VERSION,
      CONFIG_VERSION,
      CONFIG_HEAPLIMIT,
      CONFIG_NEVER_BACKSLASH_C,
      CONFIG_COMPILED_WIDTHS)


# supported options for different use cases

const NL_MASK =
    NEWLINE_ANY | NEWLINE_ANYCRLF | NEWLINE_CR | NEWLINE_CRLF | NEWLINE_LF

const COMMON_MASK = ANCHORED | ENDANCHORED | NO_UTF_CHECK

const COMPILE_MASK =
    (COMMON_MASK
     | ALLOW_EMPTY_CLASS
     | ALT_BSUX
     | AUTO_CALLOUT
     | CASELESS
     | DOLLAR_ENDONLY
     | DOTALL
     | DUPNAMES
     | EXTENDED
     | FIRSTLINE
     | MATCH_UNSET_BACKREF
     | MULTILINE
     | NEVER_UCP
     | NEVER_UTF
     | NO_AUTO_CAPTURE
     | NO_AUTO_POSSESS
     | NO_DOTSTAR_ANCHOR
     | NO_START_OPTIMIZE
     | UCP
     | UNGREEDY
     | UTF
     | NEVER_BACKSLASH_C
     | ALT_CIRCUMFLEX
     | ALT_VERBNAMES
     | USE_OFFSET_LIMIT
     | EXTENDED_MORE
     | LITERAL
     )

const MATCH_MASK =
    (COMMON_MASK
     | NOTBOL
     | NOTEOL
     | NOTEMPTY
     | NOTEMPTY_ATSTART
     | PARTIAL_HARD
     | PARTIAL_SOFT
     )

const LIB_8  = "libpcre2-8"
const LIB_16 = "libpcre2-16"
const LIB_32 = "libpcre2-32"

const UNSET = ~Csize_t(0)  # Indicates that an output vector element is unset

struct _UCHAR end

## Type definitions for PCRE bindings

const UCharP          = Ptr{_UCHAR} # This is really Ptr{UInt8},Ptr{UInt16},Ptr{UInt32}
const StrP            = UCharP
const VoidP           = Ptr{Cvoid}
const GeneralContextP = Ptr{Cvoid}
const CompileContextP = Ptr{Cvoid}
const MatchContextP   = Ptr{Cvoid}
const ConvertContextP = Ptr{Cvoid}
const MatchDataP      = Ptr{Cvoid}
const CodeP           = Ptr{Cvoid}
const JitStackP       = Ptr{Cvoid}
const SizeP           = Ptr{Csize_t}
const SizeRef         = Ref{Csize_t}
const MatchOptions    = UInt32
const CompileOptions  = UInt32

const funclist =
(
 (:config, Cint, (CONFIG, VoidP)),


## Functions for manipulating contexts

# GENERAL CONTEXT FUNCTIONS
 (:general_context_copy,      GeneralContextP, (GeneralContextP,)),
 #(:general_context_create, GeneralContextP,
 #    (VoidP (*)(Csize_t, VoidP), Cvoid (*)(VoidP, VoidP), VoidP)),
 (:general_context_free,      Cvoid,           (GeneralContextP,)),

# COMPILE CONTEXT FUNCTIONS
 (:compile_context_copy,      CompileContextP, (CompileContextP,)),
 (:compile_context_create,    CompileContextP, (GeneralContextP,)),
 (:compile_context_free,      Cvoid,           (CompileContextP,)),
 (:set_bsr,                   Cint,            (CompileContextP, UInt32)),
 (:set_character_tables,      Cint,            (CompileContextP, Ptr{UInt8})),
 (:set_compile_extra_options, Cint,            (CompileContextP, UInt32)),
 (:set_max_pattern_length,    Cint,            (CompileContextP, Csize_t)),
 (:set_newline,               Cint,            (CompileContextP, UInt32)),
 (:set_parens_nest_limit,     Cint,            (CompileContextP, UInt32)),
 #(:set_compile_recursion_guard, Cint, (CompileContextP, Cint (*)(UInt32, VoidP), VoidP)

# MATCH CONTEXT FUNCTIONS
 (:match_context_copy,        MatchContextP,   (MatchContextP,)),
 (:match_context_create,      MatchContextP,   (GeneralContextP,)),
 (:match_context_free,        Cvoid,           (MatchContextP,)),
 #(:set_callout, Cint, (MatchContextP, Cint (*)(callout_block *, VoidP), VoidP)),
 (:set_depth_limit,           Cint,            (MatchContextP, UInt32)),
 (:set_heap_limit,            Cint,            (MatchContextP, UInt32)),
 (:set_match_limit,           Cint,            (MatchContextP, UInt32)),
 (:set_offset_limit,          Cint,            (MatchContextP, Csize_t)),
 (:set_recursion_limit,       Cint,            (MatchContextP, UInt32)),
 #(:set_recursion_memory_management, Cint,
 # (MatchContextP, VoidP (*)(Csize_t, VoidP), Cvoid (*)(VoidP, VoidP), VoidP)),

# CONVERT CONTEXT FUNCTIONS
 (:convert_context_copy,      ConvertContextP, (ConvertContextP,)),
 (:convert_context_create,    ConvertContextP, (GeneralContextP,)),
 (:convert_context_free,      Cvoid,           (ConvertContextP,)),
 (:set_glob_escape,           Cint,            (ConvertContextP, UInt32)),
 (:set_glob_separator,        Cint,            (ConvertContextP, UInt32)),


## Functions concerned with compiling a pattern to PCRE internal code

# COMPILE FUNCTIONS
 (:compile, CodeP, (StrP, Csize_t, CompileOptions, Ref{Cint}, SizeRef, CompileContextP)),
 (:code_free,                 Cvoid,           (CodeP,)),
 (:code_copy,                 CodeP,           (CodeP,)),
 (:code_copy_with_tables,     CodeP,           (CodeP,)),

## Functions that give information about a compiled pattern

# PATTERN INFO FUNCTIONS
 (:pattern_info,              Cint,            (CodeP, INFO, VoidP)),
#(:callout_enumerate, Cint, (CodeP, Cint (*)(callout_enumerate_block *, VoidP), VoidP)),


## Functions for running a match and inspecting the result.

# MATCH FUNCTIONS
 (:match_data_create,          MatchDataP,     (UInt32, GeneralContextP)),
 (:match_data_create_from_pattern, MatchDataP, (CodeP, GeneralContextP)),
 (:dfa_match,                  Cint,
  (CodeP, StrP, Csize_t, Csize_t, MatchOptions, MatchDataP, MatchContextP, Ptr{Cint}, Csize_t)),
 (:match,                      Cint,
  (CodeP, StrP, Csize_t, Csize_t, MatchOptions, MatchDataP, MatchContextP)),
 (:match_data_free,            Cvoid,          (MatchDataP,)),
 (:get_mark,                   StrP,           (MatchDataP,)),
 (:get_ovector_count,          UInt32,         (MatchDataP,)),
 (:get_ovector_pointer,        SizeP,          (MatchDataP,)),
 (:get_startchar,              Csize_t,        (MatchDataP,)),


## Convenience functions for handling matched substrings

# SUBSTRING FUNCTIONS
 (:substring_copy_byname,      Cint,           (MatchDataP, StrP, UCharP, SizeRef)),
 (:substring_copy_bynumber,    Cint,           (MatchDataP, UInt32, UCharP, SizeRef)),
 (:substring_free,             Cvoid,          (UCharP,)),
 (:substring_get_byname,       Cint,           (MatchDataP, StrP, Ref{UCharP}, SizeRef)),
 (:substring_get_bynumber,     Cint,           (MatchDataP, UInt32, Ref{UCharP}, SizeRef)),
 (:substring_length_byname,    Cint,           (MatchDataP, StrP, SizeRef)),
 (:substring_length_bynumber,  Cint,           (MatchDataP, UInt32, SizeRef)),
 (:substring_nametable_scan,   Cint,           (CodeP, StrP, Ptr{StrP}, Ptr{StrP})),
 (:substring_number_from_name, Cint,           (CodeP, StrP)),
 (:substring_list_free,        Cvoid,          (Ptr{StrP},)),
 (:substring_list_get,         Cint,           (MatchDataP, Ptr{Ptr{UCharP}}, Ptr{SizeP})),


## Functions for serializing / deserializing compiled patterns

# SERIALIZE FUNCTIONS
 (:serialize_encode,           Int32,
    (Ptr{CodeP}, Int32, Ptr{Ptr{UInt8}}, SizeP, GeneralContextP)),
 (:serialize_decode,           Int32,          (Ptr{CodeP}, Int32, Ptr{UInt8}, GeneralContextP)),
 (:serialize_get_number_of_codes, Int32,       (Ptr{UInt8},)),
 (:serialize_free,             Cvoid,          (Ptr{UInt8},)),


## Convenience function for match + substitute.

 (:substitute,                 Cint,
    (CodeP, StrP, Csize_t, Csize_t, MatchOptions, MatchDataP, MatchContextP,
     StrP, Csize_t, UCharP, SizeP)),


## Functions for converting pattern source strings

# CONVERT FUNCTIONS
 (:pattern_convert,            Cint, (StrP, Csize_t, UInt32, Ptr{UCharP}, SizeP, ConvertContextP)),
 (:converted_pattern_free,     Cvoid,          (UCharP,)),


## Functions for JIT processing

# JIT FUNCTIONS
 (:jit_compile,                Cint,           (CodeP, UInt32)),
 (:jit_match,                  Cint,
    (CodeP, StrP, Csize_t, Csize_t, UInt32, MatchDataP, MatchContextP)),
 (:jit_free_unused_memory,     Cvoid,          (GeneralContextP,)),
 (:jit_stack_create,           JitStackP,      (Csize_t, Csize_t, GeneralContextP)),
 (:jit_stack_assign,           Cvoid,          (MatchContextP, VoidP, VoidP)), # jit_callback
 (:jit_stack_free,             Cvoid,          (JitStackP,)),


## Other miscellaneous functions

 (:get_error_message,          Cint,           (Cint, UCharP, Csize_t)),
 (:maketables,                 Ptr{UInt8},     (GeneralContextP,))
)

for siz in (8,16,32), (nam, ret, sig) in funclist
    l = SubString("a,b,c,d,e,f,g,h,i,j,k,l,m", 1, length(sig)*2-1)
    #parms = string(["$('a'+i-1)::$(sig[i]), " for i=1:length(sig)]...)[1:end-1]
    sub = "UInt$siz"
    rep = "PCRE2._UCHAR"
    str = "$nam(::Type{$sub},$l)=ccall((:pcre2_$(nam)_$siz,LIB_$siz),$ret,$sig,$l)"
    ev(@static VERSION < v"v0.7.0-DEV" ? replace(str, rep, sub) : replace(str, rep => sub))
end

struct PCRE2_Error <: Exception
    errmsg::String
    errno::Int32
    erroff::Int32
    PCRE2_Error(errmsg, errno, erroff = -1) = new(errmsg, errno%Int32, erroff%Int32)
end

Base.show(io::IO, exc::PCRE2_Error) =
    print(io, "PCRE2: ", exc.errmsg,
          exc.errno < 0 ? "" : "error: $(err_message(exc.errno))",
          exc.erroff < 0 ? "" : "at offset $(exc.erroff)")

pcre_error(msg::AbstractString) = throw(PCRE2_Error(msg, -1))
pcre_error(errno::Integer)      = throw(PCRE2_Error("", errno))
jit_error(errno::Integer)       = throw(PCRE2_Error("JIT ", errno))
compile_error(errno, erroff)    = throw(PCRE2_Error("compilation ", errno, erroff))

function info_error(errno)
    errno == ERROR_NULL && pcre_error("NULL regex object")
    errno == ERROR_BADMAGIC && pcre_error("Invalid regex object")
    errno == ERROR_BADOPTION && pcre_error("Invalid option flags")
    pcre_error(errno)
end

"""PCRE2 pattern_info call wrapper"""
function info(::Type{T}, regex::CodeP, what::INFO, ::Type{S}) where {S,T<:CodeUnitTypes}
    buf = RefValue{S}()
    ret = pattern_info(T, regex, what, buf)
    ret == 0 ? buf[] : info_error(ret)
end

get_ovec(::Type{T}, md) where {T<:CodeUnitTypes} =
    unsafe_wrap(Array, get_ovector_pointer(T, md), 2 * get_ovector_count(T, md))

"""Wrapper for compile() function, throw error on error return with error info"""
function compile(pattern::T, options::Integer) where {T<:AbstractString}
    errno = RefValue{Cint}(0)
    erroff = RefValue{Csize_t}(0)
    re_ptr = compile(codeunit(T), pattern, _ncodeunits(pattern), options, errno, erroff, C_NULL)
    re_ptr == C_NULL ? compile_error(errno[], erroff[]) : re_ptr
end

"""Wrapper for jit_compile() function, throw error on error return with error info"""
jit_compile(::Type{T}, regex::CodeP) where {T<:CodeUnitTypes} =
    ((errno = jit_compile(T, regex, JIT_COMPLETE)) == 0 || jit_error(errno) ; nothing)

function err_message(errno)
    buffer = create_vector(UInt8, 256)
    get_error_message(UInt8, errno, buffer, sizeof(buffer))
    @preserve buffer unsafe_string(pointer(buffer))
end

function sub_length_bynumber(::Type{T}, match_data, num) where {T<:CodeUnitTypes}
    s = RefValue{Csize_t}()
    rc = substring_length_bynumber(T, match_data, num, s)
    rc < 0 ? pcre_error(rc) : convert(Int, s[])
end

function sub_copy_bynumber(::Type{T}, match_data, num, buf, siz::Integer) where {T<:CodeUnitTypes}
    s = RefValue{Csize_t}(siz)
    rc = substring_copy_bynumber(T, match_data, num, buf, s)
    rc < 0 ? pcre_error(rc) : convert(Int, s[])
end

function capture_names(T, re)
    name_count = info(T, re, INFO_NAMECOUNT, UInt32)
    name_entry_size = info(T, re, INFO_NAMEENTRYSIZE, UInt32)
    nametable_ptr = info(T, re, INFO_NAMETABLE, Ptr{UInt8})
    names = Dict{Int, String}()
    for i=1:name_count
        offset = (i-1)*name_entry_size + 1
        # The capture group index corresponding to name 'i' is stored as a
        # big-endian 16-bit value.
        high_byte = UInt16(unsafe_load(nametable_ptr, offset))
        low_byte = UInt16(unsafe_load(nametable_ptr, offset+1))
        idx = (high_byte << 8) | low_byte
        # The capture group name is a null-terminated string located directly
        # after the index.
        names[idx] = unsafe_string(nametable_ptr+offset+1)
    end
    names
end

end # module
