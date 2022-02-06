unit aufscript_command;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, StdCtrls,
  Dialogs, LazUTF8, Apiglio_Useful;

type
  TMemo_AufScript = class(TMemo)
  public
    Auf:TAuf;
    SubCmd:TStrings;//用于截取最新一部分的代码
    inPause:boolean;//是否暂停，若为是，则OnEnter触发AufScpt.Resume，而不是AufScpt.command
  public
    constructor Create(AOwner:TComponent);
    procedure MemoCreate(Sender:TObject);
    procedure MemoRun(Sender: TObject; var Key: char);

  end;

implementation

const
  CMD_BREAKPOINT_STR='>>>>>>>>>';

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
  Application.ProcessMessages
end;
procedure cmd_renew_beginning(Sender:TObject);
var Memo:TMemo_AufScript;
begin
  Memo:=(Sender as TAufScript).Owner as TMemo_AufScript;
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
  Memo.SubCmd.Free;
  Memo.lines.add(CMD_BREAKPOINT_STR);//添加人工的新断点，再次运行将从新断点开始
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
var Memo:TMemo_AufScript;
begin
  Memo:=(Sender as TAufScript).Owner as TMemo_AufScript;
  Memo.lines[Memo.Lines.Count-1]:=
  Memo.lines[Memo.Lines.Count-1]+str;
  Memo.lines.add('');
  Application.ProcessMessages;
end;
procedure cmd_renew_write(Sender:TObject;str:string);
var Memo:TMemo_AufScript;
begin
  Memo:=(Sender as TAufScript).Owner as TMemo_AufScript;
  Memo.lines[Memo.Lines.Count-1]:=
  Memo.lines[Memo.Lines.Count-1]+str;
  Application.ProcessMessages;
end;
procedure cmd_renew_readln(Sender:TObject);
begin
  (Sender as TAufScript).Pause;
  Application.ProcessMessages;
end;

{ TMemo_AufScript }

constructor TMemo_AufScript.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);

  Self.Auf:=TAuf.Create(Self);
  Self.Auf.Script.InternalFuncDefine;

  Self.Auf.Script.IO_fptr.command_decode:=@cmd_command_decoder;
  Self.Auf.Script.IO_fptr.echo:=@cmd_renew_writeln;
  Self.Auf.Script.IO_fptr.print:=@cmd_renew_write;
  Self.Auf.Script.IO_fptr.pause:=@cmd_renew_readln;
  Self.Auf.Script.IO_fptr.error:=@cmd_renew_writeln;
  Self.Auf.Script.Func_process.beginning:=@cmd_renew_beginning;
  Self.Auf.Script.Func_process.ending:=@cmd_renew_ending;
  Self.Auf.Script.Func_process.OnPause:=@cmd_renew_onPause;
  Self.Auf.Script.Func_process.OnResume:=@cmd_renew_onResume;
  Self.Auf.Script.Func_process.pre:=@cmd_renew_pre;
  Self.Auf.Script.Func_process.mid:=@cmd_renew_mid;
  Self.Auf.Script.Func_process.post:=@cmd_renew_post;

  Self.OnKeyPress:=@Self.MemoRun;
  Self.Font.Name:='consolas';
  Self.ScrollBars:=ssBoth;
  Self.WordWrap:=false;

end;
procedure TMemo_AufScript.MemoCreate(Sender:TObject);
begin

end;
procedure TMemo_AufScript.MemoRun(Sender: TObject; var Key: char);
var i:integer;
begin
  if Key=#3 then Self.Auf.Script.Stop;
  if (Key<>#13) then exit;
  IF Self.inPause THEN BEGIN
    Self.Auf.Script.Resume;
  END ELSE BEGIN
    Self.SubCmd:=TStringList.Create;
    for i:=0 to Self.Lines.Count-1 do
      begin
        if Self.Lines[i]=CMD_BREAKPOINT_STR then Self.SubCmd.Clear
        else Self.SubCmd.Add(Self.Lines[i]);
      end;
    Self.Auf.Script.command(Self.SubCmd);
  END;
end;

initialization

end.

