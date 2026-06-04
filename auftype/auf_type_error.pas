unit auf_type_error;


{$mode objfpc}{$H+}

interface
uses Classes;

type

  TAufScriptError = (
    AufsErr_NoFunction,
    AufsErr_NoOperator,
    AufsErr_NoVarType,
    AufsErr_NoNamedParam,
    AufsErr_InvalidDefName,
    AufsErr_PreservedDefName,
    AufsErr_GlobalRamVar,
    AufsErr_CastNonRamVar,
    AufsErr_ProtectedDefName,
    AufsErr_ConflictDefName,
    AufsErr_DefNameNotFound,
    AufsErr_AddressNotFound,
    AufsErr_AddressInvalid,
    AufsErr_AddressRecursive,
    AufsErr_ParamCount,
    AufsErr_ParamType,
    AufsErr_ParamSize,
    AufsErr_RamVarExpected,
    AufsErr_RamVarInvalid,
    AufsErr_Numeric,
    AufsErr_Convert,
    AufsErr_DividedByZero,
    AufsErr_StackOverflow,
    AufsErr_StackInvalid,
    AufsErr_FileNotExists,
    AufsErr_FileIOFailed,
    AufsErr_ScreenFile,
    AufsErr_TaskNotFound,
    AufsErr_TaskNotEnabled,
    AufsErr_TaskNoMsg,
    AufsErr_DefTime,
    AufsErr_EncTime,
    AufsErr_RunTime,
    AufsErr_PlatformUnimplemented,
    AufsErr_CanvasNotFound,

    AufsErr_TemporaryARVRelease,
    AufsErr_ConvertSameVarType,
    AufsErr_PlatformUnimplementedFloat,

    AufsErr_NoError = 1,
    AufsErr_Unknown = 0
  );

var AufScriptErrorPromptMap:TStringList;

function EnsureNoError(err:TAufScriptError; AufScpt:TObject):boolean; //如果err不是NoError返回false

implementation
uses Apiglio_Useful;

var index:integer;

function EnsureNoError(err:TAufScriptError; AufScpt:TObject):boolean;
begin
  result:=true;
  if err=AufsErr_NoError then exit;
  with AufScpt as TAufScript do send_error(AufScriptErrorPromptMap[Ord(err)],err);
end;

initialization

  AufScriptErrorPromptMap:=TStringList.Create;
  for index:=0 to Ord(High(TAufScriptError)) do AufScriptErrorPromptMap.Add('');
  //0是用不到的
  AufScriptErrorPromptMap[Ord(AufsErr_TemporaryARVRelease)]:='警告：正在试图释放非临时AufRamVar，已被拒绝。';
  AufScriptErrorPromptMap[Ord(AufsErr_ConvertSameVarType)]:='警告：正在试图转换AufRamVar为相同类型，已使用copyARV。';
  AufScriptErrorPromptMap[Ord(AufsErr_PlatformUnimplementedFloat)]:='警告：自定义长度浮点型AufRamVar尚不支持。';



finalization
  AufScriptErrorPromptMap.Free;


end.

