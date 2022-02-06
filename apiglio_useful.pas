UNIT Apiglio_Useful;

//{$mode objfpc}{$H+}
{$goto on}
{$M+}
//{$TypedAddress off}

INTERFACE

uses
  Windows, Classes, SysUtils, Registry, Dos, WinCrt;

const
  c_divi=[' ',',','[',']'];//隔断符号
  c_iden=['~','@','$','#'];//变量符号
  c_toto=c_divi+c_iden;
  ram_range=32;//变量区大小
  stack_range=32;//行数堆栈区大小，最多支持256个
  func_range=256;//函数区大小，最多支持65536个
  args_range=16;//函数参数最大数量



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


  {TAufScript}
  pFunc      = procedure;
  pFuncStr   = procedure(str:string);
  TAufScript = class
    protected
      var_list:array[0..ram_range-1]of record case vType:(vtByte=1,vtLong=2,vtDouble=3,vtStr=4,vtSubstr=5) of
        vtByte:(Byte:array[0..255]of byte);
        vtLong:(Long:array[0..63]of longint);
        vtDouble:(Double:array[0..31]of double);
        vtStr:(Str:string[255]);
        vtSubStr:(SubStr:array[0..31]of string[8]);
      end;
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
      //
    public
      PSW:record
        stack:array[0..stack_range-1]of record
          filename:string;
          line:dword;//当前行数，在读指令阶段是当前指令，指令结束阶段就是下一个要读的行
          //这意味着上一个地址出栈后读取当前元素地址继续执行
        end;
        stack_ptr:byte;//PSW.stack[stack_ptr].line就是next_line,就是属性中的CurrentLine
        fileptr:text;
        jump:boolean;//是否手动安排下一次地址，生效后立即置否
        haltoff:boolean;
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
      end;
      Func_process:record
        pre,post:pFunc;//执行单条指令前后的额外过程
        beginning,ending:pFunc;//执行整段代码前后的额外过程
      end;

      property currentline:dword read GetLine write SetLine;//当前行数

      property pByte[Index:word]:pbyte read PtrByte;
      property pLong[Index:word]:plongint read PtrLong;
      property pDouble[Index:word]:pdouble read PtrDouble;
      property pStr[Index:word]:pstring read PtrStr;
      property pSubStr[Index:word]:pstring read PtrSubStr;

      property vByte[Index:word]:byte read GetByte write SetByte;
      property vLong[Index:word]:longint read GetLong write SetLong;
      property vDouble[Index:word]:double read GetDouble write SetDouble;
      property vStr[Index:word]:string read GetStr write SetStr;
      property vSubStr[Index:word]:string read GetSubStr write SetSubStr;

    published
      procedure send_error(str:string);
      function Pointer(Iden:string;Index:word):Pointer;
      function to_double(Iden,Index:string):double;//将nargs[].pre和nargs[].arg表示的变量转换成double类型
      function to_string(Iden,Index:string):string;//将nargs[].pre和nargs[].arg表示的变量转换成string类型
      procedure ram_export;//将整个内存区域打印到文件
      procedure add_func(func_name:ansistring;func_ptr:pFunc;helper:string);
      procedure run_func(func_name:ansistring);
      function have_func(func_name:ansistring):boolean;
      procedure helper;
      procedure HaltOff;
      procedure PSW_reset;
      procedure jump_next;//下一步不进行自动递进地址，改为由函数确定，需要在函数定义中配合jump_addr|pop_addr|push_addr使用
      procedure next_addr;
      procedure jump_addr(line:dword);//跳转绝对地址
      procedure offs_addr(offs:longint);//跳转偏移地址
      procedure pop_addr;
      procedure push_addr(filename:string;line:dword);
      procedure command(str:TStrings);overload;
      procedure command(str:string);overload;
      constructor Create;
      //
  end;


  {Auf  与Auf Script有关的内容}
  Tnargs=record //新的参数记录方式，新的Args[],记得开始使用
    arg:string;
    pre,post:string[8];
  end;
  TAuf= class
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
      constructor Create;
  end;


var

  i:byte;
  Auf:TAuf;
  Usf:TUsf;
  //Func:TFunc;
  //pErrorTip:procedure(str:string);//用来更改GUI或console模式下的错误弹出方式

  //operator +(obj_list:TObjList,pProc:pIterator):boolean;

  procedure de_writeln(str:string);
  procedure de_write(str:string);
  procedure de_readln;
  procedure de_message(str:string);
  procedure de_nil;
  function isprintable(str:string):boolean;


IMPLEMENTATION
(*
procedure TAuf.TestHookUp;
begin
  Fail('Write your own test');
end;
*)


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
          //writeln('tps=',tps);
        end;
      end;
  while (tps<>'') do if tps[1]=' ' then delete(tps,1,1) else break;
  if tps='' then exit;
  while (tps[length(tps)]=' ') do delete(tps,length(tps),1);


  //以nargs为主体的处理过程
  tpm:=0;//当前输入的参数下标
  is_post:=false;
  in_quotation:=false;
  for tpi:=1 to length(tps) do
    begin
      if tps[tpi]='"' then
        begin
          in_quotation:=not in_quotation;
          nargs[tpm].pre:='"';
          nargs[tpm].post:='"';
          iden:=iden+tps[tpi];
          toto:=toto+tps[tpi];
        end;
      if not in_quotation then
        begin
          if tps[tpi] in c_divi then
            begin
              inc(tpm);
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
      else if tps[tpi]<>'"' then nargs[tpm].arg:=nargs[tpm].arg+tps[tpi];
    end;
  ArgsCount:=tpm+1;

  for tpi:=0 to argsCount-1 do args[tpi]:=nargs[tpi].pre+nargs[tpi].arg+nargs[tpi].post;

end;


{
+---------------------------+
|Auf.ReadArgs Backup 20200226|
+---------------------------+

procedure TAuf.ReadArgs(ps:string);
label exitino;
var tps:string;
    tpi:byte;
begin
  if ps<>'' then tps:=ps[1] else goto exitino;
  if length(ps)>1 then
    for tpi:=2 to length(ps) do begin
      if (not(tps[length(tps)]in c_divi))or(ps[tpi]<>tps[length(tps)]) then begin
        if (ps[tpi]=' ')and(tpi<length(ps))then begin
                                                  if ps[tpi+1] in c_divi then tps:=tps+ps[tpi+1]
                                                  else tps:=tps+ps[tpi];
                                                end
        else tps:=tps+ps[tpi];
        //writeln('tps=',tps);
                                                                            end;
                                end;
  while (tps<>'') do if tps[1]=' ' then delete(tps,1,1) else break;
  if tps='' then goto exitino;
  while (tps[length(tps)]=' ') do delete(tps,length(tps),1);
  //writeln('tps=',tps);
  //tps=没有重复空格的ps

  toto:=tps;
  tpi:=1;
  repeat
    if toto[tpi] in c_toto then inc(tpi)
    else delete(toto,tpi,1);
  until tpi>=length(toto);
  if toto<>'' then if not (toto[tpi] in c_toto) then delete(toto,tpi,1);
  //writeln('toto=',toto);
  //toto=tps中包含在c_toto集合中的字符有序组合

//{$ifndef Auf_breif}
  divi:=tps;
  tpi:=1;
  repeat
    if divi[tpi] in c_divi then inc(tpi)
    else delete(divi,tpi,1);
  until tpi>=length(divi);
  if divi<>'' then if not (divi[tpi] in c_divi) then delete(divi,tpi,1);
  //writeln('divi=',divi);
  //divi=toto中包含在c_divi集合中的字符有序组合

  iden:=tps;
  tpi:=1;
  repeat
    if iden[tpi] in c_iden then inc(tpi)
    else delete(iden,tpi,1);
  until tpi>=length(iden);
  if iden<>'' then if not (iden[tpi] in c_iden) then delete(iden,tpi,1);
  //writeln('iden=',iden);
  //iden=toto中包含在c_iden集合中的字符有序组合

//{$endif}
  tpi:=0;
  repeat
    args[tpi]:=tps;
    if pos_divi(tps)>0 then
      begin
        delete(args[tpi],pos_divi(tps),999);
        delete(tps,1,pos_divi(tps));
        inc(tpi);
      end;
  until (length(tps)<=0)or(pos_divi(tps)<=0);
  if toto<>'' then args[tpi]:=tps;
  ArgsCount:=tpi+1;

//nargs新方法加入
  for tpi:=0 to ArgsCount-1 do begin
    tps:=args[tpi];
    nargs[tpi].pre:='';
    nargs[tpi].post:='';
    nargs[tpi].arg:='';
    while tps[1] in c_iden do begin
      nargs[tpi].pre:=tps[1]+nargs[tpi].pre;
      delete(tps,1,1);
    end;
    while pos_iden(tps)>0 do begin
      nargs[tpi].post:=nargs[tpi].post+tps[length(tps)];
      delete(tps,length(tps),1);
    end;
    nargs[tpi].arg:=tps;
  end;
//nargs

  exit;
exitino:
  for tpi:=0 to args_range-1 do args[tpi]:='';
  for tpi:=0 to args_range-1 do begin nargs[tpi].arg:='';nargs[tpi].post:='';nargs[tpi].pre:='' end;
  ArgsCount:=0;
  toto:='';divi:='';iden:='';
end;


}

constructor TAuf.Create;
var i:byte;
begin
  inherited Create;
  Self.Script:=TAufScript.Create;
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
function TAufScript.PtrByte(Index:word):pbyte;
var dv,md:byte;
begin
  dv:=Index div 256;
  md:=Index mod 256;
  result:=@(Self.var_list[dv].Byte[md]);
end;
function TAufScript.PtrLong(Index:word):plongint;
var dv,md:byte;
begin
  dv:=Index div 64;
  md:=Index mod 64;
  result:=@(Self.var_list[dv].Long[md]);
end;
function TAufScript.PtrDouble(Index:word):pdouble;
var dv,md:byte;
begin
  dv:=Index div 32;
  md:=Index mod 32;
  result:=@(Self.var_list[dv].Double[md]);
end;
function TAufScript.PtrStr(Index:word):pstring;
begin
  result:=@(Self.var_list[Index].Str);
end;
function TAufScript.PtrSubStr(Index:word):pstring;
var dv,md:byte;
begin
  dv:=Index div 32;
  md:=Index mod 32;
  result:=@(Self.var_list[dv].SubStr[md]);
end;
function TAufScript.GetLine:dword;
begin
  result:=Self.PSW.stack[Self.PSW.stack_ptr].line
end;
procedure TAufScript.SetLine(l:dword);
begin
  Self.PSW.stack[Self.PSW.stack_ptr].line:=l;
end;
function TAufScript.GetByte(Index:word):byte;
begin
  result:=Self.pByte[Index]^;
end;
procedure TAufScript.SetByte(Index:word;byt:byte);
begin
  Self.pByte[Index]^:=byt;
end;
function TAufScript.GetLong(Index:word):longint;
begin
  result:=Self.pLong[Index]^;
end;
procedure TAufScript.SetLong(Index:word;lng:longint);
begin
  Self.pLong[Index]^:=lng;
end;
function TAufScript.GetDouble(Index:word):double;
begin
  result:=Self.pDouble[Index]^;
end;
procedure TAufScript.SetDouble(Index:word;dbl:double);
begin
  Self.pDouble[Index]^:=dbl;
end;
function TAufScript.GetStr(Index:word):string;
begin
  result:=Self.pStr[Index]^;
end;
procedure TAufScript.SetStr(Index:word;str:string);
begin
  Self.pStr[Index]^:=str;
end;
function TAufScript.GetSubStr(Index:word):string;
begin
  result:=Self.pSubStr[Index]^;
end;
procedure TAufScript.SetSubStr(Index:word;str:string);
begin
  Self.pSubStr[Index]^:=str;
end;

function TAufScript.Pointer(Iden:string;Index:word):Pointer;//这里要注意pointer类型的可变
begin
  case Iden of
    '$':result:=Self.pByte[Index];
    '@':result:=Self.pLong[Index];
    '~':result:=Self.pDouble[Index];
    '##':result:=Self.pStr[Index];
    '#':result:=Self.pSubStr[Index];
    else begin Self.send_error('警告：无效的指针类型，返回nil！');result:=@(Self.var_list) end;
  end;
end;
function TAufScript.to_double(Iden,Index:string):double;//将nargs[].pre和nargs[].arg表示的变量转换成double类型
var dbl:double;
    value:word;
    codee:byte;
begin
  val(Index,value,codee);
  if (codee<>0)and(Iden<>'') then begin Self.send_error('警告：变量序号有误，返回0！');result:=0;exit end;
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
  rewrite(ex);
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
  Self.IO_fptr.echo('[In '''+Self.PSW.stack[Self.CurrentLine].filename + ''' Line ' + Usf.i_to_s(Self.CurrentLine)+ ']'+str);
end;
procedure TAufScript.HaltOff;
begin
  Self.PSW.haltoff:=true;
end;
procedure TAufScript.PSW_reset;
var i:word;
begin
  for i:= 0 to stack_range-1 do begin
    Self.PSW.stack[i].filename:='';
    Self.PSW.stack[i].line:=0;
  end;
  Self.PSW.stack_ptr:=0;
  Self.PSW.haltoff:=false;
  assignfile(Self.PSW.fileptr,'');
end;
procedure TAufScript.jump_next;inline;
begin
  Self.PSW.jump:=true;
end;
procedure TAufScript.next_addr;
begin
  inc(Self.PSW.stack[Self.PSW.stack_ptr].line);
end;
procedure TAufScript.jump_addr(line:dword);//跳转绝对地址
var pi:dword;
begin
  if line > Self.PSW.stack[Self.PSW.stack_ptr].line then begin
    for pi:=2 to line - Self.PSW.stack[Self.PSW.stack_ptr].line do readln(Self.PSW.fileptr);
  end
  else begin
    reset(Self.PSW.fileptr);
    for pi:=1 to line do readln(Self.PSW.fileptr);        //注意！！！暂时还没有地址超界检验！！！
  end;
  Self.PSW.stack[Self.PSW.stack_ptr].line:=line;
end;
procedure TAufScript.offs_addr(offs:longint);//跳转偏移地址
begin
  jump_addr(Self.PSW.stack[Self.PSW.stack_ptr].line+offs);
end;
procedure TAufScript.pop_addr;
var pi:dword;
begin
  if Self.PSW.stack_ptr=0 then begin Self.send_error('错误：[-1]超出栈范围！');Self.IO_fptr.pause;halt end;
  close(Self.PSW.fileptr);
  Self.PSW.stack[Self.PSW.stack_ptr].line:=0;
  Self.PSW.stack[Self.PSW.stack_ptr].filename:='';
  dec(Self.PSW.stack_ptr);
  assignfile(Self.PSW.fileptr,'');
  reset(Self.PSW.fileptr);
  for pi:=1 to Self.PSW.stack[Self.PSW.stack_ptr].line do readln(Self.PSW.fileptr);
end;
procedure TAufScript.push_addr(filename:string;line:dword);
var pi:dword;
begin
  if Self.PSW.stack_ptr=stack_range-1 then begin Self.send_error('错误：['+Usf.to_s(stack_range)+']超出栈范围！');Self.IO_fptr.pause;halt end;
  close(Self.PSW.fileptr);
  inc(Self.PSW.stack_ptr);
  Self.PSW.stack[Self.PSW.stack_ptr].filename:=filename;
  Self.PSW.stack[Self.PSW.stack_ptr].line:=line;
  assignfile(Self.PSW.fileptr,filename);
  reset(Self.PSW.fileptr);
  for pi:=1 to line do readln(Self.PSW.fileptr);
end;

procedure TAufScript.command(str:TStrings);
var i:dword;
    cmd:string;
begin
  Self.PSW_reset;

  Self.Func_process.beginning;

  while Self.PSW.stack[0].line < str.count do begin
    //读取栈中地址的指令
    if Self.PSW.stack_ptr=0 then cmd:=str.strings[Self.PSW.stack[0].line]
    else readln(Self.PSW.fileptr,cmd);

    Self.Func_process.pre;

    //自定义函数执行部分
    Auf.ReadArgs(cmd);
    if (Auf.args[0][1]<>'/') or (Auf.args[0][2]<>'/') then
    Self.run_func(Auf.args[0]);

    Self.Func_process.post;

    if Self.PSW.haltoff then break;

    //安排下一个地址
    if not Self.PSW.jump then Self.next_addr;
    Self.PSW.jump:=false;
  end;

  Self.Func_process.ending;

end;
procedure TAufScript.command(str:string);
var scpt:TStringList;
begin
  scpt:=TStringList.Create;
  scpt.add(str);
  command(scpt);
  scpt.Destroy;
end;
constructor TAufScript.Create;
var i:word;
begin
  inherited Create;
  IO_fptr.echo:=@de_writeln;//默认的输出函数
  IO_fptr.print:=@de_write;//默认的不换行输出函数
  IO_fptr.error:=@de_writeln;//默认的错误报告函数
  IO_fptr.pause:=@de_readln;//默认的确认函数

  Func_process.pre:=@de_nil;//默认的前驱过程
  Func_process.post:=@de_nil;//默认的后驱过程
  Func_process.beginning:=@de_nil;//默认的开始过程
  Func_process.ending:=@de_nil;//默认的结束过程


  for i:=0 to func_range-1 do Self.func[i].name:='';
end;

//////Class Methods end

//内置流程函数开始
procedure helper;
begin
  Auf.Script.helper;
end;
procedure ramex;
begin
  Auf.Script.ram_export;
end;
procedure sleep;
begin
  delay(Round(Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg)));
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
procedure mov;
begin
  case Auf.nargs[1].pre of
    '$':movb;
    '@':movl;
    '~':movd;
    '##':movs;
    '#':movs;
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
begin
  ofs:=0;
  if Auf.ArgsCount<3 then begin Auf.Script.send_error('警告：ife需要两个变量，该语句未执行。');exit end;
  if Auf.ArgsCount>3 then begin
    case Auf.nargs[3].pre of
      '$':ofs:=pByte(Auf.Script.Pointer(Auf.nargs[3].pre,Usf.to_i(Auf.nargs[3].arg)))^;
      '@':ofs:=pLong(Auf.Script.Pointer(Auf.nargs[3].pre,Usf.to_i(Auf.nargs[3].arg)))^;
      '~':ofs:=round(pDouble(Auf.Script.Pointer(Auf.nargs[3].pre,Usf.to_i(Auf.nargs[3].arg)))^);
      '':ofs:=Usf.to_i(Auf.nargs[3].arg);
      else begin Auf.Script.send_error('警告：地址偏移参数有误，语句未执行');exit end;
    end;
  end
  else
  begin
    if mode[1]='n' then ofs:=-2
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
  case mode of
    'ife':if a=b then begin Auf.Script.PSW.jump:=false;Auf.Script.currentLine:=Auf.Script.currentLine+ofs-1 end;
    'cje':if a=b then begin Auf.Script.PSW.jump:=false;Auf.Script.currentLine:=Auf.Script.currentLine+ofs-1 end;
    'nife':if a<>b then begin Auf.Script.PSW.jump:=false;Auf.Script.currentLine:=Auf.Script.currentLine+ofs-1 end;
    'ncje':if a<>b then begin Auf.Script.PSW.jump:=false;Auf.Script.currentLine:=Auf.Script.currentLine+ofs-1 end;
    'ifl':if a<b then begin Auf.Script.PSW.jump:=false;Auf.Script.currentLine:=Auf.Script.currentLine+ofs-1 end;
    'cjl':if a<b then begin Auf.Script.PSW.jump:=false;Auf.Script.currentLine:=Auf.Script.currentLine+ofs-1 end;
    'ifm':if a>b then begin Auf.Script.PSW.jump:=false;Auf.Script.currentLine:=Auf.Script.currentLine+ofs-1 end;
    'cjm':if a>b then begin Auf.Script.PSW.jump:=false;Auf.Script.currentLine:=Auf.Script.currentLine+ofs-1 end;
    'nifl':if a>=b then begin Auf.Script.PSW.jump:=false;Auf.Script.currentLine:=Auf.Script.currentLine+ofs-1 end;
    'ncjl':if a>=b then begin Auf.Script.PSW.jump:=false;Auf.Script.currentLine:=Auf.Script.currentLine+ofs-1 end;
    'nifm':if a<=b then begin Auf.Script.PSW.jump:=false;Auf.Script.currentLine:=Auf.Script.currentLine+ofs-1 end;
    'ncjm':if a<=b then begin Auf.Script.PSW.jump:=false;Auf.Script.currentLine:=Auf.Script.currentLine+ofs-1 end;

  end;///////////TString和Line之间的跳转有大问题
end;

procedure cj;
begin
  cj_mode(Auf.nargs[0].arg);
end;

procedure ife;//满足条件执行下一句，不满足条件跳过下一句  ife var1,var2
var a,b:double;
    ofs:smallint;
begin
  ofs:=0;
  if Auf.ArgsCount<3 then begin Auf.Script.send_error('警告：ife需要两个变量，该语句未执行。');exit end;
  if Auf.ArgsCount>3 then begin
    case Auf.nargs[3].pre of
      '$':ofs:=pByte(Auf.Script.Pointer(Auf.nargs[3].pre,Usf.to_i(Auf.nargs[3].arg)))^;
      '@':ofs:=pLong(Auf.Script.Pointer(Auf.nargs[3].pre,Usf.to_i(Auf.nargs[3].arg)))^;
      '~':ofs:=round(pDouble(Auf.Script.Pointer(Auf.nargs[3].pre,Usf.to_i(Auf.nargs[3].arg)))^);
      '':ofs:=Usf.to_i(Auf.nargs[3].arg);
      else begin Auf.Script.send_error('警告：地址偏移参数有误，语句未执行');exit end;
    end;
  end
  else ofs:=2;
  if ofs=0 then begin Auf.Script.send_error('警告：ife需要非零的地址偏移量，该语句未执行。');exit end;
  case Auf.nargs[1].pre of
    '':a:=Usf.to_f(Auf.nargs[1].arg);
    else a:=Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg);
  end;
  case Auf.nargs[2].pre of
    '':b:=Usf.to_f(Auf.nargs[2].arg);
    else b:=Auf.Script.to_double(Auf.nargs[2].pre,Auf.nargs[2].arg);
  end;
  if a=b then begin Auf.Script.PSW.jump:=false;Auf.Script.currentLine:=Auf.Script.currentLine+ofs-1 end;     ///////////TString和Line之间的跳转有大问题
  //Auf.Script.IO_fptr.echo('currentLine='+Usf.to_s(Auf.Script.currentLine)+', Offset='+Usf.to_s(ofs));
end;

procedure nife;//满足条件执行下一句，不满足条件跳过下一句  ife var1,var2
var a,b:double;
    ofs:smallint;
begin
  ofs:=0;
  if Auf.ArgsCount<3 then begin Auf.Script.send_error('警告：cjx需要两个变量，该语句未执行。');exit end;
  if Auf.ArgsCount>3 then begin
    case Auf.nargs[3].pre of
      '$':ofs:=pByte(Auf.Script.Pointer(Auf.nargs[3].pre,Usf.to_i(Auf.nargs[3].arg)))^;
      '@':ofs:=pLong(Auf.Script.Pointer(Auf.nargs[3].pre,Usf.to_i(Auf.nargs[3].arg)))^;
      '~':ofs:=round(pDouble(Auf.Script.Pointer(Auf.nargs[3].pre,Usf.to_i(Auf.nargs[3].arg)))^);
      '':ofs:=Usf.to_i(Auf.nargs[3].arg);
      else begin Auf.Script.send_error('警告：地址偏移参数有误，语句未执行');exit end;
    end;
  end
  else ofs:=-2;
  if ofs=0 then begin Auf.Script.send_error('警告：cjx需要非零的地址偏移量，该语句未执行。');exit end;
  case Auf.nargs[1].pre of
    '':a:=Usf.to_f(Auf.nargs[1].arg);
    else a:=Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg);
  end;
  case Auf.nargs[2].pre of
    '':b:=Usf.to_f(Auf.nargs[2].arg);
    else b:=Auf.Script.to_double(Auf.nargs[2].pre,Auf.nargs[2].arg);
  end;
  if a<>b then begin Auf.Script.PSW.jump:=false;Auf.Script.currentLine:=Auf.Script.currentLine+ofs-1 end;     ///////////TString和Line之间的跳转有大问题
  //Auf.Script.IO_fptr.echo('currentLine='+Usf.to_s(Auf.Script.currentLine)+', Offset='+Usf.to_s(ofs));
end;

procedure jmp;//满足条件执行下一句，不满足条件跳过下一句  jmp ofs
var ofs:smallint;
begin
  ofs:=0;
  if Auf.ArgsCount<2 then begin Auf.Script.send_error('警告：jmp需要一个变量，该语句未执行。');exit end;
  ofs:=Round(Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg));
  if ofs=0 then begin Auf.Script.send_error('警告：jmp需要非零的地址偏移量，该语句未执行。');exit end;
  Auf.Script.PSW.jump:=false;
  Auf.Script.currentLine:=Auf.Script.currentLine+ofs-1;
end;


//内置流程函数结束





INITIALIZATION

  Auf:=TAuf.Create;
  Usf:=TUsf.Create;

  Auf.Script.add_func('help',@helper,'                | 显示帮助');
  Auf.Script.add_func('ramex',@ramex,'               | 将内存导出到ram.var');
  Auf.Script.add_func('sleep',@sleep,'n              | 等待n毫秒');
  Auf.Script.add_func('print',@print,'var            | 输出变量var');
  Auf.Script.add_func('println',@println,'var          | 输出变量var并换行');
  Auf.Script.add_func('echo',@echo,'str             | 输出字符串');
  Auf.Script.add_func('echoln',@echoln,'str           | 输出字符串并换行');
  Auf.Script.add_func('cwln',@cwln,'                | 换行');
  Auf.Script.add_func('mov',@mov,'var,#            | 将#值赋值给var');
  Auf.Script.add_func('add',@add,'var,#            | 将var和#的值相加并返回给var');
  Auf.Script.add_func('sub',@sub,'var,#            | 将var和#的值相减并返回给var');
  Auf.Script.add_func('mul',@mul,'var,#            | 将var和#的值相乘并返回给var');
  Auf.Script.add_func('div',@div_,'var,#            | 将var和#的值相除并返回给var');
  Auf.Script.add_func('mod',@mod_,'var,#            | 将var和#的值求余并返回给var');
  Auf.Script.add_func('rand',@rand,'var,#           | 将不大于#的随机整数返回给var');
  Auf.Script.add_func('jmp',@jmp,'ofs              | 跳转到相对地址，不能跳转到当前地址0');
  //Auf.Script.add_func('ife',@ife,'var1,var2[,ofs]  | 如果var1等于var2则跳转到相对地址，默认跳转到+2');
  //Auf.Script.add_func('nife',@nife,'var1,var2[,ofs] | 如果var1不等于var2则跳转到相对地址，默认跳转到-2');
  Auf.Script.add_func('ife',@cj,'var1,var2[,ofs]  | 如果var1等于var2则跳转到相对地址，默认跳转到+2');
  Auf.Script.add_func('nife',@cj,'var1,var2[,ofs] | 如果var1不等于var2则跳转到相对地址，默认跳转到-2');
  Auf.Script.add_func('ifm',@cj,'var1,var2[,ofs]  | 如果var1大于var2则跳转到相对地址，默认跳转到+2');
  Auf.Script.add_func('nifm',@cj,'var1,var2[,ofs] | 如果var1不大于var2则跳转到相对地址，默认跳转到-2');
  Auf.Script.add_func('ifl',@cj,'var1,var2[,ofs]  | 如果var1小于var2则跳转到相对地址，默认跳转到+2');
  Auf.Script.add_func('nifl',@cj,'var1,var2[,ofs] | 如果var1不小于var2则跳转到相对地址，默认跳转到-2');

  //Auf.Script.add_func('raddr',@raddr,'var,addr       | 将addr的值储存到var中');
  //Auf.Script.add_func('waddr',@raddr,'var,addr       | 将var的值储存到addr中');
  //先对应地写一个专门地址运算的私有方法



  //RegisterTest(TAuf);



END.

