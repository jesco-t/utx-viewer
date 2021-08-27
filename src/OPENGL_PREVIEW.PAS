{ @abstract(Contains a descendant of @link(TOpenGL). Implements the renderer
            of the main form. )
  @author(Jesco Topp <jesco@users.sourceforge.net>)
  @created(January 2002)
  @lastmod()
  Contains the specialized OpenGL renderer, which is used to render the previews
  on the main form. @link(TOpenGL_Preview) descends from @link(TOpenGL). The
  previews are rendered row-to-column wise.}
unit OpenGL_Preview;

//------------------------------------------------------------------------------
interface

uses
        Windows, Graphics, Dialogs,
        OpenGL, GLAux,
        OpenGL_Base;

//------------------------------------------------------------------------------

type
  { record to store the vertices, normal, texture id and aspect ratio of a
    textured quad. }
  TVertexQuad = record
    { vertex coordinates (x|y|z) for each corner of the quad }
    v1, v2, v3, v4 : array[0..2] of Glfloat;
    { normal vector of quad }
    n              : array[0..2] of Glfloat;
    { texture id }
    Texture        : Gluint;
    { texture coordinates }
    t1, t2, t3, t4 : array[0..1] of Glfloat;
    { aspect ratio of selected texture (needed for calculating the ratio of the quad);
      stored as x:y }
    Ratio          : Glfloat;
  end;

type
  { Specialized class for rendering the previews of the main-form. The
    previews are rendered row-to-column wise. }
  TOpenGL_Preview = class(TOpenGL)
    { Constructor }
    constructor Create( const OGL_Info : TOpenGL_Info );
    { Destructor }
    destructor  Destroy; override;
    { Standard .Free procedure }
    procedure   Free;
  protected
    { Overwritten render procedure. Renders the data stored in the
      @link(TOpenGL_Preview.VertexQuad) array. }
    procedure Render( DeltaTime : longint ); override;
  public
    { number of columns }
    Columns   : integer;
    { count of textures to preview }
    TexCount  : integer;
    { load & initialise textures }
    procedure LoadTexturesIntoMemory( FileName : string );
  private
    { array of @link(TVertexQuad) which holds the data on each quad which
      should be rendered }
    VertexQuad : array of TVertexQuad;
    { generates the coordinates for each quad based on
      @link(TOpenGL_Preview.Columns). }
    procedure GenerateVertexCoordinates;
end;

//------------------------------------------------------------------------------
implementation

uses
  UTPFF_Load;
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// TOpenGL_Preview
//
//------------------------------------------------------------------------------

//
// Constructor and destructor
//
constructor TOpenGL_Preview.Create;
begin
  Columns := 5; // temporary
  inherited Create( OGL_Info );
end;

destructor TOpenGL_Preview.Destroy;
begin
  inherited Destroy;
end;

procedure TOpenGL_Preview.Free;
begin
  if ( self <> nil ) then Destroy;
end;


//
//  Load & initialise textures
//
procedure TOpenGL_Preview.LoadTexturesIntoMemory;
var
  PFile : TUTPackage_Load;         // object for texture package
  i     : integer;
begin
  try
    // Load package
    PFile := TUTPackage_Load.Create;
    PFile.Load( FileName );

    // Reserve space for textures
    TexCount := PFile.TextureList.Count;
    Setlength( TextureIndex, TexCount );
    SetLength( VertexQuad, TexCount );

    // Load and generate each texture
    for i:=0 to TexCount-1 do
    begin
      PFile.Load_NormalTexture( i, {TexSize}256 );

      CreateTextureFrom256Bitmap( PFile.Texture.MipMap, PFile.Texture.Pal.Color, i );
      VertexQuad[i].Texture := i+1;
      VertexQuad[i].Ratio := PFile.Texture.MipMap.Width / PFile.Texture.MipMap.Height;
    end;
  finally
    PFile.Free;
  end;
end;

//
//  Update & Render
//
procedure TOpenGL_Preview.Render;
var
  i,j    : integer;
begin
  // Initialise
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  glLoadIdentity();

  // Calculate vertex coordinates
  GenerateVertexCoordinates;

  // temp
  glTranslatef( 0.0, 2.2, 0.0 );

  // render each texture quad
  for i:=0 to TexCount-1 do
    with VertexQuad[i] do
    begin
      // enable texture-mapping
      glBindTexture( GL_TEXTURE_2D, Texture );

      // render vertices of quad
      glBegin( GL_QUADS );
        glTexCoord2f( t1[0],  t1[1]);     glVertex3f( v1[0], v1[1], v1[2] );
        glTexCoord2f( t2[0],  t2[1]);     glVertex3f( v2[0], v2[1], v2[2] );
        glTexCoord2f( t3[0],  t3[1]);     glVertex3f( v3[0], v3[1], v3[2] );
        glTexCoord2f( t4[0],  t4[1]);     glVertex3f( v4[0], v4[1], v4[2] );

        glNormal3f( n[0], n[1], n[2] );
      glEnd();
    end;

  SwapBuffers(h_DC);
end;

//
// Generate coordinates of each vertex
//
procedure TOpenGL_Preview.GenerateVertexCoordinates;
var
  hSpace       : Glfloat;     // space between quads (horizontal), border to border
  vSpace       : Glfloat;     // space between quads (vertical), center to center
  LeftX        : Glfloat;
  xSize, ySize : Glfloat;     // texture sizes
  x, y, z      : Glfloat;     // current position in 3d space (similiar to glTranslatef)
  Passed       : integer;
  i,j          : integer;
begin
  // Space between quads, later to be modified in real-time
  hSpace := 0.4;
  vSpace := -1.5;

  // Initialise a few things
  Passed := 0;                  // nothing done yet
  x := 0;                       // \
  y := 0;                       //  } origin
  z := 0;                       // /

  // First, move into depth
  x :=  0.0;
  y :=  0.0;
  z := -6.0;

  // Calculate vertex coordinates for each quad
  for j:=0 to Trunc( TexCount/Columns + 1) do
  begin
    // Calculate each quad in a row
    for i:=0 to Columns-1 do
    begin
      if ( Passed < TexCount ) then
      begin
        // Calculate left x coordinate (relative to origin)
        LeftX := 0 - ( (Columns/2) + (((Columns-1)*hSpace)/2) );   // base value
        LeftX := LeftX + (1.0 + hSpace)*i;                         // move from left to right

        // calc vertices for texture-quad (order: upper left/right, lower right/left)
        // calc normal vector
        // calc texture coordinates
        with VertexQuad[Passed] do
        begin
          // vertices
          v1[0] := LeftX + x;
          v1[1] := y - 1.0;
          v1[2] := z;

          v2[0] := LeftX + x + 1.0;
          v2[1] := y - 1.0;
          v2[2] := z;

          v3[0] := LeftX + x + 1.0;
          v3[1] := y;
          v3[2] := z;

          v4[0] := LeftX + x;
          v4[1] := y;
          v4[2] := z;

          // normal
          n[0] := 0.0;
          n[1] := 0.0;
          n[2] := 1.0;

          // texture coordinates
          if ( Ratio = 1 ) then
          begin
            xSize := 1.0;
            ySize := 1.0;
          end;
          if ( Ratio < 1 ) then
          begin
            xSize := Ratio;
            ySize := 1.0;
          end;
          if ( Ratio > 1 ) then
          begin
            xSize := 1.0;
            ySize := Ratio;
          end;

          t1[0] := 0.0;
          t1[1] := ySize;;

          t2[0] := xSize;
          t2[1] := ySize;

          t3[0] := xSize;
          t3[1] := 0.0;

          t4[0] := 0.0;
          t4[1] := 0.0;
        end;

        Passed := Passed + 1;
      end
      else
        break;
    end;

    // move down for next row
    x := x;
    y := y + vSpace;
    z := z;
  end;
end;

end.
