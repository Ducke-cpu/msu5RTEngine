program msu5RTEngine;

uses
  Vcl.Forms,
  frmMainUnit in 'frmMainUnit.pas' {frmMSURTEMain},
  MSURTESettings in 'MSURTESettings.pas',
  MSUCore in 'MSUCore.pas',
  msu5RTEOPCSrv in 'msu5RTEOPCSrv.pas',
  DummyUnit in 'DummyUnit.pas',
  msu2FenceUnit in 'msu2FenceUnit.pas',
  WatchWindowUnit in 'WatchWindowUnit.pas' {frmWatchWindow},
  TagManagerUnit in 'TagManagerUnit.pas' {frmTagManager},
  prObjInit in 'C:\0_0MSU5\Apps\Common\prObjInit.pas',
  PassWord in 'PassWord.pas' {PasswordDlg},
  chgPass in 'chgPass.pas' {dlgChgPass};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMSURTEMain, frmMSURTEMain);
  Application.Run;
end.
