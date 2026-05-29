unit aufscript_canvas;

{$mode objfpc}{$H+}
{$inline on}

interface

uses
  Classes, SysUtils, Controls, ExtCtrls, Graphics;

type

  TShapeType = (astUnknown=0, astPolygon, astEllipse, astPolyline, astCaption);
  TShapeStyle = (assFillColor=0, assBorderColor=1, assStrokeColor=2, assSymbolWidth=3, assBorderWidth=4, assStrokeWidth=5);
  TShapeState = $0..$f;

const
  ShapeStateCount = 4;
  assNormal   : TShapeState = $1;
  assHover    : TShapeState = $2;
  assToggled  : TShapeState = $4;
  assFocus    : TShapeState = $8;
  assAllState : TShapeState = $f;

{
                  text  point line  face
  fill-color      O     O     X     O
  border-color    X     O     O     O
  stroke-color    O     O     O     O
  symbol-width    O     O     X     X
  border-width    X     O     O     O
  stroke-width    O     O     O     O
  :normal         O     O     O     O
  :hover          X     O     X     O
  :toggled        X     O     X     O
  :focus          X     O     X     O
}

type

  TAufStateStyle = class
  private
    FStyle:PDWORD;
  public
    function GetColor(AStyle:TShapeStyle; AState:TShapeState):TColor;
    function GetDWord(AStyle:TShapeStyle; AState:TShapeState):DWord;
    procedure SetColor(AStyle:TShapeStyle; AState:TShapeState; value:TColor);
    procedure SetDWord(AStyle:TShapeStyle; AState:TShapeState; value:DWord);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(AStyle:TAufStateStyle);
  end;

  TAufShape = class
  private
    FShapeId:Integer;
    FShapeType:TShapeType;
    FStyle:TAufStateStyle;
  public
    procedure Draw(ACanvas:TCanvas;AHover:boolean=false);virtual;
    function PointContains(APoint:TPoint):boolean;virtual;abstract;
  public
    constructor Create;
    destructor Destroy; override;
    property Style:TAufStateStyle read FStyle write FStyle;
  end;

  TAufPolygon = class(TAufShape)
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

  TAufPolyline = class(TAufShape)
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

  TAufCaption = class(TAufShape)
  private
    FCentroid:TPoint;
    FMaxWidth:Integer; //小于0表示无限制
    FCaption:String;
    //FCache:TBitmap;
  //private
    //procedure BuildCache;
  public
    procedure Draw(ACanvas:TCanvas;AHover:boolean=false);override;
    function PointContains(APoint:TPoint):boolean;override;
  public
    constructor Create(ACentroid:TPoint;ACaption:String;AScale:Integer);
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

var
    _DEFAULT_SHAPE_STYLE_ : TAufStateStyle;

implementation
uses Apiglio_Useful, auf_ram_var;

{ TAufStateStyle }

function TAufStateStyle.GetColor(AStyle:TShapeStyle; AState:TShapeState):TColor;
var state_bits:TShapeState;
    step:integer;
begin
  state_bits:=AState;
  step:=0;
  while state_bits>0 do begin
    state_bits:=state_bits shr 1;
    inc(step);
  end;
  if step=0 then step:=1;
  dec(step);
  result:=TColor((FStyle+step*(Ord(High(TShapeStyle))+1)+Ord(AStyle))^);
end;

function TAufStateStyle.GetDWord(AStyle:TShapeStyle; AState:TShapeState):DWord;
var state_bits:TShapeState;
    step:integer;
begin
  state_bits:=AState;
  step:=0;
  while state_bits>0 do begin
    state_bits:=state_bits shr 1;
    inc(step);
  end;
  if step=0 then step:=1;
  dec(step);
  result:=(FStyle+step*(Ord(High(TShapeStyle))+1)+Ord(AStyle))^;
end;

procedure TAufStateStyle.SetColor(AStyle:TShapeStyle; AState:TShapeState; value:TColor);
var state_bits:TShapeState;
    step:integer;
begin
  state_bits:=AState;
  for step:=0 to ShapeStateCount-1 do begin
    if (state_bits and $1) > 0 then (FStyle+step*(Ord(High(TShapeStyle))+1)+Ord(AStyle))^:=dword(value);
    state_bits:=state_bits shr 1;
  end;
end;

procedure TAufStateStyle.SetDWord(AStyle:TShapeStyle; AState:TShapeState; value:DWord);
var state_bits:TShapeState;
    step:integer;
begin
  state_bits:=AState;
  for step:=0 to ShapeStateCount-1 do begin
    if (state_bits and $1) > 0 then (FStyle+step*(Ord(High(TShapeStyle))+1)+Ord(AStyle))^:=value;
    state_bits:=state_bits shr 1;
  end;
end;

constructor TAufStateStyle.Create;
begin
  inherited Create;
  FStyle:=AllocMem(ShapeStateCount*(Ord(High(TShapeStyle))+1)*sizeof(DWord));
end;

destructor TAufStateStyle.Destroy;
begin
  FreeMem(FStyle);
  inherited Destroy;
end;

procedure TAufStateStyle.Assign(AStyle:TAufStateStyle);
begin
  move(AStyle.FStyle^, Self.FStyle^, sizeof(DWord)*ShapeStateCount*(Ord(High(TShapeStyle))+1));
end;


{ TAufShape }

procedure TAufShape.Draw(ACanvas:TCanvas;AHover:boolean=false);
var tmpColor:TColor;
begin
  ACanvas.Brush.Style:=bsSolid;
  ACanvas.Pen.Style:=psSolid;
  if AHover then begin
    tmpColor:=Style.GetColor(assFillColor, assHover);
    ACanvas.Brush.Color:=tmpColor;
    if tmpColor shr 24 = $ff then ACanvas.Brush.Style:=bsClear;

    tmpColor:=Style.GetColor(assBorderColor, assHover);
    ACanvas.Pen.Color:=tmpColor;
    if tmpColor shr 24 = $ff then ACanvas.Pen.Style:=psClear;

    ACanvas.Pen.Width:=Style.GetDWord(assBorderWidth, assHover);
  end else begin
    tmpColor:=Style.GetColor(assFillColor, assNormal);
    ACanvas.Brush.Color:=tmpColor;
    if tmpColor shr 24 = $ff then ACanvas.Brush.Style:=bsClear;

    tmpColor:=Style.GetColor(assBorderColor, assNormal);
    ACanvas.Pen.Color:=Style.GetColor(assBorderColor, assNormal);
    if tmpColor shr 24 = $ff then ACanvas.Pen.Style:=psClear;

    ACanvas.Pen.Width:=Style.GetDWord(assBorderWidth, assNormal);
  end;
end;

constructor TAufShape.Create;
begin
  inherited Create;
  FStyle:=TAufStateStyle.Create;
  FStyle.Assign(_DEFAULT_SHAPE_STYLE_);
end;

destructor TAufShape.Destroy;
begin
  FStyle.Free;
  inherited Destroy;
end;

{ TAufPolygon }

procedure TAufPolygon.Draw(ACanvas:TCanvas;AHover:boolean=false);
begin
  if Length(FCoordinates)<3 then exit;
  inherited Draw(ACanvas, AHover);
  ACanvas.Polygon(FCoordinates);
end;

//这个函数deepseek写的
function TAufPolygon.PointContains(point:TPoint):boolean;
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

constructor TAufPolygon.Create(APoints:array of TPoint);
var count_point:integer;
begin
  inherited Create;
  FShapeType:=astPolygon;
  count_point:=Length(APoints);
  SetLength(FCoordinates,count_point);
  Move(APoints, FCoordinates, count_point*sizeof(TPoint));
end;

constructor TAufPolygon.CreateByRect(ARect:TRect);
begin
  inherited Create;
  FShapeType:=astPolygon;
  SetLength(FCoordinates, 4);
  FCoordinates[0]:=ARect.TopLeft;
  FCoordinates[2]:=ARect.BottomRight;
  FCoordinates[1].x:=FCoordinates[0].x;
  FCoordinates[1].y:=FCoordinates[2].y;
  FCoordinates[3].x:=FCoordinates[2].x;
  FCoordinates[3].y:=FCoordinates[0].y;
end;

destructor TAufPolygon.Destroy;
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


{ TAufPolyline }

procedure TAufPolyline.Draw(ACanvas:TCanvas;AHover:boolean=false);
begin
  if Length(FCoordinates)<2 then exit;
  inherited Draw(ACanvas, AHover);
  ACanvas.Polyline(FCoordinates);
end;

function TAufPolyline.PointContains(point:TPoint):boolean;
begin
  result:=false;
end;

constructor TAufPolyline.Create(APoints:array of TPoint);
var count_point:integer;
begin
  inherited Create;
  FShapeType:=astPolyline;
  count_point:=Length(APoints);
  SetLength(FCoordinates,count_point);
  Move(APoints, FCoordinates, count_point*sizeof(TPoint));
end;

constructor TAufPolyline.CreateByRect(ARect:TRect);
begin
  inherited Create;
  FShapeType:=astPolyline;
  SetLength(FCoordinates, 2);
  FCoordinates[0]:=ARect.TopLeft;
  FCoordinates[1]:=ARect.BottomRight;
end;

destructor TAufPolyline.Destroy;
begin
  SetLength(FCoordinates, 0);
  inherited Destroy;
end;


{ TAufCaption }

{
procedure TAufCaption.BuildCache;unimplemented '没有处理好绘制效果，坐标也不对';
var MaxWidth, offset, ofs_idx:Integer;
    TextStyle:TTextStyle;
begin
  FCache.Canvas.Font.Size:=Style.Width;
  if FMaxWidth>=0 then MaxWidth:=FMaxWidth+1
  else MaxWidth:=FCache.Canvas.TextWidth(FCaption);
  FCache.SetSize(MaxWidth,Style.Width+2*Style.HoverWidth+1);
  //FCache.Canvas.Brush.Style:=bsClear;
  //FCache.Canvas.Brush.Color:=clNone;
  //FCache.Canvas.Clear;
  TextStyle.Alignment:=taCenter;
  offset:=Style.HoverWidth;
  if offset>10 then offset:=10;
  FCache.Canvas.Font.Color:=Style.HoverFillColor;
  for ofs_idx:=1 to offset do begin
    FCache.Canvas.TextRect(Classes.Rect(0,0,FCache.Width, FCache.Height),offset+ofs_idx,offset+ofs_idx,FCaption,TextStyle);
    FCache.Canvas.TextRect(Classes.Rect(0,0,FCache.Width, FCache.Height),offset-ofs_idx,offset+ofs_idx,FCaption,TextStyle);
    FCache.Canvas.TextRect(Classes.Rect(0,0,FCache.Width, FCache.Height),offset+ofs_idx,offset-ofs_idx,FCaption,TextStyle);
    FCache.Canvas.TextRect(Classes.Rect(0,0,FCache.Width, FCache.Height),offset-ofs_idx,offset-ofs_idx,FCaption,TextStyle);
  end;
  FCache.Canvas.Font.Color:=Style.FillColor;
  FCache.Canvas.TextRect(Classes.Rect(0,0,FCache.Width, FCache.Height),offset,offset,FCaption,TextStyle);
end;

//和BuildCache没配合好
procedure TAufCaption.Draw(ACanvas:TCanvas;AHover:boolean=false);
var dstRect, srcRect:TRect;
    semi_w, semi_h:integer;
begin
  //inherited Draw(ACanvas, AHover); 文字不需要继承笔刷
  //Style里的Width作为字高 StrokeColor作为描边厚度
  //FillColor是文字颜色 HoverFillColor是描边颜色
  ACanvas.Font.Size:=Style.Width;
  ACanvas.Font.Color:=Style.FillColor;
  semi_w:=FCache.Width div 2;
  semi_h:=FCache.Height div 2;
  srcRect:=Classes.Rect(0,0,FCache.Width,FCache.Height);
  dstRect:=Classes.Rect(FCentroid.x + semi_w, FCentroid.y + semi_h, FCache.Width, FCache.Height);
  ACanvas.CopyMode:=cmSrcCopy;
  ACanvas.CopyRect(dstRect, FCache.Canvas, srcRect);
end;
}

procedure TAufCaption.Draw(ACanvas:TCanvas;AHover:boolean=false);
var MaxWidth, offset, ofs_idx:Integer;
    TextStyle:TTextStyle;
    dstRect:TRect;
    text_w, text_h, semi_w, semi_h:integer;
    ll, tt, rr, bb:integer;
begin
  //inherited Draw(ACanvas, AHover); 文字不需要继承笔刷

  offset:=Style.GetDWord(assStrokeWidth, assNormal);
  if offset>10 then offset:=10; //字体描边最大 10 pixels

  text_h:=Style.GetDWord(assSymbolWidth, assNormal);
  text_w:=ACanvas.TextWidth(FCaption);
  ACanvas.Font.Size:=text_h;
  text_h:=text_h+2*offset;
  text_w:=text_w+2*offset;
  if FMaxWidth>=0 then text_w:=FMaxWidth+1;
  semi_w:=text_w div 2;
  semi_h:=text_h div 2;
  ll:=FCentroid.x - semi_w;
  tt:=FCentroid.y - semi_h;
  rr:=ll + text_w;
  bb:=tt + text_h;

  TextStyle.Alignment:=taCenter;
  ACanvas.Font.Color:=Style.GetColor(assStrokeColor, assNormal);
  for ofs_idx:=1 to offset do begin
    ACanvas.TextRect(Classes.Rect(ll-ofs_idx, tt-ofs_idx, rr-ofs_idx, bb-ofs_idx), ll-ofs_idx, tt-ofs_idx, FCaption, TextStyle);
    ACanvas.TextRect(Classes.Rect(ll+ofs_idx, tt-ofs_idx, rr+ofs_idx, bb-ofs_idx), ll+ofs_idx, tt-ofs_idx, FCaption, TextStyle);
    ACanvas.TextRect(Classes.Rect(ll-ofs_idx, tt+ofs_idx, rr-ofs_idx, bb+ofs_idx), ll-ofs_idx, tt+ofs_idx, FCaption, TextStyle);
    ACanvas.TextRect(Classes.Rect(ll+ofs_idx, tt+ofs_idx, rr+ofs_idx, bb+ofs_idx), ll+ofs_idx, tt+ofs_idx, FCaption, TextStyle);
    ACanvas.TextRect(Classes.Rect(ll+ofs_idx, tt, rr+ofs_idx, bb), ll+ofs_idx, tt, FCaption, TextStyle);
    ACanvas.TextRect(Classes.Rect(ll-ofs_idx, tt, rr-ofs_idx, bb), ll-ofs_idx, tt, FCaption, TextStyle);
    ACanvas.TextRect(Classes.Rect(ll, tt+ofs_idx, rr, bb+ofs_idx), ll, tt+ofs_idx, FCaption, TextStyle);
    ACanvas.TextRect(Classes.Rect(ll, tt-ofs_idx, rr, bb-ofs_idx), ll, tt-ofs_idx, FCaption, TextStyle);
  end;
  ACanvas.Font.Color:=Style.GetColor(assFillColor, assNormal);
  ACanvas.TextRect(Classes.Rect(ll, tt, rr, bb), ll, tt, FCaption, TextStyle);
end;

function TAufCaption.PointContains(APoint:TPoint):boolean;
begin
  result:=false; //标注不能选中
end;

constructor TAufCaption.Create(ACentroid:TPoint;ACaption:String;AScale:Integer);
begin
  inherited Create;
  FShapeType:=astCaption;
  FCentroid:=ACentroid;
  FCaption:=ACaption;
  FMaxWidth:=-1;
  //FCache:=TBitmap.Create;
  //FCache.PixelFormat:=pf32bit;
  Style.SetDWord(assSymbolWidth, assAllState, AScale);
  Style.SetDWord(assStrokeWidth, assAllState, 1);
  Style.SetColor(assStrokeColor, assAllState, clWhite);
  //BuildCache;
end;

constructor TAufCaption.CreateByRect(ARect:TRect);
begin
  inherited Create;
  FShapeType:=astCaption;
  FCentroid:=ARect.CenterPoint;
  FMaxWidth:=ARect.Width;
  //FCache:=TBitmap.Create;
  //FCache.PixelFormat:=pf32bit;
  Style.SetDWord(assSymbolWidth, assAllState, ARect.Height);
  Style.SetDWord(assStrokeWidth, assAllState ,1);
  Style.SetColor(assStrokeColor, assAllState, clWhite);
  //BuildCache;
end;

destructor TAufCaption.Destroy;
begin
  //FCache.Free;
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
    else result:=result+#9+tmpShape.ClassName+'#'+IntToStr(tmpShape.FShapeId);
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


initialization

  _DEFAULT_SHAPE_STYLE_:=TAufStateStyle.Create;

finalization

  _DEFAULT_SHAPE_STYLE_.Free;

end.

