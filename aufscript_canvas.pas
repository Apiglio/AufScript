unit aufscript_canvas;

{$mode objfpc}{$H+}
{$inline on}

interface

uses
  Classes, SysUtils, Controls, ExtCtrls, Graphics;

type

  TShapeType = (astUnknown=0, astFace);

  TAufShape = class
  private
    FShapeId:Integer;
    FShapeType:TShapeType;
    FStyle:record
      FillColor:TColor;
      StrokeColor:TColor;
    end;
  public
    procedure Draw(Canvas:TCanvas);virtual;abstract;
    function PointContains(point:TPoint):boolean;virtual;abstract;
  public
    constructor Create;
  end;

  TAufFace = class(TAufShape)
  private
    FCoordinates:array of TPoint;
  public
    procedure Draw(Canvas:TCanvas);override;
    function PointContains(point:TPoint):boolean;override;
  public
    constructor Create(points:array of TPoint);
    constructor CreateByRect(rect:TRect);
    destructor Destroy; override;
  end;

  TAufShapeContainer = class
  private
    FList:TList;
    FAutoInc:integer; //始终自增的ID
    FNilCount:integer;//计算空图形数量，达nil数量超过五分之一时清理
  private
    procedure CheckCompact;inline;
  public
    function AddShape(shape:TAufShape):Integer;
    procedure Clear;
    procedure Compact; //清空列表中的所有nil
    constructor Create;
    destructor Destroy; override;
  public
    function FindShapeByID(Shape_ID:Integer; out Index:Integer):TAufShape;
    function PickShape(pick:TPoint):TAufShape;
    procedure BringToTop(Shape_ID:Integer);
    procedure SendToBack(Shape_ID:Integer);
  public
    function AsString:string;
  end;

  TAufCanvasPanel = class(TCustomPanel)
  public
    FAufScript:TObject;
    FContainer:TAufShapeContainer;
  private
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure Resize; override;
  protected
    procedure SetAufScript(value:TObject);
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    property Shapes:TAufShapeContainer read FContainer write FContainer;
    property AufScript:TObject read FAufScript write SetAufScript;
  end;

implementation
uses Apiglio_Useful, auf_ram_var;


{ TAufShape }

constructor TAufShape.Create;
begin
  FStyle.FillColor:=clRed;
  FStyle.StrokeColor:=clBlack;
end;

{ TAufFace }

procedure TAufFace.Draw(Canvas: TCanvas);
begin
  if Length(FCoordinates)<3 then exit;
  Canvas.Brush.Color:=FStyle.FillColor;
  Canvas.Brush.Style:=bsSolid;
  Canvas.Pen.Color:=FStyle.StrokeColor;
  Canvas.Pen.Width:=1;
  Canvas.Pen.Style:=psSolid;
  Canvas.Polygon(FCoordinates);
end;

//这个函数deepseek写的
function TAufFace.PointContains(point:TPoint):boolean;
var i,j:integer;
begin
  result:=false;
  if Length(FCoordinates)<3 then exit;
  j:=High(FCoordinates);
  for i:=0 to High(FCoordinates) do begin
    if (((FCoordinates[i].Y>point.Y)<>(FCoordinates[j].Y>point.Y)) and
        (point.X<(FCoordinates[j].X-FCoordinates[i].X)*(point.Y-FCoordinates[i].Y) /
        (FCoordinates[j].Y-FCoordinates[i].Y)+FCoordinates[i].X)) then
    begin
      result:=not result;
    end;
    j:=i;
  end;
end;

constructor TAufFace.Create(points:array of TPoint);
var count_point:integer;
begin
  inherited Create;
  FShapeType:=astFace;
  count_point:=Length(points);
  SetLength(FCoordinates,count_point);
  Move(points, FCoordinates, count_point*sizeof(TPoint));
end;

constructor TAufFace.CreateByRect(rect:TRect);
begin
  inherited Create;
  FShapeType:=astFace;
  SetLength(FCoordinates, 4);
  FCoordinates[0]:=rect.TopLeft;
  FCoordinates[2]:=rect.BottomRight;
  FCoordinates[1].x:=FCoordinates[0].x;
  FCoordinates[1].y:=FCoordinates[2].y;
  FCoordinates[3].x:=FCoordinates[2].x;
  FCoordinates[3].y:=FCoordinates[0].y;
end;

destructor TAufFace.Destroy;
begin
  SetLength(FCoordinates, 0);
  inherited Destroy;
end;


{ TAufShapeContainer }

procedure TAufShapeContainer.CheckCompact;
begin
  writeln(FNilCount, '>?', FList.Count);
  if FNilCount<37 then exit;
  if 5*FNilCount>FList.Count then Compact;
end;

function TAufShapeContainer.AddShape(shape:TAufShape):Integer;
begin
  FList.Add(shape);
  inc(FAutoInc);
  shape.FShapeId:=FAutoInc;
  result:=FAutoInc;
  if shape=nil then inc(FNilCount);
  CheckCompact;
end;

procedure TAufShapeContainer.Clear;
var index:integer;
    tmpShape:TAufShape;
begin
  for index:=FList.Count-1 downto 0 do begin
    tmpShape:=TAufShape(FList[index]);
    if tmpShape<>nil then tmpShape.Free;
  end;
  FList.Clear;
  FNilCount:=0;
  FAutoInc:=0;
end;

//删除图形列表多余的nil，保留前五分之一的nil集中在FList最前，以便SendToBack快速交换
procedure TAufShapeContainer.Compact;
var idx, writeIdx, len, keepNilCount: integer;
begin
  len:=FList.Count;
  if len<37 then exit;
  keepNilCount:=len div 5;
  // 从保留区后开始整理
  writeIdx:=keepNilCount;
  for idx:=keepNilCount to len-1 do begin
    if FList[idx]<>nil then begin
      FList[writeIdx]:=FList[idx];
      inc(writeIdx);
    end;
  end;
  // 删除尾部多余元素
  for idx:=FList.Count-1 downto writeIdx do FList.Delete(idx);
  // 重新规整前三分之一的nil
  writeIdx:=keepNilCount-1;
  for idx:=keepNilCount-1 downto 0 do begin
    if FList[idx]<>nil then begin
      FList[writeIdx]:=FList[idx];
      dec(writeIdx);
    end;
  end;
  for idx:=writeIdx downto 0 do FList[idx]:=nil;
  FNilCount:=writeIdx+1;
end;


constructor TAufShapeContainer.Create;
begin
  inherited Create;
  FList:=TList.Create;
  FAutoInc:=0;
  FNilCount:=0;
end;

destructor TAufShapeContainer.Destroy;
begin
  Clear;
  FList.Free;
  inherited Destroy;
end;

function TAufShapeContainer.FindShapeByID(Shape_ID:Integer; out Index:Integer):TAufShape;
var tmpIndex:integer;
    tmpShape:TAufShape;
begin
  result:=nil;
  if (FAutoInc<Shape_ID) or (Shape_ID<=0) then exit;
  for tmpIndex:=FList.Count-1 downto 0 do begin
    tmpShape:=TAufShape(FList[tmpIndex]);
    if tmpShape=nil then continue;
    if tmpShape.FShapeId=Shape_ID then begin
      result:=tmpShape;
      Index:=tmpIndex;
      exit;
    end;
  end;
end;

function TAufShapeContainer.PickShape(pick:TPoint):TAufShape;
var index:integer;
begin
  for index:=FList.Count-1 downto 0 do begin
    result:=TAufShape(FList[index]);
    if result=nil then continue;
    if result.PointContains(pick) then exit;
  end;
  result:=nil;
end;

procedure TAufShapeContainer.BringToTop(Shape_ID:Integer);
var idx,len:integer;
begin
  if FindShapeByID(Shape_ID, idx) = nil then exit;
  len:=FList.Count;
  if idx+1=len then exit;
  FList.Add(nil);//不能用AddShape，有可能正好达到导致Compact的FNilCount
  FList[len]:=FList[idx];
  FList[idx]:=nil;
  inc(FNilCount);
  CheckCompact;
end;

procedure TAufShapeContainer.SendToBack(Shape_ID:Integer);
var idx,len,last_head_nil,tmp_idx:integer;
begin
  if FindShapeByID(Shape_ID, idx) = nil then exit;
  len:=FList.Count;
  if idx=0 then exit;
  for last_head_nil:=0 to len-1 do begin
    if FList[last_head_nil]<>nil then break;
  end;
  if last_head_nil=0 then begin
    //列表开头没有nil：在前面创建4个nil，然后将指定图形与第4个nil交换
    for tmp_idx:=0 to 3 do FList.Add(nil);
    for tmp_idx:=len-1 downto 0 do FList[tmp_idx+4]:=FList[tmp_idx];
    for tmp_idx:=0 to 3 do FList[tmp_idx]:=nil;
    FList[3]:=FList[idx+4];
    FList[idx+4]:=nil;
    inc(FNilCount,4);
  end else begin
    //列表开头有nil：直接将指定图形和最后一个nil交换
    FList[last_head_nil-1]:=FList[idx];
    FList[idx]:=nil;
  end;
  CheckCompact;
end;

function TAufShapeContainer.AsString:string;
var idx,len:integer;
    tmpShape:TAufShape;
begin
  result:='';
  len:=FList.Count;
  for idx:=0 to len-1 do begin
    tmpShape:=TAufShape(FList[idx]);
    if tmpShape=nil then result:=result+#9+'_'
    else result:=result+#9+'s'+IntToStr(tmpShape.FShapeId);
  end;
end;

{ TAufCanvasPanel }

procedure TAufCanvasPanel.Paint;
var idx, len:integer;
    shp:TAufShape;
begin
  inherited Paint;
  len:=FContainer.FList.Count;
  for idx:=0 to len-1 do begin
    shp:=TAufShape(FContainer.FList[idx]);
    if shp<>nil then shp.Draw(Canvas);
  end;
end;

procedure TAufCanvasPanel.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin

end;

procedure TAufCanvasPanel.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var picked_shape:TAufShape;
    event_arv:TAufRamVar;
    AufScpt:TAufScript;
begin
  AufScpt:=FAufScript as TAufScript;
  picked_shape:=FContainer.PickShape(Classes.Point(X,Y));
  if picked_shape=nil then exit;
  if not AufScpt.TaskMessageEnabled then exit;
  newARV(event_arv, 32);
  fillARV(0,event_arv);
  pdword(event_arv.Head)^:=1;
  pdword(event_arv.Head+4)^:=picked_shape.FShapeId;
  pdword(event_arv.Head+8)^:=X;
  pdword(event_arv.Head+12)^:=Y;
  AufScpt.SendTaskMessage(AufScpt, event_arv, mcCanvas);
  freeARV(event_arv);
end;

procedure TAufCanvasPanel.MouseMove(Shift: TShiftState; X, Y: Integer);
begin

end;

procedure TAufCanvasPanel.Resize;
begin

end;

procedure TAufCanvasPanel.SetAufScript(value:TObject);
begin
  if not (value is TAufScript) then raise Exception.Create('FAufScript必须是TAufScript类，不能是'+value.ClassName+'。');
  FAufScript:=value;
end;

constructor TAufCanvasPanel.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FContainer:=TAufShapeContainer.Create;
end;

destructor TAufCanvasPanel.Destroy;
begin
  FContainer.Free;
  inherited Destroy;
end;



end.

