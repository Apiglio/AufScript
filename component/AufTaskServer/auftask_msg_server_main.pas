unit auftask_msg_server_main;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
    syncobjs,
    auftask_msg_webmodule;

type

    { TForm_AufTask_Server }

    TForm_AufTask_Server = class(TForm)
        Memo_DebugLine: TMemo;
        procedure FormCreate(Sender: TObject);
    private
        FNextDebugline:string;
    public
        procedure DebugLine;
    end;

var
    Form_AufTask_Server: TForm_AufTask_Server;
    ServThread : TAufTaskServerModule;
    ThdSession : TCriticalSection;

    procedure Debugline(msg:string);


implementation

procedure Debugline(msg:string);
begin
    ThdSession.Acquire;
    try
        Form_AufTask_Server.FNextDebugline:=msg;
        ServThread.Queue(ServThread, @Form_AufTask_Server.DebugLine);
    finally
        ThdSession.Release;
    end;
end;

{$R *.lfm}

{ TForm_AufTask_Server }

procedure TForm_AufTask_Server.FormCreate(Sender: TObject);
begin
    ServThread:=TAufTaskServerModule.Create;
    ServThread.Start;
end;

procedure TForm_AufTask_Server.DebugLine;
begin
    Memo_DebugLine.Lines.Add(FNextDebugline);
end;

initialization
    ThdSession:=TCriticalSection.Create;

finalization
    ThdSession.Free;

end.

