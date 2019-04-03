grammar edu:umn:cs:melt:exts:ableC:templating:silverconstruction;

imports silver:langutil:pp;
imports silver:hostEmbedding;
imports silver:reflect;

imports silver:definition:core;

imports edu:umn:cs:melt:exts:silver:ableC:abstractsyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax:host as ableC;

-- AbleC-to-Silver bridge productions
abstract production escapeTemplateParameters
top::TemplateParameter ::= e::Expr
{
  top.pp = pp"$$ConstructorList{${text(e.unparse)}}";
  forwards to error("TODO: forward value for escapeConstructorList");
}

abstract production escapeTemplateArgNames
top::TemplateArgName ::= e::Expr
{
  top.pp = pp"$$StmtClauses{${text(e.unparse)}}";
  forwards to error("TODO: forward value for escapeStmtClauses");
}

aspect production nonterminalAST
top::AST ::= prodName::String children::ASTs annotations::NamedASTs
{
  collectionEscapeProductions <-
    [pair(
       "edu:umn:cs:melt:exts:ableC:templating:silverconstruction:escapeTemplateParameters",
       pair("TemplateParameters",
         pair(
           "edu:umn:cs:melt:exts:ableC:templating:abstractsyntax:consTemplateParameter",
           "edu:umn:cs:melt:exts:ableC:templating:abstractsyntax:appendTemplateParameters"))),
     pair(
       "edu:umn:cs:melt:exts:ableC:templating:silverconstruction:escapeTemplateArgNames",
       pair("TemplateArgNames",
         pair(
           "edu:umn:cs:melt:exts:ableC:templating:abstractsyntax:consTemplateArgName",
           "edu:umn:cs:melt:exts:ableC:templating:abstractsyntax:appendTemplateArgNames")))];
}
