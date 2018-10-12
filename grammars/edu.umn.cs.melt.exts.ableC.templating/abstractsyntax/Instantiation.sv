grammar edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

abstract production templateDeclRefExpr
top::Expr ::= n::Name ts::TypeNames
{
  top.pp = pp"${n.pp}<${ppImplode(pp", ", ts.pps)}>";
  top.substituted = templateDeclRefExpr(n, ts.substituted, location=top.location); -- Don't substitute n
  
  ts.env = globalEnv(top.env);
  
  local decl::Decl = templateExprInstDecl(n, ts);
  decl.isTopLevel = true;
  decl.env = top.env;
  decl.returnType = nothing();
  
  local localErrors::[Message] = ts.errors ++ n.templateLookupCheck;
  local instErrors::[Message] =
    localErrors ++ 
    if !null(decl.errors)
    then
      [nested(
         top.location,
         s"In instantiation ${n.name}<${show(80, ppImplode(pp", ", ts.pps))}>",
         decl.errors)]
    else [];
  
  local fwrd::Expr =
    injectGlobalDeclsExpr(
      consDecl(decl, nilDecl()),
      declRefExpr(name(templateMangledName(n.name, ts.typereps), location=builtin), location=builtin),
      location=top.location);
  
  forwards to
    if containsErrorType(ts.typereps)
    then errorExpr(localErrors, location=top.location)
    else mkErrorCheck(instErrors, fwrd);
}

abstract production templateTypedefTypeExpr
top::BaseTypeExpr ::= q::Qualifiers n::Name ts::TypeNames
{
  top.pp = pp"${terminate(space(), q.pps)}${n.pp}<${ppImplode(pp", ", ts.pps)}>";
  top.substituted = templateTypedefTypeExpr(q, n, ts.substituted); -- Don't substitute n
  
  -- templatedType forwards to resolved (forward.typerep here), so no interference.
  top.typerep = templatedType(q, n.name, ts.typereps, forward.typerep);
  
  ts.env = globalEnv(top.env);
  
  local decl::Decl = templateTypeExprInstDecl(q, n, ts);
  decl.isTopLevel = true;
  decl.env = top.env;
  decl.returnType = nothing();
  
  local localErrors::[Message] = ts.errors ++ n.templateLookupCheck;
  local instErrors::[Message] =
    localErrors ++ 
    if !null(decl.errors)
    then
      [nested(
         n.location,
         s"In instantiation ${n.name}<${show(80, ppImplode(pp", ", ts.pps))}>",
         decl.errors)]
    else [];
  
  local fwrd::BaseTypeExpr =
    injectGlobalDeclsTypeExpr(
      consDecl(decl, nilDecl()),
      typedefTypeExpr(q, name(templateMangledName(n.name, ts.typereps), location=builtin)));
  
  forwards to
    if containsErrorType(ts.typereps)
    then errorTypeExpr(localErrors)
    else if !null(instErrors)
    then errorTypeExpr(instErrors)
    else fwrd;
}

abstract production templateExprInstDecl
top::Decl ::= n::Name ts::TypeNames
{
  top.pp = pp"${n.pp}<${ppImplode(pp", ", ts.pps)}>;";
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
    else [];
  
  local mangledName::String = templateMangledName(n.name, ts.typereps);
  
  local fwrd::Decls =
    foldDecl([
      decls(ts.unusedTypedefTrans),
      substDecl(
        zipWith(
          typedefSubstitution,
          templateItem.templateParams,
          map(directTypeExpr, ts.typereps)),
        templateItem.decl(name(mangledName, location=builtin)))]);
  
  forwards to
    if !null(lookupValue(mangledName, top.env))
    then decls(nilDecl())
    else if !null(localErrors)
    then decls(consDecl(warnDecl(localErrors), fwrd))
    else decls(fwrd);
}

abstract production templateTypeExprInstDecl
top::Decl ::= q::Qualifiers n::Name ts::TypeNames
{
  top.pp = pp"${terminate(space(), q.pps)}${n.pp}<${ppImplode(pp", ", ts.pps)}>;";
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
    else [];
  
  local mangledName::String = templateMangledName(n.name, ts.typereps);
  local mangledRefId::String = templateMangledRefId(n.name, ts.typereps);
  
  local fwrd::Decls =
    foldDecl([
      decls(ts.unusedTypedefTrans),
      substDecl(
        refIdSubstitution(s"edu:umn:cs:melt:exts:ableC:templating:${n.name}", mangledRefId) ::
        zipWith(
          typedefSubstitution,
          templateItem.templateParams,
          map(directTypeExpr, ts.typereps)),
        templateItem.decl(name(mangledName, location=builtin)))]);
  
  forwards to
    if !null(lookupValue(mangledName, top.env))
    then decls(nilDecl())
    else if !null(localErrors)
    then decls(consDecl(warnDecl(localErrors), fwrd))
    else decls(fwrd);
}

-- type parameters should be included literally in the forward tree exactly once
-- Generate phony typedefs instead of typeExprDecls to avoid gcc warnings
synthesized attribute unusedTypedefTrans::Decls occurs on TypeNames;

aspect production consTypeName
top::TypeNames ::= h::TypeName t::TypeNames
{
  top.unusedTypedefTrans =
    consDecl(
      typedefDecls(
        nilAttribute(), h.bty,
        consDeclarator(
          declarator(
            name(s"_template_param_unused_${toString(genInt())}", location=builtin),
            h.mty,
            nilAttribute(),
            nothingInitializer()),
          nilDeclarator())),
      t.unusedTypedefTrans);
}

aspect production nilTypeName
top::TypeNames ::=
{
  top.unusedTypedefTrans = nilDecl();
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
