unit auftask_msg_webmodule;

{$mode objfpc}{$H+}
{$label on}
{$inline on}

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
uses auftask_msg_server_main, fpjson;

var GlobalAufTaskPool:TAufTaskPool;
    GlobalAufTaskMessagePool:TAufTaskMessagePool;


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


procedure teapot_response(var AResponse: TFPHTTPConnectionResponse; const Msg:String);inline;
begin
    AResponse.Code:=418;
    AResponse.ContentType:='application/json';
    AResponse.Content:=Msg;
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
    if IsEqualGUID(senderID, GUID_NULL) then goto FL_INVALID_GUID;
    tmpTaskClient:=GlobalAufTaskPool.AddTaskClient(senderID);
    if tmpTaskClient=nil then goto FL_REPEATED_GUID;

    outkey:=GlobalAufTaskPool.GenOutKey;

    tmpTaskClient.OutKey := outkey;
    tmpTaskClient.Name   := argName;
    tmpTaskClient.Prompt := argPrompt;

    AResponse.Code:=200;
    AResponse.ContentType:='application/json';
    AResponse.Content:=Format('{"result":"Success", "outkey"="%s"}',[outkey]);

EXIT;

FL_INVALID_ARGEMENTS:
    teapot_response(AResponse, Format(
        '{"result"="LOGIN Incomplete Arguments. %d %d %d"}', [idxSenderId, idxName, idxPrompt]
    ));exit;

FL_INVALID_GUID:
    teapot_response(AResponse, Format(
        '{"result"="AufTask Function login Error: Invalid GUID: %s."}', [argSenderId]
    ));exit;

FL_REPEATED_GUID:
    teapot_response(AResponse, Format(
        '{"result"="AufTask Function login Error: Repeated GUID: %s."}', [argSenderId]
    ));exit;


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
    if IsEqualGUID(senderID, GUID_NULL) then goto FL_INVALID_GUID;
    tmpTaskClient:=GlobalAufTaskPool.GetTaskClient(senderID);
    if tmpTaskClient.OutKey<>argOutKey then goto FL_INVALID_OUTKEY;

    if not GlobalAufTaskPool.DelTaskClient(senderID) then goto FL_TASK_NOT_FOUND;

    AResponse.Code:=200;
    AResponse.ContentType:='application/json';
    AResponse.Content:='{"result":"Success"}';

EXIT;

FL_INVALID_ARGEMENTS:
    teapot_response(AResponse, Format(
        '{"result"="AufTask Function logout Error: Incomplete Arguments. %d %d"}', [idxSenderId, idxOutKey]
    ));exit;

FL_INVALID_OUTKEY:
    teapot_response(AResponse, Format(
        '{"result"="AufTask Function logout Error: Invalid Outkey: %s."}', [argOutKey]
    ));exit;

FL_INVALID_GUID:
    teapot_response(AResponse, Format(
        '{"result"="AufTask Function logout Error: Invalid GUID: %s."}', [argSenderId]
    ));exit;

FL_TASK_NOT_FOUND:
    teapot_response(AResponse, Format(
        '{"result"="AufTask Function logout Error: Task Not Found: %s."}', [argSenderId]
    ));exit;


end;


procedure auftask_func_send(var ARequest: TFPHTTPConnectionRequest; var AResponse: TFPHTTPConnectionResponse);
label FL_INVALID_ARGEMENTS, FL_INVALID_GUID, FL_TASK_NOT_FOUND;
var idxSenderId, idxTargetId, idxData, idxPass, idxCode:integer;
    argSenderId, argTargetId, argData, argPass:string;
    argCode:integer;
    senderID, targetID:TAufTaskClientId;
    senderTC, targetTC:TAufTaskClient;
begin

    idxSenderId := ARequest.QueryFields.IndexOfName('sender_id');
    idxTargetId := ARequest.QueryFields.IndexOfName('target_id');
    idxData     := ARequest.QueryFields.IndexOfName('data');
    idxPass     := ARequest.QueryFields.IndexOfName('pass');
    idxCode     := ARequest.QueryFields.IndexOfName('code');
    if (idxSenderId<0) or (idxTargetId<0) or (idxData<0) or (idxPass<0) or (idxCode<0) then goto FL_INVALID_ARGEMENTS;

    argSenderId := ARequest.QueryFields.ValueFromIndex[idxSenderId];
    argTargetId := ARequest.QueryFields.ValueFromIndex[idxTargetId];
    argData     := ARequest.QueryFields.ValueFromIndex[idxData];
    argPass     := ARequest.QueryFields.ValueFromIndex[idxPass];
    if not TryStrToInt(ARequest.QueryFields.ValueFromIndex[idxCode], argCode) then argCode:=0;

    if not TryStringToGUID(argSenderId, senderID) then goto FL_INVALID_GUID;
    if IsEqualGUID(senderID, GUID_NULL) then goto FL_INVALID_GUID;
    if not TryStringToGUID(argTargetId, targetID) then goto FL_INVALID_GUID;
    if IsEqualGUID(targetID, GUID_NULL) then goto FL_INVALID_GUID;

    senderTC:=GlobalAufTaskPool.GetTaskClient(senderID);
    if senderTC=nil then goto FL_TASK_NOT_FOUND;
    targetTC:=GlobalAufTaskPool.GetTaskClient(targetID);
    if targetTC=nil then goto FL_TASK_NOT_FOUND;

    //argPass检验未实现
    GlobalAufTaskMessagePool.PushMessage(senderID, targetID, argData, argCode);

    AResponse.Code:=200;
    AResponse.ContentType:='application/json';
    AResponse.Content:='{"result":"Success"}';

EXIT;

FL_INVALID_ARGEMENTS:
    teapot_response(AResponse, Format(
        '{"result"="AufTask Function send Error: Incomplete Arguments. %d %d %d %d %d"}', [idxSenderId, idxTargetId, idxData, idxPass, idxCode]
    ));exit;

FL_INVALID_GUID:
    teapot_response(AResponse, Format(
        '{"result"="AufTask Function send Error: Invalid GUID(s): %s %s."}', [argSenderId, argTargetId]
    ));exit;

FL_TASK_NOT_FOUND:
    teapot_response(AResponse, Format(
        '{"result"="AufTask Function send Error: Task(s) Not Found: %s %s."}', [argSenderId, argTargetId]
    ));exit;


end;

procedure auftask_func_fetch(var ARequest: TFPHTTPConnectionRequest; var AResponse: TFPHTTPConnectionResponse);
label FL_INVALID_ARGEMENTS, FL_INVALID_GUID, FL_TASK_NOT_FOUND;
var idxTargetId, idxOutKey:integer;
    argTargetId, argOutKey:string;
    targetID:TAufTaskClientId;
    targetTC:TAufTaskClient;
    tmpMsg:TAufTaskMessage;
    resJSON:TJSONArray;
    objJSON:TJSONObject;
begin

    idxTargetId := ARequest.QueryFields.IndexOfName('target_id');
    idxOutKey   := ARequest.QueryFields.IndexOfName('outkey');
    if (idxTargetId<0) or (idxOutKey<0) then goto FL_INVALID_ARGEMENTS;

    argTargetId := ARequest.QueryFields.ValueFromIndex[idxTargetId];
    argOutKey   := ARequest.QueryFields.ValueFromIndex[idxOutKey];

    if not TryStringToGUID(argTargetId, targetID) then goto FL_INVALID_GUID;
    if IsEqualGUID(targetID, GUID_NULL) then goto FL_INVALID_GUID;

    targetTC:=GlobalAufTaskPool.GetTaskClient(targetID);
    if targetTC=nil then goto FL_TASK_NOT_FOUND;

    resJSON:=TJSONArray.Create;
    try
        while true do begin
            tmpMsg:=GlobalAufTaskMessagePool.PopMessage(targetID);
            if tmpMsg=nil then break;
            objJSON:=TJSONObject.Create;
            objJSON.Strings['sender_id']:=GUIDToString(tmpMsg.Sender);
            objJSON.Strings['target_id']:=GUIDToString(tmpMsg.Target);
            objJSON.Strings['data']:=tmpMsg.Data;
            objJSON.Integers['code']:=tmpMsg.Code;
            resJSON.Add(objJSON);
        end;
        AResponse.Code:=200;
        AResponse.ContentType:='application/json';
        AResponse.Content:=Format('{"result":"Success", "messages":%s}',[resJSON.FormatJSON()]);
    finally
        resJSON.Free;
    end;


EXIT;

FL_INVALID_ARGEMENTS:
    teapot_response(AResponse, Format(
        '{"result"="AufTask Function fetch Error: Incomplete Arguments. %d %d"}', [idxTargetId, idxOutKey]
    ));exit;

FL_INVALID_GUID:
    teapot_response(AResponse, Format(
        '{"result"="AufTask Function fetch Error: Invalid GUID: %s."}', [argTargetId]
    ));exit;

FL_TASK_NOT_FOUND:
    teapot_response(AResponse, Format(
        '{"result"="AufTask Function fetch Error: Task Not Found: %s."}', [argTargetId]
    ));exit;

end;


procedure auftask_func_getlist(var ARequest: TFPHTTPConnectionRequest; var AResponse: TFPHTTPConnectionResponse);
label FL_INVALID_ARGEMENTS, FL_INVALID_GUID, FL_TASK_NOT_FOUND;
var idxTargetId, idxOutKey:integer;
    argTargetId, argOutKey:string;
    targetID:TAufTaskClientId;
    targetTC:TAufTaskClient;
    tmpMsg:TAufTaskMessage;
begin

    idxTargetId := ARequest.QueryFields.IndexOfName('target_id');
    idxOutKey   := ARequest.QueryFields.IndexOfName('outkey');
    if (idxTargetId<0) or (idxOutKey<0) then goto FL_INVALID_ARGEMENTS;

    argTargetId := ARequest.QueryFields.ValueFromIndex[idxTargetId];
    argOutKey   := ARequest.QueryFields.ValueFromIndex[idxOutKey];

    if not TryStringToGUID(argTargetId, targetID) then goto FL_INVALID_GUID;
    if IsEqualGUID(targetID, GUID_NULL) then goto FL_INVALID_GUID;

    targetTC:=GlobalAufTaskPool.GetTaskClient(targetID);
    if targetTC=nil then goto FL_TASK_NOT_FOUND;

    AResponse.Code:=200;
    AResponse.ContentType:='application/json';
    AResponse.Content:=Format('{"result":"Success", "messages":%s}',[GlobalAufTaskPool.GetTaskListJSON().FormatJSON()]);


EXIT;

FL_INVALID_ARGEMENTS:
    teapot_response(AResponse, Format(
        '{"result"="AufTask Function fetch Error: Incomplete Arguments. %d %d"}', [idxTargetId, idxOutKey]
    ));exit;

FL_INVALID_GUID:
    teapot_response(AResponse, Format(
        '{"result"="AufTask Function fetch Error: Invalid GUID: %s."}', [argTargetId]
    ));exit;

FL_TASK_NOT_FOUND:
    teapot_response(AResponse, Format(
        '{"result"="AufTask Function fetch Error: Task Not Found: %s."}', [argTargetId]
    ));exit;

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
        'send':auftask_func_send(ARequest, AResponse);
        'fetch':auftask_func_fetch(ARequest, AResponse);
        'getlist':auftask_func_getlist(ARequest, AResponse);
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
    GlobalAufTaskMessagePool:=TAufTaskMessagePool.Create;
    Randomize;

finalization
    GlobalAufTaskPool.Free;
    GlobalAufTaskMessagePool.Free;

end.

