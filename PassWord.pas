unit PASSWORD;

interface

uses Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Forms,
  Vcl.Controls, Vcl.StdCtrls, Vcl.Buttons, MSURTESettings, IdHashMessageDigest;

type
  TPasswordDlg = class(TForm)
    Label1: TLabel;
    Password: TEdit;
    OKBtn: TButton;
    CancelBtn: TButton;
    procedure OKBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  PasswordDlg: TPasswordDlg;

implementation
uses WatchWindowUnit,frmMainUnit;
{$R *.dfm}

procedure TPasswordDlg.FormShow(Sender: TObject);
begin
  Password.Clear;
  Password.SetFocus;
end;

procedure TPasswordDlg.OKBtnClick(Sender: TObject);
var
  ControlStr : String;
  inpStr : String;
begin
  ModalResult := mrCancel;
  if not Assigned(frmMSURTEMain) then Exit;
  ControlStr := frmMSURTEMain.msu5RTECore.MSURTESettings.AdmModePass;
  with TIdHashMessageDigest5.Create do
  try
    inpStr := Password.Text;
    inpStr := LowerCase(inpStr);
    inpStr := LowerCase(HashStringAsHex(inpStr));
    if ControlStr.Equals(inpStr) then
    begin
      ModalResult := mrOk;
      frmMSURTEMain.msu5RTECore.AppLogger.AddInfoMessage('¬веден корректный пароль дл€ доступа к режиму изменени€ тэгов.');
    end
    else
    begin
      frmMSURTEMain.msu5RTECore.AppLogger.AddInfoMessage('¬веден некорректный пароль дл€ доступа к режиму изменени€ тэгов.');
    end;
  finally
    Free;
  end;
end;

end.

