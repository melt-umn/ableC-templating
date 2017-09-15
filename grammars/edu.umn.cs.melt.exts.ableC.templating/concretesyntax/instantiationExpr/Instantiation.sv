grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instantiationExpr;

imports silver:langutil only ast;

imports edu:umn:cs:melt:ableC:abstractsyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:concretesyntax;

imports edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateKeyword;

concrete production templateDeclRefExpr_c
top::PrimaryExpr_c ::= 'inst' id::Identifier_t '<' params::TypeNames_c '>'
{
  top.ast = templateDeclRefExpr(fromId(id), params.ast, location=top.location);
}

