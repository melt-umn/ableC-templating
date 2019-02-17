grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instantiationTypeExpr;

imports silver:langutil only ast;

imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:concretesyntax;

imports edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instKeyword;

marking terminal TemplateTypeName_t /[A-Za-z_\$][A-Za-z_0-9\$]*/ lexer classes {Cidentifier, Ctype};

concrete productions top::TypeSpecifier_c
| ty::TemplateTypeName_t '<' params::TypeNames_c '>'
  {
    top.realTypeSpecifiers = [templateTypedefTypeExpr(top.givenQualifiers, name(ty.lexeme, location=ty.location), params.ast)];
    top.preTypeSpecifiers = [];
  }
-- For use in silver-ableC
| 'inst' ty::TypeIdName_c '<' params::TypeNames_c '>'
  {
    top.realTypeSpecifiers = [templateTypedefTypeExpr(top.givenQualifiers, ty.ast, params.ast)];
    top.preTypeSpecifiers = [];
  }
