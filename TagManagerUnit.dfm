object frmTagManager: TfrmTagManager
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = #1058#1101#1075' '#1084#1077#1085#1077#1076#1078#1077#1088
  ClientHeight = 476
  ClientWidth = 860
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object tmSplitter: TSplitter
    Left = 241
    Top = 0
    Height = 416
    ExplicitLeft = 312
    ExplicitTop = 112
    ExplicitHeight = 100
  end
  object tmStatusBar: TStatusBar
    Left = 0
    Top = 457
    Width = 860
    Height = 19
    Panels = <>
  end
  object tvTagTree: TTreeView
    Left = 0
    Top = 0
    Width = 241
    Height = 416
    Align = alLeft
    Indent = 19
    TabOrder = 1
    OnMouseDown = tvTagTreeMouseDown
  end
  object tmListView: TListView
    Left = 244
    Top = 0
    Width = 616
    Height = 416
    Align = alClient
    Columns = <
      item
        AutoSize = True
        Caption = #1048#1084#1103' '#1090#1101#1075#1072
      end
      item
        AutoSize = True
        Caption = #1058#1080#1087
      end
      item
        AutoSize = True
        Caption = #1054#1087#1080#1089#1072#1085#1080#1077
      end>
    DoubleBuffered = True
    MultiSelect = True
    RowSelect = True
    ParentDoubleBuffered = False
    SortType = stText
    TabOrder = 2
    ViewStyle = vsReport
  end
  object tmPanel: TPanel
    Left = 0
    Top = 416
    Width = 860
    Height = 41
    Align = alBottom
    TabOrder = 3
    object lbFindTag: TLabel
      Left = 13
      Top = 16
      Width = 107
      Height = 13
      Caption = #1055#1086#1080#1089#1082' '#1090#1101#1075#1072' '#1087#1086' '#1080#1084#1077#1085#1080':'
    end
    object BitBtn1: TBitBtn
      Left = 624
      Top = 10
      Width = 90
      Height = 25
      Kind = bkOK
      NumGlyphs = 2
      TabOrder = 0
    end
    object BitBtn2: TBitBtn
      Left = 744
      Top = 10
      Width = 90
      Height = 25
      Kind = bkCancel
      NumGlyphs = 2
      TabOrder = 1
    end
    object edFindTag: TEdit
      Left = 128
      Top = 14
      Width = 289
      Height = 21
      TabOrder = 2
      OnChange = edFindTagChange
    end
  end
end
