{ @abstract(This unit contains the dialog to display the GNU/GPL license.)
  @author(Jesco Topp <jesco@users.sourceforge.net>)
  @created(unknown)
  @lastmod(last release date)
  This unit contains the dialog to display the GNU/GPL license.}
unit App_About_GPL;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls, 
  Buttons, ExtCtrls;

type
  { License dialog box. Generated via Delphi's GUI builder. }
  TDlg_About_GPL = class(TForm)
    OKBtn: TButton;
    Bevel1: TBevel;
    Memo1: TMemo;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.DFM}

end.
