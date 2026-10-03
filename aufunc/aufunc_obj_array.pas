unit aufunc_obj_array;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Apiglio_Useful, auf_ram_var, auf_type_error,
  auf_type_parser, auf_type_base, auf_type_array;

procedure array_newArray(Sender:TObject); //array.new @arr  ||  array.new = arr
procedure array_delArray(Sender:TObject); //array.del @arr  ||  array.del . arr
procedure array_copyArray(Sender:TObject); //array.copy dst,src  ||  array.copy = dst src
procedure array_ClearArrayList(Sender:TObject);
procedure array_Insert(Sender:TObject);//array.insert @arr,12[,0]
procedure array_Reinsert(Sender:TObject);//array.reinsert @arr,elem
procedure array_Delete(Sender:TObject);//array.delete @arr,index[,@res]
procedure array_Draw(Sender:TObject);//array.draw @arr[,@res]
procedure array_Clear(Sender:TObject);
procedure array_Print(Sender:TObject);
procedure array_Count(Sender:TObject);
procedure array_Index(Sender:TObject);
procedure array_CheckElement(Sender:TObject);//array.valid? @array, :addr || array.empty?


implementation

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
  if arv_to_dword(arv)<>0 then begin
    AufScpt.send_error('警告：对象变量'+AAuf.args[1]+'已被占用，未创建对象。',AufsErr_ObjectAssigned);
    exit;
  end;
  obj:=TAufArray.Create(arv);
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
    AufScpt.send_error('找不到对应的TAufArray，删除失败',AufsErr_ParamType);
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

procedure array_Index(Sender:TObject);
var AAuf:TAuf;
    AufScpt:TAufScript;
    obj:TObject;
    arv_idx, arv_elem:TAufRamVar;
    len, idx:integer;
    base_elem:TAufBase;
    arv_type:TAufRamVarType;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToObject(1,TAufArray,obj) then exit;
  if not AAuf.TryArgToARV(3,1,High(DWord),[ARV_FixNum],arv_idx) then exit;
  arv_type:=AAuf.TellArgType(2);
  case arv_type of
    ARV_Raw:begin
      newARV(arv_elem,length(AAuf.args[2]));
      if AAuf.nargs[2].pre='"' then arv_elem.VarType:=ARV_Char
      else if pos('.', AAuf.args[2])>0 then arv_elem.VarType:=ARV_Float
      else if pos('e', lowercase(AAuf.args[2]))>0 then arv_elem.VarType:=ARV_Float
      else arv_elem.VarType:=ARV_FixNum;
      initiate_arv(AAuf.args[2], arv_elem);
      base_elem:=TAufBase.CreateAsARV(arv_elem);
      freeARV(arv_elem);
    end;
    else begin
      if not AAuf.TryArgToARV(2,1,High(longint),[ARV_FixNum],arv_elem) then exit;
      base_elem:=TAufBase.CreateAsARV(arv_elem);
    end;
  end;

  try with TAufArray(obj) do begin
    len:=Count;
    idx:=Find(base_elem);
    if len=idx then begin
      AufScpt.send_error('警告：数组内不包含给定元素，下标结果未赋值', AufsErr_RunTime);
      exit;
    end;
    dword_to_arv(idx, arv_idx);
  end;
  finally
    base_elem.Free;
  end;

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

end.

