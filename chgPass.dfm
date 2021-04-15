object dlgChgPass: TdlgChgPass
  Left = 227
  Top = 108
  BorderStyle = bsDialog
  Caption = #1057#1084#1077#1085#1072' '#1087#1072#1088#1086#1083#1103
  ClientHeight = 209
  ClientWidth = 264
  Color = clBtnFace
  ParentFont = True
  OldCreateOrder = True
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object lbValidPass: TLabel
    Left = 24
    Top = 16
    Width = 161
    Height = 13
    Caption = #1042#1074#1077#1076#1080#1090#1077' '#1076#1077#1081#1089#1090#1074#1091#1102#1097#1080#1081' '#1087#1072#1088#1086#1083#1100':'
  end
  object lbNewPass1: TLabel
    Left = 24
    Top = 62
    Width = 121
    Height = 13
    Caption = #1042#1074#1077#1076#1080#1090#1077' '#1085#1086#1074#1099#1081' '#1087#1072#1088#1086#1083#1100':'
  end
  object lbNewPass2: TLabel
    Left = 24
    Top = 108
    Width = 165
    Height = 13
    Caption = #1042#1074#1077#1076#1080#1090#1077' '#1085#1086#1074#1099#1081' '#1087#1072#1088#1086#1083#1100' '#1077#1097#1077' '#1088#1072#1079':'
  end
  object OKBtn: TButton
    Left = 20
    Top = 170
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 0
    OnClick = OKBtnClick
  end
  object CancelBtn: TButton
    Left = 132
    Top = 170
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
  end
  object edValidPass: TEdit
    Left = 24
    Top = 35
    Width = 217
    Height = 21
    PasswordChar = '*'
    TabOrder = 2
  end
  object edNewPass1: TEdit
    Left = 24
    Top = 81
    Width = 217
    Height = 21
    PasswordChar = '*'
    TabOrder = 3
  end
  object edNewPass2: TEdit
    Left = 24
    Top = 127
    Width = 217
    Height = 21
    PasswordChar = '*'
    TabOrder = 4
  end
end
