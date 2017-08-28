grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateStructDecl;

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

concrete production templateStructDecl_c
top::ExternalDeclaration_c ::= JustTemplate_t '<' params::TemplateParameters_c '>' TemplateStruct_t
maa::MaybeAttributes_c
id::Identifier_t '{' ss::StructDeclarationList_c '}'  ';'
{ 
  top.ast = templateStructDecl(params.ast, maa.ast, ast:fromId(id), ast:foldStructItem(ss.ast));
}
action {
  context = lh:closeScope(context); -- Opened by TemplateParams_c
  context = lh:addTypenamesToScope([ast:fromId(id)], context);
}
