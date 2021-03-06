"""
`PairwiseListMatrix{T, L, diagonal}` is a (squared) symmetric matrix that stores a `list` of values of type `T` for the pairwise comparison/evaluation of `nelements`.
If `diagonal` is `true` the first element of the list is `1, 1` otherwise is `1, 2`.
If `diagonal` is `false`, the diagonal values are stored in a vector on the `diag` field.
Labels can be stored on the field `labels` as an `IndexedArray`.
"""
type PairwiseListMatrix{T, L, diagonal} <: AbstractArray{T, 2}
  list::Vector{T}
  diag::Vector{T}
  labels::IndexedArray{L}
  nelements::Int
end

# Creation
# ========

function _test_nelements(vector, nelements::Int, name::ASCIIString)
  if length(vector) != 0 && length(vector) != nelements
    throw(DimensionMismatch(string(name, " must have ", nelements, " names!")))
  end
end

@inline _list_length(nelements) = @fastmath div(nelements*(nelements-1),2)
@inline _list_with_diagonal_length(nelements) = @fastmath div(nelements*(nelements+1),2)

# Empties
# -------

"""
An empty `PairwiseListMatrix` can be created for a given `Type` and a number of elements `elements`.
Optionally, you can use a vector or IndexedArray for declaring names/labels to each element.
The `diagonal` (default to `false`) could be declared as `true` in order to indicate that the list needs space for the diagonal elements.
If `diagonal` is `false`, the diagonal values are stored in a vector on the `diag` field instead of being on the list.
This vector can be filled to a value with the optional `diagonalvalue` arguments (default to `0`).
"""
function PairwiseListMatrix{T, L}(::Type{T}, nelements::Int, labels::IndexedArray{L},
                                  diagonal::Bool=false, diagonalvalue::T=zero(T))
  _test_nelements(labels, nelements, "labels")
  if diagonal
    return PairwiseListMatrix{T, L, diagonal}(Array(T, _list_with_diagonal_length(nelements)), T[], labels, nelements)
  else
    return PairwiseListMatrix{T, L, diagonal}(Array(T, _list_length(nelements)), fill!(Array(T, nelements), diagonalvalue), labels, nelements)
  end
end

PairwiseListMatrix{T, L}(::Type{T}, nelements::Int, labels::AbstractVector{L}, diagonal::Bool=false,
                         diagonalvalue::T=zero(T)) = PairwiseListMatrix(T, nelements, IndexedArray(labels), diagonal, diagonalvalue)

PairwiseListMatrix{T}(::Type{T}, nelements::Int, diagonal::Bool=false,
                      diagonalvalue::T=zero(T)) = PairwiseListMatrix(T, nelements, IndexedArray{Any}(), diagonal, diagonalvalue)

# From a list
# -----------

@inline _nelements(len::Int) = @fastmath div(1+Int(sqrt(1+8*len)),2)
@inline _nelements_with_diagonal(len::Int) = @fastmath div(Int(sqrt(1+8*len)-1),2)

"""
A `PairwiseListMatrix` can be from a `list`. Optionally, you can use a vector or IndexedArray for declaring `labels` to each element.
The `diagonal` (default to `false`) could be declared as `true` in order to indicate that the list has the diagonal elements.
If `diagonal` is `false`, the diagonal values are stored in a vector on the `diag` field instead of being on the list.
This vector can be filled to a value with the optional `diagonalvalue` arguments (default to `0`).
"""
function PairwiseListMatrix{T, L}(list::AbstractVector{T}, labels::IndexedArray{L},
                                  diagonal::Bool=false, diagonalvalue::T=zero(T))
  if diagonal
    nelements = _nelements_with_diagonal(length(list))
    _test_nelements(labels, nelements, "labels")
    return PairwiseListMatrix{T, L, diagonal}(list, T[], labels, nelements)
  else
    nelements = _nelements(length(list))
    _test_nelements(labels, nelements, "labels")
    return PairwiseListMatrix{T, L, diagonal}(list, fill!(Array(T, nelements), diagonalvalue), labels, nelements)
  end
end

PairwiseListMatrix{T, L}(list::AbstractVector{T}, labels::AbstractVector{L}, diagonal::Bool=false,
                         diagonalvalue::T=zero(T)) = PairwiseListMatrix(list, IndexedArray(labels), diagonal, diagonalvalue)

PairwiseListMatrix{T}(list::AbstractVector{T}, diagonal::Bool=false,
                      diagonalvalue::T=zero(T)) = PairwiseListMatrix(list, IndexedArray{Any}(), diagonal, diagonalvalue)


# AbstractArray methods
# =====================

size(m::PairwiseListMatrix) = (m.nelements, m.nelements)
length(m::PairwiseListMatrix) = m.nelements * m.nelements

eltype{T, L, diagonal}(m::PairwiseListMatrix{T, L, diagonal}) = T

similar{T, L, diagonal}(m::PairwiseListMatrix{T, L, diagonal}) = PairwiseListMatrix{T, L, diagonal}(similar(m.list), copy(m.diag),
                                                                                                    copy(m.labels), copy(m.nelements))
similar{T, L, diagonal, S}(m::PairwiseListMatrix{T, L, diagonal}, ::Type{S}) = PairwiseListMatrix{S, L, diagonal}(similar(m.list, S), convert(Vector{S}, m.diag),
                                                                                                                  copy(m.labels), S(copy(m.nelements)))

copy{T, L, diagonal}(m::PairwiseListMatrix{T, L, diagonal}) = PairwiseListMatrix{T, L, diagonal}(copy(m.list), copy(m.diag), copy(m.labels), copy(m.nelements))

zeros{T, L, diagonal}(m::PairwiseListMatrix{T, L, diagonal}) = PairwiseListMatrix{T, L, diagonal}(zeros(m.list), zeros(m.diag), copy(m.labels), copy(m.nelements))
ones{T, L, diagonal}(m::PairwiseListMatrix{T, L, diagonal})  = PairwiseListMatrix{T, L, diagonal}(ones(m.list),  ones(m.diag),  copy(m.labels), copy(m.nelements))

# Indexing (getindex)
# ===================

@inline _listindex(i, j, n) = @fastmath div((n*(n-1))-((n-i)*(n-i-1)),2) - n + j
@inline _listindex_with_diagonal(i, j, n) = @fastmath div((n*(n+1))-((n-i)*(n-i+1)),2) - n + j

function getindex{T, L}(lm::PairwiseListMatrix{T, L, true}, i::Int, j::Int)
  if i <= j
    return(lm.list[_listindex_with_diagonal(i, j, lm.nelements)])
  else
    return(lm.list[_listindex_with_diagonal(j, i, lm.nelements)])
  end
end

function getindex{T, L}(lm::PairwiseListMatrix{T, L, false}, i::Int, j::Int)
  if i < j
    return(lm.list[_listindex(i, j, lm.nelements)])
  elseif i > j
    return(lm.list[_listindex(j, i, lm.nelements)])
  else
    return(lm.diag[i])
  end
end

# i, n -> row: ceil(i/n) col: rem(i-1, n)+1
# i, n -> row: ceil(i/n) col: i - n*(ceil(i/n)-1)

Base.linearindexing(m::PairwiseListMatrix) = Base.LinearFast()

function getindex{T, L}(lm::PairwiseListMatrix{T, L, true}, i::Int)
  n = lm.nelements
  row = Int(ceil(i/n))
  col = i - n*(row-1)
  if row <= col
    @inbounds return lm.list[_listindex_with_diagonal(row, col, n)]
  else
    @inbounds return lm.list[_listindex_with_diagonal(col, row, n)]
  end
end

function getindex{T, L}(lm::PairwiseListMatrix{T, L, false}, i::Int)
  n = lm.nelements
  row = Int(ceil(i/n))
  col = i - n*(row-1)
  if row < col
    @inbounds return lm.list[_listindex(row, col, n)]
  elseif row > col
    @inbounds return lm.list[_listindex(col, row, n)]
  else
    @inbounds return lm.diag[row]
  end
end

# Labels
# ======

"Get the labels/names of the row/columns of the matrix"
labels(lm::PairwiseListMatrix) = lm.labels

"You can use labels for add labels/names to the row/columns of the matrix"
function labels!(lm::PairwiseListMatrix, labels::IndexedArray)
  _test_nelements(labels, lm.nelements, "labels")
  lm.labels = labels
end

labels!(lm::PairwiseListMatrix, labels::AbstractVector) = labels!(lm, IndexedArray(labels))

# Indexing using labels (getlabel)
# ================================

"Like `getindex`, but using the labels/names instead of `Int` numbers."
function getlabel(lm::PairwiseListMatrix, i, j)
  if isempty(lm.labels)
    throw(ErrorException("There are not labels in the matrix. You can use labels!(...) for add them."))
  else
    return getindex(lm, findfirst(lm.labels, i), findfirst(lm.labels, j))
  end
end

# Set values (setindex!)
# ======================

function setindex!{T, L}(lm::PairwiseListMatrix{T, L, true}, v, i::Int, j::Int)
  if i <= j
    return setindex!(lm.list, v, _listindex_with_diagonal(i, j, lm.nelements))
  else
    return setindex!(lm.list, v, _listindex_with_diagonal(j, i, lm.nelements))
  end
end

function setindex!{T, L}(lm::PairwiseListMatrix{T, L, false}, v, i::Int, j::Int)
  if i < j
    return setindex!(lm.list, v, _listindex(i, j, lm.nelements))
  elseif i > j
    return setindex!(lm.list, v, _listindex(j, i, lm.nelements))
  else
    return setindex!(lm.diag, v, i)
  end
end

function setindex!{T, L}(lm::PairwiseListMatrix{T, L, true}, v, i::Int)
  n = lm.nelements
  row = Int(ceil(i/n))
  col = i - n*(row-1)
  if row <= col
    return setindex!(lm.list, v, _listindex_with_diagonal(row, col, n))
  else
    return setindex!(lm.list, v, _listindex_with_diagonal(col, row, n))
  end
end

function setindex!{T, L}(lm::PairwiseListMatrix{T, L, false}, v, i::Int)
  n = lm.nelements
  row = Int(ceil(i/n))
  col = i - n*(row-1)
  if row < col
    return setindex!(lm.list, v, _listindex(row, col, n))
  elseif row > col
    return setindex!(lm.list, v, _listindex(col, row, n))
  else
    return setindex!(lm.diag, v, row)
  end
end

# Set values using labels (setlabel!)
# ===================================

"Like `setindex!`, but using the labels/names instead of `Int` numbers."
function setlabel!(lm::PairwiseListMatrix, v, i, j)
  if isempty(lm.labels)
    throw(ErrorException("There are not labels in the matrix. You can use labels!(...) for add them."))
  else
    return setindex!(lm, v, findfirst(lm.labels, i), findfirst(lm.labels, j))
  end
end

# Transpose
# =========

transpose(lm::PairwiseListMatrix) = lm
transpose!(lm::PairwiseListMatrix) = lm

ctranspose(lm::PairwiseListMatrix) = lm
ctranspose!(lm::PairwiseListMatrix) = lm

# diag and full
# =============

diag{T, L}(lm::PairwiseListMatrix{T, L, false}) = lm.diag

diag{T, L}(lm::PairwiseListMatrix{T, L, true}) = T[ lm[i,i] for i in 1:lm.nelements ]

# This is faster than list comprehension (2.4 x)
"Returns a full dense matrix"
function full{T, L}(lm::PairwiseListMatrix{T, L, true})
  N = lm.nelements
  complete = Array(T, N, N)
  list = lm.list
  k = 0
  for col in 1:N
    @inbounds for row in col:N
            complete[row, col] = complete[col, row] = list[k += 1]
    end
  end
  complete
end

function full{T, L}(lm::PairwiseListMatrix{T, L, false})
  N = lm.nelements
  complete = Array(T, N, N)
  list = lm.list
  diag = lm.diag
  k = 0
  l = 0
  for col in 1:(N-1)
    @inbounds for row in (col+1):N
      complete[row, col] = list[k += 1]
    end
    @inbounds for row in (col+1):N
      complete[col, row] = list[l += 1]
    end
  end
  @inbounds for i in 1:N
    complete[i, i] = diag[i]
  end
  complete
end

full{T, S <: PairwiseListMatrix}(m::Symmetric{T, S}) = full(m.data)

# Unary operations
# ================

for una in (:abs, :sqrt, :-)
  @eval begin
    $(una){T, L}(lm::PairwiseListMatrix{T, L, true}) = PairwiseListMatrix{T, L, true }($(una)(lm.list), lm.diag, lm.labels, lm.nelements)
    $(una){T, L}(lm::PairwiseListMatrix{T, L, false})= PairwiseListMatrix{T, L, false}($(una)(lm.list), $(una)(lm.diag), lm.labels, lm.nelements)
  end
end

svd(m::PairwiseListMatrix) = svd(full(m))

# Binary operations
# =================

for bin in ( :-, :+, :.*, :./, :.+, :.- )

  @eval begin

    function $(bin){T, L}(A::PairwiseListMatrix{T, L, true}, B::PairwiseListMatrix{T, L, true})
      if A.labels != B.labels || A.nelements != B.nelements
        return($(bin)(full(A), full(B)))
      end
      PairwiseListMatrix{T, L, true}($(bin)(A.list, B.list), copy(A.diag), copy(A.labels), copy(A.nelements))
    end

    function $(bin){T, L}(A::PairwiseListMatrix{T, L, false}, B::PairwiseListMatrix{T, L, false})
      if A.labels != B.labels || A.nelements != B.nelements
        return($(bin)(full(A), full(B)))
      end
      PairwiseListMatrix{T, L, false}($(bin)(A.list, B.list), $(bin)(A.diag, B.diag), copy(A.labels), copy(A.nelements))
    end

    $(bin)(A::PairwiseListMatrix, B::PairwiseListMatrix) = $(bin)(full(A), full(B))

  end

end

for bin in (:/, :./)

  @eval begin

	$(bin){T <: AbstractFloat, L}(A::PairwiseListMatrix{T, L, true},  B::T) = PairwiseListMatrix{T, L, true }($(bin)(A.list, B), copy(A.diag), copy(A.labels), copy(A.nelements))
	$(bin){T <: AbstractFloat, L}(A::PairwiseListMatrix{T, L, false}, B::T) = PairwiseListMatrix{T, L, false}($(bin)(A.list, B), $(bin)(A.diag, B), copy(A.labels), copy(A.nelements))

	$(bin){L}(A::PairwiseListMatrix{Int, L, true},  B::Integer) = PairwiseListMatrix{Float64, L, true }($(bin)(A.list, B), copy(A.diag), copy(A.labels), copy(A.nelements))
	$(bin){L}(A::PairwiseListMatrix{Int, L, false}, B::Integer) = PairwiseListMatrix{Float64, L, false}($(bin)(A.list, B), $(bin)(A.diag, B), copy(A.labels), copy(A.nelements))

  end

end

for bin in (:+, :-)
  @eval begin
    $(bin){L}(A::PairwiseListMatrix{Bool, L, true},  B::Bool) = PairwiseListMatrix{Int, L, true }($(bin)(A.list, B), copy(A.diag), copy(A.labels), copy(A.nelements))
    $(bin){L}(A::PairwiseListMatrix{Bool, L, false}, B::Bool) = PairwiseListMatrix{Int, L, false}($(bin)(A.list, B), $(bin)(A.diag, B), copy(A.labels), copy(A.nelements))
  end
end

for bin in (:.+, :.-, :.*, :-, :+)

  @eval begin

	$(bin){T <: Number, L}(A::PairwiseListMatrix{T, L, true},  B::T) = PairwiseListMatrix{T, L, true }($(bin)(A.list, B), copy(A.diag), copy(A.labels), copy(A.nelements))
	$(bin){T <: Number, L}(A::PairwiseListMatrix{T, L, false}, B::T) = PairwiseListMatrix{T, L, false}($(bin)(A.list, B), $(bin)(A.diag, B), copy(A.labels), copy(A.nelements))

  end

end

for bin in (:*, :/)

  @eval $(bin)(A::PairwiseListMatrix, B::PairwiseListMatrix) = $(bin)(full(A), full(B))

end

# Faster mean
# ===========

sum{T, L}(m::PairwiseListMatrix{T, L, false}) = 2*sum(m.list) + sum(m.diag)
sum{T, L}(m::PairwiseListMatrix{T, L, true}) =  2*sum(m.list) - sum(diag(m))

function _sum_kernel!(sum_i, list, N)
  k = 0
  l = 0
  for i in 1:N
    l += 1
    @inbounds @simd for j in i:N
      sum_i[i] += list[k += 1]
    end
    @inbounds for j in (i+1):N
      sum_i[j] += list[l += 1]
    end
  end
  sum_i
end

function _sum_kernel!(sum_i, diag, list, N)
  k = 0
  l = 0
  for i in 1:(N-1)
    @inbounds @simd for j in (i+1):N
      sum_i[i] += list[k += 1]
    end
    @inbounds for j in (i+1):N
      sum_i[j] += list[l += 1]
    end
  end
  @inbounds for i in 1:N
    sum_i[i] += diag[i]
  end
  sum_i
end

function _test_and_set_sum{T}(::Type{T}, region, N)
  if region == 1
    sum_i = zeros(T, 1, N)
  elseif region == 2
    sum_i = zeros(T, N, 1)
  else
    throw(ErrorException("region should be 1 or 2"))
  end
  sum_i
end

function sum{T, L}(lm::PairwiseListMatrix{T, L, true}, region::Int)
  N = lm.nelements
  sum_i = _test_and_set_sum(T, region, N)
  _sum_kernel!(sum_i, lm.list, N)
end

function sum{T, L}(lm::PairwiseListMatrix{T, L, false}, region::Int)
  N = lm.nelements
  sum_i = _test_and_set_sum(T, region, N)
  _sum_kernel!(sum_i, lm.diag, lm.list, N)
end

mean(m::PairwiseListMatrix) = sum(m)/length(m)
mean(m::PairwiseListMatrix, region::Int) = sum(m, region) ./ m.nelements

# Sum/Mean without diagonal: sum/mean_nodiag
# ------------------------------------------
"Sum the values outside the diagonal"
sum_nodiag{T, L}(m::PairwiseListMatrix{T, L, false}) = T(2) * sum(m.list)
sum_nodiag{T, L}(m::PairwiseListMatrix{T, L, true}) = T(2) * sum(m.list) - sum(diag(m))

function _sum_nodiag_kernel!{T, L}(sum_i, lm::PairwiseListMatrix{T, L, true}, N)
  list = lm.list
  k = 0
  for i in 1:N
    for j in i:N
      k += 1
      if i != j
        @inbounds value = list[k]
        @inbounds sum_i[i] += value
        @inbounds sum_i[j] += value
      end
    end
  end
  sum_i
end

function _sum_nodiag_kernel!{T, L}(sum_i, lm::PairwiseListMatrix{T, L, false}, N)
  list = lm.list
  k = 0
  l = 0
  for i in 1:(N-1)
    @inbounds @simd for j in (i+1):N
      sum_i[i] += list[k += 1]
    end
    @inbounds for j in (i+1):N
      sum_i[j] += list[l += 1]
    end
  end
  sum_i
end

function sum_nodiag{T, L, diagonal}(lm::PairwiseListMatrix{T, L, diagonal}, region::Int)
  N = lm.nelements
  sum_i = _test_and_set_sum(T, region, N)
  _sum_nodiag_kernel!(sum_i, lm, N)
end

"Mean of the values outside the diagonal"
mean_nodiag(m::PairwiseListMatrix) = sum_nodiag(m) / (length(m) - m.nelements)
mean_nodiag(m::PairwiseListMatrix, region::Int) = sum_nodiag(m, region) ./ (m.nelements-1)

# Operations on Vector{PairwiseListMatrix}
# ========================================

# Sum
# ---

@inline _has_diagonal{T, L, diagonal}(x::PairwiseListMatrix{T, L, diagonal}) = diagonal

function sum{T <: PairwiseListMatrix}(list::Vector{T})
  samples = length(list)
  if samples == 1
    return list[1]
  elseif samples == 0
    return zero(list[1])
  else
    start = copy(list[1])
    i = 2
    start_list = start.list
    N = length(start_list)
    i = 2
    while i <= samples
      @inbounds ylist = list[i].list
      if length(ylist) != N
        throw(ErrorException("Different number of elements"))
      end
      for k in 1:N
        @inbounds start_list[k] += ylist[k]
      end
      i += 1
    end
    if !_has_diagonal(start)
      i = 2
      start_diag = start.diag
      while i <= samples
        @inbounds ydiag = list[i].diag
        for k in 1:length(start_diag)
          @inbounds start_diag[k] += ydiag[k]
        end
        i += 1
      end
    end
    return start
  end
end

# std
# ---

function varm{T <: PairwiseListMatrix}(list::Vector{T}, mean::PairwiseListMatrix)
  samples = length(list)
  if samples < 2
    throw(ErrorException("You need at least 2 samples."))
  end
  out = zeros(list[1])
  out_list = out.list
  mean_list = mean.list
  N = length(mean_list)
  @inbounds for sample in list
    sample_list = sample.list
    if length(sample_list) != N
      throw(ErrorException("Different number of elements"))
    end
    for k in 1:N
      @inbounds out_list[k] += abs2( sample_list[k] - mean_list[k])
    end
  end
  if !_has_diagonal(out)
  out_diag = out.diag
  mean_diag = mean.diag
  @inbounds for sample in list
    sample_diag = sample.diag
    for k in 1:length(out_diag)
      @inbounds out_diag[k] += abs2( sample_diag[k] - mean_diag[k])
    end
  end
  end
  out
end

function var{T <: PairwiseListMatrix}(list::Vector{T}; mean=nothing)
    mean === nothing ? varm(list, Base.mean(list)) : varm(list, mean)
end

std{T <: PairwiseListMatrix}(list::Vector{T}; mean=nothing) = sqrt(var(list, mean=mean))

# Tables
# ======

"""
Creates a `Matrix{Any}` useful for `writedlm` and/or `writecsv`.
The labels are stored in the columns 1 and 2, and the values in the column 3.
The diagonal values are included by default.

```
julia> list
3x3 PairwiseListMatrices.PairwiseListMatrix{Int64,ASCIIString,false}:
 0  1  2
 1  0  3
 2  3  0

julia> to_table(list)
6x3 Array{Any,2}:
 "A"  "A"  0
 "A"  "B"  1
 "A"  "C"  2
 "B"  "B"  0
 "B"  "C"  3
 "C"  "C"  0

julia> to_table(list, false)
3x3 Array{Any,2}:
 "A"  "B"  1
 "A"  "C"  2
 "B"  "C"  3

```
"""
function to_table{T, L, D}(lm::PairwiseListMatrix{T, L, D}, diagonal::Bool=true)
  N = lm.nelements
  labels = lm.labels
  list = lm.list
  OutType = T == L ? T : Any
  if D
    if diagonal
      table = Array(OutType, length(list), 3)
      k = 0
      for i in 1:N
        for j in i:N
          k += 1
          table[k, 1] = labels[i]
          table[k, 2] = labels[j]
          table[k, 3] = list[k]
        end
      end
    else
      table = Array(OutType, length(list) - N, 3)
      k = 0
      for i in 1:(N-1)
        for j in (i+1):N
          k += 1
          table[k, 1] = labels[i]
          table[k, 2] = labels[j]
          table[k, 3] = lm[i,j]
        end
      end
    end
  else
    if diagonal
      table = Array(OutType, length(list) + N, 3)
      l = 0
      t = 0
      for i in 1:N
        for j in i:N
          t += 1
          table[t, 1] = labels[i]
          table[t, 2] = labels[j]
          if i != j
            l += 1
            table[t, 3] = list[l]
          else
            table[t, 3] = lm.diag[i]
          end
        end
      end
    else
      table = Array(OutType, length(list), 3)
      k = 0
      for i in 1:(N-1)
        for j in (i+1):N
          k += 1
          table[k, 1] = labels[i]
          table[k, 2] = labels[j]
          table[k, 3] = list[k]
        end
      end
    end
  end
  table
end

"""
Creates a `PairwiseListMatrix` from a `Matrix`.
By default the columns with the labels for i (slow) and j (fast) are 1 and 2.
The values are taken from the column 3 by default.

```
julia> data = readcsv("example.csv")
3x3 Array{Any,2}:
 "A"  "B"  10
 "A"  "C"  20
 "B"  "C"  30

julia> from_table(data, Int, ASCIIString, false)
3x3 PairwiseListMatrices.PairwiseListMatrix{Int64,ASCIIString,false}:
  0  10  20
 10   0  30
 20  30   0

```
"""
function from_table{T, L}(table::Matrix, value::Type{T}, labels::Type{L}, diagonal::Bool, labelcols::Vector{Int}=[1,2], valuecol::Int=3)
  PairwiseListMatrix(convert(Vector{T}, table[:,valuecol]), convert(Vector{L}, unique(table[:,labelcols])), diagonal)
end
