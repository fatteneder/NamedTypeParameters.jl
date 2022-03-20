using Test
using NamedTypeParameters


# Test types
struct NoTypes end
struct AnyTypes1{A} end
struct AnyTypes2{A,B} end
struct AnyTypes3{A,B,C} end
struct SuperTypes1{A<:Real} end
struct SuperTypes2{A<:Real,B<:Array} end
struct SuperTypes3{A<:Real,B<:Array,C<:AbstractDict} end

# return type itself if no parameters are given
types = [ NoTypes, 
          AnyTypes1, AnyTypes2, AnyTypes2,
          SuperTypes1, SuperTypes2, SuperTypes3 ]
for t in types
  @test @parameterize(t) == t
end


### Notes parameter types

# specifying a type with <: equals adding an unnamed where parameter with <: Real
@test SuperTypes1{<:Real} == SuperTypes1{A} where A<:Real
# note: using invalid where supertypes (invalid wrt the definition of the parameteric type)
# does not throw
SuperTypes1{A} where A<:String # works, although SuperTypes1 is defined with A<:Real
# but inserting an invalid type as a concrete type parameter does throw
@test_throws TypeError SuperTypes1{String}


# using the parameter type name alone inserts its default supertype
@test @parameterize(AnyTypes1{A}) == AnyTypes1{<:Any}
@test @parameterize(AnyTypes2{A,B}) == AnyTypes2{<:Any, <:Any}
@test @parameterize(AnyTypes3{A,B,C}) == AnyTypes3{<:Any, <:Any, <:Any}
@test @parameterize(SuperTypes1{A}) == SuperTypes1{<:Real}
@test @parameterize(SuperTypes2{A,B}) == SuperTypes2{<:Real, <:Array}
@test @parameterize(SuperTypes3{A,B,C}) == SuperTypes3{<:Real, <:Array, <:AbstractDict}

# override type parameter defaults
@test @parameterize(AnyTypes1{A<:Float64}) == AnyTypes1{<:Float64}
@test @parameterize(AnyTypes2{A<:Float64,B<:String}) == AnyTypes2{<:Float64,<:String}
@test @parameterize(AnyTypes3{A<:Float64,B<:String,C<:Symbol}) == AnyTypes3{<:Float64,<:String,<:Symbol}
@test @parameterize(SuperTypes1{A<:Float64}) == SuperTypes1{<:Float64}
@test @parameterize(SuperTypes2{A<:Float64,B<:Vector}) == SuperTypes2{<:Float64,<:Vector}
@test @parameterize(SuperTypes3{A<:Float64,B<:Vector,C<:Dict}) == SuperTypes3{<:Float64,<:Vector,<:Dict}

# skip parameters
@test @parameterize(AnyTypes2{A<:Float64}) == AnyTypes2{<:Float64,<:Any}
@test @parameterize(AnyTypes2{B<:String}) == AnyTypes2{<:Any,<:String}
@test @parameterize(AnyTypes3{A<:Float64}) == AnyTypes3{<:Float64,<:Any,<:Any}
@test @parameterize(AnyTypes3{B<:Vector}) == AnyTypes3{<:Any,<:Vector,<:Any}
@test @parameterize(AnyTypes3{C<:Dict}) == AnyTypes3{<:Any,<:Any,<:Dict}
@test @parameterize(AnyTypes3{A<:Float64,B<:String}) == AnyTypes3{<:Float64,<:String,<:Any}
@test @parameterize(AnyTypes3{A<:Float64,C<:Symbol}) == AnyTypes3{<:Float64,<:Any,<:Symbol}
@test @parameterize(AnyTypes3{B<:String,C<:Symbol}) == AnyTypes3{<:Any,<:String,<:Symbol}
@test @parameterize(SuperTypes2{A<:Float64}) == SuperTypes2{<:Float64,<:Array}
@test @parameterize(SuperTypes2{B<:Vector}) == SuperTypes2{<:Real,<:Vector}
@test @parameterize(SuperTypes3{A<:Float64}) == SuperTypes3{<:Float64,<:Array,<:AbstractDict}
@test @parameterize(SuperTypes3{B<:Vector}) == SuperTypes3{<:Real,<:Vector,<:AbstractDict}
@test @parameterize(SuperTypes3{C<:Dict}) == SuperTypes3{<:Real,<:Array,<:Dict}
@test @parameterize(SuperTypes3{A<:Float64,B<:Vector}) == SuperTypes3{<:Float64,<:Vector,<:AbstractDict}
@test @parameterize(SuperTypes3{A<:Float64,C<:Dict}) == SuperTypes3{<:Float64,<:Array,<:Dict}
@test @parameterize(SuperTypes3{B<:Vector,C<:Dict}) == SuperTypes3{<:Real,<:Vector,<:Dict}


# throw if more overrides than type parameters are given
@test_throws LoadError @eval @parameterize(NoTypes{A})
@test_throws LoadError @eval @parameterize(AnyTypes1{A,B})
@test_throws LoadError @eval @parameterize(AnyTypes2{A,B,C})
@test_throws LoadError @eval @parameterize(AnyTypes3{A,B,C,D})
@test_throws LoadError @eval @parameterize(SuperTypes1{A,B})
@test_throws LoadError @eval @parameterize(SuperTypes2{A,B,C})
@test_throws LoadError @eval @parameterize(SuperTypes3{A,B,C,D})


# name=dummy inserts the dummy in place of name, to be used with where syntax
# note that AnyTypes1{<:Any} == AnyTypes1{T} where <: Any
@test (@parameterize(AnyTypes1{A=>T}) where {T<:Real}) == AnyTypes1{<:Real}
@test (@parameterize(AnyTypes2{A=>T,B=>S}) where {T<:Real,S<:Array}) == AnyTypes2{<:Real, <:Array}
@test (@parameterize(AnyTypes3{A=>T,B=>S,C=>R}) where {T<:Real,S<:Array,R<:Symbol}) == AnyTypes3{<:Real, <:Array, <:Symbol}
@test (@parameterize(SuperTypes1{A=>T}) where {T<:Float64}) == SuperTypes1{<:Float64}
@test (@parameterize(SuperTypes2{A=>T,B=>S}) where {T<:Float64,S<:Vector}) == SuperTypes2{<:Float64, <:Vector}
@test (@parameterize(SuperTypes3{A=>T,B=>S,C=>R}) where {T<:Float64,S<:Vector,R<:Dict}) == SuperTypes3{<:Float64, <:Vector, <:Dict}


# # set a parameter type with =
# @test @parameterize(AnyTypes1{A=Float64}) == AnyTypes1{Float64}
# @test @parameterize(AnyTypes2{A=Float64,B=String}) == AnyTypes2{Float64,String}
# @test @parameterize(AnyTypes3{A=Float64,B=String,C=Symbol}) == AnyTypes3{Float64,String,Symbol}
# @test @parameterize(SuperTypes1{A=Float64}) == SuperTypes1{Float64}
# @test @parameterize(SuperTypes2{A=Float64,B=Vector}) == SuperTypes2{Float64,Vector}
# @test @parameterize(SuperTypes3{A=Float64,B=Vector,C=Dict}) == SuperTypes3{Float64,Vector,Dict}


# duplicated parameter names
@test_throws LoadError @eval @parameterize(AnyTypes2{A,A})
@test_throws LoadError @eval @parameterize(AnyTypes3{A,A,A})
@test_throws LoadError @eval @parameterize(AnyTypes3{A,A,C})
@test_throws LoadError @eval @parameterize(AnyTypes3{A,B,A})
@test_throws LoadError @eval @parameterize(AnyTypes3{A,B,B})
@test_throws LoadError @eval @parameterize(SuperTypes2{A,A})
@test_throws LoadError @eval @parameterize(SuperTypes3{A,A,A})
@test_throws LoadError @eval @parameterize(SuperTypes3{A,A,C})
@test_throws LoadError @eval @parameterize(SuperTypes3{A,B,A})
@test_throws LoadError @eval @parameterize(SuperTypes3{A,B,B})


# unknown parameter names
@test_throws LoadError @eval @parameterize(AnyTypes1{X})
@test_throws LoadError @eval @parameterize(AnyTypes2{X})
@test_throws LoadError @eval @parameterize(AnyTypes2{X,Y})
@test_throws LoadError @eval @parameterize(AnyTypes3{X})
@test_throws LoadError @eval @parameterize(AnyTypes3{X,Y})
@test_throws LoadError @eval @parameterize(AnyTypes3{X,Y,Z})
@test_throws LoadError @eval @parameterize(AnyTypes3{A,Y})
@test_throws LoadError @eval @parameterize(AnyTypes3{A,B,Z})
@test_throws LoadError @eval @parameterize(SuperTypes1{X})
@test_throws LoadError @eval @parameterize(SuperTypes2{X})
@test_throws LoadError @eval @parameterize(SuperTypes2{X,Y})
@test_throws LoadError @eval @parameterize(SuperTypes3{X})
@test_throws LoadError @eval @parameterize(SuperTypes3{X,Y})
@test_throws LoadError @eval @parameterize(SuperTypes3{X,Y,Z})
@test_throws LoadError @eval @parameterize(SuperTypes3{A,Y})
@test_throws LoadError @eval @parameterize(SuperTypes3{A,B,Z})
