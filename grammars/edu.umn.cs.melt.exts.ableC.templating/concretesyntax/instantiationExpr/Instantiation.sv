grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instantiationExpr;

imports silver:langutil only ast;

imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:concretesyntax;

imports edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateKeyword;

terminal TemplateLParen_t '(';

disambiguate TemplateLParen_t, LParen_t {
  pluck TemplateLParen_t;
}

concrete production templateDirectRefExpr_c
top::PrimaryExpr_c ::= 'inst' id::Identifier_c '<' params::TypeNames_c '>'
{
  top.ast = templateDirectRefExpr(id.ast, params.ast, location=top.location);
}

concrete production templateDirectCallExpr_c
top::PrimaryExpr_c ::= 'inst' id::Identifier_c '<' params::TypeNames_c '>' '(' a::ArgumentExprList_c ')'
{
  top.ast = templateDirectCallExpr(id.ast, params.ast, foldExpr(a.ast), location=top.location);
}

concrete production templateDirectCallNoArgsExpr_c
top::PrimaryExpr_c ::= 'inst' id::Identifier_c '<' params::TypeNames_c '>' '(' ')'
{
  top.ast = templateDirectCallExpr(id.ast, params.ast, nilExpr(), location=top.location);
}
