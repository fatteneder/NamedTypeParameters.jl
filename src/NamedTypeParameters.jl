module NamedTypeParameters


export get_type_signature,
       parameterize,
       @parameterize


get_type_signature(ua::UnionAll) = get_type_signature(ua.body)
get_type_signature(dt::DataType) = (dt.name, dt.parameters)


function parameterize(type, override_parameters=[])
  typename, typeparameters = get_type_signature(type)
  if length(typeparameters) < length(override_parameters)
    error("Requested too many parameters for type $type")
  end
  if length(typeparameters) == 0
    return quote 
      $(esc(typename.name)) 
    end
  end
  # parameter_list = [ Expr(:<:, Symbol(p.name), Symbol(p.ub)) for p in typeparameters ]
  parameter_list = Union{Expr,Symbol}[ Expr(:<:, Symbol(p.ub)) for p in typeparameters ]
  parameter_names = [ p.name for p in typeparameters ]
  # override
  # TODO Check for duplicates in override_parameters
  for override in override_parameters
    name, type, type_is_dummy = if override isa Symbol
      override, nothing, false
    elseif override.head === :<:         
      override.args[1], override.args[2], false
    elseif override.head === :(=)
      override.args[1], override.args[2], true
    else
      error("Unrecognized type pattern $(override)")
    end
    # parameter names must be unique, hence, findfirst is enough
    index = findfirst(n -> n == name, parameter_names)
    isnothing(index) && continue
    # parameter_list[index] = Expr(:<:, Symbol(name), Symbol(type))
    # parameter_list[index] = Expr(:<:, Symbol(type))
    isnothing(type) && continue # typename without a supertype or assignment falls back to default
    if !type_is_dummy
      parameter_list[index] = Expr(:<:, Symbol(type))
    else
      parameter_list[index] = type
    end
  end
  new_signature = Expr(:curly, typename.name, parameter_list...)
  # display(new_signature)
  quote
    $new_signature
  end
end


"""
    parameterize(short_signature)

===
# Examples

struct MyType{A,B,C,D} end

@parameterize MyType{B<:Float64, C, D=T}
transforms into
MyType{<:Any, <:Float64, <:Any, T}
Here is what happend for each slot:
(A) We inserted <:Any, because we did not specify anything for slot A and <:Any is its default supertype
(as given in the definion of MyType).
(B) We inserted <:Float64 as requested.
(C) We inserted <: Any, because although it was mentioned, no supertype was provided.
(D) We inserted T as a placeholder for a preceeding `where` list.
"""
macro parameterize(short_signature)
  if short_signature isa Symbol
    return esc(short_signature)
  end
  if short_signature.head !== :curly
    error("Could not recognize a type")
  end
  type, override_parameters = short_signature.args[1], short_signature.args[2:end]
  type = @eval __module__ $type
  return esc(parameterize(type, override_parameters))
end


end # module
