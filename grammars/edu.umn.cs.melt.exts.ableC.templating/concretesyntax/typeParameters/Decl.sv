grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:typeParameters;

imports silver:langutil;

imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:ableC:concretesyntax:lexerHack as lh;

imports edu:umn:cs:melt:ableC:abstractsyntax:host as ast;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction as ast;

imports edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

-- Seperate nonterminal from Names_c so that we can open a scope and add newly defined parameter
-- types to the context
closed nonterminal TypeParameters_c with location, ast<TypeParameters>;

concrete production typeParameters_c
top::TypeParameters_c ::= params::Names_c
{
  top.ast = foldr(consTypeParameters, nilTypeParameters(), params.ast);
}
action {
  context = lh:addTypenamesToScope(params.ast, lh:openScope(context));
}

closed nonterminal Names_c with location, ast<[ast:Name]>;

concrete productions top::Names_c
| h::Identifier_t ',' t::Names_c
  { top.ast = ast:fromId(h) :: t.ast; }
| h::Identifier_t
  { top.ast = [ast:fromId(h)]; }
| 
  { top.ast = []; }
