unit aufscript_https;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, URIParser;

type
  TAufScriptHttpsClient = class
    procedure CheckURI (Sender: TObject; const ASrc: String; var ADest: String);
  end;

  procedure FuncDefineHTTP(Sender:TObject);

implementation
uses Apiglio_Useful, auf_ram_var, auf_type_error;
var AufScriptHttpClient:TAufScriptHttpsClient;

//Fixed by @wittbo on Lazarus Forum,
//Source: https://forum.lazarus.freepascal.org/index.php/topic,43553.msg335901.html#msg335901
procedure TAufScriptHttpsClient.CheckURI (Sender: TObject; const ASrc: String; var ADest: String);
var newURI     : TURI;
    OriginalURI: TURI;
begin
   newURI := ParseURI (ADest, False);
   if (newURI.Host = '') then begin                         // NewURI does not contain protocol or host
      OriginalURI          := ParseURI (ASrc, False);       // use the original URI...
      OriginalURI.Path     := newURI.Path;                  // ... with the new subpage (path)...
      OriginalURI.Document := newURI.Document;              // ... and the new document info...
      ADest                := EncodeURI (OriginalURI)       // ... and return the complete redirected URI
   end
end;

procedure auf_https_get(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    client:TFPHTTPClient;
    arv:TAufRamVar;
    url:string;
    response:TStringList;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToARV(1, 1, High(Dword), [ARV_Char], arv) then exit;
  if not AAuf.TryArgToString(2, url) then exit;
  client:=TFPHTTPClient.Create(nil);
  response:=TStringList.Create;
  try
    try
      client.AllowRedirect:=true;
      client.OnRedirect:=@(AufScriptHttpClient.CheckURI);
      client.AddHeader('User-Agent','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36');
      client.Get(EncodeURLElement(url), response);
      initiate_arv_str(response.Text, arv);
    except
      initiate_arv_str('', arv);
      AufScpt.send_error(Format('警告：http访问错误（%d）',[client.ResponseStatusCode]),AufsErr_RunTime);
    end;
  finally
    client.Free;
    response.Free;
  end;
end;

procedure FuncDefineHTTP(Sender:TObject);
var AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AufScpt.add_func('http.get',  @auf_https_get,  'RESULT, url',   '网络访问url并将结果存到RESULT');

end;

initialization

  TAufScript.DoFuncDefineHTTP:=@FuncDefineHTTP;
  AufScriptHttpClient:=TAufScriptHttpsClient.Create;

finalization

end.

