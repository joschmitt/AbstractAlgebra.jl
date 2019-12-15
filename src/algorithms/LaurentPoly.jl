###############################################################################
#
#   LaurentPoly.jl : Generic algorithms for abstract Laurent polynomials
#
###############################################################################

base_ring(p::LaurentPolyElem) = base_ring(parent(p))

###############################################################################
#
#   Basic manipulation
#
###############################################################################

# required implementation
"""
    monomials_degrees(p::LaurentPolyElem) -> AbstractVector

> Return a vector containing at least all the degrees of the non-null
> monomials of `p`.
"""
function monomials_degrees end

# return a monomials_degrees vector valid for both polys
function monomials_degrees(p::LaurentPolyElem, q::LaurentPolyElem)
   minp, maxp = extrema(monomials_degrees(p))
   minq, maxq = extrema(monomials_degrees(q))
   min(minp, minq):max(maxp, maxq)
end

# return the degree of the unique monomial, throw if not a monomial
function monomial_degree(p::LaurentPolyElem)
   isnull = true
   local deg
   for d in monomials_degrees(p)
      if !iszero(coeff(p, d))
         !isnull && throw(DomainError(p, "not a monomial"))
         deg = d
         isnull = false
      end
   end
   deg
end

# other required methods without default implementation:
# coeff

###############################################################################
#
#   String I/O
#
###############################################################################

function show(io::IO, p::LaurentPolynomialRing)
   print(io, "Univariate Laurent Polynomial Ring in ")
   print(io, string(var(p)))
   print(io, " over ")
   print(IOContext(io, :compact => true), base_ring(p))
end
