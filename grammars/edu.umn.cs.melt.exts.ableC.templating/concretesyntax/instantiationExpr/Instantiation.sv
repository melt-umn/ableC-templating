grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instantiationExpr;

imports silver:langutil only ast;

imports edu:umn:cs:melt:ableC:abstractsyntax;
imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:ableC:concretesyntax:lexerHack as lh;

imports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:lexerHack as lh;

imports edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

marking terminal TemplateIdentifier_t /[A-Za-z_\$][A-Za-z_0-9\$]*/ lexer classes {Cidentifier};

function fromTemplateId
Name ::= n::TemplateIdentifier_t
{
  return name(n.lexeme, location=n.location);
}

concrete production templateDeclRefExpr_c
top::PrimaryExpr_c ::= id::TemplateIdentifier_t '<' params::TypeNames_c '>'
{
  top.ast = templateDeclRefExpr(fromTemplateId(id), params.ast, location=top.location);
}

disambiguate TemplateIdentifier_t, Identifier_t, TypeName_t
{
  pluck
    case lookupBy(stringEq, lexeme, head(context)) of
    | just(lh:templateTypenameType_c()) -> TemplateIdentifier_t
    | just(lh:identType_c()) -> Identifier_t
    | just(lh:typenameType_c()) -> TypeName_t
    | nothing() -> Identifier_t
    | it -> error(s"Unexpected lookup result for ${lexeme} in disambiguation function for TemplateIdentifier_t, Identifier_t, TypeName_t: ${hackUnparse(it)}")
    end;
}
disambiguate TemplateIdentifier_t, Identifier_t
{
  pluck
    case lookupBy(stringEq, lexeme, concat(context)) of
    | just(lh:templateIdentType_c()) -> TemplateIdentifier_t
    | just(lh:identType_c()) -> Identifier_t
    | nothing() -> Identifier_t
    | it -> error(s"Unexpected lookup result for ${lexeme} in disambiguation function for TemplateIdentifier_t, Identifier_t: ${hackUnparse(it)}")
    end;
}
