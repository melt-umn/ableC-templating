grammar edu:umn:cs:melt:exts:ableC:templating:silverconstruction;

imports silver:langutil:pp;
imports silver:reflect;

imports silver:compiler:definition:core;
imports silver:compiler:metatranslation;

imports edu:umn:cs:melt:ableC:silverconstruction:abstractsyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax:host as ableC;

-- AbleC-to-Silver bridge productions
abstract production antiquoteTemplateParameters
top::TemplateParameter ::= e::Expr
{
  top.pp = pp"$$ConstructorList{${text(e.unparse)}}";
  forwards to error("TODO: forward value for antiquoteConstructorList");
}

abstract production antiquoteTemplateArgNames
top::TemplateArgName ::= e::Expr
{
  top.pp = pp"$$StmtClauses{${text(e.unparse)}}";
  forwards to error("TODO: forward value for antiquoteStmtClauses");
}

aspect production nonterminalAST
top::AST ::= prodName::String children::ASTs annotations::NamedASTs
{
  collectionAntiquoteProductions <-
    [("edu:umn:cs:melt:exts:ableC:templating:silverconstruction:antiquoteTemplateParameters",
      "TemplateParameters",
      "edu:umn:cs:melt:exts:ableC:templating:abstractsyntax:consTemplateParameter",
      "edu:umn:cs:melt:exts:ableC:templating:abstractsyntax:nilTemplateParameter",
      "edu:umn:cs:melt:exts:ableC:templating:abstractsyntax:appendTemplateParameters"),
     ("edu:umn:cs:melt:exts:ableC:templating:silverconstruction:antiquoteTemplateArgNames",
      "TemplateArgNames",
      "edu:umn:cs:melt:exts:ableC:templating:abstractsyntax:consTemplateArgName",
      "edu:umn:cs:melt:exts:ableC:templating:abstractsyntax:nilTemplateArgName",
      "edu:umn:cs:melt:exts:ableC:templating:abstractsyntax:appendTemplateArgNames")];
}
