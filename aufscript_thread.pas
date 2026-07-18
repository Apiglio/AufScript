unit aufscript_thread;

{$mode objfpc}{$H+}

interface

uses
  {$ifdef UNIX}
    {$ifndef ANDROID}
    cthreads,
    {$endif}
  {$endif}
  Classes, SysUtils;

type
  TAufScriptThread = class(TThread)
  private
    FAufScript:TObject;
    procedure RunFirst;
    procedure RunNext;
    procedure RunClose;
  protected
    procedure Execute; override;
  public
    Constructor Create(AufScpt:TObject;CreateSuspended:boolean);
  end;

implementation
uses Apiglio_Useful;

{ TAufScriptThread }

constructor TAufScriptThread.Create(AufScpt:TObject;CreateSuspended:boolean);
begin
  if not (AufScpt is TAufScript) then raise Exception.Create('TAufScriptThread.FAufScript must be TAufScript.');
  inherited Create(CreateSuspended);
  FAufScript:=AufScpt;
  FreeOnTerminate := True;
end;

procedure TAufScriptThread.RunFirst;
begin
  (FAufScript as TAufScript).RunFirst;
end;

procedure TAufScriptThread.RunNext;
begin
  (FAufScript as TAufScript).RunNext;
end;

procedure TAufScriptThread.RunClose;
begin
  (FAufScript as TAufScript).RunClose;
end;

procedure TAufScriptThread.Execute;
var AufScpt:TAufScript;
begin
  AufScpt:=FAufScript as TAufScript;
  Synchronize(@RunFirst);
  while not Terminated do
  begin
    if AufScpt.PSW.haltoff then break;
    if AufScpt.PSW.pause then continue;
    if AufScpt.PSW.inRunNext then continue;
    AufScpt.Time.WaitingMSAfterFunc:=0;
    RunNext;
    with AufScpt.Time do if WaitingMSAfterFunc>0 then sleep(WaitingMSAfterFunc);
  end;
  Synchronize(@RunClose);
end;



end.

