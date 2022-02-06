unit aufscript_frame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, StdCtrls, Buttons, ComCtrls,
  Dialogs, ExtCtrls, Windows, LazUTF8, SynEdit, Apiglio_Useful;

const
  ARF_CommonGap      = 6;
  ARF_MemoProportion = 0.85;
  ARF_TrackBarHeight = 24;
  ARF_ButtonHeight   = 24;
  ARF_ProcessBarH    = 12;

type

  { TFrame_AufScript }

  TFrame_AufScript = class(TFrame)
    Button_run: TButton;
    Button_pause: TButton;
    Button_stop: TButton;
    Button_ScriptLoad: TButton;
    Button_ScriptSave: TButton;
    Memo_cmd: TSynEdit;
    Memo_out: TMemo;
    OpenDialog: TOpenDialog;
    ProgressBar: TProgressBar;
    SaveDialog: TSaveDialog;
    TrackBar: TTrackBar;
    procedure Button_pauseClick(Sender: TObject);
    procedure Button_runClick(Sender: TObject);
    procedure Button_stopClick(Sender: TObject);

    procedure Button_ScriptLoadClick(Sender: TObject);
    procedure Button_ScriptSaveClick(Sender: TObject);
    procedure Memo_cmdKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TrackBarChange(Sender: TObject);

  private
    ProgressBarEnabled:boolean;
    CommonGap:word;
    MemoProportion:single;
    TrackBarHeight:word;
    ButtonHeight:word;
    ProcessBarH:word;
  public
    Auf:TAuf;
  public
    procedure FrameResize(Sender: TObject);
    procedure AufGenerator;

  end;

implementation
{$R *.lfm}

{ default GUI Func }
procedure frm_command_decoder(var str:string);
begin
  str:={utf8towincp}(str);
  //str:=StringReplace(str,'\s',' ',[rfReplaceAll]);

end;
procedure frm_renew_pre(Sender:TObject);
var Frame:TFrame_AufScript;
begin
  Frame:=(Sender as TAufScript).Owner as TFrame_AufScript;
  if Frame.ProgressBarEnabled then Frame.ProgressBar.Position:=Frame.Auf.Script.currentline;
  Application.ProcessMessages
end;
procedure frm_renew_post(Sender:TObject);
begin
  Application.ProcessMessages
end;
procedure frm_renew_mid(Sender:TObject);
begin
  Application.ProcessMessages
end;
procedure frm_renew_beginning(Sender:TObject);
var Frame:TFrame_AufScript;
begin
  Frame:=(Sender as TAufScript).Owner as TFrame_AufScript;
  Frame.Memo_out.Clear;
  Frame.Button_run.Enabled:=false;
  Frame.Button_stop.Enabled:=true;
  Frame.Button_pause.Enabled:=true;
  Frame.Memo_cmd.ReadOnly:=true;
  if Frame.ProgressBarEnabled then
    begin
      Frame.ProgressBar.Min:=0;
      Frame.ProgressBar.Max:=Frame.Auf.Script.PSW.run_parameter.current_strings.Count-1;
    end;
  Application.ProcessMessages;
end;
procedure frm_renew_ending(Sender:TObject);
var Frame:TFrame_AufScript;
begin
  Frame:=(Sender as TAufScript).Owner as TFrame_AufScript;
  Frame.Button_run.Enabled:=true;
  Frame.Button_stop.Enabled:=false;
  Frame.Button_pause.Enabled:=false;
  Frame.Memo_cmd.ReadOnly:=false;
  Frame.Button_pause.Caption:='暂停';
  Application.ProcessMessages;
end;
procedure frm_renew_onPause(Sender:TObject);
var Frame:TFrame_AufScript;
begin
  Frame:=(Sender as TAufScript).Owner as TFrame_AufScript;
  Frame.Button_pause.Caption:='继续';
  Application.ProcessMessages;
end;
procedure frm_renew_onResume(Sender:TObject);
var Frame:TFrame_AufScript;
begin
  Frame:=(Sender as TAufScript).Owner as TFrame_AufScript;
  Frame.Button_pause.Caption:='暂停';
  Application.ProcessMessages;
end;
procedure frm_renew_writeln(Sender:TObject;str:string);
var Frame:TFrame_AufScript;
begin
  Frame:=(Sender as TAufScript).Owner as TFrame_AufScript;
  Frame.Memo_out.lines[Frame.Memo_out.Lines.Count-1]:=
  Frame.Memo_out.lines[Frame.Memo_out.Lines.Count-1]+
  {wincptoutf8}(str);
  Frame.Memo_out.lines.add({wincptoutf8}(''));
  Application.ProcessMessages;
end;
procedure frm_renew_write(Sender:TObject;str:string);
var Frame:TFrame_AufScript;
begin
  Frame:=(Sender as TAufScript).Owner as TFrame_AufScript;
  Frame.Memo_out.lines[Frame.Memo_out.Lines.Count-1]:=
  Frame.Memo_out.lines[Frame.Memo_out.Lines.Count-1]+
  {wincptoutf8}(str);
  Application.ProcessMessages;
end;
procedure frm_renew_readln(Sender:TObject);
var Frame:TFrame_AufScript;
begin
  Frame:=(Sender as TAufScript).Owner as TFrame_AufScript;
  (Sender as TAufScript).Pause;
  Application.ProcessMessages;
end;


{ TFrame_AufScript }

procedure TFrame_AufScript.FrameResize(Sender: TObject);
var Memo_Left,Memo_Right:word;
    ButtonTop:word;
    L2,R3:word;
begin
  //if (Self.Width<300) or (Self.Width>3000) or (Self.Height<200) or (Self.Height>2000) then exit;

  TrackBar.Top:=CommonGap;
  TrackBar.Left:=CommonGap;
  TrackBar.Width:=Self.Width - 2*CommonGap;
  TrackBar.Height:=TrackBarHeight;

  Memo_Left:=round(MemoProportion * (Self.Width - 3*CommonGap) / (MemoProportion + 1));
  Memo_Right:=Self.Width - Memo_Left - 3*CommonGap;

  Memo_cmd.Left:=CommonGap;
  Memo_out.Left:=CommonGap*2 + Memo_Left;
  Memo_cmd.Top:=2*CommonGap+TrackBarHeight;
  Memo_out.Top:=Memo_cmd.Top;
  Memo_cmd.Width:=Memo_Left;
  Memo_out.Width:=Memo_Right;
  Memo_cmd.Height:=Self.Height - 5*CommonGap - ButtonHeight - ProcessBarH - TrackBarHeight;
  Memo_out.Height:=Memo_cmd.Height;

  ButtonTop:=CommonGap*3+Memo_cmd.Height+TrackBarHeight;
  Button_Run.Top:=ButtonTop;
  Button_Stop.Top:=ButtonTop;
  Button_Pause.Top:=ButtonTop;
  Button_ScriptLoad.Top:=ButtonTop;
  Button_ScriptSave.Top:=ButtonTop;
  Button_Run.Height:=ButtonHeight;
  Button_Stop.Height:=ButtonHeight;
  Button_Pause.Height:=ButtonHeight;
  Button_ScriptLoad.Height:=ButtonHeight;
  Button_ScriptSave.Height:=ButtonHeight;
  L2:=(Memo_Left - CommonGap) div 2;
  R3:=(Memo_Right - 2*CommonGap) div 3;
  Button_Run.Width:=R3;
  Button_Stop.Width:=R3;
  Button_Pause.Width:=R3;
  Button_ScriptLoad.Width:=L2;
  Button_ScriptSave.Width:=L2;
  Button_Run.Left:=Memo_Left+2*CommonGap;
  Button_Stop.Left:=Memo_Left+3*CommonGap+R3;
  Button_Pause.Left:=Memo_Left+4*CommonGap+2*R3;
  Button_ScriptLoad.Left:=CommonGap;
  Button_ScriptSave.Left:=CommonGap*2 + L2;

  Button_Stop.Enabled:=false;
  Button_Pause.Enabled:=false;

  ProgressBar.Left:=CommonGap;
  ProgressBar.Width:=Self.Width - 2*CommonGap;
  ProgressBar.Top:=ButtonTop + ButtonHeight +CommonGap;
  ProgressBar.Height:=ProcessBarH;
end;

procedure TFrame_AufScript.Button_ScriptLoadClick(Sender: TObject);
begin
  OpenDialog.Title:='载入脚本';
  OpenDialog.InitialDir:=ExtractFilePath(Application.ExeName);
  OpenDialog.Filter:='AufScript File(*.auf)|*.auf|TableCalc Script File(*.scpt)|*.scpt|文本文档(*.txt)|*.txt|全部文件(*.*)|*.*';
  OpenDialog.DefaultExt:='*.auf';
  if OpenDialog.Execute then
    try
      Memo_cmd.Lines.LoadFromFile(OpenDialog.FileName);
    except
      MessageBox(0,Usf.ExPChar(utf8towincp('载入文件失败')),'Error',MB_OK);
    end;
end;

procedure TFrame_AufScript.Button_runClick(Sender: TObject);
begin
  Self.Auf.Script.command(Self.Memo_cmd.Lines);
end;

procedure TFrame_AufScript.Button_pauseClick(Sender: TObject);
var btn:TButton;
begin
  btn:=Sender as TButton;
  if btn.Caption='暂停' then begin
    //btn.Caption:='继续';//转移到OnPause中
    Self.Auf.Script.Pause;
  end else begin
    //btn.Caption:='暂停';//转移到OnResume中
    Self.Auf.Script.Resume;
  end;
end;

procedure TFrame_AufScript.Button_stopClick(Sender: TObject);
begin
  Self.Auf.Script.Stop;
end;

procedure TFrame_AufScript.Button_ScriptSaveClick(Sender: TObject);
begin
  SaveDialog.Title:='保存脚本';
  SaveDialog.InitialDir:=ExtractFilePath(Application.ExeName);
  SaveDialog.Filter:='AufScript File(*.auf)|*.auf|TableCalc Script File(*.scpt)|*.scpt|文本文档(*.txt)|*.txt|全部文件(*.*)|*.*';
  SaveDialog.DefaultExt:='*.auf';
  if SaveDialog.Execute then
    try
      Memo_cmd.Lines.SaveToFile(SaveDialog.FileName);
    except
      MessageBox(0,Usf.ExPChar(utf8towincp('保存文件失败')),'Error',MB_OK);
    end;
end;

procedure TFrame_AufScript.Memo_cmdKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key<>120) or (Shift<>[]) then exit;
  Self.Auf.Script.command(Self.Memo_cmd.Lines);
end;



procedure TFrame_AufScript.TrackBarChange(Sender: TObject);
var tmp:single;
begin
  tmp:=((Sender as TTrackBar).Position);
  if tmp=100 then tmp:=99;
  tmp:=tmp/(100-tmp);
  if tmp<0.2 then
    Self.MemoProportion:=0.2
  else if tmp>4 then
    Self.MemoProportion:=4
  else
    Self.MemoProportion:=tmp;
  Self.FrameResize(nil);
end;

procedure TFrame_AufScript.AufGenerator;
var tmp:single;
begin
  Self.Auf:=TAuf.Create(Self);
  Self.Auf.Script.InternalFuncDefine;
  Self.Auf.Script.IO_fptr.command_decode:=@frm_command_decoder;
  Self.Auf.Script.IO_fptr.echo:=@frm_renew_writeln;
  Self.Auf.Script.IO_fptr.print:=@frm_renew_write;
  Self.Auf.Script.IO_fptr.pause:=@frm_renew_readln;
  Self.Auf.Script.IO_fptr.error:=@frm_renew_writeln;
  Self.Auf.Script.Func_process.beginning:=@frm_renew_beginning;
  Self.Auf.Script.Func_process.ending:=@frm_renew_ending;
  Self.Auf.Script.Func_process.OnPause:=@frm_renew_onPause;
  Self.Auf.Script.Func_process.OnResume:=@frm_renew_onResume;
  Self.Auf.Script.Func_process.pre:=@frm_renew_pre;
  Self.Auf.Script.Func_process.mid:=@frm_renew_mid;
  Self.Auf.Script.Func_process.post:=@frm_renew_post;

  Self.ProgressBarEnabled:=true;
  Self.CommonGap:=ARF_CommonGap;
  Self.MemoProportion:=ARF_MemoProportion;
  Self.TrackBarHeight:=ARF_TrackBarHeight;
  Self.ButtonHeight:=ARF_ButtonHeight;
  Self.ProcessBarH:=ARF_ProcessBarH;
  tmp:=Self.MemoProportion;
  Self.TrackBar.Position:=round(100*(1-tmp/(1+tmp)));

end;

end.

