grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateArguments;

imports silver:langutil;

imports edu:umn:cs:melt:ableC:concretesyntax;

imports edu:umn:cs:melt:ableC:abstractsyntax:host as ast;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction as ast;

imports edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

closed tracked nonterminal TemplateArguments_c
  layout {LineComment_t, BlockComment_t, Spaces_t, NewLine_t}
  with ast<TemplateArgNames>;

concrete productions top::TemplateArguments_c
| h::TemplateArgument_c ',' t::TemplateArguments_c
  { top.ast = consTemplateArgName(h.ast, t.ast); }
| h::TemplateArgument_c
  { top.ast = consTemplateArgName(h.ast, nilTemplateArgName()); }
|
  { top.ast = nilTemplateArgName(); }

closed tracked nonterminal TemplateArgument_c with ast<TemplateArgName>;

concrete productions top::TemplateArgument_c
| ty::TypeName_c
  { top.ast = typeTemplateArgName(ty.ast); }
| id::Identifier_c
  { top.ast = valueTemplateArgName(ast:declRefExpr(id.ast)); }
| c::Constant_c
  { top.ast = valueTemplateArgName(c.ast); }
