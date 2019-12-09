grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:usingDecl;

imports silver:langutil;

imports edu:umn:cs:melt:ableC:concretesyntax;

imports edu:umn:cs:melt:ableC:abstractsyntax:host as ast;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction as ast;

imports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instantiationTypeExpr;
imports edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateParameters;

marking terminal Using_t 'using' lexer classes {Keyword, Global};

concrete production usingDeclaration_c
top::Declaration_c ::= 'using' id::Identifier_c '<' params::TemplateParameters_c '>' '=' ty::TypeName_c ';'
{
  top.ast = templateTypeDecl(params.ast, id.ast, ty.ast);
}
action {
  context = closeScope(context); -- Opened by TypeParameters_c
  context = addIdentsToScope([id.ast], TemplateTypeName_t, context);
}
