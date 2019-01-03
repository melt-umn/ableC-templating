grammar edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

-- Type of an instantiated template typedef
abstract production templatedType
top::Type ::= q::Qualifiers n::String args::[Type] resolved::Type
{
  -- Non-interfering overrides to preserve pp for better errors, as much as possible.
  top.lpp = pp"${terminate(space(), q.pps)}${text(n)}<${ppImplode(pp", ", map(\t::Type -> cat(t.lpp, t.rpp), args))}>";
  top.rpp = notext();
  
  -- This is considered non-interfering since
  -- typeName(top.baseTypeExpr, top.typeModifierExpr).* is equivalent to
  -- typeName(top.forward.baseTypeExpr, top.forward.typeModifierExpr).*
  top.baseTypeExpr =
    case resolved of
    -- Don't reproduce previous instantiation errors
    | errorType() -> errorTypeExpr([])
    | _ ->
      templateTypedefTypeExpr(
        q,
        name(n, location=builtin),
        foldr(
          consTypeName, nilTypeName(),
          map(\ t::Type -> typeName(t.baseTypeExpr, t.typeModifierExpr), args)))
    end;
  top.typeModifierExpr = baseTypeExpr();
  top.canonicalType =
    templatedType(q, n, map(\ t::Type -> t.canonicalType, args), resolved.canonicalType);
  top.withoutTypeQualifiers =
    templatedType(nilQualifier(), n, args, resolved.withoutTypeQualifiers);
  top.withoutExtensionQualifiers =
    templatedType(filterExtensionQualifiers(q), n, args, resolved.withoutExtensionQualifiers);
  top.withTypeQualifiers =
    templatedType(foldQualifier(top.addedTypeQualifiers ++ q.qualifiers), n, args, resolved.withTypeQualifiers);
  top.mergeQualifiers = \t2::Type ->
    case t2 of
    | templatedType(q2, _, _, resolved2) ->
      templatedType(unionQualifiers(top.qualifiers, q2.qualifiers), n, args, resolved.mergeQualifiers(t2))
    | _ -> resolved.mergeQualifiers(t2)
    end;
  
  resolved.addedTypeQualifiers = top.addedTypeQualifiers;
  
  forwards to resolved;
}

function mkTemplatedType
Type ::= q::Qualifiers n::String args::[Type] env::Decorated Env
{
  local result::BaseTypeExpr =
    templateTypedefTypeExpr(
      q,
      name(n, location=builtin),
      foldr(
        consTypeName, nilTypeName(),
        map(\ t::Type -> typeName(t.baseTypeExpr, t.typeModifierExpr), args)));
  result.env = env;
  result.returnType = nothing();
  result.givenRefId = nothing();
  
  return result.typerep;
}
