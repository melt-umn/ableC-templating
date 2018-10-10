grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:usingDecl;

imports silver:langutil;

imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:ableC:concretesyntax:lexerHack as lh;

imports edu:umn:cs:melt:ableC:abstractsyntax:host as ast;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction as ast;

imports edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateParameters;

marking terminal Using_t 'using' lexer classes {Ckeyword};

concrete production usingDeclaration_c
top::Declaration_c ::= 'using' id::Identifier_t '<' params::TemplateParameters_c '>' '=' ty::TypeName_c ';'
{
  top.ast = templateTypeDecl(params.ast, ast:fromId(id), ty.ast);
}
action {
  context = lh:closeScope(context); -- Opened by TemplateDecl_c
  context = lh:addTypenamesToScope([ast:fromId(id)], context);
}
