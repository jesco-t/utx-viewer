{ @abstract(This unit contains the dialog to display the readme file.)
  @author(Jesco Topp <jesco@users.sourceforge.net>)
  @created(unknown)
  @lastmod(last release date)
  This unit contains the dialog to display the readme file.}
unit App_About_Readme;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  App_About_GPL, StdCtrls, ExtCtrls;

type
  { Readme dialog box. Generated via Delphi's GUI builder. }
  TDlg_About_Readme = class(TDlg_About_GPL)
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

implementation

{$R *.DFM}

end.
