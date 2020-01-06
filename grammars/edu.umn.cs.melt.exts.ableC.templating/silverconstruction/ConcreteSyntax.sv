grammar edu:umn:cs:melt:exts:ableC:templating:silverconstruction;

imports edu:umn:cs:melt:exts:silver:ableC:concretesyntax;

exports edu:umn:cs:melt:exts:ableC:templating;

terminal EscapeTemplateParameters_t '$TemplateParameters' lexer classes {Escape, Reserved};
terminal EscapeTemplateArgNames_t   '$TemplateArgNames'   lexer classes {Escape, Reserved};

concrete productions top::TemplateParameter_c
| '$TemplateParameters' NotInAbleC silver:definition:core:LCurly_t e::Expr silver:definition:core:RCurly_t InAbleC
  { top.ast = antiquoteTemplateParameters(e, location=top.location); }

concrete productions top::TemplateArgument_c
| '$TemplateArgNames' NotInAbleC silver:definition:core:LCurly_t e::Expr silver:definition:core:RCurly_t InAbleC
  { top.ast = antiquoteTemplateArgNames(e, location=top.location); }
