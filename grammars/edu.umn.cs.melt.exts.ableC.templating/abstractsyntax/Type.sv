grammar edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

-- Type of an instantiated template typedef
abstract production templatedType
top::Type ::= q::Qualifiers n::String args::[Type] resolved::Type
{
  -- Non-interfering overrides to preserve pp for better errors, as much as possible.
  top.lpp = pp"${terminate(space(), q.pps)}${text(n)}<${ppImplode(pp", ", map(\t::Type -> cat(t.lpp, t.rpp), args))}>";
  top.rpp = notext();
  -- These are considered non-interfering since
  -- typeName(top.baseTypeExpr, top.typeModifierExpr).* is equivalent to
  -- typeName(top.forward.baseTypeExpr, top.forward.typeModifierExpr).*
  top.baseTypeExpr =
    templateTypedefTypeExpr(
      q,
      name(n, location=builtin),
      foldr(
        consTypeName, nilTypeName(),
        map(\ t::Type -> typeName(t.baseTypeExpr, t.typeModifierExpr), args)));
  top.typeModifierExpr = baseTypeExpr();
  
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
