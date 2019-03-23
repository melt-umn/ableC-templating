grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateStructForwardDecl;

imports silver:langutil;

imports edu:umn:cs:melt:ableC:concretesyntax;

imports edu:umn:cs:melt:ableC:abstractsyntax:host as ast;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction as ast;

imports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instantiationTypeExpr;
imports edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

--exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateKeyword;
exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateStructKeyword;
exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateStructDecl;

-- This production has no semantic meaning, it only serves to insert the template
-- type name in the partsing context.
concrete production templateStructForwardDecl_c
top::Declaration_c ::= 'template' d::TemplateInitialStructDeclaration_c ';'
{
  top.ast = ast:decls(ast:nilDecl());
}
action {
  context = closeScope(context); -- Opened by TypeParameters_c
  context = addIdentsToScope([d.declaredIdent], TemplateTypeName_t, context);
}
