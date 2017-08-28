grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instantiationExpr;

imports silver:langutil only ast;

imports edu:umn:cs:melt:ableC:abstractsyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:concretesyntax;

imports edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

imports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateKeyword;

--marking terminal TemplateIdentifier_t 'template' lexer classes {Ckeyword};
--marking terminal T_t 'template' lexer classes {Ckeyword};

concrete production templateDeclRefExpr_c
top::PrimaryExpr_c ::= JustTemplate_t id::Identifier_t '<' params::TypeNames_c '>'
{
  top.ast = templateDeclRefExpr(fromId(id), params.ast, location=top.location);
}

