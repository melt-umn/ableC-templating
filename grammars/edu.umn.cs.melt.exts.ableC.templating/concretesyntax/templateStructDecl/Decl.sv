grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateStructDecl;

imports silver:langutil;

imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:ableC:concretesyntax:lexerHack as lh;
imports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:lexerHack as lh;

imports edu:umn:cs:melt:ableC:abstractsyntax as ast;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction as ast;

imports edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateKeyword;
exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateParameters;
exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateStructKeyword;
exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:maybeAttributes;

concrete production templateStructDecl_c
top::ExternalDeclaration_c ::= Template_t params::TemplateParameters_c '>' TemplateStruct_t maa::MaybeAttributes_c id::TemplateInitialStructDeclaration_c '{' ss::StructDeclarationList_c '}'  ';'
{ 
  top.ast = templateStructDecl(params.ast, maa.ast, id.ast, ast:foldStructItem(ss.ast));
}
action {
  context = lh:closeScope(context); -- Opened by TemplateParameters_c
  -- Add the template name to the global context
  context = lh:addTemplateTypenamesToScope([id.ast], context);
}

-- Wrapper nonterminal for Identifier_t that adds the template name to the current scope
nonterminal TemplateInitialStructDeclaration_c with location, ast<ast:Name>;

concrete production templateInitialStructDeclaration_c
top::TemplateInitialStructDeclaration_c ::= id::Identifier_t
{ 
  top.ast = ast:fromId(id);
}
action {
  -- Add the template name to the context for the struct body
  context = lh:addTemplateTypenamesToScope([ast:fromId(id)], context);
}
