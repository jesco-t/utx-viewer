//------------------------------------------------------------------------------
// GUI for UTX-Viewer  
//
//  [- version-constant must be synchronized with build numbers -]
//
//  Global History
//  --------------
//  Version:  Build 7:  - basic gui finished [jt]
//                      - starting to implement the UTPFF (read_only) [jt]
//                 10:  - UTPFF: header & tables work [jt]
//                 11:  - UTPFF: first build of new implementation [jt]
//                 12:  - UTPFF: 50% performance increasement (from build 11 to 12),
//                               size of tables has been decreased [jt]
//                      - GUI: support for previews has been activated [jt]
//                 13:  - GUI: removed dropdown, added package-listing,
//                             added ordinary menu [jt,(fordy)]
//                      - GUI: added "About" dialog [jt]
//                      - GUI: added improved package-filter [jt,(fordy)]
//                      - GUI: bug-fix -- scrolling through previews [jt]
//                 15:  - GUI: started implementing export-functions [jt]
//                 16:  - BASE: ported to Delphi6 [jt]
//                 17:  - UTPFF: fixed some bugs due to port to Delphi6 [jt]
//                      - GUI: both export-dialogs are working, support for
//                             S3TC and MipMaps is disabled  [jt]
//                      - GUI: export single texture implemented, support for
//                             jpeg cancelled [jt]
//                      - GUI: support for packages outside the default package
//                             directory via open-dialog [jt]
//                      - GUI: added nifty splashscreen at startup [jt]
//                 18:  - GUI: preference dialog finished [jt]
//                      - GUI: log-dialog finished [jt]
//                      - BASE: logging implemented [jt]
//                      - GUI: custom exception handler added [jt, fordy]
//                      - GUI: added dialog for TiledPreview [jt]
//                      - GUI: added package information dialog [jt]
//                      - UTPFF: added some funtions to retrieve pkg-info [jt]
//                      - GUI: added Texture Details dialog (copied from v22) [jt]
//                      - UTPFF: minor modifications due to Texture Details [jt]
//                 19:  - BASE: entered beta stages [jt]
//                 20:  - GUI: fixed a few stupid bugs [jt]
//                      - GUI: added copy to clipboard [jt, fordy]
//                      - UTPFF: added exception handler for oversize packages [jt]
//                      - OpenGL: added proper exception handling [jt]
//                 ------ release of version 3.0 ------
//                 21:  - Added Browse functions to Texture & Export directory [Fordy]
//                      - Added new Favorites menu & favourites setup in Preferences [Fordy]
//                      - Added a Trackbar to allow easier Zoom of texture details [Fordy]
//                      - The current Favorite folder becomes the default Folder on exit [Fordy]
//                      - Fix Crash while performance testing if no package loaded [Fordy]
//                      - Gave the GUI a small visual makeover [Fordy]
//                      - Prevented crash on attempted scroll if no package loaded or change of favorites [Fordy]
//                      - Disabled Scrolling by dragging the 'Thumb' on the scroll bar.  If the scroll isnt done
//                        15 textures at a time, the the program loses it's position & can result in scrolling
//                        Past the end or beginning of the textures resulting in a blank viewport. [Fordy]
//                 22:  - Added check for package-signature. Invalid files are now handled correctly [jt]
//                      - Fixed a small bug in handling of favourites [jt]
//                      - Added marker for currently selected texture [jt]
//                      - Added count of textures in current package in package-info dialog [jt]
//                      - Packages are opned as 'read-only' now. This fixes some issues with write-protected files [jt]
//                      - Added dialog for fullsize preview like in v22 [jt]
//                 23:  - Made error form ShowModal [Fordy]
//                      - Fixed texture selection remaining on screen when scrolling of changing favorites [Fordy]
//                 24:  - Disabled Popup-Menu at startup [jt]
//                      - Added compatibility mode for users with 800*600 res. Basically, the most right column
//                        is left away, plus no status bar and logo and smaller package-list [jt]
//                 ------ release of version 3.1 ------
//                 25:  - Error in logging fixed [jt]
//                      - Added support for groups in 'Package Export' dialog [jt]
//                 26:  - Fixed size limit for packages (Oversized-Headers Error)
//                      - 10-15% performance increase in texture extraction (plus another 30% when using
//                        Windows NT/2000/XP) [jt]
//                      - Splashscreen is now displayed for two secs at startup [jt]
//                 27:  - Package list has been replaced by a TreeView;
//                        - new search option; generates a new treenode with all results
//                        - mass extraction currently disabled [jt]
//                      - Removed noisy palettes in packages with S3TC textures; although,
//                        only the non-compressed mipmaps are displayed [jt]
//                 ------ release of version 3.2.0 ------
//                 29:  - some minor code-cleanup [jt]
//                      - new OpenGL renderer for main-window [in progress]; user can choose
//                        which renderer to use [jt]
//                      - rewritten file handling (fixes a nasty error under XP when opening the first package) [jt]
//                      - filename of active package is displayed in the title bar [jt, fordy]
//                 30:  - added shortcuts for most used menu-items [jt]
//                      - started catalogue printing [jt]
//                 ------ release of version 3.3.0 ------
//                 31:  - Added XML code for XP's new gui-styles [eGo]
//
//
//  ToDo: - Show maps that uses specific texture packages (extra popup option), by Cursed Soul
//        - Print out a catalogue (by Spencer Jarvis).
//        - Maybe re-add the profiles from v0.7
//        - Hotkeys for various actions.
//        - Search options for internal groups
//        - Readd support for export to .pcx
//        - Package-writer
//
//  Bugs: - none at all *Cough*
//
// (c) 2000, 2001, 2002, Jesco Topp & Andy Ford
//------------------------------------------------------------------------------
unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, ExtCtrls, StdCtrls, clipbrd, Printers, 
  registry, filectrl, Menus, UTPFF_Load, OleCtrls, OpenGL_Base, OpenGL_Preview; //, SHDocVw;

const
  { version number & name (i.e. beta, private etc) }
  Version = 'UTX-Viewer 3.3.1 - beta';
  { current build number }
  Build   = '31';
  { registry key in which the preferences are stored }
  AppRegKey  = 'Software\Topp\UTX-Viewer-v3.2';

{ record which holds the search results }
type
  USearchList = record
    FileName  : string;
    FilePath  : string;
end;

type
  TMainForm = class(TForm)
    StatusBar: TStatusBar;
    BasePanel: TPanel;
    TexturePopup: TPopupMenu;
    Export2BMP: TMenuItem;
    N1: TMenuItem;
    OpenDetails: TMenuItem;
    TileTexture1: TMenuItem;
    Panel_PkgList: TPanel;
    Panel_Scroll: TPanel;
    PreviewScrollBar: TScrollBar;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Exit1: TMenuItem;
    N3: TMenuItem;
    OpenPackage1: TMenuItem;
    Preferences1: TMenuItem;
    N4: TMenuItem;
    Actions1: TMenuItem;
    Help1: TMenuItem;
    Manual1: TMenuItem;
    N5: TMenuItem;
    About1: TMenuItem;
    ShowTextureDetails1: TMenuItem;
    TilePreview1: TMenuItem;
    Export1: TMenuItem;
    CurrentPackage1: TMenuItem;
    AllPackages1: TMenuItem;
    PerformanceTest1: TMenuItem;
    N7: TMenuItem;
    GroupBox1: TGroupBox;
    PackageWriter1: TMenuItem;
    LoadPreset1: TMenuItem;
    N9: TMenuItem;
    AddtoExistingPackage1: TMenuItem;
    CreateNewPackage1: TMenuItem;
    DisplayLogfile1: TMenuItem;
    GroupBox2: TGroupBox;
    FilterText: TEdit;
    FilterBtn: TButton;
    StatusBarPanel: TPanel;
    PnlStatus: TLabel;
    Utilities1: TMenuItem;
    N6: TMenuItem;
    N8: TMenuItem;
    OpenPackageDlg: TOpenDialog;
    CreateAdd1: TMenuItem;
    N2: TMenuItem;
    Information1: TMenuItem;
    N10: TMenuItem;
    CopytClipboard1: TMenuItem;
    TitlePanel: TPanel;
    image1: TImage;
    lbltitleText: TLabel;
    DisplayTextureFullsize1: TMenuItem;
    DisplayFullsizePreview1: TMenuItem;
    Pkg_TreeView: TTreeView;
    AllPackagesnotrecommended1: TMenuItem;
    OpenGL_Timer: TTimer;
    N11: TMenuItem;
    Print1: TMenuItem;
    CurrentPackage2: TMenuItem;
    N12: TMenuItem;
    AllPackagesinCurrentDirectory1: TMenuItem;
    AllPackages2: TMenuItem;
    PrinterDialog: TPrintDialog;
    procedure CloseBtnClick(Sender: TObject);
    procedure ShowHint(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure PerformanceBtnClick(Sender: TObject);
    procedure PackageListClick(Sender: TObject);
    procedure PreviewScrollBarChange(Sender: TObject;
      ScrollCode: TScrollCode; var ScrollPos: Integer);
    procedure About1Click(Sender: TObject);
    procedure FilterBtnClick(Sender: TObject);
    procedure FilterTextKeyPress(Sender: TObject; var Key: Char);
    procedure CurrentPackage1Click(Sender: TObject);
    procedure AllPackages1Click(Sender: TObject);
    procedure TexPanelMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Export2BMPClick(Sender: TObject);
    procedure OpenPackage1Click(Sender: TObject);
    procedure Preferences1Click(Sender: TObject);
    procedure DisplayLogfile1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TilePreview1Click(Sender: TObject);
    procedure Information1Click(Sender: TObject);
    procedure ShowTextureDetails1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure CopytClipboard1Click(Sender: TObject);
    procedure DisplayTextureFullsize1Click(Sender: TObject);
    procedure Pkg_TreeViewClick(Sender: TObject);
    procedure OpenGL_TimerTimer(Sender: TObject);
    procedure CurrentPackage2Click(Sender: TObject);
  private
    PosTop, PosBot  : Integer;
    PPanel      : array[0..17] of TPanel;  // contains labels and images of each texture
    TexLabel    : array[0..17] of TLabel;  // displays texture name and count
    PkgLabel    : array[0..17] of TLabel;  // displays texture's internal package
    PImg        : array[0..17] of TImage;  // display actual preview of texture
    OpenGLPanel : TPanel;
    procedure MyException(Sender: TObject; E: Exception);
  public
    // package file
    UTPackage_Load : TUTPackage_Load;   // object to load a package
    // init vars
    Directory      : array[0..3] of string;
    Directory_Desc : array[0..3] of string;
    SaveDir        : string;
    OpenGL_TexSize : integer;
    UseOpenGL      : Boolean;
    Resolution     : integer;
    PreviewCount   : integer;
    PreviewRows    : integer;
    PreviewColumns : integer;
    // working vars
    TexId       : integer;
    Fav_Node    : array[0..4] of TTreeNode;
    SearchList  : array[0..1024] of USearchList;
    procedure DrawPreviews( Position : integer);
    procedure App_Log( Text : string; Icon : BYTE );
  end;

var
  MainForm       : TMainForm;         // main window
  OpenGL_Object  : TOpenGL_Preview;

implementation

uses App_About, App_Extract, App_Splashscreen, App_Preferences, App_ShowLog, ErrorBox,
  App_TiledPreview, App_PackageInfo, App_TextureDetails,
  App_FullsizePreview;

{$R *.DFM}
{$R WinXP.res}

//------------------------------------------------------------------------------
// Logging stuff
//
procedure TMainForm.App_Log;
begin
  Text := TimeToStr( now ) + ' - ' + Text;

  Dlg_ShowLog.Log( Text, Icon );
end;

procedure TMainForm.MyException;
var
  frmError : TfrmError;
begin
  App_Log( 'Exception: ' + E.Message, ICO_ERROR );

  frmError := TfrmError.Create( application );
  frmError.lblError.caption := E.Message;
  frmError.showModal;
  frmError.Free;
end;

//------------------------------------------------------------------------------
// Finishing stuff
//
procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
var
  i           : integer;  // simple counter
  Reg         : TRegistry;
begin
  // Free up ressources taken by dynamically created objects
  // (main-window)
  for i:=0 to 17 do
  begin
    PkgLabel[i].Free;
    TexLabel[i].Free;
    PImg[i].Free;
    PPanel[i].Free;
  end;
  // (package-objects)
  UTPackage_Load.Free;

  // Save preferences (like filter)
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;
  Reg.OpenKey(AppRegKey, FALSE);
  Reg.Free;

  //OGL
  OpenGL_Object.Free;
end;

procedure TMainForm.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

//------------------------------------------------------------------------------
// Startup stuff
//

// Initialise application
procedure TMainForm.FormCreate(Sender: TObject);
var
  x,y          : integer;
  Reg          : TRegistry;
  RegSuccess   : Boolean;
  SplashScreen : TSplashForm;
  i,j          : integer;
  tmp_FileList : TFileListBox;
  tmp_File     : File;
begin
  SplashScreen := TSplashForm.Create( application );
  SplashScreen.Show;
  SplashScreen.RePaint;

  // hint handler
  Application.OnHint := ShowHint;
  // exception handler
  Application.OnException := MyException;

  //---------------------
  // Load registry-values
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;
  RegSuccess := Reg.OpenKey(AppRegKey, FALSE);
  if (RegSuccess = FALSE) then
  begin
    // create keys and stanard values
    Reg.OpenKey(AppRegKey, TRUE);
    Reg.WriteString('SaveDir', 'C:\');
    Reg.WriteString('Favourite Path1', '');
    Reg.WriteString('Favourite Desc1', '');
    Reg.WriteString('Favourite Path2', '');
    Reg.WriteString('Favourite Desc2', '');
    Reg.WriteString('Favourite Path3', '');
    Reg.WriteString('Favourite Desc3', '');
    Reg.WriteString('Favourite Path4', '');
    Reg.WriteString('Favourite Desc4', '');
    Reg.WriteInteger('Resolution', 0);
    Reg.WriteInteger('OpenGL_TexSize', 3 );     // 256*256 pixels
    Reg.WriteInteger('Default_Renderer', 0 );   // standard renderer
  end;
  SaveDir    := Reg.ReadString('SaveDir');
  if ( not IsPathDelimiter(SaveDir, Length(SaveDir)) ) then SaveDir := SaveDir + '\';
  Directory[0] := Reg.ReadString('Favourite Path1');
  Directory[1] := Reg.ReadString('Favourite Path2');
  Directory[2] := Reg.ReadString('Favourite Path3');
  Directory[3] := Reg.ReadString('Favourite Path4');
  Directory_Desc[0] := Reg.ReadString('Favourite Desc1');
  Directory_Desc[1] := Reg.ReadString('Favourite Desc2');
  Directory_Desc[2] := Reg.ReadString('Favourite Desc3');
  Directory_Desc[3] := Reg.ReadString('Favourite Desc4');
  if ( not IsPathDelimiter(Directory[0], Length(Directory[0])) ) then Directory[0] := Directory[0] + '\';
  if ( not IsPathDelimiter(Directory[1], Length(Directory[1])) ) then Directory[1] := Directory[1] + '\';
  if ( not IsPathDelimiter(Directory[2], Length(Directory[2])) ) then Directory[2] := Directory[2] + '\';
  if ( not IsPathDelimiter(Directory[3], Length(Directory[3])) ) then Directory[3] := Directory[3] + '\';

  Resolution := Reg.ReadInteger('Resolution');
  case Resolution of
    0 : begin
          PreviewCount   := 15;
          PreviewRows    := 3;
          PreviewColumns := 5;
          PreviewScrollBar.SmallChange := PreviewCount;
        end;
    1 : begin
          PreviewCount   := 12;
          PreviewRows    := 3;
          PreviewColumns := 4;
          PreviewScrollBar.SmallChange := PreviewCount;

          //adjust other controls
          TitlePanel.Hide;
          StatusBar.Hide;
          StatusBarPanel.Hide;
          // remove one column
          Width := Width - 204;
          // move control 30 px to top
          Panel_PkgList.Top := Panel_PkgList.Top - 30;
          BasePanel.Top := BasePanel.Top - 30;
          Panel_Scroll.Height := Panel_Scroll.Height - 30;
          PreviewScrollbar.Height := PreviewScrollbar.Height - 30;
          // make pkg-list 30 px smaller
          Panel_PkgList.Width := Panel_PkgList.Width - 42;
            GroupBox1.Width := GroupBox1.Width - 42;
            Pkg_TreeView.Width := Pkg_TreeView.Width - 42;
            GroupBox2.Width := GroupBox2.Width - 42;
              FilterBtn.Width := FilterBtn.Width - 42;
              FilterText.Width := FilterText.Width - 42;
          // move scroll bar to left
          Panel_Scroll.Left := Panel_PkgList.Left + Panel_PkgList.Width;
          Panel_Scroll.Top  := Panel_Scroll.Top + 2;
          Panel_Scroll.Height := Panel_Scroll.Height - 2;
          // move base panel
          BasePanel.Left := Panel_Scroll.Left + Panel_Scroll.Width;
          Height := Height - 53;
        end;
  end;

  // renderer-stuff
  UseOpenGL := Boolean(Reg.ReadInteger('Default_Renderer'));
  OpenGL_TexSize := Reg.ReadInteger('OpenGL_TexSize');
  case OpenGL_TexSize of
    0: Tex_Size := 2048;
    1: Tex_Size := 1024;
    2: Tex_Size := 512;
    3: Tex_Size := 256;
    4: Tex_Size := 128;
    5: Tex_Size := 64;
    6: Tex_Size := 32;
    7: Tex_Size := 16;
    8: Tex_Size := 8;
  end;
  // End of 'loading registry'
  //--------------------------

  // Choose between the two renderer, only initialise for one
  case UseOpenGL of
    TRUE:
      begin
        // Dynamic creation of OpenGL panel
        OpenGLPanel := TPanel.Create( BasePanel );
        with OpenGLPanel do
        begin
          Left       := 0;
          Top        := 0;
          Width      := 100;
          Height     := 100;
          Color      := clBlack;
          Align      := alClient;
          BevelInner := bvRaised;
          BevelOuter := bvLowered;
          Parent     := BasePanel;
        end;

        // enable timer
        OpenGL_Timer.Enabled := TRUE;
      end;
    FALSE :
      begin
        //-----------------------------------------------------------
        // Dynamic creation of preview-image objects and their labels
        // y=row, x=column
        for y:=0 to PreviewRows-1 do
          for x:=0 to PreviewColumns-1 do
          begin
            // create panels first
            PPanel[PreviewColumns*y+x] := TPanel.Create(BasePanel);
            with PPanel[PreviewColumns*y+x] do
            begin
              Left    := 8 + x*152;
              Top     := 8 + y*185;
              Width   := 145;
              Height  := 177;
              Color   := clBlack;
              BevelInner := bvNone;
              BevelOuter := bvNone;
              Parent  := BasePanel;
            end;
            // create texture-labels
            TexLabel[PreviewColumns*y+x] := TLabel.Create(PPanel[PreviewColumns*y+x]);
            with TexLabel[PreviewColumns*y+x] do
            begin
              Left       := 8;
              Top        := 8;
              Width      := 129;
              Height     := 13;
              AutoSize   := FALSE;
              Alignment  := taCenter;
              Font.Color := clWhite;
              Parent     := PPanel[PreviewColumns*y+x];
            end;
            // create image-objects
            PImg[PreviewColumns*y+x] := TImage.Create(PPanel[PreviewColumns*y+x]);
            with PImg[PreviewColumns*y+x] do
            begin
              Left       := 8;
              Top        := 24;
              Width      := 128;
              Height     := 128;
              AutoSize   := FALSE;
              Center     := TRUE;
              Font.Color := clWhite;
              ShowHint   := TRUE;
              Hint       := 'Right-Click for Options';
              PopupMenu  := TexturePopup;
              Parent     := PPanel[PreviewColumns*y+x];

              // procedure
              OnMouseUp := TexPanelMouseUp;
            end;
            // create package-labels
            PkgLabel[PreviewColumns*y+x] := TLabel.Create(PPanel[PreviewColumns*y+x]);
            with PkgLabel[PreviewColumns*y+x] do
            begin
              Left       := 8;
              Top        := 155;
              Width      := 129;
              Height     := 13;
              AutoSize   := FALSE;
              Alignment  := taCenter;
              Parent     := PPanel[PreviewColumns*y+x];
            end;
          end;
        // End of 'Dynamic object creation'
        //---------------------------------

        // disable popupmenu and markers
        for i:=0 to PreviewCount-1 do
        begin
          TexLabel[i].Hide;
          PkgLabel[i].Hide;
          PImg[i].Hide;
          BasePanel.Repaint;
        end;

        // disable OpenGL timer
        OpenGL_Timer.Enabled := FALSE;
      end;
  end;


  // setting TexId to None
  TexId := - 1;


  // test TreeView
  with Pkg_TreeView.Items do
  begin
    Clear; { remove any existing nodes }

    for i:=0 to 3 do
    begin
      if ( Directory_Desc[i] <> '' ) then
      begin
        Fav_Node[i] := Add(nil, Directory_Desc[i]);

        // Read directory content
        tmp_FileList := TFileListBox.Create( application );
        tmp_FileList.Parent := MainForm;
        tmp_FileList.Visible := FALSE;
        tmp_FileList.Directory := Directory[i];
        tmp_FileList.Mask := '*.UTX;*.UNR;*.U;*.UMX;*.UAX';
        tmp_FileList.Update;

        for j:=0 to tmp_FileList.Items.Count-1 do
        begin
          AddChild(Fav_Node[i], tmp_FileList.Items.Strings[j]);
        end;

        tmp_FileList.Free;
      end;
    end;
  end;

  // sleep for two sec
  Sleep( 2000 );
  // hide splashscreen
  SplashScreen.Close;
  SplashScreen.free;

  // Update caption
  Caption := Version;
  Application.Title := Version;
end;

// Initialise the hint handling routine
procedure TMainForm.ShowHint(Sender: TObject);
begin
  PnlStatus.Caption := '   ' + application.Hint;
end;

// Update logs
procedure TMainForm.FormShow(Sender: TObject);
begin
  App_Log( Version + ' - Build ' + Build + ' started.', ICO_INFO );
  if ( Resolution = 1 ) then
    App_Log( 'Using compatibility mode for low resolutions. 1024*768 is recommended.', ICO_WARNING );

  // Show Extract path in export dialog
  Dlg_Extract.txtExtractTo.Caption := ' Export To: ' + SaveDir;
end;

//------------------------------------------------------------------------------
// Gui handling
//

// Left-Click : Load specified file
procedure TMainForm.Pkg_TreeViewClick(Sender: TObject);
var
  Parent_Node_Text      : string;
  FileDirectory         : string;
  FileName              : string;
  i                     : integer;
  OGL_Info              : TOpenGL_Info;
begin
  if ( Pkg_TreeView.Selected <> nil ) then
    with Pkg_TreeView do
      if ( ExtractFileExt( Selected.Text ) <> '' ) then
      begin
        // Select node is a filename, now build full path and load the file
        Parent_Node_Text := Selected.Parent.Text;

        // search results if neccessary
        if ( Parent_Node_Text = 'Search Results' ) then
        begin
          for i:=0 to Selected.Parent.Count-1 do
            if ( SearchList[i].FileName = Selected.Text ) then
              FileName := SearchList[i].FilePath + SearchList[i].FileName;
        end
        else
        begin
          // normal folders
          for i:=0 to 3 do
            if ( Directory_Desc[i] = Parent_Node_Text ) then
              FileDirectory := Directory[i];

          FileName := FileDirectory + Selected.Text;
        end;

        // Update Caption
        MainForm.Caption := Version + ' - ' + ExtractFileName( FileName );
        RePaint;

        case UseOpenGL of
          TRUE:
            begin
              // OGL stuff
              OGL_Info.Handle     := OpenGLPanel.Handle;
              OGL_Info.Width      := OpenGLPanel.Width;
              OGL_Info.Height     := OpenGLPanel.Height;
              OGL_Info.ColorBits  := 32;
              OGL_Info.TexSize    := Tex_Size;
              OGL_Info.Fullscreen := FALSE;

              OpenGL_Object.Free;
              OpenGL_Object := TOpenGL_Preview.Create( OGL_Info );
              OpenGL_Object.LoadTexturesIntoMemory( Filename );
            end;
          FALSE:
            begin
              // prepare to load & display the file
              PreviewScrollBar.Position := 0;  // synchronize with scrollbar
              UTPackage_Load.Free;

              UTPackage_Load := TUTPackage_Load.Create;  // load package into object
              UTPackage_Load.Load( FileName );

              PreviewScrollBar.Min := 0;  // setup preview scrollbar
              if ( UTPackage_Load.TextureList.Count > 0 ) then
                PreviewScrollBar.Max := UTPackage_Load.TextureList.Count
              else
                PreviewScrollBar.Max := 1;

              DrawPreviews( 0 ); // Draw previews

              PreviewScrollBar.Enabled := True; // Enable scroll bar
            end;
        end;
      end;
end;

// user selected an item in package-dropdown
procedure TMainForm.PackageListClick(Sender: TObject);
var
  FileName     : string;
begin
  // synchronize with scrollbar
  PreviewScrollBar.Position := 0;

  UTPackage_Load.Free;
  UTPackage_Load := TUTPackage_Load.Create;

  UTPackage_Load.Load( FileName );

  // setup preview scrollbar
  PreviewScrollBar.Min := 0;
  if ( UTPackage_Load.TextureList.Count > 0 ) then
    PreviewScrollBar.Max := UTPackage_Load.TextureList.Count
  else
    PreviewScrollBar.Max := 1;

  DrawPreviews( 0 );

  PreviewScrollBar.Enabled := True;
end;

// user clicked the scrollbar to scroll through package
procedure TMainForm.PreviewScrollBarChange(Sender: TObject;
  ScrollCode: TScrollCode; var ScrollPos: Integer);
var
  i     : integer;
begin
  If (ScrollCode = scTrack) then exit;
  // check if package loaded before attempting to scroll
  if UTPackage_Load = nil then exit;

  // clear texture selection on scroll
  for i:=0 to PreviewCount-1 do
    PPanel[i].Color := clBlack;
  TexId := -1;

  // If LargeChange > No of textures available, set next texture to be displayed to current + 1;
  if ScrollPos >= (UTPackage_Load.TextureList.Count) then scrollpos := PosBot + 1;

  if PosBot = (UTPackage_Load.TextureList.Count)
  then Begin
    If (ScrollCode = scLineDown) then exit;
    If (ScrollCode = scPageDown) then exit;
    If (ScrollCode = scEndScroll) then exit;
  End;

  // needed for proper functioning
  if ( PreviewScrollBar.Position = ScrollPos ) then exit;
  DrawPreviews(ScrollPos);
end;

// draw actual previews
procedure TMainForm.DrawPreviews;
var
  i       : integer;
begin
  // first hide all old previews (looks nicer)
  for i:=0 to PreviewCount-1 do
  begin

  // Reset selection marker
    PPanel[i].Color := clBlack;

    TexLabel[i].Hide;
    PkgLabel[i].Hide;
    PImg[i].Hide;
    BasePanel.Repaint;
  end;

  PosTop := 0; PosBot:=1;
  // draw new previews
  for i:=0 to PreviewCount-1 do
  begin
    if ( Position <= UTPackage_Load.TextureList.Count-1 ) then
    begin
    If I = 0 then PosTop := Position + 1;
    PosBot := Position + 1;
      // display name and package
      TexLabel[i].Caption := '[' + IntToStr(Position+1) + '/' + IntToStr(UTPackage_Load.TextureList.Count) + '] - '
                                 + UTPackage_Load.TextureList.Name[Position];
      Texlabel[i].Show;
      TexLabel[i].RePaint;

      PkgLabel[i].Caption := UTPackage_Load.TextureList.Group[Position];
      PkgLabel[i].Show;
      PkgLabel[i].RePaint;
      // display texture
      UTPackage_Load.Load_NormalTexture(Position, 128);
      PImg[i].Picture.Bitmap.Assign(UTPackage_Load.Texture.MipMap);
      Pimg[i].Show;
      PImg[i].RePaint;
    end;

    Position := Position + 1;
  end;
end;

// re-draw OpenGLpreview when timer is triggered
procedure TMainForm.OpenGL_TimerTimer(Sender: TObject);
begin
  if ( OpenGL_Object <> nil ) then
  begin
    OpenGL_Object.RePaint;
  end;
end;

// package filter
procedure TMainForm.FilterBtnClick(Sender: TObject);
var
  SearchPhrase  : string;
  FilePath      : string;
  i, j, k       : integer;
  SearchCount   : integer;
begin
  // init
  SearchPhrase := FilterText.Text;
  SearchCount := 0;

  // do search
  with Pkg_TreeView do
    for i:=0 to 3 do
      if ( Fav_Node[i] <> nil ) then
      begin
        // store path for later use
        for k:=0 to 3 do
          if ( Directory_Desc[k] = Fav_Node[i].Text ) then
            FilePath := Directory[k];

        // cycle through nodes
        for j:=0 to Fav_Node[i].Count-1 do
          if ( Pos( LowerCase( SearchPhrase ), LowerCase( Fav_Node[i].Item[j].Text )) > 0 ) then
          begin
            SearchList[SearchCount].FileName := Fav_Node[i].Item[j].Text;
            SearchList[SearchCount].FilePath := FilePath;

            SearchCount := SearchCount + 1;
          end;
      end;

  // build new node
  with Pkg_TreeView.Items do
  begin
    Fav_Node[4].Free;
    Fav_Node[4] := Add(nil, 'Search Results');

    // fill node
    for i:=0 to SearchCount-1 do
    begin
     AddChild( Fav_Node[4], SearchList[i].FileName );
    end;
  end;
end;

// 'Enter' starts filtering
procedure TMainForm.FilterTextKeyPress(Sender: TObject; var Key: Char);
begin
  if ( Key = #13 ) then
    FilterBtnClick(Sender);
end;

//------------------------------------------------------------------------------
// extract-stuff
//

// extract texture (single, package, complete)
procedure TMainForm.CurrentPackage1Click(Sender: TObject);
begin
  if ( Pkg_TreeView.Selected = nil ) then
  begin
    App_Log( 'No package selected to export.', ICO_WARNING );
    ShowMessage( 'No package selected. Select a package and try again.' );
  end
  else
  begin
    // set properties
    Dlg_Extract.ExtractMode := 1;
    Dlg_Extract.FileName    := UTPackage_Load.Name;
    Dlg_Extract.PkgCount.Caption := '1';

    // show dialog
    Dlg_Extract.ShowModal;
  end;
end;

procedure TMainForm.AllPackages1Click(Sender: TObject);
var
  i       : integer;
begin
{  // set properties
  Dlg_Extract.ExtractMode := 2;
  Dlg_Extract.FileCount   := PackageList.Items.Count;
  Dlg_Extract.PkgCount.Caption := IntToStr( PackageList.Items.Count );
  //for i:=0 to PackageList.Items.Count-1 do
    //Dlg_Extract.FileList[i] := Directory + PackageList.Items.Strings[i];


  // show dialog
  Dlg_Extract.ShowModal;}
end;

// export current texture to bmp
procedure TMainForm.Export2BMPClick(Sender: TObject);
var
  Texture      : TBitmap;
begin
  // logging
  App_Log( 'Extracting texture: ' + UTPackage_Load.TextureList.Name[TexId], ICO_INFO );
  // load texture
  UTPackage_Load.Load_NormalTexture(TexId, 512);

  // save as bmp
  Texture := TBitmap.Create;

  Texture.Assign( UTPackage_Load.Texture.MipMap );
  Texture.SaveToFile( SaveDir + UTPackage_Load.TextureList.Name[TexId] + '.bmp');

  Texture.Free;
end;

// copy current texture to clipboard
procedure TMainForm.CopytClipboard1Click(Sender: TObject);
var
  MyFormat  : Word;
  Texture   : TBitmap;
  AData     : THandle;
  APalette  : HPALETTE;
begin
  Texture := TBitmap.Create;

  try
    UTPackage_Load.Load_NormalTexture( TexId, 512 );

    Texture.Assign( UTPackage_Load.Texture.MipMap );
    Texture.SaveToClipBoardFormat(MyFormat, AData, APalette);
    ClipBoard.SetAsHandle(MyFormat,AData);

    // logging
    App_Log( 'Copied texture ' + ExtractFileName( UTPackage_Load.Name ) + '\' + UTPackage_Load.TextureList.Name[TexId] + ' to clipboard.', ICO_INFO );
  finally
    Texture.Free;
  end;
end;

//------------------------------------------------------------------------------
// printing-stuff
//

procedure TMainForm.CurrentPackage2Click(Sender: TObject);
var
  dpc           : Real;  // dots per centimeter
begin
  //
  // if a package is already selected, the current UTPackage_Load object
  // can be used for printing; otherwise, display a small messagebox which
  // notifies the user that he/she should select a package first
  //
  if ( Pkg_TreeView.Selected = nil ) then
  begin
    App_Log( 'No package selected. Aborting printing.', ICO_WARNING );
    ShowMessage( 'No package selected. Select a package and try again.' );
  end
  else
  begin
    if( PrinterDialog.Execute = TRUE ) then
    begin
      with Printer do
      begin
        // calculate dimensions (assuming the use of DIN-A4)
        // (also assuming that the printer has an auto upper border)
        dpc := PageWidth/21;

        // start printing
        BeginDoc;

        // Header
        Canvas.Font.Name := 'Verdana';
        Canvas.TextOut( Round(2.54*dpc), 0, ExtractFileName( UTPackage_Load.Name ) );
        Canvas.MoveTo( Round(2.54*dpc), Round(0.5*dpc) );
        Canvas.LineTo( PageWidth - Round(2.54*dpc), Round(0.5*dpc) );
        Canvas.TextOut( Round(2.54*dpc), Round(0.7*dpc), 'Generated by ' + Version );

        EndDoc;
      end;
    end;
  end;
end;

//------------------------------------------------------------------------------
// dialog-stuff
//

// Show About-Dialog
procedure TMainForm.About1Click(Sender: TObject);
var
  Dlg_About : TDlg_About;
begin
  Dlg_About := TDlg_About.Create(application);
  Dlg_About.ShowModal;
  Dlg_About.Free;
end;

// Open package dialog
procedure TMainForm.OpenPackage1Click(Sender: TObject);
begin
//  OpenPackageDlg.InitialDir := Directory;
  if ( OpenPackageDlg.Execute ) then
  begin
    // logging                     
    App_log( 'Loading external package: ' + OpenPackageDlg.FileName, ICO_INFO );

    // update caption
    MainForm.Caption := Version + ' - ' + OpenPackageDlg.FileName;

    // synchronize with scrollbar
    PreviewScrollBar.Position := 0;
    
    // destroy any old existing package object
    UTPackage_Load.Free;
    UTPackage_Load := TUTPackage_Load.Create;

    // load package into object
    UTPackage_Load.Load( OpenPackageDlg.FileName );

    // setup previewscrollbar
    PreviewScrollBar.Min := 0;
    if ( UTPackage_Load.TextureList.Count > 0 ) then
      PreviewScrollBar.Max := UTPackage_Load.TextureList.Count-1
    else
      PreviewScrollBar.Max := 1;

    DrawPreviews( 0 );
  end;
end;

// Display preference dialog
procedure TMainForm.Preferences1Click(Sender: TObject);
var
  Dlg_Preferences : TDlg_Preferences;
begin
  Dlg_Preferences := TDlg_Preferences.Create( application );
  Dlg_Preferences.ShowModal;
  Dlg_Preferences.Free;
end;

// Display logfile dialog
procedure TMainForm.DisplayLogfile1Click(Sender: TObject);
begin
  Dlg_ShowLog.ShowModal;
end;

// Display TiledPreview
procedure TMainForm.TilePreview1Click(Sender: TObject);
var
  Dlg_TiledPreview : TDlg_TiledPreview;
begin
  if ( TexId = - 1 ) then
  begin
    ShowMessage( 'No texture and / or no package selected.' );
  end
  else
  begin
    // logging
    App_Log( 'Showing tiled preview of texture: ' + UTPackage_Load.TextureList.Name[TexId], ICO_INFO );

    // load texture
    UTPackage_Load.Load_NormalTexture(TexId, 512);

    Dlg_TiledPreview := TDlg_TiledPreview.Create( application );
    Dlg_TiledPreview.ShowModal( UTPackage_Load.Texture.MipMap );
    Dlg_TiledPreview.Free;
  end;
end;

// Display package info dialog
procedure TMainForm.Information1Click(Sender: TObject);
var
  Dlg_PackageInfo : TDlg_PackageInfo;
begin
  if ( Pkg_TreeView.Selected = nil ) then
  begin
    App_Log( 'No package selected to export.', ICO_WARNING );
    ShowMessage( 'No package selected. Select a package and try again.' );
  end
  else
  begin
    Dlg_PackageInfo := TDlg_PackageInfo.Create( application );
    Dlg_PackageInfo.ShowModal;
    Dlg_PackageInfo.Free;
  end;
end;

// Display TextureDetails dialog
procedure TMainForm.ShowTextureDetails1Click(Sender: TObject);
var
  Dlg_TextureDetails : TDlg_TextureDetails;
begin
  if ( TexId = - 1 ) then
  begin
    ShowMessage( 'No texture and / or no package selected.' );
  end
  else
  begin
    // logging
    App_Log( 'Showing OpenGL based preview of texture: ' + UTPackage_Load.TextureList.Name[TexId], ICO_INFO );

    Dlg_TextureDetails := TDlg_TextureDetails.Create( application );
    Dlg_TextureDetails.ShowModal;
    Dlg_TextureDetails.Free;
  end;
end;

// display texture fullsize
procedure TMainForm.DisplayTextureFullsize1Click(Sender: TObject);
var
  Dlg_Fullsize : TDlg_Fullsize;
begin
  if ( TexId = - 1 ) then
  begin
    ShowMessage( 'No texture and / or no package selected.' );
  end
  else
  begin
    // logging
    App_Log( 'Showing full-size preview of texture: ' + UTPackage_Load.TextureList.Name[TexId], ICO_INFO );

    Dlg_Fullsize := TDlg_Fullsize.Create( application );
    Dlg_Fullsize.ShowModal;
    Dlg_Fullsize.Free;
  end;
end;

//------------------------------------------------------------------------------
// helper functions
//

// get id of currently selected texture and mark it
procedure TMainForm.TexPanelMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  i             : integer;
begin
  for i:=0 to PreviewCount-1 do
    if ( TImage(Sender).Parent = PPanel[i] ) then
    begin
      TexId := i + PreviewScrollBar.Position;
      PPanel[i].Color := clGray;
    end
    else
      PPanel[i].Color := clBlack;
end;

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Testing stuff
//

// performance tests
procedure TMainForm.PerformanceBtnClick(Sender: TObject);
var
  StartTime,
  EndTime      : longint;
  Diff         : longint;
  h, m, s, ms  : word;
  i            : integer;
begin
  Screen.Cursor := crHourGlass;
  // logging
  App_Log(' Starting performance test...', ICO_INFO );

  if UTPackage_Load <> nil then
  Begin;

    // Start
    DecodeTime(Now, h, m, s, ms);
    StartTime := ms + 1000*s + 1000*60*m + 1000*60*60*h;

    // Extract textures
    for i:=0 to UTPackage_Load.TextureList.Count-1 do
    begin
      UTPackage_Load.Load_NormalTexture(i, 32);
    end;

    // End
    DecodeTime(Now, h, m, s, ms);
    EndTime := ms + 1000*s + 1000*60*m + 1000*60*60*h;

    // Eval
    Diff := EndTime - StartTime;

    // logging and output
    App_Log('... finished: ' + FloatToStr(Diff/UTPackage_Load.TextureList.Count) + ' msec. per texture.', ICO_INFO);
  End
 Else
    App_Log('No Package loaded for performance test!', ICO_WARNING);

  Screen.Cursor := crDefault;
  Dlg_ShowLog.ShowModal;
end;

end.
