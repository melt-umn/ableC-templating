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
top::Decl ::= params::TypeParameters n::Name ty::TypeName
{
  propagate substituted;
  top.pp = pp"using ${n.pp}<${ppImplode(text(", "), params.pps)}> = ${ty.pp};";
  
  local localErrors::[Message] =
    if !top.isTopLevel
    then [err(n.location, "Template declarations must be global")]
    else n.templateRedeclarationCheck ++ params.errors;
  
  local fwrd::Decl =
    defsDecl([
      templateDef(
        n.name,
        templateItem(
          true, false, n.location, params.names,
          typedefDecls(
            nilAttribute(),
            ty.bty,
            consDeclarator(
              declarator(n, ty.mty, nilAttribute(), nothingInitializer()),
              nilDeclarator()))))]);
  
  forwards to
    if !null(localErrors)
    then decls(consDecl(warnDecl(localErrors), consDecl(fwrd, nilDecl())))
    else fwrd;
}

abstract production templateStructForwardDecl
top::Decl ::= params::TypeParameters attrs::Attributes n::Name
{
  propagate substituted;
  top.pp = ppConcat([
    pp"template<", ppImplode(text(", "), params.pps), pp">", line(),
    pp"struct ", ppAttributes(attrs), text(n.name), space(), semi()]);
  
  local localErrors::[Message] =
    if !top.isTopLevel
    then [err(n.location, "Template declarations must be global")]
    else n.templateRedeclarationCheck ++ params.errors;
  
  local fwrd::Decl =
    defsDecl([
      templateDef(
        n.name,
        templateItem(
          true, true, n.location, params.names,
          -- maybeDecl {typedef __attribute__((refId("edu:umn:cs:melt:exts:ableC:templating:__name__"))) struct __name__ __name__;}
          maybeValueDecl(
            n.name,
            typedefDecls(
              consAttribute(
                gccAttribute(
                  consAttrib(
                    appliedAttrib(
                      attribName(name("refId", location=builtin)),
                      consExpr(
                        stringLiteral(s"\"edu:umn:cs:melt:exts:ableC:templating:${n.name}\"", location=builtin),
                        nilExpr())),
                    nilAttrib())),
                attrs),
              tagReferenceTypeExpr(nilQualifier(), structSEU(), n),
              consDeclarator(
                declarator(n, baseTypeExpr(), nilAttribute(), nothingInitializer()),
                nilDeclarator())))))]);
  
  forwards to
    if !null(localErrors)
    then decls(consDecl(warnDecl(localErrors), consDecl(fwrd, nilDecl())))
    else fwrd;
}

abstract production templateStructDecl
top::Decl ::= params::TypeParameters attrs::Attributes n::Name dcls::StructItemList
{
  propagate substituted;
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
        templateItem(
          true, false, n.location, params.names,
          decls(
            foldDecl([
              -- maybeDecl {typedef __attribute__((refId("edu:umn:cs:melt:exts:ableC:templating:__name__"))) struct __name__ __name__;}
              maybeValueDecl(
                n.name,
                typedefDecls(
                  consAttribute(
                    gccAttribute(
                      consAttrib(
                        appliedAttrib(
                          attribName(name("refId", location=builtin)),
                          consExpr(
                            stringLiteral(s"\"edu:umn:cs:melt:exts:ableC:templating:${n.name}\"", location=builtin),
                            nilExpr())),
                        nilAttrib())),
                    nilAttribute()),
                  tagReferenceTypeExpr(nilQualifier(), structSEU(), n),
                  consDeclarator(
                    declarator(n, baseTypeExpr(), nilAttribute(), nothingInitializer()),
                    nilDeclarator()))),
              -- struct __name__ { ... };
              typeExprDecl(
                nilAttribute(),
                structTypeExpr(
                  nilQualifier(),
                  structDecl(attrs, justName(n), dcls, location=n.location)))]))))]);
  
  forwards to
    if !null(localErrors)
    then decls(consDecl(warnDecl(localErrors), consDecl(fwrd, nilDecl())))
    else fwrd;
}

abstract production templateFunctionDecl
top::Decl ::= params::TypeParameters d::FunctionDecl
{
  propagate substituted;
  top.pp = ppConcat([pp"template<", ppImplode(text(", "), params.pps), pp">", line(), d.pp]);
  
  local localErrors::[Message] =
    case d of
      functionDecl(_, _, _, _, n, _, _, _) -> 
        if !top.isTopLevel
        then [err(n.location, "Template declarations must be global")]
        else n.templateRedeclarationCheck ++ params.errors
      | badFunctionDecl(msg) -> msg
      end;
  
  local resultTypedefName::Name =
    name(s"_template_result_${toString(genInt())}", location=builtin);
  local fwrd::Decl =
    case d of
      functionDecl(storage, fnquals, bty, mty, n, attrs, ds, body) -> 
        defsDecl([
          templateDef(
            n.name,
            templateItem(
              false, false, d.sourceLocation, params.names,
              decls(
                foldDecl([
                  typedefDecls(
                    nilAttribute(), bty,
                    consDeclarator(
                      declarator(resultTypedefName, baseTypeExpr(), nilAttribute(), nothingInitializer()),
                      nilDeclarator())),
                  variableDecls(
                    if !containsBy(storageClassEq, staticStorageClass(), storage)
                    then staticStorageClass() :: storage
                    else storage,
                    nilAttribute(),
                    typedefTypeExpr(nilQualifier(), resultTypedefName),
                    consDeclarator(
                      declarator(n, mty, nilAttribute(), nothingInitializer()),
                      nilDeclarator())),
                  functionDeclaration(
                    functionDecl(
                      if !containsBy(storageClassEq, staticStorageClass(), storage)
                      then staticStorageClass() :: storage
                      else storage,
                      fnquals,
                      typedefTypeExpr(nilQualifier(), resultTypedefName),
                      mty, n, attrs, ds, body))]))))])
    | badFunctionDecl(msg) -> decls(nilDecl())
    end;
  
  forwards to
    if !null(localErrors)
    then decls(consDecl(warnDecl(localErrors), consDecl(fwrd, nilDecl())))
    else fwrd;
}

synthesized attribute names::[String];

nonterminal TypeParameters with pps, names, errors, substitutions, substituted<TypeParameters>;

abstract production consTypeParameters
top::TypeParameters ::= h::Name t::TypeParameters
{
  propagate substituted;
  top.pps = h.pp :: t.pps;
  top.names = h.name :: t.names;
  top.errors :=
    (if containsBy(stringEq, h.name, t.names)
     then [err(h.location, "Duplicate template parameter " ++ h.name)]
     else []) ++ t.errors;
}

abstract production nilTypeParameters
top::TypeParameters ::=
{
  propagate substituted;
  top.pps = [];
  top.names = [];
  top.errors := [];
}

function storageClassEq
Boolean ::= s1::StorageClass s2::StorageClass
{
  return
    case s1, s2 of
      externStorageClass(), externStorageClass() -> true
    | staticStorageClass(), staticStorageClass() -> true
    | autoStorageClass(), autoStorageClass() -> true
    | registerStorageClass(), registerStorageClass() -> true
    | threadLocalStorageClass(), threadLocalStorageClass() -> true
    | _, _ -> false
    end;
}
