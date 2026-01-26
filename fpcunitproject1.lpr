program fpcunitproject1;

{$define GUI_TEST}
{$ifdef GUI_TEST}
  //{$apptype GUI}
  {$define AufFrame}
{$else}
  {$apptype console}
{$endif}

{$mode objfpc}{$H+}

uses
  {$ifdef UNIX}
  cthreads,
  {$endif}
  {$ifdef WINDOWS}
  Windows,
  {$endif}
  Classes, StdCtrls, ExtCtrls, Sysutils, Forms, consoletestrunner, Interfaces,
  Controls, Dialogs, LazUTF8, Apiglio_Useful, auf_ram_var, aufscript_frame,
  aufscript_command, auf_ram_syntax, auf_ram_image, aufscript_thread,
  auf_type_array, auf_type_base, word_tree, svo_tree, auf_type_parser;

type

  {$ifdef GUI_TEST}
  TMyTestForm = class(TForm)
  published
    {$ifdef AufFrame}
    AufFrame:TFrame_AufScript;
    {$else}
    AufMemo:TMemo_AufScript;
    {$endif}
  public
    constructor CreateNew(AOwner:TComponent);
    procedure InitializeForm;
    procedure ResizeForm(Sender:TObject);
    procedure FormDestroy(Sender:TObject);
  public
    procedure test;
    procedure ChangeMainTitle(Sender:TObject;str:string);
  end;

  {$else}
  { TLazTestRunner }
  TMyTestRunner = class(TTestRunner)
  protected
  // override the protected methods of TTestRunner to customize its behavior
  end;
  {$endif}


var
  {$ifdef GUI_TEST}
     Application:TApplication;
     Test_Form:TMyTestForm;
  {$else}
     Application: TMyTestRunner;
  {$endif}
  i:integer;
  b:byte;
  fptr:pFuncFileByte;
  ts:TStringlist;
  ptr:pointer;
  s:string;
  v1,v2:TAufRamVar;



procedure project_test(Sender:TObject);
var tmp,tmp2,oup,oup2:TAufRamVar;
    AufScpt:TAufScript;
    AAuf:TAuf;
    tmpNode:TWordTreeNode;
    tmpP:Pointer;
    arr:TAufArray;
    dw1,dw2,dw3:dword;
    subcode:string;
    cy_n_br:int16;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;

  //AufScpt.writeln('arv_to_dec_fraction:'+arv_to_dec_fraction(AufScpt.RamVar(AAuf.nargs[1])));
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToStrParam(1,['add','sub','mul','div','rem','fsc','fadd','fsub','fmul','fdiv','fcmp'],false,subcode) then exit;
  if not AAuf.TryArgToARV(2,1,high(QWord),[ARV_FixNum, ARV_Float],tmp) then exit;
  if not AAuf.TryArgToARV(3,1,high(QWord),[ARV_FixNum, ARV_Float],tmp2) then exit;

  newARV(oup, tmp.size);
  newARV(oup2, tmp.size);
  case lowercase(subcode) of
    'add':fixnum_add(tmp,tmp2,oup,cy_n_br);
    'sub':fixnum_sub(tmp,tmp2,oup,cy_n_br);
    'mul':fixnum_mul(tmp,tmp2,oup);
    'div':fixnum_div(tmp,tmp2,oup,oup2);
    'rem':fixnum_div(tmp,tmp2,oup,oup2);
    'fsc':ARV_floating_scaling(tmp,tmp2);
    'fadd':float_add(tmp,tmp2,oup);
    'fsub':float_sub(tmp,tmp2,oup);
    'fmul':float_mul(tmp,tmp2,oup);
    'fdiv':float_div(tmp,tmp2,oup);
    'fcmp':AufScpt.writeln(IntToStr(ARV_floating_comp(tmp,tmp2)));
  end;
  case lowercase(subcode) of
    'rem':copyARV(oup2, tmp);
    'fsc':{do-nothing};
    'fcmp':{do-nothing};
    else copyARV(oup, tmp);
  end;
  freeARV(oup);
  freeARV(oup2);

  exit;

  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToAufArray(1,arr) then exit;
  AufScpt.writeln(arr.ToString);
  arr.Free;

  exit;

  tmpNode:=TWordTreeNode.Create;
  try
    tmpNode['BB']:=pchar('BB');
    tmpNode['ASS']:=pchar('ASS');
    tmpNode['func_o']:=pchar('func_o');
    tmpNode['func_new']:=pchar('func_new');
    tmpNode['test']:=pchar('test');
    tmpNode['test2']:=pchar('test2');
    for tmpP in tmpNode do AufScpt.writeln(PChar(tmpP))
  finally
    tmpNode.Free;
  end;

end;


{$ifdef GUI_TEST}
{ TMyTestForm }
procedure TMyTestForm.test;
begin
  //MessageBox(0,'TEST:OK','TEST',MB_OK);
  ShowMessage('TEST');
end;
procedure TMyTestForm.ChangeMainTitle(Sender:TObject;str:string);
begin
  Self.Caption:=str;
end;
procedure TMyTestForm.InitializeForm;
begin
  Self.Caption:='Auf GUI Tester';
  Self.Width:=600;
  Self.Height:=360;
  Self.Position:=poScreenCenter;
  Self.Show;
  {$ifndef AufFrame}
  AufMemo:=TMemo_AufScript.Create(Self);
  AufMemo.Parent:=Self;
  AufMemo.Auf.Script.add_func('ptest',@project_test,'','测试');
  {$else}
  AufFrame:=TFrame_AufScript.Create(Self);
  AufFrame.Parent:=Self;
  //AufFrame.Portrait:=true;
  AufFrame.FrameResize(nil);
  AufFrame.AufGenerator;
  AufFrame.Auf.Script.add_func('ptest',@project_test,'','测试');
  AufFrame.OnChangeTitle:=@ChangeMainTitle;
  {$endif}
  Self.ResizeForm(nil);
  Self.OnResize:=@Self.ResizeForm;
  Self.OnDestroy:=@Self.FormDestroy;



end;
constructor TMyTestForm.CreateNew(AOwner:TComponent);
begin
  inherited CreateNew(AOwner);
  Self.InitializeForm;
end;
procedure TMyTestForm.ResizeForm(Sender:TObject);
var gap:word;//通用间隔

begin
  gap:=6;
  {$ifndef AufFrame}
  Self.AufMemo.Width:=Self.Width-2*gap;
  Self.AufMemo.Height:=Self.Height-2*gap;
  Self.AufMemo.Left:=gap;
  Self.AufMemo.Top:=gap;
  {$else}
  {
  Self.AufFrame.Width:=Self.Width-2*gap;
  Self.AufFrame.Height:=Self.Height-2*gap;
  Self.AufFrame.Left:=gap;
  Self.AufFrame.Top:=gap;
  }
  Self.AufFrame.Align:=alClient;
  Self.AufFrame.FrameResize(nil);

  {$endif}

end;
procedure TMyTestForm.FormDestroy(Sender:TObject);
begin
  //Application.Terminate;
  Halt;
end;

{$endif}



procedure test(str:string);
begin
  writeln(str);
end;

BEGIN
  {$ifdef GUI_TEST}
  Application:=TApplication.Create(nil);
  Application.Initialize;
  Application.CreateForm(TMyTestForm,Test_Form);

  {$ifndef AufFrame}
  ///////////////////////////////
  {$endif}
  Test_Form.InitializeForm;
  Application.Run;
  {$else}
  Application := TMyTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'FPCUnit Console test runner';

  Auf.Free;
  Auf:=TAuf.Create(nil);
  Auf.Script.InternalFuncDefine;
  Auf.Script.add_func('ptest',@project_test,'','测试');


  writeln;
  writeln;
  writeln;
  writeln;


  //这一段介绍Auf.ReadArg(str)返回的Auf对象之下的ArgsCount,divi,iden,toto,args[]和nargs[]属性
  Auf.ReadArgs('addb $2,1,"(345,234,12)",@112~,$"S#@FA|@",?"134<<2+22<<4",?"$12[33]",&&"sasde??s"$$,&"@@@@@@@@A"');
  //for i:=0 to args_range-1 do writeln('Auf.args[',i,']=',Auf.args[i]);
  for i:=0 to args_range-1 do
    begin
      write('Auf.nargs[',i,']=',Auf.nargs[i].pre);
      write(utf8toansi('囗'),Auf.nargs[i].arg);
      writeln(utf8toansi('囗'),Auf.nargs[i].post);
    end;
  writeln('zeroplus=',Usf.zeroplus(1234,5));
  writeln('Auf.divi=',Auf.divi);
  writeln('Auf.iden=',Auf.iden);
  writeln('Auf.toto=',Auf.toto);
  writeln('Auf.ArgsCount=',Auf.ArgsCount);

  writeln(isprintable('<WWF#$'));
  writeln(isprintable('WWF#$'));
  writeln(isprintable('<W:WF#$'));
  writeln(isprintable('WW5236,.;F#$'));

  Auf.Script.command('help');
  Auf.Script.command('echoln "English Test"');
  Auf.Script.command('echoln "中文测试"');
  Auf.Script.command('mov #8[0] "中文测试"');
  Auf.Script.command('println #8[0]');
  writeln('----------------------');
  writeln;
  writeln;
  writeln;

  ts:=TStringList.Create;
  //ts.add('mov $1,0');
  //ts.add('aa:');
  //ts.add('add $1,1');
  //ts.add('echo "<"');
  //ts.add('print $1');
  //ts.add('echoln ">" ');
  //ts.add('ncje $1,10,:aa');
  //ts.add('nife $1,10,:aa');
  //ts.add('echoln 44444');
  //ts.add('sqrt $1');
  //ts.add('cwln');
  //ts.add('end');

  //ts.add('mov @0,1234');
  //ts.add('mov @4,12345');
  //ts.add('test $"@@@@@@@@|@D",$"@@@@@@@D|@D"');
  //ts.add('end');


  //以下是内存区置零代码
  {
  ts.Add('mov,@0,32');
  ts.Add('loo:');
  ts.Add('mov $32{0},0000H');
  ts.Add('add @0,32');
  ts.Add('cjl @0,'+Usf.i_to_s(ram_range*256)+',:loo');
  ts.Add('mov $32[0],0000H');
  ts.Add('echoln "done"');
  ts.Add('end');
  }
  //以下是检测高运算次数可行性的代码
  {
  ts.Add('mov @0,0');
  ts.Add('loo:');
  ts.Add('mov @4,@0');
  ts.Add('mod @4,4096');
  ts.Add('ncje @4,0,:skip');
  ts.Add('echoln @0');
  ts.Add('skip:');
  ts.Add('add @0,1');
  ts.Add('jmp :loo');
  }

  Auf.Script.command(ts);

  {
  Usf.fassign('1.txt');
  Usf.freset('1.txt');
  Usf.fwrites('1.txt',4,'aaaaaaaa');
  Usf.fclose('1.txt');
  }

  for i:=0 to ts.Count-1 do
  writeln(ts.Strings[i]);

  writeln('----------------------');
  while true do begin
    write('AufScript>');readln(s);
    Auf.Script.command(s);
    writeln;
  end;

  //////////////////
  //fptr:=@test;
  //Usf.each_file('F:\temp',fptr);
  //////////////////
  readln;

  Application.Run;
  Application.Free;
  {$endif}

END.
