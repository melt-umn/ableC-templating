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
    | _ -> templateTypedefTypeExpr(q, name(n, location=builtin), args.argNames)
    end;
  top.typeModifierExpr = baseTypeExpr();
  top.canonicalType =
    templatedType(q, n, args.canonicalArgs, resolved.canonicalType);
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
synthesized attribute canonicalArgs::TemplateArgs;
synthesized attribute containsErrorType::Boolean;

nonterminal TemplateArgs with pps, mangledName, count, argNames, paramNames, canonicalArgs, containsErrorType, substDefs;

abstract production consTemplateArg
top::TemplateArgs ::= h::TemplateArg t::TemplateArgs
{
  propagate canonicalArgs;
  top.pps = h.pp :: t.pps;
  top.mangledName = h.mangledName ++ "_" ++ t.mangledName;
  top.count = 1 + t.count;
  top.argNames = consTemplateArgName(h.argName, t.argNames);
  top.containsErrorType = h.containsErrorType || t.containsErrorType;
  top.substDefs = h.substDefs ++ t.substDefs;
  
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
  propagate canonicalArgs;
  top.pps = [];
  top.mangledName = "";
  top.count = 0;
  top.argNames = nilTemplateArgName();
  top.containsErrorType = false;
  top.substDefs = [];
}

global foldTemplateArg::(TemplateArgs ::= [TemplateArg]) =
  foldr(consTemplateArg, nilTemplateArg(), _);

synthesized attribute argName::TemplateArgName;
synthesized attribute canonicalArg::TemplateArg;

nonterminal TemplateArg with pp, mangledName, argName, paramName, canonicalArg, containsErrorType, substDefs;

abstract production typeTemplateArg
top::TemplateArg ::= t::Type
{
  top.pp = pp"typename ${t.lpp}${t.rpp}";
  top.mangledName = t.mangledName;
  top.argName = typeTemplateArgName(typeName(directTypeExpr(t), baseTypeExpr()), location=builtin);
  top.canonicalArg = typeTemplateArg(t.canonicalType);
  top.containsErrorType = case t of errorType() -> true | _ -> false end;
  top.substDefs = [typedefSubstitution(top.paramName, directTypeExpr(t))];
}

abstract production nameTemplateArg
top::TemplateArg ::= n::String
{
  propagate canonicalArg;
  top.pp = text(n);
  top.mangledName = n;
  top.argName =
    valueTemplateArgName(
      declRefExpr(name(n, location=builtin), location=builtin),
      location=builtin);
  top.containsErrorType = false;
  top.substDefs =
    [declRefSubstitution(top.paramName, declRefExpr(name(n, location=builtin), location=builtin))];
}

abstract production realConstTemplateArg
top::TemplateArg ::= c::Decorated NumericConstant
{
  propagate canonicalArg;
  top.pp = c.pp;
  top.mangledName = c.mangledName;
  top.argName =
    valueTemplateArgName(
      realConstant(new(c), location=builtin),
      location=builtin);
  top.containsErrorType = false;
  top.substDefs =
    [declRefSubstitution(top.paramName, realConstant(new(c), location=builtin))];
}

abstract production characterConstTemplateArg
top::TemplateArg ::= c::String p::CharPrefix
{
  propagate canonicalArg;
  top.pp = text(c);
  top.mangledName = substring(indexOf("'", c) + 1, lastIndexOf("'", c), c);
  top.argName =
    valueTemplateArgName(
      characterConstant(c, p, location=builtin),
      location=builtin);
  top.containsErrorType = false;
  top.substDefs =
    [declRefSubstitution(top.paramName, characterConstant(c, p, location=builtin))];
}

abstract production errorTemplateArg
top::TemplateArg ::=
{
  propagate canonicalArg;
  top.pp = pp"/*err*/";
  top.mangledName = "error";
  top.argName = errorTemplateArgName([], location=builtin);
  top.containsErrorType = true;
  top.substDefs = [];
}

function mkTemplatedType
Type ::= q::Qualifiers n::String args::[TemplateArg] env::Decorated Env
{
  local result::BaseTypeExpr =
    templateTypedefTypeExpr(q, name(n, location=builtin), foldTemplateArg(args).argNames);
  result.env = env;
  result.returnType = nothing();
  result.givenRefId = nothing();
  
  return result.typerep;
}
