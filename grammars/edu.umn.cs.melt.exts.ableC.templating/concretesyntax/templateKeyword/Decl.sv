grammar edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateKeyword;

imports edu:umn:cs:melt:ableC:concretesyntax;

marking terminal Template_t 'template' lexer classes {Ckeyword};
marking terminal Inst_t     'inst'     lexer classes {Ckeyword}, precedence=1;
