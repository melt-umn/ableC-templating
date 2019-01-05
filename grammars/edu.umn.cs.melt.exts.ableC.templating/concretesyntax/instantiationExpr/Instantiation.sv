grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instantiationExpr;

imports silver:langutil only ast;

imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:concretesyntax;

imports edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

marking terminal TemplateIdentifier_t /[A-Za-z_\$][A-Za-z_0-9\$]*/ lexer classes {Cidentifier};
terminal TemplateLParen_t '(';

disambiguate TemplateLParen_t, LParen_t {
  pluck TemplateLParen_t;
}

concrete productions top::PrimaryExpr_c
{-| id::Identifier_c '<' params::TypeNames_c '>'
  { top.ast = templateDirectRefExpr(id.ast, params.ast, location=top.location); }
| id::Identifier_c '<' params::TypeNames_c '>' '(' a::ArgumentExprList_c ')'
  { top.ast = templateDirectCallExpr(id.ast, params.ast, foldExpr(a.ast), location=top.location); }
| id::Identifier_c '<' params::TypeNames_c '>' '(' ')'
  { top.ast = templateDirectCallExpr(id.ast, params.ast, nilExpr(), location=top.location); }-}
| id::TemplateIdentifier_t '<' params::TypeNames_c '>'
  { top.ast = templateDirectRefExpr(name(id.lexeme, location=id.location), params.ast, location=top.location); }
| id::TemplateIdentifier_t '<' params::TypeNames_c '>' '(' a::ArgumentExprList_c ')'
  { top.ast = templateDirectCallExpr(name(id.lexeme, location=id.location), params.ast, foldExpr(a.ast), location=top.location); }
| id::TemplateIdentifier_t '<' params::TypeNames_c '>' '(' ')'
  { top.ast = templateDirectCallExpr(name(id.lexeme, location=id.location), params.ast, nilExpr(), location=top.location); }
