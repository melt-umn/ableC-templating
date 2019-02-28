grammar edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

synthesized attribute inferredArgs::[Pair<String TemplateArg>] occurs on Parameters, ParameterDecl, TypeNames, TypeName, BaseTypeExpr, TypeModifierExpr;
inherited attribute argumentTypes::[Type] occurs on TypeNames, Parameters;
inherited attribute argumentType::Type occurs on ParameterDecl, TypeName, BaseTypeExpr, TypeModifierExpr;
synthesized attribute argumentBaseType::Type occurs on TypeModifierExpr;

aspect production consParameters
top::Parameters ::= h::ParameterDecl  t::Parameters
{
  top.inferredArgs = h.inferredArgs ++ t.inferredArgs;
  h.argumentType =
    case top.argumentTypes of
    | [] -> errorType()
    | h :: t -> h
    end;
  t.argumentTypes =
    case top.argumentTypes of
    | [] -> []
    | h :: t -> t
    end;
}

aspect production nilParameters
top::Parameters ::=
{
  top.inferredArgs = [];
}

aspect production parameterDecl
top::ParameterDecl ::= storage::StorageClasses  bty::BaseTypeExpr  mty::TypeModifierExpr  name::MaybeName  attrs::Attributes
{
  top.inferredArgs = bty.inferredArgs ++ mty.inferredArgs;
  mty.argumentType = top.argumentType;
  bty.argumentType = mty.argumentBaseType;
}

aspect production consTypeName
top::TypeNames ::= h::TypeName t::TypeNames
{
  top.inferredArgs = h.inferredArgs ++ t.inferredArgs;
  h.argumentType =
    case top.argumentTypes of
    | [] -> errorType()
    | h :: t -> h
    end;
  t.argumentTypes =
    case top.argumentTypes of
    | [] -> []
    | h :: t -> t
    end;
}

aspect production nilTypeName
top::TypeNames ::= 
{
  top.inferredArgs = [];
}

aspect production typeName
top::TypeName ::= bty::BaseTypeExpr  mty::TypeModifierExpr
{
  top.inferredArgs = bty.inferredArgs;
  bty.argumentType = mty.argumentBaseType;
  mty.argumentType = top.argumentType;
}

aspect production errorTypeExpr
top::BaseTypeExpr ::= msg::[Message]
{
  top.inferredArgs = [];
}

aspect production warnTypeExpr
top::BaseTypeExpr ::= msg::[Message]  ty::BaseTypeExpr
{
  top.inferredArgs = ty.inferredArgs;
  ty.argumentType = top.argumentType;
}

aspect production decTypeExpr
top::BaseTypeExpr ::= ty::Decorated BaseTypeExpr
{
  top.inferredArgs = newTy.inferredArgs;
  local newTy::BaseTypeExpr = new(ty);
  newTy.env = top.env;
  newTy.returnType = top.returnType;
  newTy.givenRefId = top.givenRefId;
  newTy.argumentType = top.argumentType;
}

aspect production defsTypeExpr
top::BaseTypeExpr ::= d::[Def]  bty::BaseTypeExpr
{
  top.inferredArgs = bty.inferredArgs;
  bty.argumentType = top.argumentType;
}

aspect production typeModifierTypeExpr
top::BaseTypeExpr ::= bty::BaseTypeExpr  mty::TypeModifierExpr
{
  top.inferredArgs = bty.inferredArgs ++ mty.inferredArgs;
  bty.argumentType = mty.argumentBaseType;
  mty.argumentType = top.argumentType;
}

aspect production builtinTypeExpr
top::BaseTypeExpr ::= q::Qualifiers  result::BuiltinType
{
  top.inferredArgs = [];
}

aspect production tagReferenceTypeExpr
top::BaseTypeExpr ::= q::Qualifiers  kwd::StructOrEnumOrUnion  n::Name
{
  top.inferredArgs = [];
}

aspect production structTypeExpr
top::BaseTypeExpr ::= q::Qualifiers  def::StructDecl
{
  top.inferredArgs = [];
}

aspect production unionTypeExpr
top::BaseTypeExpr ::= q::Qualifiers  def::UnionDecl
{
  top.inferredArgs = [];
}

aspect production enumTypeExpr
top::BaseTypeExpr ::= q::Qualifiers  def::EnumDecl
{
  top.inferredArgs = [];
}

aspect production extTypeExpr
top::BaseTypeExpr ::= q::Qualifiers  sub::ExtType
{
  top.inferredArgs = [];
}

aspect production typedefTypeExpr
top::BaseTypeExpr ::= q::Qualifiers  name::Name
{
  top.inferredArgs =
    case top.argumentType of
    | errorType() -> [] -- We might find an actual type later on
    -- TODO: Better treatment of type qualifiers here, maybe?
    -- Take union of all positive qualifiers and intersection of all negative qualifiers
    | t -> [pair(name.name, typeTemplateArg(t.withoutTypeQualifiers))]
    end;
}

aspect production attributedTypeExpr
top::BaseTypeExpr ::= attrs::Attributes  bt::BaseTypeExpr
{
  top.inferredArgs = bt.inferredArgs;
  bt.argumentType = top.argumentType;
}

aspect production atomicTypeExpr
top::BaseTypeExpr ::= q::Qualifiers  wrapped::TypeName
{
  top.inferredArgs = wrapped.inferredArgs;
  wrapped.argumentType =
    case top.argumentType of
    | atomicType(_, t) -> t
    | _ -> errorType()
    end;
}

aspect production vaListTypeExpr
top::BaseTypeExpr ::=
{
  top.inferredArgs = [];
}

aspect production typeofTypeExpr
top::BaseTypeExpr ::= q::Qualifiers  e::ExprOrTypeName
{
  top.inferredArgs = [];
}

aspect production injectGlobalDeclsTypeExpr
top::BaseTypeExpr ::= decls::Decls lifted::BaseTypeExpr
{
  top.inferredArgs = lifted.inferredArgs;
  lifted.argumentType = top.argumentType;
}

aspect production baseTypeExpr
top::TypeModifierExpr ::=
{
  top.inferredArgs = [];
  top.argumentBaseType = top.argumentType;
}

aspect production modifiedTypeExpr
top::TypeModifierExpr ::= bty::BaseTypeExpr
{
  top.inferredArgs = bty.inferredArgs;
  top.argumentBaseType = errorType(); -- TODO: ???
  bty.argumentType = top.argumentType;
}

aspect production decTypeModifierExpr
top::TypeModifierExpr ::= ty::Decorated TypeModifierExpr
{
  top.inferredArgs = newTy.inferredArgs;
  top.argumentBaseType = newTy.argumentBaseType;
  local newTy::TypeModifierExpr = new(ty);
  newTy.env = top.env;
  newTy.returnType = top.returnType;
  newTy.baseType = top.baseType;
  newTy.typeModifiersIn = top.typeModifiersIn;
  newTy.argumentType = top.argumentType;
}

aspect production pointerTypeExpr
top::TypeModifierExpr ::= q::Qualifiers  target::TypeModifierExpr
{
  top.inferredArgs = target.inferredArgs;
  top.argumentBaseType = target.argumentBaseType;
  target.argumentType =
    case top.argumentType.defaultFunctionArrayLvalueConversion of
    | pointerType(_, t) -> t
    | _ -> errorType()
    end;
}

aspect production arrayTypeExprWithExpr
top::TypeModifierExpr ::= element::TypeModifierExpr  indexQualifiers::Qualifiers  sizeModifier::ArraySizeModifier  size::Expr
{
  top.inferredArgs = element.inferredArgs;
  top.argumentBaseType = element.argumentBaseType;
  element.argumentType =
    case top.argumentType.defaultFunctionArrayLvalueConversion of
    | pointerType(_, t) -> t
    | _ -> errorType()
    end;
}

aspect production arrayTypeExprWithoutExpr
top::TypeModifierExpr ::= element::TypeModifierExpr  indexQualifiers::Qualifiers  sizeModifier::ArraySizeModifier
{
  top.inferredArgs = element.inferredArgs;
  top.argumentBaseType = element.argumentBaseType;
  element.argumentType =
    case top.argumentType.defaultFunctionArrayLvalueConversion of
    | pointerType(_, t) -> t
    | _ -> errorType()
    end;
}

aspect production functionTypeExprWithArgs
top::TypeModifierExpr ::= result::TypeModifierExpr  args::Parameters  variadic::Boolean  q::Qualifiers
{
  top.inferredArgs = result.inferredArgs ++ args.inferredArgs;
  top.argumentBaseType = result.argumentBaseType;
  result.argumentType =
    case top.argumentType of
    | functionType(t, _, _) -> t
    | _ -> errorType()
    end;
  args.argumentTypes =
    case top.argumentType of
    | functionType(_, protoFunctionType(ts, _), _) -> ts
    | _ -> []
    end;
}

aspect production functionTypeExprWithoutArgs
top::TypeModifierExpr ::= result::TypeModifierExpr  ids::[Name]  q::Qualifiers
{
  top.inferredArgs = result.inferredArgs;
  top.argumentBaseType = result.argumentBaseType;
  result.argumentType =
    case top.argumentType of
    | functionType(t, _, _) -> t
    | _ -> errorType()
    end;
}

aspect production parenTypeExpr
top::TypeModifierExpr ::= wrapped::TypeModifierExpr
{
  top.inferredArgs = wrapped.inferredArgs;
  top.argumentBaseType = wrapped.argumentBaseType;
  wrapped.argumentType = top.argumentType;
}
