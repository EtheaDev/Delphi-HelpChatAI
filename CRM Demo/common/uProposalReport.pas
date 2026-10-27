{******************************************************************************}
{                                                                              }
{   HelpChatAI CRM demo - the proposal document                                }
{                                                                              }
{   The invoice the draft window previews and saves: plain RTL, no VCL and     }
{   no FireMonkey, so the two demos produce byte for byte the same document.   }
{   It used to live in uDraftProposal with the CSS in a hidden TMemo of the    }
{   form; the FireMonkey port is what made the duplication visible.            }
{                                                                              }
{******************************************************************************}

unit uProposalReport;

interface

uses
  System.SysUtils, System.Classes, Data.DB;

type
  /// <summary>One line of the proposal, as whoever prepares the draft from
  /// the outside passes it.</summary>
  TProposalLineItem = record
    Title: string;
    Quantity: Integer;
    Price: Currency;
  end;

/// <summary>The invoice as one HTML document: the draft record for the header
/// and the line items for the table.</summary>
function GenerateProposalReport(ADataSet, ALineItemsDataSet: TDataSet): string;

/// <summary>"Consulting x 12 @ 150" per line, the way the model writes it.
/// Raises on anything it cannot read: a wrong proposal is worse than none.</summary>
function ParseProposalLineItems(const AText: string): TArray<TProposalLineItem>;

var
  /// <summary>The document is in English: numbers and dates do not follow
  /// the settings of the machine.</summary>
  InvoiceFormat: TFormatSettings;

implementation

uses
  System.NetEncoding;

const
  EmptyLBRow = '<tr class="row header ltblue"><td>&nbsp;</td><td><h3>&nbsp;</h3></td></tr>';
  TableTRStart = '<tr class="row header ltblue"><td><b>';
  TableTREnd = '</td></tr>';
  InvoiceTStart = '<tr class="row"><td colspan="2"><table width="100%" align="center" cellspacing="0" cellpadding="10" border="0">';
  InvoiceTHStart = '<tr class="row"><th><b>';
  InvoiceTHMid = '</b></th><th><b>';
  InvoiceTHEnd = '</b></th></tr>';
  InvoiceTRStart = '<tr class="row" align="center"><td>';
  InvoiceTRMid = '</td><td>';
  InvoiceTREnd = '</td></tr>';
  InvoiceTEnd = '</table></td></tr>';

  /// <summary>The style of the document. It was the Lines of a hidden TMemo
  /// on the draft form, which is a form designer's way of storing a constant.</summary>
  ProposalCss =
    '<style type="text/css">'#13#10 +
    'body {'#13#10 +
    '  font-family: "Helvetica Neue", Helvetica, Arial;'#13#10 +
    '  font-size: 14px;'#13#10 +
    '  line-height: 20px;'#13#10 +
    '  font-weight: 400;'#13#10 +
    '  color: #3b3b3b;'#13#10 +
    '  -webkit-font-smoothing: antialiased;'#13#10 +
    '  font-smoothing: antialiased;'#13#10 +
    '  background: #2b2b2b;'#13#10 +
    '}'#13#10 +
    ''#13#10 +
    '.container-fluid {'#13#10 +
    '  margin: 0 auto;'#13#10 +
    '  padding: 40px;'#13#10 +
    '  max-width: 100%;'#13#10 +
    '}'#13#10 +
    ''#13#10 +
    '.table {'#13#10 +
    '  margin: 0 0 40px 0;'#13#10 +
    '  width: 100%;'#13#10 +
    '  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.2);'#13#10 +
    '  display: table;'#13#10 +
    '}'#13#10 +
    '@media screen and (max-width: 100%) {'#13#10 +
    '  .table {'#13#10 +
    '    display: block;'#13#10 +
    '  }'#13#10 +
    '}'#13#10 +
    ''#13#10 +
    '.row {'#13#10 +
    '  display: table-row;'#13#10 +
    '  background: #f6f6f6;'#13#10 +
    '}'#13#10 +
    '.row:nth-of-type(odd) {'#13#10 +
    '  background: #e9e9e9;'#13#10 +
    '}'#13#10 +
    '.row.header {'#13#10 +
    '  font-weight: 900;'#13#10 +
    '  color: #ffffff;'#13#10 +
    '  background: #ea6153;'#13#10 +
    '}'#13#10 +
    '.row.green {'#13#10 +
    '  background: #27ae60;'#13#10 +
    '}'#13#10 +
    '.row.blue {'#13#10 +
    '  background: #2980b9;'#13#10 +
    '}'#13#10 +
    '.row.ltblue {'#13#10 +
    '  background: #3792D1;'#13#10 +
    '}'#13#10 +
    '@media screen and (max-width: 100%) {'#13#10 +
    '  .row {'#13#10 +
    '    padding: 8px 0;'#13#10 +
    '    display: block;'#13#10 +
    '  }'#13#10 +
    '}'#13#10 +
    ''#13#10 +
    '.col-xs-6 {'#13#10 +
    '  padding: 6px 12px;'#13#10 +
    '  display: table-cell;'#13#10 +
    '}'#13#10 +
    '@media screen and (max-width: 100%) {'#13#10 +
    '  .col-xs-6 {'#13#10 +
    '    padding: 2px 12px;'#13#10 +
    '    display: block;'#13#10 +
    '  }'#13#10 +
    '}'#13#10 +
    ''#13#10 +
    '.col-xs-12 {'#13#10 +
    '  padding: 6px 12px;'#13#10 +
    '  display: table-cell;'#13#10 +
    '}'#13#10 +
    '@media screen and (max-width: 100%) {'#13#10 +
    '  .col-xs-12 {'#13#10 +
    '    padding: 2px 12px;'#13#10 +
    '    display: block;'#13#10 +
    '  }'#13#10 +
    '}'#13#10 +
    '</style>';

procedure AddReportHeaderLine(const S1, S2: string; AStrings: TStrings);
begin
  AStrings.Append('<tr class="row header blue"><td><h3><p class="bg-primary">' + S1 + '</p></h3></td>'
                  + '<td align="right"><h3><p class="bg-primary">' + S2 + '</p></h3></td></tr>');
end;

procedure AddReportSubHeader(const S1: string; AStrings: TStrings);
begin
  AStrings.Append('<tr class="row header blue"><td align="left"><p class="bg-info"><b>Bill To</b></p></td><td align="right">'
                  + '<p class="bg-info"><b>Date: ' + S1 + '</b></p></td></tr>');
end;

procedure AddReportSubHeaderInfo(const S1, S2, S3, S4: string; AStrings: TStrings);
begin
  AStrings.Append('<tr class="row header ltblue"><td align="left"><h4>'
                    + '<p class="bg-info">' + S1 + '</p>'
                    + '<p class="bg-info">' + S2 + '</p>'
                    + '<p class="bg-info">' + S3 + '</p>'
                    + '<p class="bg-info">' + S4 + '</p>'
                    + '</h4></td><td></td></tr>');
end;

procedure AddReportFooterLine(const S1: string; AStrings: TStrings);
begin
  AStrings.Append('<tr class="row header blue"><td colspan="2"><h3><p class="bg-primary" align="center">' + S1 + '</p></h3></td></tr>');
end;

procedure AddInvoiceData(const AName, AQuantity, APrice: string; AStrings: TStrings);
begin
  AStrings.Append(InvoiceTRStart + AName + InvoiceTRMid + AQuantity + InvoiceTRMid + APrice + InvoiceTREnd);
end;

procedure AddInvoiceSection(ALineItemsDataSet: TDataSet; AStrings: TStrings);
begin
  AStrings.Append(InvoiceTStart + InvoiceTHStart + 'Name' + InvoiceTHMid + 'Quantity' +
    InvoiceTHMid + 'Price' + InvoiceTHEnd);
  ALineItemsDataSet.First;
  while not ALineItemsDataSet.Eof do
  begin
    // The invoice is in English: quantities and amounts do not follow the
    // settings of the machine, which would otherwise write 1.234,50 in a
    // document that says $.
    AddInvoiceData(TNetEncoding.HTML.Encode(ALineItemsDataSet.FieldByName('Title').AsString),
                   IntToStr(ALineItemsDataSet.FieldByName('Quantity').AsInteger),
                   FormatCurr('#,##0.00', ALineItemsDataSet.FieldByName('Price').AsCurrency,
                     InvoiceFormat), AStrings);
    ALineItemsDataSet.Next;
  end;
  AStrings.Append(InvoiceTEnd);
end;

function GenerateProposalReport(ADataSet, ALineItemsDataSet: TDataSet): string;
var
  LReport: TStringList;
begin
  LReport := TStringList.Create;
  try
    LReport.Append('<!DOCTYPE html>');
    LReport.Append('<html lang="en"><head>');
    LReport.Append('<meta name="viewport" content="width=device-width; initial-scale=1" />');
    LReport.Append(ProposalCss);
    LReport.Append('</head><body><table width="100%" align="center" cellspacing="0" cellpadding="10" border="0">');
    AddReportHeaderLine(TNetEncoding.HTML.Encode('My Company'),
                        TNetEncoding.HTML.Encode('Invoice'), LReport);
    LReport.Append(EmptyLBRow);
    AddReportSubHeader(TNetEncoding.HTML.Encode(ADataSet.FieldByName('Date').AsString), LReport);
    AddReportSubHeaderInfo(TNetEncoding.HTML.Encode(ADataSet.FieldByName('CompanyName').AsString),
                           TNetEncoding.HTML.Encode(ADataSet.FieldByName('Address1').AsString),
                           TNetEncoding.HTML.Encode(ADataSet.FieldByName('Address2').AsString),
                           TNetEncoding.HTML.Encode(ADataSet.FieldByName('Phone').AsString), LReport);
    LReport.Append(EmptyLBRow);
    LReport.Append(EmptyLBRow);
    AddInvoiceSection(ALineItemsDataSet, LReport);
    LReport.Append(TableTRStart + '</b></td><td align="right">' + '<h2>Total</h2>' + TableTREnd);
    LReport.Append(TableTRStart + '</b></td><td align="right">$' +
      FormatCurr('#,##0.00', ADataSet.FieldByName('Total').AsCurrency, InvoiceFormat) + TableTREnd);
    LReport.Append(EmptyLBRow);
    LReport.Append(EmptyLBRow);
    LReport.Append(EmptyLBRow);
    AddReportFooterLine('Thank you for your business!&nbsp;', LReport);
    LReport.Append('</table></body></html>');
    Result := LReport.Text;
  finally
    LReport.Free;
  end;
end;

function ParseProposalLineItems(const AText: string): TArray<TProposalLineItem>;
var
  LLine, LTitle, LRest: string;
  LItem: TProposalLineItem;
  LAt, LBy: Integer;
begin
  Result := [];
  for LLine in AText.Replace(#13, '').Split([#10]) do
  begin
    if Trim(LLine) = '' then
      Continue;
    LBy := LLine.LastIndexOf('x');
    LAt := LLine.LastIndexOf('@');
    if (LBy < 0) or (LAt < LBy) then
      raise Exception.CreateFmt('I cannot read the line "%s": it must be "title x quantity @ price".', [LLine.Trim]);
    LTitle := LLine.Substring(0, LBy).Trim;
    LRest := LLine.Substring(LBy + 1, LAt - LBy - 1).Trim;
    LItem.Title := LTitle;
    LItem.Quantity := StrToIntDef(LRest, 0);
    // The price is written by the model, not by the user: decimal point, always.
    LItem.Price := StrToCurrDef(LLine.Substring(LAt + 1).Trim.Replace(',', '.'), 0,
      TFormatSettings.Invariant);
    if (LItem.Title = '') or (LItem.Quantity <= 0) then
      raise Exception.CreateFmt('Invalid line: "%s".', [LLine.Trim]);
    Result := Result + [LItem];
  end;
  if Length(Result) = 0 then
    raise Exception.Create('No line to put in the proposal.');
end;

initialization
  InvoiceFormat := TFormatSettings.Create('en-US');

end.
