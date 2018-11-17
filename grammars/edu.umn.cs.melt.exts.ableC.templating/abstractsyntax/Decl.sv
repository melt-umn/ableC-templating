grammar edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

imports silver:langutil;
imports silver:langutil:pp;

imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;
imports edu:umn:cs:melt:ableC:abstractsyntax:overloadable;
imports edu:umn:cs:melt:ableC:abstractsyntax:substitution;

global builtin::Location = builtinLoc("templating");

abstract production templateTypeDecl
top::Decl ::= params::Names n::Name ty::TypeName
{
  propagate substituted;
  top.pp = pp"using ${n.pp}<${ppImplode(text(", "), params.pps)}> = ${ty.pp};";
  
  local localErrors::[Message] =
    if !top.isTopLevel
    then [err(n.location, "Template declarations must be global")]
    else n.templateRedeclarationCheck ++ params.typeParameterErrors;
  
  local fwrd::Decl =
    defsDecl([
      templateDef(
        n.name,
        templateItem(
          true, false, n.location, params.names,
          \ mangledName::Name ->
            typedefDecls(
              nilAttribute(),
              ty.bty,
              consDeclarator(
                declarator(mangledName, ty.mty, nilAttribute(), nothingInitializer()),
                nilDeclarator()))))]);
  
  forwards to
    if !null(localErrors)
    then decls(consDecl(warnDecl(localErrors), consDecl(fwrd, nilDecl())))
    else fwrd;
}

abstract production templateStructDecl
top::Decl ::= params::Names attrs::Attributes n::Name dcls::StructItemList
{
  propagate substituted;
  top.pp = ppConcat([
    pp"template<", ppImplode(text(", "), params.pps), pp">", line(),
    pp"struct ", ppAttributes(attrs), text(n.name), space(),
    braces(nestlines(2, terminate(cat(semi(),line()), dcls.pps))), semi()]);
  
  local localErrors::[Message] =
    if !top.isTopLevel
    then [err(n.location, "Template declarations must be global")]
    else n.templateRedeclarationCheck ++ params.typeParameterErrors;
  
  local fwrd::Decl =
    defsDecl([
      templateDef(
        n.name,
        templateItem(
          true, false, n.location, params.names,
          \ mangledName::Name ->
            decls(
              foldDecl([
                -- maybeDecl {typedef __attribute__((refId("edu:umn:cs:melt:exts:ableC:templating:__name__"))) struct __name__ __name__;}
                typedefDecls(
                  consAttribute(
                    gccAttribute(
                      consAttrib(
                        appliedAttrib(
                          attribName(name("refId", location=builtin)),
                          consExpr(
                            stringLiteral(s"\"edu:umn:cs:melt:exts:ableC:templating:${mangledName.name}\"", location=builtin),
                            nilExpr())),
                        nilAttrib())),
                    nilAttribute()),
                  tagReferenceTypeExpr(nilQualifier(), structSEU(), mangledName),
                  consDeclarator(
                    declarator(mangledName, baseTypeExpr(), nilAttribute(), nothingInitializer()),
                    nilDeclarator())),
                -- Defer the struct declaration until all components are complete types
                deferredStructDecl(attrs, mangledName, dcls)]))))]);
  
  forwards to
    if !null(localErrors)
    then decls(consDecl(warnDecl(localErrors), consDecl(fwrd, nilDecl())))
    else fwrd;
}

abstract production deferredStructDecl
top::Decl ::= attrs::Attributes n::Name dcls::StructItemList
{
  propagate substituted;
  top.pp = ppConcat([
    pp"deferred struct ", ppAttributes(attrs), text(n.name), space(),
    braces(nestlines(2, terminate(cat(semi(),line()), dcls.pps))), semi()]);
  
  -- Global environment also containing global defs from dcls
  local augmentedGlobalEnv::Decorated Env =
    addEnv(foldr(consDefs, nilDefs(), dcls.defs).globalDefs, globalEnv(top.env));
  
  forwards to
    foldr(
      deferredDecl,
      -- Only declare the struct if it doesn't already have a definition
      maybeDecl(
        \ env::Decorated Env ->
          null(lookupRefId(decorate n with {env = env;}.tagRefId, env)),
        -- struct __name__ { ... };
        typeExprDecl(
          nilAttribute(),
          structTypeExpr(
            nilQualifier(),
            structDecl(attrs, justName(n), dcls, location=n.location)))),
      filter(
        \ refId::String -> null(lookupRefId(refId, augmentedGlobalEnv)),
        catMaybes(
          map(
            \ c::Pair<String ValueItem> -> c.snd.typerep.maybeRefId,
            foldr(consDefs, nilDefs(), dcls.localDefs).valueContribs))));
}

abstract production templateFunctionDecl
top::Decl ::= params::Names d::FunctionDecl
{
  propagate substituted;
  top.pp = ppConcat([pp"template<", ppImplode(text(", "), params.pps), pp">", line(), d.pp]);
  
  local localErrors::[Message] =
    case d of
      functionDecl(_, _, _, _, n, _, _, _) -> 
        if !top.isTopLevel
        then [err(n.location, "Template declarations must be global")]
        else n.templateRedeclarationCheck ++ params.typeParameterErrors
      | badFunctionDecl(msg) -> msg
      end;
  
  local fwrd::Decl =
    defsDecl(
      [templateDef(
         d.name,
         templateItem(
           false, false, d.sourceLocation, params.names,
           instFunctionDeclaration(_, d)))]);
  
  forwards to
    if !null(localErrors)
    then decls(consDecl(warnDecl(localErrors), consDecl(fwrd, nilDecl())))
    else fwrd;
}

abstract production instFunctionDeclaration
top::Decl ::= mangledName::Name decl::FunctionDecl
{
  propagate substituted;
  top.pp = pp"inst_decl ${decl.pp}";
  
  decl.givenMangledName = mangledName;
  forwards to decl.instFunctionDecl;
}

inherited attribute givenMangledName::Name occurs on FunctionDecl;
synthesized attribute instFunctionDecl::Decl occurs on FunctionDecl;

aspect production functionDecl
top::FunctionDecl ::= storage::StorageClasses  fnquals::SpecialSpecifiers  bty::BaseTypeExpr mty::TypeModifierExpr  n::Name  attrs::Attributes  ds::Decls  body::Stmt
{
  local newStorageClasses::StorageClasses =
    if !storage.isStatic
    then consStorageClass(staticStorageClass(), storage)
    else storage;
  top.instFunctionDecl =
    decls(
      foldDecl([
        variableDecls(
          newStorageClasses, nilAttribute(), bty,
          consDeclarator(
            declarator(top.givenMangledName, mty, nilAttribute(), nothingInitializer()),
            nilDeclarator())),
        functionDeclaration(
          functionDecl(
            newStorageClasses, fnquals, directTypeExpr(bty.typerep),
            case mty of
            | functionTypeExprWithArgs(result, params, variadic, q) ->
              functionTypeExprWithArgs(result, directTypeParameters(params), variadic, q)
            | functionTypeExprWithoutArgs(_, _, _) -> mty
            | _ -> error("mty should always be a functionTypeExpr")
            end, top.givenMangledName, attrs, ds, body))]));
}

aspect production badFunctionDecl
top::FunctionDecl ::= msg::[Message]
{
  top.instFunctionDecl = functionDeclaration(top);
}

function directTypeParameters
Parameters ::= p::Decorated Parameters
{
  return
    case p of
      consParameters(parameterDecl(storage, bty, mty, n, attrs), t) ->
        consParameters(
          parameterDecl(storage, directTypeExpr(mty.typerep), baseTypeExpr(), n, attrs),
          directTypeParameters(t))
    | nilParameters() -> nilParameters()
    end;
}

synthesized attribute typeParameterErrors::[Message] occurs on Names;

aspect production consName
top::Names ::= h::Name t::Names
{
  top.typeParameterErrors =
    (if containsBy(stringEq, h.name, t.names)
     then [err(h.location, "Duplicate template parameter " ++ h.name)]
     else []) ++ t.typeParameterErrors;
}

aspect production nilName
top::Names ::=
{
  top.typeParameterErrors = [];
}
