UNIT Apiglio_Useful;

{$mode objfpc}{$H+}
{$goto on}
{$M+}
{$TypedAddress off}

{$define command_detach}//这个模式太古老了，恐怕不能用了

//{$define TEST_MODE}//开启这个模式会导致没有命令行的GUI报错

INTERFACE

uses
  Windows, Classes, SysUtils, Registry, Dos, WinCrt, FileUtil, Forms, Controls, StdCtrls, ExtCtrls,
  Interfaces, SynEdit, LazUTF8, Auf_Ram_Var, SynHighlighterAuf;

const

  AufScript_Version='beta 1.0';

  c_divi=[' ',','];//隔断符号
  c_iden=['~','@','$','#','?',':','&'];//变量符号，前后缀符号
  c_toto=c_divi+c_iden;
  ram_range=4096{32};//变量区大小
  stack_range=32;//行数堆栈区大小，最多支持256个
  func_range=256;//函数区大小，最多支持65536个
  args_range=16;//函数参数最大数量

  AufProcessControl_RunFirst = WM_USER + 19950;
  AufProcessControl_RunNext = WM_USER + 19951;
  AufProcessControl_RunClose = WM_USER + 19952;

type

  pRam = Dword;//内存编号

  {Usf  工具库}
  pFuncFileByte= procedure(str:string);
  TUsf= class
    private
      str_buffer:string;//ExPChar使用的全局变量
    public
      FileByte:array[0..255]of record
        fptr:file of byte;
        name:string;
        fready:boolean;//是否处在打开状态
      end;
    published
      function ExPChar(str:string):Pchar;
      function zeroplus(num:word;bit:byte):ansistring;inline;
      function blankplus(len:byte):ansistring;inline;
      function fullblankplus(len:byte):ansistring;inline;
      function left_adjust(str:string;len:byte):string;
      function right_adjust(str:string;len:byte):string;
      function to_s(num:double):ansistring;inline;
      function f_to_s(num:double;n:byte):ansistring;inline;
      function i_to_s(i:int64):ansistring;inline;
      function to_i(str:ansistring):int64;inline;
      function to_f(str:ansistring):double;inline;

      function to_hex(inp:qword;len:byte):ansistring;
      function to_binary(inp:qword;len:byte):ansistring;

      procedure reg_add(_key,_var,_data:string);
      function reg_query(_key,_var:string):string;
      procedure each_file(path:ansistring;func_ptr:pFuncFileByte);//查找路径下所有文件，并将目标字符串作为函数自变量运行func_ptr，例如Usf.each_file('F:\Temp',@writeln)
      procedure each_file_in_folder(path:ansistring;func_ptr:pFuncFileByte);//查找文件夹中所有文件，并将目标字符串作为函数自变量运行func_ptr

      function fsel(address:string):byte;
      procedure fassign(address:string;fid:byte);overload;
      procedure fcreate(fid:byte);overload;
      procedure freset(fid:byte);overload;
      procedure fwriteb(fid:byte;seeking:dword;byt:byte);overload;
      procedure freadb(fid:byte;seeking:dword;var byt:byte);overload;
      procedure fwrites(fid:byte;seeking:dword;str:string);overload;
      procedure freads(fid:byte;seeking:dword;len:byte;var str:string);overload;
      procedure fclose(fid:byte);overload;
      //automatical procedure needing filename only.
      procedure fassign(address:string);overload;
      procedure fcreate(address:string);inline;overload;
      procedure freset(address:string);inline;overload;
      procedure fwriteb(address:string;seeking:dword;byt:byte);overload;
      procedure freadb(address:string;seeking:dword;var byt:byte);overload;
      procedure fwrites(address:string;seeking:dword;str:string);overload;
      procedure freads(address:string;seeking:dword;len:byte;var str:string);overload;
      procedure fclose(address:string);overload;

    public
      constructor Create;
  end;

  Tnargs=record //新的参数记录方式，新的Args[],记得开始使用
    arg:string;
    pre,post:string[8];
  end;

  TAufTimer=class(TTimer)
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
  end;


  //用于AufScript的内存读取和计算

  {TAufScript}
  pFunc      = procedure;
  pFuncStr   = procedure(str:string);
  pFuncVarStr= procedure(var str:string);
  pFuncAuf   = procedure(Sender:TObject);
  pFuncAufStr= procedure(Sender:TObject;str:string);
  PAufScript = ^TAufScript;

  TAufScript = class
    protected
      var_stream:TMemoryStream;
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

    public
      Control:TAufControl;
      Owner:TComponent;//用于附着在窗体上，与Auf相同
      Auf:TObject;
      SynAufSyn:TSynAufSyn;

    public //关于执行时间的一些定义
      Time:record
        Timer:TTimer;
        TimerPause:boolean;
        Synthesis_Mode:(SynMoDelay=0,SynMoTimer=1);
      end;
      procedure TimerInitialization(var AControl:TAufControl);
      procedure send(msg:UINT);

    public
      PSW:record
        stack:array[0..stack_range-1]of record
          line:dword;
          //当前行数，在读指令阶段是当前指令，指令结束阶段就是下一个要读的行
          script:TStrings;
          scriptname:string;
        end;
        stack_ptr:byte;
        //PSW.stack[stack_ptr].line就是next_line,就是属性中的CurrentLine

        haltoff,pause:boolean;
        inRunNext:boolean;//仅在SynMoTimer模式下使用，表示是否正在执行RunNext
        run_parameter:record
          current_line_number:word;//当前行号
          next_line_number:word;//下一行
          prev_line_number:word;//上一行
          current_strings:TStrings;//当前代码所在TStrings
          ram_zero:pbyte;//内存零点
          ram_size:pRam;//内存大小
          error_raise:boolean;//报错是否直接退出
        end;
        calc:record
          YC:boolean;//位溢出标识
        end;
        extra_variable:record
          timer:longint;//用于Time模块的settimer和gettimer
        end;
      end;
      Func:array[0..func_range-1]of record
        name:ansistring;
        func_ptr:pFuncAuf;
        parameter:string;
        helper:string;
      end;
      Expression:record
        Local,Global:TAufExpressionList;
      end;
      IO_fptr:record
        echo:pFuncAufStr;//相当于writeln(nil,str:string);
        print:pFuncAufStr;//相当于write(nil,str:string);
        error:pFuncAufStr;//相当于writeln(nil,str:string);
        pause:pFuncAuf;//相当于readln;
        clear:pFuncAuf;//清屏
        command_decode:pFuncVarStr;//在GUI模式中使用utf8编码时需要设置转码函数
      end;
      Func_process:record
        pre,post,mid:pFuncAuf;//执行单条指令前后的额外过程和中途防假死预留
        beginning,ending:pFuncAuf;//执行整段代码前后的额外过程
        OnPause,OnResume:pFuncAuf;//暂停和继续时的额外过程
      end;

    published
      procedure send_error(str:string);inline;
      procedure write(str:string);inline;
      procedure writeln(str:string);inline;
      procedure readln;inline;
      procedure ClearScreen;

      function Pointer(Iden:string;Index:pRam):Pointer;
      function TmpExpRamVar(arg:Tnargs):TAufRamVar;
      function RamVar(arg:Tnargs):TAufRamVar;//将标准变量形式转化成ARV
      function to_double(Iden,Index:string):double;deprecated;//将nargs[].pre和nargs[].arg表示的变量转换成double类型
      function to_string(Iden,Index:string):string;deprecated;//将nargs[].pre和nargs[].arg表示的变量转换成string类型

    published
      //将Tnargs参数转换成需要的格式，不符合要求的情况下raise，使用时需要解决异常。
      function TryToDouble(arg:Tnargs):double;
      function TryToDWord(arg:Tnargs):dword;
      function TryToString(arg:Tnargs):string;

      function SharpToDouble(sharp:Tnargs):double;
      function SharpToDword(sharp:Tnargs):dword;
      function SharpToString(sharp:Tnargs):string;

      function TmpexpToDouble(tmpexp:Tnargs):double;deprecated;
      function TmpexpToDword(tmpexp:Tnargs):dword;deprecated;
      function TmpexpToString(tmpexp:Tnargs):string;deprecated;



    published
      procedure add_func(func_name:ansistring;func_ptr:pFuncAuf;func_param,helper:string);
      procedure run_func(func_name:ansistring);
      function have_func(func_name:ansistring):boolean;
      procedure HaltOff;
      procedure PSW_reset;
      procedure line_transfer;//将当前行代码转译成标准形式
      procedure next_addr;
      procedure jump_addr(line:dword);//跳转绝对地址
      procedure offs_addr(offs:longint);//跳转偏移地址
      procedure pop_addr;
      procedure push_addr(Ascript:TStrings;Ascriptname:string;line:dword);

    published
      procedure ram_export;//将整个内存区域打印到文件
      procedure helper;
      procedure define_helper;


      procedure Pause;//人为暂停
      procedure Resume;//人为继续
      procedure Stop;//人为中止

      procedure RunFirst;//代码执行初始化
      procedure RunNext;//代码执行的循环体
      procedure RunClose;//代码执行中止化

      procedure command(str:TStrings);overload;
      procedure command(str:string);overload;

    published
      constructor Create(AOwner:TComponent);
      procedure InternalFuncDefine;//默认函数定义
      procedure AdditionFuncDefine_Text;//字串模块函数定义
      procedure AdditionFuncDefine_Time;//时间模块函数定义
      procedure AdditionFuncDefine_File;//文件模块函数定义
      procedure AdditionFuncDefine_Math;//数学模块函数定义


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
      procedure ReadArgs(ps:string);//将字符串按照隔断符号和变量符号分离出多个参数
      function CheckArgs(MinCount:byte):boolean;//检验参数数量是否满足最小数量要求，数量包括函数名本身
  end;


var

  i:byte;
  Usf:TUsf;

  Auf:TAuf;
  GlobalExpressionList:TAufExpressionList;

  procedure de_writeln(Sender:Tobject;str:string);
  procedure de_write(Sender:TObject;str:string);
  procedure de_readln(Sender:TObject);
  procedure de_message(Sender:TObject;str:string);
  procedure de_nil(Sender:TObject);
  procedure de_decoder(var str:string);

  function narg(Apre,Aarg,Apost:string):Tnargs;


  function isprintable(str:string):boolean;
  function DwordToRawStr(inp:dword):string;
  function RawStrToDword(str:string):dword;
  function pRamToRawStr(inp:pRam):string;
  function RawStrTopRam(str:string):pRam;
  function HexToDword(exp:string):dword;
  function BinaryToDword(exp:string):dword;
  function ExpToDword(exp:string):dword;


IMPLEMENTATION
{$ifdef TEST_MODE}
procedure SysWriteln(str:string);deprecated;
begin
  Auf.Script.writeln(str);
end;
{$endif}

procedure de_decoder(var str:string);
begin
  //do nothing
end;

procedure de_write(Sender:TObject;str:string);
begin
  write(UTF8Toansi(str));
end;
procedure de_writeln(Sender:TObject;str:string);
begin
  de_write(Sender,str);
  writeln;
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
  MessageBox(0,Pchar(str),'Error',MB_OK);
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

function DwordToRawStr(inp:dword):string;
begin
  result:='XXXXDDDD';
  result[1]:=chr(64+inp shr 28);
  result[2]:=chr(64+inp shr 24 mod 16);
  result[3]:=chr(64+inp shr 20 mod 16);
  result[4]:=chr(64+inp shr 16 mod 16);
  result[5]:=chr(64+inp shr 12 mod 16);
  result[6]:=chr(64+inp shr 8 mod 16);
  result[7]:=chr(64+inp shr 4 mod 16);
  result[8]:=chr(64+inp mod 16);
end;
function RawStrToDword(str:string):dword;
begin
  result:=0;
  result:=result+((ord(str[1])-64) shl 28);
  result:=result+((ord(str[2])-64) shl 24);
  result:=result+((ord(str[3])-64) shl 20);
  result:=result+((ord(str[4])-64) shl 16);
  result:=result+((ord(str[5])-64) shl 12);
  result:=result+((ord(str[6])-64) shl 8);
  result:=result+((ord(str[7])-64) shl 4);
  result:=result+(ord(str[8])-64);
end;

function pRamToRawStr(inp:pRam):string;
begin
  {
  result:='DD';
  result[1]:=chr(64+inp shr 4);
  result[2]:=chr(64+inp mod 16);
  }
  result:=DwordToRawStr(inp);
end;
function RawStrTopRam(str:string):pRam;
begin
  {
  result:=0;
  result:=result+((ord(str[1])-64) shl 4);
  result:=result+(ord(str[2])-64);
  }
  result:=RawStrToDword(str);
end;

function HexToDword(exp:string):dword;
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
function BinaryToDword(exp:string):dword;
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

function ExpToDword(exp:string):dword;
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
        result:=HexToDword(str);
      except
        result:=0;
      end;
    end
  else if exp[len] in ['b','B'] then
    begin
      try
        delete(str,len,1);
        result:=BinaryToDword(str);
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
    tpi:byte;
begin
  if ps<>'' then tps:=ps[1] else exit;
  if length(ps)>1 then
    for tpi:=2 to length(ps) do
      begin
        if (not(tps[length(tps)]in c_divi))or(ps[tpi]<>tps[length(tps)]) then
          begin
            if (ps[tpi]=' ')and(tpi<length(ps))then
              begin
                if ps[tpi+1] in c_divi then tps:=tps+ps[tpi+1]
                else tps:=tps+ps[tpi];
              end
            else tps:=tps+ps[tpi];
        end;
      end;
  while (tps<>'') do if tps[1]=' ' then delete(tps,1,1) else break;
  if tps='' then exit;
  while (tps[length(tps)]=' ') do delete(tps,length(tps),1);
  result:=tps;
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
end;
procedure _helper(Sender:TObject);
var AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AufScpt.helper;
end;
procedure _define_helper(Sender:TObject);
var AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AufScpt.define_helper;
end;
procedure ramex(Sender:TObject);
var AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AufScpt.ram_export;
end;
procedure _clear(Sender:TObject);
var AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AufScpt.ClearScreen;
end;
procedure _sleep(Sender:TObject);
var ms:dword;
    AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  //if AAuf.ArgsCount<2 then begin AAuf.Script.send_error('警告：sleep需要一个参数，语句未执行。');exit end;
  //ms:=Round(AufScpt.to_double(AAuf.nargs[1].pre,AAuf.nargs[1].arg));
  try
    ms:=AufScpt.TryToDWord(AAuf.nargs[1]);
  except
    AufScpt.send_error('警告：第一个参数不能转换为FixNum变量，语句未执行。');exit;
  end;
  if ms=0 then exit;
  IF AufScpt.Time.Synthesis_Mode=SynMoTimer THEN BEGIN;
    AufScpt.Time.Timer.Interval:=ms;
    AufScpt.Time.Timer.Enabled:=true;
    AufScpt.Time.TimerPause:=true;
  END ELSE BEGIN
    sleep(ms);
  END;
end;
procedure _pause(Sender:TObject);
begin
  (Sender as TAufScript).writeln('按任意键继续……');
  (Sender as TAufScript).readln;
end;

procedure echo(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  try
    //AufScpt.write(AufScpt.TryToString(AAuf.nargs[1]));
    AufScpt.write(AAuf.args[1]);
  except
    AufScpt.send_error('参数不能转换为字符串');
  end;
end;
procedure cwln(Sender:TObject);
begin
  (Sender as TAufScript).writeln('');
end;
procedure echoln(Sender:TObject);
begin
  echo(Sender);
  cwln(Sender);
end;
procedure print(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  //if AAuf.ArgsCount<2 then begin AAuf.Script.send_error('警告：未指定显示的变量');exit end;
  try
    AufScpt.write(AufScpt.TryToString(AAuf.nargs[1]));
  except
    AufScpt.send_error('错误：'+AAuf.args[1]+'转为字符串时失败！')
  end;
end;
{$ifdef TEST_MODE}
procedure _debugln(Sender:TObject);
var AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  SysWriteln(AufScpt.to_string((AufScpt.Auf as TAuf).nargs[1].pre,(AufScpt.Auf as TAuf).nargs[1].arg));
end;
procedure _pause_resume(Sender:TObject);
begin
  _pause(Sender);
  Application.ProcessMessages;
  (Sender as TAufScript).Resume;
end;
{$endif}
procedure println(Sender:TObject);
var AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  print(AufScpt);
  cwln(Sender);
end;
{
procedure exchange(Sender:TObject);
var AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
end;
}
procedure hex(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  //if AAuf.ArgsCount<1 then begin AufScpt.send_error('警告：hex需要一个参数，不能显示。');exit end;
  case AAuf.nargs[1].pre of
    '$"','~"','#"','$&"','~&"','#&"':AufScpt.write(arv_to_hex(AAuf.Script.RamVar(AAuf.nargs[1])));
    else AufScpt.send_error('警告：不支持非标准变量形式，不能显示');
  end;
end;

procedure hexln(Sender:TObject);
begin
  hex(Sender);
  (Sender as TAufScript).writeln('');
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
  //if AAuf.ArgsCount<2 then begin AufScpt.send_error('警告：fillbyte需要2个参数，赋值未成功。');exit end;
  tmp:=AufScpt.RamVar(AAuf.nargs[1]);
  if tmp.size=0 then begin
    AufScpt.send_error('警告：第一个参数需要是变量，'+AAuf.nargs[0].arg+'语句未执行。');
    exit;
  end;
  try
    target:=AufScpt.TryToDWord(AAuf.nargs[2]);
  except
    stmp:=AufScpt.TryToString(AAuf.nargs[2]);
    if length(stmp)<>0 then target:=ord(stmp[1])
    else begin
      AufScpt.send_error('警告：第二个参数需要是字符型或整型数值，'+AAuf.nargs[0].arg+'语句未执行。');
      exit;
    end;
  end;
  //AufScpt.writeln('tmp.size='+IntToStr(tmp.size));
  //AufScpt.writeln('target='+IntToStr(target));
  for pi:=0 to tmp.size-1 do (tmp.Head+pi)^:=target;
end;


procedure movb(Sender:TObject);
var a:byte;
    AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  //if AAuf.ArgsCount<3 then begin AAuf.Script.send_error('警告：movb需要两个参数，赋值未成功。');exit end;
  if not (AAuf.nargs[1].pre='$') then begin AAuf.Script.send_error('警告：movb的一个参数需要是byte变量，赋值未成功。');exit end;
  case AAuf.nargs[2].pre of
    '$':a:=pByte(AufScpt.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^;
    '@':a:=pLong(AufScpt.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^;
    '~':a:=round(pDouble(AufScpt.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^);
    '##':a:=round(Usf.to_f(pString(AufScpt.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^));
    '#':a:=round(Usf.to_f(pString(AufScpt.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^));
    '':a:=round(Usf.to_f(AAuf.nargs[2].arg));
    else begin AufScpt.send_error('警告：movb的第二个参数有误，赋值未成功。');exit end;
  end;
  PByte(AufScpt.Pointer(AAuf.nargs[1].pre,Usf.to_i(AAuf.nargs[1].arg)))^:=a;
end;
procedure movl(Sender:TObject);
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
    '@':a:=pLong(AufScpt.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^;
    '~':a:=round(pDouble(AAuf.Script.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^);
    '##':a:=round(Usf.to_f(pString(AAuf.Script.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^));
    '#':a:=round(Usf.to_f(pString(AAuf.Script.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^));
    '':a:=round(Usf.to_f(AAuf.nargs[2].arg));
    else begin AufScpt.send_error('警告：movl的第二个参数有误，赋值未成功。');exit end;
  end;
  PLong(AufScpt.Pointer(AAuf.nargs[1].pre,Usf.to_i(AAuf.nargs[1].arg)))^:=a;
end;
procedure movd(Sender:TObject);
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
    '@':a:=pLong(AAuf.Script.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^;
    '~':a:=pDouble(AAuf.Script.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^;
    '##':a:=Usf.to_f(pString(AufScpt.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^);
    '#':a:=Usf.to_f(pString(AufScpt.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^);
    '':a:=Usf.to_f(AAuf.nargs[2].arg);
    else begin AufScpt.send_error('警告：movl的第二个参数有误，赋值未成功。');exit end;
  end;
  PDouble(AufScpt.Pointer(AAuf.nargs[1].pre,Usf.to_i(AAuf.nargs[1].arg)))^:=a;
end;
procedure movs(Sender:TObject);
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
    tmp:TAufRamVar;
    AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  //if AAuf.ArgsCount<3 then begin AufScpt.send_error('警告：mov_arv需要两个参数，赋值未成功。');exit end;
  case AAuf.nargs[1].pre of
    '$"','~"','$&"','~&"','#"','#&"':;
    else
      begin
        AAuf.Script.send_error('警告：mov_arv的一个参数需要是标准ARV变量形式，赋值未成功。');
        exit
      end;
  end;
  tmp:=(AufScpt.RamVar(AAuf.nargs[1]));
  case AAuf.nargs[2].pre of
    '$':initiate_arv(IntToHex(pByte(AufScpt.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^,2),tmp);
    '@':initiate_arv(IntToHex(pLong(AufScpt.Pointer(AAuf.nargs[2].pre,Usf.to_i(AAuf.nargs[2].arg)))^,8),tmp);
    '~':begin AAuf.Script.send_error('警告：mov_arv暂不支持浮点型，赋值未成功。');initiate_arv('0h',tmp) end;
    '$"','~"','$&"','~&"','#&"','#"':
      begin
        copyARV(AufScpt.RamVar(AAuf.nargs[2]),tmp);
      end;
    '':
      try
        initiate_arv(AAuf.nargs[2].arg,tmp)
      except
        AAuf.Script.send_error('警告：mov_arv暂不支持非十六进制，赋值未成功。');
      end;
    '"':initiate_arv_str(AAuf.nargs[2].arg,tmp);
    else begin AAuf.Script.send_error('警告：mov_arv的第二个参数有误，赋值未成功。');exit end;
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
  ARV_add(tmp1,tmp2);

end;
procedure add(Sender:TObject);
var a,b:double;
    tmp:TAufRamVar;
    AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  //if AAuf.ArgsCount<3 then begin AufScpt.send_error('警告：add需要两个参数，赋值未成功。');exit end;
  {=begin 临时增加}
  if AufScpt.RamVar(AAuf.nargs[1]).size * AufScpt.RamVar(AAuf.nargs[2]).size <>0 then
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
  ARV_sub(tmp1,tmp2);
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
  ARV_mul2(tmp1,tmp2);
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
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  //if AAuf.ArgsCount<3 then begin AufScpt.send_error('警告：sub_add需要两个参数，赋值未成功。');exit end;
  tmp1:=AufScpt.RamVar(AAuf.nargs[1]);
  if tmp1.size=0 then begin
    AufScpt.send_error('警告：div_arv的第1个参数错误，语句未执行。');
    exit;
  end;
  tmp2:=AufScpt.RamVar(AAuf.nargs[2]);
  if tmp2.size=0 then begin
    AufScpt.send_error('警告：div_arv的第2个参数错误，语句未执行。');
    exit;
  end;
  if ARV_EqlZero(tmp2) then begin
    AufScpt.send_error('警告：div_arv的第2个参数不能为0，语句未执行。');
    exit;
  end;
  ARV_div(tmp1,tmp2);
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
  ARV_mod(tmp1,tmp2);
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
var rand_res,rand_max:longint;
    tmp:TAufRamVar;
    AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  //if AAuf.ArgsCount<3 then begin AufScpt.send_error('警告：rand需要两个参数，赋值未成功。');exit end;
  try
    rand_max:=AufScpt.TryToDWord(AAuf.nargs[2]);
  except
    AufScpt.send_error('警告：mod的第二个参数不能转换为dword类型，语句未执行。');
    exit;
  end;
  if rand_max=0 then begin AufScpt.send_error('警告：rand的第二个参数不能为0，语句未执行。');exit end;
  try
    randomize;
    rand_res:=random(rand_max);
    tmp:=AufScpt.RamVar(AAuf.nargs[1]);
    case tmp.VarType of
      ARV_Char:;
      ARV_FixNum:dword_to_arv(rand_res,tmp);
      ARV_Float:double_to_arv(rand_res,tmp);
    end;
  except
    AufScpt.send_error('警告：rand的第一个参数需要是Float或FixNum变量，语句未执行。');
    exit;
  end;
end;

procedure cj_mode(mode:string;Sender:TObject);//比较两个变量，满足条件则跳转至ofs  cj var1,var2,ofs
var a,b:double;
    ofs:smallint;
    is_not,is_call:boolean;//是否有N前缀或C后缀
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

  ofs:=0;
  if not AAuf.CheckArgs(4) then exit;//取消默认跳转数值
  //if AAuf.ArgsCount<3 then begin AufScpt.send_error('警告：'+AAuf.nargs[0].arg+'需要两个变量，该语句未执行。');exit end;
  if AAuf.ArgsCount>3 then
    begin
      case AAuf.nargs[3].pre of
        '$':ofs:=pByte(AufScpt.Pointer(AAuf.nargs[3].pre,Usf.to_i(AAuf.nargs[3].arg)))^;
        '@':ofs:=pLong(AufScpt.Pointer(AAuf.nargs[3].pre,Usf.to_i(AAuf.nargs[3].arg)))^;
        '~':ofs:=round(pDouble(AufScpt.Pointer(AAuf.nargs[3].pre,Usf.to_i(AAuf.nargs[3].arg)))^);
        '&"':ofs:=RawStrToDword(AAuf.nargs[3].arg) - AufScpt.PSW.run_parameter.current_line_number;
        '':ofs:=Usf.to_i(AAuf.nargs[3].arg);
        else begin AufScpt.send_error('警告：地址偏移参数有误，语句未执行');exit end;
      end;
    end
  else
    begin
      if is_not then ofs:=-2
      else ofs:=2;
    end;
  if ofs=0 then begin AufScpt.send_error('警告：'+AAuf.nargs[0].arg+'需要非零的地址偏移量，该语句未执行。');exit end;
  try
    b:=AufScpt.TryToDouble(AAuf.nargs[2]);
  except
    AufScpt.send_error('警告：'+AAuf.nargs[0].arg+'的第二个参数不能转换为double类型，语句未执行。');exit;
  end;
  try
    a:=AufScpt.TryToDouble(AAuf.nargs[1]);
  except
    AufScpt.send_error('警告：'+AAuf.nargs[0].arg+'的第一个参数不能转换为double类型，语句未执行。');exit;
  end;
  case core_mode of
    'ife':if (a=b) xor is_not then switch_addr(AufScpt.currentLine+ofs,is_call);
    'cje':if (a=b) xor is_not then switch_addr(AufScpt.currentLine+ofs,is_call);
    'ifl':if (a<b) xor is_not then switch_addr(AufScpt.currentLine+ofs,is_call);
    'cjl':if (a<b) xor is_not then switch_addr(AufScpt.currentLine+ofs,is_call);
    'ifm':if (a>b) xor is_not then switch_addr(AufScpt.currentLine+ofs,is_call);
    'cjm':if (a>b) xor is_not then switch_addr(AufScpt.currentLine+ofs,is_call);
  end;

end;

procedure cj(Sender:TObject);
var AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  cj_mode((AufScpt.Auf as TAuf).nargs[0].arg,AufScpt);
end;

procedure jmp(Sender:TObject);//满足条件执行下一句，不满足条件跳过下一句  jmp ofs|:label
var ofs:smallint;
    AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  ofs:=0;
  if not AAuf.CheckArgs(2) then exit;
  //if AAuf.ArgsCount<2 then begin AufScpt.send_error('警告：jmp需要一个变量，该语句未执行。');exit end;
  case AAuf.nargs[1].pre of
    '&"':ofs:=RawStrToDword(AAuf.nargs[1].arg) - AufScpt.PSW.run_parameter.current_line_number;
    else ofs:=Round(AAuf.Script.to_double(AAuf.nargs[1].pre,AAuf.nargs[1].arg));
  end;
  if ofs=0 then begin AufScpt.send_error('警告：jmp需要非零的地址偏移量，该语句未执行。');exit end;
  AufScpt.jump_addr(AufScpt.currentLine+ofs);
end;

procedure call(Sender:TObject);//满足条件执行下一句，使用ret返回至该位置的下一行，不满足条件跳过下一句  call ofs|:label
var ofs:smallint;
    AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  ofs:=0;
  if not AAuf.CheckArgs(2) then exit;
  //if AAuf.ArgsCount<2 then begin AAuf.Script.send_error('警告：call需要一个变量，该语句未执行。');exit end;
  case AAuf.nargs[1].pre of
    '&"':ofs:=RawStrToDword(AAuf.nargs[1].arg) - AufScpt.PSW.run_parameter.current_line_number;
    else ofs:=Round(AufScpt.to_double(AAuf.nargs[1].pre,AAuf.nargs[1].arg));
  end;
  if ofs=0 then begin AufScpt.send_error('警告：call需要非零的地址偏移量，该语句未执行。');exit end;
  AufScpt.push_addr(AufScpt.ScriptLines,AufScpt.ScriptName,AufScpt.currentLine+ofs);
end;

procedure _load(Sender:TObject);//打开文件 load "filename"
var AufScpt:TAufScript;
    tmp:TStrings;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  //if AAuf.argsCount < 2 then begin AufScpt.send_error('警告：load需要一个变量，该语句未执行。');exit end;
  tmp:=TStringList.Create;
  try
    tmp.LoadFromFile(AAuf.nargs[1].arg);
    tmp.Add('fend');//不判断了，保底最后都跳出来
  except
    AufScpt.send_error('警告：文件"'+AAuf.nargs[1].arg+'"打开失败，该语句未执行。');
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
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  //if AAuf.ArgsCount<3 then begin AufScpt.send_error('警告：define需要两个变量，该语句未执行。');exit end;
  case AAuf.nargs[1].arg[1] of
    'a'..'z','A'..'Z','_':;
    else begin AufScpt.send_error('警告：第一个参数的第一个字符需要是字母或下划线，该语句未执行。');exit end;
  end;
  try
    AufScpt.Expression.Local.TryAddExp(AAuf.nargs[1].arg,AAuf.nargs[2]);
  except
    AufScpt.send_error('警告：define参数有误，未正确执行')
  end;
end;
procedure _rendef(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  //if AAuf.ArgsCount<3 then begin AufScpt.send_error('警告：rendef需要两个变量，该语句未执行。');exit end;
  case AAuf.nargs[1].arg[1] of
    'a'..'z','A'..'Z','_':;
    else begin AufScpt.send_error('警告：第一个参数的第一个字符需要是字母或下划线，该语句未执行。');exit end;
  end;
  case AAuf.nargs[1].arg[2] of
    'a'..'z','A'..'Z','_':;
    else begin AufScpt.send_error('警告：第二个参数的第一个字符需要是字母或下划线，该语句未执行。');exit end;
  end;
  try
    AufScpt.Expression.Local.TryRenameExp(AAuf.nargs[1].arg,AAuf.nargs[2].arg);
  except
    AufScpt.send_error('警告：rendef参数有误，未正确执行')
  end;
end;

{$ifdef TEST_MODE}
procedure _test(Sender:TObject);
var tmp:TAufRamVar;
    t1,t2,add,sub,mul,divv,modd,divreal:TDecimalStr;
    AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;

  AufScpt.writeln('arv_to_dec_fraction:'+arv_to_dec_fraction(AufScpt.RamVar(AAuf.nargs[1])));

  {
  t1.data:=AAuf.args[1];
  t2.data:=AAuf.args[2];
  AufScpt.writeln('DecimalStr_Comp='+IntToStr(DecimalStr_Comp(t1,t2)));
  AufScpt.writeln('DecimalStr_AADD='+DecimalStr_ABS_ADD(t1,t2).data);
  AufScpt.writeln('DecimalStr_ASUB='+DecimalStr_ABS_SUB(t1,t2).data);
  add:=t1+t2;
  AufScpt.writeln('t1+t2='+add.data);
  sub:=t1-t2;
  AufScpt.writeln('t1-t2='+sub.data);
  mul:=t1*t2;
  AufScpt.writeln('t1*t2='+mul.data);
  divv:=t1 div t2;
  AufScpt.writeln('t1 div t2='+divv.data);
  modd:=t1 mod t2;
  AufScpt.writeln('t1 mod t2='+modd.data);
  divreal:=t1 / t2;
  AufScpt.writeln('t1 / t2='+divreal.data);

  }

  //AufScpt.writeln(IntToStr(numberic_check(AAuf.args[1])));
end;
{$endif}

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
    tmp1,tmp2:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  tmp1:=AufScpt.RamVar(AAuf.nargs[1]);
  if tmp1.size=0 then begin
    AufScpt.send_error('警告：第一个参数不是变量类型');
    exit;
  end;
  tmp2:=AufScpt.RamVar(AAuf.nargs[2]);
  if tmp2.size=0 then begin
    AufScpt.send_error('警告：第二个参数不是变量类型');
    exit;
  end;
  AufScpt.writeln('对比结果：'+IntToStr(ARV_comp(tmp1,tmp2)));
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
  tmp:=AufScpt.RamVar(AAuf.nargs[1]);
  if tmp.size=0 then begin
    AufScpt.send_error('警告：第一个参数不是变量类型');
    exit;
  end;
  try
    bit:=AufScpt.TryToDWord(AAuf.nargs[2]);
  except
    AufScpt.send_error('警告：第二个参数不能转换为dword类型，'+AAuf.nargs[0].arg+'语句未执行。');
    exit;
  end;
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
  if tmp.size=0 then begin
    AufScpt.send_error('警告：第一个参数不是变量类型');
    exit;
  end;
  try
    bit:=AufScpt.TryToDWord(AAuf.nargs[2]);
  except
    AufScpt.send_error('警告：第二个参数不能转换为dword类型，'+AAuf.nargs[0].arg+'语句未执行。');
    exit;
  end;
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
  tmp:=AufScpt.RamVar(AAuf.nargs[1]);
  if tmp.size=0 then begin
    AufScpt.send_error('警告：第一个参数不是变量类型');
    exit;
  end;
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
  tmp1:=AufScpt.RamVar(AAuf.nargs[1]);
  if tmp1.size=0 then begin
    AufScpt.send_error('警告：第一个参数不是变量类型');
    exit;
  end;
  tmp2:=AufScpt.RamVar(AAuf.nargs[2]);
  if tmp2.size=0 then begin
    AufScpt.send_error('警告：第二个参数不是变量类型');
    exit;
  end;
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
  tmp1:=AufScpt.RamVar(AAuf.nargs[1]);
  if tmp1.size=0 then begin
    AufScpt.send_error('警告：第一个参数不是变量类型');
    exit;
  end;
  tmp2:=AufScpt.RamVar(AAuf.nargs[2]);
  if tmp2.size=0 then begin
    AufScpt.send_error('警告：第二个参数不是变量类型');
    exit;
  end;
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
  tmp1:=AufScpt.RamVar(AAuf.nargs[1]);
  if tmp1.size=0 then begin
    AufScpt.send_error('警告：第一个参数不是变量类型');
    exit;
  end;
  tmp2:=AufScpt.RamVar(AAuf.nargs[2]);
  if tmp2.size=0 then begin
    AufScpt.send_error('警告：第二个参数不是变量类型');
    exit;
  end;
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
  //if AAuf.ArgsCount<3 then begin AufScpt.send_error('警告：h_add需要两个参数，语句未执行。');exit end; ;
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
  try
    b.data:=AufScpt.TryToString(AAuf.nargs[2]);
  except
    AufScpt.send_error('警告：第二个参数不能转换为string类型，'+AAuf.nargs[0].arg+'语句未执行。');exit;
  end;

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
  try
    b.data:=AufScpt.TryToString(AAuf.nargs[2]);
  except
    AufScpt.send_error('警告：第二个参数不能转换为string类型，'+AAuf.nargs[0].arg+'语句未执行。');exit;
  end;
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


procedure text_str(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    tmp:TAufRamVar;
    str:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  try
    tmp:=AufScpt.RamVar(AAuf.nargs[1]);
    //if tmp=nil then raise Exception.Create('');
    if tmp.VarType<>ARV_Char then raise Exception.Create('');
  except
    AufScpt.send_error('警告：第一个参数需要是字符串变量，'+AAuf.nargs[0].arg+'语句未执行。');exit;
  end;
  try
    str:=AufScpt.TryToString(AAuf.nargs[2]);
  except
    AufScpt.send_error('警告：第二个参数不能转换为string类型，'+AAuf.nargs[0].arg+'语句未执行。');exit;
  end;
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
  try
    tmp:=AufScpt.RamVar(AAuf.nargs[1]);
    //if tmp=nil then raise Exception.Create('');
    if not (tmp.VarType in [ARV_Float,ARV_FixNum]) then raise Exception.Create('');
  except
    AufScpt.send_error('警告：第一个参数需要是数值变量，'+AAuf.nargs[0].arg+'语句未执行。');exit;
  end;
  try
    str:=AufScpt.TryToString(AAuf.nargs[2]);
  except
    AufScpt.send_error('警告：第二个参数不能转换为double类型，'+AAuf.nargs[0].arg+'语句未执行。');exit;
  end;
  initiate_arv(str,tmp);
end;

procedure time_settimer(Sender:TObject);
var AufScpt:TAufScript;
    h,m,s,cs:word;
begin
  AufScpt:=Sender as TAufScript;
  gettime(h,m,s,cs);
  AufScpt.PSW.extra_variable.timer:=cs*10+s*1000+m*60000+h*3600000;
end;
procedure time_gettimer(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    h,m,s,cs:word;
    tmp:longint;
    arv:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  gettime(h,m,s,cs);
  tmp:=cs*10+s*1000+m*60000+h*3600000;
  if tmp<AufScpt.PSW.extra_variable.timer then tmp:=tmp+24*60*60*1000;
  tmp:=tmp - AufScpt.PSW.extra_variable.timer;
  if AAuf.ArgsCount=1 then AufScpt.writeln('定时器读数：'+IntToStr(tmp)+'毫秒')
  else
    begin
      arv:=AufScpt.RamVar(AAuf.nargs[1]);
      if (arv.VarType <> ARV_FixNum) or (arv.Size < 4) then
        AufScpt.send_error('警告：第一个参数需要是4位及以上宽度的整型变量，该语句未执行。')
      else
        dword_to_arv(dword(tmp),arv);
    end;
end;
procedure time_waittimer(Sender:TObject);//线程不可用，需要再看怎么处理
var AufScpt:TAufScript;
    AAuf:TAuf;
    h,m,s,cs:word;
    tmp,std:dword;
    arv:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  //if AAuf.ArgsCount<2 then begin AAuf.Script.send_error('警告：waittimer需要一个参数，语句未执行。');exit end;
  try
    std:=AufScpt.TryToDWord(AAuf.nargs[1]);
  except
    AufScpt.send_error('警告：第一个参数不能转换为FixNum变量，语句未执行。');exit;
  end;
  ////////////////
  gettime(h,m,s,cs);
  tmp:=cs*10+s*1000+m*60000+h*3600000;
  if tmp<AufScpt.PSW.extra_variable.timer then tmp:=tmp+24*60*60*1000;
  tmp:=tmp - AufScpt.PSW.extra_variable.timer;

  if tmp>=std then exit
  else begin
    tmp:=std-tmp;
    IF AufScpt.Time.Synthesis_Mode=SynMoTimer THEN BEGIN;
      AufScpt.Time.Timer.Interval:=tmp;
      AufScpt.Time.Timer.Enabled:=true;
      AufScpt.Time.TimerPause:=true;
    END ELSE BEGIN
      sleep(tmp);
    END;
  end;
end;
procedure time_gettimestr(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    h,m,s,cs:word;
    arv:TAufRamVar;
    tmp:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  gettime(h,m,s,cs);
  tmp:=Usf.zeroplus(h,2)+':'+Usf.zeroplus(m,2)+':'+Usf.zeroplus(s,2)+'.'+Usf.zeroplus(cs,2)+'0';
  if AAuf.ArgsCount=1 then AufScpt.writeln('当前时间：'+tmp)
  else
    begin
      arv:=AufScpt.RamVar(AAuf.nargs[1]);
      if (arv.VarType <> ARV_Char) or (arv.Size < 12) then
        AufScpt.send_error('警告：第一个参数需要是12位及以上宽度的字符型变量，该语句未执行。')
      else
        s_to_arv(tmp,arv);
    end;
end;
procedure time_getdatestr(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    y,m,d,w:word;
    arv:TAufRamVar;
    tmp:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  getdate(y,m,d,w);
  tmp:=Usf.zeroplus(y,4)+'-'+Usf.zeroplus(m,2)+'-'+Usf.zeroplus(d,2);
  if AAuf.ArgsCount=1 then AufScpt.writeln('当前日期：'+tmp)
  else
    begin
      arv:=AufScpt.RamVar(AAuf.nargs[1]);
      if (arv.VarType <> ARV_Char) or (arv.Size < 10) then
        AufScpt.send_error('警告：第一个参数需要是10位及以上宽度的字符型变量，该语句未执行。')
      else
        s_to_arv(tmp,arv);
    end;
end;

//内置流程函数结束




///////////Class Methods begin


//Auf Methods
procedure TAuf.ReadArgs(ps:string);
var tps:string;
    tpi,tpm:byte;
    in_quotation,is_post:boolean;
begin
  //初始化返回变量
  for tpi:=0 to args_range-1 do args[tpi]:='';
  for tpi:=0 to args_range-1 do begin nargs[tpi].arg:='';nargs[tpi].post:='';nargs[tpi].pre:='' end;
  ArgsCount:=0;
  toto:='';divi:='';iden:='';

  //命令删除重复空格

  if ps<>'' then tps:=non_space(ps) else exit;

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
function TUsf.ExPChar(str:string):Pchar;//string转PChar的新方法
begin
  str_buffer:=str+#0;
  result:=@str_buffer[1];
end;
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
function TUsf.left_adjust(str:string;len:byte):string;
begin
  result:=str;
  while (length(result)<len)or(length(result) mod 8<>0) do result:=result+' ';
end;
function TUsf.right_adjust(str:string;len:byte):string;
begin
  result:=str;
  while (length(result)<len)or(length(result) mod 8<>0) do result:=' '+result;
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
var tmp:qword;
begin
  tmp:=inp;
  result:='';
  repeat
    result:=chr(48+(tmp mod 16))+result;
    tmp:=tmp shr 4;
  until length(result)>=len;
  for tmp:=1 to length(result) do if result[tmp] in [#58..#63] then result[tmp]:=chr(ord(result[tmp])+7);
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
procedure TUsf.each_file(path:ansistring;func_ptr:pFuncFileByte);//开始备份指定盘符，从Ucrawer搬运
var Rec:^SearchRec;
    ARec:SearchRec;
  begin
    Rec:=@ARec;
    //getmem(Rec,sizeof(Rec));
    //非文件夹
    findfirst(path+'\*.*',$2F,Rec^);
    while dosError=0 do begin
      func_ptr(path+'\'+Rec^.name);
      findnext(Rec^);
    end;
    findclose(Rec^);
    //文件夹递归
    findfirst(path+'\*',$10,Rec^);
    while dosError=0 do begin
      if (Rec^.name<>'.')and(Rec^.name<>'..') then each_file(path+'\'+Rec^.name,func_ptr);
      findnext(Rec^);
    end;
    findclose(Rec^);
    //freemem(Rec{,sizeof(Rec)});
  end;
procedure TUsf.each_file_in_folder(path:ansistring;func_ptr:pFuncFileByte);
var Rec:^SearchRec;
    ARec:SearchRec;
  begin
    Rec:=@ARec;
    //getmem(Rec,sizeof(Rec));
    //非文件夹
    findfirst(path+'\*.*',$2F,Rec^);
    while dosError=0 do begin
      func_ptr(path+'\'+Rec^.name);
      findnext(Rec^);
    end;
    findclose(Rec^);
    //freemem(Rec{,sizeof(Rec)});
  end;

function TUsf.fsel(address:string):byte;
var i:byte;
begin
  for i:=0 to 255 do if FileByte[i].name=address then begin result:=i;exit end;
  result:=255;
  write(result);
end;

procedure TUsf.fassign(address:string;fid:byte);
begin
  if FileByte[fid].fready=true then begin Auf.Script.send_error('错误：不能指派打开的文件！');exit end;//不太合适的跨模块调用
  FileByte[fid].name:=address;
  assignfile(FileByte[fid].fptr,address);
end;
procedure TUsf.fcreate(fid:byte);
begin
  rewrite(FileByte[fid].fptr);
  close(FileByte[fid].fptr);
end;
procedure TUsf.freset(fid:byte);
begin
  reset(FileByte[fid].fptr);
  FileByte[fid].fready:=true;
end;
procedure TUsf.fwriteb(fid:byte;seeking:dword;byt:byte);
begin
  seek(FileByte[fid].fptr,seeking);
  write(FileByte[fid].fptr,byt);
end;
procedure TUsf.freadb(fid:byte;seeking:dword;var byt:byte);
begin
  seek(FileByte[fid].fptr,seeking);
  read(FileByte[fid].fptr,byt);
end;
procedure TUsf.fwrites(fid:byte;seeking:dword;str:string);
var i:byte;
begin
  for i:=0 to length(str)-1 do fwriteb(fid,seeking+i,ord(str[i+1]));
end;
procedure TUsf.freads(fid:byte;seeking:dword;len:byte;var str:string);
var i,c:byte;
begin
  str:='';
  for i:=0 to len-1 do begin
    freadb(fid,seeking+i,c);
    str:=str+chr(c);
  end;
end;
procedure TUsf.fclose(fid:byte);
begin
  if FileByte[fid].fready=false then begin Auf.Script.send_error('警告：不能关闭未打开的文件！');exit end;//不太合适的跨模块调用
  close(FileByte[fid].fptr);
  FileByte[fid].fready:=false;
end;

procedure TUsf.fassign(address:string);
var i:byte;
begin
  for i:=0 to 255 do if FileByte[i].name='' then break;
  //write(i);
  FileByte[i].name:=address;
  assignfile(FileByte[i].fptr,address);
  //FileByte[255].fptr在文件打开的情况下变更会导致错误
end;

procedure TUsf.fcreate(address:string);inline;
begin
  fcreate(fsel(address));
end;
procedure TUsf.freset(address:string);inline;
begin
  freset(fsel(address));
end;
procedure TUsf.fwriteb(address:string;seeking:dword;byt:byte);
begin
  fwriteb(fsel(address),seeking,byt);
end;
procedure TUsf.freadb(address:string;seeking:dword;var byt:byte);
begin
  freadb(fsel(address),seeking,byt);
end;
procedure TUsf.fwrites(address:string;seeking:dword;str:string);
begin
  fwrites(fsel(address),seeking,str);
end;
procedure TUsf.freads(address:string;seeking:dword;len:byte;var str:string);
begin
  freads(fsel(address),seeking,len,str);
end;
procedure TUsf.fclose(address:string);
begin
  fclose(fsel(address));
end;
constructor TUsf.Create;
var i:byte;
begin
  inherited Create;
  for i:=0 to 255 do Self.FileByte[i].name:='';
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
  {$ifdef TEST_MODE}SysWriteln(IntToStr(l));{$endif}
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

function TAufScript.GetArgLine:string;
begin
  result:=(Self.Auf as TAuf).args[0];
  for i:=1 to (Self.Auf as TAuf).ArgsCount-1 do
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
  if codee<>0 then begin raise Exception.Create('没有中部');exit end;
  result.head:=pbyte(value)+dword(Self.PSW.run_parameter.ram_zero);
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
  result.size:=RawStrTopRam(s_size);
  if result.size=0 then result.size:=4;
  result.head:=pbyte(RawStrToDWord(s_addr));

  if is_ref then
    begin
      result.Head:=pbyte(pdword(result.Head+dword(Self.PSW.run_parameter.ram_zero))^);
    end;

  {if arg.post[length(arg.post)]<>arg.pre[1] then }
  result.head:=result.head+dword(Self.PSW.run_parameter.ram_zero);

  result.Is_Temporary:=false;
  result.Stream:=nil;

end;

function TAufScript.SharpToDouble(sharp:Tnargs):double;
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
              '1'..'9':result:=result+ord(stmp[1])-ord('0');
              'A'..'F':result:=result+ord(stmp[1])+10-ord('A');
              'a'..'f':result:=result+ord(stmp[1])+10-ord('a');
              else raise Exception.Create('SharpToDouble Error: 十六进制包含非法字符');
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
              else raise Exception.Create('SharpToDouble Error: 二进制包含非法字符');
            end;
            delete(stmp,1,1);
          end;
      end;
    else
      begin
        let:=0;
        val(stmp,result,let);
        if let<>0 then raise Exception.Create('SharpToDouble Error: 十进制包含非法字符');
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
              '1'..'9':result:=result+ord(stmp[1])-ord('0');
              'A'..'F':result:=result+ord(stmp[1])+10-ord('A');
              'a'..'f':result:=result+ord(stmp[1])+10-ord('a');
              else raise Exception.Create('SharpToDword Error: 十六进制包含非法字符');
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
              else raise Exception.Create('SharpToDword Error: 二进制包含非法字符');
            end;
            delete(stmp,1,1);
          end;
      end;
    else
      begin
        let:=0;
        val(stmp,result,let);
        if let<>0 then raise Exception.Create('SharpToDword Error: 十进制包含非法字符');
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
    raise Exception.Create('TmpexpToDouble error: @n/$n/~n index invalid');
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
    raise Exception.Create('TmpexpToDword error: @n/$n/~n index invalid');
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
    raise Exception.Create('TmpexpToString error: @n/$n/~n index invalid');
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
function TAufScript.to_double(Iden,Index:string):double;//将nargs[].pre和nargs[].arg表示的变量转换成double类型
var dbl:double;
    value:pRam;
    codee:byte;
    tmp_narg:Tnargs;//不得已而为之，以后重构整个to_double
begin
  tmp_narg.arg:=index;
  tmp_narg.pre:=iden;
  case tmp_narg.pre of
    '$"','$&"','~"','~&"','#"','#&"': tmp_narg.post:='"';
    else
      begin
        val(Index,value,codee);
        if (codee<>0)and(Iden<>'') then begin Self.send_error('警告：变量序号有误，返回0！');result:=0;exit end;
      end;
  end;
  case Iden of
    '$':result:=vByte[value];
    '@':result:=vLong[value];
    '~':result:=vDouble[value];
    '##':begin
           val(vStr[value],dbl,codee);
           if codee=0 then result:=dbl
           else begin
             Self.send_error('警告：字符变量转换浮点型失败，返回0！');result:=0;
             result:=0
           end
         end;
    '#':begin
          val(vSubStr[value],dbl,codee);
          if codee=0 then result:=dbl
          else begin
            Self.send_error('警告：字符变量转换浮点型失败，返回0！');result:=0;
            result:=0
          end
        end;
    '':begin
         result:=Usf.to_f(Index);
       end;
    '$"','$&"':
      begin
        result:=arv_to_dword(Self.RamVar(tmp_narg));
      end;
 {   '~"','~&"':
      begin
        //
      end;
    '#"','#&"':
      begin
        //
      end;           }
    else begin Self.send_error('警告：无效的指针类型，返回0！');result:=0;exit end;
  end;
end;
function TAufScript.to_string(Iden,Index:string):string;//将nargs[].pre和nargs[].arg表示的变量转换成string类型
var str:string;
    value:pRam;
    codee:byte;
begin
  val(Index,value,codee);
  if (codee<>0)and(iden<>'') and (iden<>'"') then begin Self.send_error('警告：变量序号有误，返回0！');result:='';exit end;
  case Iden of
    '$':result:=Usf.i_to_s(vByte[value]);
    '@':result:=Usf.i_to_s(vLong[value]);
    '~':result:=Usf.to_s(vDouble[value]);
    '##':begin
           result:=vStr[value];
         end;
    '#':begin
          result:=vSubStr[value];
        end;
    '':begin
          result:=Index;
       end;
    '"':begin
          result:=Index;
       end;
    else begin Self.send_error('警告：无效的指针类型，返回0！');result:='';exit end;
  end;
end;
procedure TAufScript.ram_export;//将整个内存区域打印到文件
begin
  try
    Self.var_stream.SaveToFile('ram.var');
  except
    Self.send_error('警告：文件写入失败！请检查ram.var文件是否被占用。');
  end;
end;

procedure TAufScript.add_func(func_name:ansistring;func_ptr:pFuncAuf;func_param,helper:string);
var i:word;
begin
  for i:=0 to func_range-1 do if Self.func[i].name='' then break;
  if (i=func_range-1) and (Self.func[i].name<>'') then begin Self.send_error('错误：函数列表已满，不能继续添加新的函数！');Self.readln;halt end;
  Self.func[i].name:=func_name;
  Self.func[i].helper:=helper;
  Self.func[i].parameter:=func_param;
  Self.func[i].func_ptr:=func_ptr;
  if Self.SynAufSyn<>nil then Self.SynAufSyn.InternalFunc:=Self.SynAufSyn.InternalFunc+func_name+',';
end;
procedure TAufScript.run_func(func_name:ansistring);
var i:word;
begin
  if func_name='' then begin Self.writeln('');exit end;
  func_name:=lowercase(func_name);
  for i:=0 to func_range-1 do if Self.func[i].name=func_name then break;
  if (i=func_range-1) and (Self.func[i].name<>func_name) then begin Self.send_error('警告：未找到函数'+func_name+'！');exit end;
  Self.func[i].func_ptr(Self);
end;
function TAufScript.have_func(func_name:ansistring):boolean;
var i:word;
begin
  if func_name='' then begin Self.writeln('');exit end;;
  for i:=0 to func_range-1 do if Self.func[i].name=func_name then break;
  if (i=func_range-1) and (Self.func[i].name<>func_name) then begin result:=false;exit end;
  result:=true;
end;
procedure TAufScript.helper;
var i:word;
begin
  Self.writeln('函数列表:');
  for i:=0 to func_range-1 do begin
    if Self.func[i].name='' then break;
    Self.writeln(Usf.left_adjust(Self.func[i].name+' '+Self.func[i].parameter,16)+' '+Self.func[i].helper);
  end;
end;
procedure TAufScript.define_helper;
var i:word;
    tmp:TAufExpressionUnit;
begin
  Self.writeln('定义列表:');
  i:=0;
  while i<Self.Expression.Global.Count do
    begin
      tmp:=TAufExpressionUnit(Self.Expression.Global.Items[i]);
      Self.writeln('@'+Usf.left_adjust(tmp.key,16)+' = '+tmp.value.pre+tmp.value.arg+tmp.value.post);
      inc(i);
    end;
  i:=0;
  while i<Self.Expression.Local.Count do
    begin
      tmp:=TAufExpressionUnit(Self.Expression.Local.Items[i]);
      Self.writeln('@'+Usf.left_adjust(tmp.key,16)+' = '+tmp.value.pre+tmp.value.arg+tmp.value.post);
      inc(i);
    end;

end;
procedure TAufScript.write(str:string);
begin
  Self.IO_fptr.print(Self,str);
end;
procedure TAufScript.writeln(str:string);
begin
  Self.IO_fptr.echo(Self,str);
end;
procedure TAufScript.readln;
begin
  Self.IO_fptr.pause(Self);
end;
procedure TAufScript.send_error(str:string);
begin
  Self.writeln('');
  Self.writeln('[In "'+Self.ScriptName+'" Line ' + IntToStr(Self.CurrentLine+1)+ '] '+Self.ScriptLines[Self.currentline]);
  Self.writeln(str);
  if Self.PSW.run_parameter.error_raise then begin
    Self.Func_process.mid(Self);
    Self.Stop;
  end;
end;
procedure TAufScript.ClearScreen;
begin
  Self.IO_fptr.clear(Self);
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

end;

procedure TAufScript.line_transfer;//将当前行代码转译成标准形式
var i:0..args_range;
    line:dword;
    ts1,ts2:string;
    idx1,idx2:integer;
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
                AAuf.nargs[i].arg:=DwordToRawStr(line);
              end
            else
              begin
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
                AAuf.nargs[i].arg:=DwordToRawStr(ExpToDword(ts2))+'|'+pRamToRawStr(ExpToDword(ts1) mod (High(pRam)+1){256});
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
                AAuf.nargs[i].arg:=DwordToRawStr(ExpToDword(ts2))+'|'+pRamToRawStr(ExpToDword(ts1) mod (High(pRam)+1){256});
              end
            else
              begin
                //暂时保留原始的@0 ~32 $12的不带[]{}的表达
              end;
          end;
        '@':
          begin
            case AAuf.nargs[i].arg of
              'current_line':AAuf.nargs[i]:=narg('',IntToStr(Self.PSW.run_parameter.current_line_number),'');
              'prev_line':AAuf.nargs[i]:=narg('',IntToStr(Self.PSW.run_parameter.current_line_number-1),'');
              'next_line':AAuf.nargs[i]:=narg('',IntToStr(Self.PSW.run_parameter.current_line_number+1),'');
              'ram_zero':AAuf.nargs[i]:=narg('',DwordToRawStr(Dword(Self.PSW.run_parameter.ram_zero)),'');
              'ram_size':AAuf.nargs[i]:=narg('',IntToStr(Self.PSW.run_parameter.ram_size),'');
              'error_raise':AAuf.nargs[i]:=narg('',BoolToStr(Self.PSW.run_parameter.error_raise),'');
              else case AAuf.nargs[i].arg[1] of
                '0'..'9':;
                'a'..'z','A'..'Z','_':
                  begin
                    tmp_nargs:=Self.Expression.Local.Translate(AAuf.nargs[i].arg);
                    if tmp_nargs.arg='~Error' then tmp_nargs:=Self.Expression.Global.Translate(AAuf.nargs[i].arg);
                    if tmp_nargs.arg<>'~Error' then AAuf.nargs[i]:=tmp_nargs;
                  end;
              end;
            end;
          end;
      end;
      AAuf.args[i]:=AAuf.nargs[i].pre+AAuf.nargs[i].arg+AAuf.nargs[i].post;
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

procedure TAufScript.send(msg:UINT);
begin
  {$ifdef TEST_MODE}SysWriteln('AufScript.send '+IntToHex(Self.Control.Handle,8)+' '+IntToStr(int64(Self)));{$endif}
  Postmessage(Self.Control.Handle,msg,int64(@Self),0);
  //Self.Control.Perform(msg,int64(@Self),0);//这个是等同于sendmessage的同步消息，不可用
end;

procedure TAufScript.Pause;//人为暂停
begin
  if Self.Time.Synthesis_Mode = SynMoDelay then raise Exception.Create('命令行模式AufScript不能人为暂停或恢复');
  if Self.PSW.pause then exit;
  Self.PSW.pause:=true;
  WITH Self.Time DO BEGIN
  if Synthesis_Mode = SynMoTimer then
    case TimerPause of
      true:Timer.Enabled:=false;
      false:;
    end;
  END;
  Self.Func_process.OnPause(Self);
end;
procedure TAufScript.Resume;//人为继续
begin
  if Self.Time.Synthesis_Mode = SynMoDelay then raise Exception.Create('命令行模式AufScript不能人为暂停或恢复');
  if not Self.PSW.pause then exit;
  Self.Func_process.OnResume(Self);
  Self.PSW.pause:=false;
  WITH Self.Time DO BEGIN
  if Synthesis_Mode = SynMoTimer then
    case TimerPause of
      true:Timer.Enabled:=true;
      false:Self.send(AufProcessControl_RunNext);
    end;
  END;
end;
procedure TAufScript.Stop;//人为中止
begin
  if Self.Time.Synthesis_Mode = SynMoDelay then raise Exception.Create('命令行模式AufScript不能人为中止');
  //if not Self.PSW.haltoff then exit;
  //if Self.PSW.pause then Self.Resume;
  Self.send(AufProcessControl_RunClose);
end;
procedure TAufScript.RunFirst;//代码执行初始化
begin
  //Self.writeln('RunFirst');
  PSW.run_parameter.current_strings:=ScriptLines;
  Self.Func_process.beginning(Self);//预设的开始过程
  Self.Time.TimerPause:=false;
  IF Self.Time.Synthesis_Mode = SynMoTimer THEN BEGIN
    //使用Self.Control的消息来激活下一个过程
    Self.send(AufProcessControl_RunNext);
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
  procedure DoRunClose;
  begin
      IF Self.Time.Synthesis_Mode = SynMoTimer THEN BEGIN
        Self.send(AufProcessControl_RunClose);
      END ELSE BEGIN
        Self.PSW.haltoff:=true;
      END;
  end;
  procedure DoRunNext;
  var tmp_msg:TMsg;
  begin
      IF Self.Time.Synthesis_Mode = SynMoTimer THEN BEGIN
        //repeat until not PeekMessage(tmp_msg,Self.Control.Handle,0,0,PM_REMOVE);
        Self.send(AufProcessControl_RunNext);
      END ELSE BEGIN
        //DO NOTHING
      END;
  end;

begin
  {$ifdef TEST_MODE}SysWriteln('AufScript.RunNext.Auf='+IntToHex(int64(Self.Auf),8));{$endif}
  {$ifdef TEST_MODE}SysWriteln('AufScript.RunNext.AufScpt='+IntToHex(int64(Self),8));{$endif}
  AAuf:=Self.Auf as TAuf;
  if Self.PSW.haltoff or Self.PSW.pause then exit;
  if Self.currentline < ScriptLines.count then begin
    //读取栈中地址的指令
    cmd:=ScriptLines.strings[Self.currentline];
    Self.PSW.run_parameter.current_line_number:=currentline;
    Self.PSW.run_parameter.prev_line_number:=Self.PSW.run_parameter.current_line_number-1;
    Self.PSW.run_parameter.next_line_number:=Self.PSW.run_parameter.current_line_number+1;
    Self.Func_process.pre(Self);//预设的前置过程
    Self.PSW.inRunNext:=true;//过程保护，阻挡新的RunNext消息
    {$ifdef TEST_MODE}SysWriteln('                                 AufScript.RunNext-IN  -> Line '+IntToStr(currentline));{$endif}

    //自定义函数执行部分
    AAuf.ReadArgs(cmd);
    if AAuf.args[0]<>'' then begin
    if ((AAuf.args[0][1]<>'/') or (AAuf.args[0][2]<>'/')) and (AAuf.nargs[0].arg<>'') and (AAuf.nargs[0].post<>':') then
      begin
        Self.line_transfer;//转化为标准形态
        Self.run_func(AAuf.args[0]);
      end;
    end;
    if Self.PSW.haltoff then begin DoRunClose;exit end;

    //安排下一个地址
    Self.next_addr;

    Self.PSW.inRunNext:=false;//取消过程保护，允许新的RunNext消息
    {$ifdef TEST_MODE}SysWriteln('                                 AufScript.RunNext-OUT -> Line '+IntToStr(currentline));{$endif}
    Self.Func_process.post(Self);//预设的后置过程

    if (not Self.PSW.Pause) and (not Self.Time.TimerPause) and (not Self.PSW.haltoff) then DoRunNext;

  end
  else begin
    DoRunClose;
  end;
end;
procedure TAufScript.RunClose;//代码执行中止化
begin
  //Self.writeln('RunClose');
  Self.PSW.haltoff:=true;
  Self.PSW.pause:=false;
  IF Self.Time.Synthesis_Mode=SynMoTimer THEN BEGIN
    Self.Time.TimerPause:=false;
    Self.Time.Timer.Enabled:=false;
  END;
  Self.Func_process.ending(Self);//预设的结束过程
end;


procedure TAufScript.command(str:TStrings);
var i:dword;
    cmd:string;
    line_tmp:dword;
begin
  if str.count = 0 then begin Self.Func_process.ending(Self);exit end;
  {$ifdef command_detach}
  Self.PSW_reset;
  Self.ScriptLines:=TStringList.Create;
  Self.ScriptLines.Clear;
  for line_tmp:=0 to str.Count - 1 do
    begin
      {tmp}cmd:=str.Strings[line_tmp];
      IO_fptr.command_decode({tmp}cmd);
      Self.ScriptLines.Add({tmp}cmd);
    end;
  {$else}
  Self.ScriptLines:=str;
  for line_tmp:=0 to str.Count-1 do
    begin
      {tmp}cmd:=str.Strings[line_tmp];
      IO_fptr.command_decode({tmp}cmd);
      str.Strings[line_tmp]:={tmp}cmd;
    end;
  {$endif}

  {$define new_run}
  {$ifdef new_run}
  Self.RunFirst;
  {$else}
  Self.PSW_reset;
  PSW.run_parameter.current_strings:=Self.ScriptLines;

  Self.Func_process.beginning;//预设的开始过程

  while Self.currentline < Self.ScriptLines.count do begin
    //读取栈中地址的指令

    cmd:=Self.ScriptLines.strings[Self.currentline];

    (Self.Auf as TAuf).Script.PSW.run_parameter.current_line_number:=currentline;
    (Self.Auf as TAuf).Script.PSW.run_parameter.prev_line_number:=AufScpt.PSW.run_parameter.current_line_number-1;
    (Self.Auf as TAuf).Script.PSW.run_parameter.next_line_number:=AufScpt.PSW.run_parameter.current_line_number+1;

    Self.Func_process.pre;//预设的前置过程

    //自定义函数执行部分
    (Self.Auf as TAuf).ReadArgs(cmd);
    if (Self.Auf as TAuf).args[0]<>'' then begin
    if (((Self.Auf as TAuf).args[0][1]<>'/') or ((Self.Auf as TAuf).args[0][2]<>'/')) and ((Self.Auf as TAuf).nargs[0].arg<>'') and ((Self.Auf as TAuf).nargs[0].post<>':') then
      begin
        Self.line_transfer;//转化为标准形态
        Self.run_func((Self.Auf as TAuf).args[0]);
      end;
    end;
    Self.Func_process.post;//预设的后置过程

    if Self.PSW.haltoff then break;

    //安排下一个地址
    {if not Self.PSW.jump then }Self.next_addr
    {else Self.PSW.jump:=false};
  end;

  Self.Func_process.ending;//预设的结束过程
  {$endif}

  {$ifdef command_detach}
  if Self.PSW.haltoff then Self.ScriptLines.Free;
  {$endif}

end;
procedure TAufScript.command(str:string);
var scpt:TStringList;
begin
  scpt:=TStringList.Create;
  scpt.add(str);
  command(scpt);
  scpt.Destroy;
end;
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
  Self.Control.FAuf:=Self.Auf as TAuf;
  Self.Control.FAufScpt:=Self as TAufScript;
end;


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
      if tmp.readonly then raise Exception.Create('不能修改只读表达式')
      else tmp.value:=AValue;
    end;
end;
function TAufExpressionList.TryRenameExp(OldKey,NewKey:string):boolean;
var tmp:TAufExpressionUnit;
begin
  tmp:=Self.Find(OldKey);
  if tmp=nil then
    begin
      raise Exception.Create('不能给不存在的表达式更名')
    end
  else
    begin
      if tmp.readonly then raise Exception.Create('不能修改只读表达式')
      else tmp.key:=NewKey;
    end;
end;
procedure TAufTimer.OnTimerResume(Sender:TObject);
var auf:TAufScript;
begin
  auf:=(Sender as TAufTimer).AufScript as TAufScript;
  {$ifdef TEST_MODE}SysWriteln('##AufTimer.OnTimerResume -> Line '+IntToStr(auf.currentline));{$endif}
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
    {$ifdef TEST_MODE}SysWriteln('Control.RunFirst -> Line '+IntToStr(currentline));{$endif}
    RunFirst;
  end;
end;
procedure TAufControl.RunNext(var Msg:TMessage);
begin
  with {$ifdef ptr_flag}PAufScript(int64(Msg.wParam))^{$else}Self.FAufScpt as TAufScript{$endif} do begin
    {$ifdef TEST_MODE}SysWriteln('Control.RunNext -> Line '+IntToStr(currentline)+' bool:'+IntToStr(byte(PSW.inRunNext)));{$endif}
    if PSW.inRunNext then begin
      //PostMessage(Self.Handle,Msg.msg,Msg.wParam,Msg.lParam);
      //Self.Perform(Msg.msg,Msg.wParam,Msg.lParam);
    end else RunNext;
  end;
end;
procedure TAufControl.RunClose(var Msg:TMessage);
begin
  with {$ifdef ptr_flag}PAufScript(int64(Msg.wParam))^{$else}Self.FAufScpt as TAufScript{$endif} do begin
    {$ifdef TEST_MODE}SysWriteln('Control.RunClose -> Line '+IntToStr(currentline));{$endif}
    RunClose;
  end;
end;
{$undef ptr_flag}

constructor TAufScript.Create(AOwner:TComponent);
var i:word;
begin
  inherited Create;

  Self.Version:=AufScript_Version;
  if AOwner<>nil then Self.SynAufSyn:=TSynAufSyn.Create(AOwner)
  else Self.SynAufSyn:=nil;

  if AOwner=nil then
    begin
      Time.Synthesis_Mode:=SynMoDelay;
    end
  else if (AOwner is TComponent) and Assigned(AOwner) then
    begin
      Time.Synthesis_Mode:=SynMoTimer;
      Self.Control:=TAufControl.Create{New}(AOwner);
      if AOwner is TCustomDesignControl then
        Self.Control.Parent:=AOwner as TWinControl
      else
        Self.Control.Parent:=(AOwner.Owner) as TWinControl;
      Self.TimerInitialization(Self.Control);
    end
  else
    begin
      raise Exception.Create('AufScript初始化错误，异常的Owner');
    end;
  Self.Owner:=AOwner;

  IO_fptr.echo:=@de_writeln;//默认的输出函数
  IO_fptr.print:=@de_write;//默认的不换行输出函数
  IO_fptr.error:=@de_writeln;//默认的错误报告函数
  IO_fptr.pause:=@de_readln;//默认的确认函数
  IO_fptr.clear:=@de_clearscreen;//默认的清屏函数
  IO_fptr.command_decode:=@de_decoder;//默认的转码函数

  Func_process.pre:=@de_nil;//默认的前驱过程
  Func_process.post:=@de_nil;//默认的后驱过程
  Func_process.mid:=@de_nil;//默认的防假死过程
  Func_process.beginning:=@de_nil;//默认的开始过程
  Func_process.ending:=@de_nil;//默认的结束过程
  Func_process.OnPause:=@de_nil;//默认的挂起过程
  Func_process.OnResume:=@de_nil;//默认的恢复过程

  var_stream:=TMemoryStream.Create;
  var_stream.SetSize(RAM_RANGE*256);
  PSW.run_parameter.ram_zero:=var_stream.Memory;
  PSW.run_parameter.ram_size:=RAM_RANGE*256;
  PSW.run_parameter.error_raise:=false;

  Expression.Global:=GlobalExpressionList;
  Expression.Local:=TAufExpressionList.Create;

  for i:=0 to func_range-1 do Self.func[i].name:='';
end;

procedure TAufScript.InternalFuncDefine;
begin
  Self.add_func('version',@_version,'','显示解释器版本号');
  Self.add_func('help',@_helper,'','显示帮助');
  Self.add_func('deflist',@_define_helper,'','显示定义列表');
  Self.add_func('ramex',@ramex,'','将内存导出到ram.var');
  Self.add_func('sleep',@_sleep,'n','等待n毫秒');
  Self.add_func('pause',@_pause,'','暂停');

  Self.add_func('hex',@hex,'var','输出标准变量形式的十六进制');
  Self.add_func('hexln',@hexln,'var','输出标准变量形式的十六进制并换行');
  Self.add_func('print',@print,'var','输出变量var');
  Self.add_func('println',@println,'var','输出变量var并换行');
  Self.add_func('echo',@echo,'str','输出字符串');
  Self.add_func('echoln',@echoln,'str','输出字符串并换行');
  Self.add_func('cwln',@cwln,'','换行');
  Self.add_func('clear',@_clear,'','清屏');

  Self.add_func('mov',@mov,'var,#','将#值赋值给var');
  Self.add_func('add',@add,'var,#','将var和#的值相加并返回给var');
  Self.add_func('sub',@sub,'var,#','将var和#的值相减并返回给var');
  Self.add_func('mul',@mul,'var,#','将var和#的值相乘并返回给var');
  Self.add_func('div',@div_,'var,#','将var和#的值相除并返回给var');
  Self.add_func('mod',@mod_,'var,#','将var和#的值求余并返回给var');
  Self.add_func('rand',@rand,'var,#','将不大于#的随机整数返回给var');
  Self.add_func('fill',@_fillbyte,'var,byte','用byte填充var');

  Self.add_func('jmp',@jmp,'ofs','跳转到相对地址');
  Self.add_func('call',@call,'ofs','跳转到相对地址，并将当前地址压栈');
  Self.add_func('ret',@_ret,'','从栈中取出一个地址，并跳转至该地址');
  Self.add_func('load',@_load,'filename','加载运行指定脚本文件');
  Self.add_func('fend',@_fend,'','从加载的脚本文件中跳出');
  Self.add_func('halt',@_halt,'','无条件结束');
  Self.add_func('end',@_end,'','有条件结束，根据运行状态转译为ret, fend或halt');
  Self.add_func('define',@_define,'name,expression','定义一个以@开头的局部宏定义');
  Self.add_func('rendef',@_rendef,'oldname,newname','修改一个局部宏定义的名称');

  Self.add_func('cje',@cj,'var1,var2[,ofs=+2]','如果var1等于var2则跳转到相对地址');
  Self.add_func('ncje',@cj,'var1,var2[,ofs=-2]','如果var1不等于var2则跳转到相对地址');
  Self.add_func('cjm',@cj,'var1,var2[,ofs=+2]','如果var1大于var2则跳转到相对地址');
  Self.add_func('ncjm',@cj,'var1,var2[,ofs=-2]','如果var1不大于var2则跳转到相对地址');
  Self.add_func('cjl',@cj,'var1,var2[,ofs=+2]','如果var1小于var2则跳转到相对地址');
  Self.add_func('ncjl',@cj,'var1,var2[,ofs=-2]','如果var1不小于var2则跳转到相对地址');
  Self.add_func('cjec',@cj,'var1,var2[,ofs=+2]','如果var1等于var2则跳转到相对地址，并将当前地址压栈');
  Self.add_func('ncjec',@cj,'var1,var2[,ofs=-2]','如果var1不等于var2则跳转到相对地址，并将当前地址压栈');
  Self.add_func('cjmc',@cj,'var1,var2[,ofs=+2]','如果var1大于var2则跳转到相对地址，并将当前地址压栈');
  Self.add_func('ncjmc',@cj,'var1,var2[,ofs=-2]','如果var1不大于var2则跳转到相对地址，并将当前地址压栈');
  Self.add_func('cjlc',@cj,'var1,var2[,ofs=+2]','如果var1小于var2则跳转到相对地址，并将当前地址压栈');
  Self.add_func('ncjlc',@cj,'var1,var2[,ofs=-2]','如果var1不小于var2则跳转到相对地址，并将当前地址压栈');


  {$ifdef TEST_MODE}
  Self.add_func('debugln',@_debugln,'var','调试函数');
  Self.add_func('pause_resume',@_pause_resume,'','暂停后立刻继续');
  Self.add_func('test',@_test,'var','临时的函数');
  {$endif}

  AdditionFuncDefine_Text;
  AdditionFuncDefine_Time;
  AdditionFuncDefine_File;
  AdditionFuncDefine_Math;


end;

procedure TAufScript.AdditionFuncDefine_Text;
begin
  Self.add_func('str',@text_str,'#[],var','将var转化成字符串存入#[]');
  Self.add_func('val',@text_val,'$[],str','将str转化成数值存入$[]');

end;
procedure TAufScript.AdditionFuncDefine_Time;
begin
  Self.add_func('gettimestr',@time_gettimestr,'var','显示当前时间字符串或存入字符变量var中');
  Self.add_func('getdatestr',@time_getdatestr,'var','显示当前日期字符串或存入字符变量var中');

  Self.add_func('settimer',@time_settimer,'','初始化计时器');
  Self.add_func('gettimer',@time_gettimer,'var','获取计时器度数');
  Self.add_func('waittimer',@time_waittimer,'var','等待计时器达到var');

end;
procedure TAufScript.AdditionFuncDefine_File;
begin

end;
procedure TAufScript.AdditionFuncDefine_Math;
begin
  //Self.add_func('ln',@math_ln,'var','自然对数');
  //Self.add_func('exp',@math_exp,'var','指数函数');
  //Self.add_func('sqrt',@math_sqrt,'var[,index=2]','开方');
  //Self.add_func('pow',@math_pow,'var[,index=2]','幂运算');

  Self.add_func('cmp',@math_logic_cmp,'var1,var2','比较');
  Self.add_func('shl',@math_logic_shl,'var,bit',  '左移');
  Self.add_func('shr',@math_logic_shr,'var,bit',  '右移');
  Self.add_func('not',@math_logic_not,'var',      '位非');
  Self.add_func('and',@math_logic_and,'var1,var2','位与');
  Self.add_func('or', @math_logic_or, 'var1,var2','位或');
  Self.add_func('xor',@math_logic_xor,'var1,var2','异或');

  {
  Self.add_func('h_add',@math_h_arithmetic,'#[],#[]','高精加');
  Self.add_func('h_sub',@math_h_arithmetic,'#[],#[]','高精减');
  Self.add_func('h_mul',@math_h_arithmetic,'#[],#[]','高精乘');
  Self.add_func('h_div',@math_h_arithmetic,'#[],#[]','高精整除');
  Self.add_func('h_mod',@math_h_arithmetic,'#[],#[]','高精求余');
  Self.add_func('h_divreal',@math_h_arithmetic,'#[],#[]','高精实数除');
  }
  Self.add_func('h_add',@math_hr_arithmetic,'#[],#[]','高精加');
  Self.add_func('h_sub',@math_hr_arithmetic,'#[],#[]','高精减');
  Self.add_func('h_mul',@math_hr_arithmetic,'#[],#[]','高精乘');
  //Self.add_func('h_div',@math_hr_arithmetic,'#[],#[]','高精整除');
  //Self.add_func('h_mod',@math_hr_arithmetic,'#[],#[]','高精求余');
  Self.add_func('h_divreal',@math_hr_arithmetic,'#[],#[]','高精实数除');



end;

//////Class Methods end

INITIALIZATION

  Auf:=TAuf.Create(nil);
  Auf.Script.InternalFuncDefine;
  GlobalExpressionList:=TAufExpressionList.Create;
  //这个是共用的，所有AufScript.Expression.Global都应该赋值这个
  GlobalExpressionList.TryAddExp('AufScriptAuthor',narg('"','Apiglio&Apemiro','"'));
  GlobalExpressionList.TryAddExp('AufScriptVersion',narg('"',AufScript_Version,'"'));

  Usf:=TUsf.Create;





  //RegisterTest(TAuf);



END.

