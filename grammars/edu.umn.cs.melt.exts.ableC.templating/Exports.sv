grammar edu:umn:cs:melt:exts:ableC:templating;

exports edu:umn:cs:melt:exts:ableC:templating:concretesyntax;
exports edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

exports edu:umn:cs:melt:exts:ableC:templating:silverconstruction
   with edu:umn:cs:melt:ableC:silverconstruction:concretesyntax:antiquotation;
-- Include this in the main extension artifact, for now.
-- In theory, we could build a seperate artifact containing the Silver ableC construction utilties.
imports edu:umn:cs:melt:exts:ableC:templating:silverconstruction only ;
