unit auftask_msg_manager;

{$mode ObjFPC}{$H+}

interface

uses
    Classes, SysUtils,
    fpjson;

type

    TAufTaskClientId = TGuid;

    //连接到的任务客户端
    TAufTaskClient = class
    public
        TaskId    :TAufTaskClientId;
        Name      :string;
        Prompt    :string; //任务的呼号，发送消息时只有拥有正确的呼号才会发送给该任务
        TaskToken :string; //主动登出所需的凭证
    private
        TimeLogin     :TDateTime; //登陆的时间
        TimeLastSend  :TDateTime; //最后一次发送消息的时间
        TimeLastFetch :TDateTime; //最后一次拉取消息的时间
    end;

    TAufTaskPool = class
    private
        FTaskList : TStringList;
    public
        function GetTaskClient(TaskId:TAufTaskClientId):TAufTaskClient;
        function AddTaskClient(TaskId:TAufTaskClientId):TAufTaskClient;
        function DelTaskClient(TaskId:TAufTaskClientId):boolean;
    public
        function GetTaskListJSON:TJSONData;
        function GenOutKey:string;
    public
        constructor Create;
        destructor Destroy; override;
    end;

    TAufTaskMessage = class
    public
        Sender :TAufTaskClientId;
        Target :TAufTaskClientId;
        Data   :string;
        Code   :integer;
    private
        TimeSending   :TDateTime;
        TimeReceiving :TDateTime;
    end;

    TAufTaskMessagePool = class
    private
        FMessageList : TList;
        FCount       : Integer;
        FTrimNil     : Integer;
    public
        function PushMessage(ASender,ATarget:TAufTaskClientId;AData:string;ACode:Integer):TAufTaskMessage;
        function PopMessage(ATarget:TAufTaskClientId):TAufTaskMessage; //从符合条件的消息中返回最早的一条，并移除，没有任何消息则返回nil
    public
        procedure Maintenance; //更新FTrimNil的位置和Count计数，并在nil过多时整理列表
        constructor Create;
        destructor Destroy; override;
    end;

implementation

{ TAufTaskPool }

function TAufTaskPool.GetTaskClient(TaskId:TAufTaskClientId):TAufTaskClient;
var guid_text:string;
    idx:integer;
begin
    guid_text:=GUIDToString(TaskId);
    if FTaskList.Find(guid_text, idx) then begin
        result:=TAufTaskClient(FTaskList.Objects[idx]);
    end else begin
        result:=nil; //找不到就返回nil
    end;
end;

function TAufTaskPool.AddTaskClient(TaskId:TAufTaskClientId):TAufTaskClient;
var guid_text:string;
    idx:integer;
begin
    guid_text:=GUIDToString(TaskId);
    if FTaskList.Find(guid_text, idx) then begin
        result:=nil; //已存在就返回nil
    end else begin
        result:=TAufTaskClient.Create;
        result.TaskId:=TaskId;
        FTaskList.AddObject(GUIDToString(TaskId), result);
    end;
end;

function TAufTaskPool.DelTaskClient(TaskId:TAufTaskClientId):boolean;
var guid_text:string;
    idx:integer;
begin
    guid_text:=GUIDToString(TaskId);
    if FTaskList.Find(guid_text, idx) then begin
        FTaskList.Delete(idx);
        result:=true;  //删除成功返回true
    end else begin
        result:=false; //并没有执行删除，返回false
    end;
end;

function TAufTaskPool.GetTaskListJSON:TJSONData;
var idx,len:integer;
    tmpTask:TAufTaskClient;
    tmpTaskObject:TJSONObject;
begin
    result:=TJSONArray.Create;
    len:=FTaskList.Count;
    for idx:=0 to len-1 do begin
        tmpTask:=TAufTaskClient(FTaskList.Objects[idx]);
        tmpTaskObject:=TJSONObject.Create;
        tmpTaskObject.Strings['name']:=tmpTask.Name;
        tmpTaskObject.Strings['guid']:=GUIDToString(tmpTask.TaskId);
        TJSONArray(result).Add(tmpTaskObject);
    end;
end;

function TAufTaskPool.GenOutKey:string;
var a,b,c,d:dword;
begin
    a:=Random(High(dword));
    b:=Random(High(dword));
    c:=Random(High(dword));
    d:=Random(High(dword));
    result:=Format('%.08X%.08X%.08X%.08X',[a,b,c,d]);
end;

constructor TAufTaskPool.Create;
begin
    inherited Create;
    FTaskList:=TStringList.Create;
    FTaskList.Sorted:=true;
end;

destructor TAufTaskPool.Destroy;
var idx:integer;
begin
    for idx:=FTaskList.Count-1 downto 0 do TAufTaskClient(FTaskList.Objects[idx]).Free;
    FTaskList.Free;
end;


{ TAufTaskMessagePool }

function TAufTaskMessagePool.PushMessage(ASender,ATarget:TAufTaskClientId;AData:string;ACode:Integer):TAufTaskMessage;
var tmpMsg:TAufTaskMessage;
begin
    tmpMsg:=TAufTaskMessage.Create;
    with tmpMsg do begin
        Target:=ATarget;
        Sender:=ASender;
        Data:=AData;
        Code:=ACode;
        //TimeSending:=0;
        TimeReceiving:=Now();
    end;
    FMessageList.Add(tmpMsg);
    inc(FCount);
end;

function TAufTaskMessagePool.PopMessage(ATarget:TAufTaskClientId):TAufTaskMessage;
var idx,len:integer;
    tmpMsg:TAufTaskMessage;
begin
    idx:=FTrimNil;
    len:=FMessageList.Count;
    for idx:=FTrimNil to len-1 do begin
        tmpMsg:=TAufTaskMessage(FMessageList[idx]);
        if tmpMsg=nil then continue;
        if not IsEqualGUID(tmpMsg.Target,ATarget) then continue;
        result:=tmpMsg;
        FMessageList[idx]:=nil;
        dec(FCount);
        if idx=FTrimNil then Maintenance;
        exit;
    end;
    result:=nil;
end;

procedure TAufTaskMessagePool.Maintenance; unimplemented;
begin

end;

constructor TAufTaskMessagePool.Create;
begin
    inherited Create;
    FMessageList:=TList.Create;
    FCount:=0;
    FTrimNil:=0;
end;

destructor TAufTaskMessagePool.Destroy;
var idx:integer;
begin
    for idx:=FMessageList.Count-1 downto 0 do TAufTaskMessage(FMessageList[idx]).Free;
    FMessageList.Free;
    inherited Destroy;
end;

end.

