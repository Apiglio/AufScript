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
        TaskId :TAufTaskClientId;
        Name   :string;
        Prompt :string; //任务的呼号，发送消息时只有拥有正确的呼号才会发送给该任务
        OutKey :string; //主动登出所需的凭证
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
    public
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

end.

