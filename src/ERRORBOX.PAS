{ @abstract(Contains a custom error dialog.)
  @author(Andy Ford <fordy@planetunreal.com>)
  @created(December 2000)
  @lastmod(./.)
  Contains a custom error dialog/messagebox, which display the type of
  the error and a support eMail adress. }

unit ErrorBox;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls;

type
  { exception messagebox }
  TfrmError = class(TForm)
    Panel1: TPanel;
    Button1: TButton;
    Bevel1: TBevel;
    Label2: TLabel;
    { content of the exception }
    lblerror: TLabel;
    { support text }
    lblReport: TLabel;
    { support eMail }
    lblWhoTo: TLabel;
    Bevel2: TBevel;
    { simple close procedure }
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.DFM}

procedure TfrmError.Button1Click(Sender: TObject);
begin
  Close;
end;

end.
