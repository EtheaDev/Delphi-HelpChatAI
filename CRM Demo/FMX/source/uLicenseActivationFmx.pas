{******************************************************************************}
{                                                                              }
{   HelpChatAI CRM demo - license activation (FireMonkey)                      }
{                                                                              }
{   The FireMonkey half of uLicenseActivation: same window, same words. Where  }
{   a real application would activate its license - ask the licensing service  }
{   for the key and keep what comes back - this demo asks for the key itself,  }
{   encrypts it with the secret of the application (uAppSecret) and writes it  }
{   to the per-user configuration file, never in clear.                        }
{                                                                              }
{   FireMonkey answers in a callback: ShowModal is asynchronous, so Execute    }
{   hands the key to a closure instead of returning it.                        }
{                                                                              }
{******************************************************************************}

unit uLicenseActivationFmx;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Objects, FMX.StdCtrls, FMX.Controls.Presentation, FMX.Edit;

type
  TLicenseActivationFormFmx = class(TForm)
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
    procedure FormShow(Sender: TObject);
    procedure KeyEditChangeTracking(Sender: TObject);
    procedure ShowKeyCheckChange(Sender: TObject);
    procedure ActivateButtonClick(Sender: TObject);
    procedure SkipButtonClick(Sender: TObject);
  private
    procedure UpdateButtons;
  public
    /// <summary>Asks for the key and calls AOnActivated with it, once, only
    /// when the user activated and typed something. AStorageFile is only
    /// shown, so that whoever types a key knows where it is about to end
    /// up.</summary>
    class procedure Execute(const AStorageFile: string;
      const AOnActivated: TProc<string>);
  end;

implementation

{$R *.fmx}

class procedure TLicenseActivationFormFmx.Execute(const AStorageFile: string;
  const AOnActivated: TProc<string>);
var
  LForm: TLicenseActivationFormFmx;
begin
  LForm := TLicenseActivationFormFmx.Create(Application);
  LForm.StorageLabel.Text := AStorageFile;
  LForm.ShowModal(
    procedure(AResult: TModalResult)
    var
      LKey: string;
    begin
      LKey := Trim(LForm.KeyEdit.Text);
      if (AResult = mrOk) and (LKey <> '') and Assigned(AOnActivated) then
        AOnActivated(LKey);
      // Not here: this closure runs while the modal window is still being
      // closed, and the runtime touches the form after it returns.
      TThread.ForceQueue(nil,
        procedure
        begin
          LForm.Free;
        end);
    end);
end;

procedure TLicenseActivationFormFmx.FormShow(Sender: TObject);
begin
  UpdateButtons;
  KeyEdit.SetFocus;
end;

procedure TLicenseActivationFormFmx.KeyEditChangeTracking(Sender: TObject);
begin
  UpdateButtons;
end;

procedure TLicenseActivationFormFmx.ShowKeyCheckChange(Sender: TObject);
begin
  // A key is pasted more often than typed, and a key pasted into the wrong
  // field looks exactly like a key pasted into the right one.
  KeyEdit.Password := not ShowKeyCheck.IsChecked;
end;

procedure TLicenseActivationFormFmx.UpdateButtons;
begin
  ActivateButton.Enabled := Trim(KeyEdit.Text) <> '';
end;

procedure TLicenseActivationFormFmx.ActivateButtonClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TLicenseActivationFormFmx.SkipButtonClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
