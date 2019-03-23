grammar edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

synthesized attribute templateParams::[String];
synthesized attribute decl::(Decl ::= Name);
synthesized attribute isItemError::Boolean;

closed nonterminal TemplateItem with templateParams, kinds, decl, maybeParameters, sourceLocation, isItemValue, isItemType, isItemError;

aspect default production
top::TemplateItem ::=
{
  top.maybeParameters = nothing();
  top.isItemType = false;
  top.isItemValue = false;
  top.isItemError = false;
}

abstract production typeTemplateItem
top::TemplateItem ::= sourceLocation::Location params::[String] kinds::[Maybe<TypeName>] decl::(Decl ::= Name)
{
  top.templateParams = params;
  top.kinds = kinds;
  top.decl = decl;
  top.sourceLocation = sourceLocation;
  top.isItemType = true;
}

abstract production valueTemplateItem
top::TemplateItem ::= sourceLocation::Location params::[String] kinds::[Maybe<TypeName>] decl::(Decl ::= Name)
{
  top.templateParams = params;
  top.kinds = kinds;
  top.decl = decl;
  top.sourceLocation = sourceLocation;
  top.isItemValue = true;
}

abstract production templateTypeTemplateItem
top::TemplateItem ::= sourceLocation::Location params::[String] kinds::[Maybe<TypeName>] ty::TypeName
{
  top.templateParams = params;
  top.kinds = kinds;
  top.decl =
    \ mangledName::Name ->
      typedefDecls(
        nilAttribute(),
        ty.bty,
        consDeclarator(
          declarator(mangledName, ty.mty, nilAttribute(), nothingInitializer()),
          nilDeclarator()));
  top.sourceLocation = sourceLocation;
  top.isItemType = true;
}

abstract production functionTemplateItem
top::TemplateItem ::= sourceLocation::Location params::[String] kinds::[Maybe<TypeName>] decl::Decorated FunctionDecl
{
  top.templateParams = params;
  top.kinds = kinds;
  top.decl = instFunctionDeclaration(_, new(decl));
  top.maybeParameters = decl.maybeParameters;
  top.sourceLocation = sourceLocation;
  top.isItemValue = true;
}

abstract production errorTemplateItem
top::TemplateItem ::= 
{
  top.templateParams = [];
  top.kinds = [];
  top.decl = \ n::Name -> decls(nilDecl());
  top.sourceLocation = builtin;
  top.isItemValue = true;
  top.isItemType = true;
  top.isItemError = true;
}

synthesized attribute templates::Scopes<TemplateItem> occurs on Env;
synthesized attribute templateContribs::Contribs<TemplateItem> occurs on Defs, Def;

aspect production emptyEnv_i
top::Env ::=
{
  top.templates = emptyScope();
}
aspect production addEnv_i
top::Env ::= d::Defs  e::Decorated Env
{
  top.templates = addGlobalScope(gd.templateContribs, addScope(d.templateContribs, e.templates));
}
aspect production openScopeEnv_i
top::Env ::= e::Decorated Env
{
  top.templates = openScope(e.templates);
}
aspect production globalEnv_i
top::Env ::= e::Decorated Env
{
  top.templates = globalScope(e.templates);
}
aspect production nonGlobalEnv_i
top::Env ::= e::Decorated Env
{
  top.templates = nonGlobalScope(e.templates);
}

aspect production nilDefs
top::Defs ::=
{
  top.templateContribs = [];
}
aspect production consDefs
top::Defs ::= h::Def  t::Defs
{
  top.templateContribs = h.templateContribs ++ t.templateContribs;
}

aspect default production
top::Def ::=
{
  top.templateContribs = [];
}

abstract production templateDef
top::Def ::= s::String  t::TemplateItem
{
  top.templateContribs = [pair(s, t)];
}

function lookupTemplate
[TemplateItem] ::= n::String  e::Decorated Env
{
  return lookupScope(n, e.templates);
}

synthesized attribute templateItem::Decorated TemplateItem occurs on Name;
synthesized attribute templateLookupCheck::[Message] occurs on Name;
synthesized attribute templateRedeclarationCheck::[Message] occurs on Name;

aspect production name
top::Name ::= n::String
{
  local templates::[TemplateItem] = lookupTemplate(n, top.env);
  top.templateLookupCheck =
    case templates of
    | [] -> [err(top.location, "Undeclared templated name " ++ n)]
    | _ :: _ -> []
    end;
  
  top.templateRedeclarationCheck =
    case templates of
    | [] -> []
    | v :: _ ->
        [err(top.location, 
          "Redeclaration of " ++ n ++ ". Original (from " ++
          v.sourceLocation.unparse ++ ")")]
    end;
  
  local template::TemplateItem = if null(templates) then errorTemplateItem() else head(templates);
  top.templateItem = template;
}