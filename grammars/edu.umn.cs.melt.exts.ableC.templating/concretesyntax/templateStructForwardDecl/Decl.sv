grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateStructForwardDecl;

imports silver:langutil;

imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:ableC:concretesyntax:lexerHack as lh;

imports edu:umn:cs:melt:ableC:abstractsyntax as ast;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction as ast;

imports edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

imports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateKeyword;
imports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateParameters;
imports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateStructKeyword;
imports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:maybeAttributes;

concrete production templateStructForwardDecl_c
top::ExternalDeclaration_c ::= JustTemplate_t '<' params::TemplateParameters_c '>' TemplateStruct_t
maa::MaybeAttributes_c
id::Identifier_t ';'
{ 
  top.ast = templateStructForwardDecl(params.ast, maa.ast, ast:fromId(id));
}
action {
  context = lh:closeScope(context); -- Opened by TemplateParams_c
  context = lh:addTypenamesToScope([ast:fromId(id)], context);
}
