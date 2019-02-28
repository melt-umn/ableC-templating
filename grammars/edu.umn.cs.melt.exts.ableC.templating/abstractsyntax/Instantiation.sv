grammar edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

import core:monad;

abstract production templateDirectRefExpr
top::Expr ::= n::Name tas::TemplateArgNames
{
  propagate substituted;
  top.pp = pp"${n.pp}<${ppImplode(pp", ", tas.pps)}>";
  
  local templateItem::Decorated TemplateItem = n.templateItem;
  tas.env = globalEnv(top.env);
  tas.substEnv = [];
  tas.paramNames = templateItem.templateParams;
  tas.paramKinds = templateItem.kinds;
  
  forwards to
    injectGlobalDeclsExpr(
      foldDecl(
        (if null(n.templateLookupCheck) && !null(tas.errors)
         then [warnDecl(tas.errors)]
         else []) ++
        tas.decls ++
        [templateExprInstDecl(n, tas.argreps)]),
      directRefExpr(name(templateMangledName(n.name, tas.argreps), location=top.location), location=top.location),
      location=top.location);
}

abstract production templateDirectCallExpr
top::Expr ::= n::Name tas::TemplateArgNames a::Exprs
{
  propagate substituted;
  top.pp = pp"${n.pp}<${ppImplode(pp", ", tas.pps)}>(${ppImplode(pp", ", a.pps)})";
  
  local templateItem::Decorated TemplateItem = n.templateItem;
  tas.env = globalEnv(top.env);
  tas.substEnv = [];
  tas.paramNames = templateItem.templateParams;
  tas.paramKinds = templateItem.kinds;
  
  forwards to
    injectGlobalDeclsExpr(
      foldDecl(
        (if null(n.templateLookupCheck) && !null(tas.errors)
         then [warnDecl(tas.errors)]
         else []) ++
        tas.decls ++
        [templateExprInstDecl(n, tas.argreps)]),
      directCallExpr(name(templateMangledName(n.name, tas.argreps), location=top.location), a, location=top.location),
      location=top.location);
}

abstract production templateInferredDirectCallExpr
top::Expr ::= n::Name a::Exprs
{
  propagate substituted;
  top.pp = pp"${n.pp}(${ppImplode(pp", ", a.pps)})";
  
  local templateItem::Decorated TemplateItem = n.templateItem;
  local inferredTypeArguments::Maybe<TemplateArgs> =
    do (bindMaybe, returnMaybe) {
      params::Parameters <- templateItem.maybeParameters;
      inferredArgs::[Pair<String TemplateArg>] =
        decorate params with {
          env = top.env;
          returnType = top.returnType;
          position = 0;
          argumentTypes = a.typereps;
        }.inferredArgs;
      tas::[TemplateArg] <- lookupAll(inferredArgs, templateItem.templateParams);
      return foldr(consTemplateArg, nilTemplateArg(), tas);
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
    else if !inferredTypeArguments.isJust || inferredTypeArguments.fromJust.containsErrorType
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
top::BaseTypeExpr ::= q::Qualifiers n::Name tas::TemplateArgNames
{
  propagate substituted;
  top.pp = pp"${terminate(space(), q.pps)}${n.pp}<${ppImplode(pp", ", tas.pps)}>";
  
  -- templatedType forwards to resolved (forward.typerep here), so no interference.
  top.typerep = templatedType(q, n.name, tas.argreps, forward.typerep);
  
  -- Better template parameter inference, non-interfering since it's not an error if
  -- we try to infer on the forward instead.
  top.inferredArgs =
    case top.argumentType of
    | templatedType(_, n1, _, _) ->
      if n.name == n1 then tas.inferredArgs else forwardInferredTypes
    | _ -> forwardInferredTypes
    end;
  tas.arguments =
    case top.argumentType of
    | templatedType(_, n1, args, _) -> if n.name == n1 then args else nilTemplateArg()
    | _ -> nilTemplateArg()
    end;
  -- Also try inferring on the transformation, if this is a templated type definition
  local templateItem::Decorated TemplateItem = n.templateItem;
  local forwardTypeName::TypeName =
    substTypeName(
      tas.substDefs,
      case templateItem of templateTypeTemplateItem(_, _, _, ty) -> ty end);
  forwardTypeName.env = globalEnv(top.env);
  forwardTypeName.returnType = nothing();
  forwardTypeName.argumentType = top.argumentType;
  local forwardInferredTypes::[Pair<String TemplateArg>] =
    case templateItem of
    | templateTypeTemplateItem(_, _, _, _) -> forwardTypeName.inferredArgs
    | _ -> []
    end;
  
  tas.env = globalEnv(top.env);
  tas.substEnv = [];
  tas.paramNames = templateItem.templateParams;
  tas.paramKinds = templateItem.kinds;
  
  forwards to
    injectGlobalDeclsTypeExpr(
      foldDecl(
        (if !null(tas.errors) then [warnDecl(tas.errors)] else []) ++
        tas.decls ++
        [templateTypeExprInstDecl(q, n, tas.argreps)]),
      typedefTypeExpr(q, name(templateMangledName(n.name, tas.argreps), location=builtin)));
}

abstract production templateExprInstDecl
top::Decl ::= n::Name tas::TemplateArgs
{
  top.pp = pp"inst ${n.pp}<${ppImplode(pp", ", tas.pps)}>;";
  top.substituted = top; -- Don't substitute n
  
  local templateItem::Decorated TemplateItem = n.templateItem;
  
  local localErrors::[Message] =
    if !null(n.templateLookupCheck)
    then n.templateLookupCheck
    else if !templateItem.isItemValue
    then [err(n.location, s"${n.name} is not a value")]
    else if !templateItem.isItemError && tas.count != length(templateItem.templateParams)
    then [err(
            n.location,
            s"Wrong number of template parameters for ${n.name}, " ++
            s"expected ${toString(length(templateItem.templateParams))} but got ${toString(tas.count)}")]
    else if !tas.containsErrorType && !null(fwrd.errors)
    then
      [nested(
         n.location,
         s"In instantiation ${n.name}<${show(80, ppImplode(pp", ", tas.pps))}>",
         fwrd.errors)]
    else [];
  
  tas.paramNames = templateItem.templateParams;
  
  local mangledName::String = templateMangledName(n.name, tas);
  
  local fwrd::Decl =
    if !null(lookupValue(mangledName, top.env))
    then decls(nilDecl())
    else substDecl(tas.substDefs, templateItem.decl(name(mangledName, location=builtin)));
  fwrd.isTopLevel = true;
  fwrd.env = top.env;
  fwrd.returnType = nothing();
  
  forwards to
    if templateItem.isItemError || tas.containsErrorType || !null(localErrors)
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
top::Decl ::= q::Qualifiers n::Name tas::TemplateArgs
{
  top.pp = pp"inst ${terminate(space(), q.pps)}${n.pp}<${ppImplode(pp", ", tas.pps)}>;";
  top.substituted = top; -- Don't substitute n
  
  local templateItem::Decorated TemplateItem = n.templateItem;
  
  local localErrors::[Message] =
    if !null(n.templateLookupCheck)
    then n.templateLookupCheck
    else if !templateItem.isItemType
    then [err(n.location, s"${n.name} is not a type")]
    else if !templateItem.isItemError && tas.count != length(templateItem.templateParams)
    then [err(
            n.location,
            s"Wrong number of template parameters for ${n.name}, " ++
            s"expected ${toString(length(templateItem.templateParams))} but got ${toString(tas.count)}")]
    else if !tas.containsErrorType && !null(fwrd.errors)
    then
      [nested(
         n.location,
         s"In instantiation ${n.name}<${show(80, ppImplode(pp", ", tas.pps))}>",
         fwrd.errors)]
    else [];
  
  local mangledName::String = templateMangledName(n.name, tas);
  local mangledRefId::String = templateMangledRefId(n.name, tas);
  
  tas.paramNames = templateItem.templateParams;
  
  local fwrd::Decl =
    if !null(lookupValue(mangledName, top.env))
    then decls(nilDecl())
    else
      substDecl(
        refIdSubstitution(s"edu:umn:cs:melt:exts:ableC:templating:${n.name}", mangledRefId) ::
        tas.substDefs,
        templateItem.decl(name(mangledName, location=builtin)));
  fwrd.isTopLevel = true;
  fwrd.env = top.env;
  fwrd.returnType = nothing();
  
  forwards to
    if templateItem.isItemError || tas.containsErrorType || !null(localErrors)
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


autocopy attribute substEnv::[Substitution];
synthesized attribute substDefs::[Substitution];

inherited attribute paramNames::[String];
inherited attribute paramKinds::[Maybe<TypeName>];
synthesized attribute argreps::TemplateArgs;

inherited attribute arguments::TemplateArgs;

nonterminal TemplateArgNames with pps, env, substEnv, paramNames, paramKinds, argreps, count, errors, decls, defs, substDefs, arguments, inferredArgs, substituted<TemplateArgNames>, substitutions;

abstract production consTemplateArgName
top::TemplateArgNames ::= h::TemplateArgName t::TemplateArgNames
{
  propagate substituted;
  top.pps = h.pp :: t.pps;
  top.argreps = consTemplateArg(h.argrep, t.argreps);
  top.count = 1 + t.count;
  top.errors := h.errors ++ t.errors;
  top.decls = h.decls ++ t.decls;
  top.defs := h.defs ++ t.defs;
  top.substDefs = ta.substDefs ++ t.substDefs;
  top.inferredArgs = h.inferredArgs ++ t.inferredArgs;
  
  local ta::TemplateArg = h.argrep;
  ta.paramName = h.paramName;
  
  t.env = addEnv(h.defs, h.env);
  t.substEnv = ta.substDefs ++ h.substEnv;
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
  h.paramKind =
    case top.paramKinds of
    | h :: _ -> h
    | [] -> nothing()
    end;
  t.paramKinds =
    case top.paramKinds of
    | _ :: t -> t
    | [] -> []
    end;
  h.argument =
    case top.arguments of
    | consTemplateArg(h, _) -> h
    | nilTemplateArg() -> errorTemplateArg()
    end;
  t.arguments =
    case top.arguments of
    | consTemplateArg(_, t) -> t
    | nilTemplateArg() -> nilTemplateArg()
    end;
}

abstract production nilTemplateArgName
top::TemplateArgNames ::=
{
  propagate substituted;
  top.pps = [];
  top.argreps = nilTemplateArg();
  top.count = 0;
  top.errors := [];
  top.decls = [];
  top.defs := [];
  top.substDefs = [];
  top.inferredArgs = [];
}

inherited attribute paramName::String;
inherited attribute paramKind::Maybe<TypeName>;
synthesized attribute argrep::TemplateArg;

inherited attribute argument::TemplateArg;

nonterminal TemplateArgName with pp, env, substEnv, paramName, paramKind, argrep, errors, decls, defs, argument, inferredArgs, substituted<TemplateArgName>, substitutions, location;

abstract production typeTemplateArgName
top::TemplateArgName ::= ty::TypeName
{
  propagate substituted;
  top.pp = pp"typename ${ty.pp}";
  top.argrep = typeTemplateArg(ty.typerep);
  top.errors := ty.errors;
  top.errors <-
    case top.paramKind of
    | just(_) -> [err(top.location, "Template value parameter given type argument")]
    | nothing() -> []
    end;
  top.decls = ty.decls;
  top.defs := ty.defs;
  
  ty.returnType = nothing();
  ty.argumentType =
    case top.argument of
    | typeTemplateArg(t) -> t
    end;
  top.inferredArgs =
    case top.argument of
    | typeTemplateArg(_) -> ty.inferredArgs
    | _ -> []
    end;
}

abstract production nameTemplateArgName
top::TemplateArgName ::= n::Name
{
  propagate substituted;
  top.pp = n.pp;
  top.argrep = nameTemplateArg(n.name);
  top.errors := n.valueLookupCheck;
  
  local ty::TypeName = substTypeName(top.substEnv, top.paramKind.fromJust);
  ty.env = top.env;
  ty.returnType = nothing();
  top.errors <-
    case top.paramKind of
    | just(_) ->
      ty.errors ++
      if typeAssignableTo(ty.typerep, n.valueItem.typerep)
      then []
      else [err(top.location, s"Template value parameter expected ${showType(ty.typerep)} but got ${showType(n.valueItem.typerep)}")]
    | nothing() -> [err(top.location, "Template type parameter given value argument")]
    end;
  top.decls = ty.decls;
  top.defs := ty.defs;
  top.inferredArgs = [pair(n.name, top.argument)];
}

abstract production errorTemplateArgName
top::TemplateArgName ::= msg::[Message]
{
  propagate substituted;
  top.pp = pp"/*err*/";
  top.argrep = errorTemplateArg();
  top.errors := msg;
  top.decls = [];
  top.defs := [];
  top.inferredArgs = [];
}

function templateMangledName
String ::= n::String params::TemplateArgs
{
  return s"_template_${n}_${params.mangledName}";
}

function templateMangledRefId
String ::= n::String params::TemplateArgs
{
  return s"edu:umn:cs:melt:exts:ableC:templating:${templateMangledName(n, params)}";
}

function lookupAll
Maybe<[a]> ::= env::[Pair<String a>] ns::[String]
{
  return
    foldr(
      bindMaybeSwapped, returnMaybe([]),
      map(
        \ n::String ->
          \ rest::[a] ->
            do (bindMaybe, returnMaybe) {
              x :: a <- lookupBy(stringEq, n, env);
              return x :: rest;
            },
        ns));
}

-- Bind paramters are backwards, ugh.
function bindMaybeSwapped
Maybe<b> ::= x::(Maybe<b> ::= a) y::Maybe<a>
{
  return bindMaybe(y, x);
}

