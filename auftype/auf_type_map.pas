unit auf_type_map;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, auf_type_base, auf_ram_var;

type

  TAufMapError = class(TAufBaseError)

  end;

  TAufMap = class(TAufObject)
  private
    FMap:TStringList;
  protected
    function GetItem(Key:String):TAufBase;
    procedure SetItem(Key:String;element:TAufBase);
    function GetValueByIndex(Index:Integer):TAufBase;
    function GetKeyByIndex(Index:Integer):String;
  public
    function Delete(Key:String):TAufBase;             //删除第index个元素，并返回删除的元素
    function Count:Integer;                           //返回条目个数
    procedure Clear;                                  //清空：清除所有元素
    property Items[Key:String]:TAufBase read GetItem write SetItem; default;
    property ValuesByIndex[Index:Integer]:TAufBase read GetValueByIndex;
    property KeysByIndex[Index:Integer]:String read GetKeyByIndex;
  public
    procedure Assign(ASource:TAufBase); override;
    function Copy:TAufBase; override;
    function ToString: ansistring; override;
  public
    constructor Create(DefineARV:TAufRamVar);         //创建散列表
    destructor Destroy; override;                     //释放散列表
    class function AufTypeName:String; override;
  end;

implementation

function TAufMap.GetItem(Key:String):TAufBase;
var idx:integer;
begin
  if FMap.Find(Key, idx) then begin
    result:=TAufBase(FMap.Objects[idx]);
  end else begin
    result:=nil;
  end;
end;

procedure TAufMap.SetItem(Key:String;element:TAufBase);
var idx:integer;
begin
  if FMap.Find(Key, idx) then begin
    //覆盖时会释放原先的值
    TAufBase(FMap.Objects[idx]).Free;
    FMap.Objects[idx]:=element;
  end else begin
    //使用成员赋值需要在外层.copy
    FMap.AddObject(Key, element);
  end;
end;

function TAufMap.GetValueByIndex(Index:Integer):TAufBase;
begin
  result:=nil;
  if Index>=FMap.Count then exit;
  if Index<0 then Index:=Index+FMap.Count;
  if Index<0 then exit;
  result:=TAufBase(FMap.Objects[Index]);
end;

function TAufMap.GetKeyByIndex(Index:Integer):String;
begin
  if Index>=FMap.Count then raise TAufMapError.Create('TAufMap：无效的下标。');;
  if Index<0 then Index:=Index+FMap.Count;
  if Index<0 then raise TAufMapError.Create('TAufMap：无效的下标。');;
  result:=FMap.Strings[Index];
end;

function TAufMap.Delete(Key:String):TAufBase;
var idx:integer;
begin
  if FMap.Find(Key, idx) then begin
    result:=TAufBase(FMap.Objects[idx]);
    FMap.Delete(idx);
  end else begin
    result:=nil;
  end;
end;


function TAufMap.Count:Integer;
begin
  result:=FMap.Count;
end;

procedure TAufMap.Clear;
var idx,len:integer;
begin
  len:=FMap.Count;
  for idx:=len-1 downto 0 do TAufBase(FMap.Objects[idx]).Free;
  //这里没有考虑链接对象的情况，Array中的链接对象删除判断也已经因为给定DefineARV不可用了
  //之后应该统一改成通过ParentObject判断
  FMap.Clear;
end;

procedure TAufMap.Assign(ASource:TAufBase);
var idx,len:integer;
    key:string;
    value:TAufBase;
begin
  if not (ASource is TAufMap) then TAufMapError.Create('AufMap must assigned by another AufMap.');
  len:=TAufMap(ASource).FMap.Count;
  for idx:=0 to len-1 do begin
    key:=TAufMap(ASource).FMap.Strings[idx];
    value:=TAufBase(TAufMap(ASource).FMap.Objects[idx]);
    Items[key]:=value.Copy;
  end;
end;

function TAufMap.Copy:TAufBase;
begin
  result:=TAufMap.Create(ARV_Nil);
  (result as TAufMap).Assign(Self);
end;

function TAufMap.ToString: ansistring;
var idx,len:integer;
    key:string;
    value:TAufBase;
begin
  result:='{';
  len:=FMap.Count;
  for idx:=0 to len-1 do begin
    key:=FMap.Strings[idx];
    value:=TAufBase(FMap.Objects[idx]);
    result:=result+format('"%s":%s',[key, value.ToString]);
    if idx<>len-1 then result:=result+', ';
  end;
  result:=result+'}';
end;

constructor TAufMap.Create(DefineARV:TAufRamVar);
begin
  inherited Create(DefineARV);
  FMap:=TStringList.Create;
  FMap.Sorted:=true;
end;

destructor TAufMap.Destroy;
begin
  Clear;
  FMap.Free;
  inherited Destroy;
end;

class function TAufMap.AufTypeName:String;
begin
  result:='map';
end;

end.

