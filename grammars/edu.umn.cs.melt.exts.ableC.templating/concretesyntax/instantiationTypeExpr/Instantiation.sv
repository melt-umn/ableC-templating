grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instantiationTypeExpr;

imports silver:langutil only ast;

imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:concretesyntax;

imports edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateKeyword;

concrete production templateTypedef_c
top::TypeSpecifier_c ::= 'inst' ty::TypeName_t '<' params::TypeNames_c '>'
{
  top.realTypeSpecifiers = [templateTypedefTypeExpr(top.givenQualifiers, fromTy(ty), params.ast)];
  top.preTypeSpecifiers = []; 
}
