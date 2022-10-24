grammar edu:umn:cs:melt:exts:ableC:templating:silverconstruction;

imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:exts:silver:ableC:concretesyntax:antiquotation;
imports edu:umn:cs:melt:exts:ableC:templating;

marking terminal AntiquoteTemplateParameters_t '$TemplateParameters' lexer classes {Antiquote, Reserved};
marking terminal AntiquoteTemplateArgNames_t   '$TemplateArgNames'   lexer classes {Antiquote, Reserved};

concrete productions top::TemplateParameter_c
| '$TemplateParameters' silver:compiler:definition:core:LCurly_t e::Expr silver:compiler:definition:core:RCurly_t
  layout {silver:compiler:definition:core:WhiteSpace, BlockComments, Comments}
  { top.ast = antiquoteTemplateParameters(e, location=top.location); }

concrete productions top::TemplateArgument_c
| '$TemplateArgNames' silver:compiler:definition:core:LCurly_t e::Expr silver:compiler:definition:core:RCurly_t
  layout {silver:compiler:definition:core:WhiteSpace, BlockComments, Comments}
  { top.ast = antiquoteTemplateArgNames(e, location=top.location); }
