UNIT Apiglio_Useful;

{$mode objfpc}{$H+}
{$goto on}
{$M+}
{$TypedAddress off}

{$define command_detach}

INTERFACE

uses
  Windows, Classes, SysUtils, Registry, Dos, WinCrt, FileUtil, Forms, Controls, StdCtrls, ExtCtrls, Interfaces,
  Auf_Ram_Var;
  //Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls, Dos,
  //ExtCtrls, Windows, Wincrt

const
  c_divi=[' ',','];//隔断符号
  c_iden=['~','@','$','#','?',':','&'];//变量符号，前后缀符号
  c_toto=c_divi+c_iden;
  ram_range=32;//变量区大小
  stack_range=32;//行数堆栈区大小，最多支持256个
  func_range=256;//函数区大小，最多支持65536个
  args_range=16;//函数参数最大数量

  //Msg_RunNext = WM_USER + 199;
  AufProcessControl_RunFirst = WM_USER + 19950;
  AufProcessControl_RunNext = WM_USER + 19951;
  AufProcessControl_RunClose = WM_USER + 19952;


type

  {Usf  工具库}
  //TFileByte= file of byte;
  pFuncFileByte= procedure(str:string);
  TUsf= class
    private
      str_buffer:string;//ExPChar使用的全局变量
    public{|protected}
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

  ACBase = TForm{TWinControl};
  TAufControl=class(ACBase)
      constructor Create(AOwner:TComponent);
    public
      procedure RunFirst(var Msg:TMessage);message AufProcessControl_RunFirst;
      procedure RunNext(var Msg:TMessage);message AufProcessControl_RunNext;
      procedure RunClose(var Msg:TMessage);message AufProcessControl_RunClose;
      class function ClassType:String;
  end;

  //用于AufScript的内存读取和计算

  {TAufScript}
  pFunc      = procedure;
  pFuncStr   = procedure(str:string);
  pFuncVarStr= procedure(var str:string);
  PAufScript = ^TAufScript;
  TAufScript = class
    protected
      {
      var_list:array[0..ram_range-1]of record case vType:(vtByte=1,vtLong=2,vtDouble=3,vtStr=4,vtSubstr=5) of
        vtByte:(Byte:array[0..255]of byte);
        vtLong:(Long:array[0..63]of longint);
        vtDouble:(Double:array[0..31]of double);
        vtStr:(Str:string[255]);
        vtSubStr:(SubStr:array[0..31]of string[8]);
      end;
      }
      var_stream:TMemoryStream;
    protected
      procedure SetLine(l:dword);
      procedure SetByte(Index:word;byt:byte);
      procedure SetLong(Index:word;lng:longint);
      procedure SetDouble(Index:word;dbl:double);
      procedure SetStr(Index:word;str:string);
      procedure SetSubStr(Index:word;str:string);
      function GetLine:dword;
      function GetByte(Index:word):byte;
      function GetLong(Index:word):longint;
      function GetDouble(Index:word):double;
      function GetStr(Index:word):string;
      function GetSubStr(Index:word):string;
      function PtrByte(Index:word):pbyte;
      function PtrLong(Index:word):plongint;
      function PtrDouble(Index:word):pdouble;
      function PtrStr(Index:word):pstring;
      function PtrSubStr(Index:word):pstring;

      function GetArgLine:string;

      //
    public //时间同步过程
      Time:record
        Timer:TTimer;
        TimerPause:boolean;
        Synthesis_Mode:(SynMoDelay=0,SynMoTimer=1);
      end;
      Control:TAufControl;
      Owner:TComponent;//用于附着在窗体上，与Auf相同

      //procedure TimerInitialization(var ATimer:TTimer);//初始化计时器模式，需要外部计时器定义
      procedure TimerInitialization(var AControl:TAufControl);//新款
      procedure send(msg:UINT);

      //Handle:hwnd;
      //procedure WndProc(var Msg:TMessage);

    public
      ScriptLines:TStrings;

      PSW:record
        stack:array[0..stack_range-1]of record
          //filename:string;
          line:dword;//当前行数，在读指令阶段是当前指令，指令结束阶段就是下一个要读的行
          //这意味着上一个地址出栈后读取当前元素地址继续执行
          //上一行注释未必有效，参见TAufScript.command和TAufScript.PSW.jump
        end;
        stack_ptr:byte;//PSW.stack[stack_ptr].line就是next_line,就是属性中的CurrentLine
        fileptr:text;
        jump:boolean;//是否手动安排下一次地址，生效后立即置否
        haltoff,pause:boolean;

        run_parameter:record
          current_line_number:word;//当前行号
          next_line_number:word;//下一行
          prev_line_number:word;//上一行

          current_strings:TStrings;//当前代码所在TStrings
          ram_zero:pbyte;//内存零点
          ram_size:word;//内存大小

          mid_fresh_time:word;//防假死的刷新时间

        end;

        calc:record
          YC:boolean;//位溢出标识
        end;
        //
      end;
      Func:array[0..func_range-1]of record
        name:ansistring;
        func_ptr:pFunc;
        helper:string;
      end;
      IO_fptr:record
        echo:pFuncStr;//相当于writeln(str:string);
        print:pFuncStr;//相当于write(str:string);
        error:pFuncStr;//相当于writeln(str:string);
        pause:pFunc;//相当于readln;
        command_decode:pFuncVarStr;//在GUI模式中使用utf8编码时需要设置转码函数
      end;
      Func_process:record
        pre,post,mid:pFunc;//执行单条指令前后的额外过程和中途防假死预留
        beginning,ending:pFunc;//执行整段代码前后的额外过程
      end;

      property currentline:dword read GetLine write SetLine;//当前行数
      property ArgLine:string read GetArgLine;

      property poByte[Index:word]:pbyte read PtrByte;
      property poLong[Index:word]:plongint read PtrLong;
      property poDouble[Index:word]:pdouble read PtrDouble;
      property poStr[Index:word]:pstring read PtrStr;
      property poSubStr[Index:word]:pstring read PtrSubStr;

      property vByte[Index:word]:byte read GetByte write SetByte;
      property vLong[Index:word]:longint read GetLong write SetLong;
      property vDouble[Index:word]:double read GetDouble write SetDouble;
      property vStr[Index:word]:string read GetStr write SetStr;
      property vSubStr[Index:word]:string read GetSubStr write SetSubStr;

    published

      procedure send_error(str:string);
      function Pointer(Iden:string;Index:word):Pointer;
      function RamVar(arg:Tnargs):TAufRamVar;//将标准变量形式转化成ARV
      function to_double(Iden,Index:string):double;//将nargs[].pre和nargs[].arg表示的变量转换成double类型
      function to_string(Iden,Index:string):string;//将nargs[].pre和nargs[].arg表示的变量转换成string类型

      function syntax_to_double(arg:Tnargs):double;
      function syntax_to_dword(arg:Tnargs):dword;
      function syntax_to_string(arg:Tnargs):string;

      procedure ram_export;//将整个内存区域打印到文件
      procedure add_func(func_name:ansistring;func_ptr:pFunc;helper:string);
      procedure run_func(func_name:ansistring);
      function have_func(func_name:ansistring):boolean;
      procedure helper;
      procedure HaltOff;
      procedure PSW_reset;
      procedure line_transfer;//将当前行代码转译成标准形式
      //procedure jump_next;//下一步不进行自动递进地址，改为由函数确定，需要在函数定义中配合jump_addr|pop_addr|push_addr使用
      procedure next_addr;
      procedure jump_addr(line:dword);//跳转绝对地址
      procedure offs_addr(offs:longint);//跳转偏移地址
      procedure pop_addr;
      procedure push_addr({filename:string;}line:dword);

      procedure Pause;//人为暂停
      procedure Resume;//人为继续
      procedure Stop;//人为中止

      procedure RunFirst;//代码执行初始化
      procedure RunNext(Sender:TObject);//代码执行的循环体
      procedure RunClose;//代码执行中止化

      procedure command(str:TStrings);overload;
      procedure command(str:string);overload;

      constructor Create(AOwner:TComponent);
      procedure InternalFuncDefine;
      //destructor Destroy;override;
      //
  end;


  {Auf  与Auf Script有关的内容}
  TAuf = class
    public
      args:array[0..args_range-1]of string;//ReadArgs的输出结果
      ArgsCount:byte;
      divi,iden,toto:string;
      nargs:packed array[0..args_range-1]of Tnargs;
      Script:TAufScript;
      //procedure TestHookUp;
      procedure ReadArgs(ps:string);//将字符串按照隔断符号和变量符号分离出多个参数
      //pByte('@12'):=223;
      //byt:=pByte('@14');
      constructor Create(AOwner:TComponent=nil);
    public
      Owner:TComponent;//用于附着在窗体上，命令行调用则为nil
  end;


var

  i:byte;
  Usf:TUsf;

  Auf:TAuf;
  //AufControl:TAufControl;
  //Func:TFunc;
  //pErrorTip:procedure(str:string);//用来更改GUI或console模式下的错误弹出方式

  //operator +(obj_list:TObjList,pProc:pIterator):boolean;

  procedure de_writeln(str:string);
  procedure de_write(str:string);
  procedure de_readln;
  procedure de_message(str:string);
  procedure de_nil;
  procedure de_decoder(var str:string);

  function isprintable(str:string):boolean;
  function DwordToRawStr(inp:dword):string;
  function RawStrToDword(str:string):dword;
  function ByteToRawStr(inp:byte):string;
  function RawStrToByte(str:string):byte;
  function HexToDword(exp:string):dword;
  function BinaryToDword(exp:string):dword;
  function ExpToDword(exp:string):dword;


IMPLEMENTATION
(*
procedure TAuf.TestHookUp;
begin
  Fail('Write your own test');
end;
*)


procedure de_decoder(var str:string);
begin
  //do nothing
end;

procedure de_write(str:string);
begin
  write(UTF8Toansi(str));
end;
procedure de_writeln(str:string);
begin
  de_write(str);
  writeln;
end;
procedure de_readln;
begin
  readln;
end;
procedure de_message(str:string);
begin
  MessageBox(0,Pchar(str),'Error',MB_OK);
end;
procedure de_nil;
begin
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

function ByteToRawStr(inp:byte):string;
begin
  result:='DD';
  result[1]:=chr(64+inp shr 4);
  result[2]:=chr(64+inp mod 16);

end;
function RawStrToByte(str:string):byte;
begin
  result:=0;
  result:=result+((ord(str[1])-64) shl 4);
  result:=result+(ord(str[2])-64);

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

constructor TAuf.Create(AOwner:TComponent=nil);
var i:byte;
begin
  inherited Create;
  Self.Script:=TAufScript.Create(AOwner);
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
var Rec:SearchRec;
  begin
    //非文件夹
    findfirst(path+'\*.*',$2F,Rec);
    while dosError=0 do begin
      //if need(path+'\'+Rec.name,Rec.size) then mov(path+'\'+Rec.name);
      func_ptr(path+'\'+Rec.name);

      findnext(Rec);
    end;
    findclose(Rec);
    //文件夹递归
    findfirst(path+'\*',$10,Rec);
    while dosError=0 do begin
      if (Rec.name<>'.')and(Rec.name<>'..') then each_file(path+'\'+Rec.name,func_ptr);
      findnext(Rec);
    end;
    findclose(Rec);
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
  assignfile(FileByte[i].fptr,address);//FileByte[255].fptr在文件打开的情况下变更会导致错误
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


//TAufScript

{
procedure TAufScript.WndProc(var Msg:TMessage);
begin
  {Result := }DefWindowProc(Self.Handle, Msg.msg, Msg.wParam, Msg.lParam);
end;
}

function TAufScript.PtrByte(Index:word):pbyte;
var dv,md:byte;
begin
  result:=var_stream.Memory+index;
end;

function TAufScript.PtrLong(Index:word):plongint;
var dv,md:byte;
begin
  result:=var_stream.Memory+Index;
end;
function TAufScript.PtrDouble(Index:word):pdouble;
var dv,md:byte;
begin
  result:=var_stream.Memory+Index;
end;
function TAufScript.PtrStr(Index:word):pstring;deprecated;
begin
  result:=var_stream.Memory+Index;
end;
function TAufScript.PtrSubStr(Index:word):pstring;deprecated;
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
function TAufScript.GetByte(Index:word):byte;inline;
begin
  result:=PtrByte(index)^;
end;
procedure TAufScript.SetByte(Index:word;byt:byte);inline;
begin
  PtrByte(index)^:=byt;
end;
function TAufScript.GetLong(Index:word):longint;inline;
begin
  result:=PtrLong(index)^;
end;
procedure TAufScript.SetLong(Index:word;lng:longint);inline;
begin
  PtrLong(index)^:=lng;
end;
function TAufScript.GetDouble(Index:word):double;inline;
begin
  result:=PtrDouble(index)^;
end;
procedure TAufScript.SetDouble(Index:word;dbl:double);inline;
begin
  PtrDouble(index)^:=dbl;
end;
function TAufScript.GetStr(Index:word):string;inline;deprecated;
begin
  result:=PtrStr(index)^;
end;
procedure TAufScript.SetStr(Index:word;str:string);inline;deprecated;
begin
  PtrStr(index)^:=str;
end;
function TAufScript.GetSubStr(Index:word):string;inline;deprecated;
begin
  result:=PtrSubStr(index)^;
end;
procedure TAufScript.SetSubStr(Index:word;str:string);inline;deprecated;
begin
  PtrSubStr(index)^:=str;
end;

function TAufScript.GetArgLine:string;
begin
  result:=Auf.args[0];
  for i:=1 to Auf.ArgsCount-1 do
    begin
      result:=result+' '+Auf.args[i];
    end;
end;

function TAufScript.RamVar(arg:Tnargs):TAufRamVar;//将标准变量形式转化成ARV  相对地址$"@@BB|@A"  绝对地址$&"@@BB|@A"
var s_addr,s_size:string;
    is_ref:boolean;
begin
  case arg.pre of
    '$"':begin result.VarType:=ARV_FixNum;is_ref:=false end;
    '~"':begin result.VarType:=ARV_Float;is_ref:=false end;
    '#"':begin result.VarType:=ARV_Char;is_ref:=false end;
    '$&"':begin result.VarType:=ARV_FixNum;is_ref:=true end;
    '~&"':begin result.VarType:=ARV_Float;is_ref:=true end;
    '#&"':begin result.VarType:=ARV_Char;is_ref:=true end;

    else {raise Exception.Create('未知的变量类型')}begin Auf.Script.IO_fptr.error('TAufScript.RamVar: arg.pre "'+arg.pre+'"');exit end;
  end;

  s_addr:=arg.arg;
  s_size:=arg.arg;
  delete(s_size,1,pos('|',s_size));
  delete(s_addr,pos('|',s_addr),999);
  result.size:=RawStrToByte(s_size);
  if result.size=0 then result.size:=4;
  result.head:=pbyte(RawStrToDWord(s_addr));

  if is_ref then
    begin
      result.Head:=pbyte(pdword(result.Head+dword(Auf.Script.PSW.run_parameter.ram_zero))^);
    end;

  //Auf.Script.IO_fptr.echo('size="'+s_size+'" head="'+s_addr+'"');
  //Auf.Script.IO_fptr.echo('size='+IntToStr(result.size)+' head='+IntToStr(dword(result.head)));

  if arg.post[length(arg.post)]<>arg.pre[1] then result.head:=result.head+dword(Auf.Script.PSW.run_parameter.ram_zero);

  result.Is_Temporary:=false;
  result.Stream:=nil;

end;

function TAufScript.syntax_to_double(arg:Tnargs):double;
var stmp:string;
    len,let:integer;
begin
  case arg.pre of
    '~&"','~"','#&"','#"','$"','$&"':begin result:=arv_to_double(Self.RamVar(arg));exit end;
    '"':try
          result:=StrToFloat(arg.arg);exit
        except
          result:=0;Auf.Script.IO_fptr.error('syntax_to_double error: string_to_double');exit
        end;
    '':;
    else begin Auf.Script.IO_fptr.error('syntax_to_double error: unexpected arg.pre "'+arg.pre+'"');exit end;
  end;
  stmp:=arg.arg;
  len:=length(stmp);
  result:=0;
  case arg.arg[len] of
    'H','h':
      begin
        delete(stmp,len,1);
        while stmp<>'' do
          begin
            //let:=length(stmp);
            result:=result*16;
            case stmp[1] of
              '1'..'9':result:=result+ord(stmp[1])-ord('0');
              'A'..'F':result:=result+ord(stmp[1])+10-ord('A');
              'a'..'f':result:=result+ord(stmp[1])+10-ord('a');
            end;
            delete(stmp,1,1);
          end;
      end;
    'B','b':
      begin
        delete(stmp,len,1);
        while stmp<>'' do
          begin
            //let:=length(stmp);
            result:=result*2;
            case stmp[1] of '1':result:=result+1 end;
            delete(stmp,1,1);
          end;
      end;
    else
      begin
        let:=0;
        val(stmp,result,let);
        if let<>0 then Auf.Script.IO_fptr.error('syntax_to_double error: unexpected arg.arg for decimal');
      end;
  end;
end;
function TAufScript.syntax_to_dword(arg:Tnargs):dword;
begin
  Auf.Script.IO_fptr.error('暂不支持syntax_to_dword');
end;
function TAufScript.syntax_to_string(arg:Tnargs):string;
begin
  Auf.Script.IO_fptr.error('暂不支持syntax_to_string');
end;

function TAufScript.Pointer(Iden:string;Index:word):Pointer;//这里要注意pointer类型的可变
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
    value:word;
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
        result:=arv_to_dword(Auf.Script.RamVar(tmp_narg));
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
    value:word;
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
var ex:file of byte;
    i,j:word;
begin
  assign(ex,'ram.var');
  try
    rewrite(ex);
  except
    Self.send_error('警告：文件写入失败！请检查ram.var文件是否被占用。');
    exit;
  end;
    for i:=0 to ram_range-1 do begin
      for j:=0 to 255 do begin
        seek(ex,i*256+j);
        write(ex,Self.vByte[i*256+j]);
      end;
    end;
    close(ex);
end;

procedure TAufScript.add_func(func_name:ansistring;func_ptr:pFunc;helper:string);
var i:word;
begin
  for i:=0 to func_range-1 do if Self.func[i].name='' then break;
  if (i=func_range-1) and (Self.func[i].name<>'') then begin Self.send_error('错误：函数列表已满，不能继续添加新的函数！');Self.IO_fptr.pause;halt end;
  Self.func[i].name:=func_name;
  Self.func[i].helper:=helper;
  Self.func[i].func_ptr:=func_ptr;
end;
procedure TAufScript.run_func(func_name:ansistring);
var i:word;
begin
  if func_name='' then begin Self.IO_fptr.echo('');exit end;;
  for i:=0 to func_range-1 do if Self.func[i].name=func_name then break;
  if (i=func_range-1) and (Self.func[i].name<>func_name) then begin Self.send_error('警告：未找到函数'+func_name+'！');exit end;
  Self.func[i].func_ptr;
end;
function TAufScript.have_func(func_name:ansistring):boolean;
var i:word;
begin
  if func_name='' then begin Self.IO_fptr.echo('');exit end;;
  for i:=0 to func_range-1 do if Self.func[i].name=func_name then break;
  if (i=func_range-1) and (Self.func[i].name<>func_name) then begin result:=false;exit end;
  result:=true;
end;
procedure TAufScript.helper;
var i:word;
begin
  Self.IO_fptr.echo('函数列表:');
  for i:=0 to func_range-1 do begin
    if Self.func[i].name='' then break;
    Self.IO_fptr.echo(Self.func[i].name+' '+Self.func[i].helper);
  end;
end;

procedure TAufScript.send_error(str:string);
begin
  Self.IO_fptr.echo('[In Line ' + Usf.i_to_s(Self.CurrentLine)+ ']'+str);
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
  end;
  Self.PSW.stack_ptr:=0;
  Self.PSW.haltoff:=false;
  Self.PSW.pause:=false;

  Self.PSW.calc.YC:=false;

end;

procedure TAufScript.line_transfer;//将当前行代码转译成标准形式
var i:0..args_range;
    line:dword;
    ts1,ts2:string;
    idx1,idx2:integer;
begin
  for i:=0 to Auf.ArgsCount-1 do
    begin
      case Auf.nargs[i].pre of
        ':':
          begin
            //:loo :a :aaa
            line:=0;
            while line < PSW.run_parameter.current_strings.Count-1 do
              begin
                if non_space(PSW.run_parameter.current_strings.Strings[line]) = Auf.nargs[i].arg+':' then break;
                inc(line);
              end;
            if line <> PSW.run_parameter.current_strings.Count then
              begin
                Auf.nargs[i].pre:='&"';
                Auf.nargs[i].post:='"';
                Auf.nargs[i].arg:=DwordToRawStr(line);
              end
            else
              begin
                Auf.nargs[i].pre:='?"';
                Auf.nargs[i].post:='"';
                Auf.nargs[i].arg:='~Error';
              end;
          end;
        '~','$','#':
          begin
            //$4[0] $2[64] ~8[64] ~8{0} $4{16} -> $"@@@@@@@@|@D" $"@@@@@@B@|@B" ~"@@@@@@B@|@H" ~&"@@@@@@@@|@H" $&"@@@@@@@P|@D"
            idx1:=pos('[',Auf.nargs[i].arg);
            idx2:=pos('{',Auf.nargs[i].arg);
            if idx1>0 then
              begin
                Auf.nargs[i].pre:=Auf.nargs[i].pre+'"';
                Auf.nargs[i].post:='"';
                ts1:=Auf.nargs[i].arg;
                ts2:=Auf.nargs[i].arg;
                delete(ts1,idx1,9999);
                delete(ts2,1,idx1);
                if ts2[length(ts2)]=']' then delete(ts2,length(ts2),1);
                Auf.nargs[i].arg:=DwordToRawStr(ExpToDword(ts2))+'|'+ByteToRawStr(ExpToDword(ts1) mod 256);
              end
            else if idx2>0 then
              begin
                Auf.nargs[i].pre:=Auf.nargs[i].pre+'&"';
                Auf.nargs[i].post:='"';
                ts1:=Auf.nargs[i].arg;
                ts2:=Auf.nargs[i].arg;
                delete(ts1,idx2,9999);
                delete(ts2,1,idx2);
                if ts2[length(ts2)]='}' then delete(ts2,length(ts2),1);
                Auf.nargs[i].arg:=DwordToRawStr(ExpToDword(ts2))+'|'+ByteToRawStr(ExpToDword(ts1) mod 256);
              end
            else
              begin
                //暂时保留原始的@0 ~32 $12的不带[]{}的表达
              end;
          end;
      end;
      Auf.args[i]:=Auf.nargs[i].pre+Auf.nargs[i].arg+Auf.nargs[i].post;
      //Auf.Script.send_error('[Auf.args[i]]='+Auf.args[i]);
    end;
  PSW.run_parameter.current_strings.Strings[PSW.run_parameter.current_line_number]:=Self.ArgLine;
  //Self.IO_fptr.echo(Self.ArgLine);
end;

{
procedure TAufScript.jump_next;inline;
begin
  Self.PSW.jump:=true;
end;
}
procedure TAufScript.next_addr;
begin
  //inc(Self.PSW.stack[Self.PSW.stack_ptr].line);
  currentline:=currentline+1;
end;
procedure TAufScript.jump_addr(line:dword);//跳转绝对地址
var pi:dword;
begin
  {
  if line > Self.PSW.stack[Self.PSW.stack_ptr].line then
    begin
      for pi:=2 to line - Self.PSW.stack[Self.PSW.stack_ptr].line do readln(Self.PSW.fileptr);
    end
  else
    begin
      reset(Self.PSW.fileptr);
      for pi:=1 to line do readln(Self.PSW.fileptr);        //注意！！！暂时还没有地址超界检验！！！
    end;
  }
  Self.currentline:=line-1;
end;
procedure TAufScript.offs_addr(offs:longint);//跳转偏移地址
begin
  jump_addr(Self.PSW.stack[Self.PSW.stack_ptr].line+offs);
end;
procedure TAufScript.pop_addr;
//var pi:dword;
begin
  if Self.PSW.stack_ptr=0 then
    begin
      Self.send_error('错误：[-1]超出栈范围！');
      //Self.IO_fptr.pause;
      Self.PSW.haltoff:=true;
    end;
  Self.currentline:=0;
  dec(Self.PSW.stack_ptr);
  Self.currentline:=Self.currentline;
end;
procedure TAufScript.push_addr({filename:string;}line:dword);
//var pi:dword;
begin
  if Self.PSW.stack_ptr=stack_range-1 then
    begin
      Self.send_error('错误：['+Usf.to_s(stack_range)+']超出栈范围！');
      //Self.IO_fptr.pause;
      Self.PSW.haltoff:=true;
    end;
  inc(Self.PSW.stack_ptr);
  Self.currentline:=line;
end;

//重大问题必须解决，一个是递归调用导致溢栈，一个是定时器造成累加情况随机

procedure TAufScript.send(msg:UINT);
begin
  //Postmessage(Self.Control.Handle,msg,int64(@Self),0);
  Self.Control.Perform(msg,int64(@Self),0);
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
end;
procedure TAufScript.Resume;//人为继续
begin
  if Self.Time.Synthesis_Mode = SynMoDelay then raise Exception.Create('命令行模式AufScript不能人为暂停或恢复');
  if not Self.PSW.pause then exit;
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
  Auf.Script.send(AufProcessControl_RunClose);
end;
procedure TAufScript.RunFirst;//代码执行初始化
begin
  //Self.IO_fptr.echo('RunFirst');
  Self.PSW_reset;
  PSW.run_parameter.current_strings:=ScriptLines;
  Self.Func_process.beginning;//预设的开始过程
  Self.Time.TimerPause:=false;
  IF Self.Time.Synthesis_Mode = SynMoTimer THEN BEGIN
    //使用Self.Control的消息来激活下一个过程
    Self.send(AufProcessControl_RunNext);
    exit;
  END ELSE BEGIN
    repeat
      Self.RunNext(nil);
    until Self.PSW.haltoff;
    Self.RunClose;
  END;
end;
procedure TAufScript.RunNext(Sender:TObject);//代码执行的循环体
var cmd:string;
  procedure DoRunClose;
  begin
      IF Self.Time.Synthesis_Mode = SynMoTimer THEN BEGIN
        Self.send(AufProcessControl_RunClose);
      END ELSE BEGIN
        Self.PSW.haltoff:=true;
      END;
  end;
  procedure DoRunNext;
  begin
      IF Self.Time.Synthesis_Mode = SynMoTimer THEN BEGIN
        Self.send(AufProcessControl_RunNext);
      END ELSE BEGIN
        //DO NOTHING
      END;
  end;

begin
  if Self.PSW.haltoff then exit;
  if Self.currentline < ScriptLines.count then begin
    //读取栈中地址的指令

    cmd:=ScriptLines.strings[Self.currentline];

    Auf.Script.PSW.run_parameter.current_line_number:=currentline;
    Auf.Script.PSW.run_parameter.prev_line_number:=Auf.Script.PSW.run_parameter.current_line_number-1;
    Auf.Script.PSW.run_parameter.next_line_number:=Auf.Script.PSW.run_parameter.current_line_number+1;

    Self.Func_process.pre;//预设的前置过程

    //自定义函数执行部分
    Auf.ReadArgs(cmd);
    if Auf.args[0]<>'' then begin
    if ((Auf.args[0][1]<>'/') or (Auf.args[0][2]<>'/')) and (Auf.nargs[0].arg<>'') and (Auf.nargs[0].post<>':') then
      begin
        Self.line_transfer;//转化为标准形态
        Self.run_func(Auf.args[0]);
      end;
    end;
    Self.Func_process.post;//预设的后置过程
    if Self.PSW.haltoff then begin DoRunClose;exit end;

    //安排下一个地址
    Self.next_addr;
    //SendMessage(Self.Handle,Msg_RunNext,0,0);
    if (not Self.PSW.Pause) and (not Self.Time.TimerPause) and (not Self.PSW.haltoff) then DoRunNext;
  end
  else begin
    DoRunClose;
  end;
end;
procedure TAufScript.RunClose;//代码执行中止化
begin
  //Self.IO_fptr.echo('RunClose');
  IF Self.Time.Synthesis_Mode=SynMoTimer THEN BEGIN
    Self.Time.TimerPause:=false;
    Self.Time.Timer.Enabled:=false;
  END;
  Self.Func_process.ending;//预设的结束过程
end;


procedure TAufScript.command(str:TStrings);
var i:dword;
    cmd:string;
    line_tmp:word;
begin
  {$ifdef command_detach}
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
      IO_fptr.command_decode(str.Strings[line_tmp]);
    end;
  {$endif}
  if Self.ScriptLines.Count=0 then Self.ScriptLines.Add('help');

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

    Auf.Script.PSW.run_parameter.current_line_number:=currentline;
    Auf.Script.PSW.run_parameter.prev_line_number:=Auf.Script.PSW.run_parameter.current_line_number-1;
    Auf.Script.PSW.run_parameter.next_line_number:=Auf.Script.PSW.run_parameter.current_line_number+1;

    Self.Func_process.pre;//预设的前置过程

    //自定义函数执行部分
    Auf.ReadArgs(cmd);
    if Auf.args[0]<>'' then begin
    if ((Auf.args[0][1]<>'/') or (Auf.args[0][2]<>'/')) and (Auf.nargs[0].arg<>'') and (Auf.nargs[0].post<>':') then
      begin
        Self.line_transfer;//转化为标准形态
        Self.run_func(Auf.args[0]);
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
{
procedure TAufScript.TimerInitialization(var ATimer:TTimer);
begin
  Self.Time.Timer:=ATimer;
  if not Assigned(ATimer) then raise Exception.Create('未初始化的Timer');
  Self.Time.Synthesis_Mode:=SynMoTimer;
  Self.Time.Timer.Enabled:=false;
  Self.Time.Timer.OnTimer:=@Self.RunNext;
end;
}
procedure TAufScript.TimerInitialization(var AControl:TAufControl);
begin
  //if Assigned(AControl) then exit;
  if not (AControl is TAufControl) then raise Exception.Create('TimerInitialization需要初始化的TAufControl对象');
  Self.Control:=AControl;
  if not Assigned(Self.Time.Timer) then Self.Time.Timer:=TAufTimer.Create(Self.Control.Owner,Self);
  Self.Time.Synthesis_Mode:=SynMoTimer;
  Self.Time.Timer.Enabled:=false;
end;

procedure TAufTimer.OnTimerResume(Sender:TObject);
var auf:TAufScript;
begin
  auf:=(Sender as TAufTimer).AufScript as TAufScript;
  auf.Time.TimerPause:=false;
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
  inherited Create(AOwner);
  if AOwner is ACBase then else raise Exception.Create('AOwner不是'+ACBase.ClassName);
  //Self.Parent:=AOwner as ACBase;
end;

class function TAufControl.ClassType:String;
begin
  result:='TAufControl';
end;

procedure TAufControl.RunFirst(var Msg:TMessage);
var ptr:PAufScript;
begin
  PAufScript(Msg.wParam)^.RunFirst;
end;
procedure TAufControl.RunNext(var Msg:TMessage);
begin
  PAufScript(Msg.wParam)^.RunNext(nil);
end;
procedure TAufControl.RunClose(var Msg:TMessage);
begin
  PAufScript(Msg.wParam)^.RunClose;
end;

constructor TAufScript.Create(AOwner:TComponent);
var i:word;
begin
  inherited Create;

  //Self.Handle := Classes.AllocateHWnd(@Self.WndProc);
  //Self.Time.Timer:=TTimer.Create(nil);
  //Self.Time.Timer.Enabled:=false;
  //Self.Time.Timer.onTimer:=@Self.RunNext;

  if AOwner=nil then
    begin
      Time.Synthesis_Mode:=SynMoDelay;
    end
  else if (AOwner is TComponent) and Assigned(AOwner) then
    begin
      Time.Synthesis_Mode:=SynMoTimer;
      Self.Control:=TAufControl.CreateNew(AOwner);
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
  IO_fptr.command_decode:=@de_decoder;//默认的转码函数

  Func_process.pre:=@de_nil;//默认的前驱过程
  Func_process.post:=@de_nil;//默认的后驱过程
  Func_process.mid:=@de_nil;//默认的防假死过程
  Func_process.beginning:=@de_nil;//默认的开始过程
  Func_process.ending:=@de_nil;//默认的结束过程

  var_stream:=TMemoryStream.Create;
  var_stream.SetSize(RAM_RANGE*256);
  PSW.run_parameter.ram_zero:=var_stream.Memory;
  PSW.run_parameter.ram_size:=RAM_RANGE*256;
  PSW.run_parameter.mid_fresh_time:=100;

  for i:=0 to func_range-1 do Self.func[i].name:='';
end;
{
destructor TAufScript.Destroy;
begin
  if Self.Handle <> 0 then  Classes.DeallocateHWnd(Self.Handle);  // 必须释放系统核心对象
  inherited Destroy;
end;
}
//////Class Methods end

//内置流程函数开始
procedure _helper;
begin
  Auf.Script.helper;
end;
procedure ramex;
begin
  Auf.Script.ram_export;
end;
procedure _sleep;
var ms,mc:dword;
begin
  ms:=Round(Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg));
  IF Auf.Script.Time.Synthesis_Mode=SynMoTimer THEN BEGIN;
    Auf.Script.Time.Timer.Interval:=ms;
    Auf.Script.Time.Timer.Enabled:=true;
    Auf.Script.Time.TimerPause:=true;
  END ELSE BEGIN
    for mc:=0 to ms div Auf.Script.PSW.run_parameter.mid_fresh_time do begin
      sleep(Auf.Script.PSW.run_parameter.mid_fresh_time);
      Auf.Script.Func_process.mid;
    end;
    sleep(ms mod Auf.Script.PSW.run_parameter.mid_fresh_time);
  END;
end;
procedure echo;
begin
  Auf.Script.IO_fptr.print(Auf.Script.to_string(Auf.nargs[1].pre,Auf.nargs[1].arg));
end;
procedure cwln;
begin
  Auf.Script.IO_fptr.echo('');
end;
procedure echoln;
begin
  echo;Auf.Script.IO_fptr.echo('');
end;
procedure print;
begin
  if Auf.ArgsCount<2 then begin Auf.Script.send_error('警告：未指定显示的变量');exit end;
  case Auf.nargs[1].pre of
    '$':Auf.Script.IO_fptr.print(Usf.i_to_s(pByte(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^));
    '@':Auf.Script.IO_fptr.print(Usf.i_to_s(pLong(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^));
    '~':Auf.Script.IO_fptr.print(Usf.to_s(pDouble(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^));
    '##':Auf.Script.IO_fptr.print(pString(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^);
    //子串的输出需要用的时候再详细解决
    '#':Auf.Script.IO_fptr.print(pString(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^);
    '$"','~"','$&"','~&"','#"','#&"':Auf.Script.IO_fptr.print(arv_to_s(Auf.Script.RamVar(Auf.nargs[1])));
    else begin Auf.Script.send_error('警告：错误的变量形式');exit end;
  end;
end;
procedure println;
begin
  print;Auf.Script.IO_fptr.echo('');
end;
procedure scan;
begin
end;
procedure exchange;
begin
end;

procedure hex;
begin
  if Auf.ArgsCount<1 then begin Auf.Script.send_error('警告：hex需要一个参数，不能显示。');exit end;
  case Auf.nargs[1].pre of
    '$"','~"','#"','$&"','~&"','#&"':Auf.Script.IO_fptr.print(arv_to_hex(Auf.Script.RamVar(Auf.nargs[1])));
    else Auf.Script.send_error('警告：不支持非标准变量形式，不能显示');
  end;
end;

procedure movb;
var a:byte;
begin
  if Auf.ArgsCount<3 then begin Auf.Script.send_error('警告：movb需要两个参数，赋值未成功。');exit end;
  if not (Auf.nargs[1].pre='$') then begin Auf.Script.send_error('警告：movb的一个参数需要是byte变量，赋值未成功。');exit end;
  case Auf.nargs[2].pre of
    '$':a:=pByte(Auf.Script.Pointer(Auf.nargs[2].pre,Usf.to_i(Auf.nargs[2].arg)))^;
    '@':a:=pLong(Auf.Script.Pointer(Auf.nargs[2].pre,Usf.to_i(Auf.nargs[2].arg)))^;
    '~':a:=round(pDouble(Auf.Script.Pointer(Auf.nargs[2].pre,Usf.to_i(Auf.nargs[2].arg)))^);
    '##':a:=round(Usf.to_f(pString(Auf.Script.Pointer(Auf.nargs[2].pre,Usf.to_i(Auf.nargs[2].arg)))^));
    '#':a:=round(Usf.to_f(pString(Auf.Script.Pointer(Auf.nargs[2].pre,Usf.to_i(Auf.nargs[2].arg)))^));
    '':a:=round(Usf.to_f(Auf.nargs[2].arg));
    else begin Auf.Script.send_error('警告：movb的第二个参数有误，赋值未成功。');exit end;
  end;
  PByte(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^:=a;
end;
procedure movl;
var a:longint;
begin
  if Auf.ArgsCount<3 then begin Auf.Script.send_error('警告：movl需要两个参数，赋值未成功。');exit end;
  if not (Auf.nargs[1].pre='@') then begin Auf.Script.send_error('警告：movl的一个参数需要是byte变量，赋值未成功。');exit end;
  case Auf.nargs[2].pre of
    '$':a:=pByte(Auf.Script.Pointer(Auf.nargs[2].pre,Usf.to_i(Auf.nargs[2].arg)))^;
    '@':a:=pLong(Auf.Script.Pointer(Auf.nargs[2].pre,Usf.to_i(Auf.nargs[2].arg)))^;
    '~':a:=round(pDouble(Auf.Script.Pointer(Auf.nargs[2].pre,Usf.to_i(Auf.nargs[2].arg)))^);
    '##':a:=round(Usf.to_f(pString(Auf.Script.Pointer(Auf.nargs[2].pre,Usf.to_i(Auf.nargs[2].arg)))^));
    '#':a:=round(Usf.to_f(pString(Auf.Script.Pointer(Auf.nargs[2].pre,Usf.to_i(Auf.nargs[2].arg)))^));
    '':a:=round(Usf.to_f(Auf.nargs[2].arg));
    else begin Auf.Script.send_error('警告：movl的第二个参数有误，赋值未成功。');exit end;
  end;
  PLong(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^:=a;
end;
procedure movd;
var a:double;
begin
  if Auf.ArgsCount<3 then begin Auf.Script.send_error('警告：movd需要两个参数，赋值未成功。');exit end;
  if not (Auf.nargs[1].pre='~') then begin Auf.Script.send_error('警告：movd的一个参数需要是byte变量，赋值未成功。');exit end;
  case Auf.nargs[2].pre of
    '$':a:=pByte(Auf.Script.Pointer(Auf.nargs[2].pre,Usf.to_i(Auf.nargs[2].arg)))^;
    '@':a:=pLong(Auf.Script.Pointer(Auf.nargs[2].pre,Usf.to_i(Auf.nargs[2].arg)))^;
    '~':a:=pDouble(Auf.Script.Pointer(Auf.nargs[2].pre,Usf.to_i(Auf.nargs[2].arg)))^;
    '##':a:=Usf.to_f(pString(Auf.Script.Pointer(Auf.nargs[2].pre,Usf.to_i(Auf.nargs[2].arg)))^);
    '#':a:=Usf.to_f(pString(Auf.Script.Pointer(Auf.nargs[2].pre,Usf.to_i(Auf.nargs[2].arg)))^);
    '':a:=Usf.to_f(Auf.nargs[2].arg);
    else begin Auf.Script.send_error('警告：movl的第二个参数有误，赋值未成功。');exit end;
  end;
  PDouble(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^:=a;
end;
procedure movs;
var a:string;
begin
  if Auf.ArgsCount<3 then begin Auf.Script.send_error('警告：movs需要两个参数，赋值未成功。');exit end;
  if (Auf.nargs[1].pre<>'#') and (Auf.nargs[1].pre<>'##') then begin Auf.Script.send_error('警告：movs的一个参数需要是str或substr变量，赋值未成功。');exit end;
  case Auf.nargs[2].pre of
    '##':a:=pString(Auf.Script.Pointer(Auf.nargs[2].pre,Usf.to_i(Auf.nargs[2].arg)))^;
    '#':a:=pString(Auf.Script.Pointer(Auf.nargs[2].pre,Usf.to_i(Auf.nargs[2].arg)))^;
    '':a:=Auf.nargs[2].arg;
    else begin Auf.Script.send_error('警告：movs的第二个参数有误，赋值未成功。');exit end;
  end;
  if Auf.nargs[1].pre='#' then delete(a,7,999);
  PString(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^:=a;
end;
procedure mov_arv;
var a:longint;
    tmp:TAufRamVar;
begin
  if Auf.ArgsCount<3 then begin Auf.Script.send_error('警告：mov_arv需要两个参数，赋值未成功。');exit end;
  case Auf.nargs[1].pre of
    '$"','~"','$&"','~&"','#"','#&"':;
    else
      begin
        Auf.Script.send_error('警告：mov_arv的一个参数需要是标准ARV变量形式，赋值未成功。');
        exit
      end;
  end;

  tmp:=Auf.Script.RamVar(Auf.nargs[1]);


  case Auf.nargs[2].pre of
    '$':initiate_arv(IntToHex(pByte(Auf.Script.Pointer(Auf.nargs[2].pre,Usf.to_i(Auf.nargs[2].arg)))^,2),tmp);
    '@':initiate_arv(IntToHex(pLong(Auf.Script.Pointer(Auf.nargs[2].pre,Usf.to_i(Auf.nargs[2].arg)))^,8),tmp);
    '~':begin Auf.Script.send_error('警告：mov_arv暂不支持浮点型，赋值未成功。');initiate_arv('0h',tmp) end;
    '##':initiate_arv((pString(Auf.Script.Pointer(Auf.nargs[2].pre,Usf.to_i(Auf.nargs[2].arg)))^),tmp);
    '#':initiate_arv((pString(Auf.Script.Pointer(Auf.nargs[2].pre,Usf.to_i(Auf.nargs[2].arg)))^),tmp);
    '$"','~"','$&"','~&"':Auf.Script.send_error('警告：mov_arv暂不支持ARV赋值给ARV，赋值未成功。');
    '':try initiate_arv(Auf.nargs[2].arg,tmp) except Auf.Script.send_error('警告：mov_arv暂不支持非十六进制，赋值未成功。') end;
    '"':initiate_arv_str(Auf.nargs[2].arg,tmp);
    else begin Auf.Script.send_error('警告：mov_arv的第二个参数有误，赋值未成功。');exit end;
  end;

end;
procedure mov;
begin
  case Auf.nargs[1].pre of
    '$':movb;
    '@':movl;
    '~':movd;
    '##':movs;
    '#':movs;
    '$"','~"','$&"','~&"','#"','#&"':mov_arv;
    else begin Auf.Script.send_error('警告：mov的第一个参数有误，赋值未成功。');exit end;
  end;
end;
procedure add;
var b:double;
begin
  if Auf.ArgsCount<3 then begin Auf.Script.send_error('警告：add需要两个参数，赋值未成功。');exit end;
  case Auf.nargs[2].pre of
    '$':b:=Auf.Script.to_double(Auf.nargs[2].pre,Auf.nargs[2].arg);
    '@':b:=Auf.Script.to_double(Auf.nargs[2].pre,Auf.nargs[2].arg);
    '~':b:=Auf.Script.to_double(Auf.nargs[2].pre,Auf.nargs[2].arg);
    '':b:=Usf.to_f(Auf.nargs[2].arg);
    else begin Auf.Script.send_error('警告：add的第二个参数需要是byte,long,double变量或立即数，语句未执行。');exit end;
  end;
  case Auf.nargs[1].pre of
    '$':pByte(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^:=round(Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg)+b);
    '@':pLong(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^:=round(Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg)+b);
    '~':pDouble(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^:=Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg)+b;
    else begin Auf.Script.send_error('警告：add的第一个参数需要是byte,long或double变量，语句未执行。');exit end;
  end;
end;
procedure sub;
var b:double;
begin
  if Auf.ArgsCount<3 then begin Auf.Script.send_error('警告：sub需要两个参数，赋值未成功。');exit end;
  case Auf.nargs[2].pre of
    '$':b:=Auf.Script.to_double(Auf.nargs[2].pre,Auf.nargs[2].arg);
    '@':b:=Auf.Script.to_double(Auf.nargs[2].pre,Auf.nargs[2].arg);
    '~':b:=Auf.Script.to_double(Auf.nargs[2].pre,Auf.nargs[2].arg);
    '':b:=Usf.to_f(Auf.nargs[2].arg);
    else begin Auf.Script.send_error('警告：sub的第二个参数需要是byte,long,double变量或立即数，语句未执行。');exit end;
  end;
  case Auf.nargs[1].pre of
    '$':pByte(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^:=round(Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg)-b);
    '@':pLong(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^:=round(Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg)-b);
    '~':pDouble(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^:=Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg)-b;
    else begin Auf.Script.send_error('警告：sub的第一个参数需要是byte,long或double变量，语句未执行。');exit end;
  end;
end;
procedure mul;
var b:double;
begin
  if Auf.ArgsCount<3 then begin Auf.Script.send_error('警告：mul需要两个参数，赋值未成功。');exit end;
  case Auf.nargs[2].pre of
    '$':b:=Auf.Script.to_double(Auf.nargs[2].pre,Auf.nargs[2].arg);
    '@':b:=Auf.Script.to_double(Auf.nargs[2].pre,Auf.nargs[2].arg);
    '~':b:=Auf.Script.to_double(Auf.nargs[2].pre,Auf.nargs[2].arg);
    '':b:=Usf.to_f(Auf.nargs[2].arg);
    else begin Auf.Script.send_error('警告：mul的第二个参数需要是byte,long,double变量或立即数，语句未执行。');exit end;
  end;
  case Auf.nargs[1].pre of
    '$':pByte(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^:=round(Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg)*b);
    '@':pLong(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^:=round(Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg)*b);
    '~':pDouble(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^:=Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg)*b;
    else begin Auf.Script.send_error('警告：mul的第一个参数需要是byte,long或double变量，语句未执行。');exit end;
  end;
end;
procedure div_;
var b:double;
    l:longint;
    double_integer,double_number:boolean;
begin
  if Auf.ArgsCount<3 then begin Auf.Script.send_error('警告：div需要两个参数，赋值未成功。');exit end;
  //检验参数
  double_integer:=true;
  double_number:=true;
  case Auf.nargs[1].pre of
    '$':;
    '@':;
    '~':double_integer:=false;
    '##':double_number:=false;
    '#':double_number:=false;
    '':begin Auf.Script.send_error('警告：div的第一个参数需要是byte,long,double变量，语句未执行。');exit end;
    else double_number:=false;
  end;
  case Auf.nargs[2].pre of
    '$':;
    '@':;
    '~':double_integer:=false;
    '##':double_number:=false;
    '#':double_number:=false;
    '':if (pos('.',Auf.nargs[2].arg)>0) or (pos('e',Auf.nargs[2].arg)>0) or (pos('E',Auf.nargs[2].arg)>0) then double_integer:=false;
    else double_number:=false;
  end;
  if not double_number then begin Auf.Script.send_error('警告：div的两个参数需要是byte,long,double变量或立即数，语句未执行。');exit end;
  //开始计算
  IF DOUBLE_INTEGER THEN BEGIN
  case Auf.nargs[2].pre of
    '$':l:=pByte(Auf.Script.Pointer(Auf.nargs[2].pre,Usf.to_i(Auf.nargs[2].arg)))^;
    '@':l:=pLong(Auf.Script.Pointer(Auf.nargs[2].pre,Usf.to_i(Auf.nargs[2].arg)))^;
    '':l:=Usf.to_i(Auf.nargs[2].arg);
    else begin Auf.Script.send_error('警告：异常错误，语句未执行');exit end;
  end;
  case Auf.nargs[1].pre of
    '$':pByte(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^:=pByte(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^ div l;
    '@':pLong(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^:=pLong(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^ div l;
    else begin Auf.Script.send_error('警告：异常错误，语句未执行');exit end;
  end;
  END
  ELSE BEGIN
  case Auf.nargs[2].pre of
    '$':b:=Auf.Script.to_double(Auf.nargs[2].pre,Auf.nargs[2].arg);
    '@':b:=Auf.Script.to_double(Auf.nargs[2].pre,Auf.nargs[2].arg);
    '~':b:=Auf.Script.to_double(Auf.nargs[2].pre,Auf.nargs[2].arg);
    '':b:=Usf.to_f(Auf.nargs[2].arg);
    else begin Auf.Script.send_error('警告：异常错误，语句未执行');exit end;
  end;
  case Auf.nargs[1].pre of
    '$':pByte(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^:=round(Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg)/b);
    '@':pLong(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^:=round(Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg)/b);
    '~':pDouble(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^:=Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg)/b;
    else begin Auf.Script.send_error('警告：异常错误，语句未执行');exit end;
  end;
  END;
end;
procedure mod_;
var l:longint;
    double_integer:boolean;
begin
  if Auf.ArgsCount<3 then begin Auf.Script.send_error('警告：mod需要两个参数，赋值未成功。');exit end;
  //检验参数
  double_integer:=true;
  case Auf.nargs[1].pre of
    '$':;
    '@':;
    '~':double_integer:=false;
    '##':double_integer:=false;
    '#':double_integer:=false;
    '':begin Auf.Script.send_error('警告：mod的第一个参数需要是byte,long变量，语句未执行。');exit end;
    else double_integer:=false;
  end;
  case Auf.nargs[2].pre of
    '$':;
    '@':;
    '~':double_integer:=false;
    '##':double_integer:=false;
    '#':double_integer:=false;
    '':if (pos('.',Auf.nargs[2].arg)>0) or (pos('e',Auf.nargs[2].arg)>0) or (pos('E',Auf.nargs[2].arg)>0) then double_integer:=false;
    else double_integer:=false;
  end;
  if not double_integer then begin Auf.Script.send_error('警告：mod的两个参数需要是byte,long变量或立即数，语句未执行。');exit end;
  //开始计算
  case Auf.nargs[2].pre of
    '$':l:=pByte(Auf.Script.Pointer(Auf.nargs[2].pre,Usf.to_i(Auf.nargs[2].arg)))^;
    '@':l:=pLong(Auf.Script.Pointer(Auf.nargs[2].pre,Usf.to_i(Auf.nargs[2].arg)))^;
    '':l:=Usf.to_i(Auf.nargs[2].arg);
    else begin Auf.Script.send_error('警告：异常错误，语句未执行');exit end;
  end;
  case Auf.nargs[1].pre of
    '$':pByte(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^:=pByte(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^ mod l;
    '@':pLong(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^:=pLong(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^ mod l;
    else begin Auf.Script.send_error('警告：异常错误，语句未执行');exit end;
  end;
end;
procedure rand;
var rand_res:longint;
begin
  if Auf.ArgsCount<3 then begin Auf.Script.send_error('警告：rand需要两个参数，赋值未成功。');exit end;
  case Auf.nargs[1].pre of
    '$':;
    '@':;
    '~':;
    '':begin Auf.Script.send_error('警告：rand的第一个参数需要是整型或浮点型变量，语句未执行。');exit end;
    else begin Auf.Script.send_error('警告：rand的第一个参数需要是变量，语句未执行。');exit end;
  end;
  case Auf.nargs[2].pre of
    '$':;
    '@':;
    '~':;
    '':;
    else begin Auf.Script.send_error('警告：rand的第二个参数需要是整型或浮点型，语句未执行。');exit end;
  end;
  randomize;
  rand_res:=random(Round(Auf.Script.to_double(Auf.nargs[2].pre,Auf.nargs[2].arg)));
  case Auf.nargs[1].pre of
    '$':pByte(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^:=rand_res mod 256;
    '@':pLong(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^:=rand_res;
    '~':pDouble(Auf.Script.Pointer(Auf.nargs[1].pre,Usf.to_i(Auf.nargs[1].arg)))^:=rand_res;
    else begin Auf.Script.send_error('警告：异常错误，语句未执行');exit end;
  end;
  //Round(Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg));
end;
procedure pow;
begin
end;
procedure log;
begin
end;
procedure exp;
begin
end;
procedure str;
begin
end;
procedure val;
begin
end;


procedure cj_mode(mode:string);//比较两个变量，满足条件则跳转至ofs  cj var1,var2,ofs
var a,b:double;
    ofs:smallint;
    is_not,is_call:boolean;//是否有N前缀或C后缀
    core_mode:string;//去除前后缀的mode

  procedure switch_addr(addr:word;iscall:boolean);
  begin
    if iscall then Auf.Script.push_addr(addr)
    else Auf.Script.jump_addr(addr);
  end;

begin
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
  if Auf.ArgsCount<3 then begin Auf.Script.send_error('警告：ife需要两个变量，该语句未执行。');exit end;
  if Auf.ArgsCount>3 then
    begin
      case Auf.nargs[3].pre of
        '$':ofs:=pByte(Auf.Script.Pointer(Auf.nargs[3].pre,Usf.to_i(Auf.nargs[3].arg)))^;
        '@':ofs:=pLong(Auf.Script.Pointer(Auf.nargs[3].pre,Usf.to_i(Auf.nargs[3].arg)))^;
        '~':ofs:=round(pDouble(Auf.Script.Pointer(Auf.nargs[3].pre,Usf.to_i(Auf.nargs[3].arg)))^);
        '&"':ofs:=RawStrToDword(Auf.nargs[3].arg) - Auf.Script.PSW.run_parameter.current_line_number;
        '':ofs:=Usf.to_i(Auf.nargs[3].arg);
        else begin Auf.Script.send_error('警告：地址偏移参数有误，语句未执行');exit end;
      end;
    end
  else
    begin
      if is_not then ofs:=-2
      else ofs:=2;
    end;
  if ofs=0 then begin Auf.Script.send_error('警告：ife需要非零的地址偏移量，该语句未执行。');exit end;
  case Auf.nargs[1].pre of
    '':a:=Usf.to_f(Auf.nargs[1].arg);
    else a:=Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg);
  end;
  case Auf.nargs[2].pre of
    '':b:=Usf.to_f(Auf.nargs[2].arg);
    else b:=Auf.Script.to_double(Auf.nargs[2].pre,Auf.nargs[2].arg);
  end;

  case core_mode of
    'ife':if (a=b) xor is_not then switch_addr(Auf.Script.currentLine+ofs,is_call);
    'cje':if (a=b) xor is_not then switch_addr(Auf.Script.currentLine+ofs,is_call);
    'ifl':if (a<b) xor is_not then switch_addr(Auf.Script.currentLine+ofs,is_call);
    'cjl':if (a<b) xor is_not then switch_addr(Auf.Script.currentLine+ofs,is_call);
    'ifm':if (a>b) xor is_not then switch_addr(Auf.Script.currentLine+ofs,is_call);
    'cjm':if (a>b) xor is_not then switch_addr(Auf.Script.currentLine+ofs,is_call);

  end;///////////TString和Line之间的跳转有大问题      答：解决方法是全盘使用TStrings

end;

procedure cj;
begin
  cj_mode(Auf.nargs[0].arg);
end;

procedure jmp;//满足条件执行下一句，不满足条件跳过下一句  jmp ofs|:label
var ofs:smallint;
begin
  ofs:=0;
  if Auf.ArgsCount<2 then begin Auf.Script.send_error('警告：jmp需要一个变量，该语句未执行。');exit end;
  case Auf.nargs[1].pre of
    '&"':ofs:=RawStrToDword(Auf.nargs[1].arg) - Auf.Script.PSW.run_parameter.current_line_number;
    else ofs:=Round(Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg));
  end;
  if ofs=0 then begin Auf.Script.send_error('警告：jmp需要非零的地址偏移量，该语句未执行。');exit end;
  Auf.Script.jump_addr(Auf.Script.currentLine+ofs);
end;

procedure call;//满足条件执行下一句，使用ret返回至该位置的下一行，不满足条件跳过下一句  call ofs|:label
var ofs:smallint;
begin
  ofs:=0;
  if Auf.ArgsCount<2 then begin Auf.Script.send_error('警告：jmp需要一个变量，该语句未执行。');exit end;
  case Auf.nargs[1].pre of
    '&"':ofs:=RawStrToDword(Auf.nargs[1].arg) - Auf.Script.PSW.run_parameter.current_line_number;
    else ofs:=Round(Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg));
  end;
  if ofs=0 then begin Auf.Script.send_error('警告：jmp需要非零的地址偏移量，该语句未执行。');exit end;
  Auf.Script.push_addr(Auf.Script.currentLine+ofs);
end;

procedure _ret;//返回至最近使用call的下一行，不满足条件跳过下一句  call ofs|:label
begin
  Auf.Script.pop_addr;
end;

procedure _end;//结束
begin
  Auf.Script.PSW.haltoff:=true;
end;

procedure _test;
var tmp:TAufRamVar;
begin
  {
  newARV(tmp,Auf.Script.RamVar(Auf.nargs[1]).size);

  //tmp:=Auf.Script.RamVar(Auf.nargs[1])+Auf.Script.RamVar(Auf.nargs[2]);
  //这个重载咋搞呀
  ARV_add(Auf.Script.RamVar(Auf.nargs[1]),Auf.Script.RamVar(Auf.nargs[2]),tmp);

  Auf.Script.IO_fptr.echo(to_hex(tmp));
  freeARV(tmp);
  }

  //Auf.Script.IO_fptr.echo(IntToStr(arv_to_dword(Auf.Script.RamVar(Auf.nargs[1]))));

  Auf.Script.IO_fptr.echo(FloatToStr(Auf.Script.syntax_to_double(Auf.nargs[1])));

end;


//内置流程函数结束

procedure TAufScript.InternalFuncDefine;
begin
  Self.add_func('help',@_helper,'                | 显示帮助');
  Self.add_func('ramex',@ramex,'               | 将内存导出到ram.var');
  Self.add_func('sleep',@_sleep,'n              | 等待n毫秒');
  Self.add_func('hex',@hex,'var              | 输出标准变量形式的十六进制');

  Self.add_func('print',@print,'var            | 输出变量var');
  Self.add_func('println',@println,'var          | 输出变量var并换行');
  Self.add_func('echo',@echo,'str             | 输出字符串');
  Self.add_func('echoln',@echoln,'str           | 输出字符串并换行');
  Self.add_func('cwln',@cwln,'                | 换行');
  Self.add_func('mov',@mov,'var,#            | 将#值赋值给var');
  Self.add_func('add',@add,'var,#            | 将var和#的值相加并返回给var');
  Self.add_func('sub',@sub,'var,#            | 将var和#的值相减并返回给var');
  Self.add_func('mul',@mul,'var,#            | 将var和#的值相乘并返回给var');
  Self.add_func('div',@div_,'var,#            | 将var和#的值相除并返回给var');
  Self.add_func('mod',@mod_,'var,#            | 将var和#的值求余并返回给var');
  Self.add_func('rand',@rand,'var,#           | 将不大于#的随机整数返回给var');

  Self.add_func('jmp',@jmp,'ofs              | 跳转到相对地址，不能跳转到当前地址0');
  Self.add_func('call',@call,'ofs             | 跳转到相对地址，使用ret返回至该位置的下一行，不能跳转到当前地址0');
  Self.add_func('ret',@_ret,'                 | 返回至最近一次使用call位置的下一行');
  Self.add_func('end',@_end,'                 | 立即结束');

  //Self.add_func('ife',@ife,'var1,var2[,ofs]  | 如果var1等于var2则跳转到相对地址，默认跳转到+2');
  //Self.add_func('nife',@nife,'var1,var2[,ofs] | 如果var1不等于var2则跳转到相对地址，默认跳转到-2');

  //{$define if_mode}
  //{$define asm_mode}
  {$ifdef if_mode}
  Self.add_func('ife',@cj,'var1,var2[,ofs]  | 如果var1等于var2则跳转到相对地址，默认跳转到+2');
  Self.add_func('nife',@cj,'var1,var2[,ofs] | 如果var1不等于var2则跳转到相对地址，默认跳转到-2');
  Self.add_func('ifm',@cj,'var1,var2[,ofs]  | 如果var1大于var2则跳转到相对地址，默认跳转到+2');
  Self.add_func('nifm',@cj,'var1,var2[,ofs] | 如果var1不大于var2则跳转到相对地址，默认跳转到-2');
  Self.add_func('ifl',@cj,'var1,var2[,ofs]  | 如果var1小于var2则跳转到相对地址，默认跳转到+2');
  Self.add_func('nifl',@cj,'var1,var2[,ofs] | 如果var1不小于var2则跳转到相对地址，默认跳转到-2');
  Self.add_func('ifec',@cj,'var1,var2[,ofs]  | 如果var1等于var2则跳转到相对地址，默认跳转到+2，并将当前地址压栈');
  Self.add_func('nifec',@cj,'var1,var2[,ofs] | 如果var1不等于var2则跳转到相对地址，默认跳转到-2，并将当前地址压栈');
  Self.add_func('ifmc',@cj,'var1,var2[,ofs]  | 如果var1大于var2则跳转到相对地址，默认跳转到+2，并将当前地址压栈');
  Self.add_func('nifmc',@cj,'var1,var2[,ofs] | 如果var1不大于var2则跳转到相对地址，默认跳转到-2，并将当前地址压栈');
  Self.add_func('iflc',@cj,'var1,var2[,ofs]  | 如果var1小于var2则跳转到相对地址，默认跳转到+2，并将当前地址压栈');
  Self.add_func('niflc',@cj,'var1,var2[,ofs] | 如果var1不小于var2则跳转到相对地址，默认跳转到-2，并将当前地址压栈');
  {$else}
     {$ifdef asm_mode}
  Self.add_func('je',@cj,'var1,var2[,ofs]  | 如果var1等于var2则跳转到相对地址，默认跳转到+2');
  Self.add_func('jne',@cj,'var1,var2[,ofs] | 如果var1不等于var2则跳转到相对地址，默认跳转到-2');
  Self.add_func('jm',@cj,'var1,var2[,ofs]  | 如果var1大于var2则跳转到相对地址，默认跳转到+2');
  Self.add_func('jnm',@cj,'var1,var2[,ofs] | 如果var1不大于var2则跳转到相对地址，默认跳转到-2');
  Self.add_func('jl',@cj,'var1,var2[,ofs]  | 如果var1小于var2则跳转到相对地址，默认跳转到+2');
  Self.add_func('jnl',@cj,'var1,var2[,ofs] | 如果var1不小于var2则跳转到相对地址，默认跳转到-2');
  Self.add_func('jec',@cj,'var1,var2[,ofs]  | 如果var1等于var2则跳转到相对地址，默认跳转到+2，并将当前地址压栈');
  Self.add_func('jnec',@cj,'var1,var2[,ofs] | 如果var1不等于var2则跳转到相对地址，默认跳转到-2，并将当前地址压栈');
  Self.add_func('jmc',@cj,'var1,var2[,ofs]  | 如果var1大于var2则跳转到相对地址，默认跳转到+2，并将当前地址压栈');
  Self.add_func('jnmc',@cj,'var1,var2[,ofs] | 如果var1不大于var2则跳转到相对地址，默认跳转到-2，并将当前地址压栈');
  Self.add_func('jlc',@cj,'var1,var2[,ofs]  | 如果var1小于var2则跳转到相对地址，默认跳转到+2，并将当前地址压栈');
  Self.add_func('jnlc',@cj,'var1,var2[,ofs] | 如果var1不小于var2则跳转到相对地址，默认跳转到-2，并将当前地址压栈');
     {$else}
  Self.add_func('cje',@cj,'var1,var2[,ofs]  | 如果var1等于var2则跳转到相对地址，默认跳转到+2');
  Self.add_func('ncje',@cj,'var1,var2[,ofs] | 如果var1不等于var2则跳转到相对地址，默认跳转到-2');
  Self.add_func('cjm',@cj,'var1,var2[,ofs]  | 如果var1大于var2则跳转到相对地址，默认跳转到+2');
  Self.add_func('ncjm',@cj,'var1,var2[,ofs] | 如果var1不大于var2则跳转到相对地址，默认跳转到-2');
  Self.add_func('cjl',@cj,'var1,var2[,ofs]  | 如果var1小于var2则跳转到相对地址，默认跳转到+2');
  Self.add_func('ncjl',@cj,'var1,var2[,ofs] | 如果var1不小于var2则跳转到相对地址，默认跳转到-2');
  Self.add_func('cjec',@cj,'var1,var2[,ofs]  | 如果var1等于var2则跳转到相对地址，默认跳转到+2，并将当前地址压栈');
  Self.add_func('ncjec',@cj,'var1,var2[,ofs] | 如果var1不等于var2则跳转到相对地址，默认跳转到-2，并将当前地址压栈');
  Self.add_func('cjmc',@cj,'var1,var2[,ofs]  | 如果var1大于var2则跳转到相对地址，默认跳转到+2，并将当前地址压栈');
  Self.add_func('ncjmc',@cj,'var1,var2[,ofs] | 如果var1不大于var2则跳转到相对地址，默认跳转到-2，并将当前地址压栈');
  Self.add_func('cjlc',@cj,'var1,var2[,ofs]  | 如果var1小于var2则跳转到相对地址，默认跳转到+2，并将当前地址压栈');
  Self.add_func('ncjlc',@cj,'var1,var2[,ofs] | 如果var1不小于var2则跳转到相对地址，默认跳转到-2，并将当前地址压栈');
     {$endif}
  {$endif}

  Self.add_func('test',@_test,'var              | 临时的函数');

  //Self.add_func('raddr',@raddr,'var,addr       | 将addr的值储存到var中');
  //Self.add_func('waddr',@raddr,'var,addr       | 将var的值储存到addr中');
  //先对应地写一个专门地址运算的私有方法
end;



INITIALIZATION

  Auf:=TAuf.Create(nil);
  Auf.Script.InternalFuncDefine;

  Usf:=TUsf.Create;





  //RegisterTest(TAuf);



END.

