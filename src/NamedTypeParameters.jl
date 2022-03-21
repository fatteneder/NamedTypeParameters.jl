module NamedTypeParameters


export @parameterize,
       expand_type_parameters


expand_type_parameters(x::Union{DataType,UnionAll}) = Base.unwrap_unionall(x)


function parse_overrides(typeparameters)
  list_name, list_typeexpr = [], []
  for tp in typeparameters
    name, typeexpr = if tp isa Symbol
      # {..., A, ...} -> {..., <:default_supertype_of_A, ...}
      tp, nothing
    elseif tp.head === :<:         
      # {..., A <: SuperType, ...} -> {..., <:SuperType, ...}
      tp.args[1], Expr(:<:, tp.args[2])
    elseif tp.head === :(=)
      # {..., A = Float64, ...} -> {..., Float64, ...}
      tp.args[1], tp.args[2]
    else
      error("Unrecognized type pattern $(tp)")
    end
    push!(list_name, name)
    push!(list_typeexpr, typeexpr)
  end

  list_name, list_typeexpr
end


function parameterize(type, override_parameters=[])

  # !!! This block relies on Base internals
  # - unwrap_unionall (used in expand_type_parameters)
  # - TypeName fields :name, :parameters
  # - TypeVar fields :name, :ub
  expanded_type = expand_type_parameters(type)
  typename, typeparameters = expanded_type.name, expanded_type.parameters
  if length(typeparameters) < length(override_parameters)
    error("Too many parameters for type '$expanded_type'")
  end
  # build parameter list from defaults
  parameter_list = Union{Expr,Symbol}[ Expr(:<:, Symbol(p.ub)) for p in typeparameters ]
  parameter_names = [ p.name for p in typeparameters ]

  override_names, override_typeexprs = parse_overrides(override_parameters)
  if length(unique(override_names)) != length(override_names)
    error("Duplicated parameter names")
  end

  # override
  for (name, typeexpr) in zip(override_names, override_typeexprs)
    # parameter names must be unique, hence, findfirst is enough
    index = findfirst(n -> n == name, parameter_names)
    if isnothing(index)
      error("Unknown parameter name '$name'")
    end
    isnothing(typeexpr) && continue # typename without a supertype falls back to default
    parameter_list[index] = typeexpr
  end

  Expr(:curly, typename.name, parameter_list...)
end


"""
Macro which allows to access type parameters of structs by their name,
ignore certain type parameters in method signatures,
and stop worrying about the order of type parameters.

# Examples

```
julia> struct MyType{A<:Real, B, C, D<:Array, E, F, G} end

julia> @parameterize MyType{C=String, B<:Array, G<:Dict}
MyType{<:Real, <:Array, String, <:Array, <:Any, <:Any, <:Dict}

julia> function foo(m::@parameterize(MyType{G=T, A=T, C=String})) where T
          # ...
       end
```
"""
macro parameterize(signature)
  if signature isa Symbol
    return esc(signature)
  end
  if signature.head !== :curly
    error("Failed to recognize a type in '$signature'")
  end
  type, override_parameters = signature.args[1], signature.args[2:end]
  type = @eval __module__ $type

  esc(parameterize(type, override_parameters))
end


end # module
