unit auf_ram_var;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LazUTF8;

type
  TAufRamVarType = (ARV_Raw=0,ARV_FixNum=1,ARV_Float=2,ARV_Char=3);
  TAufRamVar = record
    VarType:TAufRamVarType;
    Head:pbyte;
    size:dword;
    Is_Temporary:boolean;//是否是运算符重载计算时临时产生的内存流数据
    Stream:TMemoryStream;//如果是，这里是内存流的指针
  end;

  TDecimalStr = record
    data:string;
  end;
  //+000000000000000
  //-000000000000000
  TRealStr = record
    data:string;
  end;
  //+000000.00000
  //-.0000000

  function DecimalStr(str:string):TDecimalStr;
  function number_std(var s:string):char; //标准化DecimalStr为绝对值，同时返回符号

  function DecimalStr_Comp(ina,inb:TDecimalStr):smallint;
  function DecimalStr_Abs_Comp(ina,inb:TDecimalStr):smallint;
  function DecimalStr_Abs_Add(ina,inb:TDecimalStr):TDecimalStr;
  function DecimalStr_Abs_Sub(ina,inb:TDecimalStr):TDecimalStr;//a为被减数，b为减数
  function DecimalStr_Abs_Mul(ina,inb:TDecimalStr):TDecimalStr;
  procedure DecimalStr_Abs_Div(ina,inb:TDecimalStr;var oua,oub:TDecimalStr);//Ia为被除数, Ib为除数, Oa为商, Ob为余数
  operator +(ina,inb:TDecimalStr):TDecimalStr;
  operator -(ina,inb:TDecimalStr):TDecimalStr;
  operator *(ina,inb:TDecimalStr):TDecimalStr;
  operator div(ina,inb:TDecimalStr):TDecimalStr;
  operator mod(ina,inb:TDecimalStr):TDecimalStr;
  operator /(ina,inb:TDecimalStr):TDecimalStr;
  operator >(ina,inb:TDecimalStr):boolean;
  operator <(ina,inb:TDecimalStr):boolean;
  operator =(ina,inb:TDecimalStr):boolean;
  operator <>(ina,inb:TDecimalStr):boolean;
  operator >=(ina,inb:TDecimalStr):boolean;
  operator <=(ina,inb:TDecimalStr):boolean;

  procedure RealStrToDecimalStr(const inp:TRealStr;var integ,fract:TDecimalStr;var sgn:char);//将实数串分为三个部分，sgn=#0时转换错误
  function RealStr(str:string):TRealStr;

  function RealStr_Comp(ina,inb:TRealStr):smallint;
  function RealStr_Abs_Comp(ina,inb:TRealStr):smallint;

  function RealStr_Abs_Add(ina,inb:TRealStr):TRealStr;
  function RealStr_Abs_Sub(ina,inb:TRealStr):TRealStr;//a为被减数，b为减数
  function RealStr_Abs_Mul(ina,inb:TRealStr):TRealStr;
  function RealStr_Abs_Div(ina,inb:TRealStr;fraction_length:longint):TRealStr;//Ia为被除数, Ib为除数，fl为小数数位

  operator +(ina,inb:TRealStr):TRealStr;
  operator -(ina,inb:TRealStr):TRealStr;
  operator *(ina,inb:TRealStr):TRealStr;
  operator /(ina,inb:TRealStr):TRealStr;
  operator >(ina,inb:TRealStr):boolean;
  operator <(ina,inb:TRealStr):boolean;
  operator =(ina,inb:TRealStr):boolean;
  operator <>(ina,inb:TRealStr):boolean;
  operator >=(ina,inb:TRealStr):boolean;
  operator <=(ina,inb:TRealStr):boolean;



  procedure newARV(var inp:TAufRamVar;Size:dword);
  procedure freeARV(inp:TAufRamVar);
  function assignedARV(inp:TAufRamVar):boolean;
  procedure copyARV(ori_arv:TAufRamVar;var new_arv:TAufRamVar);

  procedure fixnum_add(ina,inb:TAufRamVar;var oup:TAufRamVar);
  procedure fixnum_sub(ina,inb:TAufRamVar;var oup:TAufRamVar);

  {
  procedure ARV_add(ina,inb:TAufRamVar;var oup:TAufRamVar);
  procedure ARV_sub(ina,inb:TAufRamVar;var oup:TAufRamVar);
  procedure ARV_mul(ina,inb:TAufRamVar;var oup:TAufRamVar);
  procedure ARV_div(ina,inb:TAufRamVar;var oup:TAufRamVar);
  procedure ARV_mod(ina,inb:TAufRamVar;var oup:TAufRamVar);
  }

  function ARV_EqlZero(inp:TAufRamVar):boolean;
  function ARV_comp(ina,inb:TAufRamVar):smallint;//ina<=>inb

  procedure ARV_shl(var inp:TAufRamVar;bit:qword);
  procedure ARV_shr(var inp:TAufRamVar;bit:qword);
  procedure ARV_not(var inp:TAufRamVar);
  procedure ARV_and(var ina:TAufRamVar;const inb:TAufRamVar);
  procedure ARV_or(var ina:TAufRamVar;const inb:TAufRamVar);
  procedure ARV_xor(var ina:TAufRamVar;const inb:TAufRamVar);

  procedure ARV_add(var ina:TAufRamVar;const inb:TAufRamVar);
  procedure ARV_add2(var ina:TAufRamVar;const inb:TAufRamVar);
  procedure ARV_sub(var ina:TAufRamVar;const inb:TAufRamVar);
  procedure ARV_mul(var ina:TAufRamVar;const inb:TAufRamVar);
  procedure ARV_mul2(var ina:TAufRamVar;const inb:TAufRamVar);

  procedure ARV_div(var ina:TAufRamVar;const inb:TAufRamVar);
  procedure ARV_mod(var ina:TAufRamVar;const inb:TAufRamVar);



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
  function arv_to_dec(ina:TAufRamVar):string;
  function arv_to_dec_fraction(ina:TAufRamVar):string;//小数点后
  function arv_to_dword(ina:TAufRamVar):dword;
  function arv_to_double(ina:TAufRamVar):double;

  procedure dec_to_arv(ina:TDecimalStr;oua:TAufRamVar);

  procedure s_to_arv(s:string;oup:TAufRamVar);
  procedure dword_to_arv(d:dword;oup:TAufRamVar);
  procedure double_to_arv(d:double;oup:TAufRamVar);

  procedure initiate_arv(exp:string;var arv:TAufRamVar);//根据字符串创建最大相似的ARV
  procedure initiate_arv_str(exp:RawByteString;var arv:TAufRamVar);//根据字符串创建字符串的ARV


var

  MaxDivDigit:dword;

implementation

uses Apiglio_Useful;


function DecimalStr(str:string):TDecimalStr;
begin
  result.data:=str;
end;

function number_std(var s:string):char; //标准化DecimalStr为绝对值，同时返回符号
begin
  if length(s)=0 then begin result:='+';s:='0';exit end;
  case s[1] of
    '-','+':begin result:=s[1];delete(s,1,1)end;
    else result:='+';
  end;
  while (length(s)>1)and(s[1] ='0') do delete(s,1,1);
  if pos('.',s)>0 then begin
    while s[length(s)]='0' do delete(s,length(s),1)
  end;
  if s='.' then s:='0';
  //{$ifdef TEST_MODE}SysWriteln('std='+s);{$endif}
end;

function DecimalStr_Comp(ina,inb:TDecimalStr):smallint;
var minus:smallint;
    digit:longint;

    function cmp(a,b:longint):smallint;
    begin
      if a>b then result:=1
      else if a<b then result:=-1
      else result:=0;
    end;
begin
  if not (ina.data[1] in ['+','-']) then ina.data:='+'+ina.data;
  if not (inb.data[1] in ['+','-']) then inb.data:='+'+inb.data;
  case ina.data[1] of
    '+':case inb.data[1] of
          '+':minus:=1;
          '-':begin result:=1;exit end;
        end;
    '-':case inb.data[1] of
          '+':begin result:=-1;exit end;
          '-':minus:=-1;
        end;
  end;
  case cmp(length(ina.data),length(inb.data)) of
    1:begin result:=minus;exit end;
    0:;
   -1:begin result:=-minus;exit end;
  end;
  for digit:=2 to length(ina.data) do
    begin
      case cmp(ord(ina.data[digit]),ord(inb.data[digit])) of
        1:begin result:=minus;exit end;
        0:;
       -1:begin result:=-minus;exit end;
      end;
    end;
  result:=0;
end;
function DecimalStr_Abs_Comp(ina,inb:TDecimalStr):smallint;
var digit:longint;
    function cmp(a,b:longint):smallint;
    begin
      if a>b then result:=1
      else if a<b then result:=-1
      else result:=0;
    end;
begin
  if (ina.data[1] in ['+','-']) then delete(ina.data,1,1);
  if (inb.data[1] in ['+','-']) then delete(inb.data,1,1);
  case cmp(length(ina.data),length(inb.data)) of
    1:begin result:=1;exit end;
    0:;
   -1:begin result:=-1;exit end;
  end;
  for digit:=1 to length(ina.data) do
    begin
      case cmp(ord(ina.data[digit]),ord(inb.data[digit])) of
        1:begin result:=1;exit end;
        0:;
       -1:begin result:=-1;exit end;
      end;
    end;
  result:=0;
end;
operator >(ina,inb:TDecimalStr):boolean;
begin
  if DecimalStr_Comp(ina,inb)=1 then result:=true
  else result:=false;
end;
operator <(ina,inb:TDecimalStr):boolean;
begin
  if DecimalStr_Comp(ina,inb)=-1 then result:=true
  else result:=false;
end;
operator =(ina,inb:TDecimalStr):boolean;
begin
  if DecimalStr_Comp(ina,inb)=0 then result:=true
  else result:=false;
end;
operator <>(ina,inb:TDecimalStr):boolean;
begin
  if DecimalStr_Comp(ina,inb)<>0 then result:=true
  else result:=false;
end;
operator >=(ina,inb:TDecimalStr):boolean;
begin
  if DecimalStr_Comp(ina,inb)<>-1 then result:=true
  else result:=false;
end;
operator <=(ina,inb:TDecimalStr):boolean;
begin
  if DecimalStr_Comp(ina,inb)<>1 then result:=true
  else result:=false;
end;
function DecimalStr_Abs_Add(ina,inb:TDecimalStr):TDecimalStr;
var sgna,sgnb:char;
    digit:longint;
    acc,yc:smallint;
begin
  if ina.data[1] = '-' then begin
    delete(ina.data,1,1);
    sgna:='-';
  end else begin
    sgna:='+';
    if ina.data[1]='+' then delete(ina.data,1,1);
  end;
  if inb.data[1] = '-' then begin
    delete(inb.data,1,1);
    sgnb:='-';
  end else begin
    sgnb:='+';
    if inb.data[1]='+' then delete(inb.data,1,1);
  end;
  while length(ina.data)>length(inb.data) do inb.data:='0'+inb.data;
  while length(inb.data)>length(ina.data) do ina.data:='0'+ina.data;
  ina.data:='0'+ina.data;
  inb.data:='0'+inb.data;
  result.data:=ina.data;//占个坑
  acc:=0;yc:=0;
  for digit:=length(ina.data) downto 1 do
    begin
      acc:=ord(ina.data[digit])-ord('0')+ord(inb.data[digit])-ord('0')+yc;
      yc:=acc div 10;
      acc:=acc mod 10;
      result.data[digit]:=chr(acc+ord('0'));
    end;
  while (result.data[1]='0')and(length(result.data)>1) do delete(result.data,1,1);
  while (ina.data[1]='0')and(length(ina.data)>1) do delete(ina.data,1,1);
  while (inb.data[1]='0')and(length(inb.data)>1) do delete(inb.data,1,1);
  ina.data:=sgna+ina.data;
  inb.data:=sgnb+inb.data;
end;
function DecimalStr_Abs_Sub(ina,inb:TDecimalStr):TDecimalStr;//a必须绝对值大于b
var sgna,sgnb:char;
    digit:longint;
    acc,yc:smallint;
begin
  if ina.data[1] = '-' then begin
    delete(ina.data,1,1);
    sgna:='-';
  end else begin
    sgna:='+';
    if ina.data[1]='+' then delete(ina.data,1,1);
  end;
  if inb.data[1] = '-' then begin
    delete(inb.data,1,1);
    sgnb:='-';
  end else begin
    sgnb:='+';
    if inb.data[1]='+' then delete(inb.data,1,1);
  end;
  while length(ina.data)>length(inb.data) do inb.data:='0'+inb.data;
  while length(inb.data)>length(ina.data) do ina.data:='0'+ina.data;
  ina.data:='0'+ina.data;
  inb.data:='0'+inb.data;
  result.data:=ina.data;//占个坑
  acc:=0;yc:=0;
  for digit:=length(ina.data) downto 1 do
    begin
      acc:=ord(ina.data[digit])-ord(inb.data[digit])+yc;
      if acc<0 then begin yc:=-1;inc(acc,10) end else yc:=0;
      acc:=acc mod 10;
      result.data[digit]:=chr(acc+ord('0'));
    end;
  while (result.data[1]='0')and(length(result.data)>1) do delete(result.data,1,1);
  while (ina.data[1]='0')and(length(ina.data)>1) do delete(ina.data,1,1);
  while (inb.data[1]='0')and(length(inb.data)>1) do delete(inb.data,1,1);
  ina.data:=sgna+ina.data;
  inb.data:=sgnb+inb.data;
end;
function DecimalStr_Abs_Mul(ina,inb:TDecimalStr):TDecimalStr;
var sgna,sgnb:char;
    dig1,dig2:longint;
    acc,ten:smallint;
    procedure AddToDigit(dig:longint;value:dword);
    var tmp:dword;
    begin
      tmp:=ord(result.data[dig])-ord('0');
      tmp:=tmp+value;
      if tmp>=10 then AddToDigit(dig-1,tmp div 10);
      tmp:=tmp mod 10;
      result.data[dig]:=chr(tmp+ord('0'));
    end;

begin
  if ina.data[1] = '-' then begin
    delete(ina.data,1,1);
    sgna:='-';
  end else begin
    sgna:='+';
    if ina.data[1]='+' then delete(ina.data,1,1);
  end;
  if inb.data[1] = '-' then begin
    delete(inb.data,1,1);
    sgnb:='-';
  end else begin
    sgnb:='+';
    if inb.data[1]='+' then delete(inb.data,1,1);
  end;
  result.data:='';
  while length(result.data)<=length(ina.data)+length(inb.data) do
    result.data:=result.data+'0';
  for dig1:=length(ina.data) downto 1 do
    for dig2:=length(inb.data) downto 1 do
      begin
        acc:=(ord(ina.data[dig1])-ord('0'))*(ord(inb.data[dig2])-ord('0'));
        ten:=acc div 10;
        acc:=acc mod 10;
        AddToDigit(length(result.data)-(length(ina.data)-dig1+length(inb.data)-dig2),acc);
        AddToDigit(length(result.data)-(length(ina.data)-dig1+length(inb.data)-dig2)-1,ten);
      end;
  while (result.data[1]='0')and(length(result.data)>1) do delete(result.data,1,1);
  while (ina.data[1]='0')and(length(ina.data)>1) do delete(ina.data,1,1);
  while (inb.data[1]='0')and(length(inb.data)>1) do delete(inb.data,1,1);
  ina.data:=sgna+ina.data;
  inb.data:=sgnb+inb.data;
end;
operator +(ina,inb:TDecimalStr):TDecimalStr;
begin
  if ina.data[1]='-' then begin
    if inb.data[1]='-' then begin
      result:=DecimalStr_Abs_ADD(ina,inb);
      result.data:='-'+result.data;
    end else begin
      case DecimalStr_Abs_Comp(ina,inb) of
        1:begin result:=DecimalStr_Abs_SUB(ina,inb);result.data:='-'+result.data end;
        0:result.data:='0';
       -1:begin result:=DecimalStr_Abs_SUB(inb,ina);result.data:='+'+result.data end;
      end;
    end;
  end else begin
    if inb.data[1]='-' then begin
      case DecimalStr_Abs_Comp(ina,inb) of
        1:begin result:=DecimalStr_Abs_SUB(ina,inb);result.data:='+'+result.data end;
        0:result.data:='0';
       -1:begin result:=DecimalStr_Abs_SUB(inb,ina);result.data:='-'+result.data end;
      end;
    end else begin
      result:=DecimalStr_Abs_ADD(ina,inb);
      result.data:='+'+result.data;
    end;
  end;
end;
operator -(ina,inb:TDecimalStr):TDecimalStr;
begin
  if ina.data[1]='-' then begin
    if inb.data[1]='-' then begin
      case DecimalStr_Abs_Comp(ina,inb) of
        1:begin result:=DecimalStr_Abs_SUB(ina,inb);result.data:='-'+result.data end;
        0:result.data:='0';
       -1:begin result:=DecimalStr_Abs_SUB(inb,ina);result.data:='+'+result.data end;
      end;
    end else begin
        result:=DecimalStr_Abs_ADD(ina,inb);
        result.data:='-'+result.data;
    end;
  end else begin
    if inb.data[1]='-' then begin
      result:=DecimalStr_Abs_ADD(ina,inb);
      result.data:='+'+result.data;
    end else begin
        case DecimalStr_Abs_Comp(ina,inb) of
          1:begin result:=DecimalStr_Abs_SUB(ina,inb);result.data:='+'+result.data end;
          0:result.data:='0';
         -1:begin result:=DecimalStr_Abs_SUB(inb,ina);result.data:='-'+result.data end;
        end;
    end;
  end;
end;
operator *(ina,inb:TDecimalStr):TDecimalStr;
begin
  result:=DecimalStr_Abs_MUL(ina,inb);
  if ina.data[1]='-' then begin
    if inb.data[1]='-' then begin
      result.data:='+'+result.data;
    end else begin
            result.data:='-'+result.data;
    end;
  end else begin
    if inb.data[1]='-' then begin
      result.data:='-'+result.data;
    end else begin
      result.data:='+'+result.data;
    end;
  end;
end;
procedure DecimalStr_Abs_Div(ina,inb:TDecimalStr;var oua,oub:TDecimalStr);//Ia为被除数, Ib为除数, Oa为商, Ob为余数
var outA,outB,tmpDiv,tmpAdd:TDecimalStr;
    digit,zerodigit:longint;
    zerotile:string;
begin
  while length(ina.data)<length(inb.data) do ina.data:='0'+ina.data;
  outB:=ina;
  outA.data:='';
  while ina.data[1] in ['+','-','0'] do begin delete(ina.data,1,1);if ina.data='' then break end;
  //writeln('ina=',ina.data);
  while length(outA.data)<length(outB.data) do outA.data:='0'+outA.data;
  for digit:=length(ina.data)-length(inb.data) downto 0 do
    begin
      zerotile:='';
      for zerodigit:=1 to digit do zerotile:=zerotile+'0';
      tmpDiv:=inb;
      tmpDiv.data:=tmpDiv.data+zerotile;
      while tmpDiv<=outB do
        begin
          outB:=outB-tmpDiv;
          tmpAdd.data:='1'+zerotile;
          outA:=outA+tmpAdd;
          while length(outA.data)>length(ina.data) do delete(outA.data,1,1);//实数高精做好后原本的math_h_arithmetics取消后直接修改运算符
        end;
      //writeln('tmpD=',tmpDiv.data);
      //writeln('outA=',outA.data);
    end;
  if outA.data[1] in ['+','-'] then delete(outA.data,1,1);
  if outB.data[1] in ['+','-'] then delete(outB.data,1,1);
  while (outA.data[1]='0')and(length(outA.data)>1) do delete(outA.data,1,1);
  while (outB.data[1]='0')and(length(outB.data)>1) do delete(outB.data,1,1);
  oua:=outA;
  oub:=outB;
end;
operator div(ina,inb:TDecimalStr):TDecimalStr;
var oua,oub:TDecimalStr;
    asgn,bsgn:char;
begin
  case ina.data[1] of
    '+','-':begin asgn:=ina.data[1];delete(ina.data,1,1);end;
    else asgn:='+';
  end;
  case inb.data[1] of
    '+','-':begin bsgn:=inb.data[1];delete(inb.data,1,1);end;
    else bsgn:='+';
  end;

  DecimalStr_Abs_DIV(ina,inb,oua,oub);
  result:=oua;
  if asgn<>bsgn then result.data:='-'+result.data
  else result.data:='+'+result.data;
end;
operator mod(ina,inb:TDecimalStr):TDecimalStr;
var oua,oub:TDecimalStr;
begin
  DecimalStr_Abs_DIV(ina,inb,oua,oub);
  result:=oub;
  result.data:='+'+result.data;
end;


operator /(ina,inb:TDecimalStr):TDecimalStr;
var divtmp,oua,oub,zero,roundnum,fraction:TDecimalStr;
    asgn,bsgn:char;
    modlist:TStrings;
    stmp:string;
    repeated:boolean;
begin
  divtmp:=ina;
  if ina.data[1] in ['+','-'] then delete(ina.data,1,1);
  if inb.data[1] in ['+','-'] then delete(inb.data,1,1);
  zero.data:='0';
  fraction.data:='';
  //{}Writeln('ina='+ina.data);
  //{}Writeln('inb='+inb.data);
  DecimalStr_Abs_DIV(ina,inb,oua,oub);
  roundnum:=oua;
  //{}Writeln('rnd='+roundnum.data);
  //modlist:=TStringList.Create;
  //repeated:=false;
  while oub<>zero do
    begin
      divtmp.data:=oub.data+'0';
      DecimalStr_Abs_DIV(divtmp,inb,oua,oub);
      fraction.data:=fraction.data+oua.data[length(oua.data)];
      //{}Writeln('fra='+fraction.data);
      //if modlist.count>0 then for stmp in modlist do if oub.data=stmp then begin repeated:=true;break end;
      //if repeated then break;
      if length(fraction.data)>MaxDivDigit then break;
      //modlist.Add(oub.data);
    end;
  //if asgn<>bsgn then roundnum.data[1]:='-';
  result.data:=roundnum.data+'.'+fraction.data;
  //if repeated then result.data:=result.data+'...';
end;



function RawDecimalAdd(var oup:TDecimalStr;const ina,inb:TDecimalStr):boolean;
var pi:longint;
    tmp,yc:byte;
begin
  if length(ina.data)<>length(inb.data) then raise Exception.Create('RawDecimalAdd需要相同长度的变量');
  yc:=0;
  oup.data:=ina.data;
  for pi:=length(ina.data) downto 1 do
    begin
      tmp:=ord(ina.data[pi])+ord(inb.data[pi])-ord('0')-ord('0')+yc;
      if tmp>=10 then begin yc:=1;tmp:=tmp mod 10;end
      else yc:=0;
      oup.data[pi]:=chr(ord('0')+tmp);
    end;
  if yc<>0 then result:=true
  else result:=false;
end;
function RawDecimalSub(var oup:TDecimalStr;const ina,inb:TDecimalStr):boolean;
var pi:longint;
    tmp,yc:smallint;
begin
  if length(ina.data)<>length(inb.data) then raise Exception.Create('RawDecimalSub需要相同长度的变量');
  yc:=0;
  oup.data:=ina.data;
  for pi:=length(ina.data) downto 1 do
    begin
      tmp:=ord(ina.data[pi])-ord(inb.data[pi])-yc;
      if tmp<0 then begin yc:=1;tmp:=tmp + 10;end
      else yc:=0;
      oup.data[pi]:=chr(ord('0')+tmp);
    end;
  if yc<>0 then result:=true
  else result:=false;
end;


procedure RealStrToDecimalStr(const inp:TRealStr;var integ,fract:TDecimalStr;var sgn:char);
//将实数串分为三个部分，sgn=#0时转换错误
var poss:longint;
begin
  sgn:=#0;
  if inp.data='' then exit;
  poss:=pos('.',inp.data);
  if poss>0 then
    begin
      integ.data:=inp.data;
      fract.data:=inp.data;
      delete(integ.data,poss,length(integ.data));
      delete(fract.data,1,poss);
    end
  else
    begin
      integ.data:=inp.data;
      fract.data:='';
    end;
  if integ.data='' then integ.data:='0';
  case integ.data[1] of
    '-','+':begin sgn:=integ.data[1];delete(integ.data,1,1);end;
    else sgn:='+';
  end;
  if integ.data='' then integ.data:='0';
  poss:=length(fract.data);
  if poss<>0 then
  while fract.data[poss]='0' do
    begin
      delete(fract.data,poss,1);
      dec(poss);
      if poss=0 then break;
    end;
  for poss:=1 to length(integ.data) do if not (integ.data[poss] in ['0'..'9']) then begin sgn:=#0;exit;end;
  for poss:=1 to length(fract.data) do if not (fract.data[poss] in ['0'..'9']) then begin sgn:=#0;exit;end;

end;
function RealStr(str:string):TRealStr;
begin
  result.data:=str;
end;
function RealStr_Abs_Comp(ina,inb:TRealStr):smallint;
var ai,af,bi,bf:TDecimalStr;
    asgn,bsgn:char;
    pi,min_len:longint;
begin
  RealStrToDecimalStr(ina,ai,af,asgn);
  RealStrToDecimalStr(inb,bi,bf,bsgn);
  result:=DecimalStr_Abs_Comp(ai,bi);
  if result<>0 then exit;
  min_len:=length(af.data);
  pi:=length(bf.data);
  if pi<min_len then min_len:=pi;
  for pi:=1 to min_len do
    begin
      if ord(af.data[pi])>ord(bf.data[pi]) then begin result:=1;exit end
      else if ord(af.data[pi])<ord(bf.data[pi]) then begin result:=-1;exit end
      else ;
    end;
  if length(af.data)>pi then result:=1;
  if length(bf.data)>pi then result:=-1;
end;
function RealStr_Comp(ina,inb:TRealStr):smallint;
var ai,af,bi,bf:TDecimalStr;
    asgn,bsgn:char;
begin
  RealStrToDecimalStr(ina,ai,af,asgn);
  RealStrToDecimalStr(inb,bi,bf,bsgn);
  if asgn<>bsgn then
    begin
      if asgn='+' then result:=1
      else result:=-1;
      exit;
    end
  else
    begin
      result:=RealStr_Abs_Comp(ina,inb);
      if asgn='-' then result:=-result;
    end;
end;
function RealStr_Abs_Add(ina,inb:TRealStr):TRealStr;
var ai,af,bi,bf,ci,cf:TDecimalStr;
    asgn,bsgn:char;
begin
  RealStrToDecimalStr(ina,ai,af,asgn);
  RealStrToDecimalStr(inb,bi,bf,bsgn);
  while length(af.data)>length(bf.data) do bf.data:=bf.data+'0';
  while length(bf.data)>length(af.data) do af.data:=af.data+'0';

  if RawDecimalAdd(cf,af,bf) then
    ci:=ai+bi+DecimalStr('1')
  else
    ci:=ai+bi;

  if cf.data<>'' then if cf.data[1] in ['+','-'] then delete(cf.data,1,1);
  result.data:=ci.data;
  if cf.data<>'' then result.data:=result.data+'.'+cf.data;
end;
function RealStr_Abs_Sub(ina,inb:TRealStr):TRealStr;//a为被减数，b为减数
var ai,af,bi,bf,ci,cf:TDecimalStr;
    asgn,bsgn:char;
begin
  RealStrToDecimalStr(ina,ai,af,asgn);
  RealStrToDecimalStr(inb,bi,bf,bsgn);
  while length(af.data)>length(bf.data) do bf.data:=bf.data+'0';
  while length(bf.data)>length(af.data) do af.data:=af.data+'0';

  if RawDecimalSub(cf,af,bf) then
    ci:=ai-bi-DecimalStr('1')
  else
    ci:=ai-bi;

  if cf.data<>'' then if cf.data[1] in ['+','-'] then delete(cf.data,1,1);
  result.data:=ci.data;
  if cf.data<>'' then result.data:=result.data+'.'+cf.data;
end;
function RealStr_Abs_Mul(ina,inb:TRealStr):TRealStr;
var ai,af,bi,bf,ci,cf:TDecimalStr;
    asgn,bsgn:char;
    ae,be:longint;
begin
  RealStrToDecimalStr(ina,ai,af,asgn);
  RealStrToDecimalStr(inb,bi,bf,bsgn);
  ae:=length(af.data);
  be:=length(bf.data);
  ai.data:=ai.data+af.data;
  bi.data:=bi.data+bf.data;
  ci:=ai*bi;
  ae:=ae+be;
  if ci.data<>'' then if ci.data[1] in ['+','-'] then delete(ci.data,1,1);
  be:=pos('.',ci.data);
  if be>0 then delete(ci.data,be,2);
  while length(ci.data)<ae+1 do ci.data:='0'+ci.data;
  cf.data:=ci.data;
  be:=length(ci.data);
  delete(cf.data,1,be-ae);
  delete(ci.data,be-ae+1,be);
  result.data:='u'+ci.data;
  if cf.data<>'' then result.data:=result.data+'.'+cf.data;
end;
function RealStr_Abs_Div(ina,inb:TRealStr;fraction_length:longint):TRealStr;//Ia为被除数, Ib为除数，fl为小数数位
label FixN;
var ai,af,bi,bf,ci,cf:TDecimalStr;
    asgn,bsgn:char;
    ae,be:longint;
begin
  RealStrToDecimalStr(ina,ai,af,asgn);
  RealStrToDecimalStr(inb,bi,bf,bsgn);
  ae:=length(af.data);
  be:=length(bf.data);
  if be<=ae then begin
    bi.data:=bi.data+bf.data;
    ai.data:=ai.data+af.data;
    delete(ai.data,length(ai.data)-ae+be+1,ae-be);
    delete(af.data,1,length(af.data)-ae+be);
  end else begin
    bi.data:=bi.data+bf.data;
    ai.data:=ai.data+af.data;
    af.data:='';
    while be>ae do
      begin
        ai.data:=ai.data+'0';
        inc(ae);
      end;
  end;
  while bi.data[1] in ['+','-','0'] do delete(bi.data,1,1);//如果是0会直接报错
  //writeln('a=',ai.data+'.'+af.data);
  //writeln('b=',bi.data);
  ci:=ai div bi;
  bf:=ai mod bi;
  //writeln('ci=',ci.data);
  //writeln('bf=',bf.data);
  if (bf=DecimalStr('0'))and(af.data='') then goto FixN; //   0.125 -> 0.0625开始错误
  {len}ae:=length(af.data);
  bf.data:=bf.data+af.data+'0';
  if bf.data[1] in ['-','+'] then delete(bf.data,1,1);
  cf.data:='';
  while length(cf.data)<fraction_length do
    begin
      //writeln('bf=',bf.data);
      //writeln('bi=',bi.data);
      DecimalStr_Abs_Div(bf,bi,af,ai);
      //writeln('af=',af.data);
      //writeln('ai=',ai.data);
      //writeln;
      //writeln('cf=',cf.data);
      //writeln;
      while length(af.data)<={len}ae do af.data:='0'+af.data;
      cf.data:=cf.data+af.data;
      if ai=DecimalStr('0') then break;
      bf.data:=ai.data+'0';
      {len}ae:=0;
    end;
FixN:
  result.data:=ci.data;
  if cf.data<>'' then result.data:=result.data+'.'+cf.data;
end;

operator +(ina,inb:TRealStr):TRealStr;
var asgn,bsgn:char;
    ai,af,bi,bf:TDecimalStr;
    //res:TRealStr;
begin
  RealStrToDecimalStr(ina,ai,af,asgn);
  RealStrToDecimalStr(inb,bi,bf,bsgn);
  if asgn=bsgn then begin
    result:=RealStr_Abs_Add(ina,inb);
    result.data[1]:=asgn;
  end else begin
    case RealStr_Abs_Comp(ina,inb) of
      1:
      begin
        result:=RealStr_Abs_Sub(ina,inb);
        result.data[1]:=asgn;
      end;
     -1:
      begin
        result:=RealStr_Abs_Sub(inb,ina);
        result.data[1]:=bsgn;
      end;
     else result.data:='+0';
    end;
  end;
end;
operator -(ina,inb:TRealStr):TRealStr;
var asgn,bsgn:char;
    ai,af,bi,bf:TDecimalStr;
    //res:TRealStr;
begin
  RealStrToDecimalStr(ina,ai,af,asgn);
  RealStrToDecimalStr(inb,bi,bf,bsgn);
  if asgn=bsgn then begin
    case RealStr_Abs_Comp(ina,inb) of
      1:
      begin
        result:=RealStr_Abs_Sub(ina,inb);
        result.data[1]:=asgn;
      end;
     -1:
      begin
        result:=RealStr_Abs_Sub(inb,ina);
        result.data[1]:=asgn;
      end;
     else result.data:='+0';
    end;
  end else begin
    result:=RealStr_Abs_Add(ina,inb);
    result.data[1]:=asgn;
  end;
end;
operator *(ina,inb:TRealStr):TRealStr;
var asgn,bsgn:char;
    ai,af,bi,bf:TDecimalStr;
    //res:TRealStr;
begin
  RealStrToDecimalStr(ina,ai,af,asgn);
  RealStrToDecimalStr(inb,bi,bf,bsgn);
  if asgn=bsgn then begin
    result:=RealStr_Abs_Mul(ina,inb);
    result.data[1]:='+';
  end else begin
    result:=RealStr_Abs_Mul(ina,inb);
    result.data[1]:='-';
  end;
end;
operator /(ina,inb:TRealStr):TRealStr;//使用之前需要设置MaxDivDigit
var asgn,bsgn:char;
    ai,af,bi,bf:TDecimalStr;
    //res:TRealStr;
begin
  RealStrToDecimalStr(ina,ai,af,asgn);
  RealStrToDecimalStr(inb,bi,bf,bsgn);
  { TODO : 这里ARV整数显示为小数点后数字的方法只接受4000H，更高的情况会陷入死循环，需要处理。
以下是测试代码：

mov $4[],00008000h
ptest $4[] }
  if asgn=bsgn then begin
    result:=RealStr_Abs_Div(ina,inb,MaxDivDigit);
    result.data[1]:='+';
  end else begin
    result:=RealStr_Abs_Div(ina,inb,MaxDivDigit);
    result.data[1]:='-';
  end;
end;

operator >(ina,inb:TRealStr):boolean;
begin
  if RealStr_Comp(ina,inb)>0 then result:=true
  else result:=false;
end;
operator <(ina,inb:TRealStr):boolean;
begin
  if RealStr_Comp(ina,inb)<0 then result:=true
  else result:=false;
end;
operator =(ina,inb:TRealStr):boolean;
begin
  if RealStr_Comp(ina,inb)=0 then result:=true
  else result:=false;
end;
operator <>(ina,inb:TRealStr):boolean;
begin
  if RealStr_Comp(ina,inb)<>0 then result:=true
  else result:=false;
end;
operator >=(ina,inb:TRealStr):boolean;
begin
  if RealStr_Comp(ina,inb)>=0 then result:=true
  else result:=false;
end;
operator <=(ina,inb:TRealStr):boolean;
begin
  if RealStr_Comp(ina,inb)<=0 then result:=true
  else result:=false;
end;




procedure newARV(var inp:TAufRamVar;Size:dword);
begin
  inp.Is_Temporary:=true;
  if not assigned(inp.Stream) then inp.Stream.Free;
  inp.Stream:=TMemoryStream.Create;
  inp.Stream.Size:=Size;
  inp.Size:=size;
  inp.Head:=inp.Stream.Memory;
  inp.VarType:=ARV_Raw;
  //inp.Stream.Position:=Size-1;
  //inp.stream.WriteByte($00);
  inp.Stream.Position:=0;
  while inp.Stream.Position<inp.size do inp.Stream.WriteByte($00);
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

procedure copyARV(ori_arv:TAufRamVar;var new_arv:TAufRamVar);
var pi:integer;
begin
  {
  if new_arv.Is_Temporary then
    begin
      new_arv.size:=ori_arv.size;
      new_arv.Stream.Size:=new_arv.size;
    end;
  }
  pi:=0;
  while pi<new_arv.size do
    begin
      if pi<ori_arv.size then (new_arv.Head+pi)^:=(ori_arv.Head+pi)^
      else (new_arv.Head+pi)^:=0;
      inc(pi);
    end;
end;

procedure fillARV(target:byte;var arv:TAufRamVar);
var pi:integer;
begin
  pi:=0;
  while pi<arv.size do
    begin
      (arv.Head+pi)^:=target;
      inc(pi);
    end;
end;

procedure fixnum_add(ina,inb:TAufRamVar;var oup:TAufRamVar);    //这里要改一下，可以按正常的记录类型来搞
var //stream:TMemoryStream;
    digit:dword;
    ta,tb,YC:byte;

  function max_one(a,b:dword):dword;
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
    digit:dword;
    ta,tb,YC:byte;

  function max_one(a,b:dword):dword;
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




{
procedure ARV_add(ina,inb:TAufRamVar;var oup:TAufRamVar);
begin
  if (ina.VarType=ARV_FixNum) and (inb.VarType=ARV_FixNum) then fixnum_add(ina,inb,oup)
  else raise Exception.Create('暂不支持整型数以外的变量加法');
end;
procedure ARV_sub(ina,inb:TAufRamVar;var oup:TAufRamVar);
begin
  if (ina.VarType=ARV_FixNum) and (inb.VarType=ARV_FixNum) then fixnum_sub(ina,inb,oup)
  else raise Exception.Create('暂不支持整型数以外的变量减法');
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
}


function ARV_EqlZero(inp:TAufRamVar):boolean;
var pi:dword;
begin
  pi:=0;
  while pi<inp.size do
    begin
      if (inp.Head+pi)^<>0 then begin result:=false;exit end;
      inc(pi);
    end;
  result:=true;
end;
function ARV_comp(ina,inb:TAufRamVar):smallint;//ina<=>inb
var ia,ib:dword;
begin
  if ina.size*inb.size=0 then exit;
  ia:=ina.size;
  ib:=inb.size;
  repeat
    dec(ia);
    dec(ib);
    if (ina.Head+ia)^=(inb.Head+ib)^ then
      begin
        //
      end
    else if (ina.Head+ia)^>(inb.Head+ib)^ then
      begin
        result:=1;exit;
      end
    else
      begin
        result:=-1;exit;
      end;
  until (ia=0) or (ib=0);
  while ia>0 do
    begin
      if (ina.Head+ia)^<>0 then begin result:=1;exit;end;
      dec(ia);
    end;
  while ib>0 do
    begin
      if (inb.Head+ib)^<>0 then begin result:=-1;exit;end;
      dec(ib);
    end;
  result:=0;
end;

procedure ARV_shl(var inp:TAufRamVar;bit:qword);
var pi:dword;
    byte_ofs,bit_ofs:dword;
    atmp,btmp:byte;
begin
  pi:=inp.size;
  byte_ofs:=bit div 8;
  bit_ofs:=bit mod 8;
  repeat
    dec(pi);
    if pi<inp.Size+byte_ofs then atmp:=(inp.Head+pi-byte_ofs)^ shl bit_ofs
    else atmp:=0;
    if pi<inp.Size+byte_ofs+1 then btmp:=(inp.Head+pi-byte_ofs-1)^ shr (8 - bit_ofs)
    else btmp:=0;
    (inp.Head+pi)^:=atmp or btmp;
  until pi=0;
end;
procedure ARV_shr(var inp:TAufRamVar;bit:qword);
var pi:dword;
    byte_ofs,bit_ofs:dword;
    atmp,btmp:byte;
begin
  pi:=0;
  byte_ofs:=bit div 8;
  bit_ofs:=bit mod 8;
  while pi<inp.size do
    begin
      if pi+byte_ofs<inp.Size then atmp:=(inp.Head+pi+byte_ofs)^ shr bit_ofs
      else atmp:=0;
      if pi+byte_ofs+1<inp.Size then btmp:=(inp.Head+pi+byte_ofs+1)^ shl (8 - bit_ofs)
      else btmp:=0;
      (inp.Head+pi)^:=atmp or btmp;
      inc(pi);
    end;
end;
procedure ARV_not(var inp:TAufRamVar);
var pi:dword;
begin
  for pi:=0 to inp.size-1 do (inp.Head+pi)^:=not (inp.Head+pi)^;
end;
procedure ARV_and(var ina:TAufRamVar;const inb:TAufRamVar);
var pi,len:dword;
begin
  if ina.size<inb.size then len:=ina.size
  else len:=inb.size;
  for pi:=0 to len-1 do (ina.Head+pi)^:=(ina.Head+pi)^ and (inb.Head+pi)^;
  for pi:=len to ina.size-1 do (ina.Head+pi)^:=0;
end;
procedure ARV_or(var ina:TAufRamVar;const inb:TAufRamVar);
var pi,len:dword;
begin
  if ina.size<inb.size then len:=ina.size
  else len:=inb.size;
  for pi:=0 to len-1 do (ina.Head+pi)^:=(ina.Head+pi)^ or (inb.Head+pi)^;
end;
procedure ARV_xor(var ina:TAufRamVar;const inb:TAufRamVar);
var pi,len:dword;
begin
  if ina.size<inb.size then len:=ina.size
  else len:=inb.size;
  for pi:=0 to len-1 do (ina.Head+pi)^:=(ina.Head+pi)^ xor (inb.Head+pi)^;
end;

procedure ARV_add(var ina:TAufRamVar;const inb:TAufRamVar);
var pi,len:dword;
    yc:byte;
    tmp:word;
begin
  if ina.size<inb.size then len:=ina.size
  else len:=inb.size;
  yc:=0;
  for pi:=0 to len-1 do
    begin
      tmp:=(ina.Head+pi)^ + (inb.Head+pi)^ + yc;
      yc:=tmp div 256;
      (ina.Head+pi)^:=tmp mod 256;
    end;
  for pi:=len to ina.size do
    begin
      tmp:=(ina.Head+pi)^ + yc;
      yc:=tmp div 256;
      (ina.Head+pi)^:=tmp mod 256;
    end;
end;

procedure ARV_add2(var ina:TAufRamVar;const inb:TAufRamVar);deprecated;
//原理上应该更快，但是函数实现方法慢了很多，可以作为预备优化方式
var pi,len:dword;
    yc:byte;
    tmp:word;
    xo,an,t:TAufRamVar;
begin
  newARV(xo,ina.size);
  newARV(an,ina.size);
  newARV(t,ina.size);
  copyARV(inb,t);
  repeat
    copyARV(ina,xo);
    ARV_xor(xo,t);
    copyARV(ina,an);
    ARV_and(an,t);
    ARV_shl(an,1);
    copyARV(xo,ina);
    copyARV(an,t);
  until ARV_EqlZero(an);
  copyARV(ina,xo);
  freeARV(t);
  freeARV(xo);
  freeARV(an);
end;

procedure ARV_sub(var ina:TAufRamVar;const inb:TAufRamVar);
var pi,len:dword;
    yc:byte;
    tmp:smallint;
begin
  if ina.size<inb.size then len:=ina.size
  else len:=inb.size;
  yc:=0;
  for pi:=0 to len-1 do
    begin
      tmp:=(ina.Head+pi)^ - (inb.Head+pi)^ - yc;
      if tmp<0 then begin
        inc(tmp,256);
        yc:=1;
      end else yc:=0;
      (ina.Head+pi)^:=tmp;
    end;
  for pi:=len to ina.size do
    begin
      tmp:=(ina.Head+pi)^ - yc;
      if tmp<0 then begin
        inc(tmp,256);
        yc:=1;
      end else yc:=0;
      (ina.Head+pi)^:=tmp;
    end;
end;

procedure ARV_mul(var ina:TAufRamVar;const inb:TAufRamVar);
var pi:dword;
begin

end;
procedure ARV_mul2(var ina:TAufRamVar;const inb:TAufRamVar);
var tmp,acc,add:TAufRamVar;
begin
  newARV(tmp,ina.size);
  newARV(acc,ina.size);
  newARV(add,ina.size);
  copyARV(inb,tmp);
  copyARV(ina,add);
  while not ARV_EqlZero(tmp) do
    begin
      if tmp.Head^ mod 2 = 1 then
        begin
          ARV_add(acc,add);
        end;
      ARV_shl(add,1);
      ARV_shr(tmp,1);
    end;
  copyARV(acc,ina);
  freeARV(add);
  freeARV(acc);
  freeARV(tmp);
end;


procedure ARV_divmod(ina,inb:TAufRamVar;var oua,oub:TAufRamVar);
var tmp:TAufRamVar;
begin
  copyARV(ina,oub);
  fillARV(0,oua);
  newARV(tmp,ina.size);
  copyARV(inb,tmp);
  while (ARV_comp(tmp,oub)<0) do
    begin
      ARV_shl(tmp,1);
      if ((tmp.Head+tmp.size-1)^ shr 7 <> 0) then break;
    end;
  if ARV_comp(tmp,oub)>0 then ARV_shr(tmp,1);
  while ARV_comp(tmp,inb)>=0 do
    begin
      ARV_shl(oua,1);
      if ARV_comp(tmp,oub)<=0 then
        begin
          ARV_sub(oub,tmp);
          oua.Head^:=oua.Head^ or $01;
        end
      else
        begin
          //Do nothing
        end;
      ARV_shr(tmp,1);
    end;
  freeARV(tmp);
end;
procedure ARV_div(var ina:TAufRamVar;const inb:TAufRamVar);
var oa,ob:TAufRamVar;
begin
  newARV(oa,ina.size);
  newARV(ob,ina.size);
  ARV_divmod(ina,inb,oa,ob);
  copyARV(oa,ina);
  freeARV(oa);
  freeARV(ob);
end;

procedure ARV_mod(var ina:TAufRamVar;const inb:TAufRamVar);
var oa,ob:TAufRamVar;
begin
  newARV(oa,ina.size);
  newARV(ob,ina.size);
  ARV_divmod(ina,inb,oa,ob);
  copyARV(ob,ina);
  freeARV(oa);
  freeARV(ob);
end;





operator <(ina,inb:TAufRamVar):boolean;
begin
  if ARV_comp(ina,inb)=-1 then result:=true
  else result:=false;
end;
operator <=(ina,inb:TAufRamVar):boolean;
begin
  if ARV_comp(ina,inb)<>1 then result:=true
  else result:=false;
end;
operator >(ina,inb:TAufRamVar):boolean;
begin
  if ARV_comp(ina,inb)=1 then result:=true
  else result:=false;
end;
operator >=(ina,inb:TAufRamVar):boolean;
begin
  if ARV_comp(ina,inb)<>-1 then result:=true
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

procedure dec_to_arv(ina:TDecimalStr;oua:TAufRamVar);
var pi,pj:dword;
    acc,base:TDecimalStr;
    bit,bi:longint;
  procedure bits_write(byt:pbyte;bit:byte;boo:boolean);
  var tmp:byte;
  begin
    if byt>=oua.Head+oua.size then exit;
    tmp:=byte(1) shl bit;
    if boo then byt^:=byt^ or tmp
    else byt^:=byt^ and (not tmp);
  end;
begin
  acc:=ina;
  base.data:='+1';
  bit:=0;
  while base<acc do
    begin
      base:=base+base;
      inc(bit);
    end;

  if assignedARV(oua) then
    begin
      for bi:=(oua.size*8) downto bit+1 do bits_write((oua.Head+(bi div 8)),bi mod 8,false);
      while bit>=0 do
        begin
          if base>acc then begin
            bits_write((oua.Head+(bit div 8)),bit mod 8,false);
          end else begin
            bits_write((oua.Head+(bit div 8)),bit mod 8,true);
            acc:=acc-base;
          end;
          base:=base div DecimalStr('2');
          dec(bit);
        end;
      {
      for pi:=0 to oua.size-1 do for pj:=0 to 7 do
        begin
          if bits_check((oua.Head+pi)^,pj) then acc:=acc+base;
          base:=base+base;
        end;
      result:=acc.data;
      }
    end
  else
    begin
      raise Exception.Create('警告：地址超界！');
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
      //raise Exception.Create('警告：暂时不支持十六进制以外的整型数和浮点型');
      dec_to_arv(DecimalStr(exp),arv);
    end;
end;

procedure initiate_arv_str(exp:RawByteString;var arv:TAufRamVar);//根据字符串创建字符串的ARV，非临时性ARV位数按规定赋值，临时性以参数位数为准
var size,len,pi:integer;
    str,stmp:RawByteString;
begin
  str:=utf8towincp(exp);
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

function arv_to_hex(ina:TAufRamVar):string;
var pi:dword;
begin
  result:='';
  //result:='UnKnown.Hex(';
  if assignedARV(ina) then
    begin
      for pi:=ina.size-1 downto 0 do
        begin
          result:=result+IntToHex((ina.Head+pi)^,2);
        end;
    end
  else
    begin
      raise Exception.Create('警告：地址超界！');
      result:='00H';
    end;
  //result:=result+')';
end;
function arv_to_dec(ina:TAufRamVar):string;
var pi,pj:dword;
    acc,base:TDecimalStr;
  function bits_check(byt,bit:byte):boolean;
  var tmp:byte;
  begin
    tmp:=1 shl bit;
    if byt and tmp <>0 then result:=true
    else result:=false;
  end;
begin
  result:='';
  acc.data:='+0';
  base.data:='+1';
  if assignedARV(ina) then
    begin
      for pi:=0 to ina.size-1 do for pj:=0 to 7 do
        begin
          if bits_check((ina.Head+pi)^,pj) then acc:=acc+base;
          base:=base+base;
        end;
      result:=acc.data;
    end
  else
    begin
      raise Exception.Create('警告：地址超界！');
      result:='0';
    end;
end;
function arv_to_dec_fraction(ina:TAufRamVar):string;//小数点后
var pi,pj:dword;
    digit,lastdigit:dword;
    acc,base,tmp:TRealStr;
  function bits_check(byt,bit:byte):boolean;
  var tmp:byte;
  begin
    tmp:=1 shl bit;
    if byt and tmp <>0 then result:=true
    else result:=false;
  end;
begin
  result:='';
  acc.data:='+0.0';
  base.data:='+0.5';
  digit:=ina.size*8;
  repeat
    dec(digit);
    if bits_check((ina.Head + digit div 8)^,digit mod 8) then break;
  until digit=0;
  lastdigit:=digit;
  MaxDivDigit:=ina.size*8+2;
  writeln('MDD=',MaxDivDigit);
  writeln('lastDigit=',LastDigit);
  if assignedARV(ina) then
    begin
      digit:=0;
      repeat
        pi:=digit div 8;
        pj:=digit mod 8;
        writeln('base=',base.data);
        if bits_check((ina.Head+pi)^,pj) then acc:=acc+base;
        tmp:=base/RealStr('2');
        base:=tmp;
        inc(digit);
        writeln('acc=',acc.data);

      until digit>lastdigit;
      delete(acc.data,1,2);
      result:=acc.data;
    end
  else
    begin
      raise Exception.Create('警告：地址超界！');
      result:='0';
    end;
end;
function arv_to_dword(ina:TAufRamVar):dword;
var pi:dword;
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
                 raise Exception.Create('警告：浮点型不支持to_dword转换');
                 result:=0;
               end;
    ARV_Char  :begin
                 raise Exception.Create('警告：暂不支持字符型的to_dword转换');
                 result:=0;
               end;
    else begin raise Exception.Create('错误的ARV类型，不能转换为字符');result:=0;exit end;
  end;
end;
function arv_to_double(ina:TAufRamVar):double;
var pi:dword;
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
                 raise Exception.Create('警告：浮点型不支持to_double转换');
                 result:=0;
               end;
    ARV_Char  :begin
                 raise Exception.Create('警告：暂不支持字符型的to_double转换');
                 result:=0;
               end;
    else begin raise Exception.Create('警告：错误的ARV类型，不能转换为字符串');exit end;
  end;
end;
function arv_to_s(ina:TAufRamVar):string;
var pi:dword;
begin
  result:='';
  case ina.VarType of
    ARV_FixNum:begin
                 result:=arv_to_dec(ina);
               end;
    ARV_Float :begin
                 raise Exception.Create('暂不支持浮点型的to_s转换，请使用to_hex');
               end;
    ARV_Char  :begin
                 for pi:=ina.size-1 downto 0 do
                   begin
                     result:=result+chr((ina.Head+pi)^);
                   end;
                 while length(result)>0 do if result[1]=#0 then delete(result,1,1) else break;
                 result:=wincptoutf8(result);
               end;
    else begin raise Exception.Create('错误的ARV类型，不能转换为字符串');result:='';exit end;
  end;
end;

procedure s_to_arv(s:string;oup:TAufRamVar);
begin
  initiate_arv_str(s,oup);
end;
procedure dword_to_arv(d:dword;oup:TAufRamVar);
var tmp:string;
begin
  tmp:=IntToHex(d,8);
  initiate_arv(tmp+'H',oup);
end;
procedure double_to_arv(d:double;oup:TAufRamVar);
begin
  if (oup.size<>8) and (oup.VarType<>ARV_Float) then raise Exception.Create('警告：八位浮点型以外类型暂不支持赋值');
  pdouble(oup.Head)^:=d;
end;


initialization
  MaxDivDigit:=240;

end.

