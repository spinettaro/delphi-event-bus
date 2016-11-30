object Form6: TForm6
  Left = 0
  Top = 0
  Caption = 'Analytics Form'
  ClientHeight = 337
  ClientWidth = 554
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 8
    Top = 128
    Width = 273
    Height = 201
    Lines.Strings = (
      'Memo1')
    TabOrder = 0
    OnChange = Memo1Change
  end
  object Button1: TButton
    Left = 8
    Top = 97
    Width = 273
    Height = 25
    Caption = 'Click Me!'
    TabOrder = 1
    OnClick = Button1Click
  end
  object LabeledEdit1: TLabeledEdit
    Left = 8
    Top = 24
    Width = 121
    Height = 21
    EditLabel.Width = 22
    EditLabel.Height = 13
    EditLabel.Caption = 'User'
    ReadOnly = True
    TabOrder = 2
    Text = 'ironman'
  end
  object RadioGroup1: TRadioGroup
    Left = 304
    Top = 97
    Width = 242
    Height = 232
    Caption = 'Favorite Food'
    Items.Strings = (
      'Pasta'
      'Pizza'
      'Hamburger'
      'Lasagna')
    TabOrder = 3
    OnClick = RadioGroup1Click
  end
  object PrototypeBindSource1: TPrototypeBindSource
    AutoActivate = True
    AutoPost = False
    FieldDefs = <
      item
        Name = 'ContactName1'
        Generator = 'ContactNames'
        ReadOnly = False
      end
      item
        Name = 'ContactTitle1'
        Generator = 'ContactTitles'
        ReadOnly = False
      end>
    ScopeMappings = <>
    Left = 472
    Top = 24
  end
  object BindingsList1: TBindingsList
    Methods = <>
    OutputConverters = <>
    Left = 308
    Top = 13
    object LinkFillControlToField1: TLinkFillControlToField
      Category = 'Quick Bindings'
      Track = True
      FillDataSource = PrototypeBindSource1
      FillDisplayFieldName = 'ContactName1'
      AutoFill = True
      FillExpressions = <>
      FillHeaderExpressions = <>
      FillBreakGroups = <>
    end
    object LinkFillControlToField2: TLinkFillControlToField
      Category = 'Quick Bindings'
      Track = True
      FillDataSource = PrototypeBindSource1
      FillDisplayFieldName = 'ContactName1'
      AutoFill = True
      FillExpressions = <>
      FillHeaderExpressions = <>
      FillBreakGroups = <>
    end
  end
end
