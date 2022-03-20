using Test
using NamedTypeParameters


# Test types
struct NoTypes end
struct AnyTypes1{A} end
struct AnyTypes2{A,B} end
struct AnyTypes3{A,B,C} end
# struct SuperTypes1{A<:Real} end
# struct SuperTypes2{A<:Real,B<:String} end
# struct SuperTypes3{A<:Real,B<:String,C<:Symbol} end
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


# override defaults
@test @parameterize(AnyTypes1{A<:Float64}) == AnyTypes1{<:Float64}
@test @parameterize(AnyTypes2{A<:Float64,B<:String}) == AnyTypes2{<:Float64,<:String}
@test @parameterize(AnyTypes3{A<:Float64,B<:String,C<:Symbol}) == AnyTypes3{<:Float64,<:String,<:Symbol}
@test @parameterize(SuperTypes1{A<:Float64}) == SuperTypes1{<:Float64}
@test @parameterize(SuperTypes2{A<:Float64,B<:Vector}) == SuperTypes2{<:Float64,<:Vector}
@test @parameterize(SuperTypes3{A<:Float64,B<:Vector,C<:Dict}) == SuperTypes3{<:Float64,<:Vector,<:Dict}
# note that inserting an invalid supertype for a type parameter does not throw
SuperTypes1{<:String} # valid, although defined as SuperTypes{A<:Real}
# but inserting an invalid type for a type parameter does
@test_throws TypeError SuperTypes1{String}

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


# parameterize(NoTypes)
# # parameterize(AnyTypes1)
# # parameterize(AnyTypes1, [(:A, :Float64)])
# parameterize(AnyTypes2, [Expr(:<:, :B, :Float64)])
# # @test_throws LoadError parameterize(AnyTypes2, [Expr(:curly, :B, :Float64)])

# @parameterize(AnyTypes1, :by, B<:Float64)
# args = @parameterize AnyTypes3{A, B<:Float64, C=T}
# args = @parameterize(AnyTypes3{A, B<:Float64, C=T}) where T
