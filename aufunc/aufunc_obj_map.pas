unit aufunc_obj_map;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Apiglio_Useful, auf_ram_var, auf_type_error,
  auf_type_parser, auf_type_base, auf_type_map;

procedure map_newMap(Sender:TObject);       //map.new      @dic
procedure map_delMap(Sender:TObject);       //map.del      @dic
procedure map_copyMap(Sender:TObject);      //map.copy      dst, src
procedure map_ClearMapList(Sender:TObject);

procedure map_Delete(Sender:TObject);       //map.delete   @dic, key
procedure map_Clear(Sender:TObject);
procedure map_Read(Sender:TObject);         //map.read     @dic, key, VALUE
procedure map_Write(Sender:TObject);        //map.write    @dic, key, VALUE
procedure map_Print(Sender:TObject);
procedure map_Count(Sender:TObject);


implementation

procedure map_newMap(Sender:TObject);
var AAuf:TAuf;
    AufScpt:TAufScript;
    obj:TAufMap;
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
  obj:=TAufMap.Create(arv);
  obj_to_arv(obj,arv);
end;

procedure map_delMap(Sender:TObject);
var AAuf:TAuf;
    AufScpt:TAufScript;
    obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToObject(1,TAufMap,obj) then exit;
  if obj is TAufMap then begin
    (obj as TAufMap).Free;
  end else begin
    AufScpt.send_error('找不到对应的TAufMap，删除失败',AufsErr_ParamType);
  end;
end;

procedure map_copyMap(Sender:TObject);
var AAuf:TAuf;
    AufScpt:TAufScript;
    src,dst:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToObject(1,TAufMap,dst) then exit;
  if not AAuf.TryArgToObject(2,TAufMap,src) then exit;
  TAufMap(dst).Assign(TAufMap(src));
end;

procedure map_ClearMapList(Sender:TObject);
var AufScpt:TAufScript;
    count:integer;
begin
  AufScpt:=Sender as TAufScript;
  count:=TAufMap.ClassInstancesCount;
  TAufMap.ClearClassInstances;
  AufScpt.writeln('共删除'+IntToStr(count)+'个TAufMap数组。');
end;

procedure map_Delete(Sender:TObject);
var AAuf:TAuf;
    AufScpt:TAufScript;
    obj:TObject;
    key:string;
    element:TAufBase;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToObject(1,TAufMap,obj) then exit;
  if not AAuf.TryArgToString(2,key) then exit;
  element:=TAufMap(obj).Delete(key);
  if element=nil then begin
    AufScpt.send_error('警告：散列表不包含键名'+key+'，删除操作未执行。');
  end else begin
    element.Free;
  end;
end;

procedure map_Clear(Sender:TObject);
var AAuf:TAuf;
    AufScpt:TAufScript;
    obj:TObject;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToObject(1,TAufMap,obj) then exit;
  TAufMap(obj).Clear;
end;

procedure map_Read(Sender:TObject);
var AAuf:TAuf;
    AufScpt:TAufScript;
    obj:TObject;
    arv,res:TAufRamVar;
    key:string;
    element:TAufBase;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(4) then exit;
  if not AAuf.TryArgToObject(1,TAufMap,obj) then exit;
  if not AAuf.TryArgToString(2,key) then exit;
  if not AAuf.TryArgToARV(3,1,High(dword),[ARV_FixNum, ARV_Float, ARV_Char],arv) then exit;
  element:=TAufMap(obj).Items[key];
  if element=nil then begin
    AufScpt.send_error('警告：散列表不包含键名'+key+'，未赋值。');
  end else begin
    res:=element.ARV;
    copyARV(res,arv);
  end;
end;

procedure map_Write(Sender:TObject);
var AAuf:TAuf;
    AufScpt:TAufScript;
    obj:TObject;
    arv:TAufRamVar;
    key:string;
    element:TAufBase;
    arv_type:TAufRamVarType;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(4) then exit;
  if not AAuf.TryArgToObject(1,TAufMap,obj) then exit;
  if not AAuf.TryArgToString(2,key) then exit;
  arv_type:=AAuf.TellArgType(3);
  case arv_type of
    ARV_Raw:
      begin
        element:=AufBaseParser(AAuf.args[3]);
      end;
    else
      begin
        if not AAuf.TryArgToARV(3,1,High(dword),[ARV_FixNum, ARV_Float, ARV_Char],arv) then exit;
        element:=TAufBase.CreateAsARV(arv);
      end;
  end;
  TAufMap(obj).Items[key]:=element;
end;

procedure map_Print(Sender:TObject);
var AAuf:TAuf;
    AufScpt:TAufScript;
    obj:TObject;
    val:TAufBase;
    idx,len:Integer;
    key,stmp,split:string;
    ln_mode:boolean;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToObject(1,TAufMap,obj) then exit;
  ln_mode:=pos('println',lowercase(AAuf.args[0]))>0;
  if not ln_mode then begin
    stmp:='{';
    split:=',';
  end else begin
    stmp:='';
    split:={$ifdef WINDOWS}#13#10{$else}#10{$endif};
  end;
  with TAufMap(obj) do begin
    for idx:=0 to Count-1 do begin
      val:=ValuesByIndex[idx];
      key:=KeysByIndex[idx];
      stmp:=stmp+Format('"%s": %s',[key, arv_to_s(val.ARV)]);
      stmp:=stmp+split;
    end;
  end;
  len:=length(stmp);
  if len>2 then System.Delete(stmp,len,length(split));
  if not ln_mode then stmp:=stmp+'}';
  AufScpt.writeln(stmp);
end;

procedure map_Count(Sender:TObject);
var AAuf:TAuf;
    AufScpt:TAufScript;
    obj:TObject;
    arv:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToObject(1,TAufMap,obj) then exit;
  if not AAuf.TryArgToARV(2,1,High(longint),[ARV_FixNum],arv) then exit;
  dword_to_arv(TAufMap(obj).Count,arv);
end;

end.

