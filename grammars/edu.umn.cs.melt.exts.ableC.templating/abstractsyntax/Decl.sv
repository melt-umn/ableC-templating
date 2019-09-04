grammar edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

imports silver:langutil;
imports silver:langutil:pp;

imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:substitution;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;
imports edu:umn:cs:melt:ableC:abstractsyntax:overloadable;

global builtin::Location = builtinLoc("templating");

abstract production templateTypeDecl
top::Decl ::= params::TemplateParameters n::Name ty::TypeName
{
  top.pp = pp"using ${n.pp}<${ppImplode(text(", "), params.pps)}> = ${ty.pp};";
  
  local localErrors::[Message] =
    if !top.isTopLevel
    then [err(n.location, "Template declarations must be global")]
    else n.templateRedeclarationCheck ++ params.errors;
  
  local fwrd::Decl =
    defsDecl([templateDef(n.name, templateTypeTemplateItem(n.location, params.names, params.kinds, ty))]);
  
  forwards to
    if !null(localErrors)
    then decls(consDecl(warnDecl(localErrors), consDecl(fwrd, nilDecl())))
    else fwrd;
}

abstract production templateStructDecl
top::Decl ::= params::TemplateParameters attrs::Attributes n::Name dcls::StructItemList
{
  top.pp = ppConcat([
    pp"template<", ppImplode(text(", "), params.pps), pp">", line(),
    pp"struct ", ppAttributes(attrs), text(n.name), space(),
    braces(nestlines(2, terminate(cat(semi(),line()), dcls.pps))), semi()]);
  
  local localErrors::[Message] =
    if !top.isTopLevel
    then [err(n.location, "Template declarations must be global")]
    else n.templateRedeclarationCheck ++ params.errors;
  
  local fwrd::Decl =
    defsDecl([
      templateDef(
        n.name,
        typeTemplateItem(
          n.location, params.names, params.kinds,
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
  top.pp = ppConcat([
    pp"deferred struct ", ppAttributes(attrs), text(n.name), space(),
    braces(nestlines(2, terminate(cat(semi(),line()), dcls.pps))), semi()]);
  
  dcls.inStruct = true;
  dcls.isLast = true; -- We don't know, but be conservative to avoid errors
  
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
top::Decl ::= params::TemplateParameters d::FunctionDecl
{
  top.pp = ppConcat([pp"template<", ppImplode(text(", "), params.pps), pp">", line(), d.pp]);
  
  local localErrors::[Message] =
    case d of
      functionDecl(_, _, _, _, n, _, _, _) -> 
        if !top.isTopLevel
        then [err(n.location, "Template declarations must be global")]
        else n.templateRedeclarationCheck ++ params.errors
      | badFunctionDecl(msg) -> msg
      end;
  
  local fwrd::Decl =
    defsDecl([templateDef(d.name, functionTemplateItem(d.sourceLocation, params.names, params.kinds, d))]);
  
  forwards to
    if !null(localErrors)
    then decls(consDecl(warnDecl(localErrors), consDecl(fwrd, nilDecl())))
    else fwrd;
}

abstract production instFunctionDeclaration
top::Decl ::= mangledName::Name decl::FunctionDecl
{
  top.pp = pp"inst_decl ${decl.pp}";
  
  decl.givenMangledName = mangledName;
  forwards to decl.instFunctionDecl;
}

inherited attribute givenMangledName::Name occurs on FunctionDecl;
synthesized attribute instFunctionDecl::Decl occurs on FunctionDecl;
synthesized attribute maybeParameters::Maybe<Parameters> occurs on FunctionDecl;

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
  
  top.maybeParameters =
    case mty of
    | functionTypeExprWithArgs(_, params, _, _) -> just(params)
    | functionTypeExprWithoutArgs(_, _, _) -> nothing()
    | _ -> error("mty should always be a functionTypeExpr")
    end;
}

aspect production badFunctionDecl
top::FunctionDecl ::= msg::[Message]
{
  top.instFunctionDecl = functionDeclaration(top);
  top.maybeParameters = nothing();
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

synthesized attribute kinds::[Maybe<TypeName>];

autocopy attribute appendedTemplateParameters :: TemplateParameters;
synthesized attribute appendedTemplateParametersRes :: TemplateParameters;

nonterminal TemplateParameters with pps, names, kinds, count, errors, appendedTemplateParameters, appendedTemplateParametersRes;
flowtype TemplateParameters = decorate {}, pps {}, names {}, kinds {decorate}, errors {decorate}, appendedTemplateParametersRes {appendedTemplateParameters};

abstract production consTemplateParameter
top::TemplateParameters ::= h::TemplateParameter t::TemplateParameters
{
  top.pps = h.pp :: t.pps;
  top.names = h.name :: t.names;
  top.kinds = h.kind :: t.kinds;
  top.count = t.count + 1;
  top.errors := t.errors;
  top.appendedTemplateParametersRes = consTemplateParameter(h, t.appendedTemplateParametersRes);
  
  top.errors <-
    if containsBy(stringEq, h.name, t.names)
    then [err(h.location, "Duplicate template parameter " ++ h.name)]
    else [];
}

abstract production nilTemplateParameter
top::TemplateParameters ::= 
{
  top.pps = [];
  top.names = [];
  top.kinds = [];
  top.count = 0;
  top.errors := [];
  top.appendedTemplateParametersRes = top.appendedTemplateParameters;
}

function appendTemplateParameters
TemplateParameters ::= p1::TemplateParameters p2::TemplateParameters
{
  p1.appendedTemplateParameters = p2;
  return p1.appendedTemplateParametersRes;
}

synthesized attribute kind::Maybe<TypeName>;

nonterminal TemplateParameter with pp, location, name, kind;
flowtype TemplateParameter = decorate {}, pp {}, name {}, kind {decorate};

abstract production typeTemplateParameter
top::TemplateParameter ::= n::Name
{
  top.pp = pp"typename ${n.pp}";
  top.name = n.name;
  top.kind = nothing();
}

abstract production valueTemplateParameter
top::TemplateParameter ::= bty::BaseTypeExpr n::Name mty::TypeModifierExpr
{
  top.pp = pp"${bty.pp} ${mty.lpp}${n.pp}${mty.rpp}";
  top.name = n.name;
  top.kind = just(typeName(bty, mty));
}
