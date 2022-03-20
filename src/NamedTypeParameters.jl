module NamedTypeParameters


export @parameterize


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
    elseif tp.head === :call && tp.args[1] === :(=>)
      # {..., A => T, ...} -> {..., T, ...}
      tp.args[2], tp.args[3]
    elseif tp.head === :(=)
      # {..., A = Float64, ...} -> {..., Float64, ...}
      tp.args[1], tp.args[2]
    else
      error("Unrecognized type pattern $(tp)")
    end
    push!(list_name, name)
    push!(list_typeexpr, typeexpr)
  end
  return list_name, list_typeexpr
end


function parameterize(type, override_parameters=[])

  expanded_type = expand_type_parameters(type)
  typename, typeparameters = expanded_type.name, expanded_type.parameters
  if length(typeparameters) < length(override_parameters)
    error("Too many parameters for type '$expanded_type'")
  end

  # build parameter list from defaults
  # !!! This relies on internals of TypeVar
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

  quote
    $(Expr(:curly, typename.name, parameter_list...))
  end
end


"""
    parameterize(signature)

===
# Examples

```
struct MyType{A<:Real,B,C,D} end
@parameterize MyType{D=T, B<:Float64, C}
```
transforms into
```
MyType{<:Real, <:Float64, <:Any, T}
```

Here is what happend for each slot (the order inside @parameterize does not matter)
- (A) We inserted <:Real, because we did not specify anything for slot A and <:Real is its 
default supertype (according to the definion of MyType).
- (B) We inserted <:Float64 as requested.
- (C) We inserted <:Any, because although it was skipped, no supertype was provided.
- (D) We inserted T as a placeholder for a preceeding `where` phrase (must be added separately).
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
  return esc(parameterize(type, override_parameters))
end


end # module
