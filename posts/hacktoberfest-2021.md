@def title = "October, or “That Time of the Year When I Think A Lot About Structured Matrices in Julia”"
@def date = "10/31/2021"
@def tags = ["julia"]

# October, or “That Time of the Year When I Think A Lot About Structured Matrices in Julia”

I have participated in [Hacktoberfest](https://hacktoberfest.digitalocean.com/) every year since 2016. Nearly every PR I have done for it has been related to Julia, and [nearly](https://github.com/JuliaLang/julia/pull/29671) [all](https://github.com/JuliaLang/julia/pull/29777) [of](https://github.com/JuliaLang/julia/pull/29780) [those](https://github.com/JuliaLang/julia/pull/37825) [have](https://github.com/JuliaLang/julia/pull/37983) [been](https://github.com/JuliaLang/julia/pull/42466) [related](https://github.com/JuliaLang/julia/pull/42472) [to](https://github.com/JuliaLang/julia/pull/42574) [structured](https://github.com/JuliaLang/julia/pull/42577) [matrices](https://github.com/JuliaLang/julia/pull/42669) -- [matrix types](https://docs.julialang.org/en/v1/stdlib/LinearAlgebra/#Special-matrices), like `Diagonal` and `SymTridiagonal`, that succinctly encode sparse matrices with particular [band structures](https://en.wikipedia.org/wiki/Band_matrix). Most operations on these matrix types can be done pretty quickly compared to dense or even just sparse, but unstructured matrices.

For example, `Tridiagonal` matrices are [implemented](https://github.com/JuliaLang/julia/blob/ae8452a9e0b973991c30f27beb2201db1b0ea0d3/stdlib/LinearAlgebra/src/tridiag.jl#L470) as just 3 vectors, one of length `n` and the other two of length `n-1`, describing the main and off-diagonals, respectively. All other elements in the matrix are zero, so they don't need to be stored explicitly. When adding a `Tridiagonal` matrix to another matrix, only these `3n-2` elements need to be touched, so the sum can be done faster than if nothing was known about the operands.

My first [really big foray](https://github.com/JuliaLang/julia/pull/28883) into this space was to optimize addition and multiplication when both operands were structured. Many of these methods were too conservative in their return types, returning dense or `SparseMatrixCSC` (the generic sparse matrix format), when a more appropriate return type was available, or they used generic fall back methods when fast specalized methods were possible. The findings are summarized in [this table](https://github.com/JuliaLang/julia/pull/28883#issue-353888643) describing all of the expected and actual return types. There were a few substantial speedups. For example, multiplying a lower and upper bidiagonal matrix was returning a dense array when a `Tridiagonal` was always sufficient. Specializing this method and using the correct output type resulted in a ~99% decrease in runtime.

I found a few small bugs this year, again related to structured matrices. I even [joked](https://www.youtube.com/watch?v=45SG2N6MMcg) to my friend that "In my October, it's structured matrices. All structured matrices, all the time. No exceptions."  I mostly find these just by playing with randomly constructed structured matrix types and seeing when things are kind of slow or don’t match the output when the same operations are done but using dense representations. Basically, I am just fuzzing the `LinearAlgebra` standard library by hand.

### [[1]](https://github.com/JuliaLang/julia/pull/42472) An edge case in `SymTridiagonal` that caused some methods to fail silently (or crash totally unexpectedly).

`SymTridiagonal` has a not-well-documented detail where the off-diagonal (`S.ev`) can have the same number of elements as the main diagonal (`S.dv`). I was told once that this was to aid in some linear algebra solvers, but I can’t find any instances of it being used in the standard library like that to link here. 

Anyway, this leads to some subtle bugs when there is an extra element, as that element often gets included when broadcasting functions over the off-diagonal:

```julia-repl
# ev is the same length as dv
julia> dv = rand(3); ev = zeros(3)

# Explicitly set the hidden element to 1
julia> ev[end] = 1;

# 1 doesn't show up in the matrix, but it is stored in S.ev
julia> S = SymTridiagonal(dv, ev)
3×3 SymTridiagonal{Float64, Vector{Float64}}:
 0.267635  0.0        ⋅ 
 0.0       0.241045  0.0
  ⋅        0.0       0.348539

# Silently fails on a diagonal matrix
julia> isdiag(S)
false
```

The presence of the extra element can also cause an error to be thrown:

```julia-repl
# A 3x3 matrix without the additional off-diagonal element
julia> S = SymTridiagonal(rand(3), rand(2))

# A 3x3 matrix with the additional off-diagonal element
julia> T = SymTridiagonal(rand(3), rand(3))

# This should work, but it crashes
julia> S + T
ERROR: DimensionMismatch("dimensions must match: a has dims (Base.OneTo(2),), b has dims (Base.OneTo(3),), mismatch at 1")
```

These errors were resolved by replacing instances where broadcasts over `S.ev` were being done with a broadcast over a view of just the first `n-1` elements.

[A related issue](https://github.com/JuliaLang/julia/issues/42477), regarding `triu!`, `tril!`, and `Tridiagonal(::SymTridiagonal)`, was discovered while fixing this issue, but it has not yet been resolved.

### [[2]](https://github.com/JuliaLang/julia/pull/42574) An edge case when constructing a `SparseMatrixCSC` from empty `Tridiagonal` or `SymTridiagonal` matrices.

This seems to just have been missed by accident, which is easily relatable. The Julia core developers have bigger fish to fry than the obscure case of trying to make an empty sparse matrix from another empty structured matrix.

```julia-repl
julia> sparse(Diagonal(zeros(0, 0)))
0×0 SparseMatrixCSC{Float64, Int64} with 0 stored entries

julia> sparse(Bidiagonal(zeros(0, 0), :U))
0×0 SparseMatrixCSC{Float64, Int64} with 0 stored entries

julia> sparse(Tridiagonal(zeros(0, 0)))
ERROR: ArgumentError: invalid Array dimensions

julia> sparse(SymTridiagonal(zeros(0, 0)))
ERROR: ArgumentError: invalid Array dimensions
```

### [[3]](https://github.com/JuliaLang/julia/pull/42466) Inconsistent validation of `uplo` .

There are two flavors of upper/lower structured matrices in Julia: those that have orientation encoded into the type (e.g. `UpperTriagular` vs `LowerTriangular`), and those that have it encoded as an `uplo` member (e.g. `Bidiagonal` and `Symmetric`). In the latter, `:U` or `‘U’` maps to upper and `:L` or `‘L’` to lower. However, most orientation checks were just:

```julia-repl
if B.uplo == :U
    ...
else
    ...
end
```

including in the constructor:

```julia-repl
julia> Bidiagonal(rand(2), rand(1), 'U')
2×2 Bidiagonal{Float64,Array{Float64,1}}:
 0.792414  0.848267
  ⋅        0.0463521

julia> Bidiagonal(rand(2), rand(1), 'X')
2×2 Bidiagonal{Float64,Array{Float64,1}}:
 0.916971   ⋅ 
 0.0       0.27176

# the uplo::Symbol case is handled properly
julia> Bidiagonal(rand(2), rand(1), :X)
ERROR: ArgumentError: uplo argument must be either :U (upper) or :L (lower)
```

This allows for some silent failures. Here is one that I discovered after the PR was merged (the PR fixes this case also, thankfully):

```julia-repl
julia> x = rand(3); y = rand(2)
2-element Vector{Float64}:
 0.22212153279202784
 0.5045031681116003

# printing is wrong due to `getindex`
julia> b = Bidiagonal(x, y, 'X')
3×3 Bidiagonal{Float64, Vector{Float64}}:
 0.0401843   ⋅         ⋅ 
 0.0        0.490734   ⋅ 
  ⋅         0.0       0.905297

julia> b[1, 2]
0.0

julia> b.ev[2]
0.5045031681116003
```

The above is possible due to `getindex` having a check for `U` *and* `L`:

```julia
function getindex(A::Bidiagonal{T}, i::Integer, j::Integer) where T
    if !((1 <= i <= size(A,2)) && (1 <= j <= size(A,2)))
        throw(BoundsError(A,(i,j)))
    end
    if i == j
        return A.dv[i]
    elseif A.uplo == 'U' && (i == j - 1)
        return A.ev[i]
    elseif A.uplo == 'L' && (i == j + 1)
        return A.ev[j]
    else
        return zero(T)
    end
end
```

Since our example fails the first three conditionals (`i != j` and `X != U/L`), `zero(T)` is returned, regardless of what is actually at that index in the matrix.

### [[3.1]](https://github.com/JuliaLang/julia/pull/42467) Can’t win ‘em all: a rejected PR to add more `uplo` constructors.

When testing these matrix types, I like to just use the dense matrix constructors like `Bidiagonal(::Matrix)`, where I can pass in a matrix, and the structured matrix type automatically extracts only the relevant elements. It makes testing quicker, as I don’t need to make the correct sized vectors all the time.

For example:

```julia-repl
julia> Tridiagonal(rand(3, 3))
3×3 Tridiagonal{Float64, Vector{Float64}}:
 0.61729   0.738113   ⋅ 
 0.358494  0.997877  0.441913
  ⋅        0.640765  0.474584
```

It turns out that this worked for `uplo`-matrices in some cases, but not others:

```julia-repl
# uplo::Symbol works for both matrix and vector input cases
julia> Bidiagonal(rand(3, 3), :U)
3×3 Bidiagonal{Float64,Array{Float64,1}}:
 0.971135  0.423251   ⋅ 
  ⋅        0.528393  0.696667
  ⋅         ⋅        0.343728

julia> Bidiagonal(rand(4), rand(3), :U)
4×4 Bidiagonal{Float64, Vector{Float64}}:
 0.890622  0.275298   ⋅          ⋅ 
  ⋅        0.410022  0.861401    ⋅ 
  ⋅         ⋅        0.0611919  0.255028
  ⋅         ⋅         ⋅         0.337122

# uplo::Char fails for the matrix input case
julia> Bidiagonal(rand(3, 3), 'U')
ERROR: MethodError: no method matching Bidiagonal(::Array{Float64,2}, ::Char)

# uplo::Char works for the vector input case
julia> Bidiagonal(rand(4), rand(3), 'U')
4×4 Bidiagonal{Float64, Vector{Float64}}:
 0.947027  0.983474   ⋅         ⋅ 
  ⋅        0.563658  0.490839   ⋅ 
  ⋅         ⋅        0.612506  0.666592
  ⋅         ⋅         ⋅        0.551945
```

I figured that this was just a missed case, and that the `uplo::Char` constructors should work wherever the `uplo::Symbol` constructors worked. Turns out, [this was wrong](https://github.com/JuliaLang/julia/pull/42467#issuecomment-935623412), and the `uplo::Char` representation is only intended to be used internally, so this PR is an undesired change.

### [[4]](https://github.com/JuliaLang/julia/pull/42577) Making `SparseMatrixCSC` sparser when coming from structured matrices.

Generic sparse matrices typically don’t store `zero` values when being constructed from another matrix. For example:

```julia-repl
julia> S = sprand(3, 3, .2)
3×3 SparseMatrixCSC{Float64, Int64} with 1 stored entry:
  ⋅         ⋅    ⋅ 
  ⋅         ⋅    ⋅ 
 0.266854   ⋅    ⋅ 

julia> M = Matrix(s)
3×3 Matrix{Float64}:
 0.0       0.0  0.0
 0.0       0.0  0.0
 0.266854  0.0  0.0

julia> Sp = sparse(m)
3×3 SparseMatrixCSC{Float64, Int64} with 1 stored entry:
  ⋅         ⋅    ⋅ 
  ⋅         ⋅    ⋅ 
 0.266854   ⋅    ⋅ 

julia> Sp.nzval
1-element Vector{Float64}:
 0.2668541798981767
```

However, structured matrices are just copied directly from their storage, including zeros:

```julia-repl
julia> T = Tridiagonal(zeros(2), rand(3), zeros(2))
3×3 Tridiagonal{Float64, Vector{Float64}}:
 0.872128  0.0        ⋅ 
 0.0       0.714059  0.0
  ⋅        0.0       0.529289

julia> S = sparse(T)
3×3 SparseMatrixCSC{Float64, Int64} with 7 stored entries:
 0.872128  0.0        ⋅ 
 0.0       0.714059  0.0
  ⋅        0.0       0.529289

julia> S.nzval
7-element Vector{Float64}:
 0.8721278130717491
 0.0
 0.0
 0.7140591423154512
 0.0
 0.0
 0.5292893814821844
```

The zeros can be dropped (`dropzeros!`) afterwards, but it seems better to just avoid allocating them at all.

I implemented this only for the `Diagonal` type, to get more comfortable with the `SparseMatrixCSC` [format](https://en.wikipedia.org/wiki/Sparse_matrix#Compressed_sparse_row_(CSR,_CRS_or_Yale_format)) (a post about this is in the draft stage), and to make sure that this was a wanted change before diving in to the other structured matrix types. `Diagonal` has a very amenable structure for quickly constructing a `SparseMatrixCSC` without allocating zeros, as there can be at most one non-zero value in each column, so the column pointers and row values can be easily computed.

On extremely sparse matrices, avoiding the diagonal zeros provided a reasonable speed up, since fewer allocations needed to take place. On medium sparse matrices, there is a regression, likely due to missed branch predictions when guessing if the next element on the diagonal would be zero or not. On very dense diagonals, the performance was about the same as before. So, overall, this seems like a win.

There are a few areas that this can be improved. One issue is that the constructor now loops over the diagonal twice, once to count the number of non-zeros and allocate the correct amount of storage in the sparse matrix, and a second time to fill in the correct values. It isn’t clear if this is any better than just looping over the diagonal once and resizing the sparse matrix storage arrays as necessary.

###  [[5]](https://github.com/JuliaLang/julia/pull/42549) and [[6]](https://github.com/JuliaLang/julia/pull/42669): `zero != 0`.

An assumption that is being slowly removed from the code base is that structured and sparse matrix types will always have `eltypes` that are comparable to a literal `0`, and which can be constructed by calling `convert(T, 0)`. [This isn’t always the case](https://github.com/JuliaLang/julia/issues/42536), and [several](https://github.com/JuliaLang/julia/issues/30573) [discussions](https://discourse.julialang.org/t/is-there-a-defined-minimal-interface-for-a-type-to-work-with-sparsearrays/69602/3) about how to address this have come up. One great thing about Julia is how composable it is, if you use sufficiently generic code. In the linear algebra library, it is likely that someone will want to use a custom numeric type (that doesn’t have the aforementioned properties), and will expect the code to work as is. When using an unusual “number-like” type, things might fail if there is no valid way to compare directly with `0`. 

One easy way to make the code more generic is to use `zero(T)` instead of a literal `0`  and `iszero` instead of `== 0`.

I found two instances where the more generic code could be used, one in `findnz` for `SparseMatrixCSC`, and the other in `triu!`/`tril!` for `Diagonal`, `Bidiagonal`, `Tridiagonal`, and `SymTridiagonal`. The first was comparing to a literal `0` and the second was filling the structured matrices with literal `0`. If an `eltype` that either couldn’t be compared to `0` or that couldn’t do `convert(T, 0)` was used in these methods, they would have failed.