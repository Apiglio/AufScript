unit auf_ram_var;

{$mode objfpc}{$H+}

interface

uses
  {$ifdef UNIX}
  cthreads,
  {$endif}
  Classes, SysUtils, LazUTF8;

type

  EAufRamVarError = class(Exception);
  EAufRamVarUnimplementedError=class(EAufRamVarError);
  EAufRamVarTypeError=class(EAufRamVarError);
  EAufRamVarAddressError=class(EAufRamVarError);

  TAufRamVarType = (ARV_Raw=0,ARV_FixNum=1,ARV_Float=2,ARV_Char=3);
  TAufRamVarTypeSet = set of TAufRamVarType;
  TAufRamVar = record
    VarType:TAufRamVarType;
    Head:pbyte;
    size:dword;
    Is_Temporary:boolean;//是否是运算符重载计算时临时产生的内存流数据
    Stream:TMemoryStream;//如果是，这里是内存流的指针
  end;
  PAufRamVar=^TAufRamVar;

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



  procedure newARV(out inp:TAufRamVar;Size:dword);
  procedure freeARV(inp:TAufRamVar);
  function assignedARV(inp:TAufRamVar):boolean;
  procedure copyARV(ori_arv:TAufRamVar;var new_arv:TAufRamVar);
  procedure fillARV(target:byte;var arv:TAufRamVar);

  function fixnum_comp(ina,inb:TAufRamVar):smallint;
  function fixnum_comp_abs(ina,inb:TAufRamVar):smallint;
  procedure fixnum_opp(var ina:TAufRamVar);
  procedure fixnum_abs(var ina:TAufRamVar);inline;
  procedure fixnum_add(ina,inb:TAufRamVar;var oup:TAufRamVar;out CY:int16);
  procedure fixnum_sub(ina,inb:TAufRamVar;var oup:TAufRamVar;out BR:int16);
  procedure fixnum_mul(ina,inb:TAufRamVar;var oup:TAufRamVar);
  procedure fixnum_div(ina,inb:TAufRamVar;var oup,rem:TAufRamVar);
  function fixnum_to_decimal(ina:TAufRamVar):string;
  procedure decimal_to_fixnum(dec:string;var oup:TAufRamVar);

  procedure float_add(ina,inb:TAufRamVar;var oup:TAufRamVar);
  procedure float_sub(ina,inb:TAufRamVar;var oup:TAufRamVar);
  procedure float_mul(ina,inb:TAufRamVar;var oup:TAufRamVar);
  procedure float_div(ina,inb:TAufRamVar;var oup:TAufRamVar);
  function float_to_decimal(ina:TAufRamVar):string;

  function ARV_EqlZero(inp:TAufRamVar):boolean;
  function ARV_comp(ina,inb:TAufRamVar):smallint;//ina<=>inb
  function ARV_offset_count(ina,inb:TAufRamVar;offset_threshold:byte):dword;//统计每个字节差距大于offset_threshold的字节数量
  procedure ARV_copyBits(src,dst:TAufRamVar; srcStart,dstStart:qword; CopyLen:qword);

  function ARV_float_valid(ina:TAufRamVar):boolean;//判断浮点型是否是有效值
  function ARV_floating_exponent_digits(byteCount:integer):integer;
  procedure ARV_floating_make_zero(ina:TAufRamVar;negative:boolean=false);
  procedure ARV_floating_make_infinity(ina:TAufRamVar;negative:boolean=false);
  function ARV_floating_is_infinity(const ina:TAufRamVar):boolean;
  procedure ARV_floating_make_notanumber(ina:TAufRamVar;negative:boolean=false);
  procedure ARV_floating_scaling(var oup:TAufRamVar;const inp:TAufRamVar);
  function ARV_floating_comp(ina,inb:TAufRamVar):integer;

  function ARV_string_comp(ina,inb:TAufRamVar):smallint;

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
  function arv_to_bin(ina:TAufRamVar):string;
  function arv_to_dec(ina:TAufRamVar):string;
  function arv_to_dec_fraction(ina:TAufRamVar):string;//小数点后
  function arv_to_qword(ina:TAufRamVar):qword;
  function arv_to_dword(ina:TAufRamVar):dword;
  function arv_to_double(ina:TAufRamVar):double;

  procedure dec_to_arv(ina:TDecimalStr;oua:TAufRamVar);

  procedure s_to_arv(s:string;oup:TAufRamVar);
  procedure dword_to_arv(d:dword;oup:TAufRamVar);
  procedure qword_to_arv(q:qword;oup:TAufRamVar);
  procedure double_to_arv(d:double;oup:TAufRamVar);

  procedure initiate_arv(exp:string;var arv:TAufRamVar);//根据字符串创建最大相似的ARV 应该改名initiate_arv_fixnum
  procedure initiate_arv_float(exp:string;var arv:TAufRamVar);
  procedure initiate_arv_str(exp:RawByteString;var arv:TAufRamVar);//根据字符串创建字符串的ARV

  function arv_clip(src:TAufRamVar;idx,len:longint):TAufRamVar;
  function arv_to_obj(arv:TAufRamVar):TObject;
  procedure obj_to_arv(obj:TObject;var arv:TAufRamVar);

const
  ARV_AllType:TAufRamVarTypeSet = [ARV_FixNum,ARV_Float,ARV_Char];

var

  MaxDivDigit:dword;
  _arvconst_fixnum_0_:TAufRamVar;
  _arvconst_fixnum_p1_:TAufRamVar;
  _arvconst_fixnum_n1_:TAufRamVar;
  _arvconst_fixnum_p10_:TAufRamVar;
  _arvconst_fixnum_n10_:TAufRamVar;
  _arvconst_float_0_:TAufRamVar;
  _arvconst_float_p1_:TAufRamVar;
  _arvconst_float_n1_:TAufRamVar;
  _arvconst_float_p10_:TAufRamVar;
  _arvconst_float_n10_:TAufRamVar;
  _arvconst_float_pInf_:TAufRamVar;
  _arvconst_float_nInf_:TAufRamVar;
  _arvconst_string_empty_:TAufRamVar;


implementation

uses Apiglio_Useful, auf_ram_image;


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

  {主要问题是太慢，并非8000H之后开始死循环}

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




procedure newARV(out inp:TAufRamVar;Size:dword);
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
begin
  if ori_arv.size>=new_arv.size then begin
    Move(ori_arv.Head^,new_arv.Head^,new_arv.size);
  end else begin
    Move(ori_arv.Head^,new_arv.Head^,ori_arv.size);
    FillByte((new_arv.Head+ori_arv.size)^,new_arv.size-ori_arv.size,0);
  end;
end;

procedure fillARV(target:byte;var arv:TAufRamVar);
begin
  FillByte(arv.Head^,arv.size,target);
end;

//由Gemini生成，对比两个整数
function fixnum_comp(ina,inb:TAufRamVar):smallint;
var i,max_s:dword;
    ta,tb:byte;
    sa,sb:byte;
begin
  result:=0;
  if (pbyte(ina.Head+ina.size-1)^ and $80) <> 0 then sa:=$FF else sa:=$00;
  if (pbyte(inb.Head+inb.size-1)^ and $80) <> 0 then sb:=$FF else sb:=$00;
  if sa<>sb then begin
    if sa>0 then exit(-1) else exit(1);
  end;
  if ina.size>inb.size then max_s:=ina.size else max_s:=inb.size;
  if max_s=0 then raise Exception.Create('不能比较两个长度为0的整数。');
  for i:=max_s-1 downto 0 do begin
    if i<ina.size then ta:=(ina.Head+i)^ else ta:=sa;
    if i<inb.size then tb:=(inb.Head+i)^ else tb:=sb;
    if ta>tb then begin result:=1;exit;end;
    if ta<tb then begin result:=-1;exit;end;
  end;
end;
function fixnum_comp_abs(ina,inb:TAufRamVar):smallint;
var i,max_s:dword;
    ta,tb:byte;
begin
  result:=0;
  if ina.size>inb.size then max_s:=ina.size else max_s:=inb.size;
  for i:=max_s - 1 downto 0 do begin
    if i<ina.size then ta:=(ina.Head+i)^ else ta:=0;
    if i<inb.size then tb:=(inb.Head+i)^ else tb:=0;
    if ta>tb then exit(1);
    if ta<tb then exit(-1);
  end;
end;
procedure fixnum_opp(var ina:TAufRamVar);
var i:dword;
    CY:int16;
begin
  ARV_not(ina);
  CY:=1;
  for i:=0 to ina.size-1 do begin
    CY:=CY+pbyte(ina.Head+i)^;
    pbyte(ina.Head+i)^:=byte(CY mod 256);
    CY:=CY div 256;
  end;
end;
procedure fixnum_abs(var ina:TAufRamVar);inline;
begin
  if ((ina.Head+ina.size-1)^ and $80) = 0 then exit;
  fixnum_opp(ina);
end;
procedure fixnum_add(ina,inb:TAufRamVar;var oup:TAufRamVar;out CY:int16);
var digit:dword;
    ta,tb:int16;
    sa,sb:byte;
begin
  if oup.Is_Temporary then begin
    if not assignedARV(oup) then raise Exception.Create('临时性ARV地址错误，内存流未初始化。');
  end else begin
    if not assignedARV(oup) then raise Exception.Create('非临时性ARV地址错误。');
  end;
  if (pbyte(ina.Head+ina.size-1)^ and $80) <> 0 then sa:=$FF else sa:=$00;
  if (pbyte(inb.Head+inb.size-1)^ and $80) <> 0 then sb:=$FF else sb:=$00;
  CY:=0;
  for digit:=0 to oup.size-1 do
    begin
      if ina.size>digit then ta:=(ina.Head+digit)^ else ta:=sa;
      if inb.size>digit then tb:=(inb.Head+digit)^ else tb:=sb;
      pbyte(oup.Head+digit)^:=(ta+tb+CY) mod 256;
      CY:=(ta+tb+CY) div 256;
    end;
end;
procedure fixnum_sub(ina,inb:TAufRamVar;var oup:TAufRamVar;out BR:int16);
var digit:dword;
    ta,tb:int16;
    sa,sb:byte;
begin
  if oup.Is_Temporary then begin
    if not assignedARV(oup) then raise Exception.Create('临时性ARV地址错误，内存流未初始化。');
  end else begin
    if not assignedARV(oup) then raise Exception.Create('非临时性ARV地址错误。');
  end;
  if (pbyte(ina.Head+ina.size-1)^ and $80) <> 0 then sa:=$FF else sa:=$00;
  if (pbyte(inb.Head+inb.size-1)^ and $80) <> 0 then sb:=$FF else sb:=$00;
  BR:=0;
  for digit:=0 to oup.size-1 do
    begin
      if ina.size>digit then ta:=(ina.Head+digit)^ else ta:=sa;
      if inb.size>digit then tb:=(inb.Head+digit)^ else tb:=sb;
      pbyte(oup.Head+digit)^:=byte(ta-BR-tb) mod 256;
      if ta-BR<tb then BR:=1 else BR:=0;
    end;
end;
//由Gemini生成
procedure fixnum_mul(ina,inb:TAufRamVar;var oup:TAufRamVar);
var i,j,k:dword;
    ta,tb:dword;
    arva,arvb:TAufRamVar;
    accum:dword;
    CY:dword;
    sa,sb:boolean;
begin
  fillARV(0,oup);
  newARV(arva,ina.size);
  newARV(arvb,inb.size);
  copyARV(ina,arva);
  copyARV(inb,arvb);
  sa:=(pbyte(arva.Head+arva.size-1)^ and $80) <> 0;
  if sa then fixnum_abs(arva);
  sb:=(pbyte(arvb.Head+arvb.size-1)^ and $80) <> 0;
  if sb then fixnum_abs(arvb);

  for i:=0 to arva.size-1 do begin
    if i>=oup.size then break;
    ta:=(arva.Head+i)^;
    CY:=0;
    for j:=0 to arvb.size-1 do begin
      if i+j>=oup.size then break;
      tb:=(arvb.Head+j)^;
      accum:=pbyte(oup.Head+i+j)^ + (ta*tb) + CY;
      pbyte(oup.Head+i+j)^ := byte(accum mod 256);
      CY:=accum shr 8;
    end;
    k:=i+arvb.size;
    while (CY>0) and (k<oup.size) do begin
      accum:=dword(pbyte(oup.Head+k)^)+CY;
      pbyte(oup.Head+k)^:=byte(accum and $FF);
      CY:=accum shr 8;
      inc(k);
    end;
  end;
  if sa<>sb then fixnum_opp(oup);
  freeARV(arva);
  freeARV(arvb);
end;
//由Gemini生成
procedure fixnum_div(ina,inb:TAufRamVar;var oup,rem:TAufRamVar);
var i:integer;
    quotient_bit:byte;
    BR:int16;
    arva,arvb:TAufRamVar;
    sa,sb:byte;
begin
  if (pbyte(ina.Head+ina.size-1)^ and $80) <> 0 then sa:=$FF else sa:=$00;
  if (pbyte(inb.Head+inb.size-1)^ and $80) <> 0 then sb:=$FF else sb:=$00;
  newARV(arva,ina.size+1);
  newARV(arvb,inb.size+1);
  copyARV(ina,arva);
  copyARV(inb,arvb);
  (arva.Head+arva.size-1)^:=sa;
  (arvb.Head+arvb.size-1)^:=sb;
  fillARV(0,oup);
  fillARV(0,rem);
  if sa>0 then fixnum_opp(arva);
  if sb>0 then fixnum_opp(arvb);
  if ARV_EqlZero(arvb) then raise Exception.Create('Division by zero.');

  fillARV(0,oup);
  fillARV(0,rem);
  for i:=arva.size-1 downto 0 do begin
    arv_shl(rem,8);
    pbyte(rem.Head)^:=(arva.Head+i)^;
    quotient_bit:=0;
    while fixnum_comp_abs(rem,arvb)>=0 do begin
      fixnum_sub(rem,arvb,rem,BR);//因为arva、arvb扩容，有符号减运算与无符号运算等价
      inc(quotient_bit);
      if quotient_bit=255 then break;
    end;
    if dword(i)<oup.size then pbyte(oup.Head+i)^:=quotient_bit;
  end;

  if sa<>sb then fixnum_opp(oup);
  if sa>0 then fixnum_opp(rem);
  freeARV(arva);
  freeARV(arvb);
end;
//由Gemini生成
function fixnum_to_decimal(ina:TAufRamVar):string;
var temp:TAufRamVar;
    isNeg:boolean;
    i:dword;
    current,CY:dword;
    hasValue:boolean;
begin
  if (ina.size=0) or ARV_EqlZero(ina) then exit('0');
  isNeg:=(pbyte(ina.Head+ina.size-1)^ and $80) <> 0;
  newARV(temp,ina.size+1);
  for i:=0 to temp.size-1 do pbyte(temp.Head+i)^:=0;
  for i:=0 to temp.size-1 do begin
    if i<ina.size then
      pbyte(temp.Head+i)^:=pbyte(ina.Head+i)^
    else begin
      if isNeg then pbyte(temp.Head+i)^:=$FF
      else pbyte(temp.Head+i)^:=$00;
    end;
  end;
  if isNeg then begin
    for i:=0 to temp.size-1 do
      pbyte(temp.Head+i)^:=not pbyte(temp.Head+i)^;
    CY:=1;
    for i:=0 to temp.size-1 do begin
      CY:=CY+pbyte(temp.Head+i)^;
      pbyte(temp.Head+i)^:=byte(CY and $FF);
      CY:=CY shr 8;
    end;
  end;
  result:='';
  repeat
    current:=0;
    hasValue:=false;
    for i:=temp.size-1 downto 0 do begin
      current:=(current shl 8)+pbyte(temp.Head+i)^;
      pbyte(temp.Head+i)^:=byte(current div 10);
      current:=current mod 10;
      if pbyte(temp.Head+i)^<>0 then hasValue:=true;
    end;
    result:=chr(ord('0')+byte(current))+result;
  until not hasValue;
  if isNeg then result:='-'+result;
  freeARV(temp);
end;
//由Gemini生成
procedure decimal_to_fixnum(dec:string;var oup:TAufRamVar);
label _cleanup;
var i,start_idx:integer;
    isNeg:boolean;
    b10,bDigit,temp_res:TAufRamVar;
    c:char;
    cy_n_br:int16;
begin
  if (dec='') or (oup.size=0) then exit;
  newARV(b10,oup.size);
  fillARV(0,b10);
  pbyte(b10.Head)^:=10;
  newARV(bDigit,oup.size);
  newARV(temp_res,oup.size);
  fillARV(0,oup);
  isNeg:=false;
  start_idx:=1;
  if dec[1]='-' then begin
    isNeg:=true;
    inc(start_idx);
  end else if dec[1]='+' then begin
    inc(start_idx);
  end;
  for i:=start_idx to length(dec) do begin
    c:=dec[i];
    if (c<'0') or (c>'9') then begin
      fillARV(0,oup);
      pbyte(oup.Head+oup.size-1)^:=$80;
      goto _cleanup;
    end;
    fixnum_mul(oup,b10,temp_res);
    fillARV(0,bDigit);
    pbyte(bDigit.Head)^:=ord(c)-ord('0');
    fixnum_add(temp_res,bDigit,oup,cy_n_br);
  end;
  if isNeg then fixnum_opp(oup);

_cleanup:
  freeARV(b10);
  freeARV(bDigit);
  freeARV(temp_res);
end;


function get_bit(const arv: TAufRamVar; bitIdx: integer): boolean;
begin
  result := (pbyte(arv.Head + (bitIdx div 8))^ and (1 shl (bitIdx mod 8))) <> 0;
end;

procedure set_bit(var arv: TAufRamVar; bitIdx: integer; val: boolean);
begin
  if val then pbyte(arv.Head + (bitIdx div 8))^ := pbyte(arv.Head + (bitIdx div 8))^ or (1 shl (bitIdx mod 8))
  else pbyte(arv.Head + (bitIdx div 8))^ := pbyte(arv.Head + (bitIdx div 8))^ and not (1 shl (bitIdx mod 8));
end;
procedure float_add(ina,inb:TAufRamVar;var oup:TAufRamVar);
var vA,vB,vRes:UInt64;
    sA,sB,sRes:UInt64;
    eA,eB,eRes:Int64;
    mA,mB,mRes:UInt64;
    e_bits,m_bits:integer;
    bias:Int64;
    diff:Int64;
    tmp_fsc:TAufRamVar;
begin
  if (oup.size>8) then exit;
  newARV(tmp_fsc,oup.size);
  ARV_floating_scaling(tmp_fsc,ina); Move(tmp_fsc.Head^,vA,oup.size);
  ARV_floating_scaling(tmp_fsc,inb); Move(tmp_fsc.Head^,vB,oup.size);
  freeARV(tmp_fsc);
  e_bits:=ARV_floating_exponent_digits(oup.size);
  m_bits:=(oup.size*8)-1-e_bits;
  bias:=(1 shl (e_bits-1))-1;
  sA:=(vA shr (oup.size * 8-1)) and 1;
  eA:=(vA shr m_bits) and ((UInt64(1) shl e_bits)-1);
  mA:=vA and ((UInt64(1) shl m_bits)-1);
  if eA<>0 then mA:=mA or (UInt64(1) shl m_bits); // 补隐藏位
  sB:=(vB shr (oup.size * 8-1)) and 1;
  eB:=(vB shr m_bits) and ((UInt64(1) shl e_bits)-1);
  mB:=vB and ((UInt64(1) shl m_bits)-1);
  if eB<>0 then mB:=mB or (UInt64(1) shl m_bits); // 补隐藏位
  if eA>eB then begin
    diff:=eA-eB;
    if diff>=64 then mB:=0 else mB:=mB shr diff;
    eRes:=eA;
  end else begin
    diff:=eB-eA;
    if diff>=64 then mA:=0 else mA:=mA shr diff;
    eRes:=eB;
  end;
  if sA=sB then begin
    mRes:=mA+mB;
    sRes:=sA;
    if (mRes and (UInt64(1) shl (m_bits+1)))<>0 then begin
      mRes:=mRes shr 1;
      inc(eRes);
    end;
  end else begin
    if mA>=mB then begin
      mRes:=mA-mB;
      sRes:=sA;
    end else begin
      mRes:=mB-mA;
      sRes:=sB;
    end;
    if mRes<>0 then begin
      while (mRes and (UInt64(1) shl m_bits))=0 do begin
        mRes:=mRes shl 1;
        dec(eRes);
        if eRes<=0 then break;
      end;
    end else eRes:=0;
  end;
  mRes:=mRes and ((UInt64(1) shl m_bits)-1);
  vRes:=mRes or (UInt64(eRes) shl m_bits) or (sRes shl (oup.size*8-1));
  fillARV(0,oup);
  Move(vRes,oup.Head^,oup.size);
end;
procedure float_sub(ina,inb:TAufRamVar;var oup:TAufRamVar);
var tmpB: TAufRamVar;
begin
  if (ina.size = 0) or (inb.size = 0) then exit;
  newARV(tmpB,inb.size);
  copyARV(inb,tmpB);
  pbyte(tmpB.Head+tmpB.size-1)^:=pbyte(tmpB.Head+tmpB.size-1)^ xor $80;
  float_add(ina,tmpB,oup);
  freeARV(tmpB);
end;
procedure float_mul(ina,inb:TAufRamVar;var oup:TAufRamVar);
label _cleanup;
var
  tA,tB,MA,MB,MRes,EA,EB,ERes,tmp_Bias,tmp_V: TAufRamVar;
  SA,SB,SRes:boolean;
  E_bits,M_bits:integer;
  i:integer;
  cy_br:int16;
begin
  if (oup.size=0) or (ina.size=0) or (inb.size=0) then exit;
  if ARV_EqlZero(ina) or ARV_EqlZero(inb) then begin
    copyARV(_arvconst_float_0_,oup);
    exit;
  end;
  if ARV_floating_is_infinity(ina) or ARV_floating_is_infinity(inb) then begin
    SA:=(pbyte(ina.Head+ina.size-1)^ and $80) <> 0;
    SB:=(pbyte(inb.Head+inb.size-1)^ and $80) <> 0;
    if SA xor SB then copyARV(_arvconst_float_nInf_,oup)
    else copyARV(_arvconst_float_pInf_,oup);
    exit;
  end;
  E_bits:=ARV_floating_exponent_digits(oup.size);
  M_bits:=(oup.size * 8)-1-E_bits;
  newARV(tA,oup.size); newARV(tB,oup.size);
  newARV(MA,oup.size); newARV(MB,oup.size);
  newARV(EA,oup.size); newARV(EB,oup.size);
  newARV(ERes,oup.size);
  newARV(tmp_Bias,oup.size);
  newARV(tmp_V,oup.size);
  ARV_floating_scaling(tA,ina);
  ARV_floating_scaling(tB,inb);
  SA:=(pbyte(tA.Head+tA.size-1)^ and $80) <> 0;
  SB:=(pbyte(tB.Head+tB.size-1)^ and $80) <> 0;
  SRes:=SA xor SB;
  copyARV(tA,EA); arv_shr(EA,M_bits);
  pbyte(EA.Head+EA.size-1)^:=pbyte(EA.Head+EA.size-1)^ and $7F;
  copyARV(tB,EB); arv_shr(EB,M_bits);
  pbyte(EB.Head+EB.size-1)^:=pbyte(EB.Head+EB.size-1)^ and $7F;
  copyARV(tA,MA); arv_shl(MA,E_bits+1); arv_shr(MA,E_bits+1);
  if not ARV_EqlZero(EA) then set_bit(MA,M_bits,true);
  copyARV(tB,MB); arv_shl(MB,E_bits+1); arv_shr(MB,E_bits+1);
  if not ARV_EqlZero(EB) then set_bit(MB,M_bits,true);
  fillARV(0,tmp_V);
  set_bit(tmp_V,E_bits-1,true); // 2^(E_bits-1)
  fixnum_sub(tmp_V,_arvconst_fixnum_p1_,tmp_Bias,cy_br); // Bias
  fixnum_add(EA,EB,ERes,cy_br);
  fixnum_sub(ERes,tmp_Bias,ERes,cy_br);
  newARV(MRes,oup.size * 2);
  fixnum_mul(MA,MB,MRes);
  if get_bit(MRes,M_bits * 2+1) then begin
    arv_shr(MRes,M_bits+1);
    fixnum_add(ERes,_arvconst_fixnum_p1_,ERes,cy_br);
  end else begin
    arv_shr(MRes,M_bits);
  end;
  set_bit(MRes,M_bits,false); // 剥离隐藏位
  fillARV(0,oup);
  copyARV(MRes,oup);
  copyARV(ERes,tmp_V);
  arv_shl(tmp_V,M_bits);
  for i:=0 to oup.size-1 do pbyte(oup.Head+i)^:=pbyte(oup.Head+i)^ or pbyte(tmp_V.Head+i)^;
  if SRes then pbyte(oup.Head+oup.size-1)^:=pbyte(oup.Head+oup.size-1)^ or $80;

_cleanup:
  freeARV(tA);
  freeARV(tB);
  freeARV(MA);
  freeARV(MB);
  freeARV(EA);
  freeARV(EB);
  freeARV(ERes);
  freeARV(tmp_Bias);
  freeARV(tmp_V);
  if MRes.Head <> nil then freeARV(MRes);
end;
procedure float_div(ina,inb:TAufRamVar;var oup:TAufRamVar);
label _cleanup;
var tA,tB,MA,MB,MRes,MRem,EA,EB,ERes,tmp_Bias,tmp_V:TAufRamVar;
    SA,SB,SRes:boolean;
    E_bits,M_bits,double_size:integer;
    i:integer;
    cy_br:int16;
begin
  if (oup.size = 0) or (ina.size = 0) or (inb.size = 0) then exit;
  if ARV_EqlZero(inb) then begin
    SA:=(pbyte(ina.Head+ina.size-1)^ and $80) <> 0;
    SB:=(pbyte(inb.Head+inb.size-1)^ and $80) <> 0;
    ARV_floating_make_infinity(oup,SA xor SB);
    exit;
  end;
  if ARV_EqlZero(ina) then begin
    copyARV(_arvconst_float_0_,oup);
    exit;
  end;
  E_bits:=ARV_floating_exponent_digits(oup.size);
  M_bits:=(oup.size * 8)-1-E_bits;
  double_size:=oup.size * 2; // 中间尾数运算使用双倍位宽
  newARV(tA,oup.size); newARV(tB,oup.size);
  newARV(EA,oup.size); newARV(EB,oup.size);
  newARV(ERes,oup.size);
  newARV(tmp_Bias,oup.size);
  newARV(tmp_V,oup.size);
  newARV(MA,double_size); fillARV(0,MA);
  newARV(MB,double_size); fillARV(0,MB);
  newARV(MRes,double_size); fillARV(0,MRes);
  newARV(MRem,double_size); fillARV(0,MRem);
  ARV_floating_scaling(tA,ina);
  ARV_floating_scaling(tB,inb);
  SA:=(pbyte(tA.Head+tA.size-1)^ and $80) <> 0;
  SB:=(pbyte(tB.Head+tB.size-1)^ and $80) <> 0;
  SRes:=SA xor SB;
  copyARV(tA,EA);
  arv_shr(EA,M_bits);
  pbyte(EA.Head+EA.size-1)^:=pbyte(EA.Head+EA.size-1)^ and $7F;
  copyARV(tB,EB);
  arv_shr(EB,M_bits);
  pbyte(EB.Head+EB.size-1)^:=pbyte(EB.Head+EB.size-1)^ and $7F;
  copyARV(tA,tmp_V);
  arv_shl(tmp_V,E_bits+1); arv_shr(tmp_V,E_bits+1);
  Move(tmp_V.Head^,MA.Head^,oup.size);
  if not ARV_EqlZero(EA) then set_bit(MA,M_bits,true);
  copyARV(tB,tmp_V);
  arv_shl(tmp_V,E_bits+1); arv_shr(tmp_V,E_bits+1);
  Move(tmp_V.Head^,MB.Head^,oup.size);
  if not ARV_EqlZero(EB) then set_bit(MB,M_bits,true);
  fillARV(0,tmp_V);
  set_bit(tmp_V,E_bits-1,true); // 2^(E_bits-1)
  fixnum_sub(tmp_V,_arvconst_fixnum_p1_,tmp_Bias,cy_br); // Bias
  fixnum_sub(EA,EB,ERes,cy_br);
  fixnum_add(ERes,tmp_Bias,ERes,cy_br);
  arv_shl(MA,M_bits);
  fixnum_div(MA,MB,MRes,MRem);
  if ARV_EqlZero(MRes) then begin
    copyARV(_arvconst_float_0_,oup);
    goto _cleanup;
  end;
  if get_bit(MRes,M_bits+1) then begin
    arv_shr(MRes,1);
    fixnum_add(ERes,_arvconst_fixnum_p1_,ERes,cy_br);
  end else begin
    while (not get_bit(MRes,M_bits)) do begin
      arv_shl(MRes,1);
      fixnum_sub(ERes,_arvconst_fixnum_p1_,ERes,cy_br);
      if ARV_EqlZero(ERes) then break;
    end;
  end;
  set_bit(MRes,M_bits,false); // 剥离隐藏位
  fillARV(0,oup);
  Move(MRes.Head^,oup.Head^,oup.size);
  copyARV(ERes,tmp_V);
  arv_shl(tmp_V,M_bits);
  for i:=0 to oup.size-1 do pbyte(oup.Head+i)^:=pbyte(oup.Head+i)^ or pbyte(tmp_V.Head+i)^;
  if SRes then pbyte(oup.Head+oup.size-1)^:=pbyte(oup.Head+oup.size-1)^ or $80;

_cleanup:
  freeARV(tA); freeARV(tB);
  freeARV(EA); freeARV(EB); freeARV(ERes);
  freeARV(tmp_Bias); freeARV(tmp_V);
  if MA.Head <> nil then freeARV(MA);
  if MB.Head <> nil then freeARV(MB);
  if MRes.Head <> nil then freeARV(MRes);
  if MRem.Head <> nil then freeARV(MRem);
end;
function float_to_decimal(ina:TAufRamVar):string;unimplemented;
begin

end;


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

function ARV_offset_count(ina,inb:TAufRamVar;offset_threshold:byte):dword;//统计每个字节差距大于offset_threshold的字节数量
var ia:dword;
begin
  result:=0;
  if ina.size*inb.size=0 then exit;
  if ina.size<>inb.size then exit;
  ia:=ina.size;
  repeat
    dec(ia);
    if abs((ina.Head+ia)^ - (inb.Head+ia)^) > offset_threshold then
      begin
        inc(result);
      end;
  until ia=0;
end;
{
██ Copilot

here is definition of a little-endian data record TAufRamVar:
TAufRamVar = record
    Head:pbyte;
    size:dword;
end;

Now I need a function to copy digits from src to dst. complete the pascal code for me please:

procedure ARV_copyBits(src, dst: TAufRamVar; srcStart, dstStart, CopyLen: qword);
var src1,src2,dst1,dst2:qword;
    srcEnd,dstEnd:qword;
begin
    srcEnd:=srcStart+CopyLen;
    if srcEnd>src.size then srcEnd:=src.size;
    dstEnd:=dstStart+CopyLen;
    if dstEnd>dst.size then dstEnd:=dst.size;
    src1:=srcStart;
    dst1:=dstStart;
    //complete here
end;

██ Copilot

no, srcStartc and dstStart are bit position not byte position.
CopyLen is not byte length neither.
so you must consider bits aligning problem

██ Copilot
}
{
procedure ARV_copyBits(src, dst: TAufRamVar; srcStart, dstStart, CopyLen: qword);
var idx:qword;
    srcByte,dstByte:byte;
    srcBitPos,dstBitPos:integer;
    srcByteIndex,dstByteIndex:qword;
    bitVal:byte;
begin
  for idx:=0 to CopyLen-1 do begin
    // Calculate source bit position
    srcByteIndex:=(srcStart+idx) div 8;
    srcBitPos:=(srcStart+idx) mod 8;
    // Extract bit from source
    srcByte:=src.Head[srcByteIndex];
    bitVal:=(srcByte shr srcBitPos) and $01;
    // Calculate destination bit position
    dstByteIndex:=(dstStart+idx) div 8;
    dstBitPos:=(dstStart+idx) mod 8;
    // Read destination byte
    dstByte:=dst.Head[dstByteIndex];
    // Set or clear the bit
    if bitVal=1 then dstByte:=dstByte or (1 shl dstBitPos)
    else dstByte:=dstByte and not (1 shl dstBitPos);
    // Write back to destination
    dst.Head[dstByteIndex]:=dstByte;
  end;
end;
}
//这个是GPT的生成方法（比copilot的快20%，故采用）
procedure ARV_copyBits(src, dst: TAufRamVar; srcStart, dstStart, CopyLen: qword);
var
  src1, dst1, srcEnd, dstEnd: qword;
  srcByte, dstByte: byte;
  srcBit, dstBit: integer;
  bitVal: byte;
begin
  srcEnd := srcStart + CopyLen;
  if srcEnd > src.size * 8 then srcEnd := src.size * 8;  // size in bits
  dstEnd := dstStart + CopyLen;
  if dstEnd > dst.size * 8 then dstEnd := dst.size * 8;  // size in bits
  src1 := srcStart;
  dst1 := dstStart;
  while (src1 < srcEnd) and (dst1 < dstEnd) do begin
    // find which byte & bit in src
    srcByte := src.Head[src1 div 8];
    srcBit  := src1 mod 8;
    bitVal  := (srcByte shr srcBit) and $01;
    // find which byte & bit in dst
    dstByte := dst.Head[dst1 div 8];
    dstBit  := dst1 mod 8;
    // clear that bit, then set if needed
    dstByte := dstByte and not (1 shl dstBit);
    dstByte := dstByte or (bitVal shl dstBit);
    dst.Head[dst1 div 8] := dstByte;
    inc(src1);
    inc(dst1);
  end;
end;



function ARV_float_valid(ina:TAufRamVar):boolean;
begin
  result:=false;
  case ina.size of
     4:if ((ina.Head+3)^ and $7f = $7f) and ((ina.Head+2)^ and $80=$80) then exit;
     8:if ((ina.Head+7)^ and $7f = $7f) and ((ina.Head+6)^ and $f0=$f0) then exit;
     else exit;
  end;
  result:=true;
end;

function ARV_floating_exponent_digits(byteCount:integer):integer;
begin
  result:=trunc(5.5*ln(byteCount+0.5));
end;

procedure ARV_floating_make_zero(ina:TAufRamVar;negative:boolean=false);
begin
  FillByte(ina.Head^,ina.size,0);
  if negative then pbyte(ina.Head+ina.size-1)^:=$80;
end;

procedure ARV_floating_make_infinity(ina:TAufRamVar;negative:boolean=false);
var exponent_digit, mantissa_digit, EM_byte:integer;
    mask:byte;
// | Sign Exponent| ... | Exponent Mantissa | ... | Mantissa
//   HEAD+size-1          HEAD+EM_byte-1            HEAD^
begin
  exponent_digit:=ARV_floating_exponent_digits(ina.size);
  mantissa_digit:=ina.size*8 - exponent_digit -1;
  EM_byte:=mantissa_digit div 8;
  FillByte(ina.Head^,EM_byte,0);
  mask:=($FF shl (mantissa_digit mod 8)) and $FF;
  pbyte(ina.Head+EM_byte)^:=mask;
  if (ina.size-1 > EM_byte) then FillByte((ina.Head+EM_byte+1)^, (ina.size-1-EM_byte), $FF);
  if negative then pbyte(ina.Head+ina.size-1)^:=pbyte(ina.Head+ina.size-1)^ or $80
  else pbyte(ina.Head+ina.size-1)^:=pbyte(ina.Head+ina.size-1)^ and $7F;
end;
function ARV_floating_is_infinity(const ina:TAufRamVar):boolean;
var exponent_digit,mantissa_digit,EM_byte:integer;
    i:integer;
    mask: byte;
begin
  result:=false;
  if (ina.size=0) then exit;
  exponent_digit:=ARV_floating_exponent_digits(ina.size);
  mantissa_digit:=(ina.size*8)-exponent_digit-1;
  EM_byte:=mantissa_digit div 8;
  for i:=0 to EM_byte-1 do
    if pbyte(ina.Head+i)^<>0 then exit;
  mask:=($FF shl (mantissa_digit mod 8)) and $FF;
  if (pbyte(ina.Head+EM_byte)^ and (not mask)) <> 0 then exit;
  if (pbyte(ina.Head+EM_byte)^ and mask) <> mask then exit;
  for i:=EM_byte+1 to ina.size-2 do
    if pbyte(ina.Head+i)^ <> $FF then exit;
  if (pbyte(ina.Head+ina.size-1)^ and $7F) <> $7F then exit;
  result:=true;
end;

procedure ARV_floating_make_notanumber(ina:TAufRamVar;negative:boolean=false);
begin
  FillByte(ina.Head^,ina.size,$ff);
  if not negative then pbyte(ina.Head+ina.size-1)^:=pbyte(ina.Head+ina.size-1)^ and $7f;
end;
//由Gemini生成
procedure ARV_floating_scaling(var oup:TAufRamVar;const inp:TAufRamVar);
var S:byte;
    E_raw,M_raw:UInt64;
    E_real:Int64;
    in_E_bits,in_M_bits,out_E_bits,out_M_bits:integer;
    in_Bias,out_Bias:Int64;
begin
  M_raw:=0;
  Move(inp.Head^,M_raw,inp.size);
  in_E_bits:=ARV_floating_exponent_digits(inp.size);
  in_M_bits:=(inp.size*8)-1-in_E_bits;
  out_E_bits:=ARV_floating_exponent_digits(oup.size);
  out_M_bits:=(oup.size*8)-1-out_E_bits;
  S:=(M_raw shr (inp.size*8-1)) and 1;
  E_raw:=(M_raw shr in_M_bits) and ((1 shl in_E_bits)-1);
  M_raw:=M_raw and ((UInt64(1) shl in_M_bits)-1);
  if E_raw<>0 then begin
    in_Bias:=(1 shl (in_E_bits-1))-1;
    out_Bias:=(1 shl (out_E_bits-1))-1;
    E_real:=Int64(E_raw)-in_Bias+out_Bias;
    if E_real>=(1 shl out_E_bits)-1 then E_real:=(1 shl out_E_bits)-1;
    if E_real<=0 then E_real:=0;
  end else E_real:=0;
  if out_M_bits>in_M_bits then
    M_raw:=M_raw shl (out_M_bits-in_M_bits)
  else
    M_raw:=M_raw shr (in_M_bits-out_M_bits);
  M_raw:=M_raw or (UInt64(E_real) shl out_M_bits);
  M_raw:=M_raw or (UInt64(S) shl (oup.size*8-1));
  fillARV(0,oup);
  Move(M_raw,oup.Head^,oup.size);
end;
function ARV_floating_comp(ina,inb:TAufRamVar):integer;
var SA,SB:boolean;
    EA,EB,MA,MB:TAufRamVar;
    E_bits,M_bits:integer;
    res:integer;
begin
  if ina.Head=inb.Head then exit(0);
  if ARV_EqlZero(ina) and ARV_EqlZero(inb) then exit(0);
  SA:=get_bit(ina,(ina.size*8)-1);
  SB:=get_bit(inb,(inb.size*8)-1);
  if SA<>SB then begin
    if SA then exit(-1) else exit(1);
  end;
  E_bits:=ARV_floating_exponent_digits(ina.size);
  M_bits:=(ina.size*8)-1-E_bits;
  newARV(EA,ina.size);
  newARV(EB,inb.size);
  copyARV(ina,EA);
  set_bit(EA,(ina.size*8)-1,false);
  arv_shr(EA,M_bits);
  copyARV(inb,EB);
  set_bit(EB,(inb.size*8)-1,false);
  arv_shr(EB,M_bits);
  res:=fixnum_comp(EA,EB);
  if res <> 0 then begin
    if SA then exit(-res) else exit(res);
  end;
  newARV(MA,ina.size);
  newARV(MB,inb.size);
  copyARV(ina,MA);
  arv_shl(MA,E_bits+1);
  copyARV(inb,MB);
  arv_shl(MB,E_bits+1);
  res:=fixnum_comp(MA,MB);
  freeARV(EA);
  freeARV(EB);
  freeARV(MA);
  freeARV(MB);
  if SA then exit(-res) else exit(res);
end;

function ARV_string_comp(ina,inb:TAufRamVar):smallint;
var idx,len:integer;
    tpa,tpb:byte;
    compare:integer;
begin
  if (ina.VarType<>ARV_Char) or (inb.VarType<>ARV_Char) then raise Exception.Create('[ARV_string_comp]无法比较非字符串类型。');
  if ina.size>inb.size then len:=ina.size else len:=inb.size;
  for idx:=0 to len-1 do begin
    if idx<ina.size then tpa:=(ina.Head+idx)^ else tpa:=0;
    if idx<inb.size then tpb:=(inb.Head+idx)^ else tpb:=0;
    compare:=tpa-tpb;
    if compare>0 then exit(1) else if compare<0 then exit(-1);
  end;
  exit(0);
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
    function isHex(ss:string):boolean;
    var pi:integer;
    begin
      result:=false;
      for pi:=1 to length(ss) do if not (ss[pi] in ['A'..'F','a'..'f','0'..'9']) then exit;
      result:=true;
    end;

begin
  str:=exp;
  if exp[length(exp)] in ['h','H'] then
    begin
      delete(str,length(str),1);
      if not isHex(str) then raise Exception.Create('[initiate_arv]十六进制整数表达有误。');
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
          (arv.Head+pi)^:=HexToPRam(stmp) mod 256;
          inc(pi);
        end;
    end
  else
    begin
      //raise Exception.Create('警告：暂时不支持十六进制以外的整型数和浮点型');
      //dec_to_arv(DecimalStr(exp),arv);
      if arv.Is_Temporary then begin
        arv.size:=trunc(length(exp)*0.41524101186092034)+1; // >log_256(10)
        arv.Stream.SetSize(arv.size);
      end;
      decimal_to_fixnum(exp,arv);
    end;
end;

procedure initiate_arv_float(exp:string;var arv:TAufRamVar);
var dtmp:double;
begin
  dtmp:=StrToFloat(exp);
  case arv.size of
    4:psingle(arv.Head)^:=dtmp;
    8:pdouble(arv.Head)^:=dtmp;
    else raise Exception.Create('[initiate_arv_float]暂不支持binary32和binary64以外的浮点数类型。');
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
  if len<arv.size-1 then begin
    move(str[1],arv.Head^,len);
    FillByte((arv.Head+len)^,arv.size-len,0);
  end else begin
    move(str[1],arv.Head^,arv.size);
    //末尾"\0"对于定长字符串不是必须的
  end;
end;

function arv_to_hex(ina:TAufRamVar):string;
var idx:dword;
begin
  result:='';
  if assignedARV(ina) then begin
    for idx:=ina.size-1 downto 0 do begin
      result:=result+IntToHex((ina.Head+idx)^,2);
    end;
  end else
    raise Exception.Create('警告：地址超界！');
end;
function arv_to_bin(ina:TAufRamVar):string;
var tmpHex:string;
    idx,maxIdx:integer;
begin
  result:='';
  tmpHex:=arv_to_hex(ina);
  maxIdx:=length(tmpHex);
  for idx:=1 to maxIdx do case tmpHex[idx] of
    '0':     result:=result+'0000';
    '1':     result:=result+'0001';
    '2':     result:=result+'0010';
    '3':     result:=result+'0011';
    '4':     result:=result+'0100';
    '5':     result:=result+'0101';
    '6':     result:=result+'0110';
    '7':     result:=result+'0111';
    '8':     result:=result+'1000';
    '9':     result:=result+'1001';
    'A','a': result:=result+'1010';
    'B','b': result:=result+'1011';
    'C','c': result:=result+'1100';
    'D','d': result:=result+'1101';
    'E','e': result:=result+'1110';
    'F','f': result:=result+'1111';
  end;
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
  if ina.VarType=ARV_FixNum then result:=fixnum_to_decimal(ina);
  //后面可以逐渐退出删除了
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
  //writeln('MDD=',MaxDivDigit);
  //writeln('lastDigit=',LastDigit);
  if assignedARV(ina) then
    begin
      digit:=0;
      repeat
        pi:=digit div 8;
        pj:=digit mod 8;
        //writeln('base=',base.data);
        if bits_check((ina.Head+pi)^,pj) then acc:=acc+base;
        tmp:=base/RealStr('2');
        base:=tmp;
        inc(digit);
        //writeln('acc=',acc.data);

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
function arv_to_qword(ina:TAufRamVar):qword;
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
                 if not ARV_float_valid(ina) then raise Exception.Create('警告：ARV浮点型数值为NaN');
                 raise Exception.Create('警告：浮点型不支持to_dword转换');
                 result:=0;
               end;
    ARV_Char  :begin
                 raise Exception.Create('警告：暂不支持字符型的to_dword转换');
                 result:=0;
               end;
    else begin raise Exception.Create('错误的ARV类型，不能转换为dword');result:=0;exit end;
  end;
end;
function arv_to_dword(ina:TAufRamVar):dword;
begin
  result:=arv_to_qword(ina);
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
                 result:=0;
                 if not ARV_float_valid(ina) then raise Exception.Create('警告：ARV浮点型数值为NaN');
                 case ina.size of
                   4:result:=psingle(ina.Head)^;
                   8:result:=pdouble(ina.Head)^;
                   else raise Exception.Create('警告：4或8位以外的浮点型不支持to_double转换');
                 end;
               end;
    ARV_Char  :begin
                 raise Exception.Create('警告：暂不支持字符型的to_double转换');
                 result:=0;
               end;
    else begin raise Exception.Create('警告：错误的ARV类型，不能转换为字符串');exit end;
  end;
end;
function arv_to_s(ina:TAufRamVar):string;
var idx,len:dword;
begin
  result:='';
  case ina.VarType of
    ARV_FixNum:begin
                 result:=fixnum_to_decimal(ina);
               end;
    ARV_Float :begin
                 if not ARV_float_valid(ina) then raise Exception.Create('警告：ARV浮点型数值为NaN');
                 case ina.size of
                   4:result:=FloatToStrF(psingle(ina.Head)^,ffFixed,6,6);
                   8:result:=FloatToStrF(pdouble(ina.Head)^,ffFixed,15,15);
                   else raise Exception.Create('暂不支持4和8字节以外的浮点型字符串转换，请使用to_hex');
                 end;
               end;
    ARV_Char  :begin
                 idx:=0;
                 result:='';
                 while idx<ina.size do begin
                   if (ina.Head+idx)^=0 then break;
                   result:=result+chr((ina.Head+idx)^);
                   inc(idx);
                 end;
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
procedure qword_to_arv(q:qword;oup:TAufRamVar);
var tmp:string;
begin
  tmp:=IntToHex(q,16);
  initiate_arv(tmp+'H',oup);
end;
procedure double_to_arv(d:double;oup:TAufRamVar);
begin
  if (oup.size<>8) and (oup.VarType<>ARV_Float) then raise Exception.Create('警告：八位浮点型以外类型暂不支持赋值');
  pdouble(oup.Head)^:=d;
end;

function arv_clip(src:TAufRamVar;idx,len:longint):TAufRamVar;
begin
  result.VarType:=src.VarType;
  result.size:=0;
  //if not src.Is_Temporary then exit;
  result.Head:=src.Head+idx;
  if idx+len>src.size then result.size:=src.size-idx
  else result.size:=len;
end;

function arv_to_obj(arv:TAufRamVar):TObject;
begin
  result:=nil;
  {$ifdef cpu64}
    result:=TObject(PQWord(arv.Head)^);
  {$else}
    {$ifdef cpu32}
      result:=TObject(PDWord(arv.Head)^);
    {$else}
      raise Exception.Create('cpu位数不支持。');
    {$endif}
  {$endif}
end;

procedure obj_to_arv(obj:TObject;var arv:TAufRamVar);
begin
  if (arv.Is_Temporary) or (arv.Stream<>nil) then exit;
  if arv.size<>8 then exit;
  {$ifdef cpu64}
    PQWORD(arv.Head)^:=QWORD(obj);
  {$else}
    {$ifdef cpu32}
      PDWORD(arv.Head)^:=DWORD(obj);
    {$else}
      raise Exception.Create('cpu位数不支持。');
    {$endif}
  {$endif}
end;

initialization
  MaxDivDigit:=240;
  newARV(_arvconst_fixnum_0_,1);
  newARV(_arvconst_fixnum_p1_,1);
  newARV(_arvconst_fixnum_n1_,1);
  newARV(_arvconst_fixnum_p10_,1);
  newARV(_arvconst_fixnum_n10_,1);
  newARV(_arvconst_float_0_,1);
  newARV(_arvconst_float_p1_,1);
  newARV(_arvconst_float_n1_,1);
  newARV(_arvconst_float_p10_,2);
  newARV(_arvconst_float_n10_,2);
  newARV(_arvconst_float_pInf_,1);
  newARV(_arvconst_float_nInf_,1);
  newARV(_arvconst_string_empty_,1);
  with _arvconst_fixnum_0_ do Head^:=$00;
  with _arvconst_fixnum_p1_ do Head^:=$01;
  with _arvconst_fixnum_n1_ do Head^:=$FF;
  with _arvconst_fixnum_p10_ do Head^:=$0A;
  with _arvconst_fixnum_n10_ do Head^:=$F6;
  with _arvconst_float_0_ do Head^:=$00;
  with _arvconst_float_p1_ do Head^:=$30;
  with _arvconst_float_n1_ do Head^:=$B0;
  with _arvconst_float_p10_ do begin
    Head^:=$00;
    (Head+1)^:=$49;
  end;
  with _arvconst_float_n10_ do begin
    Head^:=$00;
    (Head+1)^:=$C9;
  end;
  with _arvconst_float_pInf_ do Head^:=$60;
  with _arvconst_float_nInf_ do Head^:=$E0;


finalization

  freeARV(_arvconst_fixnum_0_);
  freeARV(_arvconst_fixnum_p1_);
  freeARV(_arvconst_fixnum_n1_);
  freeARV(_arvconst_fixnum_p10_);
  freeARV(_arvconst_fixnum_n10_);
  freeARV(_arvconst_float_0_);
  freeARV(_arvconst_float_p1_);
  freeARV(_arvconst_float_n1_);
  freeARV(_arvconst_float_p10_);
  freeARV(_arvconst_float_n10_);
  freeARV(_arvconst_float_pInf_);
  freeARV(_arvconst_float_nInf_);
  freeARV(_arvconst_string_empty_);

end.

