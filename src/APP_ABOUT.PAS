{ @abstract(This unit contains the about dialog.)
  @author(Jesco Topp <jesco@users.sourceforge.net>)
  @created(unknown)
  @lastmod(last release date)
  This unit contains the about dialog box, where a logo and some version
  information are displayed. Also, this dialog offers to button to view a
  copy of the GNU/GPL and the readme file supplied with this application.}

unit App_About;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls, 
  Buttons, ExtCtrls, jpeg;

type
  { About dialog box. Generated via Delphi's GUI builder. }
  TDlg_About = class(TForm)
    OKBtn: TButton;
    GroupBox1: TGroupBox;
    Btn_DisplayGPL: TButton;
    Btn_DisplayReadme: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label9: TLabel;
    Panel1: TPanel;
    Image1: TImage;
    GroupBox2: TGroupBox;
    { Logo }
    Image2: TImage;
    { Displays the GNU/GPL. Opens @link(TApp_About_GPL).}
    procedure Btn_DisplayGPLClick(Sender: TObject);
    { Displays the readme. Opens @link(TApp_About_Readme).}
    procedure Btn_DisplayReadmeClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

uses App_About_GPL, App_About_Readme;

{$R *.DFM}

procedure TDlg_About.Btn_DisplayGPLClick(Sender: TObject);
var
  Dlg_About_GPL : TDlg_About_GPL;
begin
  Dlg_About_GPL := TDlg_About_GPL.Create( self );
  Dlg_About_GPL.ShowModal;
  Dlg_About_GPL.Free;
end;

procedure TDlg_About.Btn_DisplayReadmeClick(Sender: TObject);
var
  Dlg_About_Readme : TDlg_About_Readme;
begin
  Dlg_About_Readme := TDlg_About_Readme.Create( self );
  Dlg_About_Readme.ShowModal;
  Dlg_About_Readme.Free;
end;

end.
