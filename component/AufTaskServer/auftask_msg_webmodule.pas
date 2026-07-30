unit auftask_msg_webmodule;

{$mode objfpc}{$H+}
{$label on}

interface

uses
    Classes, SysUtils,
    fphttpserver, fpmimetypes,
    auftask_msg_manager;

type

    TAufTaskServer = class(TFPHTTPServer)
    private
        PThread:TThread;
        FBaseDir : string;
        FCount : integer;
        FMimeLoaded : boolean;
        FMimeTypesFile: string;
        procedure SetBaseDir(const AValue: string);
    Protected
        procedure CheckMimeLoaded;
        Property MimeLoaded : boolean read FMimeLoaded;
    public
        procedure HandleRequest(var ARequest: TFPHTTPConnectionRequest; var AResponse : TFPHTTPConnectionResponse); override;
        Property BaseDir : string read FBaseDir write SetBaseDir;
        Property MimeTypesFile : string read FMimeTypesFile write FMimeTypesFile;
    end;

    TAufTaskServerModule = class(TThread)
    private
        FServer:TAufTaskServer;
    public
        procedure Execute; override;
        constructor Create;
    end;



implementation
uses auftask_msg_server_main;

var GlobalAufTaskPool:TAufTaskPool;


{ TAufTaskServer }

procedure TAufTaskServer.SetBaseDir(const AValue: string);
begin
    if FBaseDir=AValue then exit;
    FBaseDir:=AValue;
    if (FBaseDir<>'') then FBaseDir:=IncludeTrailingPathDelimiter(FBaseDir);
end;

procedure TAufTaskServer.CheckMimeLoaded;
begin
    if (Not MimeLoaded) and (MimeTypesFile<>'') then begin
        MimeTypes.LoadFromFile(MimeTypesFile);
        FMimeLoaded:=true;
    end;
end;


procedure auftask_func_login(var ARequest: TFPHTTPConnectionRequest; var AResponse: TFPHTTPConnectionResponse);
label FL_INVALID_ARGEMENTS, FL_INVALID_GUID, FL_REPEATED_GUID;
var idxSenderId, idxName, idxPrompt:integer;
    argSenderId, argName, argPrompt, outkey:string;
    senderID:TAufTaskClientId;
    tmpTaskClient:TAufTaskClient;
begin

    idxSenderId := ARequest.QueryFields.IndexOfName('sender_id');
    idxName     := ARequest.QueryFields.IndexOfName('name');
    idxPrompt   := ARequest.QueryFields.IndexOfName('prompt');
    if (idxSenderId<0) or (idxName<0) or (idxPrompt<0) then goto FL_INVALID_ARGEMENTS;

    argSenderId := ARequest.QueryFields.ValueFromIndex[idxSenderId];
    argName     := ARequest.QueryFields.ValueFromIndex[idxName];
    argPrompt   := ARequest.QueryFields.ValueFromIndex[idxPrompt];

    if not TryStringToGUID(argSenderId, senderID) then goto FL_INVALID_GUID;
    if senderID=GUID_NULL then goto FL_INVALID_GUID;
    tmpTaskClient:=GlobalAufTaskPool.AddTaskClient(senderID);
    if tmpTaskClient=nil then goto FL_REPEATED_GUID;

    outkey:='defaultOutKey';
    tmpTaskClient.OutKey := outkey;
    tmpTaskClient.Name   := argName;
    tmpTaskClient.Prompt := argPrompt;

    AResponse.Code:=200;
    AResponse.ContentType:='application/json';
    AResponse.Content:=Format('{"result":"Success", "outkey"="%s"}',[outkey]);

EXIT;

FL_INVALID_ARGEMENTS:
    AResponse.Code:=418;
    AResponse.ContentType:='application/json';
    AResponse.Content:=Format(
        '{"result"="AufTask Function login Error: Incomplete Arguments. %d %d %d"}',
        [idxSenderId, idxName, idxPrompt]
    );
    exit;

FL_INVALID_GUID:

    AResponse.Code:=418;
    AResponse.ContentType:='application/json';
    AResponse.Content:=Format(
        '{"result"="AufTask Function login Error: Invalid GUID: %s."}', [argSenderId]
    );
    exit;

FL_REPEATED_GUID:
    AResponse.Code:=418;
    AResponse.ContentType:='application/json';
    AResponse.Content:=Format(
        '{"result"="AufTask Function login Error: Repeated GUID: %s."}', [argSenderId]
    );
    exit;


end;

procedure auftask_func_logout(var ARequest: TFPHTTPConnectionRequest; var AResponse: TFPHTTPConnectionResponse);
label FL_INVALID_ARGEMENTS, FL_INVALID_OUTKEY, FL_INVALID_GUID, FL_TASK_NOT_FOUND;
var idxSenderId, idxOutKey:integer;
    argSenderId, argOutKey:string;
    senderID:TAufTaskClientId;
    tmpTaskClient:TAufTaskClient;
begin

    idxSenderId := ARequest.QueryFields.IndexOfName('sender_id');
    idxOutKey   := ARequest.QueryFields.IndexOfName('outkey');
    if (idxSenderId<0) or (idxOutKey<0) then goto FL_INVALID_ARGEMENTS;

    argSenderId := ARequest.QueryFields.ValueFromIndex[idxSenderId];
    argOutKey   := ARequest.QueryFields.ValueFromIndex[idxOutKey];

    if not TryStringToGUID(argSenderId, senderID) then goto FL_INVALID_GUID;
    if senderID=GUID_NULL then goto FL_INVALID_GUID;
    tmpTaskClient:=GlobalAufTaskPool.GetTaskClient(senderID);
    if tmpTaskClient.OutKey<>argOutKey then goto FL_INVALID_OUTKEY;

    if not GlobalAufTaskPool.DelTaskClient(senderID) then goto FL_TASK_NOT_FOUND;

    AResponse.Code:=200;
    AResponse.ContentType:='application/json';
    AResponse.Content:=Format('{"result":"Success"}',[argOutkey]);

EXIT;

FL_INVALID_ARGEMENTS:
    AResponse.Code:=418;
    AResponse.ContentType:='application/json';
    AResponse.Content:=Format(
        '{"result"="AufTask Function login Error: Incomplete Arguments. %d %d"}',
        [idxSenderId, idxOutKey]
    );
    exit;

FL_INVALID_OUTKEY:
    AResponse.Code:=418;
    AResponse.ContentType:='application/json';
    AResponse.Content:=Format(
        '{"result"="AufTask Function logout Error: Invalid Outkey: %s."}', [argOutKey]
    );
    exit;

FL_INVALID_GUID:

    AResponse.Code:=418;
    AResponse.ContentType:='application/json';
    AResponse.Content:=Format(
        '{"result"="AufTask Function logout Error: Invalid GUID: %s."}', [argSenderId]
    );
    exit;

FL_TASK_NOT_FOUND:
    AResponse.Code:=418;
    AResponse.ContentType:='application/json';
    AResponse.Content:=Format(
        '{"result"="AufTask Function logout Error: Task Not Found: %s."}', [argSenderId]
    );
    exit;


end;


procedure TAufTaskServer.HandleRequest(var ARequest: TFPHTTPConnectionRequest; var AResponse: TFPHTTPConnectionResponse);
const CRLF={$ifdef WINDOWS}#13#10{$else}#10{$endif};
var UA:string;
    func:string;
    query_spliter:integer;

begin
    UA:=lowercase(ARequest.UserAgent);
    if pos('aufscript task', UA)<=0 then begin
        AResponse.Code:=400;
        AResponse.ContentType:='application/json';
        Debugline('['+DateTimeToStr(Now())+'] UA dismatch'+CRLF+ARequest.UserAgent);
        exit;
    end;

    func:=ARequest.URI;
    query_spliter:=pos('?',func);
    if query_spliter<=0 then begin
        AResponse.Code:=400;
        AResponse.ContentType:='application/json';
        Debugline('['+DateTimeToStr(Now())+'] No query'+CRLF+ARequest.URI);
        exit;
    end;

    delete(func, query_spliter, length(func));
    delete(func,1,1);
    Debugline('['+DateTimeToStr(Now())+'] Func'+CRLF+ARequest.QueryString);
    case lowercase(func) of
        'login':auftask_func_login(ARequest, AResponse);
        'logout':auftask_func_logout(ARequest, AResponse);
        else begin
            AResponse.Code:=405;
            AResponse.ContentType:='application/json';
            AResponse.Content:=Format('{"result"="No AufTask Function %s"}',[func]);
            AResponse.SendContent;
        end;
    end;

end;


{ TAufTaskServerModule }

procedure TAufTaskServerModule.Execute;
begin
    FServer:=nil;
    FServer:=TAufTaskServer.Create(nil);

    FServer.BaseDir:=ExtractFilePath(ParamStr(0));
    {$ifdef UNIX}
    FServer.MimeTypesFile:='/etc/mime.types';
    {$endif}
    FServer.Threaded:=True;
    FServer.Port:=15616;
    FServer.AcceptIdleTimeout:=1000;

    //FServer.PThread:=Self;
    FServer.Active:=True;


end;

constructor TAufTaskServerModule.Create;
begin
    inherited Create(true);
    FreeOnTerminate:=true;
end;


initialization
    GlobalAufTaskPool:=TAufTaskPool.Create;

finalization
    GlobalAufTaskPool.Free;


end.

