grammar edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

-- Type of an instantiated template typedef
abstract production templatedType
top::Type ::= q::Qualifiers n::String args::TemplateArgs resolved::Type
{
  -- Non-interfering overrides to preserve pp for better errors, as much as possible.
  top.lpp = pp"${terminate(space(), q.pps)}${text(n)}<${ppImplode(pp", ", args.pps)}>";
  top.rpp = notext();
  
  -- This is considered non-interfering since
  -- typeName(top.baseTypeExpr, top.typeModifierExpr).* is equivalent to
  -- typeName(top.forward.baseTypeExpr, top.forward.typeModifierExpr).*
  top.baseTypeExpr =
    case resolved of
    -- Don't reproduce previous instantiation errors
    | errorType() -> errorTypeExpr([])
    | _ -> templateTypedefTypeExpr(q, name(n), args.argNames)
    end;
  top.typeModifierExpr = baseTypeExpr();
  top.canonicalType =
    templatedType(q, n, args.canonicalType, resolved.canonicalType);
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

synthesized attribute argNames::TemplateArgNames;
synthesized attribute containsErrorType::Boolean;

nonterminal TemplateArgs with pps, mangledName, count, argNames, paramNames, canonicalType, containsErrorType, substDefs;

abstract production consTemplateArg
top::TemplateArgs ::= h::TemplateArg t::TemplateArgs
{
  propagate canonicalType;
  top.pps = h.pp :: t.pps;
  top.mangledName = h.mangledName ++ "_" ++ t.mangledName;
  top.count = 1 + t.count;
  top.argNames = consTemplateArgName(h.argName, t.argNames);
  top.containsErrorType = h.containsErrorType || t.containsErrorType;
  top.substDefs =
    (if !null(top.paramNames) then h.substDefs else fail()) <+ t.substDefs;
  
  h.paramName =
    case top.paramNames of
    | h :: _ -> h
    | [] -> error("empty paramNames")
    end;
  t.paramNames =
    case top.paramNames of
    | _ :: t -> t
    | [] -> []
    end;
}

abstract production nilTemplateArg
top::TemplateArgs ::=
{
  propagate canonicalType;
  top.pps = [];
  top.mangledName = "";
  top.count = 0;
  top.argNames = nilTemplateArgName();
  top.containsErrorType = false;
  top.substDefs = fail();
}

global foldTemplateArg::(TemplateArgs ::= [TemplateArg]) =
  foldr(consTemplateArg, nilTemplateArg(), _);

synthesized attribute argName::TemplateArgName;

nonterminal TemplateArg with pp, mangledName, argName, paramName, canonicalType, containsErrorType, substDefs;

abstract production typeTemplateArg
top::TemplateArg ::= t::Type
{
  propagate canonicalType;
  top.pp = cat(t.lpp, t.rpp);
  top.mangledName = t.mangledName;
  top.argName = typeTemplateArgName(typeName(directTypeExpr(t), baseTypeExpr()));
  top.containsErrorType = case t of errorType() -> true | _ -> false end;
  top.substDefs =
    rule on BaseTypeExpr of
    | typedefTypeExpr(_, name(n)) when n == top.paramName -> directTypeExpr(t)
    end;
}

abstract production nameTemplateArg
top::TemplateArg ::= n::String
{
  propagate canonicalType;
  top.pp = text(n);
  top.mangledName = n;
  top.argName =
    valueTemplateArgName(
      declRefExpr(name(n)));
  top.containsErrorType = false;
  top.substDefs =
    rule on Name of
    | name(n1) when n1 == top.paramName -> name(n)
    end;
}

abstract production realConstTemplateArg
top::TemplateArg ::= c::Decorated NumericConstant
{
  propagate canonicalType;
  top.pp = c.pp;
  top.mangledName = c.mangledName;
  top.argName =
    valueTemplateArgName(
      realConstant(new(c)));
  top.containsErrorType = false;
  top.substDefs =
    rule on Expr of
    | directRefExpr(name(n1)) when n1 == top.paramName ->
      realConstant(new(c))
    | declRefExpr(name(n)) when n == top.paramName ->
      realConstant(new(c))
    end;
}

abstract production characterConstTemplateArg
top::TemplateArg ::= c::String p::CharPrefix
{
  propagate canonicalType;
  top.pp = text(c);
  top.mangledName = substring(indexOf("'", c) + 1, lastIndexOf("'", c), c);
  top.argName =
    valueTemplateArgName(
      characterConstant(c, p));
  top.containsErrorType = false;
  top.substDefs =
    rule on Expr of
    | directRefExpr(name(n1)) when n1 == top.paramName ->
      characterConstant(c, p)
    end;
}

abstract production errorTemplateArg
top::TemplateArg ::=
{
  propagate canonicalType;
  top.pp = pp"/*err*/";
  top.mangledName = "error";
  top.argName = errorTemplateArgName([]);
  top.containsErrorType = true;
  top.substDefs = fail();
}

function mkTemplatedType
Type ::= q::Qualifiers n::String args::[TemplateArg] env::Decorated Env
{
  local result::BaseTypeExpr =
    templateTypedefTypeExpr(q, name(n), foldTemplateArg(args).argNames);
  result.env = env;
  result.controlStmtContext = initialControlStmtContext;
  result.givenRefId = nothing();
  
  return result.typerep;
}
