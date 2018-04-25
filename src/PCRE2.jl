#=
Low-level wrapper for PCRE2 library

Copyright 2018 Gandalf Software, Inc., Scott P. Jones, and other contributors to the Julia language
Licensed under MIT License, see LICENSE.md
Based in part on julia/base/pcre.jl
Also uses julia/base/pcre_h.jl
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
else
    import Base.GC: @preserve
    ev(s) = eval(Meta.parse(s))
end

import Base: RefValue

include("pcre_h.jl")

const PCRE_LIB_8  = "libpcre2-8"
const PCRE_LIB_16 = "libpcre2-16"
const PCRE_LIB_32 = "libpcre2-32"

const UNSET = ~Csize_t(0)  # Indicates that an output vector element is unset

const VoidP = Ptr{Cvoid}

for siz in (8,16,32)
    typ = "(::Type{UInt$siz}, "
    lib = "PCRE_LIB_$siz"
    args = "a,b,c,d,e,f,g"
    for (nam, ret, sig) in
        ((:jit_stack_create,     VoidP, (Cint, Cint, VoidP)),
         (:match_context_create, VoidP, (VoidP,)),
         (:jit_stack_assign,     Cvoid, (VoidP, VoidP, VoidP)),
         (:pattern_info,         Int32, (VoidP, Int32, VoidP)),
         (:ovector_pointer,      Ptr{Csize_t}, (VoidP,)),
         (:get_ovector_count,    UInt32, (VoidP,)),
         (:compile,              VoidP, (VoidP, Csize_t, UInt32, Ref{Cint}, Ref{Csize_t}, VoidP)),
         (:jit_compile,          Cint, (VoidP, UInt32)),
         (:get_error_message,    Cvoid, (Int32, VoidP, Csize_t)),
         (:match_data_free,      Cvoid, (VoidP,)),
         (:code_free,            Cvoid, (VoidP,)),
         (:jit_stack_free,       Cvoid, (VoidP,)),
         (:match_context_free,   Cvoid, (VoidP,)),
         (:match,                Cint, (VoidP, VoidP, Csize_t, Csize_t, Cuint, VoidP, VoidP)),
         (:match_data_create_from_pattern, VoidP, (VoidP, VoidP)),
         (:substring_number_from_name,     Cint, (VoidP, Cstring)),
         (:substring_length_bynumber,      Cint, (VoidP, UInt32, Ref{Csize_t})),
         (:substring_copy_bynumber,        Cint, (VoidP, UInt32, VoidP, Ref{Csize_t})))
        l = SubString("a,b,c,d,e,f,g", 1, length(sig)*2-1)
        s = "$nam$typ$l) = ccall((:pcre2_$(nam)_$siz, $lib), $ret, $sig, $l)"
        println(s)
        ev(s)
    end
end

function info(::Type{T}, regex::Ptr{Cvoid}, what::Integer, ::Type{S}) where {S,T<:CodeUnitTypes}
    buf = RefValue{S}()
    ret = pattern_info(T, regex, what, buf)
    if ret != 0
        error(ret == ERROR_NULL      ? "NULL regex object" :
              ret == ERROR_BADMAGIC  ? "invalid regex object" :
              ret == ERROR_BADOPTION ? "invalid option flags" :
                                       "unknown error $ret")
    end
    buf[]
end

get_ovec(::Type{T}, match_data) where {T<:CodeUnitTypes} =
    unsafe_wrap(Array,
                get_ovector_pointer(T, match_data),
                2 * get_ovector_count(T, match_data),
                own = false)

function compile(pattern::T, options::Integer) where {T<:AbstractString}
    errno = RefValue{Cint}(0)
    erroff = RefValue{Csize_t}(0)
    re_ptr = compile(codeunit(T), pattern, ncodeunits(pattern), options, errno, erroff, C_NULL)
    re_ptr == C_NULL &&
        error("PCRE2 compilation error: $(err_message(errno[])) at offset $(erroff[])")
    re_ptr
end

jit_compile(::Type{T}, regex::Ptr{Cvoid}) where {T<:CodeUnitTypes} =
    ((errno = jit_compile(T, regex, JIT_COMPLETE)) == 0 ||
     error("PCRE2 JIT error: $(err_message(errno))") ; nothing)

function err_message(errno)
    buffer = Vector{UInt8}(undef, 256)
    get_error_message(UInt8, errno, buffer)
    @preserve buffer unsafe_string(pointer(buffer))
end

function substring_length_bynumber(::Type{T}, match_data, num) where {T<:CodeUnitTypes}
    s = RefValue{Csize_t}()
    rc = substring_length_bynumber(T, match_data, num, s)
    rc < 0 && error("PCRE2 error: $(err_message(rc))")
    convert(Int, s[])
end

function substring_copy_bynumber(::Type{T}, match_data, num, buf,
                                 siz::Integer) where {T<:CodeUnitTypes}
    s = RefValue{Csize_t}(siz)
    rc = substring_copy_bynumber(T, match_data, num, buf, s)
    rc < 0 && error("PCRE2 error: $(err_message(rc))")
    convert(Int, s[])
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
