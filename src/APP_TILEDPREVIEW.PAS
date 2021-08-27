{ @abstract(This unit contains a form to display textures tiled.)
  @author(Jesco Topp <jesco@users.sourceforge.net>)
  @created(September 2000)
  @lastmod()
  This unit contains a form to display textures tiled. The texture is
  directly written to the canvas of the form. }

unit App_TiledPreview;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  { form to display a texture tiled; the texture is directly written to the
    canvas of the form }
  TDlg_TiledPreview = class(TForm)
    { initialises the form; the texture is passed as a paramter }
    procedure ShowModal(const PreviewTexture : TBitmap); virtual;
    { displays the form and draws the texture directly onto the canvas of the
      form }
    procedure FormShow(Sender: TObject);
    { closes the form }
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    Texture : TBitmap;
  end;

implementation

{$R *.dfm}

procedure TDlg_TiledPreview.ShowModal;
begin
  Texture := TBitmap.Create;

  Texture.Assign( PreviewTexture );  //make texture available for other procedures in this class

  inherited ShowModal;
end;

procedure TDlg_TiledPreview.FormShow(Sender: TObject);
var
  x, y       : integer;
begin
  x := 0;

  repeat
    y := 0; //Reset y-coordinate every new column
    repeat
      Canvas.Draw(x, y, Texture);
      y := y + Texture.Height;
    until (y > Height);
    x := x + Texture.Width;
  until(x > Width);

  //Texture.Free;
end;

procedure TDlg_TiledPreview.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Texture.Free;
end;

end.
