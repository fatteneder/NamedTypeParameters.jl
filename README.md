# NamedTypeParameters.jl

This package implements a convenience macro `@parameterize` 
which allows to access type parameters of structs by their name,
ignore certain type parameters in method signatures,
and stop worrying about the order of type parameters.

The implementation relies on internals of `UnionAll` and `TypeVar`
and thus might not work with every Julia version out of the box.
The package was developed and tested with `Julia v1.7.1`. 

# Examples

```julia
julia> struct MyType{A<:Real, B, C, D<:Array, E, F, G} end

julia> @parameterize MyType{C=String, B<:Array, G<:Dict}
MyType{<:Real, <:Array, String, <:Array, <:Any, <:Any, <:Dict}

julia> function foo(m::@parameterize(MyType{G=T, A=T, C=String})) where T
          # ...
       end
```
