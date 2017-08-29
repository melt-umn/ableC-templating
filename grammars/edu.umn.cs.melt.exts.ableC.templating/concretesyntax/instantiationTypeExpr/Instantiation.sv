grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instantiationTypeExpr;

imports silver:langutil only ast;

imports edu:umn:cs:melt:ableC:abstractsyntax;
imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:ableC:concretesyntax:lexerHack as lh;

imports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:lexerHack as lh;

imports edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

marking terminal TemplateTypeName_t /[A-Za-z_\$][A-Za-z_0-9\$]*/ lexer classes {Cidentifier};

function fromTemplateTypeName
Name ::= n::TemplateTypeName_t
{
  return name(n.lexeme, location=n.location);
}

concrete production templateTypedef_c
top::TypeSpecifier_c ::= id::TemplateTypeName_t '<' params::TypeNames_c '>'
{
  top.realTypeSpecifiers = [templateTypedefTypeExpr(top.givenQualifiers, fromTemplateTypeName(id), params.ast)];
  top.preTypeSpecifiers = []; 
}

disambiguate TemplateTypeName_t, Identifier_t, TypeName_t
{
  pluck
    case lookupBy(stringEq, lexeme, head(context)) of
    | just(lh:templateTypenameType_c()) -> TemplateTypeName_t
    | just(lh:identType_c()) -> Identifier_t
    | just(lh:typenameType_c()) -> TypeName_t
    | nothing() -> Identifier_t
    | it -> error(s"Unexpected lookup result for ${lexeme} in disambiguation function for TemplateTypeName_t, Identifier_t, TypeName_t: ${hackUnparse(it)}")
    end;
}
disambiguate TemplateTypeName_t, TypeName_t
{
  pluck
    case lookupBy(stringEq, lexeme, concat(context)) of
    | just(lh:templateTypenameType_c()) -> TemplateTypeName_t
    | just(lh:typenameType_c()) -> TypeName_t
    | it -> error(s"Unexpected lookup result for ${lexeme} in disambiguation function for TemplateTypeName_t, TypeName_t: ${hackUnparse(it)}")
    end;
}
