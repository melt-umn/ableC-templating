grammar edu:umn:cs:melt:exts:ableC:templating:abstractsyntax;

monoid attribute inferredArgs::[Pair<String TemplateArg>] with [], ++;
attribute inferredArgs occurs on Parameters, ParameterDecl, TypeNames, TypeName, BaseTypeExpr, TypeModifierExpr;
inherited attribute argumentTypes::[Type] occurs on TypeNames, Parameters;
inherited attribute argumentType::Type occurs on ParameterDecl, TypeName, BaseTypeExpr, TypeModifierExpr;
synthesized attribute argumentBaseType::Type occurs on TypeModifierExpr;

-- Forward deps only needed here due to MWDA, since this these are extension attributes.
flowtype inferredArgs {decorate, argumentTypes} on TypeNames, Parameters;
flowtype inferredArgs {decorate, argumentType} on ParameterDecl, TypeName, BaseTypeExpr, TypeModifierExpr;
flowtype argumentBaseType {decorate, argumentType} on TypeModifierExpr;

propagate inferredArgs on Parameters, ParameterDecl, TypeNames, TypeName, BaseTypeExpr, TypeModifierExpr;

aspect production consParameters
top::Parameters ::= h::ParameterDecl  t::Parameters
{
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

aspect production parameterDecl
top::ParameterDecl ::= storage::StorageClasses  bty::BaseTypeExpr  mty::TypeModifierExpr  name::MaybeName  attrs::Attributes
{
  mty.argumentType = top.argumentType;
  bty.argumentType = mty.argumentBaseType;
}

aspect production consTypeName
top::TypeNames ::= h::TypeName t::TypeNames
{
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

aspect production typeName
top::TypeName ::= bty::BaseTypeExpr  mty::TypeModifierExpr
{
  bty.argumentType = mty.argumentBaseType;
  mty.argumentType = top.argumentType;
}

aspect production errorTypeExpr
top::BaseTypeExpr ::= msg::[Message]
{}

aspect production warnTypeExpr
top::BaseTypeExpr ::= msg::[Message]  ty::BaseTypeExpr
{
  ty.argumentType = top.argumentType;
}

aspect production decTypeExpr
top::BaseTypeExpr ::= ty::Decorated BaseTypeExpr
{
  top.inferredArgs <- newTy.inferredArgs;
  local newTy::BaseTypeExpr = new(ty);
  newTy.env = top.env;
  newTy.returnType = top.returnType;
  newTy.breakValid = top.breakValid;
  newTy.continueValid = top.continueValid;
  newTy.givenRefId = top.givenRefId;
  newTy.argumentType = top.argumentType;
}

aspect production defsTypeExpr
top::BaseTypeExpr ::= d::[Def]  bty::BaseTypeExpr
{
  bty.argumentType = top.argumentType;
}

aspect production typeModifierTypeExpr
top::BaseTypeExpr ::= bty::BaseTypeExpr  mty::TypeModifierExpr
{
  bty.argumentType = mty.argumentBaseType;
  mty.argumentType = top.argumentType;
}

aspect production typedefTypeExpr
top::BaseTypeExpr ::= q::Qualifiers  name::Name
{
  top.inferredArgs <-
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
  bt.argumentType = top.argumentType;
}

aspect production atomicTypeExpr
top::BaseTypeExpr ::= q::Qualifiers  wrapped::TypeName
{
  wrapped.argumentType =
    case top.argumentType of
    | atomicType(_, t) -> t
    | _ -> errorType()
    end;
}

aspect production injectGlobalDeclsTypeExpr
top::BaseTypeExpr ::= decls::Decls lifted::BaseTypeExpr
{
  lifted.argumentType = top.argumentType;
}

aspect production baseTypeExpr
top::TypeModifierExpr ::=
{
  top.argumentBaseType = top.argumentType;
}

aspect production modifiedTypeExpr
top::TypeModifierExpr ::= bty::BaseTypeExpr
{
  top.argumentBaseType = errorType(); -- TODO: ???
  bty.argumentType = top.argumentType;
}

aspect production decTypeModifierExpr
top::TypeModifierExpr ::= ty::Decorated TypeModifierExpr
{
  top.inferredArgs <- newTy.inferredArgs;
  top.argumentBaseType = newTy.argumentBaseType;
  local newTy::TypeModifierExpr = new(ty);
  newTy.env = top.env;
  newTy.returnType = top.returnType;
  newTy.breakValid = top.breakValid;
  newTy.continueValid = top.continueValid;
  newTy.baseType = top.baseType;
  newTy.typeModifierIn = top.typeModifierIn;
  newTy.argumentType = top.argumentType;
}

aspect production pointerTypeExpr
top::TypeModifierExpr ::= q::Qualifiers  target::TypeModifierExpr
{
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
  top.argumentBaseType = wrapped.argumentBaseType;
  wrapped.argumentType = top.argumentType;
}
