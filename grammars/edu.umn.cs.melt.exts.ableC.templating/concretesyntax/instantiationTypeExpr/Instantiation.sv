grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instantiationTypeExpr;

imports silver:langutil only ast;

imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:concretesyntax;

imports edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

marking terminal TemplateTypeName_t /[A-Za-z_\$][A-Za-z_0-9\$]*/ lexer classes {Cidentifier};

concrete productions top::TypeSpecifier_c
{-| ty::TypeIdName_c '<' params::TypeNames_c '>'
  {
    top.realTypeSpecifiers = [templateTypedefTypeExpr(top.givenQualifiers, ty.ast, params.ast)];
    top.preTypeSpecifiers = []; 
  }-}
| ty::TemplateTypeName_t '<' params::TypeNames_c '>'
  {
    top.realTypeSpecifiers = [templateTypedefTypeExpr(top.givenQualifiers, name(ty.lexeme, location=ty.location), params.ast)];
    top.preTypeSpecifiers = []; 
  }
