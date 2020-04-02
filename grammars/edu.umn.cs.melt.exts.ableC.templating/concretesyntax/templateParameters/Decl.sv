grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateParameters;

imports silver:langutil;

imports edu:umn:cs:melt:ableC:concretesyntax;

imports edu:umn:cs:melt:ableC:abstractsyntax:host as ast;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction as ast;

imports edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:typenameDisamb
  with edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instantiationTypeExpr;

terminal TypenameKwd_t 'typename' lexer classes {Keyword};

disambiguate TypeName_t, TypenameKwd_t {
  pluck TypenameKwd_t;
}

-- Needed to open a scope for the parameters
terminal OpenScope_t '' action { context = openScope(context); };

closed nonterminal TemplateParameters_c
  layout {LineComment_t, BlockComment_t, Spaces_t, NewLine_t}
  with location, ast<TemplateParameters>;

concrete production templateParameters_c
top::TemplateParameters_c ::= OpenScope_t params::TemplateParams_c
{
  top.ast = params.ast;
}

nonterminal TemplateParams_c with location, ast<TemplateParameters>;

concrete productions top::TemplateParams_c
| h::TemplateParameter_c ',' t::TemplateParams_c
  { top.ast = consTemplateParameter(h.ast, t.ast); }
| h::TemplateParameter_c
  { top.ast = consTemplateParameter(h.ast, nilTemplateParameter()); }
|
  { top.ast = nilTemplateParameter(); }

closed nonterminal TemplateParameter_c with location, ast<TemplateParameter>;

concrete productions top::TemplateParameter_c
| 'typename' id::Identifier_c
  { top.ast = typeTemplateParameter(id.ast, location=top.location); }
  action {
    context = addIdentsToScope([id.ast], TypeName_t, context);
  }
| ds::DeclarationSpecifiers_c d::Declarator_c
  {
    ds.givenQualifiers = ds.typeQualifiers;
    d.givenType = ast:baseTypeExpr();
    local bt :: ast:BaseTypeExpr =
      ast:figureOutTypeFromSpecifiers(ds.location, ds.typeQualifiers, ds.preTypeSpecifiers, ds.realTypeSpecifiers, ds.mutateTypeSpecifiers);
    top.ast = valueTemplateParameter(bt, d.declaredIdent, d.ast, location=top.location);
  }
  action {
    context = addIdentsToScope([d.declaredIdent], Identifier_t, context);
  }
