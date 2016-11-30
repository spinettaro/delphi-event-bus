object FormLogger: TFormLogger
  Left = 0
  Top = 0
  Caption = 'Logger Form'
  ClientHeight = 277
  ClientWidth = 510
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 0
    Top = 0
    Width = 510
    Height = 277
    Align = alClient
    Lines.Strings = (
      'Memo1')
    TabOrder = 0
  end
end
