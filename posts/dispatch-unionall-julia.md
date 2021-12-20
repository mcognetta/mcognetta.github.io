@def title = "Dispatching on Types with the Same UnionAll (but You Don’t Know the Type Beforehand)"
@def tags = ["julia"]
@def date = "09/01/2019"
@def hascode = true

@def rss_description = "A post about efficiently dispatching on types that are in the same UnionAll, but are possibly different concrete types (for example, A{T} and A{S}) in Julia."
@def rss_pubdate = Date(2019, 09, 01)

# Dispatching on Types with the Same UnionAll (but You Don’t Know the Type Beforehand)

A gist with the code in this post can be found [here](https://gist.github.com/mcognetta/a468889c2ea53b49d080c6d764f3b6da). 

When planning a small library in Julia, I kept running into a similar problem across all of the type systems that I tried when looking for the proper abstraction. Briefly, I had a single parametric abstract type at the top of an arbitrary type hierarchy (with any number of abstract and concrete types below it, possibly added later by a user) and I needed to write a function that would only work on objects with the same UnionAll[^1] types within the hierarchy. Furthermore, I wanted this to be automatic for all of the types in the hierarchy without the user having to write any code.

Here is a basic example. Suppose I have the types:

```julia
abstract type A{T} end
struct B{T} <: A{T} end
struct C{T} <: A{T} end
abstract type D{T} <: A{T} end
struct E{T} <: D{T} end
struct F{T} <: D{T} end
```
Here, `D`, `E`, and `F` are included to demonstrate that the type hierarchy can be arbitrarily complex and extended at any time by the user.

I want to define a function `f(x, y)` that does something when `x` and `y` come from the same UnionAll type, even if they are parameterized differently, and fails otherwise. For example:
```julia
x = B{Int64}()
y = B{Float32}()
z = C{Int64}()

f(x, y) # -> does something
f(x, z) # -> fails
f(y, z) # -> fails
```

A simple solution to this is to just require the user to implement `f` for their new types while providing a fall back `f(::A, ::A)` that fails. However, the library that I am writing has a very natural interface and adding more to it would have been undesirable. Also, this struck me as something that *should* be possible programmatically.

My first attempt to do it programmatically lead to method signatures similar to (the invalid code):

```julia
f(::X, ::Y) where {T, S, U<:A, X<:U{T}, Y<:U{S}} = ...
```

I was then pointed (by a JuliaLang member on Slack, though I can't remember who) to a partial solution of determining if two objects had the same UnionAll type:
```julia
sameunionall(::X, ::Y) where {X<:A, Y<:A} = !isabstracttype(typejoin(X, Y))
```
This can be rewritten for types as:
```julia
sameunionall(::Type{X}, ::Type{Y}) where {X<:A, Y<:A} = !isabstracttype(typejoin(X, Y))
```

Combining this with 'Holy-Traits' [^2] via [SimpleTraits.jl](https://github.com/mauro3/SimpleTraits.jl) leads to a nice solution:
```julia
using SimpleTraits
@traitdef SameUnionAll{X, Y}
@traitimpl SameUnionAll{X, Y} <- sameunionall(X, Y)
@traitfn f(::X, ::Y) where {X<:A, Y<:A; SameUnionAll{X, Y}} = "yo"
@traitfn f(::X, ::Y) where {X<:A, Y<:A; !SameUnionAll{X, Y}} = "nah"
```
This can be tested out:
```julia
x = B{Int64}()
y = B{Float32}()
z = C{Int64}()
f(x, y) # -> "yo"
f(x, z) # -> "nah"
f(y, z) # -> "nah"

# added later by a user
struct G{T} <: D{T} end
f(G{Int16}(), x) # -> "nah"
f(G{Int16}(), G{BigFloat}()) # -> "yo"
```

One important note is that `sameunionall` is a pure method so `f` does not fall back to dynamic dispatch. This can be verified by checking:
```julia
julia> @code_warntype f(x, y)
Body::String
1 ─     return "yo"

julia> @code_warntype f(x, z)
Body::String
1 ─     return "nah"
```

This trick will be expanded on in a future post, but to whet the appetite I will briefly introduce the exact use case that I have. Suppose I have the following structure, where more "special algebra" types can be added at will by the user:
```julia
abstract type AbstractAlgebraElement{T} end
struct SpecialAlgebraElement{T<:Real} <: AbstractAlgebraElement{T} end
struct DifferentAlgebraElement{T<:Number} <: AbstractAlgebraElement{T} end
```

Objects of the same algebraic type but with different parameters should be compatible (for example, a ring of real numbers represented by `Float32` vs one represented by `Float64` are essentially the same thing here). As such, we should be able to promote between them so that this should work:
```julia
promote_type(SpecialAlgebraElement{Float64}, SpecialAlgebraElement{Float16}) # -> SpecialAlgebraElement{Float64}
```
but this should fail:
```julia
promote_type(SpecialAlgebraElement{Float64}, DifferentAlgebraElement{Float16})
```

As a final note, more idiomatic Julia code, comments, criticisms, etc. are always welcome. Please feel free to email me.

[^1]: [https://docs.julialang.org/en/v1/manual/types/index.html#UnionAll-Types-1](https://docs.julialang.org/en/v1/manual/types/index.html#UnionAll-Types-1)
[^2]: [https://github.com/JuliaLang/julia/issues/2345#issuecomment-54537633](https://github.com/JuliaLang/julia/issues/2345#issuecomment-54537633)