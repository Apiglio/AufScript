unit auf_type_array;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, auf_type_base, auf_ram_var;

type

  TAufArrayError = class(TAufBaseError)

  end;

  PAufBaseBoolFunc = function(item:TAufBase):boolean;
  PAufBaseBaseFunc = function(item:TAufBase):TAufBase;
  TAufArray = class(TAufBase)
  private
    FArray:array of TAufBase;
    FParentArray:TAufArray;
  protected
    function getValidReadIndex(index:Integer):Integer;
    function getValidWriteIndex(index:Integer):Integer;
    function GetItem(Index:Integer):TAufBase;
    procedure SetItem(Index:Integer;element:TAufBase);
  public
    procedure Insert(index:Integer;element:TAufBase); //在第index个元素前插入element
    procedure Append(element:TAufBase);               //在数组末尾追加element
    function Delete(index:Integer):TAufBase;          //删除第index个元素，并返回删除的元素
    procedure Delete(key:PAufBaseBoolFunc);           //根据key的返回结果批量删除元素
    procedure Replace(key:PAufBaseBaseFunc);          //根据key的返回结果批量替换元素
    function Find(element:TAufBase):Integer;          //查找element，并返回所在位置下标，找不到则返回元素总数
    function Count:Integer;                           //返回元素个数
    property Items[Index:Integer]:TAufBase read GetItem write SetItem; default;
    property ParentArray:TAufArray read FParentArray write FParentArray;
  public
    function Draw:TAufBase;                           //抽牌：随机返回一个元素并从数组中移除
    procedure Reinsert(element:TAufBase);             //插牌：将元素随机插入数组中的一个位置
    procedure Shuffle;                                //洗牌：随机打乱数组顺序
    procedure Clear;                                  //清空：清除所有元素

  public
    procedure LinkInsert(index:Integer;link_element:TAufBase);  //Insert的指针版本
    procedure LinkAppend(link_element:TAufBase);                //Append的指针版本
    procedure Assign(ASource:TAufBase); override;
    function Copy:TAufBase; override;
    function ToString: ansistring; override;
  public
    constructor Create;                               //创建不定长数组
    destructor Destroy; override;                     //释放不定长数组
    class function AufTypeName:String; override;
  end;


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
  //FArray[index]:=TAufBase.Create;
  //FArray[index].Assign(element);
  FArray[len]:=element.Copy;
end;

procedure TAufArray.Append(element:TAufBase);
var len:Integer;
begin
  len:=Length(FArray);
  SetLength(FArray,len+1);
  //FArray[len]:=TAufBase.Create;
  //FArray[len].Assign(element);
  FArray[len]:=element.Copy;
end;

function TAufArray.Delete(index:Integer):TAufBase;
var len,pi:Integer;
begin
  result:=nil;
  len:=Length(FArray);
  if len<=0 then exit;
  index:=getValidReadIndex(index);
  result:=FArray[index];
  for pi:=index to len-1 do begin
    FArray[pi]:=FArray[pi+1];
  end;
  SetLength(FArray,len-1);
end;

procedure TAufArray.Delete(key:PAufBaseBoolFunc);
var len,idx,ofs:Integer;
begin
  ofs:=0;
  idx:=0;
  len:=Length(FArray);
  while idx+ofs<len do begin
    FArray[idx]:=FArray[idx+ofs];
    if key(FArray[idx]) then begin
      FArray[idx].Free;
      inc(ofs);
    end else begin
      inc(idx);
    end;
  end;
  if ofs>0 then SetLength(FArray,len-ofs);
end;

procedure TAufArray.Replace(key:PAufBaseBaseFunc);
var len,idx:Integer;
    tmpElement:TAufBase;
begin
  idx:=0;
  len:=Length(FArray);
  for idx:=0 to len-1 do begin
    tmpElement:=key(FArray[idx]);
    if tmpElement<>nil then begin
      FArray[idx].Free;
      FArray[idx]:=tmpElement;
    end;
  end;
end;

procedure TAufArray.LinkInsert(index:Integer;link_element:TAufBase);
var len,pi:Integer;
begin
  index:=getValidWriteIndex(index);
  len:=Length(FArray);
  SetLength(FArray,len+1);
  for pi:=len-1 downto index do begin
    FArray[pi+1]:=FArray[pi];
  end;
  FArray[len]:=link_element;
end;

procedure TAufArray.LinkAppend(link_element:TAufBase);
var len:Integer;
begin
  len:=Length(FArray);
  SetLength(FArray,len+1);
  FArray[len]:=link_element;
end;

procedure TAufArray.Assign(ASource:TAufBase);
var len,idx:Integer;
    SourceElement:TAufBase;
begin
  if not (ASource is TAufArray) then TAufArrayError.Create('AufArray must assigned by another AufArray.');
  len:=(ASource as TAufArray).Count;
  SetLength(FArray, len);
  for idx:=0 to len-1 do begin
    SourceElement:=(ASource as TAufArray).Items[idx];
    if SourceElement.ARV.VarType=ARV_Raw then begin
      //非基本类型传指针
      FArray[idx]:=(ASource as TAufArray).Items[idx];
    end else begin
      //基本类型复制
      FArray[idx]:=(ASource as TAufArray).Items[idx].Copy;
    end;
  end;
end;

function TAufArray.Copy:TAufBase;
begin
  result:=TAufArray.Create;
  (result as TAufArray).Assign(Self);
end;

function TAufArray.ToString: ansistring;
var idx,max:Integer;
begin
  result:='[';
  max:=Length(FArray)-1;
  for idx:=0 to max do begin
    result:=result+FArray[idx].ToString;
    if idx<>max then result:=result+', ';
  end;
  result:=result+']';
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
var len,idx:Integer;
    elem:TAufBase;
begin
  len:=Length(FArray);
  for idx:=0 to len-1 do begin
    elem:=FArray[idx];
    if elem.ARV.VarType=ARV_Raw then begin
      //非基本类型，不属于子数组的不析构
      if elem is TAufArray then
        with elem as TAufArray do
          if ParentArray=Self then Free;
    end else begin
      //基本类型析构
      elem.Free;
    end;
  end;
  SetLength(FArray,0);
end;

constructor TAufArray.Create;
begin
  inherited Create;
  FParentArray:=nil;
  FARV.Head:=@Self;
  FARV.size:={$ifdef cpu64}8{$else}4{$endif};
end;

destructor TAufArray.Destroy;
begin
  Clear;
  FARV.Head:=nil;
  FARV.size:=0;
  inherited Destroy;
end;

class function TAufArray.AufTypeName:String;
begin
  result:='array';
end;

initialization
  Randomize;

end.

