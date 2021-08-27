{ @abstract(This unit contains a dialog form which displays a texture fullsized.)
  @author(Jesco Topp <jesco@users.sourceforge.net>)
  @created()
  @lastmod()
  This unit contains a dialog form which displays a texture fullsized. The
  Tex-Id from TMainForm is used to determine what tetxure is currently selected.
  (I know that this breaks the principle of encapsulation.)}
unit App_FullsizePreview;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls, Menus, clipbrd;

type
  { Dialog object for fullsize previews. }
  TDlg_FullSize = class(TForm)
    { image object which will hold the texture }
    Image1: TImage;
    Dlg_Menu: TMainMenu;
    Close1: TMenuItem;
    CopytoClipboard1: TMenuItem;
    { closes the form }
    procedure Close1Click(Sender: TObject);
    { brings the form on top and loads the texture }
    procedure FormShow(Sender: TObject);
    { copies texture to clipboard }
    procedure CopytoClipboard1Click(Sender: TObject);
  end;

implementation

uses Main, App_ShowLog;

{$R *.dfm}

procedure TDlg_FullSize.Close1Click(Sender: TObject);
begin
  Close;
end;

procedure TDlg_FullSize.FormShow(Sender: TObject);
var
  Width, Height : integer;
begin
  //load texture
  MainForm.UTPackage_Load.Load_NormalTexture(MainForm.TexId, 512);

  Width  := MainForm.UTPackage_Load.Texture.MipMap.Width;
  Height := MainForm.UTPackage_Load.Texture.MipMap.Height;

  Image1.Picture.Assign( MainForm.UTPackage_Load.Texture.MipMap );

  Height := Height + 45;
  Width  := Width  + 7;
end;

procedure TDlg_FullSize.CopytoClipboard1Click(Sender: TObject);
var
  MyFormat  : Word;
  Texture   : TBitmap;
  AData     : THandle;
  APalette  : HPALETTE;
begin
  Texture := TBitmap.Create;

  try
    MainForm.UTPackage_Load.Load_NormalTexture( MainForm.TexId, 512 );

    Texture.Assign( MainForm.UTPackage_Load.Texture.MipMap );
    Texture.SaveToClipBoardFormat(MyFormat, AData, APalette);
    ClipBoard.SetAsHandle(MyFormat,AData);

    // logging
    MainForm.App_Log( 'Copied texture ' + MainForm.UTPackage_Load.TextureList.Name[MainForm.TexId] + ' to clipboard.', ICO_INFO );
  finally
    Texture.Free;
  end;
end;

end.
