grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instantiationExpr;

imports silver:langutil only ast;

imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:overloadable as ovrld;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:concretesyntax;

imports edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instKeyword;
exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateArguments;

marking terminal TemplateIdentifier_t /[A-Za-z_\$][A-Za-z_0-9\$]*/ lexer classes {Identifier, Scoped};

concrete productions top::UnaryExpr_c
| id::TemplateIdentifier_t '<' args::TemplateArguments_c '>'
  { top.ast = templateDirectRefExpr(name(id.lexeme, location=id.location), args.ast, location=top.location); }
  -- For use in silver-ableC
| 'inst' id::Identifier_c '<' args::TemplateArguments_c '>'
  { top.ast = templateDirectRefExpr(id.ast, args.ast, location=top.location); }

concrete productions top::PrimaryExpr_c
| id::TemplateIdentifier_t '<' args::TemplateArguments_c '>' '(' a::ArgumentExprList_c ')'
  { top.ast = templateDirectCallExpr(name(id.lexeme, location=id.location), args.ast, foldExpr(a.ast), location=top.location); }
| id::TemplateIdentifier_t '<' args::TemplateArguments_c '>' '(' ')'
  { top.ast = templateDirectCallExpr(name(id.lexeme, location=id.location), args.ast, nilExpr(), location=top.location); }
| id::TemplateIdentifier_t '(' a::ArgumentExprList_c ')'
  { top.ast = templateInferredDirectCallExpr(name(id.lexeme, location=id.location), foldExpr(a.ast), location=top.location); }
| id::TemplateIdentifier_t '(' ')'
  { top.ast = templateInferredDirectCallExpr(name(id.lexeme, location=id.location), nilExpr(), location=top.location); }
  -- For use in silver-ableC
| 'inst' id::Identifier_c '<' args::TemplateArguments_c '>' '(' a::ArgumentExprList_c ')'
  { top.ast = templateDirectCallExpr(id.ast, args.ast, foldExpr(a.ast), location=top.location); }
| 'inst' id::Identifier_c '<' args::TemplateArguments_c '>' '(' ')'
  { top.ast = templateDirectCallExpr(id.ast, args.ast, nilExpr(), location=top.location); }
