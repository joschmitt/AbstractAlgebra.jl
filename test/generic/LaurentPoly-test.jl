using AbstractAlgebra: terms_degrees, LaurentPolyRingElem

using AbstractAlgebra.Generic: Integers, LaurentPolyWrapRing, LaurentPolyWrap,
                               trail_degree, lead_degree

@testset "Generic.LaurentPoly" begin
   @testset "constructors" begin
      L0, y0 = laurent_polynomial_ring(zz, "y0")

      for R in (ZZ, GF(5))
         P, _ = polynomial_ring(R, "x0")
         L, y = laurent_polynomial_ring(R, "y")

         @test laurent_polynomial_ring(R, "y", cached = true)[1] ===
               laurent_polynomial_ring(R, "y", cached = true)[1]

         @test laurent_polynomial_ring(R, "y", cached = true)[1] !==
               laurent_polynomial_ring(R, "y", cached = false)[1]

         P2, _ = polynomial_ring(R, "x0", cached = false)

         @test laurent_polynomial_ring(P, "y")[1] ===
               laurent_polynomial_ring(P, "y")[1]

         @test laurent_polynomial_ring(P2, "y")[1] !==
               laurent_polynomial_ring(P, "y")[1]

         x = y.poly

         @test L isa LaurentPolyWrapRing{elem_type(R)}
         @test y isa LaurentPolyWrap{elem_type(R)}

         @test parent_type(y) == typeof(L)
         @test elem_type(L) == typeof(y)

         @test parent(y) == L

         @test base_ring(L) == R
         @test base_ring(L) == base_ring(P)
         @test coefficient_ring(L) == R
         @test coefficient_ring_type(L) === typeof(R)

         @test var(L) == :y
         @test symbols(L) == [:y]
         @test nvars(L) == 1

         @test characteristic(L) == characteristic(R)

         @test L(x) == y
         @test L(2x^2 + 3x + 4) == 2y^2 + 3y + 4
         @test L(2x^2 + 3x + 4, -1) * y == 2y^2 + 3y + 4

         @test L(y) === y
         f = y^2 + y
         @test L(f) === f
         @test L(0) == zero(L)
         @test L(1) == one(L)
         @test L(2) == 2*one(L)
         @test L()  == zero(L)
         c = 3 * one(R)
         @test L(c) == 3
         @test_throws Exception L('x')
         @test_throws Exception L("x")
         @test_throws Exception L(y0)

         @test is_domain_type(typeof(y))
         @test is_exact_type(typeof(y))

         R, r = laurent_polynomial_ring(RDF, "r")
         @test !is_exact_type(typeof(r))
      end
   end

   @testset "basic manipulation" begin
      L, y = laurent_polynomial_ring(ZZ, "y")
      x = y.poly
      Z, z = laurent_polynomial_ring(L, "z")
      T, t = laurent_polynomial_ring(L.polyring, "t")

      @test terms_degrees(y) == 0:1
      @test terms_degrees(y^3) == 0:3
      @test [coeff(y, i) for i=-1:2] == [0, 0, 1, 0]
      @test trail_degree(y^2) == 2
      @test lead_degree(y^2) == 2

      @test iszero(zero(L))
      @test iszero(zero(y))
      @test !iszero(one(y))
      @test !iszero(y)

      @test isone(one(L))
      @test isone(one(y))
      @test !isone(zero(y))
      @test !isone(y)

      @test is_gen(y)
      @test is_gen(gen(L))
      @test !is_gen(one(y))
      @test !is_gen(zero(y))
      @test y == gen(L)

      @test gens(L)[1] == y
      @test length(gens(L)) == 1

      @test is_monomial(y)
      @test is_monomial(y^-3)
      @test !is_monomial(2y)
      @test !is_monomial(y^-1 + y)
      @test is_monomial(z^2)
      # TODO: remove Z constructor below, when ambiguities are fixed
      @test is_monomial(Z(y^-3)*z^4)
      @test is_monomial_recursive(Z(y^-3)*z^4)
      @test !is_monomial_recursive(Z(y+y^2)*z)
      @test is_monomial_recursive(x^2*t^-3)
      @test !is_monomial(x^2*t^-3)
      @test !is_monomial_recursive((x+x^2)*t)

      @test !is_unit(laurent_polynomial_ring(ZZ, "x")[1](2))
      @test !is_unit(zero(L))

      for e = -5:5
         @test is_unit(y^e)
      end

      if base_ring(L) isa AbstractAlgebra.Field
         for e = -5:5
            @test is_unit(2*y^e)
            @test is_unit(3*y^(2e))
         end
      end

      @test is_zero_divisor(0*y)
      @test !is_zero_divisor(y)

      @test leading_coefficient(zero(y)) == 0
      @test trailing_coefficient(zero(y)) == 0
      @test leading_coefficient(one(y)) == 1
      @test trailing_coefficient(one(y)) == 1
      @test leading_coefficient(y) == 1
      @test trailing_coefficient(y) == 1

      @test hash(zero(y)) == hash(zero(y))
      @test hash(one(y)) == hash(one(y))

      f1 = f = L(x, -2)
      @test terms_degrees(f) == -2:-1
      @test trail_degree(f) == -1
      @test lead_degree(f) == -1
      @test [coeff(f, i) for i = -3:0] == [0, 0, 1, 0]

      @test !isone(f)
      @test !iszero(f)
      @test isone(f^0)
      @test iszero(f-f)

      @test leading_coefficient(f) == 1
      @test trailing_coefficient(f) == 1

      f2 = f = L(3 + 2*x^4, -3)
      @test terms_degrees(f) == -3:1
      @test trail_degree(f) == -3
      @test lead_degree(f) == 1
      @test [coeff(f, i) for i = -4:2] == [0, 3, 0, 0, 0, 2, 0]

      @test f == 3y^-3 + 2y

      @test leading_coefficient(f) == 2
      @test trailing_coefficient(f) == 3

      @test canonical_unit(f) == y^-3

      @test hash(f) != hash(3y^-3 + y)
      @test hash(f) != hash(3y^-2 + 2y)

      set_coefficient!(f, -3, big(4))
      @test f == 4y^-3 + 2y

      set_coefficient!(f, -3, big(0))
      @test f == 2y

      set_coefficient!(f, -50, big(-2))
      @test f == -2y^-50 + 2y

      @test iszero(set_coefficient!(set_coefficient!(deepcopy(f), 1, big(0)), -50, big(0)))

      @test !isone(f)
      @test !iszero(f)
      @test isone(f^0)
      @test iszero(f-f)

      for f in (f1, f2, L(rand(parent(x), 0:9, -9:9), rand(-9:9)))
         @test hash(f) == hash(f)
         @test hash(f, rand(UInt)) != hash(f) # very unlikely failure
         @test hash(f-f) == hash(zero(f))
         @test hash(f^1) == hash(f)
         @test hash(f^0) == hash(one(f))
         @test hash(f*f*f) == hash(f^3)

         @test leading_coefficient(f) == leading_coefficient(f.poly)
         @test trailing_coefficient(f) == trailing_coefficient(f.poly)
      end

      ff = deepcopy(f)
      @test parent(f) === parent(ff)
      @test f == ff && f !== ff

      g = y^2*(y+1)*(y+2)
      ok, q = divides(y*(y+1)*(y+2), g)
      @test ok && q == y^-1
      @test divexact(y*(y+1)*(y+2), g) == y^-1

      g = set_coefficient!(1+y+y^2, 0, zero(ZZ))
      ok, q = divides(y+1, g)
      @test ok && q == y^-1
      @test divexact(y+1, g) == y^-1

      @test !divides(y+1, 2*y+3)[1]
      @test_throws Exception divexact(y+1, 2*y+3)

      @test is_divisible_by(zero(L), zero(L))
      @test !is_divisible_by(one(L), zero(L))

      @test is_divisible_by(2*y+3, 2+3*y^-1)
      @test !is_divisible_by(3*y+4, 2+3*y^-1)
   end

   @testset "coercion" begin
      R, x = polynomial_ring(ZZ, "x")
      L, x1 = laurent_polynomial_ring(ZZ, "x")
      @test L(x) == x1
      @test L(x+x^2) == x1+x1^2
   end

   @testset "comparisons" begin
      L, y = laurent_polynomial_ring(ZZ, "y")
      x = y.poly

      @test y == y

      f = L(x^3 + 2x^2 - 1)
      @test f == f
      @test f == L(x^3 + 2x^2 - 1)
      @test f == x^3 + 2x^2 - 1
      @test x^3 + 2x^2 - 1 == f
      @test f != x
      @test x != f
      @test f != L(x^3 + 2x^2 - 1, -2)
   end

   @testset "unary & binary & adhoc arithmetic operations" begin
      L, y = laurent_polynomial_ring(ZZ, "y")
      x = y.poly

      @test -(-y) == y
      @test iszero(y + (-y))
      @test y + y - y == y
      @test 2y*y*y + 3y*y - 5y + 8 == L(2x^3 + 3x^2 - 5x + 8)

      c = rand(-9:9)
      for i = -9:9
         @test coeff(c*y, i) == (i == 1 ? c : 0)
         @test coeff(y*c, i) == (i == 1 ? c : 0)
      end

      fx = rand(parent(x), 1:9, -9:9)
      f = L(fx)
      @test f*f == L(fx*fx)

      f = L(fx, -3)
      @test y*y*y*y*y*y*f*f == L(fx*fx)
      @test y*y*y*y*y*y*f*f == y^6 * f^2

      # with polynomials as base ring
      P, x = polynomial_ring(ZZ, "x")
      L, y = laurent_polynomial_ring(P, "y")
      @test parent(x*y) == L
      @test parent(y*x) == L

      # with Laurent polynomials as base ring
      P, x = laurent_polynomial_ring(ZZ, "x")
      L, y = laurent_polynomial_ring(P, "y")
      @test parent(x*y) == L
      @test parent(y*x) == L

      # as base ring of polynomials
      L, y = laurent_polynomial_ring(ZZ, "y")
      P, x = polynomial_ring(L, "x")
      @test parent(x*y) == P
      @test parent(y*x) == P

      # Inexact field
      R, x = laurent_polynomial_ring(RealField, "x")
      for iter = 1:100
         f = rand(R, 0:10, -1:1)
         g = rand(R, 0:10, -1:1)
         h = rand(R, 0:10, -1:1)
         @test isapprox(f + (g + h), (f + g) + h)
         @test isapprox(f*g, g*f)
         @test isapprox(f*(g + h), f*g + f*h)
         @test isapprox((f - h) + (g + h), f + g)
         @test isapprox((f + g)*(f - g), f*f - g*g)
         @test isapprox(f - g, -(g - f))
      end
      p = 1.2*x
      q = nextfloat(1.2)*x
      @test p != q
      @test isapprox(p, q)
      @test !isapprox(p, q + 1.2x^2)
      @test !isapprox(p, 1.1*x)

      t = 1.2 * x^0
      r = RealField(1.2)
      @test isapprox(r, t) && isapprox(t, r)
      r = RealField(nextfloat(1.2))
      @test isapprox(r, t) && isapprox(t, r)
   end

   @testset "powering" begin
      L, y = laurent_polynomial_ring(ZZ, "y")
      x = y.poly

      @test 2y^-2 + 3y^-1 + 4y^0 + 5y + 6y^2 == L(2 + 3x + 4x^2 + 5x^3 + 6x^4, -2)

      fx = rand(parent(x), 1:9, -9:9)
      f = d -> L(fx, d)

      for e in rand(0:9, 2)
         fxe = L(fx^e)
         for i = -3:3
            @test y^(-i*e) * f(i)^e == fxe
         end
      end

      @test isone(f(rand(-9:9))^0)

      @test_throws DomainError (2y)^-1
      @test_throws DomainError (3y^-1)^-2
      @test_throws DomainError (y + y^2)^-1
      @test_throws DomainError (y-y)^-1

      LQ, z = laurent_polynomial_ring(QQ, "z")

      @test (2z)^-1 == 1//2 * z^-1
      @test (3z^-1)^(-2) == 1//9 * z^2

      @test_throws DomainError (z + z^2)^-1
   end

   @testset "evaluate" begin
      L, y = laurent_polynomial_ring(ZZ, "y")
      p = 2y+3y^4
      @assert p.mindeg == 0
      for a = Any[-3:3; -10.0:3.3:10;]
         @test evaluate(p, a) == evaluate(p.poly, a)
      end
      q = p - y^-2
      x = y.poly
      t = -x^0 + 2x^3 + 3x^6
      for a = -10.0:3.3:10
         @test evaluate(q, a) == evaluate(t, a) * a^-2
      end
   end

   @testset "derivative" begin
      for R in (ZZ, QQ, GF(5))
         L, x = laurent_polynomial_ring(R, "x")
         @test derivative(zero(L)) == zero(L)
         @test derivative(one(L)) == zero(L)
         @test derivative(x) == one(L)
         @test derivative(x^-5) == -5*x^-6
         @test derivative(1 + 2*x + x^5) == 2 + 5*x^4
         @test derivative(x^-5 + x) == -5*x^-6 + 1
      end
   end

   @testset "unsafe functions" begin
      L, y = laurent_polynomial_ring(ZZ, "y")

      # zero!
      p = y^-2 + 3y + y^3
      q = zero!(p)
      @test q === p
      @test iszero(p)
      p = rand(L, -10:10, -10:10)
      q = zero!(p)
      @test q === p
      @test iszero(p)
      # TODO: add a test for when p.poly is immutable

      # mul!
      p = y+1
      q = y-1
      s = y^0
      t = mul!(s, p, q)
      @test t === s == y^2-1
      p = rand(L, -10:10, -10:10)
      q = rand(L, -10:10, -10:10)
      t = p*q
      s = mul!(s, p, q)
      @test t == s
      # TODO: add a test for when s.poly is immutable

      # add!
      p = rand(L, -10:10, -10:10)
      q = rand(L, -10:10, -10:10)
      t = p + q
      s = add!(p, q)
      @test s === p == t
      # TODO: add a test for when p.poly is immutable

      # add!
      p = rand(L, -10:10, -10:10)
      q = rand(L, -10:10, -10:10)
      t = p + q
      s = y^0
      t = add!(s, p, q)
      @test t === s == p + q
      # TODO: add a test for when p.poly is immutable
   end

   @testset "shifting" begin
      L, y = laurent_polynomial_ring(ZZ, "y")

      p = 2y - 3y^-2
      @test shift_left(p, 0) == p
      @test shift_left(p, 3) == 2y^4 - 3y
      @test_throws DomainError shift_left(p, -rand(1:99))

      @test shift_right(p, 0) == p
      @test shift_right(p, 3) == 2y^-2 - 3y^-5
      @test_throws DomainError shift_right(p, -rand(1:99))
   end

   @testset "rand" begin
      L, y = laurent_polynomial_ring(ZZ, "y")

      test_rand(L, -5:5, -10:10) do f
         @test AbstractAlgebra.degrees_range(f) ⊆ -5:5
         for i = -5:5
            @test coeff(f, i) ∈ -10:10
         end
      end
   end

   @testset "change_base_ring & map_coefficients" begin
      Z, z = laurent_polynomial_ring(ZZ, "z")
      Q, q = laurent_polynomial_ring(QQ, "q")

      fz = z^2 - z - 2z^-2

      @test change_base_ring(QQ, z) == q
      @test change_base_ring(QQ, fz) == q^2 - q - 2q^-2
      @test change_base_ring(ZZ, q) == z

      @test map_coefficients(x -> x^2, fz) == z^2 + z + 4z^-2
      @test map_coefficients(one, fz) == z^2 + z + z^-2
      @test map_coefficients(x -> x+2, fz) == 3z^2 + z
      @test map_coefficients(x -> x^2, q^2 - q - 2q^-2) == q^2 + q + 4q^-2
   end

   @testset "printing" begin
      L, y = laurent_polynomial_ring(ZZ, "y")
      @test sprint(show, "text/plain", y) == "y"
      @test sprint(show, "text/plain", L) == "Univariate Laurent polynomial ring in y\n  over integers"
      p = y^1; p.mindeg = -3
      @test sprint(show, "text/plain", p) == "y^-2"
      R, z = polynomial_ring(L, "z")
      @test sprint(show, "text/plain", (y^2)*z) == "y^2*z"
      @test sprint(show, "text/plain", 3*(y^0)*z) == "3*z"
      @test sprint(show, "text/plain", -y*z + (-y*z^2)) == "-y*z^2 - y*z"
      @test sprint(show, "text/plain", -y^0*z) == "-z"
   end

   @testset "conformance" begin
      L, y = laurent_polynomial_ring(QQ, "y")
      ConformanceTests.test_Ring_interface(L)
      ConformanceTests.test_EuclideanRing_interface(L)
      ConformanceTests.test_Ring_interface_recursive(L)

      L, y = laurent_polynomial_ring(residue_ring(ZZ, ZZ(6))[1], "y")
      ConformanceTests.test_Ring_interface(L)
   end
end


# -------------------------------------------------------

# Coeff rings for the tests below
ZeroRing,_ = residue_ring(ZZ,1);
ZZmod720,_ = residue_ring(ZZ, 720);


# [2024-12-12  laurent_polynomial_ring currently gives error when coeff ring is zero ring]
# ## LaurentPoly over ZeroRing
# @testset "Nilpotent/unit for ZeroRing[x, x^(-1)]" begin
#   P,x = laurent_polynomial_ring(ZeroRing, "x");
#   @test is_nilpotent(P(0))
#   @test is_nilpotent(P(1))
#   @test is_nilpotent(x)
#   @test is_nilpotent(-x)

#   @test is_unit(P(0))
#   @test is_unit(P(1))
#   @test is_unit(x)
#   @test is_unit(-x)
# end

## LaurentPoly over ZZ
@testset "Nilpotent/unit for ZZ[x, x^(-1)]" begin
  P,x = laurent_polynomial_ring(ZZ, "x");
  @test is_nilpotent(P(0))
  @test !is_nilpotent(P(1))
  @test !is_nilpotent(x)
  @test !is_nilpotent(-x)

  @test !is_unit(P(0))
  @test is_unit(P(1))
  @test is_unit(P(-1))
  @test !is_unit(P(-2))
  @test !is_unit(P(-2))
  @test is_unit(x)
  @test is_unit(-x)
  @test is_unit(1/x)
  @test is_unit(-1/x)
  @test !is_unit(2/x)
  @test !is_unit(-2/x)
  @test !is_unit(x+1)
  @test !is_unit(x-1)
end

## LaurentPoly over QQ
@testset "Nilpotent/unit for QQ[x, x^(-1)]" begin
  P,x = laurent_polynomial_ring(QQ, "x");
  @test is_nilpotent(P(0))
  @test !is_nilpotent(P(1))
  @test !is_nilpotent(x)
  @test !is_nilpotent(-x)

  @test !is_unit(P(0))
  @test is_unit(P(1))
  @test is_unit(P(-1))
  @test is_unit(P(-2))
  @test is_unit(P(-2))
  @test is_unit(x)
  @test is_unit(-x)
  @test is_unit(2*x)
  @test is_unit(-2*x)
  @test is_unit(1/x)
  @test is_unit(-1/x)
  @test is_unit(2/x)
  @test is_unit(-2/x)
  @test !is_unit(x+1)
  @test !is_unit(x-1)
end

## LaurentPoly over ZZ/720
@testset "Nilpotent/unit for ZZ/(720)[x, x^(-1)]" begin
  P,x = laurent_polynomial_ring(ZZmod720, "x");
  @test is_nilpotent(P(0))
  @test !is_nilpotent(P(1))
  @test is_nilpotent(P(30))
  @test !is_nilpotent(x)
  @test !is_nilpotent(-x)
  @test is_nilpotent(30*x)
  @test is_nilpotent(30/x)

  @test !is_unit(P(0))
  @test is_unit(P(1))
  @test is_unit(P(-1))
  @test !is_unit(P(2))
  @test !is_unit(P(-2))
  @test is_unit(P(7))
  @test is_unit(P(-7))
  @test is_unit(x)
  @test is_unit(-x)
  @test !is_unit(2*x)
  @test !is_unit(x+1)
  @test !is_unit(x-1)
  @test is_unit(x+30)
  @test is_unit(x-30)
  @test is_unit(1+30*x)
  @test is_unit(1-30*x)
  @test is_unit(7+60*x)
  @test is_unit(7-60*x)
  @test is_unit(600+7*x+30*x^2)
  @test is_unit(600-7*x+30*x^2)
end
