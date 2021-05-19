# PCRE2

[pkg-url]: https://github.com/JuliaString/PCRE2.jl.git

[julia-url]:    https://github.com/JuliaLang/Julia
[julia-release]:https://img.shields.io/github/release/JuliaLang/julia.svg

[release]:      https://img.shields.io/github/release/JuliaString/PCRE2.jl.svg
[release-date]: https://img.shields.io/github/release-date/JuliaString/PCRE2.jl.svg
[checks]:       https://img.shields.io/github/checks-status/JuliaString/PCRE2.jl/master

[license-img]:  http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat
[license-url]:  LICENSE.md

[gitter-img]:   https://badges.gitter.im/Join%20Chat.svg
[gitter-url]:   https://gitter.im/JuliaString/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge

[codecov-url]:  https://codecov.io/gh/JuliaString/PCRE2.jl
[codecov-img]:  https://codecov.io/gh/JuliaString/PCRE2.jl/branch/master/graph/badge.svg

[contrib]:    https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat

[![][release]][pkg-url] [![][release-date]][pkg-url] [![][checks]][pkg-url] [![][codecov-img]][codecov-url] [![][license-img]][license-url] [![contributions welcome][contrib]](https://github.com/JuliaString/PCRE2.jl/issues)

The `PCRE2` package implements a low-level API for accessing the PCRE libraries (8, 16, and 32-bit)
It was intended to replace `Base.PCRE` which was not threadsafe, as well as missing non-UTF-8 support.

`Base.PCRE` still only supports UTF-8, which is why this is needed for the Strs package.
It is my intention to change this to use the libraries now created by the BinaryBuilder.