grammar edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

abstract production templateDirectRefExpr
top::Expr ::= n::Name ts::TypeNames
{
  propagate substituted;
  top.pp = pp"${n.pp}<${ppImplode(pp", ", ts.pps)}>";
  
  ts.env = globalEnv(top.env);
  
  forwards to
    injectGlobalDeclsExpr(
      foldDecl(
        (if !null(ts.errors) then [warnDecl(ts.errors)] else []) ++
        ts.decls ++
        [templateExprInstDecl(n, ts.typereps)]),
      directRefExpr(name(templateMangledName(n.name, ts.typereps), location=top.location), location=top.location),
      location=top.location);
}

abstract production templateDirectCallExpr
top::Expr ::= n::Name ts::TypeNames a::Exprs
{
  propagate substituted;
  top.pp = pp"${n.pp}<${ppImplode(pp", ", ts.pps)}>(${ppImplode(pp", ", a.pps)})";
  
  ts.env = globalEnv(top.env);
  
  forwards to
    injectGlobalDeclsExpr(
      foldDecl(
        (if !null(ts.errors) then [warnDecl(ts.errors)] else []) ++
        ts.decls ++
        [templateExprInstDecl(n, ts.typereps)]),
      directCallExpr(name(templateMangledName(n.name, ts.typereps), location=top.location), a, location=top.location),
      location=top.location);
}

abstract production templateTypedefTypeExpr
top::BaseTypeExpr ::= q::Qualifiers n::Name ts::TypeNames
{
  propagate substituted;
  top.pp = pp"${terminate(space(), q.pps)}${n.pp}<${ppImplode(pp", ", ts.pps)}>";
  
  -- templatedType forwards to resolved (forward.typerep here), so no interference.
  top.typerep = templatedType(q, n.name, ts.typereps, forward.typerep);
  
  ts.env = globalEnv(top.env);
  
  forwards to
    injectGlobalDeclsTypeExpr(
      foldDecl(
        (if !null(ts.errors) then [warnDecl(ts.errors)] else []) ++
        ts.decls ++
        [templateTypeExprInstDecl(q, n, ts.typereps)]),
      typedefTypeExpr(q, name(templateMangledName(n.name, ts.typereps), location=builtin)));
}

abstract production templateExprInstDecl
top::Decl ::= n::Name ts::[Type]
{
  top.pp = pp"inst ${n.pp}<${ppImplode(pp", ", zipWith(cat, map((.lpp), ts), map((.rpp), ts)))}>;";
  top.substituted = top; -- Don't substitute n
  
  local templateItem::Decorated TemplateItem = n.templateItem;
  
  local localErrors::[Message] =
    if !null(n.templateLookupCheck)
    then n.templateLookupCheck
    else if !templateItem.isItemValue
    then [err(n.location, s"${n.name} is not a value")]
    else if !templateItem.isItemError && length(ts) != length(templateItem.templateParams)
    then [err(
            n.location,
            s"Wrong number of template parameters for ${n.name}, " ++
            s"expected ${toString(length(templateItem.templateParams))} but got ${toString(length(ts))}")]
    else if !null(fwrd.errors)
    then
      [nested(
         n.location,
         s"In instantiation ${n.name}<${implode(", ", map(showType, ts))}>",
         fwrd.errors)]
    else [];
  
  local mangledName::String = templateMangledName(n.name, ts);
  
  local fwrd::Decl =
    if !null(lookupValue(mangledName, top.env))
    then decls(nilDecl())
    else
      substDecl(
        zipWith(
          typedefSubstitution,
          templateItem.templateParams,
          map(directTypeExpr, ts)),
        templateItem.decl(name(mangledName, location=builtin)));
  fwrd.isTopLevel = true;
  fwrd.env = top.env;
  fwrd.returnType = nothing();
  
  forwards to
    if templateItem.isItemError || containsErrorType(ts) || !null(localErrors)
    then
      variableDecls(
        nilStorageClass(), nilAttribute(),
        errorTypeExpr(localErrors),
        consDeclarator(
          declarator(
            name(mangledName, location=builtin),
            baseTypeExpr(),
            nilAttribute(),
            nothingInitializer()),
          nilDeclarator()))
    else decDecl(fwrd);
}

abstract production templateTypeExprInstDecl
top::Decl ::= q::Qualifiers n::Name ts::[Type]
{
  top.pp = pp"inst ${terminate(space(), q.pps)}${n.pp}<${ppImplode(pp", ", zipWith(cat, map((.lpp), ts), map((.rpp), ts)))}>;";
  top.substituted = top; -- Don't substitute n
  
  local templateItem::Decorated TemplateItem = n.templateItem;
  
  local localErrors::[Message] =
    if !null(n.templateLookupCheck)
    then n.templateLookupCheck
    else if !templateItem.isItemType
    then [err(n.location, s"${n.name} is not a type")]
    else if !templateItem.isItemError && length(ts) != length(templateItem.templateParams)
    then [err(
            n.location,
            s"Wrong number of template parameters for ${n.name}, " ++
            s"expected ${toString(length(templateItem.templateParams))} but got ${toString(length(ts))}")]
    else if !null(fwrd.errors)
    then
      [nested(
         n.location,
         s"In instantiation ${n.name}<${implode(", ", map(showType, ts))}>",
         fwrd.errors)]
    else [];
  
  local mangledName::String = templateMangledName(n.name, ts);
  local mangledRefId::String = templateMangledRefId(n.name, ts);
  
  local fwrd::Decl =
    if !null(lookupValue(mangledName, top.env))
    then decls(nilDecl())
    else
      substDecl(
        refIdSubstitution(s"edu:umn:cs:melt:exts:ableC:templating:${n.name}", mangledRefId) ::
        zipWith(
          typedefSubstitution,
          templateItem.templateParams,
          map(directTypeExpr, ts)),
        templateItem.decl(name(mangledName, location=builtin)));
  fwrd.isTopLevel = true;
  fwrd.env = top.env;
  fwrd.returnType = nothing();
  
  forwards to
    if templateItem.isItemError || containsErrorType(ts) || !null(localErrors)
    then
      typedefDecls(
        nilAttribute(),
        errorTypeExpr(localErrors),
        consDeclarator(
          declarator(
            name(mangledName, location=builtin),
            baseTypeExpr(),
            nilAttribute(),
            nothingInitializer()),
          nilDeclarator()))
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
