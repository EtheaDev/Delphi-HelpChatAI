object MainForm: TMainForm
  Left = 0
  Top = 0
  HelpType = htKeyword
  HelpKeyword = 'Homepage e navigazione'
  Caption = 'LendingReport Manager (HelpChatAI VCL demo)'
  ClientHeight = 520
  ClientWidth = 860
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object ChatSplitter: TSplitter
    Left = 456
    Top = 57
    Width = 4
    Height = 444
    Align = alRight
    MinSize = 250
    Visible = False
  end
  object TopPanel: TPanel
    Left = 0
    Top = 0
    Width = 860
    Height = 57
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      860
      57)
    object TitleLabel: TLabel
      Left = 16
      Top = 3
      Width = 334
      Height = 21
      Caption = 'LendingReport Manager - demo application'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object ProviderLabel: TLabel
      Left = 16
      Top = 34
      Width = 47
      Height = 15
      Caption = 'Provider:'
    end
    object StyleLabel: TLabel
      Left = 240
      Top = 34
      Width = 28
      Height = 15
      Caption = 'Style:'
    end
    object ProviderCombo: TComboBox
      Left = 72
      Top = 30
      Width = 145
      Height = 23
      Style = csDropDownList
      TabOrder = 0
      OnChange = ProviderComboChange
    end
    object StyleCombo: TComboBox
      Left = 274
      Top = 30
      Width = 204
      Height = 23
      Style = csDropDownList
      Sorted = True
      TabOrder = 3
      OnChange = StyleComboChange
    end
    object OpenChatButton: TButton
      Left = 605
      Top = 27
      Width = 121
      Height = 29
      Anchors = [akTop, akRight]
      Caption = 'Help chat'
      TabOrder = 1
      OnClick = OpenChatButtonClick
    end
    object AskScreenButton: TButton
      Left = 732
      Top = 27
      Width = 113
      Height = 29
      Anchors = [akTop, akRight]
      Caption = 'F1 - this screen'
      TabOrder = 2
      OnClick = AskScreenButtonClick
    end
    object EmbeddedCheck: TCheckBox
      Left = 487
      Top = 34
      Width = 112
      Height = 17
      Hint = 
        'Show the chat in a side panel of this form instead of its own wi' +
        'ndow'
      Caption = 'Help embedded'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 4
      OnClick = EmbeddedCheckClick
    end
  end
  object ChatPanel: TPanel
    Left = 460
    Top = 57
    Width = 400
    Height = 444
    Align = alRight
    BevelOuter = bvNone
    TabOrder = 3
    Visible = False
    object ChatHeaderPanel: TPanel
      Left = 0
      Top = 0
      Width = 400
      Height = 29
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      object ChatHeaderLabel: TLabel
        Left = 8
        Top = 6
        Width = 249
        Height = 15
        Caption = 'Assistant (embedded in the application form)'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
    end
  end
  object PageControl: TPageControl
    Left = 0
    Top = 57
    Width = 456
    Height = 444
    ActivePage = SchedulerSheet
    Align = alClient
    TabOrder = 1
    object SchedulerSheet: TTabSheet
      HelpType = htKeyword
      HelpKeyword = 'Scheduler dei Report'
      Caption = 'Scheduler dei Report'
      object SchedulerMemo: TMemo
        Left = 0
        Top = 0
        Width = 448
        Height = 414
        Align = alClient
        BorderStyle = bsNone
        Lines.Strings = (
          
            'This screen stands for the "Scheduler dei Report" function of th' +
            'e manual.'
          ''
          
            'Press F1 (or the "F1 - this screen" button): the chat opens with' +
            ' a question about '
          'this'
          
            'screen. The component reads the HelpKeyword of the active tab sh' +
            'eet '
          '("Scheduler dei Report")'
          
            'and the retriever uses it to find the right page of the document' +
            'ation index.'
          ''
          
            'The bubble in the bottom-right corner opens the chat for a free ' +
            'question.'
          ''
          
            'Providers: "docsearch" answers from the index without any key; "' +
            'claude" needs '
          'an API key'
          
            'in %APPDATA%\HelpChatAI\helpchat.json (shared by all HelpChatAI apps' +
            ')  ->  { '
          '"Claude": { "ApiKey": "sk-ant-..." } }'
          'or in %APPDATA%\HelpChatAIVclDemo\helpchat.json, or in the '
          'ANTHROPIC_API_KEY environment variable.')
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
      end
    end
    object MailSheet: TTabSheet
      HelpType = htKeyword
      HelpKeyword = 'Configurazione e gestione delle e-mail'
      Caption = 'Server di posta'
      ImageIndex = 1
      object MailMemo: TMemo
        Left = 0
        Top = 0
        Width = 448
        Height = 414
        Align = alClient
        BorderStyle = bsNone
        Lines.Strings = (
          
            'This screen stands for the e-mail configuration (PARAMETRI - Ser' +
            'ver di posta).'
          ''
          
            'Its HelpKeyword is "Configurazione e gestione delle e-mail": F1 ' +
            'here asks the '
          'assistant'
          
            'about SMTP configuration and the answer cites the page 320000.ht' +
            'ml of the '
          'manual.'
          ''
          
            'Try, in Italian: "come configuro il server SMTP?" or "come invio' +
            ' un report via '
          'e-mail?"')
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
      end
    end
    object NewReportSheet: TTabSheet
      HelpType = htKeyword
      HelpKeyword = 'Scheduler dei Report'
      Caption = 'Nuovo report'
      ImageIndex = 2
      object ReportNameLabel: TLabel
        Left = 16
        Top = 19
        Width = 36
        Height = 15
        Caption = 'Nome:'
      end
      object ReportDescLabel: TLabel
        Left = 16
        Top = 51
        Width = 63
        Height = 15
        Caption = 'Descrizione:'
      end
      object ReportMailLabel: TLabel
        Left = 16
        Top = 83
        Width = 66
        Height = 15
        Caption = 'Destinatario:'
      end
      object ReportFormatLabel: TLabel
        Left = 16
        Top = 115
        Width = 48
        Height = 15
        Caption = 'Formato:'
      end
      object ActionsHintLabel: TLabel
        Left = 16
        Top = 200
        Width = 698
        Height = 45
        Caption = 
          'This screen is what the assistant can fill in by itself. With th' +
          'e "claude" provider selected above, open the chat and ask, in It' +
          'alian: "crea un report giornaliero delle vendite in PDF da manda' +
          're a mario.rossi@example.com". The assistant calls the actions t' +
          'his form registered (apri_schermata, compila_report) and asks be' +
          'fore changing anything.'
        WordWrap = True
      end
      object ReportNameEdit: TEdit
        Left = 112
        Top = 16
        Width = 320
        Height = 23
        TabOrder = 0
      end
      object ReportDescEdit: TEdit
        Left = 112
        Top = 48
        Width = 600
        Height = 23
        TabOrder = 1
      end
      object ReportMailEdit: TEdit
        Left = 112
        Top = 80
        Width = 320
        Height = 23
        TabOrder = 2
      end
      object ReportFormatCombo: TComboBox
        Left = 112
        Top = 112
        Width = 150
        Height = 23
        Style = csDropDownList
        TabOrder = 3
        Items.Strings = (
          'PDF'
          'Excel'
          'CSV')
      end
      object CreateReportButton: TButton
        Left = 112
        Top = 152
        Width = 121
        Height = 29
        Caption = 'Crea report'
        TabOrder = 4
        OnClick = CreateReportButtonClick
      end
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 501
    Width = 860
    Height = 19
    Panels = <
      item
        Width = 160
      end
      item
        Width = 150
      end
      item
        Width = 190
      end
      item
        Width = 220
      end>
  end
  object HelpChat: TVclHelpChatAI
    Settings.Provider = 'docsearch'
    Settings.DocIndexFile = '..\..\..\Test\Help\help-index.json'
    Settings.DocBaseUrl = 'https://help.ethea.it/lendingreport/'
    Settings.Claude.Model = 'claude-haiku-4-5'
    Settings.Claude.BaseUrl = 'https://api.anthropic.com'
    Settings.Claude.ApiVersion = '2023-06-01'
    Settings.OpenAI.AzureApiVersion = '2024-10-21'
    ImageIndex = 0
    OnActionExecuted = HelpChatActionExecuted
    OnGetContext = HelpChatGetContext
    OnBeforeShowHelp = HelpChatBeforeShowHelp
    OnAfterShowHelp = HelpChatAfterShowHelp
    OnBeforeHideHelp = HelpChatBeforeHideHelp
    Left = 24
    Top = 88
  end
end
