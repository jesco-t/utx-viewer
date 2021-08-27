{ @abstract(This unit contains a form which displays some extended information
            the currently selected package.)
  @author(Jesco Topp <jesco@users.sourceforge.net>)
  @created(Ocotber 2001)
  @lastmod()
  This unit contains a form which displays some extended information the
  currently selected package. }

unit App_PackageInfo;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls;

type
  { form which displays information on texture packages }
  TDlg_PackageInfo = class(TForm)
    OKBtn: TButton;
    Panel1: TPanel;
    Image1: TImage;
    GroupBox1: TGroupBox;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    ConTex: TLabel;
    ConMus: TLabel;
    ConSnd: TLabel;
    ConGeo: TLabel;
    ConScr: TLabel;
    ConMod: TLabel;
    Label10: TLabel;
    FileName: TLabel;
    Path: TLabel;
    Size: TLabel;
    PkgVer: TLabel;
    TexCount: TLabel;
    { initialises the form and loads the right data }
    procedure FormShow(Sender: TObject);
  end;


implementation

uses Main;

{$R *.dfm}

procedure TDlg_PackageInfo.FormShow(Sender: TObject);
var
  Tex, Mus, Snd, Mdl, Geo, Scri : Boolean;
begin
  // General
  FileName.Caption := ExtractFileName( MainForm.UTPackage_Load.Name );
  Path.Caption     := ExtractFilePath( MainForm.UTPackage_Load.Name );
  Size.Caption     := FloatToStrF( MainForm.UTPackage_Load.Size/(1024*1024), ffFixed, 2, 2 ) + ' MB';

  // Details
  PkgVer.Caption := IntToStr( MainForm.UTPackage_Load.PkgVer );

  // Get Package Information on content
  MainForm.UTPackage_Load.Get_PackageInformation( Tex, Mus, Snd, Geo, Mdl, Scri );

  if ( Tex = TRUE ) then
  begin
   ConTex.Caption := 'TRUE';
   TexCount.Caption := '( ' + IntToStr( MainForm.UTPackage_Load.TextureList.Count ) + ' Textures )';
  end
  else
  begin
    ConTex.Caption := 'FALSE';
    TexCount.Caption := '';
  end;
  if ( Mus = TRUE ) then ConMus.Caption := 'TRUE' else ConMus.Caption := 'FALSE';
  if ( Snd = TRUE ) then ConSnd.Caption := 'TRUE' else ConSnd.Caption := 'FALSE';
  if ( Geo = TRUE ) then ConGeo.Caption := 'TRUE' else ConGeo.Caption := 'FALSE';
  if ( Mdl = TRUE ) then ConMod.Caption := 'TRUE' else ConMod.Caption := 'FALSE';
  if ( Scri = TRUE ) then ConScr.Caption := 'TRUE' else ConScr.Caption := 'FALSE';
end;

end.
