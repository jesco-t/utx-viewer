{ @abstract(Dialog for texture-mass-extraction.)
  @author(Jesco Topp <jesco@users.sourceforge.net>)
  @created(August 2001)
  @lastmod(unknown)
  Dialog for mass-extraction of textures. Depending on the parameters, either
  only one single package is extracted or all packages in the current directory.
  The extraction takes place in a seperate thread class: @link(TExtractThread). }
unit App_Extract;

{ ---------------
  ToDo: - MipMaps
        - S3TC
  --------------- }

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls, ComCtrls, UTPFF_Load, UTPFF_Aux,
  App_Extract_Thread;

type
  { Dialog for mass extraction of textures. This is dialog reads the Extraction
    Mode variable and determines if it shall extract only a single package or a
    complete folder.}
  TDlg_Extract = class(TForm)
    CancelBtn: TButton;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label3: TLabel;
    PkgCount: TLabel;
    TexCount: TLabel;
    GroupBox2: TGroupBox;
    Extract_MipMaps: TCheckBox;
    Preserve_Groups: TCheckBox;
    Btn_Start: TButton;
    GroupBox3: TGroupBox;
    ComPrg: TProgressBar;
    CurPrg: TProgressBar;
    Label4: TLabel;
    Label23: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    CurPkg: TLabel;
    CurTex: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    lblTime: TLabel;
    lblTimeLeft: TLabel;
    Panel1: TPanel;
    Image1: TImage;
    txtExtractTo: TStaticText;
    { Starts the extraction process. }
    procedure Btn_StartClick(Sender: TObject);
    { Does some precalculations (like determining the amount of textures/packages) }
    function  ShowModal : Integer; override;
    { Cancels extraction process }
    procedure CancelBtnClick(Sender: TObject);
    { Currently disabled }
    procedure FormShow(Sender: TObject);
  private
    { thread object which extracts the actual textures: @link(TExtractThread) }
    ExtractThread    : TExtractThread;
    { boolean variable which shows if a extraction process is currently in
      progress}
    InProgress       : Boolean;
    { Controls the extraction-thread for a single package }
    procedure Single;
    { Controls the extraction-thread for a multiple packages }
    procedure Complete;
  public
    { path & name of texture package }
    FileName    : string;
    { index of texture into ExportTable (only if single texture will be
      exported) }
    TextureId   : integer;
    { array which contains a list of all packages including pathes (only if all
      packages in current directory will be extracted) }
    FileList    : array[0..512] of string;
    { count of packages in list (only if all packages will be extracted) }
    FileCount   : integer;
    { Extraction Mode: 1 - single package;
                       2 - all packages in current directory }
    ExtractMode : BYTE;
  end;

var
  { instance of dialog }
  Dlg_Extract      : TDlg_Extract;

implementation

uses Main, App_Preferences, App_ShowLog;

{$R *.DFM}

//------------------------------------------------------------------------------
// init dialog
//
function TDlg_Extract.ShowModal;
var
  UTX_File      : TUTPackage_Load;   // temporary object to get texture count
  i             : integer;
  tmp_TexCount  : integer;
begin
  // alter caption of dialog
  case ExtractMode of
  1: begin
       PkgCount.Caption := '1';

       UTX_File := TUTPackage_Load.Create;
       UTX_File.Load( FileName );
       TexCount.Caption := IntToStr( UTX_File.TextureList.Count );
       UTX_File.Free;
     end;
  2: begin
       PkgCount.Caption := IntToStr( FileCount );

       tmp_TexCount := 0;
       for i:=0 to FileCount-1 do
       begin
         UTX_File := TUTPackage_Load.Create;
         UTX_File.Load( FileList[i] );
         tmp_TexCount := tmp_TexCount + UTX_File.TextureList.Count;
         UTX_File.Free;
       end;

       TexCount.Caption := IntToStr( tmp_TexCount );
     end;
  end;

  // clear from previous run
  ComPrg.Position := 0;
  CurPrg.Position := 0;

  CurPkg.Caption := ' ';
  CurTex.Caption := ' ';

  CancelBtn.Caption := '&Cancel';
  InProgress := FALSE;

  ExtractThread.Free;

  Result := inherited ShowModal;
end;

//------------------------------------------------------------------------------
// extract textures
//

// user started extraction-process
procedure TDlg_Extract.Btn_StartClick(Sender: TObject);
begin
  // check mode
  case ExtractMode of
    1 : begin
          Single;
        end;
    2 : begin
          Complete;
        end;
  end;
end;

// extract single package
procedure TDlg_Extract.Single;
begin
  InProgress := TRUE;

  ComPrg.Min := 0;
  ComPrg.Max := StrToInt( TexCount.Caption );
  ComPrg.Step := 1;
  ComPrg.Position := 0;

  ExtractThread := TExtractThread.Create(FALSE);

  // logging
  MainForm.App_Log( 'Extracting ' + PkgCount.Caption + ' package ( ' + TexCount.Caption + ' Textures )', ICO_INFO );
end;

// extract complete package-list
procedure TDlg_Extract.Complete;
begin
  InProgress := TRUE;

  ComPrg.Min := 0;
  ComPrg.Max := StrToInt( TexCount.Caption );
  ComPrg.Step := 1;
  ComPrg.Position := 0;

  ExtractThread := TExtractThread.Create(FALSE);

  // logging
  MainForm.App_Log( 'Extracting ' + PkgCount.Caption + ' packages ( ' + TexCount.Caption + ' Textures )', ICO_INFO );
end;

procedure TDlg_Extract.CancelBtnClick(Sender: TObject);
begin
  if ( InProgress ) then
    ExtractThread.Terminate;
end;

// Show extraction path
procedure TDlg_Extract.FormShow(Sender: TObject);
begin
//  txtExtractTo.Caption := 'To : ' + Dlg_Preferences.SaveDir.Caption;
end;

end.
