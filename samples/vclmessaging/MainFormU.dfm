object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'frmMain'
  ClientHeight = 239
  ClientWidth = 444
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -19
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 23
  object Memo1: TMemo
    Left = 0
    Top = 0
    Width = 444
    Height = 208
    Align = alClient
    TabOrder = 0
    OnChange = Memo1Change
  end
  object Panel1: TPanel
    Left = 0
    Top = 208
    Width = 444
    Height = 31
    Align = alBottom
    TabOrder = 1
    object CheckBox1: TCheckBox
      Left = 8
      Top = 6
      Width = 121
      Height = 17
      Caption = 'Click on me!'
      TabOrder = 0
      OnClick = CheckBox1Click
    end
  end
end
