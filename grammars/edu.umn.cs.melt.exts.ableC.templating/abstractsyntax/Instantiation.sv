grammar edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

abstract production templateDirectRefExpr
top::Expr ::= n::Name ts::TypeNames
{
  propagate substituted;
  top.pp = pp"${n.pp}<${ppImplode(pp", ", ts.pps)}>";
  
  forwards to
    injectGlobalDeclsExpr(
      consDecl(templateExprInstDecl(n, ts), nilDecl()),
      templateInstDirectRefExpr(n, ts, location=top.location),
      location=top.location);
}

abstract production templateDirectCallExpr
top::Expr ::= n::Name ts::TypeNames a::Exprs
{
  propagate substituted;
  top.pp = pp"${n.pp}<${ppImplode(pp", ", ts.pps)}>(${ppImplode(pp", ", a.pps)})";
  
  forwards to
    injectGlobalDeclsExpr(
      consDecl(templateExprInstDecl(n, ts), nilDecl()),
      templateInstDirectCallExpr(n, ts, a, location=top.location),
      location=top.location);
}

abstract production templateTypedefTypeExpr
top::BaseTypeExpr ::= q::Qualifiers n::Name ts::TypeNames
{
  propagate substituted;
  top.pp = pp"${terminate(space(), q.pps)}${n.pp}<${ppImplode(pp", ", ts.pps)}>";
  
  -- templatedType forwards to resolved (forward.typerep here), so no interference.
  top.typerep = templatedType(q, n.name, ts.typereps, forward.typerep);
  
  forwards to
    injectGlobalDeclsTypeExpr(
      consDecl(templateTypeExprInstDecl(q, n, ts), nilDecl()),
      templateInstTypedefTypeExpr(q, n, ts));
}

-- These are needed to compute the mangled name in the env containing defs from
-- the instantiation, to avoid redecorating the type arguments and regenerating
-- refIds, etc.
abstract production templateInstDirectRefExpr
top::Expr ::= n::Name ts::TypeNames
{
  propagate substituted;
  top.pp = pp"ref ${n.pp}<${ppImplode(pp", ", ts.pps)}>";
  forwards to
    directRefExpr(name(templateMangledName(n.name, ts.typereps), location=top.location), location=top.location);
}

abstract production templateInstDirectCallExpr
top::Expr ::= n::Name ts::TypeNames a::Exprs
{
  propagate substituted;
  top.pp = pp"${n.pp}<${ppImplode(pp", ", ts.pps)}>(${ppImplode(pp", ", a.pps)})";
  forwards to
    directCallExpr(name(templateMangledName(n.name, ts.typereps), location=top.location), a, location=top.location);
}

abstract production templateInstTypedefTypeExpr
top::BaseTypeExpr ::= q::Qualifiers n::Name ts::TypeNames
{
  propagate substituted;
  top.pp = pp"${terminate(space(), q.pps)}${n.pp}<${ppImplode(pp", ", ts.pps)}>";
  forwards to
    typedefTypeExpr(q, name(templateMangledName(n.name, ts.typereps), location=builtin));
}

abstract production templateExprInstDecl
top::Decl ::= n::Name ts::TypeNames
{
  top.pp = pp"inst ${n.pp}<${ppImplode(pp", ", ts.pps)}>;";
  top.substituted = templateExprInstDecl(n, ts.substituted); -- Don't substitute n
  
  local templateItem::Decorated TemplateItem = n.templateItem;
  
  local localErrors::[Message] =
    ts.errors ++
    if !null(n.templateLookupCheck)
    then n.templateLookupCheck
    else if !templateItem.isItemValue
    then [err(n.location, s"${n.name} is not a value")]
    else if ts.count != length(templateItem.templateParams)
    then [err(
            n.location,
            s"Wrong number of template parameters for ${n.name}, " ++
            s"expected ${toString(length(templateItem.templateParams))} but got ${toString(ts.count)}")]
    else if !null(fwrd.errors)
    then
      [nested(
         n.location,
         s"In instantiation ${n.name}<${show(80, ppImplode(pp", ", ts.pps))}>",
         fwrd.errors)]
    else [];
  
  local mangledName::String = templateMangledName(n.name, ts.typereps);
  
  local fwrd::Decl =
    decls(
      foldDecl(
        ts.decls ++
        if !null(lookupValue(mangledName, top.env))
        then []
        else
          [substDecl(
             zipWith(
               typedefSubstitution,
               templateItem.templateParams,
               map(directTypeExpr, ts.typereps)),
             templateItem.decl(name(mangledName, location=builtin)))]));
  fwrd.isTopLevel = true;
  fwrd.env = top.env;
  fwrd.returnType = nothing();
  
  forwards to
    if containsErrorType(ts.typereps) || !null(localErrors)
    then
      decls(
        foldDecl(
          ts.decls ++
          [variableDecls(
             nilStorageClass(), nilAttribute(),
             errorTypeExpr(localErrors),
             consDeclarator(
               declarator(name(mangledName, location=builtin), baseTypeExpr(), nilAttribute(), nothingInitializer()),
               nilDeclarator()))]))
    else decDecl(fwrd);
}

abstract production templateTypeExprInstDecl
top::Decl ::= q::Qualifiers n::Name ts::TypeNames
{
  top.pp = pp"inst ${terminate(space(), q.pps)}${n.pp}<${ppImplode(pp", ", ts.pps)}>;";
  top.substituted = templateTypeExprInstDecl(q, n, ts.substituted); -- Don't substitute n
  
  local templateItem::Decorated TemplateItem = n.templateItem;
  
  local localErrors::[Message] =
    ts.errors ++
    if !null(n.templateLookupCheck)
    then n.templateLookupCheck
    else if !templateItem.isItemType
    then [err(n.location, s"${n.name} is not a type")]
    else if ts.count != length(templateItem.templateParams)
    then [err(
            n.location,
            s"Wrong number of template parameters for ${n.name}, " ++
            s"expected ${toString(length(templateItem.templateParams))} but got ${toString(ts.count)}")]
    else if !null(fwrd.errors)
    then
      [nested(
         n.location,
         s"In instantiation ${n.name}<${show(80, ppImplode(pp", ", ts.pps))}>",
         fwrd.errors)]
    else [];
  
  local mangledName::String = templateMangledName(n.name, ts.typereps);
  local mangledRefId::String = templateMangledRefId(n.name, ts.typereps);
  
  local fwrd::Decl =
    decls(
      foldDecl(
        ts.decls ++
        if !null(lookupValue(mangledName, top.env))
        then []
        else
          [substDecl(
             refIdSubstitution(s"edu:umn:cs:melt:exts:ableC:templating:${n.name}", mangledRefId) ::
             zipWith(
               typedefSubstitution,
               templateItem.templateParams,
               map(directTypeExpr, ts.typereps)),
             templateItem.decl(name(mangledName, location=builtin)))]));
  fwrd.isTopLevel = true;
  fwrd.env = top.env;
  fwrd.returnType = nothing();
  
  forwards to
    if containsErrorType(ts.typereps) || !null(localErrors)
    then
      decls(
        foldDecl(
          ts.decls ++
          [typedefDecls(
             nilAttribute(),
             errorTypeExpr(localErrors),
             consDeclarator(
               declarator(
                 name(mangledName, location=builtin),
                 baseTypeExpr(),
                 nilAttribute(),
                 nothingInitializer()),
               nilDeclarator()))]))
    else decDecl(fwrd);
}

function templateMangledName
String ::= n::String params::[Type]
{
  return s"_template_${n}_${implode("_", map((.mangledName), params))}";
}

function templateMangledRefId
String ::= n::String params::[Type]
{
  return s"edu:umn:cs:melt:exts:ableC:templating:${templateMangledName(n, params)}";
}

function containsErrorType
Boolean ::= ts::[Type]
{
  return
    foldr(
      \ a::Boolean b::Boolean -> a || b, false,
      map(\ t::Type -> case t of errorType() -> true | _ -> false end, ts));
}
