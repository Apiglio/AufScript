unit auftask_msg_server_main;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
    auftask_msg_webmodule;

type

    { TForm_AufTask_Server }

    TForm_AufTask_Server = class(TForm)
        Memo_DebugLine: TMemo;
        procedure FormCreate(Sender: TObject);
    private

    public
        procedure DebugLine(msg:string);
    end;

var
    Form_AufTask_Server: TForm_AufTask_Server;
    ServThread : TAufTaskServerModule;

    procedure Debugline(msg:string);


implementation

procedure Debugline(msg:string);
begin
    Form_AufTask_Server.DebugLine(msg);
end;

{$R *.lfm}

{ TForm_AufTask_Server }

procedure TForm_AufTask_Server.FormCreate(Sender: TObject);
begin
    ServThread:=TAufTaskServerModule.Create;
    ServThread.Start;
end;

procedure TForm_AufTask_Server.DebugLine(msg:string);
begin
    Memo_DebugLine.Lines.Add(msg);
end;


end.

