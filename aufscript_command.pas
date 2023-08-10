unit aufscript_command;

{$mode objfpc}{$H+}

interface

uses
  {$ifdef UNIX}
  cthreads,
  {$endif}
  {$ifdef WINDOWS}
  Windows,
  {$endif}
  Classes, SysUtils, FileUtil, Forms, Controls, StdCtrls,
  Dialogs, LazUTF8, Apiglio_Useful;

type
  TMemo_AufScript = class(TMemo)
  public
    Auf:TAuf;
    SubCmd:TStrings;//用于截取最新一部分的代码
    inPause:boolean;//是否暂停，若为是，则OnEnter触发AufScpt.Resume，而不是AufScpt.command
  private
    AutoPauseState:boolean;
  public
    AutoClear:boolean;//执行完成后是否自动清屏
    AutoPause:boolean;//执行完成后是否默认等待

  public
    constructor Create(AOwner:TComponent);
    //procedure MemoCreate(Sender:TObject);
    //procedure MemoRun(Sender: TObject; var Key: char);
    procedure MemoKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure RunScript;


  end;

implementation

const
  CMD_BREAKPOINT_STR='//AufScript脚本结束执行……';

procedure cmd_command_decoder(var str:string);
begin
  //str:={utf8towincp}(str);
end;
procedure cmd_renew_pre(Sender:TObject);
begin
  Application.ProcessMessages
end;
procedure cmd_renew_post(Sender:TObject);
begin
  Application.ProcessMessages
end;
procedure cmd_renew_mid(Sender:TObject);
begin
  //Application.ProcessMessages
end;
procedure cmd_renew_beginning(Sender:TObject);
var Memo:TMemo_AufScript;
    Scpt:TAufScript;
begin
  Scpt:=Sender as TAufScript;
  Memo:=Scpt.Owner as TMemo_AufScript;
  Memo.ReadOnly:=true;
  Memo.lines.add('');
  Application.ProcessMessages;
end;
procedure cmd_renew_ending(Sender:TObject);
var Memo:TMemo_AufScript;
begin
  Memo:=(Sender as TAufScript).Owner as TMemo_AufScript;
  Memo.ReadOnly:=false;
  Application.ProcessMessages;
  Memo.SubCmd.Clear;
  if Memo.AutoPause then
    begin
      Memo.Lines.Append('按任意键继续……');
      Memo.AutoPauseState:=true;
      while Memo.AutoPauseState do Application.ProcessMessages;
    end;
  Memo.Lines.Append(CMD_BREAKPOINT_STR);//添加人工的新断点，再次运行将从新断点开始
  if Memo.AutoClear then Memo.Lines.Clear;
end;
procedure cmd_renew_onPause(Sender:TObject);
var Memo:TMemo_AufScript;
begin
  Memo:=(Sender as TAufScript).Owner as TMemo_AufScript;
  Memo.inPause:=true;
  //Application.ProcessMessages;
end;
procedure cmd_renew_onResume(Sender:TObject);
var Memo:TMemo_AufScript;
begin
  Memo:=(Sender as TAufScript).Owner as TMemo_AufScript;
  Memo.inPause:=false;
  //Application.ProcessMessages;
end;
procedure cmd_renew_writeln(Sender:TObject;str:string);
var str_list:TStrings;
    AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  if AufScpt.PSW.print_mode.is_screen then str_list:=(AufScpt.Owner as TMemo_AufScript).Lines
  else str_list:=AufScpt.PSW.print_mode.str_list;
  str_list[str_list.Count-1]:=
  str_list[str_list.Count-1]+str;
  str_list.add('');
  if AufScpt.PSW.print_mode.is_screen then Application.ProcessMessages;
end;
procedure cmd_renew_write(Sender:TObject;str:string);
var str_list:TStrings;
    AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  if AufScpt.PSW.print_mode.is_screen then str_list:=(AufScpt.Owner as TMemo_AufScript).Lines
  else str_list:=AufScpt.PSW.print_mode.str_list;
  str_list[str_list.Count-1]:=
  str_list[str_list.Count-1]+str;
  if AufScpt.PSW.print_mode.is_screen then Application.ProcessMessages;
end;
procedure cmd_renew_readln(Sender:TObject);
begin
  (Sender as TAufScript).Pause;
  Application.ProcessMessages;
end;
procedure cmd_renew_clearscreen(Sender:TObject);
var Memo:TMemo_AufScript;
begin
  Memo:=(Sender as TAufScript).Owner as TMemo_AufScript;
  Memo.Clear;
  Application.ProcessMessages;
end;

procedure CMD_FUNC_SETTING(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    AMemo:TMemo_AUfScript;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not (AufScpt.Owner is TMemo_AufScript) then
    begin
      AufScpt.send_error('解释器与命令行编辑框关联错误，未成功设置！');
      exit
    end
  else AMemo:=AufScpt.Owner as TMemo_AufScript;
  if AAuf.ArgsCount<3 then
    begin
      AufScpt.send_error('命令行设置需要两个参数，未成功设置！');
      exit
    end;
  case AAuf.args[1] of
    'help':
      begin
        AufScpt.writeln('autopause on/off 末尾暂停设置');
        AufScpt.writeln('autoclear on/off 自动清屏设置');
      end;
    'autoclear':
      begin
        case AAuf.args[2] of
          'on':begin AMemo.AutoClear:=true;AufScpt.writeln('自动清屏模式已打开。');end;
          'off':begin AMemo.AutoClear:=false;AufScpt.writeln('自动清屏模式已关闭。');end;
          else ;
        end;
      end;
    'autopause':
      begin
        case AAuf.args[2] of
          'on':begin AMemo.AutoPause:=true;AufScpt.writeln('末尾暂停模式已打开。');end;
          'off':begin AMemo.AutoPause:=false;AufScpt.writeln('末尾暂停模式已关闭。');end;
          else ;
        end;
      end;
    else AufScpt.send_error('未知的命令行设置项，未成功设置！');
  end;
end;

{ TMemo_AufScript }


constructor TMemo_AufScript.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);

  Self.Auf:=TAuf.Create(Self);
  //Self.Auf.Script.Owner;
  Self.Auf.Script.add_func('set',@CMD_FUNC_SETTING,'option,value','命令行运行设置');
  Self.Auf.Script.InternalFuncDefine;

  Self.Auf.Script.IO_fptr.command_decode:=@cmd_command_decoder;
  Self.Auf.Script.IO_fptr.echo:=@cmd_renew_writeln;
  Self.Auf.Script.IO_fptr.print:=@cmd_renew_write;
  Self.Auf.Script.IO_fptr.pause:=@cmd_renew_readln;
  Self.Auf.Script.IO_fptr.error:=@cmd_renew_writeln;
  Self.Auf.Script.IO_fptr.clear:=@cmd_renew_clearscreen;
  Self.Auf.Script.Func_process.beginning:=@cmd_renew_beginning;
  Self.Auf.Script.Func_process.ending:=@cmd_renew_ending;
  Self.Auf.Script.Func_process.OnPause:=@cmd_renew_onPause;
  Self.Auf.Script.Func_process.OnResume:=@cmd_renew_onResume;
  Self.Auf.Script.Func_process.pre:=@cmd_renew_pre;
  Self.Auf.Script.Func_process.mid:=@cmd_renew_mid;
  Self.Auf.Script.Func_process.post:=@cmd_renew_post;

  Self.SubCmd:=TStringList.Create;
  //Self.OnKeyPress:=@Self.MemoRun;
  Self.OnKeyUp:=@Self.MemoKeyUp;
  Self.Font.Name:='consolas';
  Self.ScrollBars:=ssBoth;
  Self.WordWrap:=false;

end;

procedure TMemo_AufScript.RunScript;
var s:string;
    pi:longint;
begin
  Self.SubCmd.Clear;
  //SubCmd.Delimiter:='|';
  for pi:=0 to Self.Lines.Count-1 do
    begin
      if Self.Lines[pi]=CMD_BREAKPOINT_STR then Self.SubCmd.Clear
      else Self.SubCmd.Add(Self.Lines[pi]);
    end;
  s:=SubCmd.CommaText;
  s:=StringReplace(s,'(',' ',[rfReplaceAll]);
  s:=StringReplace(s,')',' ',[rfReplaceAll]);
  s:=StringReplace(s,';','","',[rfReplaceAll]);
  SubCmd.CommaText:=s;
  //messagebox(0,PChar(s),'',MB_OK);
  Self.Auf.Script.command(Self.SubCmd);
end;

{
procedure TMemo_AufScript.MemoCreate(Sender:TObject);
begin

end;
}
{
procedure TMemo_AufScript.MemoRun(Sender: TObject; var Key: char);
var i:integer;
begin
  if Key=#3 then Self.Auf.Script.Stop;
  if (Key<>#13) then exit;
  IF Self.inPause THEN BEGIN
    Self.Auf.Script.Resume;
  END ELSE BEGIN
    Self.SubCmd.Clear;
    for i:=0 to Self.Lines.Count-1 do
      begin
        if Self.Lines[i]=CMD_BREAKPOINT_STR then Self.SubCmd.Clear
        else Self.SubCmd.Add(Self.Lines[i]);
      end;
    Self.Auf.Script.command(Self.SubCmd);
  END;
end;
}
procedure TMemo_AufScript.MemoKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Shift = [ssCtrl] then begin
    if Key=Ord('C') then Self.Auf.Script.Stop
    else ;
  end else if Shift = [] then begin
    if Key=13 then begin
      if Self.AutoPauseState then begin Self.AutoPauseState:=false;exit;end;//末尾暂停模式中需要用的的状态
      IF Self.inPause THEN BEGIN
        Self.Auf.Script.Resume;
      END ELSE BEGIN
        {
        Self.SubCmd.Clear;
        for i:=0 to Self.Lines.Count-1 do
          begin
            if Self.Lines[i]=CMD_BREAKPOINT_STR then Self.SubCmd.Clear
            else Self.SubCmd.Add(Self.Lines[i]);
          end;
        Self.Auf.Script.command(Self.SubCmd);
        }
        Self.RunScript;
      END;
    end else ;
  end else begin

  end;
end;

initialization

end.

