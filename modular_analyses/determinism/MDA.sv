grammar determinism;

{- This Silver specification does not generate a useful working 
   compiler, it only serves as a grammar for running the modular
   determinism analysis.
 -}

import edu:umn:cs:melt:ableC:host;
import edu:umn:cs:melt:ableC:concretesyntax;

copper_mda testTemplateStructDecl(ablecParser) {
  edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateStructDecl;
}

copper_mda testTemplateStructForwardDecl(ablecParser) {
  edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateStructForwardDecl;
}

copper_mda testTemplateFunctionDecl(ablecParser) {
  edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateFunctionDecl;
}

copper_mda testTemplateFunctionForwardDecl(ablecParser) {
  edu:umn:cs:melt:exts:ableC:templating:concretesyntax:templateFunctionForwardDecl;
}

copper_mda testUsingDecl(ablecParser) {
  edu:umn:cs:melt:exts:ableC:templating:concretesyntax:usingDecl;
}

copper_mda testInstExpr(ablecParser) {
  edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instantiationExpr;
}

copper_mda testInstTypeExpr(ablecParser) {
  edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instantiationTypeExpr;
}

parser ableCWithTemplates :: Root {
  edu:umn:cs:melt:ableC:concretesyntax;
  edu:umn:cs:melt:exts:ableC:templating:concretesyntax;
}

copper_mda testSilverConstruction(ableCWithTemplates) {
  edu:umn:cs:melt:exts:ableC:templating:silverconstruction;
  edu:umn:cs:melt:exts:silver:ableC:concretesyntax:antiquotation;
  silver:compiler:host:core;
  silver:compiler:extension:patternmatching;
  silver:compiler:extension:list;
  silver:compiler:modification:let_fix;
}
