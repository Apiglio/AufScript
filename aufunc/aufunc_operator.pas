unit aufunc_operator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Apiglio_Useful, auf_ram_var, auf_type_error, auf_type_base;

function operator_equal(Sender:TObject;var is_error:boolean):boolean;
function operator_not_equal(Sender:TObject;var is_error:boolean):boolean;
function operator_greater(Sender:TObject;var is_error:boolean):boolean;
function operator_less(Sender:TObject;var is_error:boolean):boolean;
function operator_greater_or_equal(Sender:TObject;var is_error:boolean):boolean;
function operator_less_or_equal(Sender:TObject;var is_error:boolean):boolean;
function operator_in(Sender:TObject;var is_error:boolean):boolean;
function operator_reg(Sender:TObject;var is_error:boolean):boolean;
function operator_file(Sender:TObject;var is_error:boolean):boolean;
function operator_define(Sender:TObject;var is_error:boolean):boolean;
function operator_array(Sender:TObject;var is_error:boolean):boolean;


implementation
uses auf_type_array, auf_type_parser;

function operator_compare_numeric(Sender:TObject;var is_error:boolean):smallint;
var AufScpt:TAufScript;
    AAuf:TAuf;
    t1,t2,tc:TAufRamVarType;
    a1,a2:TAufRamVar;
    diff:double;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  t1:=AAuf.TellArgType(1);
  t2:=AAuf.TellArgType(3);
  if t1=t2 then begin
    if t1<>ARV_Raw then begin
      tc:=t1;
      is_error:=is_error or not AAuf.TryArgToARV(1,1,High(dword),[tc],a1);
      is_error:=is_error or not AAuf.TryArgToARV(3,1,High(dword),[tc],a2);
    end else begin
      is_error:=true;
      AufScpt.send_error('不支持两个立即数比较大小。',AufsErr_ParamType);
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
      AufScpt.send_error('类型不同无法比较。',AufsErr_RunTime);
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

function operator_equal(Sender:TObject;var is_error:boolean):boolean;
begin
  result:=operator_compare_numeric(Sender,is_error)=0;
end;

function operator_not_equal(Sender:TObject;var is_error:boolean):boolean;
begin
  result:=operator_compare_numeric(Sender,is_error)<>0;
end;

function operator_greater(Sender:TObject;var is_error:boolean):boolean;
begin
  result:=operator_compare_numeric(Sender,is_error)>0;
end;

function operator_less(Sender:TObject;var is_error:boolean):boolean;
begin
  result:=operator_compare_numeric(Sender,is_error)<0;
end;

function operator_greater_or_equal(Sender:TObject;var is_error:boolean):boolean;
begin
  result:=operator_compare_numeric(Sender,is_error)>=0;
end;

function operator_less_or_equal(Sender:TObject;var is_error:boolean):boolean;
begin
  result:=operator_compare_numeric(Sender,is_error)<=0;
end;

function operator_in(Sender:TObject;var is_error:boolean):boolean;
var AufScpt:TAufScript;
    AAuf:TAuf;
    s1,s2:string;
    t1,t2:TAufRamVarType;
    a1,a2:TAufRamVar;
    c1,c2:TAufBaseClass;
    adr_1,adr_2:pRam;
    obj_1,obj_2:TAufBase;
begin
  result:=false;
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  t1:=AAuf.TellArgType(1);
  t2:=AAuf.TellArgType(3);
  case t2 of
    ARV_Char, ARV_Raw:
      begin
        if not AAuf.TryArgToString(1,s1) then exit;
        if not AAuf.TryArgToString(3,s2) then exit;
        result:=pos(s1,s2)>0;
      end;
    ARV_FixNum:
      begin
        if not AAuf.TryArgToPRam(3,adr_2) then exit;
        obj_2:=TAufBase.InstancesByAddress(adr_2);
        if obj_2=nil then begin
          is_error:=true;
          exit;
        end;
        AufScpt.DefineNameDecode(AAuf.nargs[1]);
        t1:=AAuf.TellArgType(1);
        case t1 of
          ARV_Raw:
            begin
              obj_1:=auf_type_parser.AufBaseParser(AAuf.nargs[1].arg);
            end;
          else
            begin
              if not AAuf.TryArgToARV(1, 1, High(dword), ARV_AllType, a1) then exit;
              obj_1:=TAufBase.CreateAsARV(a1);
            end;
        end;
        case obj_2.ClassName of
          'TAufArray': with TAufArray(obj_2) do result:=Find(obj_1)<>Count;
          else is_error:=true;
        end;
        obj_1.Free;
      end;
    else is_error:=true;
  end;
end;

function operator_reg(Sender:TObject;var is_error:boolean):boolean;
var AufScpt:TAufScript;
    AAuf:TAuf;
    s1,s2:string;
begin
  result:=false;
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.TryArgToString(1,s1) then exit;
  if not AAuf.TryArgToString(3,s2) then exit;
  RegCalc.Expression:=s1;
  try
    result:=RegCalc.Exec(s2);
  except
    result:=false;
  end;
end;

function operator_file(Sender:TObject;var is_error:boolean):boolean;
var AufScpt:TAufScript;
    AAuf:TAuf;
    filename, mode:string;
begin
  result:=false;
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(4) then exit;
  if not AAuf.TryArgToString(1, filename) then exit;
  if not AAuf.TryArgToStrParam(3, ['exists'], false, mode) then exit;
  case mode of
    'exists':result:=FileExists(filename);
  end;
end;

function operator_define(Sender:TObject;var is_error:boolean):boolean;
var AufScpt:TAufScript;
    AAuf:TAuf;
    defname, mode:string;
begin
  result:=false;
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(4) then exit;
  if not AAuf.TryArgToDefName(1, defname) then exit;
  defname:=lowercase(defname);
  if not AAuf.TryArgToStrParam(3, ['local','global'], false, mode) then exit;
  case mode of
    'local': result:=AufScpt.Expression.Local.Find(defname)<>nil;
    'global':result:=AufScpt.Expression.Global.Find(defname)<>nil;
  end;
end;

function operator_array(Sender:TObject;var is_error:boolean):boolean;
var AufScpt:TAufScript;
    AAuf:TAuf;
    obj:TObject;
    mode:string;
begin
  result:=false;
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(4) then exit;
  if not AAuf.TryArgToObject(1, TAufArray, obj) then exit;
  if not AAuf.TryArgToStrParam(3, ['empty', 'valid'], false, mode) then exit;
  case mode of
    'empty':result:=TAufArray(obj).Count=0;
    'valid':result:=TAufArray(obj).Count<>0;
  end;
end;

end.

