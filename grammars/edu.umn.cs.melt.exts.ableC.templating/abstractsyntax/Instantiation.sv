grammar edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

abstract production templateDirectRefExpr
top::Expr ::= n::Name tas::TemplateArgNames
{
  top.pp = pp"${n.pp}<${ppImplode(pp", ", tas.pps)}>";
  n.env = top.env;
  
  local templateItem::TemplateItem = n.templateItem;
  tas.substEnv = fail();
  tas.paramNames = templateItem.templateParams;
  tas.paramKinds = templateItem.kinds;
  
  forwards to
    injectGlobalDeclsExpr(
      consDecl(
        decls(@tas.argDecls),
        foldDecl(
          (if null(n.templateLookupCheck) && !null(tas.errors)
          then [warnDecl(tas.errors)]
          else []) ++
          [templateExprInstDecl(^n, tas.argreps)])),
      directRefExpr(name(tas.argreps.templateMangledName(n.name))));
}

abstract production templateDirectCallExpr
top::Expr ::= n::Name tas::TemplateArgNames a::Exprs
{
  top.pp = pp"${n.pp}<${ppImplode(pp", ", tas.pps)}>(${ppImplode(pp", ", a.pps)})";
  n.env = top.env;
  
  local templateItem::TemplateItem = n.templateItem;
  tas.substEnv = fail();
  tas.paramNames = templateItem.templateParams;
  tas.paramKinds = templateItem.kinds;
  
  forwards to
    injectGlobalDeclsExpr(
      consDecl(
        decls(@tas.argDecls),
        foldDecl(
          (if null(n.templateLookupCheck) && !null(tas.errors)
          then [warnDecl(tas.errors)]
          else []) ++
          [templateExprInstDecl(^n, tas.argreps)])),
      directCallExpr(name(tas.argreps.templateMangledName(n.name)), @a));
}

abstract production templateInferredDirectCallExpr
top::Expr ::= n::Name a::Exprs
{
  top.pp = pp"${n.pp}(${ppImplode(pp", ", a.pps)})";

  propagate env, controlStmtContext;
  
  local templateItem::TemplateItem = n.templateItem;
  local inferredTemplateArguments::Maybe<TemplateArgs> =
    do {
      params::Parameters <- templateItem.maybeParameters;
      let inferredArgs::[(String, TemplateArg)] =
        decorate params with {
          env = top.env;
          controlStmtContext = top.controlStmtContext;
          position = 0;
          argumentTypes = a.typereps;
        }.inferredArgs;
      tas::[TemplateArg] <- traverseA(lookup(_, inferredArgs), templateItem.templateParams);
      return foldr(consTemplateArg, nilTemplateArg(), tas);
    };
  
  local directErrors::[Message] =
    (if !null(n.templateLookupCheck)
     then n.templateLookupCheck
     else if !templateItem.isItemValue
     then [errFromOrigin(n, s"${n.name} is not a value")]
     else []) ++
    a.errors;
  local localErrors::[Message] =
    if !null(directErrors)
    then directErrors
    else
      case inferredTemplateArguments of
      | just(ta) when !ta.containsErrorType -> []
      | _ -> [errFromOrigin(top, s"Template arguments could not be inferred for ${n.name}(${implode(", ", map(show(80, _), a.typereps))})")]
      end;
  
  local mangledName::String = inferredTemplateArguments.fromJust.templateMangledName(n.name);
  
  nondecorated local fwrd::Expr =
    injectGlobalDeclsExpr(
      foldDecl([templateExprInstDecl(^n, inferredTemplateArguments.fromJust)]),
      directCallExpr(
        name(mangledName),
        -- We can't share a here, because it needs env to compute types that are
        -- used to infer template arguments, and a.env is affected by defs from
        -- the instantiated declaration.
        -- TODO: Can we restructure things to avoid this?
        ^a));
  
  forwards to mkErrorCheck(localErrors, fwrd);
}

abstract production templateTypedefTypeExpr
top::BaseTypeExpr ::= q::Qualifiers n::Name tas::TemplateArgNames
{
  top.pp = pp"${terminate(space(), q.pps)}${n.pp}<${ppImplode(pp", ", tas.pps)}>";
  n.env = top.env;
  
  -- templatedType forwards to resolved (forward.typerep here), so no interference.
  top.typerep = templatedType(^q, n.name, tas.argreps, forward.typerep);
  
  -- Better template parameter inference, non-interfering since it's not an error if
  -- we try to infer on the forward instead.
  top.inferredArgs :=
    case top.argumentType of
    | templatedType(_, n1, _, _) ->
      if n.name == n1 then tas.inferredArgs else forwardInferredTypes
    | _ -> forwardInferredTypes
    end;
  tas.arguments =
    case top.argumentType of
    | templatedType(_, n1, args, _) -> if n.name == n1 then ^args else nilTemplateArg()
    | _ -> nilTemplateArg()
    end;
  -- Also try inferring on the transformation, if this is a templated type definition
  local templateItem::TemplateItem = n.templateItem;
  local forwardTypeName::TypeName =
    rewriteWith(
      allTopDown(tas.substDefs),
      case templateItem of
      | templateTypeTemplateItem(_, _, ty) -> new(ty)
      | _ -> error("Not a template type")
      end).fromJust;
  forwardTypeName.env = globalEnv(top.env);
  forwardTypeName.controlStmtContext = initialControlStmtContext;
  forwardTypeName.argumentType = top.argumentType;
  local forwardInferredTypes::[Pair<String TemplateArg>] =
    case templateItem of
    | templateTypeTemplateItem(_, _, _) -> forwardTypeName.inferredArgs
    | _ -> []
    end;

  tas.substEnv = fail();
  tas.paramNames = templateItem.templateParams;
  tas.paramKinds = templateItem.kinds;
  
  forwards to
    injectGlobalDeclsTypeExpr(
      consDecl(
        decls(@tas.argDecls),
        foldDecl(
          (if !null(tas.errors) then [warnDecl(tas.errors)] else []) ++
          [templateTypeExprInstDecl(^q, ^n, tas.argreps)])),
      typedefTypeExpr(^q, name(tas.argreps.templateMangledName(n.name))));
}

abstract production templateExprInstDecl
top::Decl ::= n::Name tas::TemplateArgs
{
  top.pp = pp"inst ${n.pp}<${ppImplode(pp", ", tas.pps)}>;";
  propagate env;
  
  local templateItem::TemplateItem = n.templateItem;
  
  local localErrors::[Message] =
    if !null(n.templateLookupCheck)
    then n.templateLookupCheck
    else if !templateItem.isItemValue
    then [errFromOrigin(n, s"${n.name} is not a value")]
    else if !templateItem.isItemError && tas.count != length(templateItem.templateParams)
    then [errFromOrigin(n, s"Wrong number of template arguments for ${n.name}, " ++
            s"expected ${toString(length(templateItem.templateParams))} but got ${toString(tas.count)}")]
    else if !tas.containsErrorType && !null(fwrd.errors)
    then
      [nested(
         getParsedOriginLocationOrFallback(n),
         s"In instantiation ${n.name}<${show(80, ppImplode(pp", ", tas.pps))}>",
         fwrd.errors)]
    else [];
  
  tas.paramNames = templateItem.templateParams;
  
  local mangledName::String = tas.templateMangledName(n.name);
  
  forward fwrd =
    if !null(lookupValue(mangledName, top.env))
    then decls(nilDecl())
    else
      rewriteWith(
        allTopDown(tas.substDefs),
        templateItem.decl(name(mangledName))).fromJust;
  
  forwards to
    if templateItem.isItemError || tas.containsErrorType || !null(localErrors)
    then
      variableDecls(
        nilStorageClass(), nilAttribute(),
        errorTypeExpr(localErrors),
        consDeclarator(
          declarator(
            name(mangledName),
            baseTypeExpr(),
            nilAttribute(),
            nothingInitializer()),
          nilDeclarator()))
    else @fwrd;
}

abstract production templateTypeExprInstDecl
top::Decl ::= q::Qualifiers n::Name tas::TemplateArgs
{
  top.pp = pp"inst ${terminate(space(), q.pps)}${n.pp}<${ppImplode(pp", ", tas.pps)}>;";
  propagate env;
  
  local templateItem::TemplateItem = n.templateItem;
  
  local localErrors::[Message] =
    if !null(n.templateLookupCheck)
    then n.templateLookupCheck
    else if !templateItem.isItemType
    then [errFromOrigin(n, s"${n.name} is not a type")]
    else if !templateItem.isItemError && tas.count != length(templateItem.templateParams)
    then [errFromOrigin(n, s"Wrong number of template arguments for ${n.name}, " ++
            s"expected ${toString(length(templateItem.templateParams))} but got ${toString(tas.count)}")]
    else if !tas.containsErrorType && !null(fwrd.errors)
    then
      [nested(
         getParsedOriginLocationOrFallback(n),
         s"In instantiation ${n.name}<${show(80, ppImplode(pp", ", tas.pps))}>",
         fwrd.errors)]
    else [];
  
  local mangledName::String = tas.templateMangledName(n.name);
  local mangledRefId::String = tas.templateMangledRefId(n.name);
  
  tas.paramNames = templateItem.templateParams;
  
  forward fwrd =
    if !null(lookupValue(mangledName, top.env))
    then decls(nilDecl())
    else
      rewriteWith(
        allTopDown(
          rule on Attrib of
          | appliedAttrib(attribName(name("refId")), consExpr(stringLiteral(s), nilExpr()))
            when s == s"\"edu:umn:cs:melt:exts:ableC:templating:${n.name}\"" ->
              appliedAttrib(
                attribName(name("refId")),
                consExpr(stringLiteral(s"\"${mangledRefId}\""), nilExpr()))
          end <+ tas.substDefs),
          templateItem.decl(name(mangledName))).fromJust;
  
  forwards to
    if templateItem.isItemError || tas.containsErrorType || !null(localErrors)
    then
      typedefDecls(
        nilAttribute(),
        errorTypeExpr(localErrors),
        consDeclarator(
          declarator(
            name(mangledName),
            baseTypeExpr(),
            nilAttribute(),
            nothingInitializer()),
          nilDeclarator()))
    else @fwrd;
}


translation attribute argDecls::Decls;

inherited attribute substEnv::Strategy;
synthesized attribute substDefs::Strategy;

inherited attribute paramNames::[String];
inherited attribute paramKinds::[Maybe<TypeName>];
synthesized attribute argreps::TemplateArgs;

inherited attribute arguments::TemplateArgs;

inherited attribute appendedTemplateArgNames :: TemplateArgNames;
synthesized attribute appendedTemplateArgNamesRes :: TemplateArgNames;

tracked nonterminal TemplateArgNames with pps, substEnv, paramNames, paramKinds, argreps, count, errors, argDecls, substDefs, arguments, inferredArgs, appendedTemplateArgNames, appendedTemplateArgNamesRes;
flowtype TemplateArgNames = decorate {argDecls.env, argDecls.controlStmtContext, argDecls.isTopLevel, substEnv, paramNames, paramKinds}, pps {}, count {}, argreps {decorate}, errors {decorate}, substDefs {decorate}, inferredArgs {decorate, arguments}, appendedTemplateArgNamesRes {appendedTemplateArgNames};

propagate errors, inferredArgs, appendedTemplateArgNames on TemplateArgNames;

abstract production consTemplateArgName
top::TemplateArgNames ::= h::TemplateArgName t::TemplateArgNames
{
  top.pps = h.pp :: t.pps;
  top.argreps = consTemplateArg(h.argrep, t.argreps);
  top.count = 1 + t.count;
  top.argDecls = appendDecls(@h.argDecls, @t.argDecls);
  top.substDefs =
    (if !null(top.paramNames) then ta.substDefs else fail()) <+ t.substDefs;
  top.appendedTemplateArgNamesRes = consTemplateArgName(^h, t.appendedTemplateArgNamesRes);
  
  local ta::TemplateArg = h.argrep;
  h.substEnv = top.substEnv;
  t.substEnv = ta.substDefs <+ h.substEnv;
  ta.paramName =
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
    | consTemplateArg(h, _) -> ^h
    | nilTemplateArg() -> errorTemplateArg()
    end;
  t.arguments =
    case top.arguments of
    | consTemplateArg(_, t) -> ^t
    | nilTemplateArg() -> nilTemplateArg()
    end;
}

abstract production nilTemplateArgName
top::TemplateArgNames ::=
{
  top.pps = [];
  top.argreps = nilTemplateArg();
  top.count = 0;
  top.argDecls = nilDecl();
  top.substDefs = fail();
  top.appendedTemplateArgNamesRes = top.appendedTemplateArgNames;
}

function appendTemplateArgNames
TemplateArgNames ::= p1::TemplateArgNames p2::TemplateArgNames
{
  p1.appendedTemplateArgNames = ^p2;
  return p1.appendedTemplateArgNamesRes;
}

inherited attribute paramName::String;
inherited attribute paramKind::Maybe<TypeName>;
synthesized attribute argrep::TemplateArg;

inherited attribute argument::TemplateArg;

tracked nonterminal TemplateArgName with pp, substEnv, paramKind, argrep, errors, argDecls, argument, inferredArgs;
flowtype TemplateArgName = decorate {argDecls.env, argDecls.controlStmtContext, substEnv, paramKind}, pp {}, argrep {decorate}, errors {decorate}, inferredArgs {decorate, argument};

abstract production typeTemplateArgName
top::TemplateArgName ::= ty::TypeName
{
  top.pp = ty.pp;
  top.argrep = typeTemplateArg(ty.typerep);
  top.argDecls = consDecl(typePreDecls(@ty), nilDecl());
  top.errors :=
    case top.paramKind of
    | just(_) -> [errFromOrigin(top, "Template value parameter given type argument")]
    | nothing() -> []
    end;
  
  ty.controlStmtContext = initialControlStmtContext;
  ty.argumentType =
    case top.argument of
    | typeTemplateArg(t) -> ^t
    | _ -> error("argumentType demanded when argument is not a typeTemplateArg")
    end;
  top.inferredArgs :=
    case top.argument of
    | typeTemplateArg(_) -> ty.inferredArgs
    | _ -> []
    end;
}

abstract production valueTemplateArgName
top::TemplateArgName ::= e::Expr
{
  top.pp = e.pp;
  top.argrep =
    case e of
    | declRefExpr(n) -> nameTemplateArg(n.name)
    | realConstant(c) -> realConstTemplateArg(c)
    | characterConstant(c, p) -> characterConstTemplateArg(c, ^p)
    | _ -> errorTemplateArg()
    end;
  top.argDecls = consDecl(typePreDecls(@ty), nilDecl());
  top.errors := e.errors;
  top.errors <-
    case e of
    | declRefExpr(n) -> []
    | realConstant(c) -> []
    | characterConstant(c, p) -> []
    | _ -> [errFromOrigin(e, s"Invalid template argument expression: ${show(80, e.pp)}")]
    end;

  e.env = ty.env;
  e.controlStmtContext = initialControlStmtContext;
  
  production ty::TypeName =
    rewriteWith(
      allTopDown(top.substEnv),
      fromMaybe(typeName(errorTypeExpr([]), baseTypeExpr()), top.paramKind)).fromJust;
  top.errors <-
    case top.paramKind of
    | just(_) ->
      ty.errors ++
      if typeAssignableTo(ty.typerep, e.typerep)
      then []
      else [errFromOrigin(top, s"Template value parameter expected ${show(80, ty.typerep)} but got ${show(80, e.typerep)}")]
    | nothing() -> [errFromOrigin(top, "Template type parameter given value argument")]
    end;
  top.inferredArgs :=
    case e of
    | declRefExpr(n) -> [(n.name, top.argument)]
    | _ -> []
    end;
}

abstract production errorTemplateArgName
top::TemplateArgName ::= msg::[Message]
{
  propagate inferredArgs;
  top.pp = pp"/*err*/";
  top.argrep = errorTemplateArg();
  top.argDecls = nilDecl();
  top.errors := msg;
}
