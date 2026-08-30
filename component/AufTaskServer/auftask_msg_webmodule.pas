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
    AResponse.ContentType:='application/json; charset=utf-8';
    AResponse.Content:=Msg;
end;

procedure error_response(var AResponse: TFPHTTPConnectionResponse; const ErrorText, Msg:String);inline;
begin
    AResponse.Code:=418;
    AResponse.ContentType:='application/json; charset=utf-8';
    AResponse.Content:=Format('{"result":"%s", "info":"%s"}', [ErrorText, Msg]);
end;

procedure auftask_func_login(var ARequest: TFPHTTPConnectionRequest; var AResponse: TFPHTTPConnectionResponse; var AJSONData:TJSONObject; const ASenderId, ATargetId:string);
var argName, argPrompt, TaskToken:string;
    senderID:TAufTaskClientId;
    tmpTaskClient:TAufTaskClient;
    jKey:TJSONData;
begin
    with AJSONData do begin
        jKey:=Find('name',jtString);
        if jKey<>nil then argName:=jKey.AsString else begin
            error_response(AResponse, 'ERROR_ARGUMENT_NOT_FOUND', 'name');
            exit;
        end;
        jKey:=Find('prompt',jtString);
        if jKey<>nil then argPrompt:=jKey.AsString
        else begin
            error_response(AResponse, 'ERROR_ARGUMENT_NOT_FOUND', 'prompt');
            exit;
        end;
    end;

    if not TryStringToGUID(ASenderId, senderID) then begin
        error_response(AResponse, 'ERROR_GUID_INVALID', '');
        exit;
    end;
    if IsEqualGUID(senderID, GUID_NULL) then begin
        error_response(AResponse, 'ERROR_GUID_INVALID', '');
        exit;
    end;
    tmpTaskClient:=GlobalAufTaskPool.AddTaskClient(senderID);
    if tmpTaskClient=nil then begin
        error_response(AResponse, 'ERROR_GUID_REPEATED', '');
        exit;
    end;

    TaskToken:=GlobalAufTaskPool.GenOutKey;

    tmpTaskClient.TaskToken := TaskToken;
    tmpTaskClient.Name      := argName;
    tmpTaskClient.Prompt    := argPrompt;

    AResponse.Code:=200;
    AResponse.ContentType:='application/json; charset=utf-8';
    AResponse.Content:=Format('{"result":"SUCCESS", "task-token":"%s"}',[TaskToken]);

end;

procedure auftask_func_logout(var ARequest: TFPHTTPConnectionRequest; var AResponse: TFPHTTPConnectionResponse; var AJSONData:TJSONObject; const ASenderId, ATargetId:string);
var TaskToken:string;
    senderID:TAufTaskClientId;
    tmpTaskClient:TAufTaskClient;
    jKey:TJSONData;
begin
    with AJSONData do begin
        jKey:=Find('task-token',jtString);
        if jKey<>nil then TaskToken:=jKey.AsString
        else begin
            error_response(AResponse, 'ERROR_ARGUMENT_NOT_FOUND', 'task-token');
            exit;
        end;
    end;

    if not TryStringToGUID(ASenderId, senderID) then begin
        error_response(AResponse, 'ERROR_GUID_INVALID', '');
        exit;
    end;
    if IsEqualGUID(senderID, GUID_NULL) then begin
        error_response(AResponse, 'ERROR_GUID_INVALID', '');
        exit;
    end;
    tmpTaskClient:=GlobalAufTaskPool.GetTaskClient(senderID);
    if tmpTaskClient.TaskToken<>TaskToken then begin
        error_response(AResponse, 'ERROR_TOKEN_INVALID', '');
        exit;
    end;

    if not GlobalAufTaskPool.DelTaskClient(senderID) then begin
        error_response(AResponse, 'ERROR_GUID_NOT_FOUND', '');
        exit;
    end;

    AResponse.Code:=200;
    AResponse.ContentType:='application/json; charset=utf-8';
    AResponse.Content:='{"result":"SUCCESS"}';

end;


procedure auftask_func_send(var ARequest: TFPHTTPConnectionRequest; var AResponse: TFPHTTPConnectionResponse; var AJSONData:TJSONObject; const ASenderId, ATargetId:string);
var argData, argPass:string;
    argCode:integer;
    senderID, targetID:TAufTaskClientId;
    senderTC, targetTC:TAufTaskClient;
    jKey:TJSONData;
begin
    with AJSONData do begin
        jKey:=Find('data',jtString);
        if jKey<>nil then argData:=jKey.AsString
        else begin
            error_response(AResponse, 'ERROR_ARGUMENT_NOT_FOUND', 'data');
            exit;
        end;
        jKey:=Find('pass',jtString);
        if jKey<>nil then argPass:=jKey.AsString
        else begin
            error_response(AResponse, 'ERROR_ARGUMENT_NOT_FOUND', 'pass');
            exit;
        end;
        jKey:=Find('code',jtNumber);
        if jKey<>nil then argCode:=jKey.AsInteger
        else begin
            error_response(AResponse, 'ERROR_ARGUMENT_NOT_FOUND', 'code');
            exit;
        end;
    end;

    if not TryStringToGUID(ASenderId, senderID) then begin
        error_response(AResponse, 'ERROR_GUID_INVALID', '');
        exit;
    end;
    if IsEqualGUID(senderID, GUID_NULL) then begin
        error_response(AResponse, 'ERROR_GUID_INVALID', '');
        exit;
    end;
    if not TryStringToGUID(ATargetId, targetID) then begin
        error_response(AResponse, 'ERROR_GUID_INVALID', '');
        exit;
    end;
    if IsEqualGUID(targetID, GUID_NULL) then begin
        error_response(AResponse, 'ERROR_GUID_INVALID', '');
        exit;
    end;

    senderTC:=GlobalAufTaskPool.GetTaskClient(senderID);
    if senderTC=nil then begin
        error_response(AResponse, 'ERROR_TASK_NOT_FOUND', '');
        exit;
    end;
    targetTC:=GlobalAufTaskPool.GetTaskClient(targetID);
    if targetTC=nil then begin
        error_response(AResponse, 'ERROR_TASK_NOT_FOUND', '');
        exit;
    end;

    //argPass检验未实现
    GlobalAufTaskMessagePool.PushMessage(senderID, targetID, argData, argCode);

    AResponse.Code:=200;
    AResponse.ContentType:='application/json; charset=utf-8';
    AResponse.Content:='{"result":"SUCCESS"}';

end;

procedure auftask_func_fetch(var ARequest: TFPHTTPConnectionRequest; var AResponse: TFPHTTPConnectionResponse; var AJSONData:TJSONObject; const ASenderId, ATargetId:string);
var TaskToken:string;
    targetID:TAufTaskClientId;
    targetTC:TAufTaskClient;
    tmpMsg:TAufTaskMessage;
    resJSON:TJSONArray;
    objJSON:TJSONObject;
    jKey:TJSONData;
begin
    with AJSONData do begin
        jKey:=Find('task-token',jtString);
        if jKey<>nil then TaskToken:=jKey.AsString
        else begin
            error_response(AResponse, 'ERROR_ARGUMENT_NOT_FOUND', 'task-token');
            exit;
        end;
    end;

    if not TryStringToGUID(ATargetId, targetID) then begin
        error_response(AResponse, 'ERROR_GUID_INVALID', '');
        exit;
    end;
    if IsEqualGUID(targetID, GUID_NULL) then begin
        error_response(AResponse, 'ERROR_GUID_INVALID', '');
        exit;
    end;

    targetTC:=GlobalAufTaskPool.GetTaskClient(targetID);
    if targetTC=nil then begin
        error_response(AResponse, 'ERROR_TASK_NOT_FOUND', '');
        exit;
    end;

    resJSON:=TJSONArray.Create;
    try
        while true do begin
            tmpMsg:=GlobalAufTaskMessagePool.PopMessage(targetID);
            if tmpMsg=nil then break;
            objJSON:=TJSONObject.Create;
            objJSON.Strings['sender-id']:=GUIDToString(tmpMsg.Sender);
            objJSON.Strings['target-id']:=GUIDToString(tmpMsg.Target);
            objJSON.Strings['data']:=tmpMsg.Data;
            objJSON.Integers['code']:=tmpMsg.Code;
            resJSON.Add(objJSON);
        end;
        AResponse.Code:=200;
        AResponse.ContentType:='application/json; charset=utf-8';
        AResponse.Content:=Format('{"result":"SUCCESS", "messages":%s}',[resJSON.FormatJSON()]);
    finally
        resJSON.Free;
    end;

end;


procedure auftask_func_tasklist(var ARequest: TFPHTTPConnectionRequest; var AResponse: TFPHTTPConnectionResponse; var AJSONData:TJSONObject; const ASenderId, ATargetId:string);
var TaskToken:string;
    targetID:TAufTaskClientId;
    targetTC:TAufTaskClient;
    jKey:TJSONData;
    allowEmptyName:boolean;
begin
    with AJSONData do begin
        jKey:=Find('task-token',jtString);
        if jKey<>nil then TaskToken:=jKey.AsString
        else begin
            error_response(AResponse, 'ERROR_ARGUMENT_NOT_FOUND', 'task-token');
            exit;
        end;
        jKey:=Find('allow-empty-name',jtBoolean);
        if jKey<>nil then allowEmptyName:=jKey.AsBoolean else allowEmptyName:=false;
    end;

    if not TryStringToGUID(ATargetId, targetID) then begin
        error_response(AResponse, 'ERROR_GUID_INVALID', '');
        exit;
    end;
    if IsEqualGUID(targetID, GUID_NULL) then begin
        error_response(AResponse, 'ERROR_GUID_INVALID', '');
        exit;
    end;

    targetTC:=GlobalAufTaskPool.GetTaskClient(targetID);
    if targetTC=nil then begin
        error_response(AResponse, 'ERROR_TASK_NOT_FOUND', '');
        exit;
    end;

    AResponse.Code:=200;
    AResponse.ContentType:='application/json; charset=utf-8';
    AResponse.Content:=Format('{"result":"SUCCESS", "tasks":%s}',[GlobalAufTaskPool.GetTaskListJSON(allowEmptyName).FormatJSON()]);

end;


procedure auftask_func_upd_meta(var ARequest: TFPHTTPConnectionRequest; var AResponse: TFPHTTPConnectionResponse; var AJSONData:TJSONObject; const ASenderId, ATargetId:string);
var TaskToken, MetaKey, MetaValue:string;
    targetID:TAufTaskClientId;
    targetTC:TAufTaskClient;
    jKey:TJSONData;
begin
    with AJSONData do begin
        jKey:=Find('task-token',jtString);
        if jKey<>nil then TaskToken:=jKey.AsString
        else begin
            error_response(AResponse, 'ERROR_ARGUMENT_NOT_FOUND', 'task-token');
            exit;
        end;
        jKey:=Find('key',jtString);
        if jKey<>nil then MetaKey:=jKey.AsString
        else begin
            error_response(AResponse, 'ERROR_ARGUMENT_NOT_FOUND', 'key');
            exit;
        end;
        jKey:=Find('value',jtString);
        if jKey<>nil then MetaValue:=jKey.AsString
        else begin
            error_response(AResponse, 'ERROR_ARGUMENT_NOT_FOUND', 'value');
            exit;
        end;
    end;

    if not TryStringToGUID(ATargetId, targetID) then begin
        error_response(AResponse, 'ERROR_GUID_INVALID', '');
        exit;
    end;
    if IsEqualGUID(targetID, GUID_NULL) then begin
        error_response(AResponse, 'ERROR_GUID_INVALID', '');
        exit;
    end;

    targetTC:=GlobalAufTaskPool.GetTaskClient(targetID);
    if targetTC=nil then begin
        error_response(AResponse, 'ERROR_TASK_NOT_FOUND', '');
        exit;
    end;

    case MetaKey of
        'name':targetTC.Name:=MetaValue;
        'prompt':targetTC.Prompt:=MetaValue;
        'task-token':targetTC.TaskToken:=MetaValue;
        else begin
            error_response(AResponse, 'ERROR_METAKEY_INVALID', MetaKey);
            exit;
        end;
    end;

    AResponse.Code:=200;
    AResponse.ContentType:='application/json; charset=utf-8';
    AResponse.Content:='{"result":"SUCCESS"}';

end;

procedure TAufTaskServer.HandleRequest(var ARequest: TFPHTTPConnectionRequest; var AResponse: TFPHTTPConnectionResponse);
const CRLF={$ifdef WINDOWS}#13#10{$else}#10{$endif};
var UA:string;
    func, sender_id, target_id:string;
    query_spliter:integer;
    jData, jKey:TJSONData;

begin
    UA:=lowercase(ARequest.UserAgent);
    if pos('aufscript task', UA)<=0 then begin
        AResponse.Code:=400;
        AResponse.ContentType:='application/json; charset=utf-8';
        AResponse.Content:='{"result":"ERROR_UNKNOWN"}';
        Debugline(Format('[%s] Invalid UA: %s', [DateTimeToStr(Now()), ARequest.UserAgent]));
        exit;
    end;

    func:=ARequest.URI;
    query_spliter:=pos('?',func);
    if query_spliter>0 then delete(func, query_spliter, length(func));
    if func<>'' then delete(func,1,1);
    Debugline(Format('[%s] Func: %s '+#9+' %s', [DateTimeToStr(Now()), func, ARequest.Content]));

    TRY
        try
            jData:=nil;
            jData:=GetJSON(ARequest.Content, true);
        except
            teapot_response(AResponse,'{"result":"ERROR_FATAL"}');
            exit;
        end;
        if jData.JSONType <> jtObject then begin
            teapot_response(AResponse,'{"result":"ERROR_FATAL"}');
            exit;
        end;
        with TJSONObject(jData) do begin
            jKey:=Find('sender-id',jtString);
            if jKey=nil then sender_id:='' else sender_id:=jKey.AsString;
            jKey:=Find('target-id',jtString);
            if jKey=nil then target_id:='' else target_id:=jKey.AsString;
        end;

        case lowercase(func) of
            'login':    auftask_func_login(    ARequest, AResponse, TJSONObject(jData), sender_id, target_id);
            'logout':   auftask_func_logout(   ARequest, AResponse, TJSONObject(jData), sender_id, target_id);
            'send':     auftask_func_send(     ARequest, AResponse, TJSONObject(jData), sender_id, target_id);
            'fetch':    auftask_func_fetch(    ARequest, AResponse, TJSONObject(jData), sender_id, target_id);
            'tasklist': auftask_func_tasklist( ARequest, AResponse, TJSONObject(jData), sender_id, target_id);
            'upd_meta': auftask_func_upd_meta( ARequest, AResponse, TJSONObject(jData), sender_id, target_id);
            else begin
                AResponse.Code:=405;
                AResponse.ContentType:='application/json; charset=utf-8';
                AResponse.Content:=Format('{"result":"ERROR_FUNC_NOT_FOUND", "info":"No AufTask Function %s"}',[func]);
                AResponse.SendContent;
            end;
        end;
    FINALLY
        if jData<>nil then FreeAndNil(jData);
    END;


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

