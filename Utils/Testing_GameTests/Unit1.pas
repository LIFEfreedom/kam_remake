unit Unit1;
{$I KaM_Remake.inc}
interface
uses
  Forms, Controls, StdCtrls, Spin, ExtCtrls, Classes, SysUtils, Graphics, Types, Math, Windows,
  Unit_Runner, KM_RenderControl,
  {$IFDEF WDC} Vcl.ComCtrls {$ELSE} ComCtrls {$ENDIF};


type
  TForm2 = class(TForm)
    btnRun: TButton;
    seCycles: TSpinEdit;
    Label1: TLabel;
    ListBox1: TListBox;
    Label2: TLabel;
    PageControl1: TPageControl;
    TabSheet5: TTabSheet;
    moResults: TMemo;
    Render: TTabSheet;
    Panel1: TPanel;
    chkRender: TCheckBox;
    seDuration: TSpinEdit;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    seSeed: TSpinEdit;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    rgAIType: TRadioGroup;
    btnRunAll: TButton;
    btnStop: TButton;
    btnPause: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnRunAllClick(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnPauseClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    fResults: TKMRunResults;
    fRunTime: string;
    fStopped: Boolean;
    fPaused: Boolean;
    RenderArea: TKMRenderControl;
    function IsStopped: Boolean;
    function IsPaused: Boolean;
    procedure Testing_GameTestsProgress(const aValue: UnicodeString);
    procedure Testing_GameTestsProgress2(const aValue: UnicodeString);
    procedure Testing_GameTestsProgress3(const aValue: UnicodeString);
    procedure Testing_GameTestsProgress4(const aValue: UnicodeString);
    procedure Testing_GameTestsProgress5(const aValue: UnicodeString);
    procedure Testing_GameTestsProgress_Left(const aValue: UnicodeString);
    procedure Testing_GameTestsProgress_Left2(const aValue: UnicodeString);
    procedure Testing_GameTestsProgress_Left3(const aValue: UnicodeString);
  end;


var
  Form2: TForm2;


implementation
{$R *.dfm}
uses
  KM_GameTypes;


const
  COLORS_COUNT = 8;
  LineCol: array [0..COLORS_COUNT - 1] of TColor =
    (clRed, clBlue, clGreen, clPurple, clMaroon, clGray, clBlack, clOlive);


{$IFDEF FPC}
function Point(X,Y: Integer): TPoint;
begin
  Result.X := X;
  Result.Y := Y;
end;
{$ENDIF}


procedure TForm2.btnStopClick(Sender: TObject);
begin
  fStopped := True;
  btnStop.Enabled := False;
end;



procedure TForm2.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  RenderArea := TKMRenderControl.Create(Panel1);
  RenderArea.Parent := Panel1;
  RenderArea.Align := alClient;
  RenderArea.Color := clMaroon;

  for I := 0 to High(RunnerList) do
    ListBox1.Items.Append(RunnerList[I].ClassName);

  if Length(RunnerList) > 0 then
  begin
    ListBox1.ItemIndex := 0;
    btnRun.Enabled := True;
    btnRunAll.Enabled := True;
    btnStop.Enabled := False;
    btnPause.Enabled := False;
  end;

  Caption := ExtractFileName(Application.ExeName);
end;


procedure TForm2.FormShow(Sender: TObject);
const
  LEFT_PARAM = '-left';
  TOP_PARAM = '-top';
var
  I: Integer;
  val: Integer;
begin
  I := 1;
  while I <= ParamCount do
  begin
    if (paramstr(I) = LEFT_PARAM) then
    begin
      Inc(I);
      if TryStrToInt(paramstr(I), val) then
        Left := val;
    end;

    if (paramstr(I) = TOP_PARAM) then
    begin
      Inc(I);
      if TryStrToInt(paramstr(I), val) then
        Top := val;
    end;

    Inc(I);
  end;
end;


procedure TForm2.ListBox1Click(Sender: TObject);
var
  ID: Integer;
begin
  ID := ListBox1.ItemIndex;
  if ID = -1 then Exit;
  btnRun.Enabled := True;
  btnRunAll.Enabled := True;
  btnStop.Enabled := False;
  btnPause.Enabled := False;
end;





function TForm2.IsStopped: Boolean;
begin
  Result := fStopped;
end;


function TForm2.IsPaused: Boolean;
begin
  Result := fPaused;
end;


procedure TForm2.btnPauseClick(Sender: TObject);
begin
  fPaused := True;
  btnPause.Enabled := False;
end;


procedure TForm2.btnRunClick(Sender: TObject);
var
  T: Cardinal;
  ID, Count: Integer;
  Testing_GameTestsClass: TKMRunnerClass;
  Testing_GameTests: TKMRunnerCommon;
begin
  ID := ListBox1.ItemIndex;
  if ID = -1 then Exit;
  Count := seCycles.Value;
  if Count <= 0 then Exit;

  fStopped := False;

  btnRun.Enabled := False;
  btnStop.Enabled := True;
  btnPause.Enabled := False; //Always disabled for now
  try
    Testing_GameTestsClass := RunnerList[ID];

    if chkRender.Checked then
      Testing_GameTests := Testing_GameTestsClass.Create(RenderArea, {IsPaused, }IsStopped)
    else
      Testing_GameTests := Testing_GameTestsClass.Create(nil, {IsPaused, }IsStopped);

    Testing_GameTests.OnProgress := Testing_GameTestsProgress;
    Testing_GameTests.OnProgress_Left := Testing_GameTestsProgress_Left;
    Testing_GameTests.OnProgress_Left2 := Testing_GameTestsProgress_Left2;
    Testing_GameTests.OnProgress_Left3 := Testing_GameTestsProgress_Left3;
    Testing_GameTests.OnProgress2 := Testing_GameTestsProgress2;
    Testing_GameTests.OnProgress3 := Testing_GameTestsProgress3;
    Testing_GameTests.OnProgress4 := Testing_GameTestsProgress4;
    Testing_GameTests.OnProgress5 := Testing_GameTestsProgress5;
    try
      T := GetTickCount;
      Testing_GameTests.Duration := seDuration.Value;
      Testing_GameTests.Seed := seSeed.Value;
      if rgAIType.ItemIndex = 0 then
        Testing_GameTests.AIType := aitClassic
      else
        Testing_GameTests.AIType := aitAdvanced;

      fResults := Testing_GameTests.Run(Count);
      fRunTime := 'Done in ' + IntToStr(GetTickCount - T) + ' ms';
    finally
      Testing_GameTests.Free;
    end;
  finally
    btnRun.Enabled := True;
    btnRunAll.Enabled := True;
    btnStop.Enabled := False;
    btnPause.Enabled := False;
  end;
end;


procedure TForm2.btnRunAllClick(Sender: TObject);
var
  T: Cardinal;
  ID, Count: Integer;
  Testing_GameTestsClass: TKMRunnerClass;
  Testing_GameTests: TKMRunnerCommon;
  I: Integer;
  resStr: string;
begin
  Count := seCycles.Value;
  if Count <= 0 then Exit;

  fStopped := False;

  moResults.Clear;
  PageControl1.ActivePage := TabSheet5;

  btnRun.Enabled := False;
  btnRunAll.Enabled := False;
  btnStop.Enabled := True;
  btnPause.Enabled := False; //Always disabled for now

  for ID := 0 to High(RunnerList) do
  begin
    if fStopped then Break;

    Testing_GameTestsClass := RunnerList[ID];

    if chkRender.Checked then
      Testing_GameTests := Testing_GameTestsClass.Create(RenderArea, {IsPaused, }IsStopped)
    else
      Testing_GameTests := Testing_GameTestsClass.Create(nil, {IsPaused, }IsStopped);

    Testing_GameTests.OnProgress := Testing_GameTestsProgress;
    Testing_GameTests.OnProgress_Left := Testing_GameTestsProgress_Left;
    Testing_GameTests.OnProgress_Left2 := Testing_GameTestsProgress_Left2;
    Testing_GameTests.OnProgress_Left3 := Testing_GameTestsProgress_Left3;
    Testing_GameTests.OnProgress2 := Testing_GameTestsProgress2;
    Testing_GameTests.OnProgress3 := Testing_GameTestsProgress3;
    Testing_GameTests.OnProgress4 := Testing_GameTestsProgress4;
    Testing_GameTests.OnProgress5 := Testing_GameTestsProgress5;
    try
      T := GetTickCount;
      Testing_GameTests.Duration := seDuration.Value;
      Testing_GameTests.Seed := seSeed.Value;
      if rgAIType.ItemIndex = 0 then
        Testing_GameTests.AIType := aitClassic
      else
        Testing_GameTests.AIType := aitAdvanced;

      fResults := Testing_GameTests.Run(Count);
      
      for I := 0 to Count - 1 do
      begin
        case fResults.TestResults[I] of
          trSuccess: resStr := 'SUCCESS';
          trFailed: resStr := 'FAILED: ' + fResults.TestMessages[I];
          trException: resStr := 'EXCEPTION: ' + fResults.TestMessages[I];
        end;

        if Count > 1 then
          moResults.Lines.Append(Format('%s (Run %d): %s (%d ms)', [Testing_GameTestsClass.ClassName, I+1, resStr, GetTickCount - T]))
        else
          moResults.Lines.Append(Format('%s: %s (%d ms)', [Testing_GameTestsClass.ClassName, resStr, GetTickCount - T]));
      end;
    finally
      Testing_GameTests.Free;
    end;
    
    Application.ProcessMessages;
  end;

  btnRun.Enabled := True;
  btnRunAll.Enabled := True;
  btnStop.Enabled := False;
  btnPause.Enabled := False;
end;


procedure TForm2.Testing_GameTestsProgress(const aValue: UnicodeString);
begin
  Label2.Caption := aValue;
  Label2.Refresh;
  Application.ProcessMessages;
end;


procedure TForm2.Testing_GameTestsProgress2(const aValue: UnicodeString);
begin
  Label5.Caption := aValue;
  Label5.Refresh;
  Application.ProcessMessages;
end;


procedure TForm2.Testing_GameTestsProgress3(const aValue: UnicodeString);
begin
  Label6.Caption := aValue;
  Label6.Refresh;
  Application.ProcessMessages;
end;


procedure TForm2.Testing_GameTestsProgress4(const aValue: UnicodeString);
begin
  Label8.Caption := aValue;
  Label8.Refresh;
  Application.ProcessMessages;
end;


procedure TForm2.Testing_GameTestsProgress5(const aValue: UnicodeString);
begin
  Label12.Caption := aValue;
  Label12.Refresh;
  Application.ProcessMessages;
end;


procedure TForm2.Testing_GameTestsProgress_Left(const aValue: UnicodeString);
begin
  Label9.Caption := aValue;
  Label9.Refresh;
  Application.ProcessMessages;
end;


procedure TForm2.Testing_GameTestsProgress_Left2(const aValue: UnicodeString);
begin
  Label10.Caption := aValue;
  Label10.Refresh;
  Application.ProcessMessages;
end;


procedure TForm2.Testing_GameTestsProgress_Left3(const aValue: UnicodeString);
begin
  Label11.Caption := aValue;
  Label11.Refresh;
  Application.ProcessMessages;
end;

end.
