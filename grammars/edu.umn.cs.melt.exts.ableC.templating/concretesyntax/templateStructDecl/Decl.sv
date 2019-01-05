grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateStructDecl;

imports silver:langutil;

imports edu:umn:cs:melt:ableC:concretesyntax;

imports edu:umn:cs:melt:ableC:abstractsyntax:host as ast;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction as ast;

imports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instantiationTypeExpr;
imports edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateKeyword;
exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:typeParameters;
exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateStructKeyword;
exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:maybeAttributes;

concrete production templateStructDecl_c
top::Declaration_c ::= 'template' d::TemplateInitialStructDeclaration_c '{' ss::StructDeclarationList_c '}'  ';'
{
  top.ast = d.ast(ast:foldStructItem(ss.ast));
}
action {
  context = closeScope(context); -- Opened by TypeParameters_c
  context = addIdentsToScope([d.declaredIdent], TemplateTypeName_t, context);
}

nonterminal TemplateInitialStructDeclaration_c with ast<(ast:Decl ::= ast:StructItemList)>, declaredIdent, location;

concrete production templateInitialStructDeclaration_c
top::TemplateInitialStructDeclaration_c ::=
   '<' params::TypeParameters_c '>' TemplateStruct_t
   maa::MaybeAttributes_c id::Identifier_c
{
  top.ast = templateStructDecl(params.ast, maa.ast, id.ast, _);
  top.declaredIdent = id.ast;
}
action {
  context = addIdentsToScope([id.ast], TemplateTypeName_t, context);
}
