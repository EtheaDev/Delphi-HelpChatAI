unit HelpChatAI.Tests.Types;

interface

uses
  DUnitX.TestFramework,
  HelpChatAI.Types;

type
  [TestFixture]
  TTypesTests = class
  public
    [Test] procedure NewId_Is36CharsWithoutBraces;
    [Test] procedure NewId_IsUnique;
    [Test] procedure Message_IsCompleted;
    [Test] procedure CancelToken_StartsClear_ThenCancels;
    [Test] procedure Context_IsEmpty;
    [Test] procedure Context_DisplayName_PrefersLabel;
    [Test] procedure Context_SearchHint_JoinsKeywords;
    [Test] procedure JoinUrl_ExactlyOneSlash;
  end;

implementation

uses
  System.SysUtils;

procedure TTypesTests.NewId_Is36CharsWithoutBraces;
var
  LId: string;
begin
  LId := THelpChatMessage.NewId;
  Assert.AreEqual(36, LId.Length);
  Assert.IsFalse(LId.Contains('{'));
  Assert.IsFalse(LId.Contains('}'));
  Assert.AreEqual('-', LId[9]);
end;

procedure TTypesTests.NewId_IsUnique;
begin
  Assert.AreNotEqual(THelpChatMessage.NewId, THelpChatMessage.NewId);
end;

procedure TTypesTests.Message_IsCompleted;
var
  LMessage: THelpChatMessage;
begin
  LMessage := Default(THelpChatMessage);
  Assert.IsTrue(LMessage.IsCompleted);
  LMessage.Pending := True;
  Assert.IsFalse(LMessage.IsCompleted);
  LMessage.Pending := False;
  LMessage.IsError := True;
  Assert.IsFalse(LMessage.IsCompleted);
end;

procedure TTypesTests.CancelToken_StartsClear_ThenCancels;
var
  LToken: IHelpChatCancelToken;
begin
  LToken := THelpChatCancelToken.Create;
  Assert.IsFalse(LToken.IsCancelled);
  LToken.Cancel;
  Assert.IsTrue(LToken.IsCancelled);
  LToken.Cancel; // idempotent
  Assert.IsTrue(LToken.IsCancelled);
end;

procedure TTypesTests.Context_IsEmpty;
var
  LContext: THelpChatContext;
begin
  LContext := Default(THelpChatContext);
  Assert.IsTrue(LContext.IsEmpty);
  LContext.UserName := 'carlo'; // user alone is not screen information
  Assert.IsTrue(LContext.IsEmpty);
  LContext.HelpContext := 42;
  Assert.IsFalse(LContext.IsEmpty);
end;

procedure TTypesTests.Context_DisplayName_PrefersLabel;
var
  LContext: THelpChatContext;
begin
  LContext := Default(THelpChatContext);
  LContext.ScreenName := 'OrdersForm';
  Assert.AreEqual('OrdersForm', LContext.DisplayName);
  LContext.ScreenLabel := 'Orders';
  Assert.AreEqual('Orders', LContext.DisplayName);
  // A readable HelpKeyword names the documentation page: it is the screen.
  LContext.HelpKeyword := 'Scheduler dei Report';
  Assert.AreEqual('Scheduler dei Report', LContext.DisplayName);
  Assert.IsTrue(LContext.HasReadableKeyword);
  // A numeric keyword is a code: not something to show the user.
  LContext.HelpKeyword := '4040000';
  Assert.IsFalse(LContext.HasReadableKeyword);
  Assert.AreEqual('Orders', LContext.DisplayName);
end;

procedure TTypesTests.Context_SearchHint_JoinsKeywords;
var
  LContext: THelpChatContext;
begin
  LContext := Default(THelpChatContext);
  LContext.ScreenType := 'TOrdersForm';
  LContext.ScreenLabel := 'Orders';
  Assert.AreEqual('Orders', LContext.SearchHint, 'no keyword: the label; the class name is noise');
  LContext.HelpKeyword := 'Scheduler dei Report';
  Assert.AreEqual('Scheduler dei Report', LContext.SearchHint, 'the keyword alone is the anchor');
  LContext := Default(THelpChatContext);
  Assert.AreEqual('', LContext.SearchHint);
end;

procedure TTypesTests.JoinUrl_ExactlyOneSlash;
begin
  Assert.AreEqual('https://a/b', HelpChatJoinUrl('https://a/', 'b'));
  Assert.AreEqual('https://a/b', HelpChatJoinUrl('https://a', 'b'));
  Assert.AreEqual('https://a/b', HelpChatJoinUrl('https://a/', '/b'));
  Assert.AreEqual('https://a/b', HelpChatJoinUrl('https://a', '/b'));
  Assert.AreEqual('b', HelpChatJoinUrl('', 'b'));
  Assert.AreEqual('https://a/', HelpChatJoinUrl('https://a/', ''));
end;

end.
