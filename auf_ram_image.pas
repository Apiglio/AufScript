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
    //Clip
    function Clip(ARect:TRect):TARImage;

    //AddByLine
    function SameWidth(Img:TARImage):boolean;
    function FindStart(Img:TARImage;pixel_width:integer;back_match:integer;var back_count:integer):integer;
    function FindStart(Img:TARImage;pixel_width:integer):integer;
    function AddByLine(Img:TARImage;pixel_width:integer;back_match:integer=0):TARImage;


  public
    procedure Clear;
    procedure LoadFromStream(AStream:TStream);
    procedure SaveToStream(AStream:TStream);
    procedure LoadFromFile(filename:string);
    procedure SaveToFile(filename:string);

  public
    constructor Create;
    destructor Destroy; override;
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

function TARImage.Width:integer;
begin
  result:=FPicture.Width;
end;

function TARImage.Height:integer;
begin
  result:=FPicture.Height;
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
begin
  result:=-1;
  if not SameWidth(Img) then exit;
  b1:=FPicture.Bitmap;
  b2:=Img.FPicture.Bitmap;
  ht1:=b1.Height;
  ht2:=b2.Height;
  wt:=b1.Width;

  if back_match<0 then back_match:=0;
  back_count:=0;
  while back_count<=back_match do begin
    cursor1:=ht1-pixel_width*(back_count+1);
    cursor2:=0;
    if cursor1<0 then exit;
    while cursor2<ht2-pixel_width do begin
      if CompareMem(pdword(b1.ScanLine[cursor1]),pdword(b2.ScanLine[cursor2]),wt) then begin
        base_pass:=true;
        cc1:=cursor1;
        cc2:=cursor2;
        repeat
          inc(cc1);
          inc(cc2);
          if cc2>=ht2 then base_pass:=false;
          if not CompareMem(pdword(b1.ScanLine[cc1]),pdword(b2.ScanLine[cc2]),wt) then base_pass:=false;
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

