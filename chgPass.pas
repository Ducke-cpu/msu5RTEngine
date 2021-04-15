unit chgPass;

interface

uses Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Forms,
  Vcl.Controls, Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls, MSURTESettings, IdHashMessageDigest;

type
  TdlgChgPass = class(TForm)
    OKBtn: TButton;
    CancelBtn: TButton;
    lbValidPass: TLabel;
    edValidPass: TEdit;
    lbNewPass1: TLabel;
    edNewPass1: TEdit;
    lbNewPass2: TLabel;
    edNewPass2: TEdit;
    procedure OKBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  dlgChgPass: TdlgChgPass;

implementation
uses frmMainUnit;
{$R *.dfm}

procedure TdlgChgPass.FormShow(Sender: TObject);
begin
  edValidPass.Clear;
  edNewPass1.Clear;
  edNewPass2.Clear;
end;

procedure TdlgChgPass.OKBtnClick(Sender: TObject);
var
  ControlStr, inpStr : string;
begin
  ModalResult := mrCancel;
  if not Assigned(frmMSURTEMain) then Exit;
  inpStr := edValidPass.Text;
  if inpStr.Trim().Equals(string.Empty) then
  begin
    frmMSURTEMain.msu5RTECore.AppLogger.AddInfoMessage('Изменение пароля администратора: Пустые значения в полях ввода недопустимы!.');
    Exit;
  end;
  ControlStr := edNewPass1.Text;
  if ControlStr.Trim().Equals(string.Empty) then
  begin
    frmMSURTEMain.msu5RTECore.AppLogger.AddInfoMessage('Изменение пароля администратора: Пустые значения в полях ввода недопустимы!.');
    Exit;
  end;
  if ControlStr.Equals(inpStr) then
  begin
    frmMSURTEMain.msu5RTECore.AppLogger.AddInfoMessage('Изменение пароля администратора: Новый пароль совпадает со старым!.');
    Exit;
  end;
  ControlStr := frmMSURTEMain.msu5RTECore.MSURTESettings.AdmModePass;
  with TIdHashMessageDigest5.Create do
  try
    inpStr := edValidPass.Text;
    inpStr := LowerCase(inpStr.Trim());
    inpStr := LowerCase(HashStringAsHex(inpStr));
    if ControlStr.Equals(inpStr) then
    begin
      frmMSURTEMain.msu5RTECore.AppLogger.AddInfoMessage('Изменение пароля администратора: Введен корректный  действующий пароль.');
      inpStr := edNewPass1.Text;
      inpStr := LowerCase(inpStr.Trim());
      ControlStr := edNewPass2.Text;
      ControlStr := LowerCase(ControlStr.Trim());
      if ControlStr.Equals(inpStr) then
      begin
        inpStr := LowerCase(HashStringAsHex(inpStr));
        frmMSURTEMain.msu5RTECore.MSURTESettings.AdmModePass := inpStr;
        frmMSURTEMain.msu5RTECore.AppLogger.AddInfoMessage('Изменение пароля администратора: Пароль для доступа к режиму изменения значений тэгов изменен.');
        ModalResult := mrOk;
      end
      else
      begin
        frmMSURTEMain.msu5RTECore.AppLogger.AddInfoMessage('Изменение пароля администратора: Значения полей ввода новых паролей не совпадают.');
      end;
    end
    else
    begin
      frmMSURTEMain.msu5RTECore.AppLogger.AddInfoMessage('Изменение пароля администратора: В поле для ввода действующего пароля введено некорректное значение.');
    end;
  finally
    Free;
  end;
end;

end.
