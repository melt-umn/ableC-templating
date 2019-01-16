grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateFunctionForwardDecl;

imports silver:langutil;

imports edu:umn:cs:melt:ableC:concretesyntax;

imports edu:umn:cs:melt:ableC:abstractsyntax:host as ast;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction as ast;

imports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instantiationExpr;
imports edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateKeyword;
exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:typeParameters;

concrete production templateFunctionForwardDecl_c
top::Declaration_c ::= 'template' '<' params::TypeParameters_c '>' ds::DeclarationSpecifiers_c  idcl::InitDeclaratorList_c  ';'
{
  ds.givenQualifiers = ds.typeQualifiers;
  
  local bt :: ast:BaseTypeExpr =
    ast:figureOutTypeFromSpecifiers(ds.location, ds.typeQualifiers, ds.preTypeSpecifiers, ds.realTypeSpecifiers, ds.mutateTypeSpecifiers);
  local dcls :: ast:Declarators =
    ast:foldDeclarator(idcl.ast);
  
  top.ast = ast:decls(ast:nilDecl()); -- TODO: Ignoring type declarations that are part of the declaration
}
action {
  context = closeScope(context); -- Opened by TypeParameters_c
  context = addIdentsToScope(idcl.declaredIdents, TemplateIdentifier_t, context);
}