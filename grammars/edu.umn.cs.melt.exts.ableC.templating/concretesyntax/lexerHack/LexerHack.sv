grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:lexerHack;

imports edu:umn:cs:melt:ableC:concretesyntax:lexerHack;
imports edu:umn:cs:melt:ableC:abstractsyntax as ast;

{-
 - We extend the C lexer hack mechanism to include templates
 - We need to distinguish between template identifiers, template type names,
 - regular identifiers, and regular type names.
 -}
abstract production templateIdentType_c     top::IdentType ::= {}
abstract production templateTypenameType_c  top::IdentType ::= {}

global templateIdentType :: IdentType = templateIdentType_c();
global templateTypenameType :: IdentType = templateTypenameType_c();

function addTemplateIdentsToScope
[[Pair<String IdentType>]] ::= l::[ast:Name]  context::[[Pair<String IdentType>]]
{
  return (map(pair(_, templateIdentType), map((.ast:name), l)) ++ head(context)) :: tail(context);
}

function addTemplateTypenamesToScope
[[Pair<String IdentType>]] ::= l::[ast:Name]  context::[[Pair<String IdentType>]]
{
  return (map(pair(_, templateTypenameType), map((.ast:name), l)) ++ head(context)) :: tail(context);
}

function beginTemplateFunctionScope
[[Pair<String IdentType>]] ::= funName::ast:Name  paramNames::Maybe<[ast:Name]>  context::[[Pair<String IdentType>]]
{
  return
    addIdentsToScope(fromMaybe([], paramNames),
      openScope(
        addTemplateIdentsToScope([funName],
          context)));
}
