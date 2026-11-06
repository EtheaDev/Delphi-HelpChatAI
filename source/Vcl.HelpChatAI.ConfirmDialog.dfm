object VclHelpChatConfirmDialog: TVclHelpChatConfirmDialog
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Assistant'
  ClientHeight = 297
  ClientWidth = 540
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  PixelsPerInch = 96
  TextHeight = 15
  object HeaderPanel: TPanel
    Left = 0
    Top = 0
    Width = 540
    Height = 112
    Align = alTop
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 0
    DesignSize = (
      540
      112)
    object IconImage: TImage
      Left = 16
      Top = 16
      Width = 32
      Height = 32
      Center = True
    end
    object TitleLabel: TLabel
      Left = 64
      Top = 16
      Width = 460
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = 'The assistant wants to run'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      ShowAccelChar = False
      WordWrap = True
    end
    object DescriptionLabel: TLabel
      Left = 64
      Top = 48
      Width = 460
      Height = 15
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = 'Description'
      ShowAccelChar = False
      WordWrap = True
    end
  end
  object ValuesPanel: TPanel
    Left = 0
    Top = 112
    Width = 540
    Height = 64
    Align = alTop
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 1
  end
  object FooterPanel: TPanel
    Left = 0
    Top = 176
    Width = 540
    Height = 72
    Align = alTop
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 2
    DesignSize = (
      540
      72)
    object FooterBevel: TBevel
      Left = 16
      Top = 0
      Width = 508
      Height = 2
      Anchors = [akLeft, akTop, akRight]
      Shape = bsTopLine
    end
    object FooterImage: TImage
      Left = 16
      Top = 10
      Width = 16
      Height = 16
      Center = True
    end
    object FooterLabel: TLabel
      Left = 40
      Top = 10
      Width = 484
      Height = 15
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = 'Footer'
      ShowAccelChar = False
      WordWrap = True
    end
  end
  object ButtonsPanel: TPanel
    Left = 0
    Top = 248
    Width = 540
    Height = 49
    Align = alBottom
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 3
    DesignSize = (
      540
      49)
    object YesButton: TButton
      Left = 340
      Top = 12
      Width = 88
      Height = 26
      Anchors = [akTop, akRight]
      Caption = 'Yes'
      ModalResult = 6
      TabOrder = 1
    end
    object NoButton: TButton
      Left = 436
      Top = 12
      Width = 88
      Height = 26
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'No'
      Default = True
      ModalResult = 7
      TabOrder = 0
    end
  end
  object CountdownTimer: TTimer
    Enabled = False
    Interval = 1000
    OnTimer = CountdownTimerTimer
    Left = 480
    Top = 120
  end
end
