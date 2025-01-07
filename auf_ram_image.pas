unit auf_ram_image;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics;

type
  TARImage = class
    FPicture:TPicture;

  public
    function Width:integer;
    function Height:integer;
    function AverageColor:TColor;
    function PixelFormat:string;

    //Clip
    function Clip(ARect:TRect):TARImage;

    //Compare
    function ImgEqual(Img:TARImage):boolean;

    //AddByLine
    function SameWidth(Img:TARImage):boolean;
    function FindStart(Img:TARImage;pixel_width:integer;back_match:integer;var back_count:integer):integer;
    function FindStart(Img:TARImage;pixel_width:integer):integer;
    function AddByLine(Img:TARImage;pixel_width:integer;back_match:integer=0):TARImage;
    function FindVoid(min_height,tolerance:integer):integer;
    function VoidSegmentByLine(out ImgRest:TARImage;min,tor:integer):TARImage;

    //AutoCombine
    function SubImageRect(Img:TARImage):TRect;unimplemented;//返回Img在Self中的坐标
    procedure CombineWith(Img:TARImage;ARect:TRect);unimplemented;//将Img根据ARect的位置插入到Self中

  public
    procedure Clear;
    procedure LoadFromStream(AStream:TStream);
    procedure SaveToStream(AStream:TStream);
    procedure LoadFromFile(filename:string);
    procedure SaveToFile(filename:string);

  public
    constructor Create;
    destructor Destroy; override;
    function AufTypeName:string;{override;//这个还没改成继承自AufBase}
    class function ImageCount:Integer;
    class function ClearImageList:boolean;
  end;

var
  ARImageList:TList;

implementation

{ TARImage }

constructor TARImage.Create;
begin
  inherited Create;
  ARImageList.Add(Self);
  FPicture:=TPicture.Create;
end;

destructor TARImage.Destroy;
begin
  FPicture.Free;
  ARImageList.Remove(Self);
  inherited Destroy;
end;

function TARImage.AufTypeName:string;
begin
  result:='img';
end;

function TARImage.Width:integer;
begin
  result:=FPicture.Width;
end;

function TARImage.Height:integer;
begin
  result:=FPicture.Height;
end;
function TARImage.AverageColor:TColor;
var pi,pj,pk:integer;
    acc:array[0..3] of int64;
    phead:pbyte;
    max_color:byte;
begin
  result:=clBlack;
  if FPicture.Bitmap.Height*FPicture.Bitmap.Width=0 then exit;

  case FPicture.Bitmap.PixelFormat of
    pf32bit:max_color:=3;
    pf24bit:max_color:=2;
    else raise Exception.Create('不支持的像素类型。')
  end;

  for pk:=0 to 3 do acc[pk]:=0;
  phead:=pbyte(FPicture.Bitmap.ScanLine[0]);
  for pi:=0 to FPicture.Bitmap.Height-1 do begin
    for pj:=0 to FPicture.Bitmap.Width-1 do begin
      for pk:=0 to max_color do begin
        acc[pk]:=acc[pk]+phead^;
        phead:=phead+1;
      end;
    end;
  end;
  for pk:=0 to 3 do acc[pk]:=acc[pk] div (FPicture.Bitmap.Width * FPicture.Bitmap.Height);
  result:=(acc[0] shl 24) or (acc[1] shl 16) or (acc[2] shl 8) or acc[3];
end;
function TARImage.PixelFormat:string;
begin
  case FPicture.Bitmap.PixelFormat of
    pf32bit:result:='32 bits';
    pf24bit:result:='24 bits';
    pf16bit:result:='16 bits';
    pf15bit:result:='15 bits';
    pf8bit: result:='08 bits';
    pf4bit: result:='04 bits';
    pf1bit: result:='01 bit.';
    else    result:='unknown'
  end;
end;
function TARImage.Clip(ARect:TRect):TARImage;
var rdst:TRect;
begin
  result:=nil;
  if (ARect.Width<=0) or (ARect.Height<=0) then exit;
  if (ARect.Width>FPicture.Bitmap.Width) or (ARect.Height>FPicture.Bitmap.Height) then exit;
  result:=TARImage.Create;
  try
    rdst:=Rect(0,0,ARect.Width,ARect.Height);
    result.FPicture.Bitmap.SetSize(ARect.Width,ARect.Height);
    result.FPicture.Bitmap.Canvas.CopyRect(rdst,FPicture.Bitmap.Canvas,ARect);
  except
    result.Free;
    result:=nil;
  end;
end;

function TARImage.ImgEqual(Img:TARImage):boolean;
var b1,b2:TBitmap;
    pf_width:byte;
begin
  result:=false;
  b1:=FPicture.Bitmap;
  b2:=Img.FPicture.Bitmap;
  if b1.PixelFormat<>b2.PixelFormat then exit;
  if b1.Height<>b2.Height then exit;
  if b1.Width<>b2.Width then exit;
  case b1.PixelFormat of
    pf24bit:pf_width:=3;
    pf32bit:pf_width:=4;
    else raise Exception.Create('不支持的像素类型。');
  end;
  result:=CompareMem(pbyte(b1.ScanLine[0]),pbyte(b2.ScanLine[0]),b1.Width*b1.Height*pf_width);
end;

function TARImage.SameWidth(Img:TARImage):boolean;
begin
  result:=FPicture.Width=Img.FPicture.Width;
end;

//查找Img与Self的相同行，在Self最底部pixel_width行与Img部分行相同时返回Img相同内容部分之后的下一行
//back_match表示，在底部匹配失败后尝试往上平移匹配几次，平移匹配结果返回在back_count
function TARImage.FindStart(Img:TARImage;pixel_width:integer;back_match:integer;var back_count:integer):integer;
var ht1,ht2,wt:integer;
    cursor1,cursor2,cc1,cc2:integer;
    b1,b2:TBitmap;
    base_pass:boolean;
    pf_width:byte;
begin
  result:=-1;
  if not SameWidth(Img) then exit;
  b1:=FPicture.Bitmap;
  b2:=Img.FPicture.Bitmap;
  if b1.PixelFormat<>b2.PixelFormat then exit;
  ht1:=b1.Height;
  ht2:=b2.Height;
  wt:=b1.Width;
  case b1.PixelFormat of
    pf32bit:pf_width:=4;
    pf24bit:pf_width:=3;
    else raise Exception.Create('不支持的像素类型。');
  end;

  if back_match<0 then back_match:=0;
  back_count:=0;
  while back_count<=back_match do begin
    cursor1:=ht1-pixel_width*(back_count+1);
    cursor2:=0;
    if cursor1<0 then exit;
    while cursor2<ht2-pixel_width do begin
      if CompareMem(pbyte(b1.ScanLine[cursor1]),pbyte(b2.ScanLine[cursor2]),pf_width*wt) then begin
        base_pass:=true;
        cc1:=cursor1;
        cc2:=cursor2;
        repeat
          inc(cc1);
          inc(cc2);
          if cc2>=ht2 then base_pass:=false;
          if not CompareMem(pbyte(b1.ScanLine[cc1]),pbyte(b2.ScanLine[cc2]),pf_width*wt) then base_pass:=false;
        until (cc1>=ht1-1-back_count*pixel_width) or not base_pass;
        if base_pass then begin
          result:=cc2+1;
          exit
        end;
      end;
      inc(cursor2);
    end;
    inc(back_count);
  end;
end;
function TARImage.FindStart(Img:TARImage;pixel_width:integer):integer;
var bc:integer;
begin
  result:=FindStart(Img,pixel_width,0,bc);
end;

function TARImage.AddByLine(Img:TARImage;pixel_width:integer;back_match:integer=0):TARImage;
var start,wt,h1,h2:integer;
    back_count:integer;
    r_src,r_dst:TRect;
begin
  result:=nil;
  if (Img.Width<=0) or (Img.Height<=0) or (Width<=0) or (Height<=0) then exit;
  start:=FindStart(Img,pixel_width,back_match,back_count);
  if start<0 then exit;
  wt:=FPicture.Width;
  h1:=FPicture.Height;
  h2:=Img.FPicture.Height;
  if start>=h2 then exit;
  result:=TARImage.Create;
  try
    result.FPicture.Bitmap.SetSize(wt,h1+h2-start-back_count*pixel_width);
    r_src.Top:=0;
    r_src.Left:=0;
    r_src.Width:=wt;
    r_src.Height:=h1-back_count*pixel_width;
    r_dst.Top:=0;
    r_dst.Left:=0;
    r_dst.Width:=wt;
    r_dst.Height:=h1-back_count*pixel_width;
    result.FPicture.Bitmap.Canvas.CopyRect(r_dst,FPicture.Bitmap.Canvas,r_src);
    r_src.Top:=start;
    r_src.Left:=0;
    r_src.Width:=wt;
    r_src.Height:=h2-start;
    r_dst.Top:=h1-back_count*pixel_width;
    r_dst.Left:=0;
    r_dst.Width:=wt;
    r_dst.Height:=h2-start;
    result.FPicture.Bitmap.Canvas.CopyRect(r_dst,Img.FPicture.Bitmap.Canvas,r_src);
  except
    result.Free;
    result:=nil;
  end;
end;

function TARImage.FindVoid(min_height,tolerance:integer):integer;
var line,max_line,max_row,row:integer;
    diff:int64;
    color:byte;
    ptr:pbyte;
begin
  result:=-1;
  if (FPicture.Height<=0) or (FPicture.Width<=0) then exit;
  color:=FPicture.Bitmap.RawImage.DataSize div FPicture.Height div FPicture.Width;
  max_line:=FPicture.Height;
  max_row:=FPicture.Width;
  line:=min_height;
  while line<max_line do begin
    ptr:=pbyte(FPicture.Bitmap.ScanLine[line]);//+max_row*color*line;
    diff:=0;
    for row:=0 to (max_row-1)*color-1 do begin
      inc(diff,abs((ptr+row)^-(ptr+row+color)^));
      //writeln('value1 = ',(ptr+row)^,#9,'value2 = ',(ptr+row+color)^,#9,'diff = ',diff);
      if diff>tolerance then break;
    end;
    result:=line;
    if diff<=tolerance then exit;
    inc(line);
  end;
  result:=-1;
end;

function TARImage.VoidSegmentByLine(out ImgRest:TARImage;min,tor:integer):TARImage;
var split_line:integer;
begin
  result:=nil;
  ImgRest:=nil;
  if (min<=0) or (tor<0) then exit;
  split_line:=FindVoid(min,tor);
  if split_line<min then exit;
  ImgRest:=Clip(Classes.Rect(0,split_line,FPicture.Width,FPicture.Height));
  result:=Clip(Classes.Rect(0,0,FPicture.Width,split_line-1));
end;

function TARImage.SubImageRect(Img:TARImage):TRect;
begin

end;

procedure TARImage.CombineWith(Img:TARImage;ARect:TRect);
begin

end;

class function TARImage.ImageCount:Integer;
begin
  result:=ARImageList.Count;
end;

class function TARImage.ClearImageList:boolean;
begin
  result:=false;
  while ARImageList.Count>0 do
    TARImage(ARImageList.Items[0]).Free;
  result:=true;
end;

procedure TARImage.Clear;
begin
  FPicture.Clear;
end;

procedure TARImage.LoadFromStream(AStream:TStream);
begin
  FPicture.LoadFromStream(AStream);
end;

procedure TARImage.SaveToStream(AStream:TStream);
begin
  FPicture.SaveToStream(AStream);
end;
procedure TARImage.LoadFromFile(filename:string);
begin
  FPicture.LoadFromFile(filename);
end;
procedure TARImage.SaveToFile(filename:string);
begin
  FPicture.SaveToFile(filename);
end;

initialization
  ARImageList:=TList.Create;


finalization
  ARImageList.Free;


end.

