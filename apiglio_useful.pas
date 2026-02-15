UNIT Apiglio_Useful;

{$mode objfpc}{$H+}
{$goto on}
{$M+}
{$TypedAddress off}
{$inline on}

{$if defined(WINDOWS)}
  {$define MsgTimerMode}
  {$define SynEditMode}
{$elseif defined(UNIX)}
  {$define SynEditMode}
{$endif}

{$if defined(MsgTimerMode)}
{$else}
'Windows下的多线程会卡死AufFrame'
{$endif}

//{$define TEST_MODE}//开启这个模式会导致没有命令行的GUI报错

INTERFACE

//{$UNITPATH ./auftype}
//{$UNITPATH ./aufkernel}
uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF WINDOWS}
  Windows, WinCrt, Interfaces, Dos,
  {$ENDIF}
  {$IFDEF ANDROID}
  AndroidWidget,
  {$ENDIF}
  {$ifdef SynEditMode}
  SynEdit, SynHighlighterAuf,
  {$endif}
  Classes, SysUtils, Registry, FileUtil,
  {$ifdef MsgTimerMode}
  ExtCtrls, Controls, Forms,
  {$else}
  aufscript_thread,
  {$endif}
  {$ifdef can_be_removed}
  StdCtrls,
  {$endif}
  LazUTF8, RegExpr, Variants,
  Auf_Ram_Var, Auf_Ram_Image,
  auf_type_base, auf_type_array,
  kernel;

const

  AufScript_Version='beta 2.7.0.2';
  {$if defined(cpu32)}
  AufScript_CPU='32bits';
  {$elseif defined(cpu64)}
  AufScript_CPU='64bits';
  {$else}
  AufScript_CPU='Unknown CPU';
  {$endif}
  {$if defined(WINDOWS)}
  AufScript_OS='Windows';
  {$elseif defined(UNIX)}
    {$ifdef ANDROID}
    AufScript_OS='Android';
    {$else}
    AufScript_OS='Unix';
    {$endif}
  {$else}
  AufScript_OS='Unknown OS';
  {$endif}

  CRLF = {$ifdef Windows} #13#10 {$else} #10 {$endif};
  c_space=[' ',#9];
  c_divi=[' ',','];//隔断符号
  c_iden=['~','@','$','#',':','&'];//变量符号，前后缀符号
  c_toto=c_divi+c_iden;
  ram_range=$20000{4096}{32};//变量区大小
  stack_range=32;//行数堆栈区大小，最多支持256个
  func_range=1024;//256;//函数区大小，最多支持65536个
  args_range=16;//函数参数最大数量
  task_range=128;//跨任务消息存储条数限制

  {$IFDEF MsgTimerMode}
  AufProcessControl_RunFirst = WM_USER + 19950;
  AufProcessControl_RunNext = WM_USER + 19951;
  AufProcessControl_RunClose = WM_USER + 19952;
  {$ENDIF}

  {$I constants.inc}


type

  TAufScript = class;
  pRam = {$ifdef cpu64}QWord{$else}DWord{$endif};//内存编号

  {Usf  工具库}
  pFuncFileByte= procedure(str:string);
  TUsf= class
    published
      function zeroplus(num:word;bit:byte):ansistring;inline;
      function blankplus(len:byte):ansistring;inline;
      function fullblankplus(len:byte):ansistring;inline;
      function left_adjust(str:string;len:byte;block:byte=8):string;
      function right_adjust(str:string;len:byte;block:byte=8):string;
      function to_s(num:double):ansistring;inline;
      function f_to_s(num:double;n:byte):ansistring;inline;
      function i_to_s(i:int64):ansistring;inline;
      function to_i(str:ansistring):int64;inline;
      function to_f(str:ansistring):double;inline;

      function to_hex(inp:qword;len:byte):ansistring;
      function to_binary(inp:qword;len:byte):ansistring;

      procedure reg_add(_key,_var,_data:string);
      function reg_query(_key,_var:string):string;
      {$ifdef WINDOWS}
      procedure each_file(path:ansistring;func_ptr:pFuncFileByte);//查找路径下所有文件，并将目标字符串作为函数自变量运行func_ptr，例如Usf.each_file('F:\Temp',@writeln)
      procedure each_file_in_folder(path:ansistring;func_ptr:pFuncFileByte);//查找文件夹中所有文件，并将目标字符串作为函数自变量运行func_ptr
      {$endif}
    public
      constructor Create;
  end;

  Tnargs=record //新的参数记录方式，新的Args[],记得开始使用
    arg:string;
    pre,post:string[8];
  end;
  TJumpMode=(jmNot,jmCall);
  TJumpModeSet=set of TJumpMode;

  TMsgUuid = TGUID;
  TMsgCode = (mcUnknown=0, mcNormal=1, mcBroadcast=2);
  TMsgItem = record
    From:TAufScript;
    Data:TAufRamVar;
    Code:TMsgCode;
  end;

  {$ifdef MsgTimerMode}
  TAufTimer=class(TTimer)
  public
    AufScript:TObject;
    procedure OnTimerResume(Sender:TObject);
    constructor Create(AOwner:TComponent;AAufScript:TObject);
  end;
  TAufMultiTaskTimer=class(TTimer)
  public
    AufScript:TObject;
    procedure OnTimerResume(Sender:TObject);
    constructor Create(AOwner:TComponent;AAufScript:TObject);
  end;

  ACBase = {TForm}TWinControl;
  TAufControl=class(ACBase)
    constructor Create(AOwner:TComponent);
  public
    FAuf,FAufScpt:TObject;
  public
    procedure RunFirst(var Msg:TMessage);message AufProcessControl_RunFirst;
    procedure RunNext(var Msg:TMessage);message AufProcessControl_RunNext;
    procedure RunClose(var Msg:TMessage);message AufProcessControl_RunClose;
    class function ClassType:String;
  end;
  {$endif}

  TAufExpressionUnit = class(TObject)
  public
    key:string;
    value:Tnargs;
    readonly:boolean;
    constructor Create(AKey:string;AValue:Tnargs;AReadOnly:boolean=false);
    function TryEdit(NewValue:Tnargs):boolean;
  end;

  TAufExpressionList = class(TList)
  public
    function Find(AKey:string):TAufExpressionUnit;
    function Translate(AKey:string):Tnargs;
    function TryAddExp(AKey:string;AValue:Tnargs):boolean;
    function TryRenameExp(OldKey,NewKey:string):boolean;
    function TryDeleteExp(Key:string):boolean;
  end;

  TAufMultiTaskList = class(TStringList)
    function AddTask(AufScpt:TAufscript):boolean;
    function FindTask(task_id:TMsgUuid):TAufScript;
    function DelTask(AufScpt:TAufscript):boolean;
  public
    constructor Create;
  end;

  TAufTaskMessageQueue = class
  private
    FUUID:TMsgUuid;
    FQueue:array[0..task_range-1] of TMsgItem;
    FFirst:Integer;
    FCount:Integer;
  protected
    function GetQueueItem(Index:Integer):TMsgItem;
  public
    function Append(Msg:TMsgItem):boolean;
    function Pop:TMsgItem;
    procedure Clear;
    constructor Create;
    destructor Destroy; override;
    property UUID:TMsgUuid read FUUID;
    property Count:Integer read FCount;
    property First:Integer read FFirst;
    property Items[Index:Integer]:TMsgItem read GetQueueItem;
  end;


  //用于AufScript的内存读取和计算

  {TAufScript}
  pFunc      = procedure;
  pFuncStr   = procedure(str:string);
  pFuncVarStr= procedure(var str:string);
  pFuncAuf   = procedure(Sender:TObject);
  pFuncAufStr= procedure(Sender:TObject;str:string);
  PAufScript = ^TAufScript;
  EAufScriptSyntaxError = class(Exception)
  end;

  TAufScript = class
    protected
      var_stream:TMemoryStream;
      var_occupied:TMemoryStream;//是否内存空间是否被占用，var_stream长度的1/8
      Version:string;

    protected
      procedure SetByte(Index:pRam;byt:byte);
      procedure SetLong(Index:pRam;lng:longint);
      procedure SetDouble(Index:pRam;dbl:double);
      procedure SetStr(Index:pRam;str:string);
      procedure SetSubStr(Index:pRam;str:string);
      function GetByte(Index:pRam):byte;
      function GetLong(Index:pRam):longint;
      function GetDouble(Index:pRam):double;
      function GetStr(Index:pRam):string;
      function GetSubStr(Index:pRam):string;
      function PtrByte(Index:pRam):pbyte;
      function PtrLong(Index:pRam):plongint;
      function PtrDouble(Index:pRam):pdouble;
      function PtrStr(Index:pRam):pstring;
      function PtrSubStr(Index:pRam):pstring;

      procedure SetRamOccupation(head,size:pRam;boo:boolean);
      function GetRamOccupation(head,size:pRam):boolean;
      function FindRamVacant(size:pRam):pRam;

      procedure SetLine(l:dword);
      procedure SetScriptLines(AScript:TStrings);
      procedure SetScriptName(AName:string);
      function GetLine:dword;
      function GetScriptLines:TStrings;
      function GetScriptName:string;
      function GetArgLine:string;

    public
      property currentline:dword read GetLine write SetLine;
      property ScriptLines:TStrings read GetScriptLines write SetScriptLines;
      property ScriptName:string read GetScriptName write SetScriptName;
      property ArgLine:string read GetArgLine;

      property poByte[Index:pRam]:pbyte read PtrByte;
      property poLong[Index:pRam]:plongint read PtrLong;
      property poDouble[Index:pRam]:pdouble read PtrDouble;
      property poStr[Index:pRam]:pstring read PtrStr;
      property poSubStr[Index:pRam]:pstring read PtrSubStr;

      property vByte[Index:pRam]:byte read GetByte write SetByte;
      property vLong[Index:pRam]:longint read GetLong write SetLong;
      property vDouble[Index:pRam]:double read GetDouble write SetDouble;
      property vStr[Index:pRam]:string read GetStr write SetStr;
      property vSubStr[Index:pRam]:string read GetSubStr write SetSubStr;

      property RamOccupation[head,size:pRam]:boolean read GetRamOccupation write SetRamOccupation;

    public
      Owner:TComponent;//用于附着在窗体上，与Auf相同
      {$ifdef MsgTimerMode}
      Control:TAufControl;
      {$else}
      //AufThreadID:TThreadID;
      AufThread:TAufScriptThread;
      {$endif}

      {$ifdef SynEditMode}
      SynAufSyn:TSynAufSyn;
      {$endif}

      Auf:TObject;

    public //关于执行时间的一些定义
      Time:record
        {$ifdef MsgTimerMode}
        Timer:TTimer;
        TimerPause:boolean;
        MultiTaskTimer:TTimer;
        MultiTaskTimerPause:boolean;
        {$endif}
        Synthesis_Mode:(SynMoDelay=0,SynMoTimer=1);
      end;
      {$ifdef MsgTimerMode}
      procedure TimerInitialization(var AControl:TAufControl);
      procedure send(msg:UINT);
      {$endif}

    public
      PSW:record
        stack:array[0..stack_range-1]of record
          line:dword;           //当前行数，在读指令阶段是当前指令，指令结束阶段就是下一个要读的行
          script:TStrings;
          scriptname:string;
        end;
        stack_ptr:byte;         //PSW.stack[stack_ptr].line就是next_line,就是属性中的CurrentLine

        haltoff,pause:boolean;
        inRunNext:boolean;      //仅在SynMoTimer模式下使用，表示是否正在执行RunNext
        run_parameter:record
          current_line_number:word; //当前行号
          next_line_number:word;    //下一行
          prev_line_number:word;    //上一行
          current_strings:TStrings; //当前代码所在TStrings
          ram_zero:pbyte;           //内存零点
          ram_size:pRam;            //内存大小
          error_raise:boolean;      //报错是否直接退出
          time_consuming:array of double;  //记录每一行的累计时间开销
        end;
        calc:record
          YC:boolean;               //位溢出标识
        end;
        extra_variable:record
          timer:longint;            //用于Time模块的settimer和gettimer
        end;
        message:TAufTaskMessageQueue;      //用于跨线程信息处理
        message_stored:record
          uuid:TAufRamVar;
          data:TAufRamVar;
        end;                               //用于task.wait/wmjc的返回值记录
        print_mode:record
          target_file:string;
          is_screen:boolean;
          str_list:TStringList;
          resume_when_run_close:boolean;   //对于AufScptFrame来说为true其余为false
        end;                               //输出方式，默认为屏幕。使用os/of切换，of后可以跟文件名。切换os时保存至文件
      end;
      Func:array[0..func_range-1]of record
        name:ansistring;
        func_ptr:pFuncAuf;
        parameter:string;
        helper:string;
        result_type:TClass;                //在使用"="和"."语法糖时表示需要新建的arv对象类型
      end;
      Expression:record
        Local,Global:TAufExpressionList;
      end;
      IO_fptr:record
        echo:pFuncAufStr;                  //相当于writeln(nil,str:string);
        print:pFuncAufStr;                 //相当于write(nil,str:string);
        error:pFuncAufStr;                 //相当于writeln(nil,str:string);
        pause:pFuncAuf;                    //相当于readln;
        clear:pFuncAuf;                    //清屏
        command_decode:pFuncVarStr;        //在GUI模式中使用utf8编码时需要设置转码函数
      end;
      Func_process:record
        pre,post,mid:pFuncAuf;             //执行单条指令前后的额外过程和中途防假死预留
        beginning,ending:pFuncAuf;         //执行整段代码前后的额外过程
        OnPause,OnResume:pFuncAuf;         //暂停和继续时的额外过程
        OnRaise:pFuncAuf;                  //在error_raise=true时报错退出前执行
        Setting:pFuncAuf;                  //用于set语句的继承，set的定义分别在frame和command中
      end;

      FSVOKernel:TAufKernel;

    private
      procedure BeginOF(filename:string);
      procedure EndOF;

    published
      procedure send_error(str:string);inline;
      procedure write(str:string);inline;
      procedure writeln(str:string);inline;
      procedure readln;inline;
      procedure ClearScreen;

      function Pointer(Iden:string;Index:pRam):Pointer;
      function TmpExpRamVar(arg:Tnargs):TAufRamVar;
      function RamVar(arg:Tnargs):TAufRamVar;//将标准变量形式转化成ARV
      function RamVarToNargs(arv:TAufRamVar;not_offset:boolean=false):Tnargs;
      function RamVarClipToNargs(arv:TAufRamVar;idx,len:pRam;not_offset:boolean=false):Tnargs;

    protected
      //将Tnargs参数转换成需要的格式，不符合要求的情况下raise，使用时需要解决异常。
      function TryToDouble(arg:Tnargs):double;
      function TryToDWord(arg:Tnargs):dword;
      function TryToLong(arg:Tnargs):longint;
      function TryToString(arg:Tnargs):string;

      function SharpToDouble(sharp:Tnargs):double;
      function SharpToDword(sharp:Tnargs):dword;
      function SharpToLong(sharp:Tnargs):longint;
      function SharpToString(sharp:Tnargs):string;

      function TmpexpToDouble(tmpexp:Tnargs):double;deprecated;
      function TmpexpToDword(tmpexp:Tnargs):dword;deprecated;
      function TmpexpToString(tmpexp:Tnargs):string;deprecated;



    published
      procedure add_func(func_name:ansistring;func_ptr:pFuncAuf;func_param,helper:string;arv_type:TClass=nil);
      procedure run_func(func_name:ansistring);
      function have_func(func_name:ansistring):boolean;
      function type_func(func_name:ansistring):TClass;
      procedure HaltOff;
      procedure PSW_reset;
      procedure line_transfer;//将当前行代码转译成标准形式
      procedure next_addr;
      procedure jump_addr(line:dword);//跳转绝对地址
      procedure offs_addr(offs:longint);//跳转偏移地址
      procedure pop_addr;
      procedure push_addr(Ascript:TStrings;Ascriptname:string;line:dword);
      procedure push_addr(line:dword);
      procedure push_addr_inline(Ascript:TStrings;Ascriptname:string;line:dword);
      procedure push_addr_inline(line:dword);

    published
      procedure ram_export(filename:string);//将整个内存区域打印到文件
      procedure occupied_ram_export(filename:string);//将占位判断内存区域打印到文件
      procedure arv_ram_export(arv:TAufRamVar;filename:string);//将arv变量的内存打印到文件
      procedure ram_import(filename:string);//从文件中读取整个内存区域
      procedure arv_ram_import(arv:TAufRamVar;filename:string);//从文件中读取arv变量的内存
      procedure func_helper(func_name:string);
      procedure helper;
      procedure define_helper;

      procedure EnableTaskMessage;
      procedure DisableTaskMessage;
      function SendTaskMessage(SendTo:TAufScript;Data:TAufRamVar;Code:TMsgCode):boolean;
      procedure ReadTaskMessage(var From:TAufScript; var Data:TAufRamVar; var Code:TMsgCode); //没有消息时返回nil
      function CountTaskMessage:integer;

      procedure Pause;//人为暂停
      procedure Resume;//人为继续
      procedure Stop;//人为中止

      procedure RunFirst;//代码执行初始化
      procedure RunNext;//代码执行的循环体
      procedure RunClose;//代码执行中止化

      procedure command(str:TStrings;_error_raise_:boolean=false);overload;
      procedure command(str:string;_error_raise_:boolean=false);overload;

    published
      constructor Create(AOwner:TComponent);
      destructor Destroy; override;
      procedure InternalFuncDefine;//默认函数定义
      procedure AdditionFuncDefine_Task;//多任务协同模块定义
      procedure AdditionFuncDefine_Text;//字串模块函数定义
      procedure AdditionFuncDefine_Time;//时间模块函数定义
      procedure AdditionFuncDefine_File;//文件模块函数定义
      procedure AdditionFuncDefine_Math;//数学模块函数定义
      procedure AdditionFuncDefine_AufBase;//内建类型模块定义
      procedure AdditionFuncDefine_Image;//图像模块函数定义
      procedure AdditionFuncDefine_SVO;//SVO新语法调用模块，暂时的运行方式

  end;


  {Auf  与Auf Script有关的内容}
  TAuf = class
    public
      args:array[0..args_range-1]of string;//ReadArgs的输出结果
      ArgsCount:byte;
      divi,iden,toto:string;
      nargs:array[0..args_range-1]of Tnargs;
      Script:TAufScript;
      constructor Create(AOwner:TComponent=nil);
    public
      Owner:TComponent;//用于附着在窗体上，命令行调用则为nil
    public
      procedure ReadArgs(ps:string);              //将字符串按照隔断符号和变量符号分离出多个参数
      function CheckArgs(MinCount:byte):boolean;  //检验参数数量是否满足最小数量要求，数量包括函数名本身

      //尝试将第ArgNumber个参数转为某个类型，失败则返回false，并send_error
      function TryArgToByte(ArgNumber:byte;out res:byte):boolean;
      function TryArgToDWord(ArgNumber:byte;out res:dword):boolean;
      function TryArgToLong(ArgNumber:byte;out res:longint):boolean;
      function TryArgToString(ArgNumber:byte;out res:string):boolean;
      function TryArgToStrParam(ArgNumber:byte;paramAllowance:array of string;
        CaseSensitivity:boolean;out res:string):boolean;
      function TryArgToDouble(ArgNumber:byte;out res:double):boolean;
      function TryArgToPRam(ArgNumber:byte;out res:pRam):boolean;
      function TryArgToARV(ArgNumber:byte;minsize,maxsize:dword;
        TypeAllowance:TAufRamVarTypeSet;out res:TAufRamVar):boolean;
      function TryArgToDirectData(ArgNumber:byte;DataVarType:TAufRamVarType;out res:TAufRamVar):boolean;
      function TryArgToAddr(ArgNumber:byte;out res:pRam):boolean;
      function TryArgToObject(ArgNumber:byte;ObjectClass:TClass;out obj:TObject):boolean;
      function TryArgToAufArray(ArgNumber:byte;out arr:TAufArray):boolean;

      function TellArgType(ArgNumber:byte):TAufRamVarType;

      function RangeCheck(target,min,max:int64):boolean;inline;
      //min<=target<=max时返回true否则返回false，并send_error

  end;


var

  i:byte;
  Usf:TUsf;

  Auf:TAuf;
  GlobalExpressionList:TAufExpressionList;
  GlobalMultiTaskList:TAufMultiTaskList;
  RegCalc:TRegExpr;

  procedure de_writeln(Sender:Tobject;str:string);
  procedure de_write(Sender:TObject;str:string);
  procedure de_readln(Sender:TObject);
  procedure de_message(Sender:TObject;str:string);
  procedure de_nil(Sender:TObject);
  procedure de_decoder(var str:string);

  function narg(Apre,Aarg,Apost:string):Tnargs;
  procedure compare_jump_mode(var core_mode:string;out is_not,is_call:boolean);

  function isprintable(str:string):boolean;
  function pRamToRawStr(inp:pRam):string;
  function RawStrTopRam(str:string):pRam;
  function HexToPRam(exp:string):pRam;
  function BinaryToPRAM(exp:string):pRam;
  function ExpToPRam(exp:string):pRam;


IMPLEMENTATION
uses auf_type_parser;

procedure de_decoder(var str:string);
begin
  //do nothing
end;

procedure de_write(Sender:TObject;str:string);
var index:integer;
begin
  with (Sender as TAufScript).PSW.print_mode do begin
    if is_screen then
      write(UTF8Toansi(str))
    else begin
      index:=str_list.Count;
      if index>=$fffffff0 then exit;
      str_list[index-1]:=str_list[index-1]+str;
    end;
  end;
end;
procedure de_writeln(Sender:TObject;str:string);
var index:integer;
begin
  with (Sender as TAufScript).PSW.print_mode do begin
    if is_screen then
      writeln(UTF8Toansi(str))
    else begin
      index:=str_list.Count;
      if index>=$fffffff0 then exit;
      str_list.Add(str);
    end;
  end;
end;
procedure de_readln(Sender:TObject);
begin
  readln;
end;
procedure de_clearscreen(Sender:TObject);
begin
  writeln;writeln;writeln;writeln;writeln;writeln;writeln;writeln;writeln;
  writeln;writeln;writeln;writeln;writeln;writeln;writeln;writeln;writeln;
  writeln;writeln;writeln;writeln;writeln;writeln;writeln;writeln;writeln;
end;
procedure de_message(Sender:TObject;str:string);
begin
  {$ifdef WINDOWS}
  MessageBox(0,Pchar(str),'Error',MB_OK);
  {$else}
  raise Exception.Create('非windows平台未实现。');
  {$endif}
end;
procedure de_nil(Sender:TObject);
begin
end;

function BoolToStr(boo:boolean):string;
begin
  if boo then result:='true'
  else result:='false';
end;

function narg(Apre,Aarg,Apost:string):Tnargs;
begin
  result.pre:=Apre;
  result.arg:=Aarg;
  result.post:=Apost;
end;

function isprintable(str:string):boolean;
var ii:word;
begin
  for ii:=1 to length(str) do
    if str[ii] in ['\','/',':','*','?','"','|','<','>'] then begin result:=false;exit end;
  result:=true;
end;

function pRamToRawStr(inp:pRam):string;
var bit:byte;
begin
  result:='';
  for bit:={$ifdef cpu64}15{$else}7{$endif} downto 0 do begin
    result:=result+chr(64+inp shr (bit*4) mod 16);
  end;
end;
function RawStrTopRam(str:string):pRam;
var bit:byte;
    len:integer;
begin
  result:=0;
  len:=length(str);
  for bit:=0 to len-1 do begin
    result:=result shl 4;
    result:=result or ((ord(str[bit+1])-64));
  end;
end;

function HexToPRam(exp:string):pRam;
var str:string;
begin
  result:=0;
  str:=exp;
  while str<>'' do
    begin
      result:=result shl 4;
      case str[1] of
        'a'..'f','A'..'F':
          begin
            result:=result or ((ord(str[1]) or $20) - ord('a') + 10);
          end;
        '0'..'9':
          begin
            result:=result or (ord(str[1]) - ord('0'));
          end;
        else raise Exception.Create('HexToDword失败，发现非法字符。');
      end;
      delete(str,1,1);
    end;
end;
function BinaryToPRam(exp:string):pRam;
var str:string;
begin
  result:=0;
  str:=exp;
  while str<>'' do
    begin
      result:=result shl 1;
      case str[1] of
        '0'..'1':
          begin
            if str[1]='1' then inc(result);
          end;
        else raise Exception.Create('BinaryToDword失败，发现非法字符。');
      end;
      delete(str,1,1);
    end;
end;

function ExpToPRam(exp:string):pRam;
var len:byte;
    str:string;
begin
  if exp='' then begin result:=0;exit end;
  str:=exp;
  len:=length(str);
  if exp[len] in ['h','H'] then
    begin
      try
        delete(str,len,1);
        result:=HexToPRam(str);
      except
        result:=0;
      end;
    end
  else if exp[len] in ['b','B'] then
    begin
      try
        delete(str,len,1);
        result:=BinaryToPRam(str);
      except
        result:=0;
      end;
    end
  else
    begin
      try
        result:=StrToInt(str);
      except
        result:=0;
      end;
    end;
end;

function pos_divi(ps:string):integer;
var tpi:byte;
begin
  for tpi:=1 to length(ps) do
    if ps[tpi] in c_divi then begin result:=tpi;exit end;
  result:=-1;
end;
function pos_iden(ps:string):integer;
var tpi:byte;
begin
  for tpi:=1 to length(ps) do
    if ps[tpi] in c_iden then begin result:=tpi;exit end;
  result:=-1;
end;
function pos_toto(ps:string):integer;
var tpi:byte;
begin
  for tpi:=1 to length(ps) do
    if ps[tpi] in c_toto then begin result:=tpi;exit end;
  result:=-1;
end;

function non_space(ps:string):string;
var tps:string;
    tpi:integer;
begin
  if ps<>'' then tps:=ps[1] else exit;
  if length(ps)>1 then
    for tpi:=2 to length(ps) do
      begin
        if (not(tps[length(tps)]in c_divi))or(ps[tpi]<>tps[length(tps)]) then
          begin
            if (ps[tpi] in c_space)and(tpi<length(ps))then
              begin
                if ps[tpi+1] in c_divi then tps:=tps+ps[tpi+1]
                else tps:=tps+ps[tpi];
              end
            else tps:=tps+ps[tpi];
        end;
      end;
  while (tps<>'') do if tps[1] in c_space then delete(tps,1,1) else break;
  if tps='' then exit;
  while (tps[length(tps)] in c_space) do delete(tps,length(tps),1);
  result:=tps;
end;

function non_space_quote(ps:string):string;//引号内不删除
var tps:string;
    tpi:integer;
    quote:boolean;
begin
  tps:=Trim(ps);
  if length(tps)<=1 then result:=tps else
  begin
    result:=tps[1];
    quote:=tps[1]='"';
    for tpi:=2 to length(tps) do
    begin
      if (result[length(result)] in c_divi) and (tps[tpi] in c_divi) and not quote then
      else result:=result+tps[tpi];
      quote:=quote xor (tps[tpi]='"');
    end;
  end;
end;

function ShowBytes_MultiUnit(byte_count:int64):string;
begin
  if byte_count>$80000000 then begin
    result:=FloatToStrF(byte_count / $40000000,ffFixed,8,3)+' GiB';
  end else if byte_count>$200000 then begin
    result:=FloatToStrF(byte_count / $100000,ffFixed,8,3)+' MiB';
  end else if byte_count>$800 then begin
    result:=FloatToStrF(byte_count / $400,ffFixed,8,3)+' KiB';
  end else begin
    result:=IntToStr(byte_count)+' B';
  end;
end;

//内置流程函数开始
procedure _version(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  AufScpt.writeln('AufScript version:');
  AufScpt.writeln(AufScpt.Version);
  AufScpt.writeln(AufScript_OS+' ('+AufScript_CPU+')');
  AufScpt.writeln('Ram size: '+ShowBytes_MultiUnit(ram_range));
end;
procedure _helper(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if AAuf.ArgsCount=1 then AufScpt.helper
  else AufScpt.func_helper(AAuf.args[1]);
end;
procedure _define_helper(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    tmpUnit:TAufExpressionUnit;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if AAuf.ArgsCount=1 then AufScpt.define_helper
  else begin
    tmpUnit:=AufScpt.Expression.Local.Find(AAuf.args[1]);
    if tmpUnit=nil then tmpUnit:=AufScpt.Expression.Global.Find(AAuf.args[1]);
    if tmpUnit=nil then AufScpt.writeln('找不到'+AAuf.args[1]+'的定义。')
    else AufScpt.writeln(AAuf.args[1]+' = '+tmpUnit.value.pre+tmpUnit.value.arg+tmpUnit.value.post);
  end;
end;
procedure ramex(Sender:TObject);
//ramex | ramex -all [file] | ramex -ocp [file] | ramex arv [file]
var AufScpt:TAufScript;
    AAuf:TAuf;
    mode,filename:string;
    tmp:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if AAuf.ArgsCount=1 then mode:='-all'
  else mode:=AAuf.args[1];
  if AAuf.ArgsCount<3 then filename:=''
  else begin
    try
      filename:=AufScpt.TryToString(AAuf.nargs[2]);
    except
      AufScpt.send_error('警告：第二个参数需要是字符串变量，语句未执行。');exit;
    end;
  end;
  case lowercase(mode) of
    '-all':AufScpt.ram_export(filename);
    '-ocp':AufScpt.occupied_ram_export(filename);
    else
      try
        tmp:=AufScpt.RamVar(AAuf.nargs[1]);
        if tmp.size=0 then raise Exception.Create('');
        AufScpt.arv_ram_export(tmp,filename);
      except
        AufScpt.send_error('警告：第一个参数若不是-all或-ocp，则需要是ARV变量，语句未执行。');exit;
      end;
  end;

end;
procedure ramim(Sender:TObject);
//ramim file | ramim file arv [-f]
var AufScpt:TAufScript;
    AAuf:TAuf;
    filename:string;
    tmp:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  AAuf.CheckArgs(2);
  try
    filename:=AufScpt.TryToString(AAuf.nargs[1]);
  except
    AufScpt.send_error('警告：参数需要是字符串变量，语句未执行。');exit;
  end;
  if AAuf.ArgsCount=2 then AufScpt.ram_import(filename) else
  begin
    try
      tmp:=AufScpt.RamVar(AAuf.nargs[2]);
      if ((AAuf.ArgsCount<4) or (lowercase(AAuf.args[3])<>'-f')) and (tmp.size<>FileSize(filename)) then
        AufScpt.send_error('警告：ARV变量大小与文件大小不同，如需强制导入需要有-f参数，语句未执行。')
      else
        AufScpt.arv_ram_import(tmp,filename);
    except
      AufScpt.send_error('警告：参数需要是ARV变量，语句未执行。');exit;
    end;
  end;
end;
procedure time_consuming_log(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    line_idx:pRam;
    stmp:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  line_idx:=0;
  AufScpt.writeln('Time Consuming By Lines:');
  with AufScpt.PSW.run_parameter do
  for stmp in current_strings do begin
    AufScpt.writeln(FloatToStrF(time_consuming[line_idx]*1e6,ffFixed,9,9)+#9+stmp);
    inc(line_idx);
  end;
end;
procedure _beep(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    freq,dura:dword;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  freq:=600;
  dura:=100;
  if AAuf.ArgsCount>1 then begin
    if not AAuf.TryArgToDWord(1,freq) then exit;
  end;
  if AAuf.ArgsCount>2 then begin
    if not AAuf.TryArgToDWord(2,dura) then exit;
  end;
  {$if defined(WINDOWS)}
  Windows.beep(freq,dura);
  //{$elseif defined(UNIX)}
    //{$if defined(ANDROID)}
    //jForm(AAuf.Owner).Vibrate(dura);
    //{$else}
    //Beep;
    //{$endif}
  {$else}
  AufScpt.send_error('当前系统不支持beep');
  {$endif}
end;
procedure _cmd(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    command:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  AAuf.CheckArgs(2);
  if not AAuf.TryArgToString(1,command) then exit;
  command:=StringReplace(command,'%Q','"',[rfReplaceAll]);
  {$ifdef WINDOWS}
  ShellExecute(0,'open','cmd.exe',pchar('/c '+command),nil,SW_HIDE);
  {$else}
  AufScpt.send_error('非windows平台未实现cmd指令');
  {$endif}
end;
procedure _sleep(Sender:TObject);
var ms:dword;
    AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToDWord(1,ms) then exit;

  if ms=0 then exit;
  IF AufScpt.Time.Synthesis_Mode=SynMoTimer THEN BEGIN
    {$ifdef MsgTimerMode}
    AufScpt.Time.Timer.Interval:=ms;
    AufScpt.Time.Timer.Enabled:=true;
    AufScpt.Time.TimerPause:=true;
    {$else}
    sleep(ms);
    {$endif}
  END ELSE BEGIN
    sleep(ms);
  END;
end;
procedure _pause(Sender:TObject);
begin
  (Sender as TAufScript).writeln('按任意键继续……');
  (Sender as TAufScript).readln;
end;

procedure _clear(Sender:TObject);
var AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AufScpt.ClearScreen;
end;
procedure cwln(Sender:TObject);
begin
  (Sender as TAufScript).writeln('');
end;
procedure echo(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    pi:byte;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  case lowercase(AAuf.args[0]) of
    'echo':for pi:=1 to AAuf.ArgsCount-1 do AufScpt.write('|'+AAuf.args[pi]);
    'echoln':
      begin
        for pi:=1 to AAuf.ArgsCount-1 do AufScpt.write('|'+AAuf.args[pi]);
        AufScpt.writeln('');
      end;
    else AufScpt.send_error('未知函数，需要echo或echoln。');
  end;
end;
procedure print(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    str:string;
    arg_index,arg_count:integer;
    new_lined:boolean;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  case lowercase(AAuf.args[0]) of
    'print':   new_lined:=false;
    'println': new_lined:=true;
    else begin
      AufScpt.send_error('未知函数，需要print或println。');
      exit;
    end;
  end;

  if not AAuf.CheckArgs(2) then exit;
  arg_count:=AAuf.ArgsCount;
  for arg_index:=1 to arg_count-1 do begin
    if not AAuf.TryArgToString(arg_index,str) then exit;
    AufScpt.write(str);
  end;
  if new_lined then AufScpt.writeln('');

end;
procedure hex(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,High(dword),0,[ARV_FixNum,ARV_Char,ARV_Float,ARV_Raw],arv) then exit;
  case lowercase(AAuf.args[0]) of
    'hex':AufScpt.write(arv_to_hex(arv));
    'hexln':AufScpt.writeln(arv_to_hex(arv));
    else AufScpt.send_error('未知函数，需要hex或hexln。');
  end;
end;
procedure binary(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,High(dword),0,[ARV_FixNum,ARV_Char,ARV_Float,ARV_Raw],arv) then exit;
  case lowercase(AAuf.args[0]) of
    'bin':AufScpt.write(arv_to_bin(arv));
    'binln':AufScpt.writeln(arv_to_bin(arv));
    else AufScpt.send_error('未知函数，需要bin或binln。');
  end;
end;
procedure inspect(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    stmp:string;
    qtmp:qword;
    btmp:byte;
    ltmp:longint;
    ftmp:double;
    dtmp:dword;
    atmp:TAufRamVar;
    otmp:TObject;
    tmp_error_pfunc:pFuncAufStr;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  AufScpt.writeln('Inspect "'+AAuf.args[1]+'":');
  tmp_error_pfunc:=AufScpt.IO_fptr.echo;
  AufScpt.IO_fptr.error:=nil;
  if AAuf.TryArgToString(1,stmp) then AufScpt.writeln('  string = '+stmp);
  if AAuf.TryArgToLong(1,ltmp) then AufScpt.writeln('  long = '+IntToStr(ltmp));
  if AAuf.TryArgToByte(1,btmp) then AufScpt.writeln('  byte = '+IntToStr(btmp));
  if AAuf.TryArgToDWord(1,dtmp) then AufScpt.writeln('  dword = '+IntToStr(dtmp));
  if AAuf.TryArgToAddr(1,qtmp) then AufScpt.writeln('  addr = '+IntToStr(qtmp));
  if AAuf.TryArgToPRam(1,qtmp) then AufScpt.writeln('  pram = '+IntToStr(qtmp));
  if AAuf.TryArgToDouble(1,ftmp) then AufScpt.writeln('  double = '+FloatToStr(ftmp));
  if AAuf.TryArgToARV(1,0,High(dword),ARV_AllType,atmp) then begin
    qtmp:=dword(atmp.Head-AufScpt.PSW.run_parameter.ram_zero);
    case atmp.VarType of
      ARV_FixNum:AufScpt.writeln(Format('  arv = {type:fixnum, head:%d, size:%d}',[qtmp,atmp.size]));
      ARV_Float:AufScpt.writeln(Format('  arv = {type:float, head:%d, size:%d}',[qtmp,atmp.size]));
      ARV_Char:AufScpt.writeln(Format('  arv = {type:char, head:%d, size:%d}',[qtmp,atmp.size]));
      else AufScpt.writeln(Format('  arv = {type:unknown, head:%d, size:%d}',[qtmp,atmp.size]));
    end;
  end;
  if AAuf.TryArgToObject(1,TAufBase, otmp) then begin
    if otmp<>nil then AufScpt.writeln('  obj = '+otmp.ClassName)
    else AufScpt.writeln('  obj = nil');
  end;
  AufScpt.IO_fptr.error:=tmp_error_pfunc;

end;
procedure _of(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    str:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToString(1,str) then exit;
  AufScpt.BeginOF(str);
end;

procedure _os(Sender:TObject);
begin
  (Sender as TAufScript).EndOF;
end;
procedure _fillbyte(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    tmp:TAufRamVar;
    pi:pRam;
    target:byte;
    stmp:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,High(dword),0,[ARV_FixNum,ARV_Char,ARV_Float,ARV_Raw],tmp) then exit;
  if not AAuf.TryArgToByte(2,target) then exit;
  //for pi:=0 to tmp.size-1 do (tmp.Head+pi)^:=target;
  fillARV(target,tmp);
end;

procedure _swap(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    tmp:TAufRamVar;
    pi:pRam;
    pa,pb:pbyte;
    btmp:byte;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,High(dword),0,[ARV_FixNum,ARV_Char,ARV_Float,ARV_Raw],tmp) then exit;
  for pi:=0 to (tmp.size div 2) do
    begin
      pa:=tmp.Head+pi;
      pb:=tmp.Head+tmp.size-pi-1;
      btmp:=pa^;
      pa^:=pb^;
      pb^:=btmp;
    end;
end;

procedure _getbytes(Sender:TObject);//getbytes mem,seg,idx
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv1,arv2:TAufRamVar;
    idx,len:pRam;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(4) then exit;
  if not AAuf.TryArgToARV(1,0,High(longint),[ARV_Char,ARV_FixNum],arv1) then exit;
  if not AAuf.TryArgToARV(2,0,High(longint),[ARV_Char,ARV_FixNum],arv2) then exit;
  if not AAuf.TryArgToPRam(3,idx) then exit;
  if idx+arv2.size>arv1.size then begin
    len:=arv1.size-idx;
    FillByte((arv2.Head+len)^,arv2.size-len,0);
  end else begin
    len:=arv2.size;
  end;
  move((arv1.Head+idx)^,arv2.Head^,len);
end;

procedure _setbytes(Sender:TObject);//setbytes mem,seg,idx
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv1,arv2:TAufRamVar;
    idx,len:pRam;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(4) then exit;
  if not AAuf.TryArgToARV(1,0,High(longint),[ARV_Char,ARV_FixNum],arv1) then exit;
  if not AAuf.TryArgToARV(2,0,High(longint),[ARV_Char,ARV_FixNum],arv2) then exit;
  if not AAuf.TryArgToPRam(3,idx) then exit;
  if idx+arv2.size>arv1.size then begin
    len:=arv1.size-idx;
  end else begin
    len:=arv2.size;
  end;
  move(arv2.Head^,(arv1.Head+idx)^,len);
end;

procedure movb(Sender:TObject);deprecated;
var a:byte;
    AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not (AAuf.nargs[1].pre='$') then begin AAuf.Script.send_error('警告：movb的一个参数需要是byte变量，赋值未成功。');exit end;
  case AAuf.nargs[2].pre of
    '$':a:=pByte(AufScpt.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^;
    '@':a:=pLongint(AufScpt.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^;
    '~':a:=round(pDouble(AufScpt.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^);
    '##':a:=round(Usf.to_f(pString(AufScpt.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^));
    '#':a:=round(Usf.to_f(pString(AufScpt.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^));
    '':a:=round(Usf.to_f(AAuf.nargs[2].arg));
    else begin AufScpt.send_error('警告：movb的第二个参数有误，赋值未成功。');exit end;
  end;
  PByte(AufScpt.Pointer(AAuf.nargs[1].pre,Usf.to_i(AAuf.nargs[1].arg)))^:=a;
end;
procedure movl(Sender:TObject);deprecated;
var a:longint;
    AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  //if AAuf.ArgsCount<3 then begin AufScpt.send_error('警告：movl需要两个参数，赋值未成功。');exit end;
  if not (AAuf.nargs[1].pre='@') then begin AufScpt.send_error('警告：movl的一个参数需要是byte变量，赋值未成功。');exit end;
  case AAuf.nargs[2].pre of
    '$':a:=pByte(AufScpt.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^;
    '@':a:=pLongint(AufScpt.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^;
    '~':a:=round(pDouble(AAuf.Script.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^);
    '##':a:=round(Usf.to_f(pString(AAuf.Script.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^));
    '#':a:=round(Usf.to_f(pString(AAuf.Script.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^));
    '':a:=round(Usf.to_f(AAuf.nargs[2].arg));
    else begin AufScpt.send_error('警告：movl的第二个参数有误，赋值未成功。');exit end;
  end;
  PLongint(AufScpt.Pointer(AAuf.nargs[1].pre,Usf.to_i(AAuf.nargs[1].arg)))^:=a;
end;
procedure movd(Sender:TObject);deprecated;
var a:double;
    AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  //if AAuf.ArgsCount<3 then begin AufScpt.send_error('警告：movd需要两个参数，赋值未成功。');exit end;
  if not (AAuf.nargs[1].pre='~') then begin AufScpt.send_error('警告：movd的一个参数需要是byte变量，赋值未成功。');exit end;
  case AAuf.nargs[2].pre of
    '$':a:=pByte(AAuf.Script.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^;
    '@':a:=pLongint(AAuf.Script.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^;
    '~':a:=pDouble(AAuf.Script.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^;
    '##':a:=Usf.to_f(pString(AufScpt.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^);
    '#':a:=Usf.to_f(pString(AufScpt.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^);
    '':a:=Usf.to_f(AAuf.nargs[2].arg);
    else begin AufScpt.send_error('警告：movl的第二个参数有误，赋值未成功。');exit end;
  end;
  PDouble(AufScpt.Pointer(AAuf.nargs[1].pre,Usf.to_i(AAuf.nargs[1].arg)))^:=a;
end;
procedure movs(Sender:TObject);deprecated;
var a:string;
    AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  //if AAuf.ArgsCount<3 then begin AufScpt.send_error('警告：movs需要两个参数，赋值未成功。');exit end;
  if (AAuf.nargs[1].pre<>'#') and (AAuf.nargs[1].pre<>'##') then begin AufScpt.send_error('警告：movs的一个参数需要是str或substr变量，赋值未成功。');exit end;
  case AAuf.nargs[2].pre of
    '##':a:=pString(AufScpt.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^;
    '#':a:=pString(AufScpt.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^;
    '':a:=AAuf.nargs[2].arg;
    else begin AufScpt.send_error('警告：movs的第二个参数有误，赋值未成功。');exit end;
  end;
  if AAuf.nargs[1].pre='#' then delete(a,7,999);
  PString(AufScpt.Pointer(AAuf.nargs[1].pre,Usf.to_i(AAuf.nargs[1].arg)))^:=a;
end;
procedure mov_arv(Sender:TObject);
var a:longint;
    tmp,tmp_src:TAufRamVar;
    AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,1,High(dword),ARV_AllType,tmp) then exit;
  tmp_src:=AufScpt.RamVar(AAuf.nargs[2]);
  if tmp_src.size>0 then begin
    if tmp.VarType = tmp_src.VarType then begin
      copyARV(tmp_src,tmp);
    end else begin
      //arv 类型转换
      AufScpt.send_error('暂不支持不同类型arv之间的直接转换。');
    end;
    exit;
  end;
  case tmp.VarType of
    ARV_Char:
      begin
        initiate_arv_str(AufScpt.TryToString(AAuf.nargs[2]),tmp);
      end;
    ARV_FixNum:
      begin
        try
          initiate_arv(AAuf.nargs[2].arg,tmp);
        except
          AufScpt.send_error('整数解析出错。');
        end;
      end;
    ARV_Float:
      begin
        case tmp.size of
          4:psingle(tmp.Head)^:=AufScpt.TryToDouble(AAuf.nargs[2]);
          8:pdouble(tmp.Head)^:=AufScpt.TryToDouble(AAuf.nargs[2]);
          else AufScpt.send_error('暂不支持4bytes和8bytes以外的浮点数赋值。');
        end;
      end;
  end;
end;
procedure mov(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  case AAuf.nargs[1].pre of
    '$':movb(Sender);
    '@':movl(Sender);
    '~':movd(Sender);
    '##':movs(Sender);
    '#':movs(Sender);
    '$"','~"','$&"','~&"','#"','#&"':mov_arv(AufScpt);
    else begin AufScpt.send_error('警告：mov的第一个参数有误，赋值未成功。');exit end;
  end;
end;
procedure add_arv(Sender:TObject);
var tmp1,tmp2:TAufRamVar;
    AufScpt:TAufScript;
    AAuf:TAuf;
    tmpFloatOperand:double;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  //if AAuf.ArgsCount<3 then begin AufScpt.send_error('警告：arv_add需要两个参数，赋值未成功。');exit end;
  tmp1:=AufScpt.RamVar(AAuf.nargs[1]);
  if tmp1.size=0 then begin
    AufScpt.send_error('警告：add_arv的第1个参数错误，语句未执行。');
    exit;
  end;
  tmp2:=AufScpt.RamVar(AAuf.nargs[2]);
  if tmp2.size=0 then begin
    AufScpt.send_error('警告：add_arv的第2个参数错误，语句未执行。');
    exit;
  end;
  case tmp1.VarType of
    ARV_Float:
      begin
        case tmp2.size of
          4:tmpFloatOperand:=PSingle(tmp2.Head)^;
          8:tmpFloatOperand:=PDouble(tmp2.Head)^;
        end;
        case tmp1.size of
          4:PSingle(tmp1.Head)^:=PSingle(tmp1.Head)^+tmpFloatOperand;
          8:PDouble(tmp1.Head)^:=PDouble(tmp1.Head)^+tmpFloatOperand;
          else AufScpt.send_error('警告：浮点数长度不支持。');
        end;
      end;
    ARV_FixNum:ARV_add(tmp1,tmp2);
    else AufScpt.send_error('警告：add_arv的第1个参数类型不支持加法，代码未执行。');
  end;

end;
procedure add(Sender:TObject);
var a,b:double;
    tmp,arg1,arg2:TAufRamVar;
    AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  //if AAuf.ArgsCount<3 then begin AufScpt.send_error('警告：add需要两个参数，赋值未成功。');exit end;
  {=begin 临时增加}
  arg1:=AufScpt.RamVar(AAuf.nargs[1]);
  arg2:=AufScpt.RamVar(AAuf.nargs[2]);
  if arg1.size * arg2.size <> 0 then
    begin
      add_arv(Sender);
      exit;
    end;
  {=end   临时增加}
  try
    b:=AufScpt.TryToDouble(AAuf.nargs[2]);
  except
    AufScpt.send_error('警告：add的第二个参数不能转换为double类型，语句未执行。');
    exit;
  end;
  try
    a:=AufScpt.TryToDouble(AAuf.nargs[1]);
    tmp:=AufScpt.RamVar(AAuf.nargs[1]);
    case tmp.VarType of
      ARV_Char:;
      ARV_FixNum:dword_to_arv(round(a+b),tmp);
      ARV_Float:double_to_arv(a+b,tmp);
    end;
  except
    AufScpt.send_error('警告：add的第一个参数需要是Float或FixNum变量，语句未执行。');
    exit;
  end;
end;
procedure sub_arv(Sender:TObject);
var tmp1,tmp2:TAufRamVar;
    AufScpt:TAufScript;
    AAuf:TAuf;
    tmpFloatOperand:double;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  //if AAuf.ArgsCount<3 then begin AufScpt.send_error('警告：sub_add需要两个参数，赋值未成功。');exit end;
  tmp1:=AufScpt.RamVar(AAuf.nargs[1]);
  if tmp1.size=0 then begin
    AufScpt.send_error('警告：sub_arv的第1个参数错误，语句未执行。');
    exit;
  end;
  tmp2:=AufScpt.RamVar(AAuf.nargs[2]);
  if tmp2.size=0 then begin
    AufScpt.send_error('警告：sub_arv的第2个参数错误，语句未执行。');
    exit;
  end;
  case tmp1.VarType of
    ARV_Float:
      begin
        case tmp2.size of
          4:tmpFloatOperand:=PSingle(tmp2.Head)^;
          8:tmpFloatOperand:=PDouble(tmp2.Head)^;
        end;
        case tmp1.size of
          4:PSingle(tmp1.Head)^:=PSingle(tmp1.Head)^-tmpFloatOperand;
          8:PDouble(tmp1.Head)^:=PDouble(tmp1.Head)^-tmpFloatOperand;
          else AufScpt.send_error('警告：浮点数长度不支持。');
        end;
      end;
    ARV_FixNum:ARV_sub(tmp1,tmp2);
    else AufScpt.send_error('警告：add_arv的第1个参数类型不支持减法，代码未执行。');
  end;

end;
procedure sub(Sender:TObject);
var a,b:double;
    tmp:TAufRamVar;
    AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  //if AAuf.ArgsCount<3 then begin AufScpt.send_error('警告：sub需要两个参数，赋值未成功。');exit end;
  {=begin 临时增加}
  if AufScpt.RamVar(AAuf.nargs[1]).size * AufScpt.RamVar(AAuf.nargs[2]).size <>0 then
    begin
      sub_arv(Sender);
      exit;
    end;
  {=end   临时增加}
  try
    b:=AufScpt.TryToDouble(AAuf.nargs[2]);
  except
    AufScpt.send_error('警告：sub的第二个参数不能转换为double类型，语句未执行。');
    exit;
  end;
  try
    a:=AufScpt.TryToDouble(AAuf.nargs[1]);
    tmp:=AufScpt.RamVar(AAuf.nargs[1]);
    case tmp.VarType of
      ARV_Char:;
      ARV_FixNum:dword_to_arv(round(a-b),tmp);
      ARV_Float:double_to_arv(a-b,tmp);
    end;
  except
    AufScpt.send_error('警告：sub的第一个参数需要是Float或FixNum变量，语句未执行。');
    exit;
  end;
end;
procedure mul_arv(Sender:TObject);
var tmp1,tmp2:TAufRamVar;
    AufScpt:TAufScript;
    AAuf:TAuf;
    tmpFloatOperand:double;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  //if AAuf.ArgsCount<3 then begin AufScpt.send_error('警告：sub_add需要两个参数，赋值未成功。');exit end;
  tmp1:=AufScpt.RamVar(AAuf.nargs[1]);
  if tmp1.size=0 then begin
    AufScpt.send_error('警告：mul_arv的第1个参数错误，语句未执行。');
    exit;
  end;
  tmp2:=AufScpt.RamVar(AAuf.nargs[2]);
  if tmp2.size=0 then begin
    AufScpt.send_error('警告：mul_arv的第2个参数错误，语句未执行。');
    exit;
  end;
  case tmp1.VarType of
    ARV_Float:
      begin
        case tmp2.size of
          4:tmpFloatOperand:=PSingle(tmp2.Head)^;
          8:tmpFloatOperand:=PDouble(tmp2.Head)^;
        end;
        case tmp1.size of
          4:PSingle(tmp1.Head)^:=PSingle(tmp1.Head)^*tmpFloatOperand;
          8:PDouble(tmp1.Head)^:=PDouble(tmp1.Head)^*tmpFloatOperand;
          else AufScpt.send_error('警告：浮点数长度不支持。');
        end;
      end;
    ARV_FixNum:ARV_mul2(tmp1,tmp2);
    else AufScpt.send_error('警告：add_arv的第1个参数类型不支持乘法，代码未执行。');
  end;
end;

procedure mul(Sender:TObject);
var a,b:double;
    tmp:TAufRamVar;
    AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  //if AAuf.ArgsCount<3 then begin AufScpt.send_error('警告：mul需要两个参数，赋值未成功。');exit end;
  {=begin 临时增加}
  if AufScpt.RamVar(AAuf.nargs[1]).size * AufScpt.RamVar(AAuf.nargs[2]).size <>0 then
    begin
      mul_arv(Sender);
      exit;
    end;
  {=end   临时增加}
  try
    b:=AufScpt.TryToDouble(AAuf.nargs[2]);
  except
    AufScpt.send_error('警告：mul的第二个参数不能转换为double类型，语句未执行。');
    exit;
  end;
  try
    a:=AufScpt.TryToDouble(AAuf.nargs[1]);
    tmp:=AufScpt.RamVar(AAuf.nargs[1]);
    case tmp.VarType of
      ARV_Char:;
      ARV_FixNum:dword_to_arv(round(a*b),tmp);
      ARV_Float:double_to_arv(a*b,tmp);
    end;
  except
    AufScpt.send_error('警告：mul的第一个参数需要是Float或FixNum变量，语句未执行。');
    exit;
  end;
end;
procedure div_arv(Sender:TObject);
var tmp1,tmp2:TAufRamVar;
    AufScpt:TAufScript;
    AAuf:TAuf;
    tmpFloatOperand:double;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,0,High(pRam),ARV_AllType,tmp1) then exit;
  if not AAuf.TryArgToARV(2,0,High(pRam),ARV_AllType,tmp2) then exit;
  if ARV_EqlZero(tmp2) then begin
    AufScpt.send_error('警告：div_arv的第2个参数不能为0，语句未执行。');
    exit;
  end;

  case tmp1.VarType of
    ARV_Float:
      begin
        case tmp2.size of
          4:tmpFloatOperand:=PSingle(tmp2.Head)^;
          8:tmpFloatOperand:=PDouble(tmp2.Head)^;
        end;
        case tmp1.size of
          4:PSingle(tmp1.Head)^:=PSingle(tmp1.Head)^/tmpFloatOperand;
          8:PDouble(tmp1.Head)^:=PDouble(tmp1.Head)^/tmpFloatOperand;
          else AufScpt.send_error('警告：浮点数长度不支持。');
        end;
      end;
    ARV_FixNum:ARV_div(tmp1,tmp2);
    else AufScpt.send_error('警告：add_arv的第1个参数类型不支持除法，代码未执行。');
  end;
end;
procedure div_(Sender:TObject);//这一段写的tm和屎一样。好多了。
var a,b:double;
    l,r:longint;
    tmp:TAufRamVar;
    double_integer,double_number:boolean;
    AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  //if AAuf.ArgsCount<3 then begin AufScpt.send_error('警告：div需要两个参数，赋值未成功。');exit end;
  {=begin 临时增加}
  if AufScpt.RamVar(AAuf.nargs[1]).size * AufScpt.RamVar(AAuf.nargs[2]).size <>0 then
    begin
      div_arv(Sender);
      exit;
    end;
  {=end   临时增加}
  try
    b:=AufScpt.TryToDouble(AAuf.nargs[2]);
  except
    AufScpt.send_error('警告：div的第二个参数不能转换为double类型，语句未执行。');
    exit;
  end;
  if b=0 then begin AufScpt.send_error('警告：div的第二个参数不能为0，语句未执行。');exit end;
  try
    a:=AufScpt.TryToDouble(AAuf.nargs[1]);
    tmp:=AufScpt.RamVar(AAuf.nargs[1]);
    case tmp.VarType of
      ARV_Char:;
      ARV_FixNum:dword_to_arv(round(a) div round(b),tmp);
      ARV_Float:double_to_arv(a / b,tmp);
    end;
  except
    AufScpt.send_error('警告：div的第一个参数需要是Float或FixNum变量，语句未执行。');
    exit;
  end;
end;
procedure mod_arv(Sender:TObject);
var tmp1,tmp2:TAufRamVar;
    AufScpt:TAufScript;
    AAuf:TAuf;
    tmpFloatOperand:double;
    function float_mod(a,b:double):double;
    var quotient:double;
    begin
        quotient:=trunc(a/b);
        result:=a-quotient*b
    end;

begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  //if AAuf.ArgsCount<3 then begin AufScpt.send_error('警告：sub_add需要两个参数，赋值未成功。');exit end;
  tmp1:=AufScpt.RamVar(AAuf.nargs[1]);
  if tmp1.size=0 then begin
    AufScpt.send_error('警告：mod_arv的第1个参数错误，语句未执行。');
    exit;
  end;
  tmp2:=AufScpt.RamVar(AAuf.nargs[2]);
  if tmp2.size=0 then begin
    AufScpt.send_error('警告：mod_arv的第2个参数错误，语句未执行。');
    exit;
  end;
  if ARV_EqlZero(tmp2) then begin
    AufScpt.send_error('警告：mod_arv的第2个参数不能为0，语句未执行。');
    exit;
  end;

  case tmp1.VarType of
    ARV_Float:
      begin
        case tmp2.size of
          4:tmpFloatOperand:=PSingle(tmp2.Head)^;
          8:tmpFloatOperand:=PDouble(tmp2.Head)^;
        end;
        case tmp1.size of
          4:PSingle(tmp1.Head)^:=float_mod(PSingle(tmp1.Head)^,tmpFloatOperand);
          8:PDouble(tmp1.Head)^:=float_mod(PDouble(tmp1.Head)^,tmpFloatOperand);
          else AufScpt.send_error('警告：浮点数长度不支持。');
        end;
      end;
    ARV_FixNum:ARV_mod(tmp1,tmp2);
    else AufScpt.send_error('警告：add_arv的第1个参数类型不支持除法，代码未执行。');
  end;

end;
procedure mod_(Sender:TObject);
var l,r:longint;
    tmp:TAufRamVar;
    double_integer:boolean;
    AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  //if AAuf.ArgsCount<3 then begin AufScpt.send_error('警告：mod需要两个参数，赋值未成功。');exit end;
  {=begin 临时增加}
  if AufScpt.RamVar(AAuf.nargs[1]).size * AufScpt.RamVar(AAuf.nargs[2]).size <>0 then
    begin
      mod_arv(Sender);
      exit;
    end;
  {=end   临时增加}
  try
    r:=AufScpt.TryToDWord(AAuf.nargs[2]);
  except
    AufScpt.send_error('警告：mod的第二个参数不能转换为double类型，语句未执行。');
    exit;
  end;
  if r=0 then begin AufScpt.send_error('警告：mod的第二个参数不能为0，语句未执行。');exit end;
  try
    l:=AufScpt.TryToDWord(AAuf.nargs[1]);
    tmp:=AufScpt.RamVar(AAuf.nargs[1]);
    case tmp.VarType of
      ARV_Char:;
      ARV_FixNum:dword_to_arv(l mod r,tmp);
      ARV_Float:double_to_arv(l mod r,tmp);
    end;
  except
    AufScpt.send_error('警告：mod的第一个参数需要是Float或FixNum变量，语句未执行。');
    exit;
  end;
end;
procedure rand(Sender:TObject);
var rand_max:dword;
    pos:pbyte;
    tmp:TAufRamVar;
    AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,1,High(pRam),[ARV_FixNum,ARV_Float],tmp) then exit;
  if AAuf.ArgsCount>2 then begin
    if not AAuf.TryArgToDWord(2,rand_max) then exit;
    if rand_max=0 then begin AufScpt.send_error('警告：第二个参数不能为0，语句未执行。');exit end;
    case tmp.VarType of
      ARV_FixNum:dword_to_arv(random(rand_max),tmp);
      ARV_Float:double_to_arv(random*rand_max,tmp);
    end;
  end else begin
    pos:=tmp.Head;
    while pos<tmp.Head+tmp.size do begin
      pos^:=random(255);
      inc(pos);
    end;
  end;
end;

procedure compare_jump_mode(var core_mode:string;out is_not,is_call:boolean);
var poss:integer;
begin
  core_mode:=lowercase(core_mode);
  poss:=pos('.',core_mode);
  while poss>0 do begin
    delete(core_mode,1,poss);
    poss:=pos('.',core_mode);
  end;
  if core_mode[1]='n' then
    begin
      is_not:=true;
      delete(core_mode,1,1);
    end
  else is_not:=false;
  if core_mode[length(core_mode)]='c' then
    begin
      is_call:=true;
      delete(core_mode,length(core_mode),1);
    end
  else is_call:=false;
end;

procedure cj_mode(mode:string;Sender:TObject);//比较两个变量，满足条件则跳转至ofs  cj var1,var2,ofs
var a,b:double;
    sa,sb:string;
    //ofs:smallint;
    addr:pRam;
    is_not,is_call,tmp_bool_reg:boolean;//是否有N前缀或C后缀
    core_mode:string;//去除前后缀的mode
    AufScpt:TAufScript;
    AAuf:TAuf;

  procedure switch_addr(addr:dword;iscall:boolean);
  begin
    if iscall then AAuf.Script.push_addr(AufScpt.ScriptLines,AufScpt.ScriptName,addr)
    else AufScpt.jump_addr(addr);
  end;

begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  core_mode:=mode;
  compare_jump_mode(core_mode,is_not,is_call);

  if not AAuf.CheckArgs(4) then exit;
  if not AAuf.TryArgToAddr(3,addr) then exit;

  if core_mode[3]<>'s' then begin
    if not AAuf.TryArgToDouble(2,b) then exit;
    if not AAuf.TryArgToDouble(1,a) then exit;
  end else begin
    if not AAuf.TryArgToString(2,sb) then exit;
    if not AAuf.TryArgToString(1,sa) then exit;
  end;
  case core_mode of
    'cje':if (a=b) xor is_not then switch_addr(addr,is_call);
    'cjl':if (a<b) xor is_not then switch_addr(addr,is_call);
    'cjm':if (a>b) xor is_not then switch_addr(addr,is_call);

    'cjs':if (sa=sb) xor is_not then switch_addr(addr,is_call);
    'cjsub':if (pos(sa,sb)>0) xor is_not then switch_addr(addr,is_call);
    'cjsreg':
      begin
        RegCalc.Expression:=sa;
        try
          tmp_bool_reg:=RegCalc.Exec(sb);
        except
          tmp_bool_reg:=false;
        end;
        if tmp_bool_reg xor is_not then switch_addr(addr,is_call);
      end;

  end;

end;

procedure cj(Sender:TObject);
var AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  cj_mode((AufScpt.Auf as TAuf).nargs[0].arg,AufScpt);
end;

procedure nop(Sender:TObject); //用于else等无实际含义的函数/关键字跳转
begin
end;

procedure _if(Sender:TObject); //if a = b jmp/call :label
var AufScpt:TAufScript;
    AAuf:TAuf;
    sign, arg_0:string;
    condition_result, is_error:boolean;
    pidx, plen, pofs:integer;
    if_level:integer;

    function compare_in:boolean;
    var s1,s2:string;
    begin
      result:=false;
      if not AAuf.TryArgToString(1,s1) then exit;
      if not AAuf.TryArgToString(3,s2) then exit;
      result:=pos(s1,s2)>0;
    end;
    function compare_reg:boolean;
    var s1,s2:string;
    begin
      result:=false;
      if not AAuf.TryArgToString(1,s1) then exit;
      if not AAuf.TryArgToString(3,s2) then exit;
      RegCalc.Expression:=s1;
      try
        result:=RegCalc.Exec(s2);
      except
        result:=false;
      end;
    end;
    function compare_numeric:smallint;
    var t1,t2,tc:TAufRamVarType;
        a1,a2:TAufRamVar;
        diff:double;
    begin
      t1:=AAuf.TellArgType(1);
      t2:=AAuf.TellArgType(3);
      if t1=t2 then begin
        if t1<>ARV_Raw then begin
          tc:=t1;
          is_error:=is_error or not AAuf.TryArgToARV(1,1,High(dword),[tc],a1);
          is_error:=is_error or not AAuf.TryArgToARV(3,1,High(dword),[tc],a2);
        end else begin
          is_error:=true;
          AufScpt.send_error('不支持两个立即数比较大小。');
          exit;
        end;
      end else begin
        if t1=ARV_Raw then begin
          tc:=t2;
          newARV(a1,8);
          is_error:=is_error or not AAuf.TryArgToDirectData(1, tc, a1);
          is_error:=is_error or not AAuf.TryArgToARV(3,1,High(dword),[tc],a2);
        end else if t2=ARV_Raw then begin
          tc:=t1;
          newARV(a2,8);
          is_error:=is_error or not AAuf.TryArgToARV(1,1,High(dword),[tc],a1);
          is_error:=is_error or not AAuf.TryArgToDirectData(3, tc, a2);
        end else begin
          is_error:=true;
          AufScpt.send_error('类型不同无法比较。');
        end;
      end;
      result:=0;

      if is_error then exit;
      case tc of
        ARV_FixNum:begin
          result:=fixnum_comp(a1,a2);
        end;
        ARV_Float: begin
          //result:=ARV_floating_comp(a1,a2);
          diff:=arv_to_double(a1)-arv_to_double(a2);
          if diff=0 then result:=0 else if diff>0 then result:=1 else result:=-1;
        end;
        ARV_Char:  begin
          result:=ARV_string_comp(a1,a2);
        end;
      end;
      if t1<>tc then freeARV(a1);
      if t2<>tc then freeARV(a2);

    end;

begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(6) then exit;
  if not AAuf.TryArgToStrParam(2, ['==','eq','eql','<>','!=','≠','ne','neq','>','gt','<','lt','>=','≥','ge','<=','≤','le','in','~=','reg'], false, sign) then exit;
  is_error:=false;
  case sign of
    '==','eq','eql':          condition_result:=compare_numeric()=0;
    '<>','!=','≠','ne','neq': condition_result:=compare_numeric()<>0;
    '>','gt':                 condition_result:=compare_numeric()>0;
    '<','lt':                 condition_result:=compare_numeric()<0;
    '>=','≥','ge':            condition_result:=compare_numeric()>=0;
    '<=','≤','le':            condition_result:=compare_numeric()<=0;
    'in':                     condition_result:=compare_in();
    '~=','reg':               condition_result:=compare_reg();
    else assert(false,'不应该出现这个分支');
  end;
  if is_error then exit;

  if condition_result then begin
    //判断结果为真，直接将参数前移，直到遇到与if不成对的else
    plen:=AAuf.ArgsCount;
    if_level:=0;
    pidx:=0;
    pofs:=4;
    while pidx<plen-pofs do begin
      case lowercase(AAuf.args[pidx+pofs]) of
        'if':   inc(if_level);
        'else': begin
          dec(if_level);
          if if_level<0 then break;
        end;
      end;
      AAuf.nargs[pidx]:=AAuf.nargs[pidx+pofs];
      AAuf.args[pidx]:=AAuf.args[pidx+pofs];
      inc(pidx);
    end;
    AAuf.ArgsCount:=pidx;
    if AAuf.ArgsCount>0 then AufScpt.run_func(AAuf.args[0]);
  end else begin
    //判断结果为假，直接将与if不成对的else之后的参数前移，无参数则不run_func
    plen:=AAuf.ArgsCount;
    if_level:=1;
    pidx:=0;
    pofs:=4;
    while pidx<plen-pofs do begin
      arg_0:=lowercase(AAuf.args[pidx+pofs]);
      case arg_0 of
        'if':   inc(if_level);
        'else': dec(if_level);
      end;
      if (if_level>0) or (if_level=0) and (arg_0='else') then begin
        inc(pofs);
        continue;
      end;
      AAuf.nargs[pidx]:=AAuf.nargs[pidx+pofs];
      AAuf.args[pidx]:=AAuf.args[pidx+pofs];
      inc(pidx);
    end;
    AAuf.ArgsCount:=pidx;
    if AAuf.ArgsCount>0 then AufScpt.run_func(AAuf.args[0]);
  end;
end;

procedure jmp(Sender:TObject);//满足条件执行下一句，不满足条件跳过下一句  jmp ofs|:label
var ofs:pRam;
    AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  ofs:=0;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToAddr(1,ofs) then exit;
  if ofs=AufScpt.currentLine then begin AufScpt.send_error('警告：jmp需要非零的地址偏移量，该语句未执行。');exit end;
  AufScpt.jump_addr(ofs);
end;

procedure call(Sender:TObject);//满足条件执行下一句，使用ret返回至该位置的下一行，不满足条件跳过下一句  call ofs|:label
var ofs:pRam;
    AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  ofs:=0;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToAddr(1,ofs) then exit;
  if ofs=AufScpt.currentLine then begin AufScpt.send_error('警告：call需要非零的地址偏移量，该语句未执行。');exit end;
  AufScpt.push_addr(ofs);
end;

procedure taichi_call(Sender:TObject);//根据给定的整型数判断每一位的正负性，组合结果后压栈跳转至不同的行  taichi value chaos_width chaos_addr [addrs, ...]
//由于参数数量（16）的限制，最多判断三个字节，由于判断的整型数不定长，使用Small Endian。
//字节的正负性判断结果与chaos_width有关x^2 * y^2 * z^2 < chaos_width^-2
//chaos_width表示正值与负值之间混沌部分的宽度的倒数，值域为 [2, +Inf)
//这个跳转可以用于九色判断：taichi @color 16, :grey :black :blue :green :cyan :red :violet :yellow :white
var AufScpt:TAufScript;
    AAuf:TAuf;
    value:TAufRamVar;
    chaos_width,bytenum,idx,res:integer;
    list_ofs:array[0..8] of pRam;
    factors:array[0..2] of double;
    xyz_sqr, width_reverse:double;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  for idx:=0 to 8 do list_ofs[idx]:=0;
  if not AAuf.CheckArgs(4) then exit;//至少要有四个参数：指令名、测试值、混沌区宽度、混沌区跳转地址
  if not AAuf.TryArgToARV(1,1,High(pRam),[ARV_FixNum],value) then exit;
  if not AAuf.TryArgToLong(2,chaos_width) then exit;
  for idx:=AAuf.ArgsCount-1 downto 3 do begin
    if not AAuf.TryArgToAddr(idx,list_ofs[idx-3]) then exit;
  end;
  width_reverse:=1.0/chaos_width/chaos_width;
  xyz_sqr:=1.0;
  bytenum:=value.size;
  if bytenum>3 then bytenum:=3;
  for idx:=0 to bytenum-1 do begin
    factors[idx]:=(2.0*pbyte(value.Head+idx)^/255)-1.0;
    xyz_sqr:=xyz_sqr*sqr(factors[idx]);
  end;
  if xyz_sqr<width_reverse then begin
    res:=-1;
  end else begin
    res:=0;
    for idx:=0 to bytenum-1 do begin
      res:=res shl 1;
      if factors[idx]>0 then res:=res or $1;
    end;
  end;
  inc(res);
  if list_ofs[res]=0 then exit;
  AufScpt.push_addr(list_ofs[res]);
end;

procedure _loop(Sender:TObject);
//简易循环模式，只接受常数  loop :label times [now]
//向上loop是循环n+1次
//向下loop是n次截取一次
var AufScpt:TAufScript;
    AAuf:TAuf;
    ofs:pRam;
    times,now:dword;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  ofs:=0;
  if not AAuf.CheckArgs(3) then exit;
  case AAuf.nargs[1].pre of
    '&"':ofs:=RawStrToPRam(AAuf.nargs[1].arg) - AufScpt.PSW.run_parameter.current_line_number;
    else
      if not AAuf.TryArgToPRam(1,ofs) then begin
        AufScpt.send_error('警告：地址偏移量解析错误，该语句未执行。');
        exit;
      end;
  end;
  if ofs=0 then begin AufScpt.send_error('警告：loop需要非零的地址偏移量，该语句未执行。');exit end;
  try
    times:=AufScpt.TryToDWord(AAuf.nargs[2]);
    if times=0 then raise Exception.Create('');
  except
    AufScpt.send_error('警告：loop的循环次数需要是正整数，该语句未执行。');exit
  end;
  if AAuf.ArgsCount=3 then
    begin
      AAuf.args[3]:={DwordToRawStr}IntToStr(times-1);
      AufScpt.jump_addr(AufScpt.currentLine+ofs);
    end
  else
    begin
      now:={RawStrToDword}StrToInt(AAuf.args[3]);
      if now=0 then
        begin
          AufScpt.ScriptLines[AufScpt.PSW.run_parameter.current_line_number]:=AAuf.args[0]+' '+AAuf.args[1]+','+AAuf.args[2];
          exit
        end
      else
        begin
          AAuf.args[3]:={DwordToRawStr}IntToStr(now-1);
          AufScpt.jump_addr(AufScpt.currentLine+ofs);
        end;
    end;
  AufScpt.ScriptLines[AufScpt.PSW.run_parameter.current_line_number]:=AAuf.args[0]+' '+AAuf.args[1]+','+AAuf.args[2]+','+AAuf.args[3];

end;

procedure _load(Sender:TObject);//打开文件 load "filename"
var AufScpt:TAufScript;
    tmp:TStrings;
    AAuf:TAuf;
    addr:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToString(1,addr) then exit;
  tmp:=TStringList.Create;
  try
    if pos(':',addr)<=0 then addr:=ExtractFilePath(AufScpt.PSW.stack[AufScpt.PSW.stack_ptr].scriptname)+addr;
    tmp.LoadFromFile(addr);
    tmp.Add('fend');//不判断了，保底最后都跳出来
  except
    AufScpt.send_error('警告：文件"'+addr+'"打开失败，该语句未执行。');
    exit;
  end;
  AufScpt.push_addr(tmp,AAuf.nargs[1].arg,-1);
end;

procedure _fend(Sender:TObject);//退出文件，end语句或者无文末结束后栈未清空也会运行这个
var AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  if AufScpt.PSW.stack_ptr=0 then
    begin AufScpt.send_error('警告：当前stack_ptr不能pop_addr，该语句未执行。');exit end;
  if AufScpt.PSW.stack[AufScpt.PSW.stack_ptr].script = AufScpt.PSW.stack[AufScpt.PSW.stack_ptr-1].script then
    begin AufScpt.send_error('警告：存在未ret的call语句，该语句未执行。');exit end;
  AufScpt.ScriptLines.Free;
  AufScpt.pop_addr;
end;

procedure _ret(Sender:TObject);//返回至最近使用call的下一行，不满足条件跳过下一句  call ofs|:label
var AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AufScpt.pop_addr;
end;

procedure _end(Sender:TObject);//结束
var AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  if (AufScpt.PSW.stack_ptr<>0) then
    begin
      if AufScpt.PSW.stack[AufScpt.PSW.stack_ptr-1].scriptname <> '' then
        begin
          _fend(Sender);exit
        end
      else
        begin
          _ret(Sender);exit
        end;
    end;

  AufScpt.PSW.haltoff:=true;
end;

procedure _halt(Sender:TObject);//结束
var AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AufScpt.PSW.haltoff:=true;
end;

procedure _define(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    global:boolean;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  global:=false;
  if AAuf.ArgsCount>=4 then
    begin
      if lowercase(AAuf.args[3])='-global' then global:=true;
    end;
  case AAuf.nargs[1].arg[1] of
    'a'..'z','A'..'Z','_':;
    else begin AufScpt.send_error('警告：第一个参数的第一个字符需要是字母或下划线，该语句未执行。');exit end;
  end;
  try
    if global then AufScpt.Expression.Global.TryAddExp(AAuf.nargs[1].arg,AAuf.nargs[2])
    else AufScpt.Expression.Local.TryAddExp(AAuf.nargs[1].arg,AAuf.nargs[2]);
  except
    AufScpt.send_error('警告：define参数有误，未正确执行')
  end;
end;
procedure _rendef(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    global:boolean;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  global:=false;
  if AAuf.ArgsCount>=4 then
    begin
      if lowercase(AAuf.args[3])='-global' then global:=true;
    end;
  case AAuf.nargs[1].arg[1] of
    'a'..'z','A'..'Z','_':;
    else begin AufScpt.send_error('警告：第一个参数的第一个字符需要是字母或下划线，该语句未执行。');exit end;
  end;
  case AAuf.nargs[2].arg[1] of
    'a'..'z','A'..'Z','_':;
    else begin AufScpt.send_error('警告：第二个参数的第一个字符需要是字母或下划线，该语句未执行。');exit end;
  end;
  try
    if global then AufScpt.Expression.Global.TryRenameExp(AAuf.nargs[1].arg,AAuf.nargs[2].arg)
    else AufScpt.Expression.Local.TryRenameExp(AAuf.nargs[1].arg,AAuf.nargs[2].arg);
  except
    AufScpt.send_error('警告：rendef参数有误，未正确执行')
  end;
end;
procedure _deldef(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    global:boolean;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  global:=false;
  if AAuf.ArgsCount>=3 then
    begin
      if lowercase(AAuf.args[2])='-global' then global:=true;
    end;
  case AAuf.nargs[1].arg[1] of
    'a'..'z','A'..'Z','_':;
    else begin AufScpt.send_error('警告：参数的第一个字符需要是字母或下划线，该语句未执行。');exit end;
  end;
  try
    if global then AufScpt.Expression.Global.TryDeleteExp(AAuf.nargs[1].arg)
    else AufScpt.Expression.Local.TryDeleteExp(AAuf.nargs[1].arg);
  except
    AufScpt.send_error('警告：表达式不存在或者为只读状态，未成功删除。')
  end;
end;
procedure _ifdef(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    addr:pRam;
    global:boolean;
    tmpExprList:TAufExpressionList;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  global:=false;
  if AAuf.ArgsCount>=4 then
    begin
      if lowercase(AAuf.args[3])='-global' then global:=true;
    end;
  case AAuf.nargs[1].arg[1] of
    'a'..'z','A'..'Z','_':;
    else begin AufScpt.send_error('警告：参数的第一个字符需要是字母或下划线，该语句未执行。');exit end;
  end;
  if not AAuf.TryArgToAddr(2,addr) then exit;
  if global then tmpExprList:=AufScpt.Expression.Global
  else tmpExprList:=AufScpt.Expression.Local;
  if tmpExprList.Find(AAuf.nargs[1].arg)<>nil then
    begin
      AufScpt.jump_addr(addr);
    end
  else if tmpExprList.Find(AAuf.nargs[1].arg)<>nil then
    begin
      AufScpt.jump_addr(addr);
    end
  else
    begin
      //
    end;
end;
procedure _ifndef(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    addr:pRam;
    global:boolean;
    tmpExprList:TAufExpressionList;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  global:=false;
  if AAuf.ArgsCount>=4 then
    begin
      if lowercase(AAuf.args[3])='-global' then global:=true;
    end;
  case AAuf.nargs[1].arg[1] of
    'a'..'z','A'..'Z','_':;
    else begin AufScpt.send_error('警告：参数的第一个字符需要是字母或下划线，该语句未执行。');exit end;
  end;
  if not AAuf.TryArgToAddr(2,addr) then exit;
  if global then tmpExprList:=AufScpt.Expression.Global
  else tmpExprList:=AufScpt.Expression.Local;
  if tmpExprList.Find(AAuf.nargs[1].arg)<>nil then
    begin
      //
    end
  else if tmpExprList.Find(AAuf.nargs[1].arg)<>nil then
    begin
      //
    end
  else
    begin
      AufScpt.jump_addr(addr);
    end;
end;



procedure _var(Sender:TObject);//var type name size
var AufScpt:TAufScript;
    AAuf:TAuf;
    size,head:pRam;
    exp:Tnargs;
    exp_type,var_name:string;
    arv:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToStrParam(1,['fixnum','int','char','string','float','real','object'],false,exp_type) then exit;
  case lowercase(exp_type) of
    'fixnum','int' :exp.pre:='$"';
    'char','string':exp.pre:='#"';
    'float','real' :exp.pre:='~"';
    'object'       :exp.pre:='$"';
    else exp.pre:='$"';
  end;
  if not AAuf.TryArgToString(2,var_name) then exit;
  case var_name[1] of 'a'..'z','A'..'Z','_':;
    else begin AufScpt.send_error('警告：第二个参数作为变量名需要以字母或下划线开头，该语句未执行。');exit end;
  end;
  if AufScpt.Expression.Local.Find(var_name)<>nil then
    begin
      AufScpt.send_error('警告：变量已存在，该语句未执行。');
      exit
    end;
  if AAuf.ArgsCount>3 then begin
    if not AAuf.TryArgToPRam(3,size) then exit;
  end else size:=8;
  head:=AufScpt.FindRamVacant(size);
  exp.arg:=pRamToRawStr(head)+'|'+pRamToRawStr(size);
  exp.post:='"';
  try
    AufScpt.Expression.Local.TryAddExp(AAuf.nargs[2].arg,exp);
  except
    AufScpt.send_error('警告：var参数有误，未正确执行')
  end;
  AufScpt.RamOccupation[head,size]:=true;

  //创建变量后默认初始化为0
  arv.size:=size;
  arv.Head:=pbyte(head+AufScpt.PSW.run_parameter.ram_zero);
  arv.Is_Temporary:=false;
  case exp.pre of
    '$"':arv.VarType:=ARV_FixNum;
    '~"':arv.VarType:=ARV_Float;
    '@"':arv.VarType:=ARV_Char;
    else arv.VarType:=ARV_Raw;
  end;
  fillARV(0,arv);
end;
procedure _unvar(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    tmp:TAufExpressionUnit;
    var_name:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToString(1,var_name) then exit;
  case var_name[1] of 'a'..'z','A'..'Z','_':;
    else begin AufScpt.send_error('警告：参数的第一个字符需要是字母或下划线，该语句未执行。');exit end;
  end;
  tmp:=AufScpt.Expression.Local.Find(var_name);
  if tmp=nil then begin
    AufScpt.send_error('警告：找不到'+AAuf.nargs[1].arg+'的定义，该语句未执行。');
    exit;
  end;
  arv:=AufScpt.RamVar(tmp.value);
  if arv.size=0 then begin
    AufScpt.send_error('警告：'+AAuf.nargs[1].arg+'不是ARV变量，该语句未执行。');
    exit
  end;
  try
    AufScpt.Expression.Local.Remove(tmp);
  except
    AufScpt.send_error('警告：unvar参数有误，未正确执行')
  end;
  AufScpt.RamOccupation[arv.head-AufScpt.var_stream.Memory,arv.size]:=false;
end;

procedure math_pow(Sender:TObject);
var AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
end;
procedure math_sqrt(Sender:TObject);
var AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
end;
procedure math_ln(Sender:TObject);
var AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
end;
procedure math_exp(Sender:TObject);
var AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
end;


procedure math_logic_cmp(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    tmp1,tmp2,tmp3:TAufRamVar;
    res:smallint;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,High(dword),0,[ARV_Raw,ARV_FixNum,ARV_Float,ARV_Char],tmp1) then exit;
  if not AAuf.TryArgToARV(2,High(dword),0,[ARV_Raw,ARV_FixNum,ARV_Float,ARV_Char],tmp2) then exit;

  res:=ARV_comp(tmp1,tmp2);
  if AAuf.ArgsCount>3 then begin
    if not AAuf.TryArgToARV(3,High(dword),0,[ARV_Raw,ARV_FixNum,ARV_Float,ARV_Char],tmp3) then exit;
    dword_to_arv(res,tmp3);
  end else AufScpt.writeln('对比结果：'+IntToStr(res));
end;
procedure math_logic_offset_count(Sender:TObject);//ofs @v1,@v2,threshold,@out
var AufScpt:TAufScript;
    AAuf:TAuf;
    tmp1,tmp2,tmp3:TAufRamVar;
    threshold:byte;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(5) then exit;
  if not AAuf.TryArgToARV(1,High(dword),0,[ARV_Raw,ARV_FixNum,ARV_Float,ARV_Char],tmp1) then exit;
  if not AAuf.TryArgToARV(2,High(dword),0,[ARV_Raw,ARV_FixNum,ARV_Float,ARV_Char],tmp2) then exit;
  if not AAuf.TryArgToByte(3,threshold) then exit;
  if not AAuf.TryArgToARV(4,4,High(dword),[ARV_FixNum],tmp3) then exit;
  dword_to_arv(ARV_offset_count(tmp1,tmp2,threshold),tmp3);
end;
procedure math_logic_shl(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    tmp:TAufRamVar;
    bit:dword;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,High(dword),0,[ARV_Raw,ARV_FixNum,ARV_Float,ARV_Char],tmp) then exit;
  if not AAuf.TryArgToDWord(2,bit) then exit;
  ARV_shl(tmp,bit);
end;
procedure math_logic_shr(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    tmp:TAufRamVar;
    bit:dword;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  tmp:=AufScpt.RamVar(AAuf.nargs[1]);
  if not AAuf.TryArgToARV(1,High(dword),0,[ARV_Raw,ARV_FixNum,ARV_Float,ARV_Char],tmp) then exit;
  if not AAuf.TryArgToDWord(2,bit) then exit;
  ARV_shr(tmp,bit);
end;
procedure math_logic_not(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    tmp:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,High(dword),0,[ARV_Raw,ARV_FixNum,ARV_Float,ARV_Char],tmp) then exit;
  ARV_not(tmp);
end;
procedure math_logic_and(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    tmp1,tmp2:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,High(dword),0,[ARV_Raw,ARV_FixNum,ARV_Float,ARV_Char],tmp1) then exit;
  if not AAuf.TryArgToARV(2,High(dword),0,[ARV_Raw,ARV_FixNum,ARV_Float,ARV_Char],tmp2) then exit;
  ARV_and(tmp1,tmp2);
end;
procedure math_logic_or(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    tmp1,tmp2:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,High(dword),0,[ARV_Raw,ARV_FixNum,ARV_Float,ARV_Char],tmp1) then exit;
  if not AAuf.TryArgToARV(2,High(dword),0,[ARV_Raw,ARV_FixNum,ARV_Float,ARV_Char],tmp2) then exit;
  ARV_or(tmp1,tmp2);
end;
procedure math_logic_xor(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    tmp1,tmp2:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,High(dword),0,[ARV_Raw,ARV_FixNum,ARV_Float,ARV_Char],tmp1) then exit;
  if not AAuf.TryArgToARV(2,High(dword),0,[ARV_Raw,ARV_FixNum,ARV_Float,ARV_Char],tmp2) then exit;
  ARV_xor(tmp1,tmp2);
end;



procedure math_h_arithmetic(Sender:TObject);//这是一个性能不太好的权宜算法
//label exitt,resultt;
var AufScpt:TAufScript;
    AAuf:TAuf;
    a,b,c:TDecimalStr;
    oup:TAufRamVar;
    ae,be,te:integer;//用来记录a和b的小数点偏移位数，总退格
    asgn,bsgn,csgn:char;
    poss,post,len:integer;

begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  //if AAuf.ArgsCount<3 then begin AufScpt.send_error('警告：h_add需要两个参数，语句未执行。');exit end;
  try
    a.data:=AufScpt.TryToString(AAuf.nargs[1]);
    oup:=AufScpt.RamVar(AAuf.nargs[1]);
    if oup.VarType<>ARV_Char then begin
      raise Exception.Create('');
      AufScpt.send_error('警告：第一个参数不是字符串变量类型');
    end;
  except
    AufScpt.send_error('警告：第一个参数解析错误，'+AAuf.nargs[0].arg+'语句未执行。');exit;
  end;
  if not AAuf.TryArgToString(2,b.data) then exit;

  //标准化
  asgn:=number_std(a.data);
  bsgn:=number_std(b.data);

  //将小数点剔除
  len:=length(a.data);
  ae:=0;
  poss:=pos('.',a.data);
  if (poss>0)and(poss<>len) then
    begin
      for post:=poss to len-1 do a.data[post]:=a.data[post+1];
      delete(a.data,len,1);
      ae:=len-poss;
    end;
  if a.data[len]='.' then delete(a.data,len,1);

  len:=length(b.data);
  be:=0;
  poss:=pos('.',b.data);
  if (poss>0)and(poss<>len) then
    begin
      for post:=poss to len-1 do b.data[post]:=b.data[post+1];
      delete(b.data,len,1);
      be:=len-poss;
    end;
  if b.data[len]='.' then delete(b.data,len,1);

  while (a.data[1]='0')and(length(a.data)>1) do delete(a.data,1,1);
  while (b.data[1]='0')and(length(b.data)>1) do delete(b.data,1,1);
  case AAuf.nargs[0].arg of
    'h_div','h_mod':
      begin
        if b=DecimalStr('0') then
          begin
            AufScpt.send_error('警告：第二个参数不能为零，'+AAuf.nargs[0].arg+'语句未执行。');
            exit
          end;
        if (ae+be<>0) then
          begin
            AufScpt.send_error('警告：参数不能为非整数，'+AAuf.nargs[0].arg+'语句未执行。');
            exit
          end;
        if AAuf.nargs[0].arg='h_div' then te:=ae-be
        else te:=0;
      end;
    'h_divreal':
      begin
        te:=ae-be;
        if b=DecimalStr('0') then
          begin
            AufScpt.send_error('警告：第二个参数不能为零，'+AAuf.nargs[0].arg+'语句未执行。');
            exit
          end;
      end;
    'h_add','h_sub':
      begin
        te:=ae;
        if ae>be then begin
          for te:=be+1 to ae do b.data:=b.data+'0';
        end;
        if ae<be then begin
          for te:=ae+1 to be do a.data:=a.data+'0';
        end;
      end;
    'h_mul':
      begin
        te:=ae+be;
      end
    else ;
  end;
  case AAuf.nargs[0].arg of
    'h_add','h_sub','h_mul':
      begin
        a.data:=asgn+a.data;
        b.data:=bsgn+b.data;
      end;
    else ;
  end;

  case AAuf.nargs[0].arg of
    'h_add':c:=a+b;
    'h_sub':c:=a-b;
    'h_mul':c:=a*b;
    'h_div':begin c:=a div b;if asgn<>bsgn then c.data:='-'+c.data;end;
    'h_mod':begin c:=a mod b;end;
    'h_divreal':
      begin
        MaxDivDigit:=oup.size+4;
        c:=a/b;
        if asgn<>bsgn then c.data:='-'+c.data;
      end;
    else ;
  end;

  //把小数点退回去
  csgn:=number_std(c.data);
  poss:=pos('.',c.data);
  if poss=0 then c.data:=c.data+'.0';
  if poss=length(c.data) then c.data:=c.data+'0';
  len:=length(c.data);
  if poss=0 then poss:=len-1;
  if te<0 then begin
    while te<0 do begin
      if poss=len then begin c.data:=c.data+'0';inc(len) end;
      c.data[poss]:=c.data[poss+1];
      inc(poss);
      inc(te);
    end;
    c.data[poss]:='.';
  end else begin
    while te>0 do begin
      if poss=1 then begin c.data:='0'+c.data;inc(poss) end;
      c.data[poss]:=c.data[poss-1];
      dec(poss);
      dec(te);
    end;
    c.data[poss]:='.';
  end;
  len:=length(c.data);
  if c.data[len]='.' then delete(c.data,len,1);
  if c.data[1]='.' then c.data:='0'+c.data;
  c.data:=csgn+c.data;
  len:=length(c.data);
  while len>oup.size do
    begin
      delete(c.data,len,1);
      len:=length(c.data);
    end;

  initiate_arv_str(c.data,oup);


end;
procedure math_hr_arithmetic(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    a,b,c:TRealStr;
    oup:TAufRamVar;
    tmplen:dword;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  try
    a.data:=AufScpt.TryToString(AAuf.nargs[1]);
    oup:=AufScpt.RamVar(AAuf.nargs[1]);
    if oup.VarType<>ARV_Char then begin
      raise Exception.Create('');
      AufScpt.send_error('警告：第一个参数不是字符串变量类型');
    end;
  except
    AufScpt.send_error('警告：第一个参数解析错误，'+AAuf.nargs[0].arg+'语句未执行。');exit;
  end;
  if not AAuf.TryArgToString(2,b.data) then exit;

  case AAuf.nargs[0].arg of
    'h_add':c:=a+b;
    'h_sub':c:=a-b;
    'h_mul':a:=a*b;
    'h_div':;
    'h_mod':;
    'h_divreal':
      begin
        MaxDivDigit:=oup.size;
        c:=a/b;
        tmplen:=length(c.data);
        while tmplen>oup.size do
          begin
            if c.data[tmplen]<>'.' then delete(c.data,tmplen,1)
            else if tmplen-1>oup.size then begin c.data:='error';exit;end
            else delete(c.data,tmplen,1);
            tmplen:=length(c.data);
          end;
      end;
  end;

  initiate_arv_str(c.data,oup);
  //AufScpt.writeln(c.data);

end;

procedure task_enable(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    tmp:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,38,38,[ARV_Char],tmp) then exit;
  AufScpt.EnableTaskMessage;
  initiate_arv_str(GUIDToString(AufScpt.PSW.message.UUID), tmp);
end;

procedure task_disable(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  AufScpt.DisableTaskMessage;
end;

procedure task_list(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    idx,len:integer;
    tmpMI:TMsgItem;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  AufScpt.writeln('TaskQueue '+GUIDToString(AufScpt.PSW.message.UUID)+':');
  len:=AufScpt.PSW.message.Count;
  idx:=AufScpt.PSW.message.First;
  while len>0 do begin
    dec(len);
    tmpMI:=AufScpt.PSW.message.Items[idx];
    AufScpt.writeln('  F:'+GUIDToString(tmpMI.From.PSW.message.UUID)+' S:'+IntToStr(tmpMI.Data.size));
    idx:=(idx-1) mod task_range;
  end;
end;

procedure task_send(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    send_to:TAufScript;
    uuid:TMsgUuid;
    stmp:string;
    arv:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToString(1, stmp) then exit;
  if not AAuf.TryArgToARV(2, 0, High(dword), ARV_AllType, arv) then exit;
  uuid:=StringToGUID(stmp);
  send_to:=GlobalMultiTaskList.FindTask(uuid);
  if send_to<>nil then
    AufScpt.SendTaskMessage(send_to, arv, mcNormal)
  else
    AufScpt.send_error('未找到任务：'+stmp+'，协同消息未发出。');
end;

procedure task_read(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv_uuid, arv_data:TAufRamVar;
    str_uuid:string;
    aufs_from:TAufScript;
    msg_code:TMsgCode;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1, 38, 38, [ARV_Char], arv_uuid) then exit;
  if not AAuf.TryArgToARV(2, 0, High(dword), ARV_AllType, arv_data) then exit;
  aufs_from:=nil;
  AufScpt.ReadTaskMessage(aufs_from, arv_data, msg_code);
  if aufs_from<>nil then begin
    str_uuid:=GUIDToString(aufs_from.PSW.message.UUID);
    initiate_arv_str(str_uuid, arv_uuid);
  end else {AufScpt.send_error('协同消息队列中无条目。')};
end;

procedure task_broadcast(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    send_to:TAufScript;
    uuid_target,uuid_self:string;
    arv:TAufRamVar;
    idx,len:integer;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1, 0, High(dword), ARV_AllType, arv) then exit;
  uuid_self:=GUIDToString(AufScpt.PSW.message.UUID);
  len:=GlobalMultiTaskList.Count;
  for idx:=len-1 downto 0 do begin
    uuid_target:=GlobalMultiTaskList.Strings[idx];
    if uuid_target=uuid_self then continue;
    send_to:=TAufScript(GlobalMultiTaskList.Objects[idx]);
    AufScpt.SendTaskMessage(send_to, arv, mcBroadcast);
  end;
end;

procedure task_wait(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv_uuid, arv_data:TAufRamVar;
    addr:pRam;
    {$ifdef MsgTimerMode}{$else}
    message_received:boolean;
    {$endif}
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(4) then exit;
  if not AAuf.TryArgToARV(1, 38, 38, [ARV_Char], arv_uuid) then exit;
  if not AAuf.TryArgToARV(2, 0, High(dword), ARV_AllType, arv_data) then exit;
  if not AAuf.TryArgToAddr(3, addr) then exit;
  //需要处理预设消息，并且SendMultiTaskMessage需要避免阻塞。
  IF AufScpt.Time.Synthesis_Mode=SynMoTimer THEN BEGIN
    {$ifdef MsgTimerMode}
    AufScpt.Time.MultiTaskTimer.Interval:=50; //暂时将跨任务协同监听间隔定为50ms
    AufScpt.Time.MultiTaskTimer.Enabled:=true;
    AufScpt.Time.MultiTaskTimerPause:=true;
    AufScpt.PSW.message_stored.data:=arv_data;
    AufScpt.PSW.message_stored.uuid:=arv_uuid;
    AufScpt.push_addr(addr);
    {$else}
    //多线程模式还未测试
    message_received:=false;
    while not AufScpt.PSW.haltoff and not AufScpt.PSW.pause do begin
      if AufScpt.PSW.message.Count>0 then begin
        message_received:=true;
        break;
      end;
    end;
    if message_received then begin
      AufScpt.PSW.message_stored.data:=arv_data;
      AufScpt.PSW.message_stored.uuid:=arv_uuid;
    end else begin
      //AufScpt.offs_addr(0);
      //没有接收到消息时通过手动的方法恢复运行时，直接执行下一行
    end;
    {$endif}
  END ELSE BEGIN
    AufScpt.send_error('SynMoDelay时间模式不支持跨任务协同。');
  END;
end;

procedure text_str(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    tmp:TAufRamVar;
    str:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,High(dword),0,[ARV_Char],tmp) then exit;
  if not AAuf.TryArgToString(2,str) then exit;

  initiate_arv_str(str,tmp);
end;
procedure text_val(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    tmp:TAufRamVar;
    str:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,High(dword),0,[ARV_Float,ARV_FixNum],tmp) then exit;
  if not AAuf.TryArgToString(2,str) then exit;

  initiate_arv(str,tmp);
end;
procedure text_strReplace(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    tmp:TAufRamVar;
    old,new,str:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(4) then exit;
  if not AAuf.TryArgToARV(1,High(dword),0,[ARV_Char],tmp) then exit;
  if not AAuf.TryArgToString(2,old) then exit;
  if not AAuf.TryArgToString(3,new) then exit;
  str:=arv_to_s(tmp);
  str:=StringReplace(str,old,new,[rfReplaceAll]);
  initiate_arv_str(str,tmp);
end;
procedure text_strMid(Sender:TObject);//mid @str pos,len
var AufScpt:TAufScript;
    AAuf:TAuf;
    tmp:TAufRamVar;
    pos,len:dword;
    str:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(4) then exit;
  if not AAuf.TryArgToARV(1,High(dword),0,[ARV_Char],tmp) then exit;
  if not AAuf.TryArgToDWord(2,pos) then exit;
  if not AAuf.TryArgToDWord(3,len) then exit;
  str:=arv_to_s(tmp);
  if pos<1 then (Sender as TAufScript).send_error('警告：第2个参数小于等于0，'+AAuf.nargs[0].arg+'语句未执行。');
  delete(str,1,pos-1);
  delete(str,len+1,length(str));
  initiate_arv_str(str,tmp);
end;
procedure text_strCat(Sender:TObject);//cat @str1 @str2 -r
var AufScpt:TAufScript;
    AAuf:TAuf;
    tmp:TAufRamVar;
    s1,s2,mode:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,High(dword),0,[ARV_Char],tmp) then exit;
  if not AAuf.TryArgToString(2,s2) then exit;
  if AAuf.ArgsCount>3 then begin
    if not AAuf.TryArgToString(3,mode) then exit;
  end else begin
    mode:='';
  end;
  s1:=arv_to_s(tmp);
  case lowercase(mode) of
    '-r':initiate_arv_str(s2+s1,tmp);
    else initiate_arv_str(s1+s2,tmp);
  end;
end;

procedure text_strEnumerate(Sender:TObject);
//每次执行都从enum_text中选取一个字母存储给var，从first_index开始  enum var string [first_index]
var AufScpt:TAufScript;
    AAuf:TAuf;
    times,now:dword;
    arv:TAufRamVar;
    enum_text:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,1,High(dword),[ARV_Char],arv) then exit;
  if not AAuf.TryArgToString(2,enum_text) then exit;
  if not length(enum_text)>0 then begin
    s_to_arv('',arv);
    exit;
  end;
  times:=length(enum_text);
  if AAuf.ArgsCount=3 then now:=0
  else now:=StrToInt(AAuf.args[3]);
  if now>=times then now:=0;
  s_to_arv(enum_text[now+1],arv);
  AAuf.args[3]:=IntToStr(now+1);
  AufScpt.ScriptLines[AufScpt.PSW.run_parameter.current_line_number]:=AAuf.args[0]+' '+AAuf.args[1]+','+AAuf.args[2]+','+AAuf.args[3];

end;

procedure text_strFormat(Sender:TObject);//fmt @res, "AAA", 123, @str, ...
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    pi:byte;
    res,stmp:string;
    dtmp:Double;
    ltmp:LongInt;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,1,High(dword),[ARV_Char],arv) then exit;
  res:='';
  for pi:=2 to AAuf.ArgsCount-1 do begin
    if AAuf.TryArgToString(pi,stmp) then begin
      res:=res+stmp;
      continue;
    end;
    if AAuf.TryArgToDouble(pi,dtmp) then begin
      res:=res+FloatToStr(dtmp);
      continue;
    end;
    if AAuf.TryArgToLong(pi,ltmp) then begin
      res:=res+IntToStr(ltmp);
      continue;
    end;
    AufScpt.send_error('第'+IntToStr(pi)+'个参数'+AAuf.args[3]+'无法转换成字符串。');
  end;
  s_to_arv(res,arv);
end;

procedure time_settimer(Sender:TObject);
var AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AufScpt.PSW.extra_variable.timer:=DateTimeToTimeStamp(Now).Time;
end;
procedure time_gettimer(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    tmp:longint;
    arv:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  tmp:=DateTimeToTimeStamp(Now).Time;
  if tmp<AufScpt.PSW.extra_variable.timer then tmp:=tmp+24*60*60*1000;
  tmp:=tmp - AufScpt.PSW.extra_variable.timer;
  if AAuf.ArgsCount=1 then AufScpt.writeln('定时器读数：'+IntToStr(tmp)+'毫秒')
  else
    begin
      if AAuf.TryArgToARV(1,4,High(dword),[ARV_FixNum],arv) then dword_to_arv(dword(tmp),arv);
    end;
end;
procedure time_waittimer(Sender:TObject);//线程不可用，需要再看怎么处理//可以用啊？
var AufScpt:TAufScript;
    AAuf:TAuf;
    tmp,std:dword;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToDWord(1,std) then exit;
  tmp:=DateTimeToTimeStamp(Now).Time;
  if tmp<AufScpt.PSW.extra_variable.timer then tmp:=tmp+24*60*60*1000;
  tmp:=tmp - AufScpt.PSW.extra_variable.timer;

  if tmp>=std then exit
  else begin
    tmp:=std-tmp;
    IF AufScpt.Time.Synthesis_Mode=SynMoTimer THEN BEGIN
      {$ifdef MsgTimerMode}
      AufScpt.Time.Timer.Interval:=tmp;
      AufScpt.Time.Timer.Enabled:=true;
      AufScpt.Time.TimerPause:=true;
      {$else}
      sleep(tmp);
      {$endif}
    END ELSE BEGIN
      sleep(tmp);
    END;
  end;
end;
procedure time_gettimestr(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    tmp,fmt:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if AAuf.ArgsCount>2 then begin
    if not AAuf.TryArgToString(2,fmt) then exit;
    case fmt of
      '-f','-filename':tmp:=TimeToStr(Now,fmtsFile);
      '-F','-FILENAME':tmp:=DateTimeToStr(Now,fmtsFile);
      '-D','-DISPLAY':tmp:=DateTimeToStr(Now,fmtsDisplay);
      else tmp:=TimeToStr(Now,fmtsDisplay);
    end;
  end else tmp:=TimeToStr(Now,fmtsDisplay);
  if AAuf.ArgsCount=1 then AufScpt.writeln('当前时间：'+tmp)
  else if AAuf.TryArgToARV(1,12,High(dword),[ARV_Char],arv) then s_to_arv(tmp,arv);
end;
procedure time_getdatestr(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    tmp,fmt:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if AAuf.ArgsCount>2 then begin
    if not AAuf.TryArgToString(2,fmt) then exit;
    case fmt of
      '-f','-filename':tmp:=DateToStr(Now,fmtsFile);
      '-F','-FILENAME':tmp:=DateTimeToStr(Now,fmtsFile);
      '-D','-DISPLAY':tmp:=DateTimeToStr(Now,fmtsDisplay);
      else tmp:=DateToStr(Now,fmtsDisplay);
    end;
  end else tmp:=DateToStr(Now,fmtsDisplay);
  if AAuf.ArgsCount=1 then AufScpt.writeln('当前日期：'+tmp)
  else if AAuf.TryArgToARV(1,10,High(dword),[ARV_Char],arv) then s_to_arv(tmp,arv);
end;

Procedure ReverseMove(const source;var dest;count:SizeInt);
var i:SizeInt;
begin
  for i:=0 to count-1 do
    begin
      pbyte(@dest)^:=pbyte(@source+count-1-i)^;
    end;
end;

procedure file_exist(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    filename,jm_str:string;
    addr:pRam;
    jmode:TJumpModeSet;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToAddr(1,addr) then exit;
  if not AAuf.TryArgToString(2,filename) then exit;
  jmode:=[];
  if AAuf.ArgsCount>3 then begin
    if not AAuf.TryArgToString(3,jm_str) then exit;
    jm_str:=lowercase(jm_str);
    if pos('c',jm_str)>=0 then jmode:=jmode+[jmCall];
    if pos('n',jm_str)>=0 then jmode:=jmode+[jmNot];
  end;
  if FileExists(filename) xor (jmNot in jmode) then
    begin
      if jmCall in jmode then AufScpt.push_addr(addr)
      else AufScpt.jump_addr(addr);
    end;

end;

procedure file_read(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    filename:string;
    mem:TMemoryStream;
    fsize:int64;
    arv:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToString(2,filename) then exit;
  fsize:=FileSize(filename);
  if not AAuf.TryArgToARV(1,fsize,High(dword),ARV_AllType,arv) then exit;
  mem:=TMemoryStream.Create;
  try
    mem.LoadFromFile(filename);
    mem.Position:=0;
    mem.Read(arv.Head^,fsize);
  finally
    mem.Free;
  end;
end;

procedure file_write(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    filename:string;
    str:TMemoryStream;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,0,High(Longint),[ARV_Char],arv) then exit;
  if not AAuf.TryArgToString(2,filename) then exit;
  str:=TMemoryStream.Create;
  try
    str.SetSize(arv.size);
    Move(arv.Head^,str.Memory^,arv.size);
    str.SaveToFile(filename);
  finally
    str.Free;
  end;
end;

procedure file_list(Sender:TObject);//file.list @array "path","filter"
var AufScpt:TAufScript;
    AAuf:TAuf;
    pathname,filter,stmp:string;
    obj:TObject;
    array_obj:TAufArray;
    file_list:TStringList;

begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(4) then exit;
  if not AAuf.TryArgToObject(1,TAufArray,obj) then exit;
  if not AAuf.TryArgToString(2,pathname) then exit;
  if not AAuf.TryArgToString(3,filter) then exit;
  array_obj:=obj as TAufArray;
  array_obj.Clear;
  file_list:=TStringList.Create;
  try
    FindAllFiles(file_list,pathname,filter,false,faAnyFile);
    for stmp in file_list do begin
      array_obj.Insert(array_obj.Count,TAufBase.CreateAsString(stmp));
    end;
  finally
    file_list.Free;
  end;
end;

procedure ptr_shift_or_offset(Sender:TObject);//pshl|pshr|pofl|pofr|pexl|pexr|pcpl|pcpr var,byte
label ErrOver_L,ErrOver_R,ErrOver_O;
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    hh,ss,hhh,sss:pRam;
    idx:longint;
    exprname,func:string;
    expr:Tnargs;

begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToString(1,exprname) then exit;
  if not AAuf.TryArgToLong(2,idx) then exit;

  expr:=AufScpt.Expression.Local.Translate(exprname);
  if expr.arg[1]='~' then begin
    AufScpt.send_error('警告：变量未找到，该语句未执行。');
    exit;
  end;
  arv:=AufScpt.RamVar(expr);
  if arv.size=0 then begin
    AufScpt.send_error('警告：变量不是合法指针类型，该语句未执行。');
    exit;
  end;

  hh:=arv.Head - AufScpt.PSW.run_parameter.ram_zero;
  ss:=arv.size;
  func:=lowercase(AAuf.args[0]);
  case func of
    'pshl':
      begin
        if idx>hh then goto ErrOver_L;
        if AufScpt.PSW.run_parameter.ram_size-ss<hh-idx then goto ErrOver_R;
        hhh:=hh-idx;
        sss:=ss;
      end;
    'pshr':
      begin
        if -idx>hh then goto ErrOver_L;
        if AufScpt.PSW.run_parameter.ram_size-ss<hh+idx then goto ErrOver_R;
        hhh:=hh+idx;
        sss:=ss;
      end;
    'pofl':
      begin
        if idx*int64(ss)>hh then goto ErrOver_L;
        if AufScpt.PSW.run_parameter.ram_size-ss<int64(hh)-idx*int64(ss) then goto ErrOver_R;
        hhh:=hh-idx*ss;
        sss:=ss;
      end;
    'pofr':
      begin
        if -idx*int64(ss)>hh then goto ErrOver_L;
        if AufScpt.PSW.run_parameter.ram_size-ss<int64(hh)+int64(idx)*ss then goto ErrOver_R;
        hhh:=hh+idx*ss;
        sss:=ss;
      end;
    'pexl':
      begin
        if idx>hh then goto ErrOver_L;
        if -idx>=ss then goto ErrOver_O;
        hhh:=hh-idx;
        sss:=ss+idx;
      end;
    'pexr':
      begin
        if -idx>ss then goto ErrOver_O;
        if AufScpt.PSW.run_parameter.ram_size-ss<hh-idx then goto ErrOver_R;
        hhh:=hh;
        sss:=ss+idx;
      end;
    'pcpl':
      begin
        if -idx>hh then goto ErrOver_L;
        if idx>=ss then goto ErrOver_O;
        hhh:=hh+idx;
        sss:=ss-idx;
      end;
    'pcpr':
      begin
        if idx>ss then goto ErrOver_O;
        if AufScpt.PSW.run_parameter.ram_size-ss<hh+idx then goto ErrOver_R;
        hhh:=hh;
        sss:=ss-idx;
      end;
    else
      begin
        AufScpt.send_error('未知的指针偏移函数');
        exit;
      end
  end;
  arv.Head:=AufScpt.PSW.run_parameter.ram_zero + hhh;
  arv.size:=sss;
  AufScpt.Expression.Local.TryAddExp(exprname,AufScpt.RamVarToNargs(arv));
  exit;

ErrOver_O:
  AufScpt.send_error('指针定义长度过小[O]。');
  exit;
ErrOver_L:
  AufScpt.send_error('指针定义位移超界[L]。');
  exit;
ErrOver_R:
  AufScpt.send_error('指针定义位移超界[R]。');

end;

procedure _syntax_assign(Sender:TObject); // = method result ...
var AAuf:TAuf;
    AufScpt:TAufScript;
    method_name,define_name:string;
    head:pRam;
    exp:Tnargs;
    auftype:TClass;
    obj:TObject;
    arv:TAufRamVar;
    exp_unit:TAufExpressionUnit;
    idx,len:integer;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  method_name:=AAuf.args[1];
  define_name:=AAuf.args[2];

  if (length(define_name)<1) or not (define_name[1] in ['a'..'z','A'..'Z','_']) then begin
    AufScpt.send_error('警告：无效变量名。赋值语法需要以@开头，且变量名需要以字母或下划线开头');
    exit;
  end;
  auftype:=AufScpt.type_func(method_name);
  if auftype=nil then begin
    AufScpt.send_error('警告：'+method_name+'指令不包含返回类型，未成功赋值');
    exit;
  end;
  exp_unit:=AufScpt.Expression.Local.Find(define_name);


  if exp_unit<>nil then begin
    arv:=AufScpt.RamVar(exp_unit.value);
    if arv.size<>8 then begin
      AufScpt.send_error('警告：变量名'+define_name+'已存在，且长度不为8，因而无法修改，未成功赋值');
      exit;
    end;

    //变量覆盖不析构，析构全部交给AufBase的ClearTotalInstance
    //obj:=arv_to_obj(arv);
    //obj.Free;

    if not AufScpt.Expression.Local.TryDeleteExp(define_name) then begin
      AufScpt.send_error('警告：变量名'+define_name+'无法删除，未成功赋值');
      exit;
    end;
  end;

  exp.pre:='$"';
  head:=AufScpt.FindRamVacant(8);
  exp.arg:=pRamToRawStr(head)+'|'+pRamToRawStr(8);
  exp.post:='"';
  arv.Head:=pbyte(head+AufScpt.PSW.run_parameter.ram_zero);
  arv.size:=8;
  arv.VarType:=ARV_FixNum;
  arv.Is_Temporary:=false;
  arv.Stream:=nil;
  fillARV(0,arv);
  try
    AufScpt.Expression.Local.TryAddExp(define_name,exp);
  except
    AufScpt.send_error('警告：定义名创建错误，未正确执行');
    exit;
  end;
  AufScpt.RamOccupation[head,8]:=true;

  obj:=auftype.Create;
  obj_to_arv(obj,arv);

  AAuf.nargs[0]:=narg('',method_name,'');
  AAuf.args[0]:=method_name;
  len:=AAuf.ArgsCount;
  for idx:=2 to len-1 do begin
    AAuf.nargs[idx-1]:=AAuf.nargs[idx];
    AAuf.args[idx-1]:=AAuf.args[idx];
  end;
  AAuf.nargs[len-1]:=narg('','','');
  AAuf.args[len-1]:='';
  dec(AAuf.ArgsCount);
  AufScpt.run_func(method_name);

end;

procedure _syntax_property(Sender:TObject); // . method subject ...
var AAuf:TAuf;
    AufScpt:TAufScript;
    obj:TObject;
    obj_class:TClass;
    method_name,method_name_with_class:string;
    idx,len:integer;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  method_name:=AAuf.args[1];
  if not AAuf.TryArgToObject(2, TAufBase, obj) then exit;
  assert(not (obj is TAufBase),'_syntax_property中第二个参数obj必须是TAufBase及其子类');
  obj_class:=obj.ClassType;
  repeat
    method_name_with_class:=TAufBaseClass(obj_class).AufTypeName+'.'+method_name;
    if AufScpt.have_func(method_name_with_class) then break;
    obj_class:=obj_class.ClassParent;
  until obj_class=TAufBase;
  AAuf.nargs[0]:=narg('',method_name,'');
  AAuf.args[0]:=method_name;
  len:=AAuf.ArgsCount;
  for idx:=2 to len-1 do begin
    AAuf.nargs[idx-1]:=AAuf.nargs[idx];
    AAuf.args[idx-1]:=AAuf.args[idx];
  end;
  AAuf.nargs[len-1]:=narg('','','');
  AAuf.args[len-1]:='';
  dec(AAuf.ArgsCount);
  AufScpt.run_func(method_name_with_class);
end;

procedure array_newArray(Sender:TObject); //array.new @arr  ||  array.new = arr
var AAuf:TAuf;
    AufScpt:TAufScript;
    obj:TAufArray;
    arv:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  obj:=TAufArray.Create;
  obj_to_arv(obj,arv);
end;

procedure array_delArray(Sender:TObject); //array.del @arr  ||  array.del . arr
var AAuf:TAuf;
    AufScpt:TAufScript;
    obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToObject(1,TAufArray,obj) then exit;
  if obj is TAufArray then begin
    (obj as TAufArray).Free;
  end else begin
    AufScpt.send_error('找不到对应的TAufArray，删除失败');
  end;
end;

procedure array_copyArray(Sender:TObject); //array.copy dst,src  ||  array.copy = dst src
var AAuf:TAuf;
    AufScpt:TAufScript;
    src,dst:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToObject(1,TAufArray,dst) then exit;
  if not AAuf.TryArgToObject(2,TAufArray,src) then exit;
  TAufArray(dst).Assign(TAufArray(src));
end;

procedure array_ClearArrayList(Sender:TObject);
var AufScpt:TAufScript;
    count:integer;
begin
  AufScpt:=Sender as TAufScript;
  count:=TAufArray.ClassInstancesCount;
  TAufArray.ClearClassInstances;
  AufScpt.writeln('共删除'+IntToStr(count)+'个TAufArray数组。');
end;

procedure array_Insert(Sender:TObject);//array.insert @arr,12[,0]
var AAuf:TAuf;
    AufScpt:TAufScript;
    obj:TObject;
    index:integer;
    element:TAufBase;
    arv:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToObject(1,TAufArray,obj) then exit;
  element:=AufBaseParser(AAuf.args[2]);
  if element=nil then begin
    if not AAuf.TryArgToARV(2,1,High(dword),[ARV_FixNum, ARV_Float, ARV_Char],arv) then exit;
    element:=TAufBase.CreateAsARV(arv);
  end;
  if AAuf.ArgsCount<4 then begin
    index:=TAufArray(obj).Count;
  end else begin
    if not AAuf.TryArgToLong(3,index) then exit;
  end;
  TAufArray(obj).Insert(index,element);
end;

procedure array_Reinsert(Sender:TObject);//array.reinsert @arr,elem
var AAuf:TAuf;
    AufScpt:TAufScript;
    obj:TObject;
    element:TAufBase;
    arv:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToObject(1,TAufArray,obj) then exit;
  element:=AufBaseParser(AAuf.args[2]);
  if element=nil then begin
    if not AAuf.TryArgToARV(2,1,High(dword),[ARV_FixNum, ARV_Float, ARV_Char],arv) then exit;
    element:=TAufBase.CreateAsARV(arv);
  end;
  TAufArray(obj).Reinsert(element);
end;

procedure array_Delete(Sender:TObject);//array.delete @arr,index[,@res]
var AAuf:TAuf;
    AufScpt:TAufScript;
    obj:TObject;
    index:integer;
    arv,res:TAufRamVar;
    element:TAufBase;
    screen_output:boolean;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToObject(1,TAufArray,obj) then exit;
  if not AAuf.TryArgToLong(2,index) then exit;
  if AAuf.ArgsCount<4 then begin
    screen_output:=true;
  end else begin
    if not AAuf.TryArgToARV(3,1,High(dword),[ARV_FixNum, ARV_Float, ARV_Char],arv) then exit;
    screen_output:=false;
  end;

  element:=TAufArray(obj).Delete(index);
  res:=element.ARV;
  if screen_output then AufScpt.writeln('删除数组中的元素['+IntToStr(index)+']：'+arv_to_s(res))
  else copyARV(res,arv);
  element.Free;
end;

procedure array_Draw(Sender:TObject);//array.draw @arr[,@res]
var AAuf:TAuf;
    AufScpt:TAufScript;
    obj:TObject;
    arv,res:TAufRamVar;
    element:TAufBase;
    screen_output:boolean;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToObject(1,TAufArray,obj) then exit;
  if AAuf.ArgsCount<3 then begin
    screen_output:=true;
  end else begin
    if not AAuf.TryArgToARV(2,1,High(dword),[ARV_FixNum, ARV_Float, ARV_Char],arv) then exit;
    screen_output:=false;
  end;

  element:=TAufArray(obj).Draw();
  res:=element.ARV;
  copyARV(element.ARV,res);
  if screen_output then AufScpt.writeln('随机抽取数组中的元素：'+arv_to_s(res))
  else copyARV(res,arv);
  element.Free;
end;

procedure array_Clear(Sender:TObject);
var AAuf:TAuf;
    AufScpt:TAufScript;
    obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToObject(1,TAufArray,obj) then exit;
  TAufArray(obj).Clear;
end;

procedure array_Print(Sender:TObject);
var AAuf:TAuf;
    AufScpt:TAufScript;
    obj:TObject;
    afn:TAufBase;
    idx,len:Integer;
    stmp,split:string;
    ln_mode:boolean;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToObject(1,TAufArray,obj) then exit;
  ln_mode:=lowercase(AAuf.args[0])='array.println';
  if not ln_mode then begin
    stmp:='[';
    split:=',';
  end else begin
    stmp:='';
    split:={$ifdef WINDOWS}#13#10{$else}#10{$endif};
  end;
  with TAufArray(obj) do begin
    for idx:=0 to Count-1 do begin
      afn:=Items[idx];
      stmp:=stmp+arv_to_s(afn.ARV);
      stmp:=stmp+split;
    end;
  end;
  len:=length(stmp);
  if len>2 then System.Delete(stmp,len,length(split));
  if not ln_mode then stmp:=stmp+']';
  AufScpt.writeln(stmp);
end;

procedure array_Count(Sender:TObject);
var AAuf:TAuf;
    AufScpt:TAufScript;
    obj:TObject;
    arv:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToObject(1,TAufArray,obj) then exit;
  if not AAuf.TryArgToARV(2,1,High(longint),[ARV_FixNum],arv) then exit;
  dword_to_arv(TAufArray(obj).Count,arv);
end;

procedure array_CheckElement(Sender:TObject);//array.valid? @array, :addr || array.empty?
var AAuf:TAuf;
    AufScpt:TAufScript;
    obj:TObject;
    addr:pRam;
    method_name:string;
    is_not,is_call:boolean;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToObject(1,TAufArray,obj) then exit;
  if not AAuf.TryArgToAddr(2,addr) then exit;
  method_name:=AAuf.args[0];
  is_not:=false;
  compare_jump_mode(method_name,is_not,is_call);
  case method_name of
    'empty?':is_not:=not is_not;
  end;
  if ((obj as TAufArray).Count>0) xor is_not then begin
    if is_call then AAuf.Script.push_addr(AufScpt.ScriptLines,AufScpt.ScriptName,addr)
    else AufScpt.jump_addr(addr);
  end;
end;

function img_get_filename(AufScpt:TAufScript;filename:string;write_mode:string):string;
var rename_series:integer;
    noext,ext,stmp:string;
begin
  if FileExists(filename) then begin
    case lowercase(write_mode) of
      '-f','-force':;//do nothing
      '-r','-rename':
        begin
          rename_series:=0;
          noext:=ExtractFileNameWithoutExt(filename);
          ext:=ExtractFileExt(filename);
          repeat
            stmp:=noext+'_'+IntToStr(rename_series)+ext;
            if not FileExists(stmp) then break;
            inc(rename_series);
          until rename_series>=10000;
          if rename_series<10000 then
            result:=stmp
          else begin
            AufScpt.send_error(filename+'文件及其所有替代文件名均已存在，导出图片失败。');
            result:='';
          end;
          exit;
        end;
      else // '-e','-error'
        begin
          AufScpt.send_error(filename+'文件已存在，导出图片失败。');
          result:='';
          exit;
        end;
    end;
  end;
  result:=filename;
end;

procedure img_newImage(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    arv:TAufRamVar;
    ari:TARImage;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  ari:=TARImage.Create;
  obj_to_arv(ari,arv);
end;

procedure img_delImage(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    obj:TObject;
    arv:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  obj:=arv_to_obj(arv);
  if obj is TARImage then begin
    (obj as TARImage).Free;
    //AufScpt.writeln('删除Image成功');
  end else begin
    AufScpt.send_error('找不到对应的ARImage，删除失败');
  end;
end;
procedure img_copyImage(Sender:TObject);//img.copy img1,img2
var AufScpt:TAufScript;
    AAuf:TAuf;
    img1,img2:TARImage;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToObject(1,TARImage,TObject(img1)) then exit;
  if not AAuf.TryArgToObject(2,TARImage,TObject(img2)) then exit;
  img1.Clear;
  img1.FPicture.Assign(img2.FPicture);
end;
procedure img_saveImage(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    obj:TObject;
    arv:TAufRamVar;
    filename,write_mode:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  if not AAuf.TryArgToString(2,filename) then exit;
  if AAuf.ArgsCount>=4 then begin
    if not AAuf.TryArgToStrParam(3,['-f','-force','-r','-rename','-e','-error'],false,write_mode) then exit;
    write_mode:=lowercase(write_mode);
  end else begin
    write_mode:='-e';
  end;
  obj:=arv_to_obj(arv);
  if not (obj is TARImage) then begin
    AufScpt.send_error('找不到对应的ARImage，删除失败');
    exit;
  end;
  filename:=img_get_filename(AufScpt,filename,write_mode);
  if filename='' then exit;
  try
    (obj as TARImage).SaveToFile(filename);
  except
    AufScpt.send_error('图片导出失败，原因未知。');
  end;
end;
procedure img_loadImage(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    obj:TObject;
    arv:TAufRamVar;
    filename:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv) then exit;
  if not AAuf.TryArgToString(2,filename) then exit;
  obj:=arv_to_obj(arv);
  if not (obj is TARImage) then begin
    AufScpt.send_error('找不到对应的ARImage，删除失败');
    exit;
  end;
  try
    (obj as TARImage).LoadFromFile(filename);
  except
    AufScpt.send_error('图片导入失败，原因未知。');
  end;
end;
procedure img_clipImage(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    w,h,x,y:integer;
    rsrc:TRect;
    img,new_img:TARImage;
    arv:TAufRamVar;
    mode:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToObject(1,TARImage,TObject(img)) then exit;
  AAuf.TryArgToARV(1,8,8,[ARV_FixNum],arv);
  IF lowercase(AAuf.args[0]) = 'img.clip' THEN BEGIN
    if not AAuf.CheckArgs(6) then exit;
    if not AAuf.TryArgToLong(2,x) then exit;
    if not AAuf.TryArgToLong(3,y) then exit;
    if not AAuf.TryArgToLong(4,w) then exit;
    if not AAuf.TryArgToLong(5,h) then exit;
    rsrc:=Rect(x,y,x+w,y+h);
  END ELSE BEGIN
    if AAuf.ArgsCount>3 then begin
      if not AAuf.TryArgToStrParam(3,['-sub','-abs'],false,mode) then exit;
      mode:=lowercase(mode);
    end else mode:='-abs';

    case lowercase(AAuf.args[0]) of
      'img.trmr':begin
        if not AAuf.TryArgToLong(2,w) then exit;
        case mode of
          '-abs':begin
            h:=img.Height;
            rsrc:=Rect(0,0,w,h);
          end;
          '-sub':begin
            h:=img.Height;
            rsrc:=Rect(0,0,img.Width-w,h);
          end;
        end;
      end;
      'img.trml':begin
        if not AAuf.TryArgToLong(2,w) then exit;
        case mode of
          '-abs':begin
            h:=img.Height;
            rsrc:=Rect(img.Width-w,0,img.Width,h);
          end;
          '-sub':begin
            h:=img.Height;
            rsrc:=Rect(w,0,img.Width,h);
          end;
        end;
      end;
      'img.trmb':begin
        if not AAuf.TryArgToLong(2,h) then exit;
        case mode of
          '-abs':begin
            w:=img.Width;
            rsrc:=Rect(0,0,w,h);
          end;
          '-sub':begin
            w:=img.Width;
            rsrc:=Rect(0,0,w,img.Height-h);
          end;
        end;
      end;
      'img.trmt':begin
        if not AAuf.TryArgToLong(2,h) then exit;
        case mode of
          '-abs':begin
            w:=img.Width;
            rsrc:=Rect(0,img.Height-h,w,img.Height);
          end;
          '-sub':begin
            w:=img.Width;
            rsrc:=Rect(0,h,w,img.Height);
          end;
        end;
      end;
      else raise Exception.Create('函数名不符合img_clipImage的要求');
    end;
  END;
  new_img:=img.Clip(rsrc);
  if new_img<>nil then begin
    obj_to_arv(new_img,arv);
    img.Free;
  end else begin
    AufScpt.send_error('裁切图像失败。');
  end;
end;
procedure img_getImageValue(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    img:TARImage;
    arv:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToObject(1,TARImage,TObject(img)) then exit;
  if not AAuf.TryArgToARV(2,4,High(dword),[ARV_FixNum],arv) then exit;
  case lowercase(AAuf.args[0]) of
    'img.width':dword_to_arv(img.Width,arv);
    'img.height':dword_to_arv(img.Height,arv);
    else raise Exception.Create('函数名不符合img_getImageValue的要求');
  end;
end;
procedure img_getImageAverageColor(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    img:TARImage;
    arv:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToObject(1,TARImage,TObject(img)) then exit;
  if not AAuf.TryArgToARV(2,sizeof(dword),High(pRam),[ARV_FixNum],arv) then exit;
  dword_to_arv(dword(img.AverageColor),arv);
end;
procedure img_getImagePixelFormat(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    img:TARImage;
    arv:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToObject(1,TARImage,TObject(img)) then exit;
  if not AAuf.TryArgToARV(2,7,High(dword),[ARV_Char],arv) then exit;
  initiate_arv_str(img.PixelFormat,arv);
end;

procedure img_cj(Sender:TObject);//img._cje_ img1,img2,:label
var AufScpt:TAufScript;
    AAuf:TAuf;
    img1,img2:TARImage;
    arv:TAufRamVar;
    addr:pRam;
    mode:string;
    is_not,is_call,is_equal:boolean;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToObject(1,TARImage,TObject(img1)) then exit;
  if not AAuf.TryArgToObject(2,TARImage,TObject(img2)) then exit;
  if not AAuf.TryArgToAddr(3,addr) then exit;
  mode:=AAuf.args[0];
  compare_jump_mode(mode,is_not,is_call);
  is_equal:=img1.ImgEqual(img2);
  if is_equal xor is_not then begin
    if is_call then AufScpt.push_addr(addr)
    else AufScpt.jump_addr(addr);
  end;

end;

procedure img_clearImageList(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    ari_count:integer;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  ari_count:=ARImageList.Count;
  TARImage.ClearImageList;
  AufScpt.writeln('共删除'+IntToStr(ari_count)+'个ARI图像。');
end;

procedure img_AddByLine(Sender:TObject); //img.addln img1,img2[,pw=10,bm=0]
var AufScpt:TAufScript;
    AAuf:TAuf;
    a1,a2:TAufRamVar;
    pw,bm:byte;
    res:integer;
    img1,img2,img3:TARImage;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1,8,8,[ARV_FixNum],a1) then exit;
  if not AAuf.TryArgToARV(2,8,8,[ARV_FixNum],a2) then exit;
  if AAuf.ArgsCount>3 then begin
    if not AAuf.TryArgToByte(3,pw) then exit;
  end else begin
    pw:=10;
  end;
  if AAuf.ArgsCount>4 then begin
    if not AAuf.TryArgToByte(4,bm) then exit;
  end else begin
    bm:=0;
  end;
  img1:=arv_to_obj(a1) as TARImage;
  img2:=arv_to_obj(a2) as TARImage;
  AufScpt.writeln('findstart='+IntToStr(img1.FindStart(img2,pw,bm,res)));
  AufScpt.writeln('backcount='+IntToStr(res));
  img3:=img1.AddByLine(img2,pw,bm);
  if img3=nil then AufScpt.writeln('不符合拼接要求。')
  else begin
    img1.Free;
    obj_to_arv(img3,a1);
  end;


end;

procedure img_VoidSegmentByLine(Sender:TObject); //img.vsegln img,min,tor,basename
var AufScpt:TAufScript;
    AAuf:TAuf;
    a1,a2:TAufRamVar;
    pw,bm:byte;
    res:integer;
    img,img_out,img_rest:TARImage;
    min,tor:integer;
    basename,filename:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(5) then exit;
  if not AAuf.TryArgToObject(1,TARImage,TObject(img)) then exit;
  if not AAuf.TryArgToLong(2,min) then exit;
  if not AAuf.TryArgToLong(3,tor) then exit;
  if not AAuf.TryArgToString(4,basename) then exit;

  repeat
    img_out:=img.VoidSegmentByLine(img_rest,min,tor);
    filename:=img_get_filename(AufScpt,basename,'-r');
    if filename='' then break;
    if img_out=nil then begin
      img.SaveToFile(filename);
      img.free;
    end else begin
      img_out.SaveToFile(filename);
      img_out.free;
      img.free;
      img:=img_rest;
    end;
  until img_out=nil;
end;

procedure svo_load(Sender:TObject); //svo_load script
var AufScpt:TAufScript;
    AAuf:TAuf;
    script:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToString(1,script) then exit;

end;



//内置流程函数结束




///////////Class Methods begin


//Auf Methods
procedure TAuf.ReadArgs(ps:string);
var tps:string;
    tpi,tpm:integer;
    in_quotation,is_post:boolean;
begin
  //初始化返回变量
  for tpi:=0 to args_range-1 do args[tpi]:='';
  for tpi:=0 to args_range-1 do begin nargs[tpi].arg:='';nargs[tpi].post:='';nargs[tpi].pre:='' end;
  ArgsCount:=0;
  toto:='';divi:='';iden:='';

  //命令删除重复空格

  if ps<>'' then tps:=non_space_quote(ps) else exit;

  //以nargs为主体的处理过程
  tpm:=0;//当前输入的参数下标
  is_post:=false;
  in_quotation:=false;
  for tpi:=1 to length(tps) do
    begin
      if tps[tpi]='"' then
        begin
          in_quotation:=not in_quotation;
          if nargs[tpm].pre[length(nargs[tpm].pre)]<>'"' then nargs[tpm].pre:=nargs[tpm].pre+'"';
          //if nargs[tpm].post[1]<>'"' then nargs[tpm].post:='"'+nargs[tpm].post;
          iden:=iden+tps[tpi];
          toto:=toto+tps[tpi];
        end;
      if not in_quotation then
        begin
          if tps[tpi] in c_divi then
            begin
              {}if (nargs[tpm].arg<>'')or(nargs[tpm].pre<>'')or(nargs[tpm].post<>'') then {}inc(tpm);
              is_post:=false;
              divi:=divi+tps[tpi];
              toto:=toto+tps[tpi];
            end
          else
            begin
              if not(tps[tpi] in c_iden) then
                begin
                  is_post:=true;
                  if tps[tpi]<>'"' then nargs[tpm].arg:=nargs[tpm].arg+tps[tpi];
                end
              else
                begin
                  iden:=iden+tps[tpi];
                  toto:=toto+tps[tpi];
                  case is_post of
                    true:nargs[tpm].post:=nargs[tpm].post+tps[tpi];
                    false:nargs[tpm].pre:=nargs[tpm].pre+tps[tpi];
                  end;
                end;
            end;
        end
      else
        begin
          if tps[tpi]<>'"' then nargs[tpm].arg:=nargs[tpm].arg+tps[tpi]
          else nargs[tpm].post:='"'+nargs[tpm].post;
        end;
    end;
  ArgsCount:=tpm+1;

  for tpi:=0 to argsCount-1 do args[tpi]:=nargs[tpi].pre+nargs[tpi].arg+nargs[tpi].post;
  //Self.Script.send_error('@@@@'+Self.Script.ArgLine);

end;

function TAuf.CheckArgs(MinCount:byte):boolean;//检验参数数量是否满足最小数量要求，数量包括函数名本身
begin
  if Self.ArgsCount < MinCount then
    begin
      Self.Script.send_error('警告：'+Self.nargs[0].arg+'需要（至少）'+IntToStr(MinCount-1)+'个变量，该语句未执行。');
      result:=false;
    end
  else result:=true;
end;

function TAuf.TryArgToByte(ArgNumber:byte;out res:byte):boolean;
begin
  Assert(ArgNumber in [1..args_range],'ArgNumber必须在[1..args_range]范围内。');
  result:=false;
  try
    res:=Script.TryToDWord(nargs[ArgNumber]) mod 256;
  except
    Script.send_error('警告：第'+IntToStr(ArgNumber)+'个参数不能转化为字节byte，代码未执行。');exit
  end;
  result:=true;
end;
function TAuf.TryArgToDWord(ArgNumber:byte;out res:dword):boolean;
begin
  Assert(ArgNumber in [1..args_range],'ArgNumber必须在[1..args_range]范围内。');
  result:=false;
  try
    res:=Script.TryToDWord(nargs[ArgNumber]);
  except
    Script.send_error('警告：第'+IntToStr(ArgNumber)+'个参数不能转化为双字dword，代码未执行。');exit
  end;
  result:=true;
end;
function TAuf.TryArgToLong(ArgNumber:byte;out res:longint):boolean;
begin
  Assert(ArgNumber in [1..args_range],'ArgNumber必须在[1..args_range]范围内。');
  result:=false;
  try
    res:=Script.TryToLong(nargs[ArgNumber]);
  except
    Script.send_error('警告：第'+IntToStr(ArgNumber)+'个参数不能转化为双字DWord（有符号），代码未执行。');exit
  end;
  result:=true;
end;
function TAuf.TryArgToString(ArgNumber:byte;out res:string):boolean;
begin
  Assert(ArgNumber in [1..args_range],'ArgNumber必须在[1..args_range]范围内。');
  result:=false;
  try
    res:=Script.TryToString(nargs[ArgNumber]);
  except
    Script.send_error('警告：第'+IntToStr(ArgNumber)+'个参数不能转化为字符串string，代码未执行。');exit
  end;
  result:=true;
end;
function TAuf.TryArgToStrParam(ArgNumber:byte;paramAllowance:array of string;CaseSensitivity:boolean;out res:string):boolean;
var stmp,list:string;
    len,idx:integer;
begin
  result:=false;
  if not TryArgToString(ArgNumber,stmp) then exit;
  len:=Length(paramAllowance);
  if len<1 then exit;
  list:='';
  if CaseSensitivity then begin
    for idx:=0 to len-1 do begin
      list:=list+','+paramAllowance[idx];
      if paramAllowance[idx]=stmp then begin
        res:=stmp;
        result:=true;
        exit
      end;
    end;
  end else begin
    for idx:=0 to len-1 do begin
      list:=list+','+paramAllowance[idx];
      if lowercase(paramAllowance[idx])=lowercase(stmp) then begin
        res:=stmp;
        result:=true;
        exit
      end;
    end;
  end;
  System.Delete(list,1,1);
  Script.send_error('警告：第'+IntToStr(ArgNumber)+'个参数不在['+list+']范围内，代码未执行。');
end;
function TAuf.TryArgToDouble(ArgNumber:byte;out res:double):boolean;
begin
  Assert(ArgNumber in [1..args_range],'ArgNumber必须在[1..args_range]范围内。');
  result:=false;
  try
    res:=Script.TryToDouble(nargs[ArgNumber]);
  except
    Script.send_error('警告：第'+IntToStr(ArgNumber)+'个参数不能转化为浮点型double，代码未执行。');exit
  end;
  result:=true;
end;
function TAuf.TryArgToPRam(ArgNumber:byte;out res:pRam):boolean;
begin
  Assert(ArgNumber in [1..args_range],'ArgNumber必须在[1..args_range]范围内。');
  result:=false;
  try
    res:=Script.TryToDWord(nargs[ArgNumber]);
  except
    Script.send_error('警告：第'+IntToStr(ArgNumber)+'个参数不能转化为pRam('+AufScript_CPU+'整型数)，代码未执行。');exit
  end;
  result:=true;
end;
function TAuf.TryArgToARV(ArgNumber:byte;minsize,maxsize:dword;TypeAllowance:TAufRamVarTypeSet;out res:TAufRamVar):boolean;
var tmpUnit:TAufExpressionUnit;
begin
  Assert(ArgNumber in [1..args_range],'ArgNumber必须在[1..args_range]范围内。');
  result:=false;

  IF nargs[ArgNumber].pre = '' THEN BEGIN
    //增加动态的变量查找
    tmpUnit:=Script.Expression.Local.Find(args[ArgNumber]);
    if tmpUnit=nil then begin
      Script.send_error('警告：找不到变量定义'+args[ArgNumber]+'，代码未执行。');
      exit;
    end;
    res:=Script.RamVar(tmpUnit.value);
  END ELSE BEGIN
    res:=Script.RamVar(nargs[ArgNumber]);
  END;

  if (res.size=0) then
    begin
      Script.send_error('警告：第'+IntToStr(ArgNumber)+'个参数不是ARV变量，代码未执行。');
      exit
    end;
  if not (res.VarType in TypeAllowance) then
    begin
      Script.send_error('警告：第'+IntToStr(ArgNumber)+'个参数类型有误，代码未执行。');
      exit
    end;
  if maxsize>minsize then begin
    if (res.size>maxsize) or (res.size<minsize) then
      begin
        Script.send_error('警告：第'+IntToStr(ArgNumber)+'个参数变量长度应在'+IntToStr(minsize)+'至'+IntToStr(maxsize)+'范围内，而不能是'+IntToStr(res.size)+'，代码未执行。');
        exit
      end;
  end else if maxsize=minsize then begin
    if res.size<>maxsize then
      begin
        Script.send_error('警告：第'+IntToStr(ArgNumber)+'个参数变量长度应为'+IntToStr(maxsize)+'，而不能是'+IntToStr(res.size)+'，代码未执行。');
        exit
      end;
  end;
  result:=true;
end;

function TAuf.TryArgToDirectData(ArgNumber:byte;DataVarType:TAufRamVarType;out res:TAufRamVar):boolean;
var value_len:integer;
    value_str:string;
begin
  Assert(ArgNumber in [1..args_range],'ArgNumber必须在[1..args_range]范围内。');
  result:=false;
  if not res.Is_Temporary then begin
    raise Exception.Create('立即数必须保存在临时ARV中');
  end;
  case DataVarType of
    ARV_Char:begin
      value_str:=nargs[ArgNumber].arg;
      value_str:=UTF8ToWinCP(value_str);
      value_len:=length(value_str);
      res.size:=value_len+1;
      res.Stream.Clear;
      res.Stream.Size:=res.size;
      res.Stream.Position:=0;
      res.Stream.Write(value_str[1],value_len);
      res.Stream.WriteByte(0);
      res.VarType:=ARV_Char;
      result:=true;
      exit;
    end;
    ARV_FixNum:begin
      initiate_arv(args[ArgNumber],res);
    end;
    ARV_Float:begin
      //临时规定为double
      res.size:=8;
      res.Stream.SetSize(8);
      res.VarType:=ARV_Float;
      initiate_arv_float(args[ArgNumber],res);
    end;
  end;
  result:=true;
end;

function TAuf.TryArgToAddr(ArgNumber:byte;out res:pRam):boolean;
begin
  Assert(ArgNumber in [1..args_range],'ArgNumber必须在[1..args_range]范围内。');
  result:=false;
  try
    case Self.nargs[ArgNumber].pre of
      '&"':res:=RawStrToPRam(Self.nargs[ArgNumber].arg);
      else res:=Self.Script.TryToDword(Self.nargs[ArgNumber])+Self.Script.PSW.run_parameter.current_line_number;
    end;
  except
    Script.send_error('警告：第'+IntToStr(ArgNumber)+'个参数不能转化绝对地址，代码未执行。');exit
  end;
  result:=true;
end;
function TAuf.TryArgToObject(ArgNumber:byte;ObjectClass:TClass;out obj:TObject):boolean;
var arv:TAufRamVar;
begin
  result:=false;
  if not TryArgToARV(ArgNumber,8,8,[ARV_FixNum],arv) then exit;
  obj:=arv_to_obj(arv);
  if not (obj is ObjectClass) then begin
    Script.send_error('警告：第'+IntToStr(ArgNumber)+'个参数无法对应'+ObjectClass.ClassName+'实例，代码未执行。');
    exit;
  end;
  result:=true;
end;
function TAuf.TryArgToAufArray(ArgNumber:byte;out arr:TAufArray):boolean;
var tmpBase:TAufBase;
begin
  try
    tmpBase:=AufArrayParser(args[ArgNumber]);
    if tmpBase is TAufArray then begin
      arr:=tmpBase as TAufArray;
      result:=true;
    end else begin
      arr:=nil;
      result:=false;
      Script.send_error('警告：第'+IntToStr(ArgNumber)+'个参数无法正确解析为TAufArray实例，代码未执行。');
    end;
  except
    arr:=nil;
    result:=false;
    Script.send_error('警告：第'+IntToStr(ArgNumber)+'个参数无法正确解析为TAufArray实例，代码未执行。');
  end;
end;
function TAuf.TellArgType(ArgNumber:byte):TAufRamVarType;
begin
  case nargs[ArgNumber].pre of
    '$','$"','$&"':result:=ARV_FixNum;
    '~','~"','~&"':result:=ARV_Float;
    '#','#"','#&"':result:=ARV_Char;
    else result:=ARV_Raw;
  end;
end;
function TAuf.RangeCheck(target,min,max:int64):boolean;
begin
  if (target>max) or (target<min) then begin
    Script.send_error('警告：参数应在'+IntToStr(min)+'至'+IntToStr(max)+'范围内，代码未执行。');
    result:=false
  end else result:=true;
end;

constructor TAuf.Create(AOwner:TComponent=nil);
var i:byte;
begin
  inherited Create;
  Self.Script:=TAufScript.Create(AOwner);
  Self.Script.Auf:=Self;
  Self.Owner:=AOwner;
  for i:=0 to args_range-1 do Self.args[i]:='';
end;

//Usf Methods
function TUsf.zeroplus(num:word;bit:byte):ansistring;inline;//将数字转成bit位字符串，前补零
var tmp:ansistring;
begin
  str(num,tmp);
  while length(tmp)<bit do tmp:='0'+tmp;
  result:=tmp;
end;
function TUsf.blankplus(len:byte):ansistring;inline;//生成指定长度的空格串
var i:byte;
begin
  result:='';
  for i:=1 to len do result:=result+' ';
end;
function TUsf.fullblankplus(len:byte):ansistring;inline;//生成指定长度的全角空格串
var i:byte;
begin
  result:='';
  for i:=1 to len do result:=result+'　';
end;
function TUsf.left_adjust(str:string;len:byte;block:byte=8):string;
begin
  result:=str;
  while (length(result)<len)or(length(result) mod block<>0) do result:=result+' ';
end;
function TUsf.right_adjust(str:string;len:byte;block:byte=8):string;
begin
  result:=str;
  while (length(result)<len)or(length(result) mod block<>0) do result:=' '+result;
end;
function TUsf.to_s(num:double):ansistring;inline;
var tmp:ansistring;
begin
  str(num,tmp);
  result:=tmp;
end;
function TUsf.f_to_s(num:double;n:byte):ansistring;inline;
var tmp,temp:ansistring;
    i:int64;
begin
  i:=round(num * exp(ln(10)*n));
  str(i,tmp);
  temp:=tmp;
  delete(temp,length(temp)-n+1,999);
  delete(tmp,1,length(tmp)-n);
  if temp='' then temp:='0';
  result:=temp+'.'+tmp;
end;
function TUsf.i_to_s(i:int64):ansistring;inline;
var tmp:ansistring;
begin
  str(i,tmp);
  result:=tmp;
end;
function TUsf.to_i(str:ansistring):int64;inline;
var codee:byte;
    tmp:int64;
begin
  val(str,tmp,codee);
  if codee=0 then result:=tmp
  else result:=0;
end;

function TUsf.to_f(str:ansistring):double;inline;
var codee:byte;
    tmp:double;
begin
  val(str,tmp,codee);
  if codee=0 then result:=tmp
  else result:=0;
end;

function TUsf.to_hex(inp:qword;len:byte):ansistring;
var tmp{$ifndef cpu64},tlen{$endif}:qword;
begin
  tmp:=inp;
  result:='';
  repeat
    result:=chr(48+(tmp mod 16))+result;
    tmp:=tmp shr 4;
  until length(result)>=len;
  {$ifdef cpu64}
  for tmp:=1 to length(result) do if result[tmp] in [#58..#63] then result[tmp]:=chr(ord(result[tmp])+7);
  {$else}
  tlen:=length(result);
  tmp:=1;
  while tmp<=tlen do begin
    if result[tmp] in [#58..#63] then result[tmp]:=chr(ord(result[tmp])+7);
    inc(tmp);
  end;
  {$endif}
end;

function TUsf.to_binary(inp:qword;len:byte):ansistring;
var tmp:qword;
begin
  tmp:=inp;
  result:='';
  repeat
    result:=chr(48+(tmp mod 2))+result;
    tmp:=tmp shr 1;
  until length(result)>=len;
end;


procedure TUsf.reg_add(_key,_var,_data:string);//写入注册表项目
    var ps:string;
        Reg:TregisTry;
    begin
      ps:=_key;
      while pos('\',ps)>0 do delete(ps,pos('\',ps),999);
      Reg:=TregisTry.Create;
      case uppercase(ps) of
        'HKCU':Reg.RootKey:=HKEY_CURRENT_USER;
        'HKCR':Reg.RootKey:=HKEY_CLASSES_ROOT;
        'HKLM':Reg.RootKey:=HKEY_LOCAL_MACHINE;
        'HKCC':Reg.RootKey:=HKEY_CURRENT_CONFIG;
        'HKU':Reg.RootKey:=HKEY_USERS;
      end;
      ps:=_key;
      delete(ps,1,4);
      if ps[1]='\' then delete(ps,1,1);
      if not Reg.KeyExists(ps) then Reg.CreateKey(ps);
      Reg.OpenKey(ps,false);
      Reg.WriteString(_var,_data);
      Reg.CloseKey;
      Reg.Destroy;
    end;
function TUsf.reg_query(_key,_var:string):string;//读取注册表项目
var ps:string;
    Reg:TregisTry;
begin
  ps:=_key;
  while pos('\',ps)>0 do delete(ps,pos('\',ps),999);
  Reg:=TregisTry.Create;
  case uppercase(ps) of
    'HKCU':Reg.RootKey:=HKEY_CURRENT_USER;
    'HKCR':Reg.RootKey:=HKEY_CLASSES_ROOT;
    'HKLM':Reg.RootKey:=HKEY_LOCAL_MACHINE;
    'HKCC':Reg.RootKey:=HKEY_CURRENT_CONFIG;
    'HKU':Reg.RootKey:=HKEY_USERS;
  end;
  ps:=_key;
  delete(ps,1,4);
  if ps[1]='\' then delete(ps,1,1);
  Reg.OpenKey(ps,false);
  result:=Reg.ReadString(_var);
  Reg.Destroy;
end;

{$ifdef WINDOWS}
procedure TUsf.each_file(path:ansistring;func_ptr:pFuncFileByte);//开始备份指定盘符，从Ucrawer搬运
var Rec:^SearchRec;
    ARec:SearchRec;
  begin
    Rec:=@ARec;
    //getmem(Rec,sizeof(Rec));
    //非文件夹
    Dos.findfirst(path+'\*.*',$2F,Rec^);
    while dosError=0 do begin
      func_ptr(path+'\'+Rec^.name);
      Dos.findnext(Rec^);
    end;
    Dos.findclose(Rec^);
    //文件夹递归
    Dos.findfirst(path+'\*',$10,Rec^);
    while dosError=0 do begin
      if (Rec^.name<>'.')and(Rec^.name<>'..') then each_file(path+'\'+Rec^.name,func_ptr);
      Dos.findnext(Rec^);
    end;
    Dos.findclose(Rec^);
    //freemem(Rec{,sizeof(Rec)});
  end;
procedure TUsf.each_file_in_folder(path:ansistring;func_ptr:pFuncFileByte);
var Rec:^SearchRec;
    ARec:SearchRec;
  begin
    Rec:=@ARec;
    //getmem(Rec,sizeof(Rec));
    //非文件夹
    Dos.findfirst(path+'\*.*',$2F,Rec^);
    while dosError=0 do begin
      func_ptr(path+'\'+Rec^.name);
      Dos.findnext(Rec^);
    end;
    Dos.findclose(Rec^);
    //freemem(Rec{,sizeof(Rec)});
  end;
{$endif}

constructor TUsf.Create;
var i:byte;
begin
  inherited Create;
end;


{ TAufScript }

function TAufScript.PtrByte(Index:pRam):pbyte;
var dv,md:byte;
begin
  result:=var_stream.Memory+index;
end;

function TAufScript.PtrLong(Index:pRam):plongint;
var dv,md:byte;
begin
  result:=var_stream.Memory+Index;
end;
function TAufScript.PtrDouble(Index:pRam):pdouble;
var dv,md:byte;
begin
  result:=var_stream.Memory+Index;
end;
function TAufScript.PtrStr(Index:pRam):pstring;deprecated;
begin
  result:=var_stream.Memory+Index;
end;
function TAufScript.PtrSubStr(Index:pRam):pstring;deprecated;
var dv,md:byte;
begin
  result:=var_stream.Memory+Index;
end;
function TAufScript.GetLine:dword;
begin
  result:=Self.PSW.stack[Self.PSW.stack_ptr].line
end;
procedure TAufScript.SetLine(l:dword);
begin
  Self.PSW.stack[Self.PSW.stack_ptr].line:=l;
end;
function TAufScript.GetByte(Index:pRam):byte;inline;
begin
  result:=PtrByte(index)^;
end;
procedure TAufScript.SetByte(Index:pRam;byt:byte);inline;
begin
  PtrByte(index)^:=byt;
end;
function TAufScript.GetLong(Index:pRam):longint;inline;
begin
  result:=PtrLong(index)^;
end;
procedure TAufScript.SetLong(Index:pRam;lng:longint);inline;
begin
  PtrLong(index)^:=lng;
end;
function TAufScript.GetDouble(Index:pRam):double;inline;
begin
  result:=PtrDouble(index)^;
end;
procedure TAufScript.SetDouble(Index:pRam;dbl:double);inline;
begin
  PtrDouble(index)^:=dbl;
end;
function TAufScript.GetStr(Index:pRam):string;inline;deprecated;
begin
  result:=PtrStr(index)^;
end;
procedure TAufScript.SetStr(Index:pRam;str:string);inline;deprecated;
begin
  PtrStr(index)^:=str;
end;
function TAufScript.GetSubStr(Index:pRam):string;inline;deprecated;
begin
  result:=PtrSubStr(index)^;
end;
procedure TAufScript.SetSubStr(Index:pRam;str:string);inline;deprecated;
begin
  PtrSubStr(index)^:=str;
end;

procedure TAufScript.SetRamOccupation(head,size:pRam;boo:boolean);
var tail,pi:pRam;
    ptr:pbyte;
begin
  tail:=head+size-1;
  for pi:=head to tail do
    begin
      ptr:=pbyte(var_occupied.Memory)+(pi div 8);
      if boo then
        ptr^:=ptr^ or ($80 shr (pi mod 8))
      else
        ptr^:=ptr^ and not($80 shr (pi mod 8));
    end;
end;

function TAufScript.GetRamOccupation(head,size:pRam):boolean;
var tail,pi:pRam;
    ptr:pbyte;
begin
  tail:=head+size-1;
  for pi:=head to tail do
    begin
      ptr:=pbyte(var_occupied.Memory)+(pi div 8);
      if ptr^ and ($80 shr (pi mod 8)) <> 0 then
        begin
          result:=true;
          exit
        end;
    end;
  result:=false;
end;

function TAufScript.FindRamVacant(size:pRam):pRam;
var pi,ps,smax:pRam;
    ptr,pmax:pbyte;
begin
  pi:=0;
  while pi<var_stream.Size-size do
    begin
      if RamOccupation[pi,size] then inc(pi,8)
      else begin result:=pi;exit end;
    end;
  result:=var_stream.Size;
end;

function TAufScript.GetArgLine:string;
var len:integer;
begin
  result:='';
  len:=(Self.Auf as TAuf).ArgsCount;
  if len=0 then exit;
  for i:=0 to len-1 do
    begin
      result:=result+' '+(Self.Auf as TAuf).args[i];
    end;
end;

function TAufScript.GetScriptLines:TStrings;
begin
  result:=Self.PSW.stack[Self.PSW.stack_ptr].script;
end;
procedure TAufScript.SetScriptLines(AScript:TStrings);
begin
  Self.PSW.stack[Self.PSW.stack_ptr].script:=AScript;
end;
function TAufScript.GetScriptName:string;
begin
  result:=Self.PSW.stack[Self.PSW.stack_ptr].scriptname;
end;
procedure TAufScript.SetScriptName(AName:string);
begin
  Self.PSW.stack[Self.PSW.stack_ptr].scriptname:=AName;
end;

function TAufScript.TmpExpRamVar(arg:Tnargs):TAufRamVar;
var codee:byte;
    value:dword;
begin
  case arg.pre of
    '@':begin result.VarType:=ARV_FixNum;result.size:=4 end;
    '~':begin result.VarType:=ARV_Float;result.size:=8 end;
    '$':begin result.VarType:=ARV_FixNum;result.size:=1 end;
  end;
  val(arg.arg,value,codee);
  if codee<>0 then begin raise EAufScriptSyntaxError.Create('没有中部');exit end;
  result.head:=pbyte(value)+pRam(Self.PSW.run_parameter.ram_zero);
  result.Is_Temporary:=false;
  result.Stream:=nil;
end;

function TAufScript.RamVar(arg:Tnargs):TAufRamVar;//将标准变量形式转化成ARV  相对地址$"@@BB|@A"  绝对地址$&"@@BB|@A"
var s_addr,s_size:string;
    is_ref:boolean;
    AAuf:TAuf;
begin
  AAuf:=Self.Auf as TAuf;
  case arg.pre of
    '$"':begin result.VarType:=ARV_FixNum;is_ref:=false end;
    '~"':begin result.VarType:=ARV_Float;is_ref:=false end;
    '#"':begin result.VarType:=ARV_Char;is_ref:=false end;
    '$&"':begin result.VarType:=ARV_FixNum;is_ref:=true end;
    '~&"':begin result.VarType:=ARV_Float;is_ref:=true end;
    '#&"':begin result.VarType:=ARV_Char;is_ref:=true end;
    '@','$','~':begin result:=TmpExpRamVar(arg);exit end;
    else begin
      //Self.send_error('未知的变量前缀："'+arg.pre+'"，无法解析为变量！');
      result.size:=0;
      exit;
    end;
  end;

  s_addr:=arg.arg;
  s_size:=arg.arg;
  delete(s_size,1,pos('|',s_size));
  delete(s_addr,pos('|',s_addr),999);
  result.size:=RawStrToPRam(s_size);
  if result.size=0 then result.size:=4;
  result.head:=pbyte(RawStrToPRam(s_addr));

  if is_ref then
    begin
      result.Head:=pbyte(pdword(result.Head+pRam(Self.PSW.run_parameter.ram_zero))^);
    end;

  {if arg.post[length(arg.post)]<>arg.pre[1] then }
  result.head:=result.head+pRam(Self.PSW.run_parameter.ram_zero);//dword() failed in deepin(linux) test

  result.Is_Temporary:=false;
  result.Stream:=nil;

end;

function TAufScript.RamVarToNargs(arv:TAufRamVar;not_offset:boolean=false):Tnargs;
begin
  result.pre:='';
  result.arg:='~illegal arv type';
  result.post:='';

  case arv.VarType of
    //ARV_Raw:;
    ARV_Char:result.pre:='#';
    ARV_FixNum:result.pre:='$';
    ARV_Float:result.pre:='~';
    else exit;
  end;

  if not_offset then result.pre:=result.pre+'&';
  result.pre:=result.pre+'"';
  result.post:='"';

  if not_offset then result.arg:=pRamToRawStr(int64(arv.Head))
  else result.arg:=pRamToRawStr(int64(arv.Head)-int64(Self.PSW.run_parameter.ram_zero));
  result.arg:=result.arg+'|'+pRamToRawStr(arv.size);
end;

function TAufScript.RamVarClipToNargs(arv:TAufRamVar;idx,len:pRam;not_offset:boolean=false):Tnargs;
var clip:TAufRamVar;
begin
  clip:=arv_clip(arv,idx,len);
  result:=RamVarToNargs(clip,not_offset);
end;

function TAufScript.SharpToDouble(sharp:Tnargs):double;
var stmp:string;
    len,poss,base,offs,dot_already:integer;
    ln_value:double;
begin
  result:=0;
  stmp:=sharp.arg;
  if stmp='' then exit;
  len:=length(stmp);
  case stmp[len] of
    'H','h':begin base:=16;delete(stmp,len,1);dec(len);end;
    'B','b':begin base:=2;delete(stmp,len,1);dec(len);end;
    '.':begin base:=10;delete(stmp,len,1);dec(len);end;
    '0'..'9':base:=10;
    //else exit;
    else raise EAufScriptSyntaxError.Create('非法浮点数字符');//原先TryArgToDouble始终不会报错
  end;
  if len=0 then exit;
  poss:=pos('.',stmp);
  if poss<=0 then offs:=0 else offs:=poss-len;
  ln_value:=ln(base);
  dot_already:=0;
  case base of
    16:
      begin
        while stmp<>'' do
          begin
            case stmp[len] of
              '0'..'9':result:=result+exp(offs*ln_value)*(ord(stmp[len])-ord('0'));
              'A'..'F':result:=result+exp(offs*ln_value)*(ord(stmp[len])+10-ord('A'));
              'a'..'f':result:=result+exp(offs*ln_value)*(ord(stmp[len])+10-ord('a'));
              '.':begin
                    dec(offs);
                    if dot_already>0 then begin result:=0;exit;end;
                    inc(dot_already);
                  end;
              //else begin result:=0;exit end;
              else raise EAufScriptSyntaxError.Create('非法浮点数字符');//原先TryArgToDouble始终不会报错
            end;
            delete(stmp,len,1);
            dec(len);
            inc(offs);
          end;
      end;
    02:
      begin
        while stmp<>'' do
          begin
            case stmp[len] of
              '1':result:=result+exp(offs*ln_value);
              '0':;
              '.':begin
                    dec(offs);
                    if dot_already>0 then begin result:=0;exit;end;
                    inc(dot_already);
                  end;
              //else begin result:=0;exit end;
              else raise EAufScriptSyntaxError.Create('非法浮点数字符');//原先TryArgToDouble始终不会报错
            end;
            delete(stmp,len,1);
            dec(len);
            inc(offs);
          end;
      end;
    else
      begin
        {let}offs:=0;
        val(stmp,result,{let}offs);
        if {let}offs<>0 then raise EAufScriptSyntaxError.Create('非法浮点数字符');//原先TryArgToDouble始终不会报错
      end;
  end;
end;
function TAufScript.SharpToDword(sharp:Tnargs):dword;
var stmp:string;
    len,let:integer;
begin
  stmp:=sharp.arg;
  len:=length(stmp);
  result:=0;
  case stmp[len] of
    'H','h':
      begin
        delete(stmp,len,1);
        while stmp<>'' do
          begin
            result:=result*16;
            case stmp[1] of
              '0'..'9':result:=result+ord(stmp[1])-ord('0');
              'A'..'F':result:=result+ord(stmp[1])+10-ord('A');
              'a'..'f':result:=result+ord(stmp[1])+10-ord('a');
              else raise EAufScriptSyntaxError.Create('SharpToDword Error: 十六进制包含非法字符');
            end;
            delete(stmp,1,1);
          end;
      end;
    'B','b':
      begin
        delete(stmp,len,1);
        while stmp<>'' do
          begin
            result:=result*2;
            case stmp[1] of
              '1':result:=result+1;
              else raise EAufScriptSyntaxError.Create('SharpToDword Error: 二进制包含非法字符');
            end;
            delete(stmp,1,1);
          end;
      end;
    else
      begin
        let:=0;
        val(stmp,result,let);
        if let<>0 then raise EAufScriptSyntaxError.Create('SharpToDword Error: 十进制包含非法字符');
      end;
  end;
end;
function TAufScript.SharpToLong(sharp:Tnargs):longint;
var stmp:string;
    len,let:integer;
begin
  stmp:=sharp.arg;
  len:=length(stmp);
  result:=0;
  case stmp[len] of
    'H','h':
      begin
        delete(stmp,len,1);
        while stmp<>'' do
          begin
            result:=result*16;
            case stmp[1] of
              '0'..'9':result:=result+ord(stmp[1])-ord('0');
              'A'..'F':result:=result+ord(stmp[1])+10-ord('A');
              'a'..'f':result:=result+ord(stmp[1])+10-ord('a');
              else raise EAufScriptSyntaxError.Create('SharpToDword Error: 十六进制包含非法字符');
            end;
            delete(stmp,1,1);
          end;
      end;
    'B','b':
      begin
        delete(stmp,len,1);
        while stmp<>'' do
          begin
            result:=result*2;
            case stmp[1] of
              '1':result:=result+1;
              else raise EAufScriptSyntaxError.Create('SharpToDword Error: 二进制包含非法字符');
            end;
            delete(stmp,1,1);
          end;
      end;
    else
      begin
        let:=0;
        val(stmp,result,let);
        if let<>0 then raise EAufScriptSyntaxError.Create('SharpToDword Error: 十进制包含非法字符');
      end;
  end;
end;
function TAufScript.SharpToString(sharp:Tnargs):string;
begin
  result:=sharp.arg;
end;

function TAufScript.TmpexpToDouble(tmpexp:Tnargs):double;deprecated;
var index,codee:byte;
begin
  val(tmpexp.arg,index,codee);
  if codee<>0 then begin
    Self.send_error('TmpexpToDouble error: @n/$n/~n index invalid');
    raise EAufScriptSyntaxError.Create('TmpexpToDouble error: @n/$n/~n index invalid');
  end;
  case tmpexp.pre of
    '@':result:=Self.vLong[index];
    '$':result:=Self.vByte[index];
    '~':result:=Self.vDouble[index];
  end;
end;
function TAufScript.TmpexpToDword(tmpexp:Tnargs):dword;deprecated;
var index,codee:byte;
begin
  val(tmpexp.arg,index,codee);
  if codee<>0 then begin
    Self.send_error('TmpexpToDword error: @n/$n/~n index invalid');
    raise EAufScriptSyntaxError.Create('TmpexpToDword error: @n/$n/~n index invalid');
  end;
  case tmpexp.pre of
    '@':result:=Self.vLong[index];
    '$':result:=Self.vByte[index];
    '~':result:=trunc(Self.vDouble[index]);
  end;
end;
function TAufScript.TmpexpToString(tmpexp:Tnargs):string;deprecated;
var index,codee:byte;
begin
  val(tmpexp.arg,index,codee);
  if codee<>0 then begin
    Self.send_error('TmpexpToString error: @n/$n/~n index invalid');
    raise EAufScriptSyntaxError.Create('TmpexpToString error: @n/$n/~n index invalid');
  end;
  case tmpexp.pre of
    '@':result:=IntToStr(Self.vLong[index]);
    '$':result:=IntToStr(Self.vByte[index]);
    '~':result:=FloatToStr(Self.vDouble[index]);
  end;
end;

function TAufScript.TryToDouble(arg:Tnargs):double;
var AAuf:TAuf;
begin
  AAuf:=Self.Auf as TAuf;
  case arg.pre of
    '~&"','~"','#&"','#"','$"','$&"':begin result:=arv_to_double(Self.RamVar(arg));exit end;
    '~','@','$':begin result:=TmpExpToDouble(arg);exit end;
    else begin result:=SharpToDouble(arg);exit end;
  end;
end;
function TAufScript.TryToDWord(arg:Tnargs):dword;
var AAuf:TAuf;
begin
  AAuf:=Self.Auf as TAuf;
  case arg.pre of
    '~&"','~"','#&"','#"','$"','$&"':begin result:=arv_to_dword(Self.RamVar(arg));exit end;
    '~','@','$':begin result:=TmpExpToDword(arg);exit end;
    else begin result:=SharpToDword(arg);exit end;
  end;
end;
function TAufScript.TryToLong(arg:Tnargs):longint;
var AAuf:TAuf;
begin
  AAuf:=Self.Auf as TAuf;
  case arg.pre of
    '~&"','~"','#&"','#"','$"','$&"':begin result:=longint(arv_to_dword(Self.RamVar(arg)));exit end;
    '~','@','$':begin result:=longint(TmpExpToDWord(arg));exit end;
    else begin result:=SharpToLong(arg);exit end;
  end;
end;
function TAufScript.TryToString(arg:Tnargs):string;
var AAuf:TAuf;
begin
  AAuf:=Self.Auf as TAuf;
  case arg.pre of
    '~&"','~"','#&"','#"','$"','$&"':begin result:=arv_to_s(Self.RamVar(arg));exit end;
    '~','@','$':begin result:=TmpExpToString(arg);exit end;
    else begin result:=SharpToString(arg);exit end;
  end;
end;

function TAufScript.Pointer(Iden:string;Index:pRam):Pointer;//这里要注意pointer类型的可变
begin
  case Iden of
    '$':result:=Self.poByte[Index];
    '@':result:=Self.poLong[Index];
    '~':result:=Self.poDouble[Index];
    '##':result:=Self.poStr[Index];
    '#':result:=Self.poSubStr[Index];
    else
      begin
        Self.send_error('警告：无效的指针类型，返回nil！');
        //result:=@(Self.var_list);
        result:=var_stream.Memory;
      end;
  end;
end;

procedure TAufScript.ram_export(filename:string);
begin
  if filename='' then filename:='ram.var';
  try
    Self.var_stream.SaveToFile(filename);
  except
    Self.send_error('警告：文件写入失败！请检查'+filename+'是否被占用。');
  end;
end;
procedure TAufScript.occupied_ram_export(filename:string);
begin
  if filename='' then filename:='ram_occupied.var';
  try
    Self.var_occupied.SaveToFile(filename);
  except
    Self.send_error('警告：文件写入失败！请检查'+filename+'是否被占用。');
  end;
end;

procedure TAufScript.arv_ram_export(arv:TAufRamVar;filename:string);
var fs:TMemoryStream;
begin
  if arv.size=0 then exit;
  if arv.Is_Temporary and not assigned(arv.Stream) then exit;
  if filename='' then filename:='ram_arv.var';
  fs:=TMemoryStream.Create;
  try
    fs.Size:=arv.size;
    fs.Position:=0;
    //fs.Write(arv.Head,arv.size);
    while fs.position<arv.Size do
      begin
        fs.WriteByte((arv.Head+fs.Position)^);
      end;
    fs.SaveToFile(filename);
  except
    Self.send_error('警告：文件写入失败！请检查'+filename+'文件是否被占用。');
    fs.Free;exit
  end;
  fs.Free;
end;
procedure TAufScript.ram_import(filename:string);
var fs:TFileStream;
    minsize:int64;
begin
  try
    fs:=TFileStream.Create(filename,fmOpenRead);
  except
    Self.send_error('警告：文件读取失败！请检查'+filename+'是否存在或被占用。');
    fs.free;exit
  end;
  //minsize:=min(fs.size,Self.var_stream.Size);
  if fs.size<Self.var_stream.Size then minsize:=fs.size else minsize:=Self.var_stream.Size;
  fs.position:=0;
  Self.var_stream.Position:=0;
  Self.var_stream.CopyFrom(fs,minsize);
  fs.Free;
end;
procedure TAufScript.arv_ram_import(arv:TAufRamVar;filename:string);
var fs:TFileStream;
    minsize:int64;
begin
  try
    fs:=TFileStream.Create(filename,fmOpenRead);
  except
    Self.send_error('警告：文件读取失败！请检查'+filename+'是否存在或被占用。');
    fs.Free;exit
  end;
  //if fs.Size<>arv.size then exit;
  //minsize:=min(fs.size,arv.Size);
  if fs.size<arv.Size then minsize:=fs.size else minsize:=arv.Size;
  fs.position:=0;
  Self.var_stream.Position:=arv.Head-pbyte(Self.var_stream.Memory);
  Self.var_stream.CopyFrom(fs,minsize);
  fs.Free;
end;

procedure TAufScript.add_func(func_name:ansistring;func_ptr:pFuncAuf;func_param,helper:string;arv_type:TClass=nil);
var i:word;
begin
  func_name:=lowercase(func_name);
  for i:=0 to func_range-1 do if Self.func[i].name='' then break;
  if (i=func_range-1) and (Self.func[i].name<>'') then begin Self.send_error('错误：函数列表已满，不能继续添加新的函数！');Self.readln;halt end;
  Self.func[i].name:=func_name;
  Self.func[i].helper:=helper;
  Self.func[i].parameter:=func_param;
  Self.func[i].func_ptr:=func_ptr;
  Self.func[i].result_type:=arv_type;
  {$ifdef SynEditMode}
  if Self.SynAufSyn<>nil then Self.SynAufSyn.InternalFunc:=Self.SynAufSyn.InternalFunc+func_name+',';
  {$endif}
end;
procedure TAufScript.run_func(func_name:ansistring);
var i:word;
    stmp:string;
begin
  func_name:=lowercase(func_name);
  if func_name='' then exit;
  stmp:=','+func_name+',';
  i:=0;
  repeat
    if pos(stmp,','+Self.func[i].name+',')>0 then
      begin
        Self.func[i].func_ptr(Self);
        exit;
      end;
    inc(i);
  until (i=func_range);
  Self.send_error('警告：未找到函数'+func_name+'！');
end;
function TAufScript.have_func(func_name:ansistring):boolean;
var i:word;
begin
  func_name:=lowercase(func_name);
  if func_name='' then exit;;
  for i:=0 to func_range-1 do if Self.func[i].name=func_name then break;
  if (i=func_range-1) and (Self.func[i].name<>func_name) then begin result:=false;exit end;
  result:=true;
end;
function TAufScript.type_func(func_name:ansistring):TClass;
var idx:word;
begin
  result:=nil;
  func_name:=lowercase(func_name);
  if func_name='' then exit;
  for idx:=0 to func_range-1 do begin
    if Self.func[idx].name=func_name then begin
      result:=Self.func[idx].result_type;
      break;
    end;
  end;
end;
procedure TAufScript.func_helper(func_name:string);
var i:word;
    shown:boolean;
begin
  shown:=false;
  func_name:=lowercase(func_name);
  for i:=0 to func_range-1 do begin
    if pos(','+func_name+',',','+Self.func[i].name+',')>0 then begin
      Self.write('函数指南：');
      Self.writeln(Usf.left_adjust(StringReplace(Self.func[i].name,',',' | ',[rfReplaceAll])+' '+Self.func[i].parameter,16)+' '+Self.func[i].helper);
      shown:=true;
      break;
    end;
  end;
  if not shown then Self.writeln('函数指南：无指定函数。');
end;
procedure TAufScript.helper;
const line_break = {$ifdef WINDOWS}#13#10{$else}#10{$endif};
var i:word;
    tmp,res:string;
    tmo:integer;
begin
  Self.writeln('函数列表:');
  res:='';
  for i:=0 to func_range-1 do begin
    if Self.func[i].name='' then break;
    tmp:=Self.func[i].name;
    //repeat
      tmo:=pos(',',tmp);
      if tmo>0 then delete(tmp,tmo,length(tmp));
    //until tmo<=0;
    res:=res+line_break+Usf.left_adjust(tmp+' '+Self.func[i].parameter,16)+' '+Usf.left_adjust(Self.func[i].helper,16);
  end;
  Self.writeln(res);
end;
procedure TAufScript.define_helper;
var i:word;
    tmp:TAufExpressionUnit;
    function boolexpr(b:boolean):string;
    begin
      if b then result:='  [R.]' else result:='  [RW]';
    end;

begin
  Self.writeln('定义列表:');
  Self.writeln('[全局]');
  i:=0;
  while i<Self.Expression.Global.Count do
    begin
      tmp:=TAufExpressionUnit(Self.Expression.Global.Items[i]);
      Self.writeln(boolexpr(tmp.readonly)+'@'+Usf.left_adjust(tmp.key,16)+' = '+tmp.value.pre+tmp.value.arg+tmp.value.post);
      inc(i);
    end;
  Self.writeln('[局部]');
  i:=0;
  while i<Self.Expression.Local.Count do
    begin
      tmp:=TAufExpressionUnit(Self.Expression.Local.Items[i]);
      Self.writeln(boolexpr(tmp.readonly)+'@'+Usf.left_adjust(tmp.key,16)+' = '+tmp.value.pre+tmp.value.arg+tmp.value.post);
      inc(i);
    end;

end;
procedure TAufScript.BeginOF(filename:string);
begin
  if PSW.print_mode.is_screen then
    begin
      PSW.print_mode.is_screen:=false;
      PSW.print_mode.target_file:=filename;
      PSW.print_mode.str_list:=TStringList.Create;
      PSW.print_mode.str_list.Add('');
    end
  else
    begin
      if filename=PSW.print_mode.target_file then exit;
      EndOF;
      BeginOF(filename);
    end;
end;
procedure TAufScript.EndOF;
begin
  if PSW.print_mode.is_screen then
    begin
      exit;
    end
  else
    begin
      try
        PSW.print_mode.str_list.SaveToFile(PSW.print_mode.target_file);
      except
        PSW.print_mode.str_list.SaveToFile('screen.log');
      end;
      PSW.print_mode.is_screen:=true;
      PSW.print_mode.target_file:='';
      PSW.print_mode.str_list.Free;
    end;
end;
procedure TAufScript.write(str:string);
begin
  if Self.IO_fptr.print<>nil then Self.IO_fptr.print(Self,str);
end;
procedure TAufScript.writeln(str:string);
begin
  if Self.IO_fptr.echo<>nil then Self.IO_fptr.echo(Self,str);
end;
procedure TAufScript.readln;
begin
  if Self.IO_fptr.pause<>nil then Self.IO_fptr.pause(Self);
end;
procedure TAufScript.send_error(str:string);
var ErrStr:string;
    OriginLine, RuntimeLine, DisplayLine:string;
begin
  //Self.writeln(''); 这个换行不受IO_fptr.error控制，换成换行符，不确定兼容性如何
  OriginLine:=Self.ScriptLines[Self.currentline];
  RuntimeLine:=Self.ArgLine;
  if OriginLine<>RuntimeLine then DisplayLine:=OriginLine+CRLF+'[Runtime Line] '+RuntimeLine else DisplayLine:=OriginLine;
  ErrStr:=CRLF+'[In "'+Self.ScriptName+'" Line ' + IntToStr(Self.CurrentLine+1)+ '] '
    +DisplayLine+CRLF+str;
  if Self.IO_fptr.error<>nil then Self.IO_fptr.error(Self,ErrStr);

  if Self.PSW.run_parameter.error_raise then begin
    if Self.Func_process.mid<>nil then Self.Func_process.mid(Self);
    if Self.Func_process.OnRaise<>nil then Self.Func_process.OnRaise(Self);
    Self.Stop;
  end;
end;
procedure TAufScript.ClearScreen;
begin
  if Self.IO_fptr.clear<>nil then Self.IO_fptr.clear(Self);
end;

procedure TAufScript.HaltOff;
begin
  Self.PSW.haltoff:=true;
end;
procedure TAufScript.PSW_reset;
var i:word;
begin
  for i:= 0 to stack_range-1 do begin
    Self.PSW.stack[i].line:=0;
    Self.PSW.stack[i].script:=nil;
    Self.PSW.stack[i].scriptname:='';
  end;
  Self.PSW.stack_ptr:=0;
  Self.PSW.haltoff:=false;
  Self.PSW.pause:=false;
  Self.PSW.inRunNext:=false;;
  Self.PSW.calc.YC:=false;
  with Self.PSW.message_stored do begin
    uuid.Head:=pbyte(0);
    uuid.size:=0;
    uuid.VarType:=ARV_Raw;
    data.Head:=pbyte(0);
    data.size:=0;
    data.VarType:=ARV_Raw;
  end;

end;

procedure TAufScript.line_transfer;//将当前行代码转译成标准形式
var i:0..args_range;
    line:dword;
    ts1,ts2,at_expr,at_num:string;
    idx1,idx2,at_len,at_ofs:integer;
    AAuf:TAuf;
    tmp_nargs:Tnargs;
begin
  AAuf:=Self.Auf as TAuf;
  for i:=0 to AAuf.ArgsCount-1 do
    begin
      case AAuf.nargs[i].pre of
        ':':
          begin
            //:loo :a :aaa
            line:=0;
            while line < Self.PSW.run_parameter.current_strings.Count-1 do
              begin
                if non_space(Self.PSW.run_parameter.current_strings.Strings[line]) = AAuf.nargs[i].arg+':' then break;
                inc(line);
              end;
            if line <> Self.PSW.run_parameter.current_strings.Count then
              begin
                AAuf.nargs[i].pre:='&"';
                AAuf.nargs[i].post:='"';
                AAuf.nargs[i].arg:=pRamToRawStr(line);
              end
            else
              begin
                //这个没用到过感觉，因为?要作为函数名，这个部分需要去除
                AAuf.nargs[i].pre:='?"';
                AAuf.nargs[i].post:='"';
                AAuf.nargs[i].arg:='~Error';
              end;
          end;
        '~','$','#':
          begin
            //$4[0] $2[64] ~8[64] ~8{0} $4{16} -> $"@@@@@@@@|@D" $"@@@@@@B@|@B" ~"@@@@@@B@|@H" ~&"@@@@@@@@|@H" $&"@@@@@@@P|@D"
            idx1:=pos('[',AAuf.nargs[i].arg);
            idx2:=pos('{',AAuf.nargs[i].arg);
            if idx1>0 then
              begin
                AAuf.nargs[i].pre:=AAuf.nargs[i].pre+'"';
                AAuf.nargs[i].post:='"';
                ts1:=AAuf.nargs[i].arg;
                ts2:=AAuf.nargs[i].arg;
                delete(ts1,idx1,9999);
                delete(ts2,1,idx1);
                if ts2[length(ts2)]=']' then delete(ts2,length(ts2),1);
                AAuf.nargs[i].arg:=pRamToRawStr(ExpToPRam(ts2))+'|'+pRamToRawStr(ExpToPRam(ts1){ mod (High(pRam)+1){256}(wth was that)});
              end
            else if idx2>0 then
              begin
                AAuf.nargs[i].pre:=AAuf.nargs[i].pre+'&"';
                AAuf.nargs[i].post:='"';
                ts1:=AAuf.nargs[i].arg;
                ts2:=AAuf.nargs[i].arg;
                delete(ts1,idx2,9999);
                delete(ts2,1,idx2);
                if ts2[length(ts2)]='}' then delete(ts2,length(ts2),1);
                AAuf.nargs[i].arg:=pRamToRawStr(ExpToPRam(ts2))+'|'+pRamToRawStr(ExpToPRam(ts1){ mod (High(pRam)+1){256}(wth was that)});
              end
            else
              begin
                //暂时保留原始的@0 ~32 $12的不带[]{}的表达
                if (AAuf.nargs[i].arg='=') and (AAuf.nargs[i].post='') then begin
                  //对于~=的特殊处理
                  AAuf.nargs[i]:=narg('','reg','');
                  AAuf.args[i]:='reg';
                end;
              end;
          end;
        '@':
          begin
            at_expr:=AAuf.nargs[i].arg;
            case at_expr[1] of
              '0'..'9':
              begin
                //计划取消TmpExp
              end;
              'a'..'z','A'..'Z','_':
              begin
                case at_expr of
                  'ram_zero':AAuf.nargs[i]:=narg('',IntToStr(pRam(Self.PSW.run_parameter.ram_zero)),'');
                  'ram_size':AAuf.nargs[i]:=narg('',IntToStr(Self.PSW.run_parameter.ram_size),'');
                  'error_raise':AAuf.nargs[i]:=narg('',BoolToStr(Self.PSW.run_parameter.error_raise),'');
                  else begin
                    if pos('line[',at_expr) = 1 then begin
                      at_num:=at_expr;
                      delete(at_num,1,5);
                      at_len:=length(at_num);
                      if (at_len<>0) and (pos(']',at_num)=at_len) then delete(at_num,at_len,1);
                      try
                        at_ofs:=StrToInt(at_num);
                      except
                        at_ofs:=0;
                      end;
                      AAuf.nargs[i]:=narg('&"',pRamToRawStr(pRam(Self.PSW.run_parameter.current_line_number+at_ofs)),'"');
                    end else begin
                      tmp_nargs:=Self.Expression.Local.Translate(at_expr);
                      if tmp_nargs.arg='~Error' then tmp_nargs:=Self.Expression.Global.Translate(at_expr);
                      if tmp_nargs.arg<>'~Error' then AAuf.nargs[i]:=tmp_nargs;
                    end;
                  end;
                end;
              end;
            end;
          end;
      end;
      AAuf.args[i]:=AAuf.nargs[i].pre+AAuf.nargs[i].arg+AAuf.nargs[i].post;
    end;
  //新增 "=/." 语法糖
  //  @rect = getrect @hwnd, @l, @t, @w, @h
  //  = getrect @rect @hwnd, @l, @t, @w, @h
  //  (根据getrect函数的result_type先创建对象)
  //  @array . pop @elem
  //  . array.pop @array @elem
  //  (根据第一个对象修改指令result_type先创建对象)
  if AAuf.ArgsCount>=3 then begin
    case AAuf.args[1] of
      '=','.':begin
        ts1:=AAuf.args[0];
        AAuf.args[0]:=AAuf.args[1];
        AAuf.args[1]:=AAuf.args[2];
        AAuf.args[2]:=ts1;
        tmp_nargs:=AAuf.nargs[0];
        AAuf.nargs[0]:=AAuf.nargs[1];
        AAuf.nargs[1]:=AAuf.nargs[2];
        AAuf.nargs[2]:=tmp_nargs;
      end;
    end;
  end;

  Self.PSW.run_parameter.current_strings.Strings[Self.PSW.run_parameter.current_line_number]:=Self.ArgLine;

end;

procedure TAufScript.next_addr;
begin
  currentline:=currentline+1;
end;
procedure TAufScript.jump_addr(line:dword);//跳转绝对地址
var pi:dword;
begin
  Self.currentline:=line-1;
end;
procedure TAufScript.offs_addr(offs:longint);//跳转偏移地址
begin
  jump_addr(Self.PSW.stack[Self.PSW.stack_ptr].line+offs);
end;
procedure TAufScript.pop_addr;
begin
  if Self.PSW.stack_ptr=0 then
    begin
      Self.send_error('错误：[-1]超出栈范围！');
      Self.PSW.haltoff:=true;
    end;
  Self.currentline:=0;
  Self.ScriptLines:=nil;
  dec(Self.PSW.stack_ptr);
  Self.PSW.run_parameter.current_strings:=Self.ScriptLines;
end;
procedure TAufScript.push_addr(Ascript:TStrings;Ascriptname:string;line:dword);
begin
  if Self.PSW.stack_ptr=stack_range-1 then
    begin
      Self.send_error('错误：['+Usf.to_s(stack_range)+']超出栈范围！');
      Self.PSW.haltoff:=true;
    end;
  inc(Self.PSW.stack_ptr);
  Self.currentline:=line;
  Self.ScriptLines:=Ascript;
  Self.ScriptName:=Ascriptname;
  Self.PSW.run_parameter.current_strings:=Self.ScriptLines;
end;
procedure TAufScript.push_addr(line:dword);
begin
  push_addr(Self.ScriptLines,Self.ScriptName,line);
end;
procedure TAufScript.push_addr_inline(Ascript:TStrings;Ascriptname:string;line:dword);//why?
begin
  if Self.PSW.stack_ptr=stack_range-1 then
    begin
      Self.send_error('错误：['+Usf.to_s(stack_range)+']超出栈范围！');
      Self.PSW.haltoff:=true;
    end;
  with Self.PSW.stack[Self.PSW.stack_ptr] do line:=line - 1;
  inc(Self.PSW.stack_ptr);
  Self.currentline:=line;
  Self.ScriptLines:=Ascript;
  Self.ScriptName:=Ascriptname;
  Self.PSW.run_parameter.current_strings:=Self.ScriptLines;
end;
procedure TAufScript.push_addr_inline(line:dword);
begin
  push_addr(Self.ScriptLines,Self.ScriptName,line);//why? 再怎么说也应该要和push_addr_inline一样吧
end;

procedure TAufScript.EnableTaskMessage;
begin
  GlobalMultiTaskList.AddTask(Self);
end;

procedure TAufScript.DisableTaskMessage;
begin
  PSW.message.Clear;
  GlobalMultiTaskList.DelTask(Self);
end;

function TAufScript.SendTaskMessage(SendTo:TAufScript;Data:TAufRamVar;Code:TMsgCode):boolean;
var tmpMI:TMsgItem;
begin
  tmpMI.From:=Self;
  tmpMI.Code:=Code;
  tmpMI.Data:=Data;
  result:=SendTo.PSW.message.Append(tmpMI);
end;

procedure TAufScript.ReadTaskMessage(var From:TAufScript; var Data:TAufRamVar; var Code:TMsgCode);
var tmpMI:TMsgItem;
begin
  From:=nil;
  if Self.PSW.message.Count=0 then exit;
  tmpMI.Data:=Data;
  tmpMI:=Self.PSW.message.Pop;
  From:=tmpMI.From;
  Code:=tmpMI.Code;
end;

function TAufScript.CountTaskMessage:integer;
begin
  result:=Self.PSW.message.Count;
end;

{$ifdef MsgTimerMode}
procedure TAufScript.send(msg:UINT);
begin
  Postmessage(Self.Control.Handle,msg,int64(@Self),0);
  //Self.Control.Perform(msg,int64(@Self),0);//这个是等同于sendmessage的同步消息，不可用
end;
{$endif}
procedure TAufScript.Pause;//人为暂停
begin
  if Self.Time.Synthesis_Mode = SynMoDelay then raise Exception.Create('命令行模式AufScript不能人为暂停或恢复');
  if Self.PSW.pause then exit;
  Self.PSW.pause:=true;
  with Self.Time do if Synthesis_Mode = SynMoTimer then begin
    {$ifdef MsgTimerMode}
    case TimerPause of
      true:Timer.Enabled:=false;
      false:;
    end;
    {$else}
    //AufThread.Suspend;
    AufThread.Priority:=tpIdle;
    {$endif}
  end;
  if Self.Func_process.OnPause<>nil then Self.Func_process.OnPause(Self);
end;
procedure TAufScript.Resume;//人为继续
begin
  if Self.Time.Synthesis_Mode = SynMoDelay then raise Exception.Create('命令行模式AufScript不能人为暂停或恢复');
  if not Self.PSW.pause then exit;
  if Self.Func_process.OnResume<>nil then Self.Func_process.OnResume(Self);
  Self.PSW.pause:=false;
  with Self.Time do if Synthesis_Mode = SynMoTimer then begin
    {$ifdef MsgTimerMode}
    case TimerPause of
      true:Timer.Enabled:=true;
      false:Self.send(AufProcessControl_RunNext);
    end;
    {$else}
    //AufThread.Resume;
    AufThread.Priority:=tpNormal;
    {$endif}
  end;
end;
procedure TAufScript.Stop;//人为中止
begin
  if Self.Time.Synthesis_Mode = SynMoDelay then raise Exception.Create('命令行模式AufScript不能人为中止');
  //if not Self.PSW.haltoff then exit;
  //if Self.PSW.pause then Self.Resume;
  {$ifdef MsgTimerMode}
  Self.send(AufProcessControl_RunClose);
  {$else}
  //AufThread.Terminate;
  Self.PSW.haltoff:=true;
  {$endif}
end;
procedure TAufScript.RunFirst;//代码执行初始化
var idx:pRam;
begin
  //Self.writeln('RunFirst');
  randomize;
  Self.Expression.Local.TryAddExp('prev_res',narg('','~uninitalized prev_res',''));

  with PSW.run_parameter do begin
    current_strings:=ScriptLines;
    SetLength(time_consuming,current_strings.Count);
    for idx:=0 to current_strings.Count-1 do time_consuming[idx]:=0;
  end;
  if PSW.print_mode.resume_when_run_close then
    begin
      PSW.print_mode.is_screen:=true;
      PSW.print_mode.target_file:='';
    end;
  if Self.Func_process.beginning<>nil then Self.Func_process.beginning(Self);//预设的开始过程
  {$ifdef MsgTimerMode}
  Self.Time.TimerPause:=false;
  {$endif}
  IF Self.Time.Synthesis_Mode = SynMoTimer THEN BEGIN
    {$ifdef MsgTimerMode}
    //使用Self.Control的消息来激活下一个过程
    Self.send(AufProcessControl_RunNext);
    {$else}
    //AufThread:=TAufScriptThread.Create(Self,false);
    AufThread.Priority:=tpNormal;
    {$endif}
    exit;
  END ELSE BEGIN
    repeat
      Self.RunNext;
    until Self.PSW.haltoff;
    Self.RunClose;
  END;
end;
procedure TAufScript.RunNext;//代码执行的循环体
var cmd:string;
    AAuf:TAuf;
    t0,t1:TDateTime;
    tc:double;
  procedure DoRunClose;
  begin
    IF Self.Time.Synthesis_Mode = SynMoTimer THEN BEGIN
      {$ifdef MsgTimerMode}
      Self.send(AufProcessControl_RunClose);
      {$else}
      Self.PSW.haltoff:=true;
      {$endif}
    END ELSE BEGIN
      Self.PSW.haltoff:=true;
    END;
  end;
  procedure DoRunNext;
  {$ifdef MsgTimerMode}
  var tmp_msg:TMsg;
  {$endif}
  begin
    IF Self.Time.Synthesis_Mode = SynMoTimer THEN BEGIN
      {$ifdef MsgTimerMode}
      //repeat until not PeekMessage(tmp_msg,Self.Control.Handle,0,0,PM_REMOVE);
      Self.send(AufProcessControl_RunNext);
      {$endif}
    END ELSE BEGIN
      //DO NOTHING
    END;
  end;

begin
  AAuf:=Self.Auf as TAuf;
  if Self.PSW.haltoff or Self.PSW.pause then exit;
  if Self.currentline < ScriptLines.count then begin
    //读取栈中地址的指令
    cmd:=ScriptLines.strings[Self.currentline];
    Self.PSW.run_parameter.current_line_number:=currentline;
    Self.PSW.run_parameter.prev_line_number:=Self.PSW.run_parameter.current_line_number-1;
    Self.PSW.run_parameter.next_line_number:=Self.PSW.run_parameter.current_line_number+1;
    if Self.Func_process.pre<>nil then Self.Func_process.pre(Self);//预设的前置过程
    Self.PSW.inRunNext:=true;//过程保护，阻挡新的RunNext消息

    //自定义函数执行部分
    AAuf.ReadArgs(cmd);
    if AAuf.args[0]<>'' then begin
    if ((AAuf.args[0][1]<>'/') or (AAuf.args[0][2]<>'/')) and (AAuf.nargs[0].arg<>'') and (AAuf.nargs[0].post<>':') then
      begin
        Self.line_transfer;//转化为标准形态
        t0:=Now();
        Self.run_func(AAuf.args[0]);
        t1:=Now();
        if (PSW.stack_ptr=0)or(PSW.stack[PSW.stack_ptr].script=PSW.stack[0].script) then begin
          //只统计最外层脚本文件，没有考虑两个脚本文件之间来回load的情况
          with PSW.run_parameter do if not PSW.haltoff then begin
            tc:=time_consuming[current_line_number];
            time_consuming[current_line_number]:=tc+double(t1)-double(t0);
          end;
        end;
      end;
    end;
    if Self.PSW.haltoff then begin DoRunClose;exit end;

    //安排下一个地址
    Self.next_addr;
    Self.PSW.inRunNext:=false;//取消过程保护，允许新的RunNext消息
    if Self.Func_process.post<>nil then Self.Func_process.post(Self);//预设的后置过程
    if (not Self.PSW.Pause){$ifdef MsgTimerMode} and (not Self.Time.TimerPause) and (not Self.Time.MultiTaskTimerPause){$endif} and (not Self.PSW.haltoff) then DoRunNext;
  end else begin
    DoRunClose;
  end;
end;
procedure TAufScript.RunClose;//代码执行中止化
begin
  Self.PSW.haltoff:=true;
  Self.PSW.pause:=false;
  SetLength(PSW.run_parameter.time_consuming,0);

  {$ifdef MsgTimerMode}
  IF Self.Time.Synthesis_Mode=SynMoTimer THEN BEGIN
    Self.Time.TimerPause:=false;
    Self.Time.Timer.Enabled:=false;
  END;
  {$endif}
  if (not PSW.print_mode.is_screen) and (PSW.print_mode.resume_when_run_close) then EndOF;
  if Self.Func_process.ending<>nil then Self.Func_process.ending(Self);//预设的结束过程
end;

function auf_thread_func(parameter:pointer):ptrint;
begin
  with TAufScript(parameter) do begin
    RunFirst;
    while not PSW.haltoff do begin
      RunNext;
    end;
    RunClose;
  end;
end;

procedure TAufScript.command(str:TStrings;_error_raise_:boolean=false);
var i:dword;
    cmd:string;
    line_tmp:dword;
begin
  if not Self.PSW.haltoff then exit;
  if str.count = 0 then begin
    if Self.Func_process.ending<>nil then Self.Func_process.ending(Self);
    exit
  end;
  Self.PSW_reset;
  Self.PSW.run_parameter.error_raise:=_error_raise_;
  Self.ScriptLines:=TStringList.Create;
  Self.ScriptLines.Clear;
  for line_tmp:=0 to str.Count - 1 do
    begin
      {tmp}cmd:=str.Strings[line_tmp];
      if IO_fptr.command_decode<>nil then IO_fptr.command_decode({tmp}cmd);
      Self.ScriptLines.Add({tmp}cmd);
    end;

  {$ifdef MsgTimerMode}
  Self.RunFirst;
  {$else}
  AufThread:=TAufScriptThread.Create(Self,false);
  {$endif}

  if Self.PSW.haltoff then Self.ScriptLines.Free;

end;
procedure TAufScript.command(str:string;_error_raise_:boolean=false);
var scpt:TStringList;
begin
  scpt:=TStringList.Create;
  scpt.add(str);
  command(scpt,_error_raise_);
  scpt.Destroy;
end;
{$ifdef MsgTimerMode}
procedure TAufScript.TimerInitialization(var AControl:TAufControl);
begin
  //if Assigned(AControl) then exit;
  if not (AControl is TAufControl) then
    raise Exception.Create('TimerInitialization需要初始化的TAufControl对象');
  Self.Control:=AControl;
  if not Assigned(Self.Time.Timer) then
    Self.Time.Timer:=TAufTimer.Create(Self.Control.Owner,Self);
  Self.Time.Synthesis_Mode:=SynMoTimer;
  Self.Time.Timer.Enabled:=false;
  if not Assigned(Self.Time.MultiTaskTimer) then
    Self.Time.MultiTaskTimer:=TAufMultiTaskTimer.Create(Self.Control.Owner,Self);
  Self.Time.MultiTaskTimer.Enabled:=false;
  Self.Control.FAuf:=Self.Auf as TAuf;
  Self.Control.FAufScpt:=Self as TAufScript;
end;
{$endif}

constructor TAufExpressionUnit.Create(AKey:string;AValue:Tnargs;AReadOnly:boolean=false);
begin
  inherited Create;
  Self.key:=AKey;
  Self.value:=AValue;
  Self.readonly:=AReadOnly;
end;
function TAufExpressionUnit.TryEdit(NewValue:Tnargs):boolean;
begin
  if Self.readonly then result:=false
  else begin
    Self.value:=NewValue;
    result:=true;
  end;
end;
function TAufExpressionList.Find(AKey:string):TAufExpressionUnit;
var tmp:TAufExpressionUnit;
    i:integer;
begin
  if Self.Count = 0 then begin result:=nil;exit end;
  i:=0;
  while i<Self.Count do
    begin
      if TAufExpressionUnit(Self.Items[i]).key=AKey then break;
      inc(i);
    end;
  if i<Self.Count then result:=TAufExpressionUnit(Self.Items[i])
  else result:=nil;
end;
function TAufExpressionList.Translate(AKey:string):Tnargs;
var tmp:TAufExpressionUnit;
begin
  tmp:=Self.Find(AKey);
  if tmp=nil then result:=narg('','~Error','')
  else result:=tmp.value;
end;
function TAufExpressionList.TryAddExp(AKey:string;AValue:Tnargs):boolean;
var tmp:TAufExpressionUnit;
begin
  tmp:=Self.Find(AKey);
  if tmp=nil then
    begin
      tmp:=TAufExpressionUnit.Create(AKey,AValue,false);
      Self.Add(tmp);
    end
  else
    begin
      if tmp.readonly then raise EAufScriptSyntaxError.Create('不能修改只读表达式')
      else tmp.value:=AValue;
    end;
end;
function TAufExpressionList.TryRenameExp(OldKey,NewKey:string):boolean;
var tmp:TAufExpressionUnit;
begin
  result:=false;
  tmp:=Self.Find(OldKey);
  if tmp=nil then begin
    raise EAufScriptSyntaxError.Create('不能给不存在的表达式更名')
  end else begin
    if tmp.readonly then raise EAufScriptSyntaxError.Create('不能修改只读表达式')
    else tmp.key:=NewKey;
  end;
  result:=true;
end;
function TAufExpressionList.TryDeleteExp(Key:string):boolean;
var tmp:TAufExpressionUnit;
begin
  result:=false;
  tmp:=Self.Find(Key);
  if tmp=nil then begin
    raise EAufScriptSyntaxError.Create('不存在指定表达式')
  end else begin
    if tmp.readonly then raise EAufScriptSyntaxError.Create('不能删除只读表达式')
    else Self.Remove(tmp);
  end;
  result:=true;
end;

{ TAufMultiTaskList }
function TAufMultiTaskList.AddTask(AufScpt:TAufscript):boolean;
var new_guid:TGUID;
begin
  result:=false;
  if not IsEqualGUID(AufScpt.PSW.message.UUID, GUID_NULL) then exit;
  if CreateGUID(new_guid) <> 0 then exit; //如果UUID没有创建成功，就不会加入TaskList
  AddObject(GUIDToString(new_guid), AufScpt);
  AufScpt.PSW.message.FUUID:=new_guid;
  result:=true;
end;

function TAufMultiTaskList.FindTask(task_id:TMsgUuid):TAufScript;
var str_guid:string;
    index:integer;
begin
  str_guid:=GUIDToString(task_id);
  if Find(str_guid, index) then result:=Objects[index] as TAufScript
  else result:=nil;
end;

function TAufMultiTaskList.DelTask(AufScpt:TAufscript):boolean;
var str_guid:string;
    index:integer;
begin
  result:=false;
  str_guid:=GUIDToString(AufScpt.PSW.message.UUID);
  if Find(str_guid, index) then begin
    Delete(index);
  end;
  AufScpt.PSW.message.FUUID:=GUID_NULL;
  result:=true;
end;

constructor TAufMultiTaskList.Create;
begin
  Inherited Create;
  Sorted:=true;
end;


{ TAufTaskMessageQueue }

function TAufTaskMessageQueue.GetQueueItem(Index:Integer):TMsgItem;
begin
  result:=FQueue[index];
end;

function TAufTaskMessageQueue.Append(Msg:TMsgItem):boolean;
begin
  result:=false;
  if FCount>=task_range then exit;
  FCount:=FCount+1;
  FFirst:=(FFirst+1) mod task_range;

  FQueue[FFirst].Code:=Msg.Code;
  FQueue[FFirst].From:=Msg.From;
  //以下两行展示了*ARV方法设计究竟有多不合理
  newARV(FQueue[FFirst].Data, Msg.Data.size);
  copyARV(Msg.Data, FQueue[FFirst].Data);
end;

function TAufTaskMessageQueue.Pop:TMsgItem;
begin
  result.From:=nil;
  if FCount<=0 then exit;
  copyARV(FQueue[FFirst].Data, result.Data);
  freeARV(FQueue[FFirst].Data);
  result.Code:=FQueue[FFirst].Code;
  result.From:=FQueue[FFirst].From;
  FFirst:=(FFirst+task_range-1) mod task_range;
  dec(FCount);
end;

procedure TAufTaskMessageQueue.Clear;
var len,idx:integer;
begin
  len:=FCount;
  idx:=FFirst;
  while len>0 do begin
    freeARV(FQueue[idx].Data);
    idx:=(idx+task_range-1) mod task_range;
  end;
  FCount:=0;
  FFirst:=0;
end;

constructor TAufTaskMessageQueue.Create;
begin
  inherited Create;
  FCount:=0;
  FFirst:=0;
end;

destructor TAufTaskMessageQueue.Destroy;
begin
  Clear;
  inherited Destroy;
end;


{$ifdef MsgTimerMode}

procedure TAufTimer.OnTimerResume(Sender:TObject);
var auf:TAufScript;
begin
  auf:=(Sender as TAufTimer).AufScript as TAufScript;
  auf.Time.TimerPause:=false;
  Self.Enabled:=false;
  auf.send(AufProcessControl_RunNext);
end;
constructor TAufTimer.Create(AOwner:TComponent;AAufScript:TObject);
begin
  inherited Create(AOwner);
  Self.AufScript:=AAufScript as TAufScript;
  Self.OnTimer:=@Self.OnTimerResume;
end;

procedure TAufMultiTaskTimer.OnTimerResume(Sender:TObject);
var auf:TAufScript;
    msgQueue:TAufTaskMessageQueue;
    tmpMsg:TMsgItem;
begin
  auf:=(Sender as TAufMultiTaskTimer).AufScript as TAufScript;
  msgQueue:=auf.PSW.message;
  if msgQueue.Count>0 then begin
    tmpMsg.Data:=auf.PSW.message_stored.data;
    tmpMsg:=msgQueue.Pop;
    initiate_arv_str(GUIDToString(tmpMsg.From.PSW.message.UUID),auf.PSW.message_stored.uuid);
    auf.Time.MultiTaskTimerPause:=false;
    Self.Enabled:=false;
    auf.send(AufProcessControl_RunNext);
  end;
end;
constructor TAufMultiTaskTimer.Create(AOwner:TComponent;AAufScript:TObject);
begin
  inherited Create(AOwner);
  Self.AufScript:=AAufScript as TAufScript;
  Self.OnTimer:=@Self.OnTimerResume;
end;

constructor TAufControl.Create(AOwner:TComponent);
begin
  if AOwner is ACBase then else raise Exception.Create('AOwner不是'+ACBase.ClassName);
  if AOwner is TCustomDesignControl then
    inherited Create(AOwner)
  else
    inherited Create(AOwner.Owner);
  //Self.Parent:=AOwner as ACBase;
end;

class function TAufControl.ClassType:String;
begin
  result:='TAufControl';
end;

//{$define ptr_flag}
procedure TAufControl.RunFirst(var Msg:TMessage);
begin
  with {$ifdef ptr_flag}PAufScript(int64(Msg.wParam))^{$else}Self.FAufScpt as TAufScript{$endif} do begin
    RunFirst;
  end;
end;
procedure TAufControl.RunNext(var Msg:TMessage);
begin
  with {$ifdef ptr_flag}PAufScript(int64(Msg.wParam))^{$else}Self.FAufScpt as TAufScript{$endif} do begin
    if PSW.inRunNext then begin
      //PostMessage(Self.Handle,Msg.msg,Msg.wParam,Msg.lParam);
      //Self.Perform(Msg.msg,Msg.wParam,Msg.lParam);
    end else RunNext;
  end;
end;
procedure TAufControl.RunClose(var Msg:TMessage);
begin
  with {$ifdef ptr_flag}PAufScript(int64(Msg.wParam))^{$else}Self.FAufScpt as TAufScript{$endif} do begin
    RunClose;
  end;
end;
{$undef ptr_flag}

{$endif}

constructor TAufScript.Create(AOwner:TComponent);
var i:pRam;
begin
  inherited Create;

  Self.Version:=AufScript_Version;
  {$ifdef SynEditMode}
  if AOwner<>nil then Self.SynAufSyn:=TSynAufSyn.Create(AOwner)
  else Self.SynAufSyn:=nil;
  {$endif}

  if AOwner=nil then
    begin
      Time.Synthesis_Mode:=SynMoDelay;
    end
  else if (AOwner is TComponent) and Assigned(AOwner) then
    begin
      Time.Synthesis_Mode:=SynMoTimer;
      {$ifdef MsgTimerMode}
      Self.Control:=TAufControl.Create{New}(AOwner);
      if AOwner is TCustomDesignControl then
        Self.Control.Parent:=AOwner as TWinControl
      else
        Self.Control.Parent:=(AOwner.Owner) as TWinControl;
      Self.TimerInitialization(Self.Control);
      {$else}
      //线程版本需要初始化吗
      {$endif}
    end
  else
    begin
      raise Exception.Create('AufScript初始化错误，异常的Owner');
    end;
  Self.Owner:=AOwner;

  IO_fptr.echo           := @de_writeln;     //默认的输出函数
  IO_fptr.print          := @de_write;       //默认的不换行输出函数
  IO_fptr.error          := @de_writeln;     //默认的错误报告函数
  IO_fptr.pause          := @de_readln;      //默认的确认函数
  IO_fptr.clear          := @de_clearscreen; //默认的清屏函数
  IO_fptr.command_decode := @de_decoder;     //默认的转码函数

  Func_process.pre       := nil;             //默认的前驱过程
  Func_process.post      := nil;             //默认的后驱过程
  Func_process.mid       := nil;             //默认的防假死过程
  Func_process.beginning := nil;             //默认的开始过程
  Func_process.ending    := nil;             //默认的结束过程
  Func_process.OnPause   := nil;             //默认的挂起过程
  Func_process.OnResume  := nil;             //默认的恢复过程
  Func_process.OnRaise   := nil;             //默认的报错退出过程
  Func_process.Setting   := nil;             //默认的set语句


  var_stream:=TMemoryStream.Create;
  var_stream.SetSize(RAM_RANGE*256);
  var_occupied:=TMemoryStream.Create;
  var_occupied.SetSize(RAM_RANGE*32);
  var_occupied.Position:=0;
  for i:=0 to RAM_RANGE*32-1 do var_occupied.WriteByte(0);
  PSW.run_parameter.ram_zero:=var_stream.Memory;
  PSW.run_parameter.ram_size:=RAM_RANGE*256;
  PSW.run_parameter.error_raise:=false;
  PSW.haltoff:=true;
  PSW.print_mode.resume_when_run_close:=false;
  PSW.print_mode.is_screen:=true;
  PSW.message:=TAufTaskMessageQueue.Create;
  PSW.message.FUUID:=GUID_NULL;


  Expression.Global:=GlobalExpressionList;
  Expression.Local:=TAufExpressionList.Create;

  FSVOKernel:=TAufKernel.Create;

  for i:=0 to func_range-1 do Self.func[i].name:='';
end;

destructor TAufScript.Destroy;
begin
  var_stream.Free;
  var_occupied.Free;
  Expression.Local.Free;
  PSW.message.Free;
  FSVOKernel.Free;
  inherited Destroy;
end;

procedure TAufScript.InternalFuncDefine;
begin
  Self.add_func('version',   @_version,   '',               '显示解释器版本号');
  Self.add_func('help',      @_helper,    '',               '显示帮助');
  Self.add_func('deflist',   @_define_helper,       '',     '显示定义列表');
  Self.add_func('ramex',     @ramex,      '-option/arv,filename',     '将内存导出到ram.var');
  Self.add_func('ramim',     @ramim,      'filename [,var [,-f]]',    '从文件中载入数据到内存');
  Self.add_func('tmcsm',     @time_consuming_log,   '',     '耗时分析报告（需跟随代码执行，单独执行无效）');
  Self.add_func('sleep',     @_sleep,     'n',              '等待n毫秒');
  Self.add_func('pause',     @_pause,     '',               '暂停');
  Self.add_func('beep',      @_beep,      'freq,dura',      '以freq的频率蜂鸣dura毫秒');
  Self.add_func('cmd,shell', @_cmd,       'command',        '调用命令提示行');

  Self.add_func('hex,hexln', @hex,        'var',            '输出标准变量形式的十六进制,后加"ln"则换行');
  Self.add_func('bin,binln', @binary,     'var',            '输出标准变量形式的二进制,后加"ln"则换行');
  Self.add_func('print,println',  @print, 'var',            '输出变量var,后加"ln"则换行');
  Self.add_func('echo,echoln',    @echo,  'expr',           '解析表达式,后加"ln"则换行');
  Self.add_func('inspect',   @inspect,    'expr',           '检视表达式的值');
  Self.add_func('cwln',      @cwln,       '',               '换行');
  Self.add_func('clear',     @_clear,     '',               '清屏');
  Self.add_func('of',        @_of,        '[filename]',     '改为输出到文件');
  Self.add_func('os',        @_os,        '',               '改为输出到屏幕，同时保存已经输出到文件的内容');

  Self.add_func('mov',       @mov,        'v1,v2',          '将v2值赋值给v1');
  Self.add_func('add',       @add,        'v1,v2',          '将v1和v2的值相加并返回给v1');
  Self.add_func('sub',       @sub,        'v1,v2',          '将v1和v2的值相减并返回给v1');
  Self.add_func('mul',       @mul,        'v1,v2',          '将v1和v2的值相乘并返回给v1');
  Self.add_func('div',       @div_,       'v1,v2',          '将v1和v2的值相除并返回给v1');
  Self.add_func('mod',       @mod_,       'v1,v2',          '将v1和v2的值求余并返回给v1');
  Self.add_func('rand',      @rand,       'v1,v2',          '将不大于v2的随机整数返回给v1');
  Self.add_func('swap',      @_swap,      'v1',             '将v1字节倒序');
  Self.add_func('fill',      @_fillbyte,  'var,byte',       '用byte填充var');
  Self.add_func('getbytes',  @_getbytes,  'mem,seg,idx',    '从mem中读取值片段');
  Self.add_func('setbytes',  @_setbytes,  'mem,seg,idx',    '向mem中覆盖值片段');



  Self.add_func('loop',      @_loop,      ':label/ofs,times[,st]',  '简易循环times次');
  Self.add_func('jmp',       @jmp,        ':label/ofs',             '跳转到相对地址');
  Self.add_func('call',      @call,       ':lable/ofs',             '跳转到相对地址，并将当前地址压栈');
  Self.add_func('ret',       @_ret,       '',                       '从栈中取出一个地址，并跳转至该地址');
  Self.add_func('load',      @_load,      'filename',               '加载运行指定脚本文件');
  Self.add_func('fend',      @_fend,      '',                       '从加载的脚本文件中跳出');
  Self.add_func('halt',      @_halt,      '',                       '无条件结束');
  Self.add_func('end',       @_end,       '',                       '有条件结束，根据运行状态转译为ret, fend或halt');

  Self.add_func('if',        @_if,        'v1 sign v2 jmp/call/load :label/ofs/fname',  '满足条件则执行条件之后的指令');
  Self.add_func('else',      @nop,        '',                                           '仅跟随在if之后，单行首位执行无效');

  Self.add_func('cje,cjec,ncje,ncjec',@cj,'v1,v2,:label/ofs',       '如果v1等于v2则跳转,前加"n"表示否定,后加"c"表示压栈调用');
  Self.add_func('cjm,cjmc,ncjm,ncjmc',@cj,'v1,v2,:label/ofs',       '如果v1大于v2则跳转,前加"n"表示否定,后加"c"表示压栈调用');
  Self.add_func('cjl,cjlc,ncjl,ncjlc',@cj,'v1,v2,:label/ofs',       '如果v1小于v2则跳转,前加"n"表示否定,后加"c"表示压栈调用');

  Self.add_func('cjs,cjsc,ncjs,ncjsc',@cj,'s1,s2,:label/ofs',       '如果s1相等s2则跳转,前加"n"表示否定,后加"c"表示压栈调用');
  Self.add_func('cjsub,cjsubc,ncjsub,ncjsubc',     @cj,'sub,str,:label/ofs',         '如果str包含sub则跳转,前加"n"表示否定,后加"c"表示压栈调用');
  Self.add_func('cjsreg,cjsregc,ncjsreg,ncjsregc', @cj,'reg,str,:label/ofs',         '如果str符合reg则跳转,前加"n"表示否定,后加"c"表示压栈调用');

  Self.add_func('taichi',    @taichi_call,'value,chaos_width,chaos_addr[,addr ...]', '根据value的值跳转到相应的地址，并将当前地址压栈，可用于RGB九色划分');

  Self.add_func('define',    @_define,    'name,expr',              '定义一个以@开头的局部宏定义');
  Self.add_func('rendef',    @_rendef,    'old,new',                '修改一个局部宏定义的名称');
  Self.add_func('deldef',    @_deldef,    'name',                   '删除一个局部宏定义的名称');
  Self.add_func('ifdef',     @_ifdef,     'name',                   '如果有定义则跳转');
  Self.add_func('ifndef',    @_ifndef,    'name',                   '如果没有定义则跳转');
  Self.add_func('var',       @_var,       'type,name,size',         '创建一个ARV变量');
  Self.add_func('unvar',     @_unvar,     'name',                   '释放一个ARV变量');

  Self.add_func('pshl',     @ptr_shift_or_offset,   '@var, byte',  '定义指针左位移byte个字节');
  Self.add_func('pshr',     @ptr_shift_or_offset,   '@var, byte',  '定义指针右位移byte个字节');
  Self.add_func('pofl',     @ptr_shift_or_offset,   '@var, n',     '以定义指针宽度为基准向左偏移n个单位');
  Self.add_func('pofr',     @ptr_shift_or_offset,   '@var, n',     '以定义指针宽度为基准向右偏移n个单位');
  Self.add_func('pexl',     @ptr_shift_or_offset,   '@var, byte',  '定义指针向左拓展byte个字节');
  Self.add_func('pexr',     @ptr_shift_or_offset,   '@var, byte',  '定义指针向右拓展byte个字节');
  Self.add_func('pcpl',     @ptr_shift_or_offset,   '@var, byte',  '定义指针向左压缩byte个字节');
  Self.add_func('pcpr',     @ptr_shift_or_offset,   '@var, byte',  '定义指针向右压缩byte个字节');

  Self.add_func('=',        @_syntax_assign,        'method, result',   '赋值语法糖');
  Self.add_func('.',        @_syntax_property,      'method, subject',  '成员语法糖');


  AdditionFuncDefine_Task;
  AdditionFuncDefine_Text;
  AdditionFuncDefine_Time;
  AdditionFuncDefine_File;
  AdditionFuncDefine_Math;
  AdditionFuncDefine_AufBase;
  AdditionFuncDefine_Image;
  AdditionFuncDefine_SVO;
end;

procedure TAufScript.AdditionFuncDefine_Task;
begin
  Self.add_func('task.enable',    @task_enable,        '@var',          '开始多任务协同，并将当前TaskID返回给var');
  Self.add_func('task.disable',   @task_disable,       '',              '结束多任务协同，并将当前TaskID置空');
  Self.add_func('task.list',      @task_list,          '',              '调试查看多任务协同消息队列');
  Self.add_func('task.send',      @task_send,          'taskId, @var',  '向其他任务发送协同消息');
  Self.add_func('task.read',      @task_read,          'taskId, @var',  '直接读取跨任务协同消息');
  Self.add_func('task.broadcast', @task_broadcast,     '@var',          '向其他任务发送协同消息');
  Self.add_func('task.wait,wjmc', @task_wait,          'taskId, @var, :addr',   '等待读取一个跨任务协同消息后压栈跳转');

end;
procedure TAufScript.AdditionFuncDefine_Text;
begin
  Self.add_func('str',       @text_str,              '#[],var',       '将var转化成字符串存入#[]');
  Self.add_func('val',       @text_val,              '$[],str',       '将str转化成数值存入$[]');
  Self.add_func('srp',       @text_strReplace,       '#[],old,new',   '将#[]中的old替换成new');
  Self.add_func('mid',       @text_strMid,           '#[],pos,len',   '将#[]从pos处截取len位字符');
  Self.add_func('cat',       @text_strCat,           '#[],str[,-r]',  '将str加在#[]的末尾或开头(-r)');
  Self.add_func('enum',      @text_strEnumerate,     '#[],str[,st]',  '将str的其中一位按执行次数依次赋值给#[]');
  Self.add_func('fmt',       @text_strFormat,        '#[],s1[, ...]', '从第2个参数起，连接成字符串赋值给#[]');

end;
procedure TAufScript.AdditionFuncDefine_Time;
begin
  Self.add_func('gettimestr',@time_gettimestr,       'var[,-d|-f]',   '显示当前时间字符串或存入字符变量var中，-d为默认显示格式，-f表示符合文件名规则，参数大写则同时输出日期');
  Self.add_func('getdatestr',@time_getdatestr,       'var[,-d|-f]',   '显示当前日期字符串或存入字符变量var中，-d为默认显示格式，-f表示符合文件名规则，参数大写则同时输出时间');

  Self.add_func('settimer',  @time_settimer,         '',              '初始化计时器');
  Self.add_func('gettimer',  @time_gettimer,         'var',           '获取计时器度数');
  Self.add_func('waittimer', @time_waittimer,        'var',           '等待计时器达到var');

end;
procedure TAufScript.AdditionFuncDefine_File;
begin
  Self.add_func('file.exist?', @file_exist,  'addr,filename,mode',   '如果存在文件filename则跳转至addr，mode="[N][C]"');
  Self.add_func('file.read',   @file_read,   'var,filename',         '读取文件并保存至var');
  Self.add_func('file.write',  @file_write,  'var,filename',         '将var保存至文件');
  Self.add_func('file.list',   @file_list,   'array,path,filter',    '遍历路径中的每一个文件(filter为过滤器)，文件名赋值给数组@array', TAufArray);

end;
procedure TAufScript.AdditionFuncDefine_Math;
begin
  //Self.add_func('ln',@math_ln,'var','自然对数');
  //Self.add_func('exp',@math_exp,'var','指数函数');
  //Self.add_func('sqrt',@math_sqrt,'var[,index=2]','开方');
  //Self.add_func('pow',@math_pow,'var[,index=2]','幂运算');

  Self.add_func('cmp',         @math_logic_cmp,      'v1,v2,out',               '比较');
  Self.add_func('shl',         @math_logic_shl,      'var,bit',                 '左移');
  Self.add_func('shr',         @math_logic_shr,      'var,bit',                 '右移');
  Self.add_func('not',         @math_logic_not,      'var',                     '位非');
  Self.add_func('and',         @math_logic_and,      'v1,v2',                   '位与');
  Self.add_func('or',          @math_logic_or,       'v1,v2',                   '位或');
  Self.add_func('xor',         @math_logic_xor,      'v1,v2',                   '异或');
  Self.add_func('ofs',         @math_logic_offset_count, 'v1,v2,threshold,out', '差值位计数');

  {
  Self.add_func('h_add',@math_h_arithmetic,'#[],#[]','高精加');
  Self.add_func('h_sub',@math_h_arithmetic,'#[],#[]','高精减');
  Self.add_func('h_mul',@math_h_arithmetic,'#[],#[]','高精乘');
  Self.add_func('h_div',@math_h_arithmetic,'#[],#[]','高精整除');
  Self.add_func('h_mod',@math_h_arithmetic,'#[],#[]','高精求余');
  Self.add_func('h_divreal',@math_h_arithmetic,'#[],#[]','高精实数除');
  }
  Self.add_func('h_add',       @math_hr_arithmetic,  '#[],#[]',                 '高精加');
  Self.add_func('h_sub',       @math_hr_arithmetic,  '#[],#[]',                 '高精减');
  Self.add_func('h_mul',       @math_hr_arithmetic,  '#[],#[]',                 '高精乘');
  //Self.add_func('h_div',@math_hr_arithmetic,'#[],#[]      ','高精整除');
  //Self.add_func('h_mod',@math_hr_arithmetic,'#[],#[]      ','高精求余');
  Self.add_func('h_divreal',   @math_hr_arithmetic,  '#[],#[]',                 '高精实数除');



end;

procedure TAufScript.AdditionFuncDefine_AufBase;
begin


  Self.add_func('array.new',          @array_newArray,         'arr',           '创建array',        TAufArray);
  Self.add_func('array.del',          @array_delArray,         'arr',           '删除array');
  Self.add_func('array.copy',         @array_copyArray,        'dst,src',       '复制src数组到dst', TAufArray);
  Self.add_func('array.freeall',      @array_ClearArrayList,   '',              '清除所有array');

  Self.add_func('array.insert',       @array_Insert,           'arr,element[,index]',  '在arr数组的index处插入element');
  Self.add_func('array.delete',       @array_Delete,           'arr,index[,element]',  '返回arr数组在index处的元素并从数组中移除');
  Self.add_func('array.reinsert',     @array_Reinsert,         'arr,element',   '在arr数组中随机插入element');
  Self.add_func('array.draw',         @array_Draw,             'arr[,element]', '从arr数组中随机抽取元素并从数组中移除');
  Self.add_func('array.clear',        @array_Clear,            'arr',           '清空arr数组');
  Self.add_func('array.count',        @array_Count,            'arr,out',       '返回arr数组的元素数量');
  Self.add_func('array.valid?',       @array_CheckElement,     'arr, :label',   '如果arr数组中有元素则跳转');
  Self.add_func('array.empty?',       @array_CheckElement,     'arr, :label',   '如果arr数组中无元素则跳转');
  Self.add_func('array.valid?c',      @array_CheckElement,     'arr, :label',   '如果arr数组中有元素则跳转，并压栈');
  Self.add_func('array.empty?c',      @array_CheckElement,     'arr, :label',   '如果arr数组中无元素则跳转，并压栈');

  Self.add_func('array.print,array.println',  @array_Print,    'arr',           '在屏幕中打印arr数组');

end;

procedure TAufScript.AdditionFuncDefine_Image;
begin
  Self.add_func('img.new',            @img_newImage,           'img',           '创建image');
  Self.add_func('img.del',            @img_delImage,           'img',           '删除image');
  Self.add_func('img.copy',           @img_copyImage,          'dst,src',       '复制src图像到dst');
  Self.add_func('img.save',           @img_saveImage,          'img,filename[,-e|-r|-f]',  '保存image到filename，-e表示重名报错，-f表示覆盖写入，-r表示修改命名写入');
  Self.add_func('img.load',           @img_loadImage,          'img,filename',             '从filename导入image');

  Self.add_func('img.clip',           @img_clipImage,          'img,x,y,w,h',              '裁切img图像');
  Self.add_func('img.trml',           @img_clipImage,          'img,width[,-sub]',         '裁切image图像左侧使宽度为width，加-sub表示裁剪特定像素宽度');
  Self.add_func('img.trmr',           @img_clipImage,          'img,width[,-sub]',         '裁切image图像右侧使宽度为width，加-sub表示裁剪特定像素宽度');
  Self.add_func('img.trmt',           @img_clipImage,          'img,height[,-sub]',        '裁切image图像上部使宽度为height，加-sub表示裁剪特定像素宽度');
  Self.add_func('img.trmb',           @img_clipImage,'         img,height[,-sub]',         '裁切image图像下部使宽度为height，加-sub表示裁剪特定像素宽度');

  Self.add_func('img.width',          @img_getImageValue,      'img,result',               '返回img图像的宽到result');
  Self.add_func('img.height',         @img_getImageValue,      'img,result',               '返回img图像的高到result');
  Self.add_func('img.color',          @img_getImageAverageColor,  'img,result',            '返回img图像的平均颜色(BGRa)');
  Self.add_func('img.pixelformat',    @img_getImagePixelFormat,   'img,result',            '返回img图像的像素类型');

  Self.add_func('img.cje,img.cjec,img.ncje,img.ncjec',  @img_cj,  'img1,img2,:label/ofs',  '如果两个图像相同则跳转,前加"n"表示否定,后加"c"表示压栈调用');


  Self.add_func('img.freeall',        @img_clearImageList,     '',                         '清除所有image');

  Self.add_func('img.addln',          @img_AddByLine,          'img1,img2[,pw[,bm]]',      '两个图像按照行拼接，拼接需满足边缘pw行像素重合(pw默认值为10)，最大回溯查找bm段(bm默认值为0)');
  Self.add_func('img.vsegln',         @img_VoidSegmentByLine,  'img,min,tor,basename',     '按行分割图像，min为最小像素高度，tor为最大行颜色差值，basename为原始存储文件名称');

end;

procedure TAufScript.AdditionFuncDefine_SVO;
begin
  Self.add_func('svo',@svo_load,'svo_script','运行svo指令');
end;

//////Class Methods end

INITIALIZATION

  Auf:=TAuf.Create(nil);
  Auf.Script.InternalFuncDefine;
  GlobalExpressionList:=TAufExpressionList.Create;
  //这个是共用的，所有AufScript.Expression.Global都应该赋值这个
  GlobalExpressionList.TryAddExp('AufScriptAuthor',narg('"','Apiglio&Apemiro','"'));
  GlobalExpressionList.TryAddExp('AufScriptVersion',narg('"',AufScript_Version,'"'));
  TAufExpressionUnit(GlobalExpressionList.Items[0]).readonly:=true;
  TAufExpressionUnit(GlobalExpressionList.Items[1]).readonly:=true;
  GlobalMultiTaskList:=TAufMultiTaskList.Create;
  RegCalc:=TRegExpr.Create;


  Usf:=TUsf.Create;





  //RegisterTest(TAuf);

FINALIZATION

  Usf.Free;
  RegCalc.Free;
  GlobalExpressionList.Free;
  GlobalMultiTaskList.Free;
  Auf.Free;

END.

