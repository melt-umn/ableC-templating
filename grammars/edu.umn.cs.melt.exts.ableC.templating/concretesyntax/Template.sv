grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax;

imports silver:langutil;

imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:ableC:concretesyntax:lexerHack as lh;

imports edu:umn:cs:melt:ableC:abstractsyntax as ast;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction as ast;

imports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:lexerHack as lh;

exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateStructForwardDecl;
exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateStructDecl;
exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateFunctionDecl;
exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:usingDecl;
exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instantiationTypeExpr;
exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instantiationExpr;

{- Disambiguate between template identifiers, template type names, regular
 - identifiers, and regular type names.
 - This is a simple extension to the host lexer hack mechanism for
 - disambiguating regular identifiers and type names.
 - We need to write a seperate function for every group where an amiguity exists.
 - This function is placed at the top-level since this conflict only shows up in
 - the composition of instantiationExpr and instantiationTypeExpr, the other
 - functions are in these respective sub-grammars.
 -}
disambiguate TemplateIdentifier_t, TemplateTypeName_t, Identifier_t, TypeName_t
{
  pluck
    case lookupBy(stringEq, lexeme, head(context)) of
    | just(lh:templateIdentType_c()) -> TemplateIdentifier_t
    | just(lh:templateTypenameType_c()) -> TemplateTypeName_t
    | just(lh:identType_c()) -> Identifier_t
    | just(lh:typenameType_c()) -> TypeName_t
    | nothing() -> Identifier_t
    | it -> error(s"Unexpected lookup result for ${lexeme} in disambiguation function for TemplateIdentifier_t, TemplateTypeName_t, Identifier_t, TypeName_t: ${hackUnparse(it)}")
    end;
}
