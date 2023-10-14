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
    procedure Assign(ASource:TAufBase);
    function Equal(ACompare:TAufBase):boolean;
  public
    constructor Create;
    constructor CreateAsFixnum(value:integer);
    destructor Destroy;override;
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


implementation

{ TAufBase }

constructor TAufBase.Create;
begin
  FARV.VarType:=ARV_Raw;
  FARV.size:=0;
end;

constructor TAufBase.CreateAsFixnum(value:integer);
begin
  //inherited Create;
  Create;
  with FARV do begin
    size:=8;//默认int64，可变长度
    VarType:=ARV_FixNum;
    Is_Temporary:=false;
    GetMem(Head,size);
    FillByte(head,size,0);
  end;
end;

destructor TAufBase.Destroy;
begin
  FreeMem(FARV.Head,FARV.size);
  inherited Destroy;
end;

procedure TAufBase.Assign(ASource:TAufBase);
begin
  with Self.FARV do begin
    if size<>0 then FreeMem(head,size);
    VarType:=ASource.FARV.VarType;
    size:=ASource.FARV.size;
    Head:=GetMem(size);
    Move(ASource.FARV.Head,head,size);
  end;
end;

function TAufBase.Equal(ACompare:TAufBase):boolean;
begin
  result:=false;
  if FARV.VarType<>ACompare.FARV.VarType then exit;
  result:=ARV_comp(FARV,ACompare.FARV)=0;
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
    else raise TAufBaseError.Create('TAufBase.GetLargeInt: FARV.VarType <> ARV_FixNum.');
  end;
end;

procedure TAufBase.SetInteger(value:integer);
begin
  case FARV.VarType of
    ARV_FixNum:dword_to_arv(value,FARV);
    else raise TAufBaseError.Create('TAufBase.GetLargeInt: FARV.VarType <> ARV_FixNum.');
  end;
end;

function TAufBase.GetFloat:double;
begin
  case FARV.VarType of
    ARV_Float:result:=arv_to_double(FARV);
    else raise TAufBaseError.Create('TAufBase.GetLargeInt: FARV.VarType <> ARV_Float.');
  end;
end;

procedure TAufBase.SetFloat(value:double);
begin
  case FARV.VarType of
    ARV_Float:double_to_arv(value,FARV);
    else raise TAufBaseError.Create('TAufBase.GetLargeInt: FARV.VarType <> ARV_Float.');
  end;
end;

function TAufBase.GetString:string;
begin
  case FARV.VarType of
    ARV_Char:result:=arv_to_s(FARV);
    else raise TAufBaseError.Create('TAufBase.GetLargeInt: FARV.VarType <> ARV_Char.');
  end;
end;

procedure TAufBase.SetString(value:string);
begin
  case FARV.VarType of
    ARV_Char:initiate_arv_str(value,FARV);
    else raise TAufBaseError.Create('TAufBase.GetLargeInt: FARV.VarType <> ARV_Char.');
  end;
end;


end.

