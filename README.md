# PCRE2

[![Build Status](https://travis-ci.org/JuliaString/PCRE2.jl.svg?branch=master)](https://travis-ci.org/JuliaString/PCRE2.jl)

[![Coverage Status](https://coveralls.io/repos/JuliaString/PCRE2.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/JuliaString/PCRE2.jl?branch=master)

[![codecov.io](http://codecov.io/github/JuliaString/PCRE2.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaString/PCRE2.jl?branch=master)

The `PCRE2` package implements a low-level API for accessing the PCRE libraries (8, 16, and 32-bit)
It is intended to replace `Base.PCRE`, which is not threadsafe, only supports UTF-8, and is using an old version of the PCRE library (10.30, current version is 10.31)

It is working on both the release version (v0.6.2) and the latest master (v0.7.0-DEV).
