import macros

dumpTree:
  type
    MyAppCoanfig = ref object
      address: string
      port: int
      isDebug:bool

# ❶config宏接受类型名和字段列表。
# ❷每个宏都必须返回一个有效的AST，因此我们在这里创建一个基本的AST。
# ❸现在，我们显示typeName和fields参数的AST。

# # 根据给定的NimNode，创建
proc createRefType(ident: NimIdent, identDefs: seq[NimNode]): NimNode =   
  result = newTree(nnkTypeSection,   
    newTree(nnkTypeDef,      
      newIdentNode(ident),   
      newEmptyNode(),        
      newTree(nnkRefTy,
        newTree(nnkObjectTy,
          newEmptyNode(),    
          newEmptyNode(),    
          newTree(nnkRecList,
            identDefs
          )
        )
      )
    )
  )


proc toIdentDefs(stmtList: NimNode): seq[NimNode] =
  expectKind(stmtList, nnkStmtList)   
  result = @[]        
  for child in stmtList:              
    expectKind(child, nnkCall)        
    result.add(       
      newIdentDefs(   
        child[0],     
        child[1][0]   
      )
    )



template constructor(ident: untyped): untyped =
  proc `new ident`(): `ident` =
    new result


proc createLoadProc(typeName: NimIdent, identDefs: seq[NimNode]): NimNode =
  var cfgIdent = newIdentNode("cfg")   
  var filenameIdent = newIdentNode("filename")   
  var objIdent = newIdentNode("obj")  
  var body = newStmtList()   
  body.add quote do:         
    var `objIdent` = parseFile(`filenameIdent`)

  for identDef in identDefs:                
    let fieldNameIdent = identDef[0]        
    let fieldName = $fieldNameIdent.ident   
    echo("---------------")
    echo($identDef[1].ident)
    case $identDef[1].ident                 
    of "string":
      body.add quote do:
        `cfgIdent`.`fieldNameIdent` = `objIdent`[`fieldName`].getStr         
    of "int":
      body.add quote do:
        `cfgIdent`.`fieldNameIdent` = `objIdent`[`fieldName`].getInt 
    of "bool":
      body.add quote do:
        `cfgIdent`.`fieldNameIdent` = `objIdent`[`fieldName`].getBool 
    else:
      doAssert(false, "Not Implemented")  
    
  return newProc(newIdentNode("load"),   
  [newEmptyNode(),   
    newIdentDefs(cfgIdent, newIdentNode(typeName)),         
    newIdentDefs(filenameIdent, newIdentNode("string"))],   
  body)              





macro config(typeName: untyped, fields: untyped): untyped =   
  result = newStmtList()  
  let identDefs = toIdentDefs(fields)
  result.add createRefType(typeName.ident, identDefs)  
  result.add getAst(constructor(typeName.ident))
  #调用 createload
  result.add createLoadProc(typeName.ident, identDefs)

# 重复的typeName，重复的dields  
  echo treeRepr(typeName)   
  echo treeRepr(fields)  

  # 打印结果
  echo("打印结果---AST---")
  echo treeRepr(result)   
  echo("打印结果---生成的代码---")
  echo repr(result)


#----------------------
# config MyAppConfig:
#   address: string
#   port: int

# proc newMyAppConfig(): MyAppConfig =
#   new result

# 测试代码
import json

config MyAppConfig:
  address: string
  port: int
  isDebug: bool

var myConf = newMyAppConfig()
myConf.load("conf.json")
echo("Address: ", myConf.address)
echo("Port: ", myConf.port)
echo("isDebug: ", myConf.isDebug)