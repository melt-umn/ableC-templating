grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:maybeAttributes;

imports silver:langutil;

imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax:host as ast;

nonterminal MaybeAttributes_c with ast<ast:Attributes>;

concrete productions top::MaybeAttributes_c
| aa::Attributes_c
  { top.ast = aa.ast; }
| 
  { top.ast = ast:nilAttribute(); }
