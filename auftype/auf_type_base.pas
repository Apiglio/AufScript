unit auf_type_base;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  auf_ram_var;

type

  TAufBaseError = Exception;
  TAufTypeError = Exception;

  TAufBase = class(TObject)
  protected
    FARV:TAufRamVar;
  public
    property ARV:TAufRamVar read FARV;
  public
    procedure Assign(ASource:TAufBase); virtual;
    function Equal(ACompare:TAufBase):boolean; virtual;
    function Copy:TAufBase; virtual;
  public
    constructor Create;
    constructor CreateAsARV(value:TAufRamVar);
    constructor CreateAsFixnum(value:integer);
    constructor CreateAsDouble(value:double);
    constructor CreateAsString(value:string);
    destructor Destroy; override;
  public
    class function AufTypeName:string; virtual;
    class var Class_InstanceList:TList;                             //实例列表地址会发生变化
    class function ClassInstancesCount:Integer; virtual;             //返回自身实例数
    class function TotalInstancesCount:Integer; virtual;             //返回自身及所有子类实例数
    class function ClearClassInstances:boolean; virtual;             //释放自身的实例
    class function ClearTotalInstances:boolean; virtual;             //释放自身及所有子类的实例
    class constructor CreateClass;
    class destructor DestoryClass;
  protected
    function GetLargeInt:int64;
    procedure SetLargeInt(value:int64);
    function GetInteger:integer;
    procedure SetInteger(value:integer);
    function GetFloat:double;
    procedure SetFloat(value:double);
    function GetString:string;
    procedure SetString(value:string);

  public
    property AsLargeInt:int64 read GetLargeInt write SetLargeInt;
    property AsInteger:integer read GetInteger write SetInteger;
    property AsFloat:double read GetFloat write SetFloat;
    property AsString:string read GetString write SetString;
  end;

  TAufBaseClass = class of TAufBase;

  function CreateAufTypeByText(syntax:string):TAufBase;

implementation
uses auf_type_array;

function CreateAufTypeByText(syntax:string):TAufBase;
var itmp:int64;
    idx,codee:integer;
    ftmp:double;
    stmp:string;
    he,hd:boolean;
begin
  //type priority: integer float string
  //临时的方法，之后用语法树来实现，数组之类的先不实现
  result:=nil;
  if syntax='' then exit;
  if syntax[1]+syntax[length(syntax)]='""' then begin
    stmp:=syntax;
    if length(stmp)<2 then exit;
    delete(stmp,length(stmp),1);
    delete(stmp,1,1);
    result:=TAufBase.CreateAsString(stmp);
    exit;
  end;
  he:=false;
  hd:=false;
  for idx:=1 to length(syntax) do begin
    if syntax[idx] in ['e','E'] then he:=true;
    if syntax[idx]='.' then hd:=true;
  end;
  if he or hd then begin
    try
      ftmp:=StrToFloat(syntax);
      result:=TAufBase.CreateAsDouble(ftmp);
    except
      //
    end;
  end else begin
    val(syntax,itmp,codee);
    if codee<=0 then begin
      result:=TAufBase.CreateAsFixnum(itmp);
    end;
  end;
end;

{ TAufBase }

constructor TAufBase.Create;
begin
  FARV.VarType:=ARV_Raw;
  FARV.size:=0;
  FARV.Head:=nil;
  Class_InstanceList.Add(Self);
end;

constructor TAufBase.CreateAsARV(value:TAufRamVar);
begin
  Create;
  with FARV do begin
    size:=value.size;//默认int64，可变长度
    VarType:=value.VarType;
    Is_Temporary:=false;
    GetMem(Head,size);
  end;
  copyARV(value,FARV);
end;

constructor TAufBase.CreateAsFixnum(value:integer);
begin
  Create;
  with FARV do begin
    size:=8;//默认int64，可变长度
    VarType:=ARV_FixNum;
    Is_Temporary:=false;
    GetMem(Head,size);
    dword_to_arv(value,FARV);
  end;
end;

constructor TAufBase.CreateAsDouble(value:double);
begin
  Create;
  with FARV do begin
    size:=8;//默认int64，可变长度
    VarType:=ARV_Float;
    Is_Temporary:=false;
    GetMem(Head,size);
    double_to_arv(value,FARV);
  end;
end;

constructor TAufBase.CreateAsString(value:string);
var len:integer;
begin
  Create;
  len:=length(value);
  if len<8 then len:=8;
  with FARV do begin
    size:=len;
    VarType:=ARV_Char;
    Is_Temporary:=false;
    GetMem(Head,size);
    s_to_arv(value,FARV);
  end;
end;

destructor TAufBase.Destroy;
begin
  if FARV.Head<>nil then FreeMem(FARV.Head,FARV.size);
  Class_InstanceList.Remove(Self);
  inherited Destroy;
end;

class function TAufBase.AufTypeName:string;
begin
  result:='base';
end;

class function TAufBase.ClassInstancesCount:Integer;
var idx:integer;
begin
  result:=0;
  for idx:=Class_InstanceList.Count-1 downto 0 do
    if TObject(Class_InstanceList.Items[idx]).ClassType = Self then inc(result);
end;

class function TAufBase.TotalInstancesCount:Integer;
var idx:integer;
begin
  result:=0;
  for idx:=Class_InstanceList.Count-1 downto 0 do
    if TObject(Class_InstanceList.Items[idx]) is Self then inc(result);
end;

class function TAufBase.ClearClassInstances:boolean;
var idx:integer;
    new_list:Tlist;
    tmp_obj:TObject;
begin
  new_list:=TList.Create;
  for idx:=Class_InstanceList.Count-1 downto 0 do begin
    tmp_obj:=TObject(Class_InstanceList.Items[idx]);
    if tmp_obj.ClassType = Self then begin
      tmp_obj.Free;
    end else begin
      new_list.Add(tmp_obj);
    end;
  end;
  Class_InstanceList.Free;
  Class_InstanceList:=new_list;
end;

class function TAufBase.ClearTotalInstances:boolean;
var idx:integer;
    new_list:Tlist;
    tmp_obj:TObject;
begin
  new_list:=TList.Create;
  for idx:=Class_InstanceList.Count-1 downto 0 do begin
    tmp_obj:=TObject(Class_InstanceList.Items[idx]);
    if tmp_obj is Self then begin
      tmp_obj.Free;
    end else begin
      new_list.Add(tmp_obj);
    end;
  end;
  Class_InstanceList.Free;
  Class_InstanceList:=new_list;
end;

class constructor TAufBase.CreateClass;
begin
  Class_InstanceList:=TList.Create;
end;

class destructor TAufBase.DestoryClass;
begin
  Class_InstanceList.Free;
end;

procedure TAufBase.Assign(ASource:TAufBase);
begin
  with Self.FARV do begin
    if head<>nil then FreeMem(head,size);
    VarType:=ASource.FARV.VarType;
    size:=ASource.FARV.size;
    Head:=GetMem(size);
    //Move(ASource.FARV.Head,head,size);
    copyARV(ASource.FARV,FARV);
  end;
end;

function TAufBase.Equal(ACompare:TAufBase):boolean;
begin
  result:=false;
  if FARV.VarType<>ACompare.FARV.VarType then exit;
  result:=ARV_comp(FARV,ACompare.FARV)=0;
end;

function TAufBase.Copy:TAufBase;
begin
  result:=TAufBase.Create;
  result.Assign(Self);
end;

function TAufBase.GetLargeInt:int64;
begin
  case FARV.VarType of
    ARV_FixNum:result:=arv_to_qword(FARV);
    else raise TAufBaseError.Create('TAufBase.GetLargeInt: FARV.VarType <> ARV_FixNum.');
  end;
end;

procedure TAufBase.SetLargeInt(value:int64);
begin
  case FARV.VarType of
    ARV_FixNum:qword_to_arv(value,FARV);
    else raise TAufBaseError.Create('TAufBase.GetLargeInt: FARV.VarType <> ARV_FixNum.');
  end;
end;

function TAufBase.GetInteger:integer;
begin
  case FARV.VarType of
    ARV_FixNum:result:=arv_to_dword(FARV);
    else raise TAufBaseError.Create('TAufBase.GetInteger: FARV.VarType <> ARV_FixNum.');
  end;
end;

procedure TAufBase.SetInteger(value:integer);
begin
  case FARV.VarType of
    ARV_FixNum:dword_to_arv(value,FARV);
    else raise TAufBaseError.Create('TAufBase.GetInteger: FARV.VarType <> ARV_FixNum.');
  end;
end;

function TAufBase.GetFloat:double;
begin
  case FARV.VarType of
    ARV_Float:result:=arv_to_double(FARV);
    else raise TAufBaseError.Create('TAufBase.GetFloat: FARV.VarType <> ARV_Float.');
  end;
end;

procedure TAufBase.SetFloat(value:double);
begin
  case FARV.VarType of
    ARV_Float:double_to_arv(value,FARV);
    else raise TAufBaseError.Create('TAufBase.GetFloat: FARV.VarType <> ARV_Float.');
  end;
end;

function TAufBase.GetString:string;
begin
  case FARV.VarType of
    ARV_Char:result:=arv_to_s(FARV);
    else raise TAufBaseError.Create('TAufBase.GetString: FARV.VarType <> ARV_Char.');
  end;
end;

procedure TAufBase.SetString(value:string);
begin
  case FARV.VarType of
    ARV_Char:initiate_arv_str(value,FARV);
    else raise TAufBaseError.Create('TAufBase.GetString: FARV.VarType <> ARV_Char.');
  end;
end;


end.

