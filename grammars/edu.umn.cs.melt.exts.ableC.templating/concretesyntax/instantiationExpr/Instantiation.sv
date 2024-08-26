grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instantiationExpr;

imports silver:langutil only ast;

imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:concretesyntax;

imports edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instKeyword;
exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateArguments;

marking terminal TemplateIdentifier_t /[A-Za-z_\$][A-Za-z_0-9\$]*/ lexer classes {Identifier, Scoped};

concrete productions top::UnaryExpr_c
| id::TemplateIdentifier_t '<' args::TemplateArguments_c '>'
  { top.ast = templateDirectRefExpr(name(id.lexeme), args.ast); }
  -- For use in silver-ableC
| 'inst' id::Identifier_c '<' args::TemplateArguments_c '>'
  { top.ast = templateDirectRefExpr(id.ast, args.ast); }

concrete productions top::PrimaryExpr_c
| id::TemplateIdentifier_t '<' args::TemplateArguments_c '>' '(' a::ArgumentExprList_c ')'
  { top.ast = templateDirectCallExpr(name(id.lexeme), args.ast, foldExpr(a.ast)); }
| id::TemplateIdentifier_t '<' args::TemplateArguments_c '>' '(' ')'
  { top.ast = templateDirectCallExpr(name(id.lexeme), args.ast, nilExpr()); }
| id::TemplateIdentifier_t '(' a::ArgumentExprList_c ')'
  { top.ast = templateInferredDirectCallExpr(name(id.lexeme), foldExpr(a.ast)); }
| id::TemplateIdentifier_t '(' ')'
  { top.ast = templateInferredDirectCallExpr(name(id.lexeme), nilExpr()); }
  -- For use in silver-ableC
| 'inst' id::Identifier_c '<' args::TemplateArguments_c '>' '(' a::ArgumentExprList_c ')'
  { top.ast = templateDirectCallExpr(id.ast, args.ast, foldExpr(a.ast)); }
| 'inst' id::Identifier_c '<' args::TemplateArguments_c '>' '(' ')'
  { top.ast = templateDirectCallExpr(id.ast, args.ast, nilExpr()); }
