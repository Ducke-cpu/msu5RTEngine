object frmChangeValue: TfrmChangeValue
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = #1048#1079#1084#1077#1085#1077#1085#1080#1077' '#1079#1085#1072#1095#1077#1085#1080#1103' '#1090#1101#1075#1072
  ClientHeight = 114
  ClientWidth = 521
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object lbTagName: TLabel
    Left = 24
    Top = 8
    Width = 55
    Height = 16
    Caption = 'TagName'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lbNewValue: TLabel
    Left = 24
    Top = 40
    Width = 100
    Height = 16
    Caption = #1053#1086#1074#1086#1077' '#1079#1085#1072#1095#1077#1085#1080#1077':'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object rbTRUE: TRadioButton
    Left = 144
    Top = 38
    Width = 73
    Height = 17
    Caption = 'TRUE'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
  end
  object rbFALSE: TRadioButton
    Left = 248
    Top = 38
    Width = 81
    Height = 17
    Caption = 'FALSE'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
  end
  object btWrite: TBitBtn
    Left = 8
    Top = 72
    Width = 105
    Height = 25
    Caption = #1047#1072#1087#1080#1089#1072#1090#1100
    Kind = bkOK
    NumGlyphs = 2
    TabOrder = 2
    OnClick = btWriteClick
  end
  object btCancel: TBitBtn
    Left = 407
    Top = 72
    Width = 107
    Height = 25
    Caption = #1054#1090#1084#1077#1085#1072
    Kind = bkCancel
    NumGlyphs = 2
    TabOrder = 3
  end
  object btForce: TBitBtn
    Left = 136
    Top = 72
    Width = 113
    Height = 25
    Caption = #1047#1072#1073#1083#1086#1082#1080#1088#1086#1074#1072#1090#1100
    Kind = bkAll
    NumGlyphs = 2
    TabOrder = 4
    OnClick = btForceClick
  end
  object btUnForce: TBitBtn
    Left = 272
    Top = 72
    Width = 113
    Height = 25
    Caption = #1056#1072#1079#1073#1083#1086#1082#1080#1088#1086#1074#1072#1090#1100
    Kind = bkNo
    NumGlyphs = 2
    TabOrder = 5
    OnClick = btUnForceClick
  end
  object edChangeValue: TEdit
    Left = 144
    Top = 39
    Width = 369
    Height = 21
    TabOrder = 6
  end
end
