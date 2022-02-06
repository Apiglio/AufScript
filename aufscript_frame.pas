unit aufscript_frame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, StdCtrls, Buttons, ComCtrls,
  Dialogs, ExtCtrls, Windows, LazUTF8, SynEdit, Apiglio_Useful, SynHighlighterAuf;

const
  ARF_CommonGap      = 6;
  ARF_MemoProportion = 0.85;
  ARF_TrackBarHeight = 24;
  ARF_ButtonHeight   = 24;
  ARF_ProcessBarH    = 12;

type

  { TFrame_AufScript }
  TNotifyStringEvent = procedure(sender:TObject;str:string) of Object;
  ptrFuncStr         = procedure(str:string) of Object;
  TFrame_AufScript   = class(TFrame)
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
    procedure Button_pauseMouseEnter(Sender: TObject);
    procedure Button_pauseMouseLeave(Sender: TObject);
    procedure Button_runClick(Sender: TObject);
    procedure Button_ScriptLoadMouseEnter(Sender: TObject);
    procedure Button_ScriptLoadMouseLeave(Sender: TObject);
    procedure Button_ScriptSaveMouseEnter(Sender: TObject);
    procedure Button_ScriptSaveMouseLeave(Sender: TObject);
    procedure Button_stopMouseEnter(Sender: TObject);
    procedure Button_stopMouseLeave(Sender: TObject);
    procedure InstantHelper(str:string);inline;
    procedure Button_runMouseEnter(Sender: TObject);
    procedure Button_runMouseLeave(Sender: TObject);
    procedure Button_stopClick(Sender: TObject);

    procedure Button_ScriptLoadClick(Sender: TObject);
    procedure Button_ScriptSaveClick(Sender: TObject);
    procedure Memo_cmdKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Memo_cmdMouseEnter(Sender: TObject);
    procedure Memo_cmdMouseLeave(Sender: TObject);
    procedure Memo_outMouseEnter(Sender: TObject);
    procedure Memo_outMouseLeave(Sender: TObject);
    procedure ProgressBarMouseEnter(Sender: TObject);
    procedure ProgressBarMouseLeave(Sender: TObject);
    procedure TrackBarChange(Sender: TObject);
    procedure TrackBarMouseEnter(Sender: TObject);
    procedure TrackBarMouseLeave(Sender: TObject);
  protected
    FOnChangeTitle:TNotifyStringEvent;
  public
    property OnChangeTitle:TNotifyStringEvent read FOnChangeTitle write FOnChangeTitle;

  private
    ProgressBarEnabled:boolean;
    ProgressBarMaxString:string;//用于节约进度条文字提示的计算时间。
    CommonGap:word;
    MemoProportion:single;
    TrackBarHeight:word;
    ButtonHeight:word;
    ProcessBarH:word;
  public
    Auf:TAuf;
    onHelper:ptrFuncStr;
    //SynAufSyn:TSynAufSyn;
  public
    procedure FrameResize(Sender: TObject);
    procedure AufGenerator;
    procedure HighLighterReNew;
  end;

implementation
{$R *.lfm}

{ default GUI Func }
procedure frm_command_decoder(var str:string);
begin
  //str:=StringReplace(str,'\s',' ',[rfReplaceAll]);
end;
procedure frm_renew_pre(Sender:TObject);
var Frame:TFrame_AufScript;
begin
  Frame:=(Sender as TAufScript).Owner as TFrame_AufScript;
  if Frame.ProgressBarEnabled then
    begin
      Frame.ProgressBar.Position:=Frame.Auf.Script.currentline;
      Frame.ProgressBar.Hint:=IntToStr(Frame.ProgressBar.Position+1)+'/'+Frame.ProgressBarMaxString;
    end;
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
      Frame.ProgressBarMaxString:=IntToStr(Frame.ProgressBar.Max+1);
      Frame.ProgressBar.Hint:='0/'+Frame.ProgressBarMaxString;
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
  Frame.Memo_out.lines[Frame.Memo_out.Lines.Count-1]+str;
  Frame.Memo_out.lines.add('');
  Application.ProcessMessages;
end;
procedure frm_renew_write(Sender:TObject;str:string);
var Frame:TFrame_AufScript;
begin
  Frame:=(Sender as TAufScript).Owner as TFrame_AufScript;
  Frame.Memo_out.lines[Frame.Memo_out.Lines.Count-1]:=
  Frame.Memo_out.lines[Frame.Memo_out.Lines.Count-1]+str;
  Application.ProcessMessages;
end;
procedure frm_renew_readln(Sender:TObject);
var Frame:TFrame_AufScript;
begin
  Frame:=(Sender as TAufScript).Owner as TFrame_AufScript;
  (Sender as TAufScript).Pause;
  Application.ProcessMessages;
end;
procedure frm_renew_clearscreen(Sender:TObject);
var Frame:TFrame_AufScript;
begin
  Frame:=(Sender as TAufScript).Owner as TFrame_AufScript;
  Frame.Memo_out.Clear;
  Application.ProcessMessages;
end;


procedure FRM_FUNC_SETTING(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    AFrame:TFrame_AufScript;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not (AufScpt.Owner is TFrame_AufScript) then
    begin
      AufScpt.send_error('解释器与命令行编辑框关联错误，未成功设置！');
      exit
    end
  else AFrame:=AufScpt.Owner as TFrame_AufScript;
  if AAuf.ArgsCount<3 then
    begin
      AufScpt.send_error('命令行设置需要至少两个参数，未成功设置！');
      exit
    end;

  case lowercase(AAuf.args[1]) of
    'procbar':
      begin
        if AAuf.ArgsCount<4 then
          begin
            AufScpt.send_error('ProcBar需要三个参数，未成功设置！');
            exit
          end;
        try
          case lowercase(AAuf.args[2]) of
            'mode':
              begin
                case lowercase(AAuf.args[3]) of
                  'auto':begin AFrame.ProgressBarEnabled:=true;AufScpt.writeln('进度条显示与代码位置绑定。');end;
                  'manual':begin AFrame.ProgressBarEnabled:=false;AufScpt.writeln('进度条显示与代码位置解绑。');end;
                  else AufScpt.writeln('ProcBar Mode之后需要使用auto或manual进行设置。');
                end;
              end;
            'pos':
              begin
                AFrame.ProgressBar.Position:=AufScpt.TryToDWord(AAuf.nargs[3]);
              end;
            'max':
              begin
                AFrame.ProgressBar.Max:=AufScpt.TryToDWord(AAuf.nargs[3]);
                AFrame.ProgressBarMaxString:=IntToStr(AFrame.ProgressBar.Max);
              end;
            else AufScpt.writeln('ProcBar之后需要使用mode, pos或max进行设置。');
          end;
        finally
          AFrame.ProgressBar.Hint:=IntToStr(AFrame.ProgressBar.Position)+'/'+AFrame.ProgressBarMaxString;
        end;
      end;
    'wrap':
      begin
        case lowercase(AAuf.args[2]) of
          'on':begin AFrame.Memo_out.WordWrap:=true;AufScpt.writeln('输出窗口自动换行开启。');end;
          'off':begin AFrame.Memo_out.WordWrap:=false;AufScpt.writeln('输出窗口自动换行关闭。');end;
          else AufScpt.writeln('Wrap之后需要使用on或off进行设置。');
        end;
      end;
    else begin
      //AufScpt.send_error('未知的命令行设置项，未成功设置！')
      if AufScpt.Func_process.Setting<>nil then AufScpt.Func_process.Setting(AufScpt);
    end;
  end;
end;


{ TFrame_AufScript }

procedure TFrame_AufScript.FrameResize(Sender: TObject);
var Memo_Left,Memo_Right:word;
    ButtonTop:word;
    L2,R3:word;
begin

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
      if FOnChangeTitle<>nil then FOnChangeTitle(Self,ExtractFilename(OpenDialog.FileName));
    except
      MessageBox(0,Usf.ExPChar(utf8towincp('载入文件失败')),'Error',MB_OK);
    end;
end;

procedure TFrame_AufScript.Button_runClick(Sender: TObject);
begin
  Self.Auf.Script.command(Self.Memo_cmd.Lines);
end;

procedure TFrame_AufScript.Button_ScriptLoadMouseEnter(Sender: TObject);
begin
  InstantHelper('从文件读取脚本到代码窗口。');
end;

procedure TFrame_AufScript.Button_ScriptLoadMouseLeave(Sender: TObject);
begin
  InstantHelper('');
end;

procedure TFrame_AufScript.Button_ScriptSaveMouseEnter(Sender: TObject);
begin
  InstantHelper('保存代码窗口的脚本到文件。');
end;

procedure TFrame_AufScript.Button_ScriptSaveMouseLeave(Sender: TObject);
begin
  InstantHelper('');
end;

procedure TFrame_AufScript.Button_stopMouseEnter(Sender: TObject);
begin
  InstantHelper('单击以中止正在运行的脚本。');
end;

procedure TFrame_AufScript.Button_stopMouseLeave(Sender: TObject);
begin
  InstantHelper('');
end;

procedure TFrame_AufScript.InstantHelper(str:string);
begin
  if Self.onHelper <> nil then Self.onHelper(str);
end;

procedure TFrame_AufScript.Button_runMouseEnter(Sender: TObject);
begin
  InstantHelper('单击以运行代码窗口的脚本。');
end;

procedure TFrame_AufScript.Button_runMouseLeave(Sender: TObject);
begin
  InstantHelper('');
end;

procedure TFrame_AufScript.Button_pauseClick(Sender: TObject);
var btn:TButton;
begin
  btn:=Sender as TButton;
  if btn.Caption='暂停' then begin
    Self.Auf.Script.Pause;
  end else begin
    Self.Auf.Script.Resume;
  end;
end;

procedure TFrame_AufScript.Button_pauseMouseEnter(Sender: TObject);
var Butt:TButton;
begin
  Butt:=Sender as TButton;
  if butt.Caption='暂停' then InstantHelper('单击以暂停正在执行的脚本。')
  else InstantHelper('单击以恢复已暂停的脚本运行。');
end;

procedure TFrame_AufScript.Button_pauseMouseLeave(Sender: TObject);
begin
  InstantHelper('');
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
      if FOnChangeTitle<>nil then FOnChangeTitle(Self,ExtractFilename(SaveDialog.FileName));
    except
      MessageBox(0,Usf.ExPChar(utf8towincp('保存文件失败')),'Error',MB_OK);
    end;
end;

procedure TFrame_AufScript.Memo_cmdKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  //if (Key<>120) or (Shift<>[]) then exit;
  if Shift=[] then
    begin
      case Key of
        120:Self.Auf.Script.command(Self.Memo_cmd.Lines);
        else ;
      end;
    end
  else if Shift*[ssCtrl,ssAlt,ssShift]=[ssCtrl] then
    begin
      case Key of
        ord('S'):Self.Button_ScriptSaveClick(Self.Button_ScriptSave);
        ord('O'):Self.Button_ScriptLoadClick(Self.Button_ScriptLoad);
        else ;
      end;
    end
  else ;
end;

procedure TFrame_AufScript.Memo_cmdMouseEnter(Sender: TObject);
begin
  InstantHelper('代码窗口。在此编写AufScript脚本，输入help后执行查看帮助。');
end;

procedure TFrame_AufScript.Memo_cmdMouseLeave(Sender: TObject);
begin
  InstantHelper('');
end;

procedure TFrame_AufScript.Memo_outMouseEnter(Sender: TObject);
begin
  InstantHelper('输出窗口。显示脚本执行过程中的某些状态。');
end;

procedure TFrame_AufScript.Memo_outMouseLeave(Sender: TObject);
begin
  InstantHelper('');
end;

procedure TFrame_AufScript.ProgressBarMouseEnter(Sender: TObject);
begin
  InstantHelper('进度条，默认显示当前脚本执行行数。通过SET ProcBar指令可以自定义显示。');
end;

procedure TFrame_AufScript.ProgressBarMouseLeave(Sender: TObject);
begin
  InstantHelper('');
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

procedure TFrame_AufScript.TrackBarMouseEnter(Sender: TObject);
begin
  InstantHelper('左右拖动游标调整代码窗口与输出窗口的占比。');
end;

procedure TFrame_AufScript.TrackBarMouseLeave(Sender: TObject);
begin
  InstantHelper('');
end;

procedure TFrame_AufScript.HighLighterReNew;
var pi:word;
begin
  pi:=0;
  while Self.Auf.Script.Func[pi].name<>'' do
    begin
      with Self.Memo_cmd.Highlighter as TSynAufSyn do
        begin
          InternalFunc:=InternalFunc+Self.Auf.Script.Func[pi].name+',';
        end;
      inc(pi);
    end;
end;

procedure TFrame_AufScript.AufGenerator;
var tmp:single;
begin
  Self.Auf:=TAuf.Create(Self);
  Self.Auf.Script.add_func('set',@FRM_FUNC_SETTING,'option,value','代码窗运行设置');
  Self.Auf.Script.InternalFuncDefine;
  Self.Auf.Script.IO_fptr.command_decode:=@frm_command_decoder;
  Self.Auf.Script.IO_fptr.echo:=@frm_renew_writeln;
  Self.Auf.Script.IO_fptr.print:=@frm_renew_write;
  Self.Auf.Script.IO_fptr.pause:=@frm_renew_readln;
  Self.Auf.Script.IO_fptr.clear:=@frm_renew_clearscreen;
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

  //Self.SynAufSyn:=TSynAufSyn.Create(Self);
  Self.Memo_cmd.Highlighter:=Self.Auf.Script.SynAufSyn;

  Button_Stop.Enabled:=false;
  Button_Pause.Enabled:=false;

  //Self.HighLighterReNew;

  //FOnChangeTitle:=nil;

end;

end.

