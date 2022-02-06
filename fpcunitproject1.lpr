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
  Classes, StdCtrls, ExtCtrls, Sysutils, Forms, consoletestrunner, Interfaces,
  LazUTF8, Windows, Apiglio_Useful, auf_ram_var, aufscript_frame, aufscript_command;

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
var tmp:TAufRamVar;
    AufScpt:TAufScript;
    AAuf:TAuf;
    re1,re2,res:TRealStr;
    integ,fract:TDecimalStr;
    sgn:char;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;

  AufScpt.writeln('arv_to_dec_fraction:'+arv_to_dec_fraction(AufScpt.RamVar(AAuf.nargs[1])));
  {
  try
    re1.data:=AufScpt.TryToString(AAuf.nargs[1]);
  except
    AufScpt.send_error('Cannot convert to string');
  end;
  try
    re2.data:=AufScpt.TryToString(AAuf.nargs[2]);
  except
    AufScpt.send_error('Cannot convert to string');
  end;
  }
  //AufScpt.writeln(IntToStr(RealStr_Comp(re1,re2)));
  //res:=RealStr_Abs_Add(re1,re2);
  //res:=RealStr_Abs_Sub(re1,re2);
  //res:=RealStr_Abs_Mul(re1,re2);
  //res:=RealStr_Abs_Div(re1,re2,32);
  //AufScpt.writeln(res.data);

  //AufScpt.writeln(IntToStr(numberic_check(AAuf.args[1])));
end;


{$ifdef GUI_TEST}
{ TMyTestForm }
procedure TMyTestForm.test;
begin
  MessageBox(0,'TEST:OK','TEST',MB_OK);
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
  Self.AufFrame.Width:=Self.Width-2*gap;
  Self.AufFrame.Height:=Self.Height-2*gap;
  Self.AufFrame.Left:=gap;
  Self.AufFrame.Top:=gap;
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
