{ @abstract(This unit contains the GUI and logic for the log-file.)
  @author(Jesco Topp <jesco@users.sourceforge.net>)
  @created(September 2001)
  @lastmod(23rd Febr. 2002)
  This unit contains the GUI and logic for the log-file. @link(TDlg_ShowLog)
  takes of displaying the logfile at runtime and saving it to disk when
  closing the application.}

unit App_ShowLog;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls, ImgList;

{ icon types }
const
  { icon type: just general information }
  ICO_INFO    = 0;
  { icon type: a warning of possible errors }
  ICO_WARNING = 1;
  { icon type: an error occured }
  ICO_ERROR   = 2;

type
  { This class takes care of displaying the logfile and saving it to disk.
    Items are added with the @link(TDlg_ShowLog.Log) procedure. Only the text
    and the type of the icon must be specified. }
  TDlg_ShowLog = class(TForm)
    OKBtn: TButton;
    Bevel1: TBevel;
    Panel1: TPanel;
    Image1: TImage;
    { image list of available icons }
    IconList: TImageList;
    LogBox: TMemo;
    { self-explanatory, isn't it? }
    procedure FormDestroy(Sender: TObject);
  private
    { array which stores the appropiate icon index into the image list for
      every log message }
    Icon_Type : array[0..32767] of BYTE;
  public
    { updates the log with another message; only interface to the outside world }
    procedure Log( Text : string; Icon : BYTE );
  end;

var
  { instance of the log-box }
  Dlg_ShowLog: TDlg_ShowLog;

implementation

{$R *.dfm}

procedure TDlg_ShowLog.FormDestroy(Sender: TObject);
begin
  LogBox.Lines.SaveToFile( ExtractFilePath( Application.ExeName ) + 'UTX-Viewer.log' );
end;

procedure TDlg_ShowLog.Log;
begin
  LogBox.Lines.Add( Text );
  Icon_Type[LogBox.Lines.Count-1] := Icon;
end;

end.
