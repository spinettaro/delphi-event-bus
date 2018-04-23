object frmSecond: TfrmSecond
  Left = 658
  Top = 62
  ClientHeight = 208
  ClientWidth = 350
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesigned
  Visible = True
  PixelsPerInch = 96
  TextHeight = 13
  object MemoObserver: TMemo
    Left = 0
    Top = 36
    Width = 350
    Height = 155
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clRed
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 350
    Height = 36
    Align = alTop
    TabOrder = 1
    object Label1: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 4
      Width = 111
      Height = 23
      Align = alClient
      Caption = 'Second Form'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object CheckBox1: TCheckBox
      Left = 232
      Top = 1
      Width = 117
      Height = 34
      Align = alRight
      Caption = 'Mirror'
      TabOrder = 0
    end
  end
  object CheckBox2: TCheckBox
    Left = 0
    Top = 191
    Width = 350
    Height = 17
    Align = alBottom
    Caption = 'Register/Unregister'
    TabOrder = 2
    OnClick = CheckBox2Click
  end
end
