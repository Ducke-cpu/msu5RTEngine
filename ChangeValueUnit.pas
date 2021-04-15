unit ChangeValueUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, MSUCore;

type
  TfrmChangeValue = class(TForm)
    lbTagName: TLabel;
    rbTRUE: TRadioButton;
    rbFALSE: TRadioButton;
    lbNewValue: TLabel;
    btWrite: TBitBtn;
    btCancel: TBitBtn;
    btForce: TBitBtn;
    btUnForce: TBitBtn;
    edChangeValue: TEdit;
    procedure btWriteClick(Sender: TObject);
    procedure btForceClick(Sender: TObject);
    procedure btUnForceClick(Sender: TObject);
  private
    FCurrentTag : TRTETag;
    procedure SetCurrentTag(Value : TRTETag);
    function CheckValue : OleVariant;
  public
    property CurrentTag : TRTETag read FCurrentTag write SetCurrentTag;
  end;

var
  frmChangeValue: TfrmChangeValue;

implementation
uses Winapi.ActiveX;
{$R *.dfm}

procedure TfrmChangeValue.btForceClick(Sender: TObject);
begin
   if Assigned(FCurrentTag) then
   begin
    FCurrentTag.Forced := true;
    FCurrentTag.ForceValue := CheckValue;
   end;
end;

procedure TfrmChangeValue.btUnForceClick(Sender: TObject);
begin
  if Assigned(FCurrentTag) then
   begin
    FCurrentTag.Forced := false;
   end;
end;

procedure TfrmChangeValue.btWriteClick(Sender: TObject);
begin
   if Assigned(FCurrentTag) then
   begin
    FCurrentTag.Value := CheckValue;
   end;
end;

function TfrmChangeValue.CheckValue;
var
  ErrCode, intVal : Integer;
begin
  Result := -1;
  if Assigned(FCurrentTag) then
   begin
    case FCurrentTag.TagType  of
      VT_BOOL:
        begin
          Result := rbTRUE.Checked;
        end;
      VT_I2,VT_I4:
        begin
          val(edChangeValue.Text,intVal,ErrCode);
          if ErrCode > 0 then
          begin
            MessageBox(Handle,'Значение должно быть целым числом',PChar(Caption),MB_OK);
            edChangeValue.Text := FCurrentTag.Value;
          end
          else
          begin
            Result := intVal;
          end;
        end;
      VT_BSTR:
        begin
          Result := string(edChangeValue.Text).Trim();
        end;
    end;
   end;
end;

procedure TfrmChangeValue.SetCurrentTag(Value: TRTETag);
var
  boolValue : Boolean;
begin
  FCurrentTag := Value;
  if Assigned(FCurrentTag) then
  begin
    lbTagName.Caption := FCurrentTag.Name;
    case FCurrentTag.TagType  of
      VT_BOOL:
        begin
          edChangeValue.Visible := false;
          boolValue := FCurrentTag.Value;
          rbTRUE.Visible := true;
          rbTRUE.Checked :=  not boolValue;
          rbFALSE.Visible := true;
          rbFALSE.Checked := boolValue;
        end
        else
        begin
          edChangeValue.Visible := true;
          rbTRUE.Visible := false;
          rbFALSE.Visible := false;
          edChangeValue.Text := FCurrentTag.Value;
        end;
    end;//case
    btWrite.Enabled := not FCurrentTag.Forced;
    btForce.Enabled := true;
    btUnForce.Enabled := FCurrentTag.Forced;
  end;
end;

end.
