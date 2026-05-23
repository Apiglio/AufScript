unit aufscript_canvas;

{$mode objfpc}{$H+}

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
  public
    function AddShape(shape:TAufShape):Integer;
    procedure Clear;
    constructor Create;
    destructor Destroy; override;
  public
    function PickShape(pick:TPoint):TAufShape;
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
function TAufShapeContainer.AddShape(shape:TAufShape):Integer;
begin
  FList.Add(shape);
  inc(FAutoInc);
  shape.FShapeId:=FAutoInc;
  result:=FAutoInc;
end;

procedure TAufShapeContainer.Clear;
var index:integer;
begin
  for index:=FList.Count-1 downto 0 do TAufShape(FList[index]).Free;
  FList.Clear;
end;

constructor TAufShapeContainer.Create;
begin
  inherited Create;
  FList:=TList.Create;
  FAutoInc:=0;
end;

destructor TAufShapeContainer.Destroy;
begin
  Clear;
  FList.Free;
  inherited Destroy;
end;

function TAufShapeContainer.PickShape(pick:TPoint):TAufShape;
var index:integer;
begin
  for index:=FList.Count-1 downto 0 do begin
    result:=TAufShape(FList[index]);
    if result.PointContains(pick) then exit;
  end;
  result:=nil;
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
    shp.Draw(Canvas);
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
  pdword(event_arv.Head)^:=X;
  pdword(event_arv.Head+1)^:=Y;
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

