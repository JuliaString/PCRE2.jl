# PCRE2

[pkg-url]: https://github.com/JuliaString/PCRE2.jl.git

[julia-url]:    https://github.com/JuliaLang/Julia
[julia-release]:https://img.shields.io/github/release/JuliaLang/julia.svg

[release]:      https://img.shields.io/github/release/JuliaString/PCRE2.jl.svg
[release-date]: https://img.shields.io/github/release-date/JuliaString/PCRE2.jl.svg

[license-img]:  http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat
[license-url]:  LICENSE.md

[gitter-img]:   https://badges.gitter.im/Join%20Chat.svg
[gitter-url]:   https://gitter.im/JuliaString/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge

[travis-url]:   https://travis-ci.org/JuliaString/PCRE2.jl
[travis-s-img]: https://travis-ci.org/JuliaString/PCRE2.jl.svg
[travis-m-img]: https://travis-ci.org/JuliaString/PCRE2.jl.svg?branch=master

[codecov-url]:  https://codecov.io/gh/JuliaString/PCRE2.jl
[codecov-img]:  https://codecov.io/gh/JuliaString/PCRE2.jl/branch/master/graph/badge.svg

[contrib]:    https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat

[![][release]][pkg-url] [![][release-date]][pkg-url] [![][license-img]][license-url] [![contributions welcome][contrib]](https://github.com/JuliaString/PCRE2.jl/issues)

| **Julia Version** | **Unit Tests** | **Coverage** |
|:------------------:|:------------------:|:---------------------:|
| [![][julia-release]][julia-url] | [![][travis-s-img]][travis-url] | [![][codecov-img]][codecov-url]
| Julia Latest | [![][travis-m-img]][travis-url] | [![][codecov-img]][codecov-url]

The `PCRE2` package implements a low-level API for accessing the PCRE libraries (8, 16, and 32-bit)
It is intended to replace `Base.PCRE`, which is not threadsafe, only supports UTF-8, and is using an old version of the PCRE library (10.30, current version is 10.31)
