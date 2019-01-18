grammar edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

import core:monad;

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

abstract production templateInferredDirectCallExpr
top::Expr ::= n::Name a::Exprs
{
  propagate substituted;
  top.pp = pp"${n.pp}(${ppImplode(pp", ", a.pps)})";
  
  local templateItem::Decorated TemplateItem = n.templateItem;
  local inferredTypeArguments::Maybe<[Type]> =
    do (bindMaybe, returnMaybe) {
      params::Parameters <- templateItem.maybeParameters;
      inferredTypes::[Pair<String Type>] =
        decorate params with {
          env = top.env;
          returnType = top.returnType;
          position = 0;
          argumentTypes = a.typereps;
        }.inferredTypes;
      foldr(
        bindMaybeSwapped, returnMaybe([]),
        map(
          \ n::String ->
            \ rest::[Type] ->
              do (bindMaybe, returnMaybe) {
                t :: Type <- lookupBy(stringEq, n, inferredTypes);
                return t :: rest;
              },
          templateItem.templateParams));
    };
  
  local directErrors::[Message] =
    (if !null(n.templateLookupCheck)
     then n.templateLookupCheck
     else if !templateItem.isItemValue
     then [err(n.location, s"${n.name} is not a value")]
     else []) ++
    a.errors;
  local localErrors::[Message] =
    if !null(directErrors)
    then directErrors
    else if !inferredTypeArguments.isJust || containsErrorType(inferredTypeArguments.fromJust)
    then
      [err(
         top.location,
         s"Template argument inference failed for ${n.name}(${implode(", ", map(showType, a.typereps))})")]
    else [];
  
  local mangledName::String = templateMangledName(n.name, inferredTypeArguments.fromJust);
  
  local fwrd::Expr =
    injectGlobalDeclsExpr(
      foldDecl([templateExprInstDecl(n, inferredTypeArguments.fromJust)]),
      directCallExpr(
        name(mangledName, location=top.location),
        -- TODO: Avoid re-decorating any element of a that doesn't lift global decls also defined
        -- in this instantiation.
        a,
        location=top.location),
      location=top.location);
  
  forwards to mkErrorCheck(localErrors, fwrd);
}

abstract production templateTypedefTypeExpr
top::BaseTypeExpr ::= q::Qualifiers n::Name ts::TypeNames
{
  propagate substituted;
  top.pp = pp"${terminate(space(), q.pps)}${n.pp}<${ppImplode(pp", ", ts.pps)}>";
  
  -- templatedType forwards to resolved (forward.typerep here), so no interference.
  top.typerep = templatedType(q, n.name, ts.typereps, forward.typerep);
  
  -- Better template parameter inference, non-interfering since it's not an error if
  -- we try to infer on the forward instead.
  top.inferredTypes =
    case top.argumentType of
    | templatedType(_, n1, _, _) ->
      if n.name == n1 then ts.inferredTypes else forwardInferredTypes
    | _ -> forwardInferredTypes
    end;
  ts.argumentTypes =
    case top.argumentType of
    | templatedType(_, n1, args, _) -> if n.name == n1 then args else []
    | _ -> []
    end;
  -- Also try inferring on the transformation, if this is a templated type definition
  local templateItem::Decorated TemplateItem = n.templateItem;
  local forwardTypeName::TypeName =
    substTypeName(
      zipWith(
        typedefSubstitution,
        templateItem.templateParams,
        map(directTypeExpr, ts.typereps)),
      case templateItem of templateTypeTemplateItem(_, _, ty) -> ty end);
  forwardTypeName.env = globalEnv(top.env);
  forwardTypeName.returnType = nothing();
  forwardTypeName.argumentType = top.argumentType;
  local forwardInferredTypes::[Pair<String Type>] =
    case templateItem of
    | templateTypeTemplateItem(_, _, _) -> forwardTypeName.inferredTypes
    | _ -> []
    end;
  
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
    else if !containsErrorType(ts) && !null(fwrd.errors)
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
    else if !containsErrorType(ts) && !null(fwrd.errors)
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

-- Bind paramters are backwards, ugh.
function bindMaybeSwapped
Maybe<b> ::= x::(Maybe<b> ::= a) y::Maybe<a>
{
  return bindMaybe(y, x);
}

