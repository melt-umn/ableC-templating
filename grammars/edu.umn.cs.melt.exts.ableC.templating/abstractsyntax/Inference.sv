grammar edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

synthesized attribute inferredTypes::[Pair<String Type>] occurs on Parameters, ParameterDecl, TypeNames, TypeName, BaseTypeExpr, TypeModifierExpr;
inherited attribute argumentTypes::[Type] occurs on TypeNames, Parameters;
inherited attribute argumentType::Type occurs on ParameterDecl, TypeName, BaseTypeExpr, TypeModifierExpr;
synthesized attribute argumentBaseType::Type occurs on TypeModifierExpr;

aspect production consParameters
top::Parameters ::= h::ParameterDecl  t::Parameters
{
  top.inferredTypes = h.inferredTypes ++ t.inferredTypes;
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
  top.inferredTypes = [];
}

aspect production parameterDecl
top::ParameterDecl ::= storage::StorageClasses  bty::BaseTypeExpr  mty::TypeModifierExpr  name::MaybeName  attrs::Attributes
{
  top.inferredTypes = bty.inferredTypes ++ mty.inferredTypes;
  mty.argumentType = top.argumentType;
  bty.argumentType = mty.argumentBaseType;
}

aspect production consTypeName
top::TypeNames ::= h::TypeName t::TypeNames
{
  top.inferredTypes = h.inferredTypes ++ t.inferredTypes;
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
  top.inferredTypes = [];
}

aspect production typeName
top::TypeName ::= bty::BaseTypeExpr  mty::TypeModifierExpr
{
  top.inferredTypes = bty.inferredTypes;
  bty.argumentType = mty.argumentBaseType;
  mty.argumentType = top.argumentType;
}

aspect production errorTypeExpr
top::BaseTypeExpr ::= msg::[Message]
{
  top.inferredTypes = [];
}

aspect production warnTypeExpr
top::BaseTypeExpr ::= msg::[Message]  ty::BaseTypeExpr
{
  top.inferredTypes = ty.inferredTypes;
  ty.argumentType = top.argumentType;
}

aspect production decTypeExpr
top::BaseTypeExpr ::= ty::Decorated BaseTypeExpr
{
  top.inferredTypes = newTy.inferredTypes;
  local newTy::BaseTypeExpr = new(ty);
  newTy.env = top.env;
  newTy.returnType = top.returnType;
  newTy.givenRefId = top.givenRefId;
  newTy.argumentType = top.argumentType;
}

aspect production defsTypeExpr
top::BaseTypeExpr ::= d::[Def]  bty::BaseTypeExpr
{
  top.inferredTypes = bty.inferredTypes;
  bty.argumentType = top.argumentType;
}

aspect production typeModifierTypeExpr
top::BaseTypeExpr ::= bty::BaseTypeExpr  mty::TypeModifierExpr
{
  top.inferredTypes = bty.inferredTypes ++ mty.inferredTypes;
  bty.argumentType = mty.argumentBaseType;
  mty.argumentType = top.argumentType;
}

aspect production builtinTypeExpr
top::BaseTypeExpr ::= q::Qualifiers  result::BuiltinType
{
  top.inferredTypes = [];
}

aspect production tagReferenceTypeExpr
top::BaseTypeExpr ::= q::Qualifiers  kwd::StructOrEnumOrUnion  n::Name
{
  top.inferredTypes = [];
}

aspect production structTypeExpr
top::BaseTypeExpr ::= q::Qualifiers  def::StructDecl
{
  top.inferredTypes = [];
}

aspect production unionTypeExpr
top::BaseTypeExpr ::= q::Qualifiers  def::UnionDecl
{
  top.inferredTypes = [];
}

aspect production enumTypeExpr
top::BaseTypeExpr ::= q::Qualifiers  def::EnumDecl
{
  top.inferredTypes = [];
}

aspect production extTypeExpr
top::BaseTypeExpr ::= q::Qualifiers  sub::ExtType
{
  top.inferredTypes = [];
}

aspect production typedefTypeExpr
top::BaseTypeExpr ::= q::Qualifiers  name::Name
{
  top.inferredTypes = [pair(name.name, top.argumentType)];
}

aspect production attributedTypeExpr
top::BaseTypeExpr ::= attrs::Attributes  bt::BaseTypeExpr
{
  top.inferredTypes = bt.inferredTypes;
  bt.argumentType = top.argumentType;
}

aspect production atomicTypeExpr
top::BaseTypeExpr ::= q::Qualifiers  wrapped::TypeName
{
  top.inferredTypes = wrapped.inferredTypes;
  wrapped.argumentType =
    case top.argumentType of
    | atomicType(_, t) -> t
    | _ -> errorType()
    end;
}

aspect production vaListTypeExpr
top::BaseTypeExpr ::=
{
  top.inferredTypes = [];
}

aspect production typeofTypeExpr
top::BaseTypeExpr ::= q::Qualifiers  e::ExprOrTypeName
{
  top.inferredTypes = [];
}

aspect production injectGlobalDeclsTypeExpr
top::BaseTypeExpr ::= decls::Decls lifted::BaseTypeExpr
{
  top.inferredTypes = lifted.inferredTypes;
  lifted.argumentType = top.argumentType;
}

aspect production baseTypeExpr
top::TypeModifierExpr ::=
{
  top.inferredTypes = [];
  top.argumentBaseType = top.argumentType;
}

aspect production modifiedTypeExpr
top::TypeModifierExpr ::= bty::BaseTypeExpr
{
  top.inferredTypes = bty.inferredTypes;
  top.argumentBaseType = errorType(); -- TODO: ???
  bty.argumentType = top.argumentType;
}

aspect production decTypeModifierExpr
top::TypeModifierExpr ::= ty::Decorated TypeModifierExpr
{
  top.inferredTypes = newTy.inferredTypes;
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
  top.inferredTypes = target.inferredTypes;
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
  top.inferredTypes = element.inferredTypes;
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
  top.inferredTypes = element.inferredTypes;
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
  top.inferredTypes = result.inferredTypes ++ args.inferredTypes;
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
  top.inferredTypes = result.inferredTypes;
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
  top.inferredTypes = wrapped.inferredTypes;
  top.argumentBaseType = wrapped.argumentBaseType;
  wrapped.argumentType = top.argumentType;
}
