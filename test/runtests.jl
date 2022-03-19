using Test
using NamedTypeParameters



struct NoTypes end


# @test get_type_signature(NoTypes) == [typename(NoTypes), svec()]
# display(get_type_signature(NoTypes))


struct AnyTypes1{A} end
struct AnyTypes2{A,B} end
struct AnyTypes3{A,B,C} end


# display(get_type_signature(AnyTypes1))
# display(get_type_signature(AnyTypes2))
# display(get_type_signature(AnyTypes3))


struct SuperTypes1{A<:Real} end
struct SuperTypes2{A<:Real,B<:String} end
struct SuperTypes3{A<:Real,B<:String,C<:Symbol} end


# display(get_type_signature(SuperTypes1))
# display(get_type_signature(SuperTypes2))
# display(get_type_signature(SuperTypes3))


parameterize(NoTypes)
# parameterize(AnyTypes1)
# parameterize(AnyTypes1, [(:A, :Float64)])
parameterize(AnyTypes2, [Expr(:<:, :B, :Float64)])
# @test_throws LoadError parameterize(AnyTypes2, [Expr(:curly, :B, :Float64)])

# @parameterize(AnyTypes1, :by, B<:Float64)
# args = @parameterize AnyTypes3{A, B<:Float64, C=T}
args = @parameterize(AnyTypes3{A, B<:Float64, C=T}) where T
