unit auf_ram_var;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TAufRamVar = record
    VarType:(ARV_Raw=0,ARV_FixNum=1,ARV_Float=2,ARV_Char=3);
    Head:pbyte;
    size:byte;
    Is_Temporary:boolean;//是否是运算符重载计算时临时产生的内存流数据
    Stream:TMemoryStream;//如果是，这里是内存流的指针
  end;

  procedure newARV(var inp:TAufRamVar;Size:byte);
  procedure freeARV(inp:TAufRamVar);
  function assignedARV(inp:TAufRamVar):boolean;

  procedure fixnum_add(ina,inb:TAufRamVar;var oup:TAufRamVar);
  procedure fixnum_sub(ina,inb:TAufRamVar;var oup:TAufRamVar);


  procedure ARV_add(ina,inb:TAufRamVar;var oup:TAufRamVar);
  procedure ARV_sub(ina,inb:TAufRamVar;var oup:TAufRamVar);
  procedure ARV_mul(ina,inb:TAufRamVar;var oup:TAufRamVar);
  procedure ARV_div(ina,inb:TAufRamVar;var oup:TAufRamVar);
  procedure ARV_mod(ina,inb:TAufRamVar;var oup:TAufRamVar);

  function ARV_comp(ina,inb:TAufRamVar):smallint;//ina<=>inb
  {
  operator <(ina,inb:TAufRamVar):boolean;
  operator <=(ina,inb:TAufRamVar):boolean;
  operator >(ina,inb:TAufRamVar):boolean;
  operator >=(ina,inb:TAufRamVar):boolean;
  operator =(ina,inb:TAufRamVar):boolean;
  operator <>(ina,inb:TAufRamVar):boolean;
  }

  function arv_to_s(ina:TAufRamVar):string;
  function arv_to_hex(ina:TAufRamVar):string;
  function arv_to_dword(ina:TAufRamVar):dword;
  function arv_to_double(ina:TAufRamVar):double;
  procedure initiate_arv(exp:string;var arv:TAufRamVar);//根据字符串创建最大相似的ARV
  procedure initiate_arv_str(exp:string;var arv:TAufRamVar);//根据字符串创建字符串的ARV


implementation

uses Apiglio_Useful;

procedure newARV(var inp:TAufRamVar;Size:byte);
begin
  inp.Is_Temporary:=true;
  inp.Stream.Free;
  inp.Stream:=TMemoryStream.Create;
  inp.Stream.Size:=Size;
  inp.Size:=size;
  inp.Head:=inp.Stream.Memory;
  inp.VarType:=ARV_Raw;
  inp.Stream.Position:=Size-1;
  inp.stream.WriteByte($00);
end;

procedure freeARV(inp:TAufRamVar);
begin
  if inp.Is_Temporary then inp.Stream.Free
  else Auf.Script.send_error('警告：正在试图释放非临时AufRamVar，已被拒绝.');
end;

function assignedARV(inp:TAufRamVar):boolean;
begin
  if inp.Is_Temporary and (inp.Stream=nil) then begin result:=false;exit end;
  result:=true;//暂时没有检验超界的办法
end;

procedure fixnum_add(ina,inb:TAufRamVar;var oup:TAufRamVar);    //这里要改一下，可以按正常的记录类型来搞
var //stream:TMemoryStream;
    digit,ta,tb,YC:byte;

  function max_one(a,b:byte):byte;
    begin
      if a>b then result:=a
      else result:=b
    end;

begin

  if oup.Is_Temporary then
    begin
      if not assignedARV(oup) then
        begin
          //newARV(oup,max(ina.size,inb.size)+1);
          raise Exception.Create('临时性ARV地址错误，内存流未初始化。');
        end;
    end
  else
    begin
      if not assignedARV(oup) then raise Exception.Create('非临时性ARV地址错误。');
    end;

  YC:=0;
  for digit:=0 to oup.size-1 do
    begin
      if ina.size>digit then ta:=(ina.Head+digit)^ else ta:=0;
      if inb.size>digit then tb:=(inb.Head+digit)^ else tb:=0;
      pbyte(oup.Head+digit)^:=(ta+tb+YC)mod 256;
      YC:=(ta+tb+YC) div 256;
    end;

  if YC<>0 then Auf.Script.PSW.calc.YC:=true;

  //oup.Head:=pbyte(stream.Memory);
  //oup.size:=stream.Size;
end;
procedure fixnum_sub(ina,inb:TAufRamVar;var oup:TAufRamVar);
var stream:TMemoryStream;
    digit,ta,tb,YC:byte;

  function max_one(a,b:byte):byte;
    begin
      if a>b then result:=a
      else result:=b
    end;

begin

  if oup.Is_Temporary then
    begin
      if not assignedARV(oup) then
        begin
          //newARV(oup,max(ina.size,inb.size)+1);
          raise Exception.Create('临时性ARV地址错误，内存流未初始化。');
        end;
    end
  else
    begin
      if not assignedARV(oup) then raise Exception.Create('非临时性ARV地址错误。');
    end;

  YC:=0;
  for digit:=0 to max_one(ina.size,inb.size)-1 do
    begin
      if ina.size>digit then ta:=(ina.Head+digit)^ else ta:=0;
      if inb.size>digit then tb:=(inb.Head+digit)^ else tb:=0;
      pbyte(stream.Memory+digit)^:=(ta-YC-tb)mod 256;
      if ta-YC<tb then YC:=1 else YC:=0;
    end;

  oup.Head:=pbyte(stream.Memory);
  oup.size:=stream.Size;
end;


function fixnum_comp(ina,inb:TAufRamVar):smallint;//ina<=>inb
begin
  //ina.VarType;
end;

function ARV_comp(ina,inb:TAufRamVar):smallint;//ina<=>inb
begin
  if (ina.VarType=ARV_Char) or (inb.VarType=ARV_Char) then raise Exception.Create('字符类型AufRamVar不能比较');
  ////////////////////
end;



procedure ARV_add(ina,inb:TAufRamVar;var oup:TAufRamVar);
begin
  if (ina.VarType=ARV_FixNum) and (inb.VarType=ARV_FixNum) then fixnum_add(ina,inb,oup)
  else Auf.Script.send_error('暂不支持整型数以外的变量加法');
end;
procedure ARV_sub(ina,inb:TAufRamVar;var oup:TAufRamVar);
begin
  if (ina.VarType=ARV_FixNum) and (inb.VarType=ARV_FixNum) then fixnum_sub(ina,inb,oup)
  else Auf.Script.send_error('暂不支持整型数以外的变量加法');
end;
procedure ARV_mul(ina,inb:TAufRamVar;var oup:TAufRamVar);
begin
  //
end;
procedure ARV_div(ina,inb:TAufRamVar;var oup:TAufRamVar);
begin
  //
end;
procedure ARV_mod(ina,inb:TAufRamVar;var oup:TAufRamVar);
begin
  //
end;



operator <(ina,inb:TAufRamVar):boolean;
begin
  if ARV_comp(ina,inb)=-1 then result:=true
  else result:=false;
end;
operator <=(ina,inb:TAufRamVar):boolean;
begin
  if not ARV_comp(ina,inb)=1 then result:=true
  else result:=false;
end;
operator >(ina,inb:TAufRamVar):boolean;
begin
  if ARV_comp(ina,inb)=1 then result:=true
  else result:=false;
end;
operator >=(ina,inb:TAufRamVar):boolean;
begin
  if not ARV_comp(ina,inb)=-1 then result:=true
  else result:=false;
end;
operator =(ina,inb:TAufRamVar):boolean;
begin
  if ARV_comp(ina,inb)=0 then result:=true
  else result:=false;
end;
operator <>(ina,inb:TAufRamVar):boolean;
begin
  if ARV_comp(ina,inb)<>0 then result:=true
  else result:=false;
end;

function arv_to_s(ina:TAufRamVar):string;
var pi:byte;
begin
  result:='';
  case ina.VarType of
    ARV_FixNum:begin
                 result:='暂不支持整型数的to_s转换，请使用to_hex';
               end;
    ARV_Float :begin
                 result:='暂不支持浮点型的to_s转换，请使用to_hex';
               end;
    ARV_Char  :begin
                 for pi:=ina.size-1 downto 0 do
                   begin
                     result:=result+chr((ina.Head+pi)^);
                   end;
               end;
    else {raise Exception.Create('错误的ARV类型，不能转换为字符串')}begin Auf.Script.send_error('错误的ARV类型，不能转换为字符串');result:='';exit end;
  end;
end;
function arv_to_hex(ina:TAufRamVar):string;
var pi:byte;
begin
  result:='UnKnown.Hex(';
  if assignedARV(ina) then
    begin
      for pi:=ina.size-1 downto 0 do
        begin
          result:=result+IntToHex((ina.Head+pi)^,2);
        end;
    end
  else
    begin
      Auf.Script.send_error('警告：地址超界！');
      for pi:=ina.size-1 downto 0 do result:=result+'00';
    end;
  result:=result+')';
end;
function arv_to_dword(ina:TAufRamVar):dword;
var pi:byte;
begin
  result:=0;
  case ina.VarType of
    ARV_FixNum:begin
                 result:=0;
                 pi:=4;
                 if ina.size<4 then pi:=ina.size;
                 while pi>0 do
                   begin
                     result:=result shl 8;
                     result:=result or (ina.Head+pi-1)^;
                     dec(pi);
                   end;
               end;
    ARV_Float :begin
                 Auf.Script.send_error('警告：浮点型不支持to_dword转换');
                 result:=0;
               end;
    ARV_Char  :begin
                 Auf.Script.send_error('警告：暂不支持字符型的to_dword转换');
                 result:=0;
               end;
    else {raise Exception.Create('错误的ARV类型，不能转换为字符串')}begin Auf.Script.send_error('错误的ARV类型，不能转换为字符');result:=0;exit end;
  end;
end;
function arv_to_double(ina:TAufRamVar):double;
var pi:byte;
begin
  result:=0;
  case ina.VarType of
    ARV_FixNum:begin
                 result:=0;
                 pi:=4;
                 if ina.size<4 then pi:=ina.size;
                 while pi>0 do
                   begin
                     result:=result*256;
                     result:=result+(ina.Head+pi-1)^;
                     dec(pi);
                   end;
               end;
    ARV_Float :begin
                 Auf.Script.send_error('警告：浮点型不支持to_double转换');
                 result:=0;
               end;
    ARV_Char  :begin
                 Auf.Script.send_error('警告：暂不支持字符型的to_double转换');
                 result:=0;
               end;
    else {raise Exception.Create('错误的ARV类型，不能转换为字符串')}begin Auf.Script.send_error('警告：错误的ARV类型，不能转换为字符串');exit end;
  end;
end;

procedure initiate_arv(exp:string;var arv:TAufRamVar);//根据字符串创建最大相似的ARV，非临时性ARV位数按规定赋值，临时性最大还原字符串
var size,len,pi:integer;
    str,stmp:string;
begin
  str:=exp;
  if exp[length(exp)] in ['h','H'] then
    begin
      delete(str,length(str),1);
      len:=length(str);
      size:=len div 2 + len mod 2;
      if arv.Is_Temporary then
        begin
          arv.size:=size;
          arv.VarType:=ARV_FixNum;
          arv.Stream.Free;
          arv.Stream.Create;
          arv.Stream.Size:=size;
          arv.Head:=arv.Stream.Memory;
        end
      else
        begin
          arv.VarType:=ARV_FixNum;
          if not assignedARV(arv) then raise Exception.Create('[initiate_arv]非临时性ARV地址有误');
        end;
      while length(str)>arv.size*2 do delete(str,1,1);
      while length(str)<arv.size*2 do str:='0'+str;
      pi:=0;
      while length(str)>=2 do
        begin
          stmp:=str[length(str)-1]+str[length(str)];
          delete(str,length(str)-1,2);
          (arv.Head+pi)^:=HexToDword(stmp) mod 256;
          inc(pi);
        end;
    end
  else
    begin
      Auf.Script.send_error('警告：暂时不支持十六进制以外的整型数和浮点型');
      //raise Exception.Create('暂时不支持十六进制以外的整型数和浮点型');
    end;
end;

procedure initiate_arv_str(exp:string;var arv:TAufRamVar);//根据字符串创建字符串的ARV，非临时性ARV位数按规定赋值，临时性以参数位数为准
var size,len,pi:integer;
    str,stmp:string;
begin
  str:=exp;
  len:=length(str);
  size:=len;
  if arv.Is_Temporary then
    begin
      arv.size:=size;
      arv.VarType:=ARV_Char;
      arv.Stream.Free;
      arv.Stream.Create;
      arv.Stream.Size:=size;
      arv.Head:=arv.Stream.Memory;
    end
  else
    begin
      arv.VarType:=ARV_Char;
      if not assignedARV(arv) then raise Exception.Create('[initiate_arv_str]非临时性ARV地址有误');
    end;
  while length(str)>arv.size do delete(str,1,1);
  while length(str)<arv.size do str:=#0+str;
  pi:=0;
  while length(str)>0 do
    begin
      stmp:=str[length(str)];
      delete(str,length(str),1);
      (arv.Head+pi)^:=ord(stmp[1]);
      inc(pi);
    end;
end;

end.

