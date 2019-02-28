grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateParameters;

imports silver:langutil;

imports edu:umn:cs:melt:ableC:concretesyntax;

imports edu:umn:cs:melt:ableC:abstractsyntax:host as ast;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction as ast;

imports edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

-- Needed to open a scope for the parameters
terminal OpenScope_t '' action { context = openScope(context); };

closed nonterminal TemplateParameters_c with location, ast<ast:TemplateParameters>;

concrete production templateParameters_c
top::TemplateParameters_c ::= OpenScope_t params::Names_c
{
  top.ast = ast:foldName(params.ast);
}
action {
  context = addIdentsToScope(params.ast, TypeName_t, openScope(context));
}

nonterminal TemplateParams_c with location, ast<ast:TemplateParameters>;

concrete productions top::TemplateParams_c
| h::TemplateParameter_c ',' t::TemplateParams_c
  {}
| h::TemplateParameter_c
  {}
|
  {}

closed nonterminal TemplateParameter_c with location, ast<ast:TemplateParameter>;

concrete productions top::TemplateParameter_c
| id::Identifier_c
  { top.ast = typeTemplateParameter(id.ast); }
| h::TemplateParameter_c
  {}
|
  {}
