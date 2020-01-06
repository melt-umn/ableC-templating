grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:typenameDisamb;

imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateParameters;
imports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instantiationTypeExpr;

disambiguate TypeName_t, TemplateTypeName_t, TypenameKwd_t {
  pluck TypenameKwd_t;
}