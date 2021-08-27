{ @abstract(This unit contains the configuration dialog.)
  @author(Jesco Topp <jesco@users.sourceforge.net> & Andy Ford <fordy@planetunreal.com>)
  @created(August 2001)
  @lastmod(January 2002)
  This unit contains the configuration dialog. The config is read/written from/to
  the windows registry. }
unit App_Preferences;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls, registry, dialogs, FileCtrl, ComCtrls;

type
  { configuration form }
  TDlg_Preferences = class(TForm)
    OKBtn: TButton;
    CancelBtn: TButton;
    Panel1: TPanel;
    PageCtrl1: TPageControl;
    tsPref: TTabSheet;
    tsFav: TTabSheet;
    GroupBox1: TGroupBox;
    ExpDirBrowse: TSpeedButton;
    Label3: TLabel;
    grpFav1: TGroupBox;
    BrowseFav1: TSpeedButton;
    edFavDesc1: TEdit;
    Label4: TLabel;
    grpFav2: TGroupBox;
    BrowseFav2: TSpeedButton;
    Label5: TLabel;
    edFavDesc2: TEdit;
    grpFav3: TGroupBox;
    BrowseFav3: TSpeedButton;
    Label6: TLabel;
    edFavDesc3: TEdit;
    grpFav4: TGroupBox;
    BrowseFav4: TSpeedButton;
    Label7: TLabel;
    EdFavDesc4: TEdit;
    edFavPath1: TStaticText;
    EdFavPath2: TStaticText;
    EdFavPath3: TStaticText;
    EdFavPath4: TStaticText;
    SaveDir: TStaticText;
    Image1: TImage;
    TabSheet1: TTabSheet;
    ResBox: TRadioGroup;
    TabSheet2: TTabSheet;
    OpenGL_TexSize: TRadioGroup;
    RenderRadio: TRadioGroup;
    Label1: TLabel;
    RadioGroup2: TRadioGroup;
    Label2: TLabel;
    Label8: TLabel;
    { creates the form and loads the config data from the registry }
    procedure FormShow(Sender: TObject);
    { save all changes to the registry }
    procedure OKBtnClick(Sender: TObject);
    { browses for the 'TEMP' folder }
    procedure ExpDirBrowseClick(Sender: TObject);
    { browses for one of the favourite folders }
    procedure BrowseFav1Click(Sender: TObject);
    { browses for one of the favourite folders }
    procedure BrowseFav2Click(Sender: TObject);
    { browses for one of the favourite folders }
    procedure BrowseFav3Click(Sender: TObject);
    { browses for one of the favourite folders }
    procedure BrowseFav4Click(Sender: TObject);
  end;

implementation

uses Main;

{$R *.dfm}

{ creates the form and loads the config data from the registry }
procedure TDlg_Preferences.FormShow(Sender: TObject);
Var
  Reg         : TRegistry;
  RegSuccess  : Boolean;
begin
  // Load registry-values
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;
  RegSuccess := Reg.OpenKey(AppRegKey, FALSE);
  if (RegSuccess = TRUE) then
  begin
    SaveDir.Caption   := Reg.ReadString('SaveDir');

    edFavPath1.Caption := Reg.ReadString('Favourite Path1');
    edFavDesc1.Text := Reg.ReadString('Favourite Desc1');

    edFavPath2.Caption := Reg.ReadString('Favourite Path2');
    edFavDesc2.Text := Reg.ReadString('Favourite Desc2');

    edFavPath3.Caption := Reg.ReadString('Favourite Path3');
    edFavDesc3.Text := Reg.ReadString('Favourite Desc3');

    edFavPath4.Caption := Reg.ReadString('Favourite Path4');
    edFavDesc4.Text := Reg.ReadString('Favourite Desc4');

    ResBox.ItemIndex := Reg.ReadInteger( 'Resolution' );

    RenderRadio.ItemIndex := Reg.ReadInteger( 'Default_Renderer' );
    OpenGL_TexSize.ItemIndex := Reg.ReadInteger('OpenGL_TexSize');
  end;
end;

{ save all changes to the registry }
procedure TDlg_Preferences.OKBtnClick(Sender: TObject);
var
  Reg           : TRegistry;
  RegSuccess    : Boolean;
begin
  // save changes to registry
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;
  RegSuccess := Reg.OpenKey(AppRegKey, FALSE);
  if (RegSuccess = TRUE) then
  begin
    // save rendering options
    Reg.WriteInteger( 'OpenGL_TexSize', OpenGL_TexSize.ItemIndex );  // TexSize = 2^(11-ItemIndex)
    Reg.WriteInteger( 'Default_Renderer', RenderRadio.ItemIndex );   // 0 : Standard; 1: OpenGL

    // Save Favorites
    if ( not IsPathDelimiter(edFavPath1.Caption, Length(edFavPath1.Caption)))
      and (edFavPath1.Caption<>'')then edFavPath1.Caption := edFavPath1.Caption + '\';
    if ( not IsPathDelimiter(edFavPath2.Caption, Length(edFavPath2.Caption)))
     and (edFavPath2.Caption<>'') then edFavPath2.Caption := edFavPath2.Caption + '\';
    if ( not IsPathDelimiter(edFavPath3.Caption, Length(edFavPath3.Caption)))
     and (edFavPath3.Caption<>'') then edFavPath3.Caption := edFavPath3.Caption + '\';
    if ( not IsPathDelimiter(edFavPath4.Caption, Length(edFavPath4.Caption)))
     and (edFavPath4.Caption<>'') then edFavPath4.Caption := edFavPath4.Caption + '\';

    // save export options
    if ( not IsPathDelimiter(SaveDir.Caption, Length(SaveDir.Caption)) ) then SaveDir.Caption := SaveDir.Caption + '\';
    Reg.WriteString('SaveDir', SaveDir.Caption);

    // If description is blank then blank path too, this will remove from favorites
    If edFavDesc1.Text = '' then edFavPath1.Caption := '';
    If edFavDesc2.Text = '' then edFavPath2.Caption := '';
    If edFavDesc3.Text = '' then edFavPath3.Caption := '';
    If edFavDesc4.Text = '' then edFavPath4.Caption := '';

    // Save favorites
    Reg.WriteString('Favourite Path1', edFavPath1.Caption);
    Reg.WriteString('Favourite Desc1', edFavDesc1.Text);
    Reg.WriteString('Favourite Path2', edFavPath2.Caption);
    Reg.WriteString('Favourite Desc2', edFavDesc2.Text);
    Reg.WriteString('Favourite Path3', edFavPath3.Caption);
    Reg.WriteString('Favourite Desc3', edFavDesc3.Text);
    Reg.WriteString('Favourite Path4', edFavPath4.Caption);
    Reg.WriteString('Favourite Desc4', edFavDesc4.Text);

    // Save resolution
    Reg.WriteInteger('Resolution', ResBox.ItemIndex );
  end;

  // Message to restart the viewer
  Application.MessageBox( 'You have to restart UTX-Viewer in order for any changes to take effect.', 'Information', MB_OK );
  
  // Close dialog
  Close;
end;

{ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     gui-event handler
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
procedure TDlg_Preferences.ExpDirBrowseClick(Sender: TObject);
var
  S: string;
begin
  S := '';
  if SelectDirectory('Select Directory', '', S) then SaveDir.Caption:=S;
end;

procedure TDlg_Preferences.BrowseFav1Click(Sender: TObject);
var
  S: string;
begin
  S := '';
  if SelectDirectory('Select favorite texture folder : 1', '', S)
  then edFavPath1.Caption:=S;
end;

procedure TDlg_Preferences.BrowseFav2Click(Sender: TObject);
var
  S: string;
begin
  S := '';
  if SelectDirectory('Select favorite texture folder : 2', '', S)
  then edFavPath2.Caption:=S;
end;

procedure TDlg_Preferences.BrowseFav3Click(Sender: TObject);
var
  S: string;
begin
  S := '';
  if SelectDirectory('Select favorite texture folder : 3', '', S)
  then edFavPath3.Caption:=S;
end;

procedure TDlg_Preferences.BrowseFav4Click(Sender: TObject);
var
  S: string;
begin
  S := '';
  if SelectDirectory('Select favorite texture folder : 4', '', S)
  then edFavPath4.Caption:=S;
end;

end.
