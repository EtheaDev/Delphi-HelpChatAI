{******************************************************************************}
{                                                                              }
{   HelpChatAI CRM demo - the secret of this application                       }
{                                                                              }
{   How the demo keeps its API key encrypted in helpchatai.json, and how it    }
{   hands it back to the component through OnDecryptSecret. AES-256 (CBC,      }
{   random IV, PKCS#7) from DCPcrypt, with a key derived from a passphrase     }
{   that is not written anywhere as a string.                                  }
{                                                                              }
{   THIS IS A SIMPLE EXAMPLE, AND IT IS OBFUSCATION, NOT SECRECY.              }
{   It raises the cost: whoever receives the configuration file, a backup, a   }
{   log or a screenshot of the Object Inspector no longer has the key.         }
{   It does not make it impossible: the passphrase travels inside the          }
{   executable, so whoever owns the machine and a debugger can recover it -    }
{   and the sources of this demo are public, which settles the matter here.    }
{   A real application does better: a secret fetched from its own server at    }
{   startup, one derived from the machine or the logged-on user, or no key on  }
{   the client at all (Settings.Remote: the key lives on the HelpChat server   }
{   and never reaches the client).                                             }
{                                                                              }
{   DCPcrypt is used by the demo alone: the library has no dependency on it,   }
{   it only calls the handler. See the search path of the two projects.        }
{                                                                              }
{******************************************************************************}

unit uAppSecret;

interface

uses
  System.SysUtils;

const
  /// <summary>What marks a value this unit wrote. The library imposes no
  /// format: this prefix is a convention of the demo, and the handler is the
  /// only thing that has to recognize it.</summary>
  APPSECRET_PREFIX = 'enc:';

/// <summary>True when AValue carries the prefix of a protected value.</summary>
function AppSecretIsProtected(const AValue: string): Boolean;

/// <summary>AClearText encrypted with the secret of this application:
/// <c>enc:</c> followed by Base64 of the IV and the ciphertext. Encrypting
/// the same text twice gives two different results, because the IV is drawn
/// every time.</summary>
function AppSecretProtect(const AClearText: string): string;

/// <summary>What AppSecretProtect wrote, back in clear. Raises when the value
/// was not produced by this application - a key encrypted with another
/// passphrase is not a key with a typo in it.</summary>
function AppSecretReveal(const AValue: string): string;

/// <summary>Writes AProtectedKey into the <c>ApiKeyEncrypted</c> of the named
/// section of the per-user configuration file of this application
/// (<c>%APPDATA%\&lt;exe&gt;\helpchatai.json</c>), leaving the rest of the
/// file as it is - a clear <c>ApiKey</c> of the developer included: the IDE
/// reads that one, the running application this one.</summary>
procedure AppSecretStoreApiKey(const ASection, AProtectedKey: string);

type
  /// <summary>The handler to hang on <c>OnDecryptSecret</c>, for a host that
  /// has no form of its own to put it on. Both demos use a method of their
  /// main form instead, which is where the Object Inspector looks.</summary>
  TAppSecret = class
  public
    /// <summary>Answers for every value carrying the prefix, whichever secret
    /// it is, and leaves the others as they are.</summary>
    procedure DecryptSecret(Sender: TObject; const AName, AValue: string;
      var AResult: string; var AHandled: Boolean);
  end;

/// <summary>The one instance, freed with the unit.</summary>
function AppSecret: TAppSecret;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.JSON,
  System.NetEncoding,
  HelpChatAI.Settings,
  DCPcrypt2,
  DCPrijndael,
  DCPsha256;

const
  AES_BLOCK = 16;
  AES_KEYBITS = 256;

  // The passphrase of this application, in two halves that mean nothing on
  // their own: neither is a readable string in the executable, and the value
  // itself exists only while the key is being derived. Read the header of
  // this unit before trusting it with anything that matters.
  SECRET_A: array[0..41] of Byte = (
    $B6, $7F, $17, $F8, $9A, $C4, $AC, $67,
    $CD, $6F, $DC, $11, $9C, $E5, $1E, $6F,
    $67, $C6, $24, $C8, $D3, $D8, $7A, $7E,
    $67, $7C, $A3, $20, $A5, $86, $A9, $27,
    $97, $D1, $9A, $18, $E1, $F9, $F8, $E9,
    $9B, $84);
  SECRET_B: array[0..41] of Byte = (
    $A5, $46, $26, $D6, $86, $CC, $AC, $71,
    $EF, $42, $99, $34, $A9, $C0, $57, $61,
    $69, $C7, $26, $86, $8E, $98, $39, $3A,
    $34, $25, $FB, $76, $B7, $86, $B1, $30,
    $9C, $C1, $82, $46, $ED, $1C, $1A, $19,
    $7D, $74);
  SECRET_SALT = $5B;

var
  FAppSecret: TAppSecret;

/// <summary>Zeroes a buffer that held something secret. An empty one is
/// legal and must not be addressed.</summary>
procedure Wipe(var ABytes: TBytes);
begin
  if Length(ABytes) > 0 then
    FillChar(ABytes[0], Length(ABytes), 0);
  SetLength(ABytes, 0);
end;

function Passphrase: TBytes;
var
  I: Integer;
begin
  SetLength(Result, Length(SECRET_A));
  for I := 0 to High(SECRET_A) do
    Result[I] := SECRET_A[I] xor SECRET_B[I] xor Byte(SECRET_SALT + I);
end;

/// <summary>The 256-bit key: the SHA-256 of the passphrase, which is also
/// what turns a passphrase of any length into a key of the right one.</summary>
function KeyBytes: TBytes;
var
  LHash: TDCP_sha256;
  LPass: TBytes;
begin
  SetLength(Result, 32);
  LPass := Passphrase;
  LHash := TDCP_sha256.Create(nil);
  try
    LHash.Init;
    LHash.Update(LPass[0], Length(LPass));
    LHash.Final(Result[0]);
  finally
    LHash.Burn;
    LHash.Free;
    Wipe(LPass);
  end;
end;

/// <summary>AES-256 in CBC, keyed and set on AIv. The caller burns it.</summary>
function NewCipher(const AIv: TBytes): TDCP_rijndael;
var
  LKey: TBytes;
begin
  LKey := KeyBytes;
  Result := TDCP_rijndael.Create(nil);
  try
    Result.Init(LKey[0], AES_KEYBITS, @AIv[0]);
    Result.CipherMode := cmCBC;
  except
    Result.Free;
    raise;
  end;
  Wipe(LKey);
end;

/// <summary>An initialisation vector nobody can guess: two GUIDs, hashed.
/// It is not a secret - it travels in front of the ciphertext - but it must
/// differ every time, or the same key encrypted twice looks the same.</summary>
function NewIv: TBytes;
var
  LHash: TDCP_sha256;
  LSeed: array[0..1] of TGUID;
  LDigest: TBytes;
begin
  CreateGUID(LSeed[0]);
  CreateGUID(LSeed[1]);
  SetLength(LDigest, 32);
  LHash := TDCP_sha256.Create(nil);
  try
    LHash.Init;
    LHash.Update(LSeed[0], SizeOf(LSeed));
    LHash.Final(LDigest[0]);
  finally
    LHash.Burn;
    LHash.Free;
  end;
  SetLength(Result, AES_BLOCK);
  Move(LDigest[0], Result[0], AES_BLOCK);
end;

/// <summary>Base64 on one line: the value goes into a JSON string and into a
/// form file, and the encoder of the RTL wraps at 76 characters unless it is
/// told not to.</summary>
function Base64Of(const ABytes: TBytes): string;
var
  LEncoding: TBase64Encoding;
begin
  LEncoding := TBase64Encoding.Create(0);
  try
    Result := LEncoding.EncodeBytesToString(ABytes);
  finally
    LEncoding.Free;
  end;
end;

function BytesOfBase64(const AText: string): TBytes;
var
  LEncoding: TBase64Encoding;
begin
  LEncoding := TBase64Encoding.Create(0);
  try
    Result := LEncoding.DecodeStringToBytes(AText);
  finally
    LEncoding.Free;
  end;
end;

function AppSecretIsProtected(const AValue: string): Boolean;
begin
  Result := AValue.StartsWith(APPSECRET_PREFIX);
end;

function AppSecretProtect(const AClearText: string): string;
var
  LPlain, LPadded, LCipherText, LIv: TBytes;
  LPad: Integer;
  LCipher: TDCP_rijndael;
begin
  if AClearText = '' then
    Exit('');
  LPlain := TEncoding.UTF8.GetBytes(AClearText);
  // PKCS#7: always at least one byte of padding, every one of them saying
  // how many there are, so the length of the text is not readable from the
  // length of the ciphertext.
  LPad := AES_BLOCK - (Length(LPlain) mod AES_BLOCK);
  SetLength(LPadded, Length(LPlain) + LPad);
  Move(LPlain[0], LPadded[0], Length(LPlain));
  FillChar(LPadded[Length(LPlain)], LPad, Byte(LPad));
  LIv := NewIv;
  SetLength(LCipherText, Length(LPadded));
  LCipher := NewCipher(LIv);
  try
    LCipher.EncryptCBC(LPadded[0], LCipherText[0], Length(LPadded));
  finally
    LCipher.Burn;
    LCipher.Free;
    Wipe(LPlain);
    Wipe(LPadded);
  end;
  Result := APPSECRET_PREFIX + Base64Of(LIv + LCipherText);
end;

function AppSecretReveal(const AValue: string): string;
var
  LRaw, LPlain, LIv: TBytes;
  LCipher: TDCP_rijndael;
  LPad, LSize: Integer;
begin
  if not AppSecretIsProtected(AValue) then
    Exit(AValue);
  LRaw := BytesOfBase64(AValue.Substring(Length(APPSECRET_PREFIX)));
  LSize := Length(LRaw) - AES_BLOCK;
  if (LSize <= 0) or (LSize mod AES_BLOCK <> 0) then
    raise Exception.Create('The protected value is not one this application wrote.');
  SetLength(LIv, AES_BLOCK);
  Move(LRaw[0], LIv[0], AES_BLOCK);
  SetLength(LPlain, LSize);
  LCipher := NewCipher(LIv);
  try
    LCipher.DecryptCBC(LRaw[AES_BLOCK], LPlain[0], LSize);
  finally
    LCipher.Burn;
    LCipher.Free;
  end;
  // The padding is the only check there is: a wrong passphrase gives noise,
  // and noise does not end in 1..16 equal bytes - almost never, anyway.
  LPad := LPlain[LSize - 1];
  if (LPad < 1) or (LPad > AES_BLOCK) or (LPad > LSize) then
  begin
    Wipe(LPlain);
    raise Exception.Create('The protected value was written with another secret.');
  end;
  try
    Result := TEncoding.UTF8.GetString(LPlain, 0, LSize - LPad);
  finally
    Wipe(LPlain);
  end;
end;

procedure AppSecretStoreApiKey(const ASection, AProtectedKey: string);
var
  LFileName: string;
  LRoot, LSection: TJSONObject;
  LValue: TJSONValue;
begin
  LFileName := THelpChatSettings.UserConfigFile;
  LRoot := nil;
  if TFile.Exists(LFileName) then
    LRoot := TJSONObject.ParseJSONValue(
      TFile.ReadAllText(LFileName, TEncoding.UTF8)) as TJSONObject;
  if LRoot = nil then
    LRoot := TJSONObject.Create;
  try
    LValue := LRoot.GetValue(ASection);
    if LValue is TJSONObject then
      LSection := TJSONObject(LValue)
    else
    begin
      LSection := TJSONObject.Create;
      LRoot.AddPair(ASection, LSection);
    end;
    LSection.RemovePair('ApiKeyEncrypted').Free;
    LSection.AddPair('ApiKeyEncrypted', AProtectedKey);
    TDirectory.CreateDirectory(TPath.GetDirectoryName(LFileName));
    TFile.WriteAllText(LFileName, LRoot.Format(2), TEncoding.UTF8);
  finally
    LRoot.Free;
  end;
end;

{ TAppSecret }

procedure TAppSecret.DecryptSecret(Sender: TObject; const AName, AValue: string;
  var AResult: string; var AHandled: Boolean);
begin
  AHandled := AppSecretIsProtected(AValue);
  if AHandled then
    AResult := AppSecretReveal(AValue);
end;

function AppSecret: TAppSecret;
begin
  if FAppSecret = nil then
    FAppSecret := TAppSecret.Create;
  Result := FAppSecret;
end;

initialization

finalization
  FreeAndNil(FAppSecret);

end.
