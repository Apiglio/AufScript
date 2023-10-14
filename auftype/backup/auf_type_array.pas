unit auf_type_array;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, auf_type_base;

type

  TAufArrayError = class(TAufBaseError)

  end;

  TAufArray = class(TAufBase)
  private
    FArray:array of TAufBase;
  protected
    function getValidReadIndex(index:Integer):Integer;
    function getValidWriteIndex(index:Integer):Integer;
    function GetItem(Index:Integer):TAufBase;
    procedure SetItem(Index:Integer;element:TAufBase);
  public
    procedure Insert(index:Integer;element:TAufBase); //在第index个元素前插入element
    function Delete(index:Integer):TAufBase;          //删除第index个元素，并返回删除的元素
    function Find(element:TAufBase):Integer;          //查找element，并返回所在位置下标，找不到则返回元素总数
    function Count:Integer;                           //返回元素个数
    property Items[Index:Integer]:TAufBase read GetItem write SetItem; default;
  public
    function Draw:TAufBase;                           //抽牌：随机返回一个元素并从数组中移除
    procedure Reinsert(element:TAufBase);             //插牌：将元素随机插入数组中的一个位置
    procedure Shuffle;                                //洗牌：随机打乱数组顺序
    procedure Clear;                                  //清空：清除所有元素

  public
    constructor Create;                 //按照指定类型创建不定长数组
    destructor Destroy; override;                     //释放不定长数组
  public
    class function InstanceCount:Integer;             //返回总共多少个实例
    class function InstanceClear:boolean;             //释放所有实例
  end;

var List_AufArray:TList;

implementation

{ TAufArray }

function TAufArray.getValidReadIndex(index:Integer):Integer;
var len:Integer;
begin
  len:=Length(FArray);
  if index>=len then raise TAufArrayError.Create('下标超界');
  if index<-len then raise TAufArrayError.Create('下标超界');
  if index<0 then result:=len+index else result:=index;
end;

function TAufArray.getValidWriteIndex(index:Integer):Integer;
var len:Integer;
begin
  len:=Length(FArray);
  if index>len then raise TAufArrayError.Create('下标超界');
  if index<-len then raise TAufArrayError.Create('下标超界'); //Length作为向末尾插入的特例，相反的-Length-1不支持
  if index<0 then result:=len+index else result:=index;
end;

function TAufArray.GetItem(Index:Integer):TAufBase;
begin
  Index:=getValidReadIndex(Index);
  result:=FArray[Index];
end;

procedure TAufArray.SetItem(Index:Integer;element:TAufBase);
begin
  Index:=getValidReadIndex(Index);
  FArray[Index]:=element;
end;

procedure TAufArray.Insert(index:Integer;element:TAufBase);
var len,pi:Integer;
begin
  index:=getValidWriteIndex(index);
  len:=Length(FArray);
  SetLength(FArray,len+1);
  for pi:=len-1 downto index do begin
    FArray[pi+1]:=FArray[pi];
  end;
  FArray[index]:=TAufBase.Create;
  FArray[index].Assign(element);
end;

function TAufArray.Delete(index:Integer):TAufBase;
var len,pi:Integer;
begin
  index:=getValidReadIndex(index);
  len:=Length(FArray);
  result:=FArray[index];
  for pi:=index to len-1 do begin
    FArray[pi]:=FArray[pi+1];
  end;
  SetLength(FArray,len-1);
end;

function TAufArray.Find(element:TAufBase):Integer;
var len:Integer;
begin
  len:=Length(FArray);
  result:=0;
  while result<len do begin
    if FArray[result].Equal(element) then exit;
    inc(result);
  end;
end;

function TAufArray.Count:Integer;
begin
  result:=Length(FArray);
end;

function TAufArray.Draw:TAufBase;
var index:Integer;
begin
  index:=random(Length(FArray));
  result:=Delete(index);
end;

procedure TAufArray.Reinsert(element:TAufBase);
var index:Integer;
begin
  index:=random(Length(FArray)+1);
  Insert(index,element);
end;

procedure TAufArray.Shuffle;
var len,pi,rand:Integer;
    tmp:TAufBase;
begin
  len:=Length(FArray);
  for pi:=len-1 downto 1 do begin
    rand:=random(pi+1);
    if rand=pi then continue;
    tmp:=FArray[rand];
    FArray[rand]:=FArray[pi];
    FArray[pi]:=tmp;
  end;
end;

procedure TAufArray.Clear;
var len,pi:Integer;
begin
  len:=Length(FArray);
  for pi:=1 to len-1 do FArray[pi].Free;
  SetLength(FArray,0);
end;

constructor TAufArray.Create;
begin
  inherited Create;
  List_AufArray.Add(Self);
end;

destructor TAufArray.Destroy;
var len,pi:Integer;
begin
  len:=Length(FArray);
  for pi:=0 to len-1 do begin
    FArray[pi].Free;
  end;
  List_AufArray.Remove(Self);
  inherited Destroy;
end;

class function TAufArray.InstanceCount:Integer;
begin
  result:=List_AufArray.Count;
end;

class function TAufArray.InstanceClear:boolean;
begin
  result:=false;
  while List_AufArray.Count>0 do begin
    TAufArray(List_AufArray[0]).Free;
    List_AufArray.Delete(0);
  end;
  result:=true;
end;


initialization
  Randomize;
  List_AufArray:=TList.Create;

finalization
  List_AufArray.Free;
end.

