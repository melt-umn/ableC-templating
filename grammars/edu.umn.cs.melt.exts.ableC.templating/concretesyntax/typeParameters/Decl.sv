grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:typeParameters;

imports silver:langutil;

imports edu:umn:cs:melt:ableC:concretesyntax;

imports edu:umn:cs:melt:ableC:abstractsyntax:host as ast;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction as ast;

imports edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

-- Seperate nonterminal from Names_c so that we can open a scope and add newly defined parameter
-- types to the context
closed nonterminal TypeParameters_c with location, ast<ast:Names>;

concrete production typeParameters_c
top::TypeParameters_c ::= params::Names_c
{
  top.ast = ast:foldName(params.ast);
}
action {
  context = addIdentsToScope(params.ast, TypeName_t, openScope(context));
}
