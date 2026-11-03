{******************************************************************************}
{                                                                              }
{   HelpChatAI CRM demo - license activation (VCL)                             }
{                                                                              }
{   Where a real application would activate its license: ask the user for the  }
{   code they bought, call the licensing service, and keep what comes back -   }
{   the API key among it. This demo has no service, so it asks for the key     }
{   itself; everything after that is the same, and it is the part that         }
{   matters here: the key is encrypted with the secret of the application      }
{   (uAppSecret) and written to the per-user configuration file, never in      }
{   clear.                                                                     }
{                                                                              }
{   It is shown once, and only when no key was found anywhere - see            }
{   TMainForm.AskForApiKeyIfMissing.                                           }
{                                                                              }
{******************************************************************************}

unit uLicenseActivation;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  // The icon in the form is a PNG, and this is what reads it back.
  Vcl.Imaging.pngimage;

type
  TLicenseActivationForm = class(TForm)
    AppIconImage: TImage;
    TitleLabel: TLabel;
    ExplanationLabel: TLabel;
    KeyLabel: TLabel;
    KeyEdit: TEdit;
    ShowKeyCheck: TCheckBox;
    StorageTitleLabel: TLabel;
    StorageLabel: TLabel;
    ActivateButton: TButton;
    SkipButton: TButton;
    procedure ShowKeyCheckClick(Sender: TObject);
    procedure KeyEditChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    procedure UpdateButtons;
  public
    /// <summary>Asks for the key. True when the user activated and typed
    /// something; AStorageFile is only shown, so that whoever types a key
    /// knows where it is about to end up.</summary>
    class function Execute(const AStorageFile: string; out AKey: string): Boolean;
  end;

implementation

{$R *.dfm}

class function TLicenseActivationForm.Execute(const AStorageFile: string;
  out AKey: string): Boolean;
var
  LForm: TLicenseActivationForm;
begin
  AKey := '';
  LForm := TLicenseActivationForm.Create(Application);
  try
    LForm.StorageLabel.Caption := AStorageFile;
    Result := LForm.ShowModal = mrOk;
    if Result then
      AKey := Trim(LForm.KeyEdit.Text);
    Result := Result and (AKey <> '');
  finally
    LForm.Free;
  end;
end;

procedure TLicenseActivationForm.FormShow(Sender: TObject);
begin
  UpdateButtons;
  KeyEdit.SetFocus;
end;

procedure TLicenseActivationForm.KeyEditChange(Sender: TObject);
begin
  UpdateButtons;
end;

procedure TLicenseActivationForm.ShowKeyCheckClick(Sender: TObject);
begin
  // A key is pasted more often than typed, and a key pasted into the wrong
  // field looks exactly like a key pasted into the right one.
  if ShowKeyCheck.Checked then
    KeyEdit.PasswordChar := #0
  else
    KeyEdit.PasswordChar := '*';
end;

procedure TLicenseActivationForm.UpdateButtons;
begin
  ActivateButton.Enabled := Trim(KeyEdit.Text) <> '';
end;

end.
