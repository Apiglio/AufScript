unit auftask_msg_webmodule;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils,
    fphttpserver, fpmimetypes;

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
var idxSenderId, idxName, idxPrompt:integer;
    argSenderId, argName, argPrompt, delete_key:string;
begin

    idxSenderId := ARequest.QueryFields.IndexOfName('sender_id');
    idxName     := ARequest.QueryFields.IndexOfName('name');
    idxPrompt   := ARequest.QueryFields.IndexOfName('prompt');
    if (idxSenderId<0) or (idxName<0) or (idxPrompt<0) then begin
        AResponse.Code:=418;
        AResponse.Content:=Format(
            '{"result"="AufTask Function login Error: Incomplete Arguments. %d %d %d"}',
            [idxSenderId, idxName, idxPrompt]
        );
        exit;
    end else begin
        argSenderId := ARequest.QueryFields.ValueFromIndex[idxSenderId];
        argName     := ARequest.QueryFields.ValueFromIndex[idxName];
        argPrompt   := ARequest.QueryFields.ValueFromIndex[idxPrompt];
    end;

    delete_key:='...';
    AResponse.Code:=200;
    AResponse.Content:=Format('{"result":"Success", "delete_key"="%s"}',[delete_key]);
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
        Debugline('['+DateTimeToStr(Now())+'] UA dismatch'+CRLF+ARequest.UserAgent);
        exit;
    end;

    func:=ARequest.URI;
    query_spliter:=pos('?',func);
    if query_spliter<=0 then begin
        AResponse.Code:=400;
        Debugline('['+DateTimeToStr(Now())+'] No query'+CRLF+ARequest.URI);
        exit;
    end;

    delete(func, query_spliter, length(func));
    delete(func,1,1);
    Debugline('['+DateTimeToStr(Now())+'] Func'+CRLF+ARequest.QueryString);
    case lowercase(func) of
        'login':auftask_func_login(ARequest, AResponse);
        else begin
            AResponse.Code:=405;
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




end.

