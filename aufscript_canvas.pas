unit aufscript_canvas;

{$mode objfpc}{$H+}
{$inline on}

interface

uses
  Classes, SysUtils, Controls, ExtCtrls, Graphics;

type

  TShapeType = (astUnknown=0, astRectangle, astEllipse);

  TAufShape = class
  private
    FShapeId:Integer;
    FShapeType:TShapeType;
  public
    Style:record
      Width:Integer;
      HoverWidth:Integer;
      FillColor:TColor;
      StrokeColor:TColor;
      HoverFillColor:TColor;
      HoverStrokeColor:TColor;
    end;
  public
    procedure Draw(ACanvas:TCanvas;AHover:boolean=false);virtual;
    function PointContains(APoint:TPoint):boolean;virtual;abstract;
  public
    constructor Create;
  end;

  TAufRectangle = class(TAufShape)
  private
    FCoordinates:array of TPoint;
  public
    procedure Draw(ACanvas:TCanvas;AHover:boolean=false);override;
    function PointContains(point:TPoint):boolean;override;
  public
    constructor Create(APoints:array of TPoint);
    constructor CreateByRect(ARect:TRect);
    destructor Destroy; override;
  end;

  TAufEllipse = class(TAufShape)
  private
    FCentroid:TPoint;
    FWidth:Integer;
    FHeight:Integer;
  public
    procedure Draw(ACanvas:TCanvas;AHover:boolean=false);override;
    function PointContains(APoint:TPoint):boolean;override;
  public
    constructor Create(ACentroid:TPoint; AWidth, AHeight:Integer);
    constructor CreateByRect(ARect:TRect);
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
    FHoverShape:TAufShape;
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

procedure TAufShape.Draw(ACanvas:TCanvas;AHover:boolean=false);
begin
  ACanvas.Brush.Style:=bsSolid;
  ACanvas.Pen.Style:=psSolid;
  if AHover then begin
    ACanvas.Brush.Color:=Style.HoverFillColor;
    ACanvas.Pen.Color:=Style.HoverStrokeColor;
    ACanvas.Pen.Width:=Style.HoverWidth;
  end else begin
    ACanvas.Brush.Color:=Style.FillColor;
    ACanvas.Pen.Color:=Style.StrokeColor;
    ACanvas.Pen.Width:=Style.Width;
  end;
end;

constructor TAufShape.Create;
begin
  with Style do begin
    Width:=1;
    HoverWidth:=1;
    FillColor:=clRed;
    StrokeColor:=clBlack;
    HoverFillColor:=clMaroon;
    HoverStrokeColor:=clBlack;
  end;
end;

{ TAufRectangle }

procedure TAufRectangle.Draw(ACanvas:TCanvas;AHover:boolean=false);
begin
  if Length(FCoordinates)<3 then exit;
  inherited Draw(ACanvas, AHover);
  ACanvas.Polygon(FCoordinates);
end;

//这个函数deepseek写的
function TAufRectangle.PointContains(point:TPoint):boolean;
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

constructor TAufRectangle.Create(APoints:array of TPoint);
var count_point:integer;
begin
  inherited Create;
  FShapeType:=astRectangle;
  count_point:=Length(APoints);
  SetLength(FCoordinates,count_point);
  Move(APoints, FCoordinates, count_point*sizeof(TPoint));
end;

constructor TAufRectangle.CreateByRect(ARect:TRect);
begin
  inherited Create;
  FShapeType:=astRectangle;
  SetLength(FCoordinates, 4);
  FCoordinates[0]:=ARect.TopLeft;
  FCoordinates[2]:=ARect.BottomRight;
  FCoordinates[1].x:=FCoordinates[0].x;
  FCoordinates[1].y:=FCoordinates[2].y;
  FCoordinates[3].x:=FCoordinates[2].x;
  FCoordinates[3].y:=FCoordinates[0].y;
end;

destructor TAufRectangle.Destroy;
begin
  SetLength(FCoordinates, 0);
  inherited Destroy;
end;


{ TAufEllipse }

procedure TAufEllipse.Draw(ACanvas:TCanvas;AHover:boolean=false);
var a,b:integer;
begin
  if (FWidth<=1) or (FHeight<=1) then exit;
  inherited Draw(ACanvas, AHover);
  a:=FWidth div 2;
  b:=FHeight div 2;
  with FCentroid do ACanvas.Ellipse(x-a, y-b, x+a, y+b);
end;

//这个函数deepseek写的
function TAufEllipse.PointContains(APoint:TPoint):boolean;
var dx,dy:double;
    a,b:double;
begin
  dx:=APoint.X-FCentroid.X;
  dy:=APoint.Y-FCentroid.Y;
  a:=FWidth/2;
  b:=FHeight/2;
  if (a>0) and (b>0) then result:=(dx*dx)/(a*a)+(dy*dy)/(b*b)<=1 else result:=false;
end;

constructor TAufEllipse.Create(ACentroid:TPoint; AWidth, AHeight:Integer);
begin
  inherited Create;
  FShapeType:=astEllipse;
  FCentroid:=ACentroid;
  FWidth:=AWidth;
  FHeight:=AHeight;
end;

constructor TAufEllipse.CreateByRect(ARect:TRect);
begin
  inherited Create;
  FShapeType:=astEllipse;
  FCentroid:=ARect.CenterPoint;
  FWidth:=ARect.Width;
  FHeight:=ARect.Height;
end;

destructor TAufEllipse.Destroy;
begin
  inherited Destroy;
end;



{ TAufShapeContainer }

procedure TAufShapeContainer.CheckCompact;
begin
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
    if shp<>nil then shp.Draw(Canvas, shp=FHoverShape);
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
var picked_shape:TAufShape;
begin
  picked_shape:=FContainer.PickShape(Classes.Point(X,Y));
  if picked_shape=nil then begin
    if FHoverShape<>nil then begin
      FHoverShape:=nil;
      Invalidate;
    end;
    exit;
  end;
  if FHoverShape<>picked_shape then begin
    FHoverShape:=picked_shape;
    Invalidate;
  end;
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
  FHoverShape:=nil;
  DoubleBuffered:=true;
end;

destructor TAufCanvasPanel.Destroy;
begin
  FContainer.Free;
  inherited Destroy;
end;



end.

