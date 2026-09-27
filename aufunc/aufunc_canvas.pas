unit aufunc_canvas;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics,
  Apiglio_Useful, auf_ram_var, aufscript_canvas, auf_type_error;

procedure cav_Refresh(Sender:TObject);
procedure cav_Clear(Sender:TObject);
procedure cav_ScreenShot(Sender:TObject);
procedure cav_AddLine(Sender:TObject);
procedure cav_AddRect(Sender:TObject);
procedure cav_AddOval(Sender:TObject);
procedure cav_AddPoint(Sender:TObject);
procedure cav_AddText(Sender:TObject);
procedure cav_GenGrid(Sender:TObject);
procedure cav_GenDotArray(Sender:TObject);
procedure cav_AddImage(Sender:TObject);
procedure cav_ShapesList(Sender:TObject);
procedure cav_ToTop(Sender:TObject);
procedure cav_ToBottom(Sender:TObject);
procedure cav_MoveBy(Sender:TObject);
procedure cav_MoveTo(Sender:TObject);
procedure cav_SetStyle(Sender:TObject);
procedure cav_GetStyle(Sender:TObject);
procedure cav_SetTemplateStyle(Sender:TObject);

implementation

procedure cav_Refresh(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckCanvas then exit;
  AufScpt.IO_fptr.canvas.Refresh;
end;

procedure cav_Clear(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckCanvas then exit;
  AufScpt.IO_fptr.canvas.Shapes.Clear;
end;

procedure cav_ScreenShot(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    filename:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckCanvas then exit;
  if AAuf.ArgsCount>1 then begin
    if not AAuf.TryArgToString(1, filename) then exit;
    try
      AufScpt.IO_fptr.canvas.Shapes.SaveToSVG(filename);
    except
      on e:Exception do
        AufScpt.send_error('警告：导出SVG图像时发生错误，'+e.Message, AufsErr_FileIOFailed);
    end;
  end else begin
    AufScpt.writeln(AufScpt.IO_fptr.canvas.Shapes.AsSVG);
  end;
end;


procedure cav_AddLine(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    x0,x1,y0,y1,shp_id:integer;
    shp_id_arv:TAufRamVar;
    tmpShape:TAufShape;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckCanvas then exit;
  if not AAuf.CheckArgs(6) then exit;
  if not AAuf.TryArgToARV(1, 4, High(DWord), [ARV_FixNum], shp_id_arv) then exit;
  if not AAuf.TryArgToLong(2, x0) then exit;
  if not AAuf.TryArgToLong(3, y0) then exit;
  if not AAuf.TryArgToLong(4, x1) then exit;
  if not AAuf.TryArgToLong(5, y1) then exit;
  tmpShape:=TAufPolyline.CreateByRect(Classes.Rect(x0,y0,x1,y1));
  shp_id:=AufScpt.IO_fptr.canvas.Shapes.AddShape(tmpShape);
  dword_to_arv(shp_id, shp_id_arv);
end;

procedure cav_AddRect(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    x0,x1,y0,y1,shp_id:integer;
    shp_id_arv:TAufRamVar;
    tmpShape:TAufShape;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckCanvas then exit;
  if not AAuf.CheckArgs(6) then exit;
  if not AAuf.TryArgToARV(1, 4, High(DWord), [ARV_FixNum], shp_id_arv) then exit;
  if not AAuf.TryArgToLong(2, x0) then exit;
  if not AAuf.TryArgToLong(3, y0) then exit;
  if not AAuf.TryArgToLong(4, x1) then exit;
  if not AAuf.TryArgToLong(5, y1) then exit;
  tmpShape:=TAufPolygon.CreateByRect(Classes.Rect(x0,y0,x1,y1));
  shp_id:=AufScpt.IO_fptr.canvas.Shapes.AddShape(tmpShape);
  dword_to_arv(shp_id, shp_id_arv);
end;

procedure cav_AddOval(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    x0,x1,y0,y1,shp_id:integer;
    shp_id_arv:TAufRamVar;
    tmpShape:TAufShape;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckCanvas then exit;
  if not AAuf.CheckArgs(6) then exit;
  if not AAuf.TryArgToARV(1, 4, High(DWord), [ARV_FixNum], shp_id_arv) then exit;
  if not AAuf.TryArgToLong(2, x0) then exit;
  if not AAuf.TryArgToLong(3, y0) then exit;
  if not AAuf.TryArgToLong(4, x1) then exit;
  if not AAuf.TryArgToLong(5, y1) then exit;
  tmpShape:=TAufEllipse.CreateByRect(Classes.Rect(x0,y0,x1,y1));
  shp_id:=AufScpt.IO_fptr.canvas.Shapes.AddShape(tmpShape);
  dword_to_arv(shp_id, shp_id_arv);
end;

procedure cav_AddPoint(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    x,y,scale,shp_id:integer;
    shp_id_arv:TAufRamVar;
    tmpShape:TAufShape;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckCanvas then exit;
  if not AAuf.CheckArgs(5) then exit;
  if not AAuf.TryArgToARV(1, 4, High(DWord), [ARV_FixNum], shp_id_arv) then exit;
  if not AAuf.TryArgToLong(2, x) then exit;
  if not AAuf.TryArgToLong(3, y) then exit;
  if not AAuf.TryArgToLong(4, scale) then exit;
  tmpShape:=TAufEllipse.CreateByRect(Classes.Rect(x-scale,y-scale,x+scale,y+scale));
  shp_id:=AufScpt.IO_fptr.canvas.Shapes.AddShape(tmpShape);
  dword_to_arv(shp_id, shp_id_arv);
end;

procedure cav_AddText(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    x,y,font_size,max_width,shp_id,fx,fy:integer;
    caption_text:string;
    shp_id_arv:TAufRamVar;
    tmpShape:TAufShape;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckCanvas then exit;
  if not AAuf.CheckArgs(6) then exit;
  if not AAuf.TryArgToARV(1, 4, High(DWord), [ARV_FixNum], shp_id_arv) then exit;
  if not AAuf.TryArgToLong(2, x) then exit;
  if not AAuf.TryArgToLong(3, y) then exit;
  if not AAuf.TryArgToString(4, caption_text) then exit;
  if not AAuf.TryArgToLong(5, font_size) then exit;
  if AAuf.ArgsCount>6 then begin
    if not AAuf.TryArgToLong(6, max_width) then exit;
    fx:=x - max_width div 2;
    fy:=y - font_size div 2;
    tmpShape:=TAufCaption.CreateByRect(Classes.Rect(fx, fy, fx+max_width, fy+font_size));
    TAufCaption(tmpShape).Caption:=caption_text;
  end else begin
    tmpShape:=TAufCaption.Create(Classes.Point(x,y),caption_text,font_size);
  end;
  shp_id:=AufScpt.IO_fptr.canvas.Shapes.AddShape(tmpShape);
  dword_to_arv(shp_id, shp_id_arv);
end;

procedure cav_GenGrid(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    x0, y0, x1, y1, cw, ch, row, col:integer;
    tmpShape:TAufShape;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckCanvas then exit;
  if not AAuf.CheckArgs(7) then exit;
  if not AAuf.TryArgToLong(1, x0) then exit;
  if not AAuf.TryArgToLong(2, y0) then exit;
  if not AAuf.TryArgToLong(3, x1) then exit;
  if not AAuf.TryArgToLong(4, y1) then exit;
  if not AAuf.TryArgToLong(5, cw) then exit;
  if not AAuf.TryArgToLong(6, ch) then exit;
  col:=x0;
  while col<=x1 do begin
    tmpShape:=TAufPolyline.CreateByRect(Classes.Rect(col, y0, col, y1));
    AufScpt.IO_fptr.canvas.Shapes.AddShape(tmpShape);
    inc(col, cw);
  end;
  row:=y0;
  while row<=y1 do begin
    tmpShape:=TAufPolyline.CreateByRect(Classes.Rect(x0, row, x1, row));
    AufScpt.IO_fptr.canvas.Shapes.AddShape(tmpShape);
    inc(row, ch);
  end;
end;

procedure cav_GenDotArray(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    x0, y0, x1, y1, cw, ch, row, col:integer;
    tmpShape:TAufShape;
    dot_size:dword;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckCanvas then exit;
  if not AAuf.CheckArgs(7) then exit;
  if not AAuf.TryArgToLong(1, x0) then exit;
  if not AAuf.TryArgToLong(2, y0) then exit;
  if not AAuf.TryArgToLong(3, x1) then exit;
  if not AAuf.TryArgToLong(4, y1) then exit;
  if not AAuf.TryArgToLong(5, cw) then exit;
  if not AAuf.TryArgToLong(6, ch) then exit;
  dot_size:=_DEFAULT_SHAPE_STYLE_.GetDWord(assSymbolWidth, assNormal);
  row:=y0;
  while row<=y1 do begin
    col:=x0;
    while col<=x1 do begin
      tmpShape:=TAufEllipse.CreateByRect(Classes.Rect(col-dot_size,row-dot_size,col+dot_size,row+dot_size));
      AufScpt.IO_fptr.canvas.Shapes.AddShape(tmpShape);
      inc(col, cw);
    end;
    inc(row, ch);
  end;
end;

procedure cav_AddImage(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    x,y,shp_id,pw,ph:integer;
    shp_id_arv:TAufRamVar;
    tmpShape:TAufShape;
    filename:string;
    pic:TPicture;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckCanvas then exit;
  if not AAuf.CheckArgs(5) then exit;
  if not AAuf.TryArgToARV(1, 4, High(DWord), [ARV_FixNum], shp_id_arv) then exit;
  if not AAuf.TryArgToString(2, filename) then exit;
  if not AAuf.TryArgToLong(3, x) then exit;
  if not AAuf.TryArgToLong(4, y) then exit;
  pw:=-1;
  ph:=-1;
  if AAuf.ArgsCount>5 then begin
    if not AAuf.CheckArgs(7) then exit;
    if not AAuf.TryArgToLong(5, pw) then exit;
    if not AAuf.TryArgToLong(6, ph) then exit;
    if (pw<0) or (ph<0) then begin
      AufScpt.send_error('警告：图形尺寸不应小于0，代码未执行。',AufsErr_RunTime);
      exit;
    end;
  end;
  if not FileExists(filename) then begin
    AufScpt.send_error('警告：找不到文件'+filename+'，代码未执行。', AufsErr_FileNotExists);
    exit;
  end;
  pic:=TPicture.Create;
  try
    try
      pic.LoadFromFile(filename);
      if pw<0 then pw:=pic.Width;
      if ph<0 then ph:=pic.Height;
      tmpShape:=TAufImageShape.Create(Classes.Rect(x,y,x+pw,y+ph), pic.Bitmap);
      shp_id:=AufScpt.IO_fptr.canvas.Shapes.AddShape(tmpShape);
      dword_to_arv(shp_id, shp_id_arv);
    except
      AufScpt.send_error('警告：无法打开文件'+filename+'，代码未执行。', AufsErr_FileIOFailed);
      exit;
    end;
  finally
    pic.Free;
  end;

end;

procedure cav_ShapesList(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  AufScpt.writeln(AufScpt.IO_fptr.canvas.Shapes.AsString);
end;

procedure cav_ToTop(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    shp_id:integer;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckCanvas then exit;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToLong(1, shp_id) then exit;
  AufScpt.IO_fptr.canvas.Shapes.BringToTop(shp_id);
end;

procedure cav_ToBottom(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    shp_id:integer;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckCanvas then exit;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToLong(1, shp_id) then exit;
  AufScpt.IO_fptr.canvas.Shapes.SendToBack(shp_id);
end;

procedure cav_MoveBy(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    shp_id,shp_idx:integer;
    xPos,yPos:integer;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckCanvas then exit;
  if not AAuf.CheckArgs(4) then exit;
  if not AAuf.TryArgToLong(1, shp_id) then exit;
  if not AAuf.TryArgToLong(2, xPos) then exit;
  if not AAuf.TryArgToLong(3, yPos) then exit;
  AufScpt.IO_fptr.canvas.Shapes.FindShapeByID(shp_id,shp_idx).Translation(Classes.Point(xPos,yPos));
end;

procedure cav_MoveTo(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    shp_id,shp_idx:integer;
    xPos,yPos:integer;
    tmpShape:TAufShape;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckCanvas then exit;
  if not AAuf.CheckArgs(4) then exit;
  if not AAuf.TryArgToLong(1, shp_id) then exit;
  if not AAuf.TryArgToLong(2, xPos) then exit;
  if not AAuf.TryArgToLong(3, yPos) then exit;
  tmpShape:=AufScpt.IO_fptr.canvas.Shapes.FindShapeByID(shp_id,shp_idx);
  tmpShape.Translation(Classes.Point(xPos,yPos)-tmpShape.VertexCentroid);
end;

procedure cav_SetStyle(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    shp_id,index:integer;
    style_name, state_name:string;
    value:int32;
    tmpShape:TAufShape;
    state:TShapeState;
    style:TShapeStyle;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckCanvas then exit;
  if not AAuf.CheckArgs(4) then exit;
  if not AAuf.TryArgToLong(1, shp_id) then exit;
  if not AAuf.TryArgToString(2, style_name) then exit;
  if not AAuf.TryArgToLong(3, value) then exit;
  tmpShape:=AufScpt.IO_fptr.canvas.Shapes.FindShapeByID(shp_id, index);
  if tmpShape=nil then begin
    AufScpt.send_error(Format('警告：未找到图形#%d。',[shp_id]), AufsErr_RunTime);
    exit;
  end;
  index:=pos(':', style_name);
  if index>0 then begin
    state_name:=style_name;
    delete(style_name, index, length(style_name));
    delete(state_name, 1, index);
  end else state_name:='';

  state_name:=lowercase(state_name);
  case state_name of
    'normal'  : state:=assNormal;
    'hover'   : state:=assHover;
    'active'  : state:=assActive;
    'selected': state:=assSelected;
    'disabled': state:=assDisabled;
    'dragging': state:=assDragging;
    else        state:=assAllState;
  end;

  style_name:=lowercase(style_name);
  case style_name of
    'fill-color':   style:=assFillColor;
    'border-color': style:=assBorderColor;
    'stroke-color': style:=assStrokeColor;
    'symbol-width': style:=assSymbolWidth;
    'border-width': style:=assBorderWidth;
    'stroke-width': style:=assStrokeWidth;
    'offset-x':     style:=assOffsetX;
    'offset-y':     style:=assOffsetY;
    else begin
      AufScpt.send_error('无效样式项目，代码未执行。',AufsErr_NoNamedParam);
      exit;
    end;
  end;
  tmpShape.Style.SetDWord(style, state, value);
end;

procedure cav_GetStyle(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    shp_id,index:integer;
    style_name, state_name:string;
    value:TAufRamVar;
    tmpShape:TAufShape;
    state:TShapeState;
    style:TShapeStyle;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckCanvas then exit;
  if not AAuf.CheckArgs(4) then exit;
  if not AAuf.TryArgToLong(1, shp_id) then exit;
  if not AAuf.TryArgToString(2, style_name) then exit;
  if not AAuf.TryArgToARV(3, 4, High(DWord), [ARV_FixNum], value) then exit;
  tmpShape:=AufScpt.IO_fptr.canvas.Shapes.FindShapeByID(shp_id, index);
  if tmpShape=nil then begin
    AufScpt.send_error(Format('警告：未找到图形#%d。',[shp_id]), AufsErr_RunTime);
    exit;
  end;
  index:=pos(':', style_name);
  if index>0 then begin
    state_name:=style_name;
    delete(style_name, index, length(style_name));
    delete(state_name, 1, index);
  end else state_name:='';

  state_name:=lowercase(state_name);
  case state_name of
    'normal'  : state:=assNormal;
    'hover'   : state:=assHover;
    'active'  : state:=assActive;
    'selected': state:=assSelected;
    'disabled': state:=assDisabled;
    'dragging': state:=assDragging;
    else        state:=assAllState;
  end;

  style_name:=lowercase(style_name);
  case style_name of
    'fill-color':   style:=assFillColor;
    'border-color': style:=assBorderColor;
    'stroke-color': style:=assStrokeColor;
    'symbol-width': style:=assSymbolWidth;
    'border-width': style:=assBorderWidth;
    'stroke-width': style:=assStrokeWidth;
    'offset-x':     style:=assOffsetX;
    'offset-y':     style:=assOffsetY;
    else begin
      AufScpt.send_error('无效样式项目，代码未执行。',AufsErr_NoNamedParam);
      exit;
    end;
  end;
  dword_to_arv(tmpShape.Style.GetDWord(style, state),value);
end;

procedure cav_SetTemplateStyle(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    index:integer;
    style_name, state_name:string;
    value:int32;
    tmpShape:TAufShape;
    state:TShapeState;
    style:TShapeStyle;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckCanvas then exit;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToString(1, style_name) then exit;
  if not AAuf.TryArgToLong(2, value) then exit;

  index:=pos(':', style_name);
  if index>0 then begin
    state_name:=style_name;
    delete(style_name, index, length(style_name));
    delete(state_name, 1, index);
  end else state_name:='';

  state_name:=lowercase(state_name);
  case state_name of
    'normal'  : state:=assNormal;
    'hover'   : state:=assHover;
    'active'  : state:=assActive;
    'selected': state:=assSelected;
    'disabled': state:=assDisabled;
    'dragging': state:=assDragging;
    else        state:=assAllState;
  end;

  style_name:=lowercase(style_name);
  case style_name of
    'fill-color':   style:=assFillColor;
    'border-color': style:=assBorderColor;
    'stroke-color': style:=assStrokeColor;
    'symbol-width': style:=assSymbolWidth;
    'border-width': style:=assBorderWidth;
    'stroke-width': style:=assStrokeWidth;
    'offset-x':     style:=assOffsetX;
    'offset-y':     style:=assOffsetY;
    else begin
      AufScpt.send_error('无效样式项目，代码未执行。',AufsErr_NoNamedParam);
      exit;
    end;
  end;
  _DEFAULT_SHAPE_STYLE_.SetDWord(style, state, value);
end;

end.

