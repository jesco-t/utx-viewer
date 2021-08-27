{ @abstract(Abstract implementation of an OpenGL renderer.)
  @author(Jesco Topp <jesco@users.sourceforge.net>)
  @created(January 2002)
  @lastmod(under construction)
  OpenGL_Base.pas contains an abstract implementation of an OpenGL based
  renderer. Only basic things, like creating a rendering context, loading
  algorithms for textures and a DeltaTime based rendering update, are included.
  More specialised sub-classes are used for rendering the actual data. }
unit OpenGL_Base;

//------------------------------------------------------------------------------
interface

uses
        Windows, Graphics, Dialogs, SysUtils,
        UTPFF_Aux, 
        OpenGL, GLAux;
//------------------------------------------------------------------------------

type
  { record which stores the desired properties for the OpenGL
    rendering context. }
  TOpenGL_Info = record
   { Handle of window/control which will be rendered into. }
   Handle        : HWND;
   { Width & height of window/control which is rendered to. (Integer) }
   Width, Height : integer;
   { Desired colour depth. (16, 24, 32 bits) }
   ColorBits     : BYTE;
   { Specifies the maximum allowed size for the textures. }
   TexSize       : integer;
   { Fullscreen (TRUE) or windowed rendering (FALSE). }
   Fullscreen    : Boolean;
end;

type
  { This class provides the basic functionality for a small OpenGL based
    renderer, like setting up the rendering context, loading textures and
    providing a DeltaTime based rendering call. }
  TOpenGL = class(TObject)
    { Storage for @link(TOpenGL_Info) record, which is passed with the
      create procedure. }
    Rendering_Info : TOpenGL_Info;
    { Handle of window/control which will be rendered into. Copied from
      @link(TOpenGL.Rendering_Info).}
    h_WND          : HWND;
    { The appropiate device context. }
    h_DC           : HDC;
    { OpenGL rendering context. }
    h_RC           : HGLRC;
    { Desired colour depth. Copied from @link(TOpenGL.Rendering_Info). }
    ColorBits      : BYTE;
    { Width & height of window/control which is rendered to. (GlFloat) }
    fWidth, fHeight: GLfloat;
    { Width & height of window/control which is rendered to. (Integer) }
    Width, Height  : integer;
    { Constructor }
    constructor Create( const OGL_Info : TOpenGL_Info );
    { Destructor }
    destructor  Destroy; override;
    { Standard .Free procedure. }
    procedure   Free;
  private
    { tick-count of last rendered frame }
    LastTickCount : Int64;
    { Initialise the OpenGL rendering context. }
    procedure CreateRenderingContext;
    { Set up a few parameters for OpenGL, including viewport frustrum and
      dimensions. }
    procedure InitGL;
    { Destroy and free rendering context. }
    procedure KillGL;
  protected
    { Count of all frames rendered since init. Used to calculatea frame-rate
      later. }
    FrameCount    : longint;
    { Contains the references to all textures used by the renderer. References
      are generated in one of the three CreateTexturesFrom* procedures. }
    TextureIndex  : array of GLuint;
    { Specifies the maximum allowed size for the textures. Copied from
      @link(TOpenGL.Rendering_Info). }
    TexSize       : GLuint;
    { Create a texture from a 256 color, palettized TBitmap. Palette must
      be passed as an array of @link(TRGBAQuad) }
    procedure CreateTextureFrom256Bitmap( Bitmap : TBitmap; RGBAQuads : array of TRGBAQuad; Index : Gluint );
    { Create a texture from a TBitmap (any color depth). Procedure is currently
      very slow due to the use of TCanvas.Pixels. }
    procedure CreateTextureFromTBitmap( Bitmap : TBitmap; Index : GLuint );
    { Create a texture from a bitmap file. Bitmap is loaded and passed to
      @link(TOpenGL.CreateTextureFromTBitmap) as a parameter.  }
    procedure CreateTextureFromFile( Filename : string; Index : GLuint );
    { Handles resizing of viewport. }
    procedure ResizeGL( NWidth, NHeight : integer );
    { Abstract procedure to render the scene data. Must be overwritten by
      every decendant of @link(TOpenGL). }
    procedure Render( DeltaTime : longint ); virtual; abstract;
  public
    { RePaint is called to update DeltaTime (in ms) and calls @link(TOpenGL.Render)
      to render the scene. }
    procedure RePaint;
end;

  { Generates texture ids. Imported from OpenGL32.dll }
  procedure glGenTextures(n: GLsizei; var textures: GLuint); stdcall; external opengl32;
  { Binds a texture. Imported from OpenGL32.dll }
  procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;

//------------------------------------------------------------------------------
implementation
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// TOpenGL: basic object for all rendering
//
//------------------------------------------------------------------------------

{ Constructor }
constructor TOpenGL.Create;
begin
  Rendering_Info := OGL_Info;

  h_WND     := OGL_Info.Handle;
  ColorBits := OGL_Info.ColorBits;
  Width     := OGL_Info.Width;
  Height    := OGL_Info.Height;
  TexSize   := OGL_Info.TexSize;

  FrameCount := 0;
  LastTickCount := 0;

  CreateRenderingContext;
end;

{ Destructor }
destructor TOpenGL.Destroy;
begin
  // shutdown OpenGL
  KillGL;
  inherited Destroy;
end;

{ Standard .Free procedure. }
procedure TOpenGL.Free;
begin
  if ( self <> nil ) then Destroy;
end;

{ Initialise the OpenGL rendering context. }
procedure TOpenGL.CreateRenderingContext;
var
  Pixelformat     : GLuint;
  pfd             : TPixelFormatDescriptor;
  fwidth, fheight : GLfloat;
begin
  // describe Pixelformat
  with pfd do
  begin
    nSize:= SizeOf( TPIXELFORMATDESCRIPTOR ); // Size Of This Pixel Format Descriptor
    nVersion:= 1;                            // Version Number (?)
    dwFlags:= PFD_DRAW_TO_WINDOW             // Format Must Support Window
      or PFD_SUPPORT_OPENGL                  // Format Must Support OpenGL
      or PFD_DOUBLEBUFFER;                   // Must Support Double Buffering
    iPixelType:= PFD_TYPE_RGBA;              // Request An RGBA Format
    cColorBits:= ColorBits;                  // Select Our Color Depth
    cRedBits:= 0;                            // Color Bits Ignored
    cRedShift:= 0;
    cGreenBits:= 0;
    cBlueBits:= 0;
    cBlueShift:= 0;
    cAlphaBits:= 0;                          // No Alpha Buffer
    cAlphaShift:= 0;                         // Shift Bit Ignored
    cAccumBits:= 0;                          // No Accumulation Buffer
    cAccumRedBits:= 0;                       // Accumulation Bits Ignored
    cAccumGreenBits:= 0;
    cAccumBlueBits:= 0;
    cAccumAlphaBits:= 0;
    cDepthBits:= 16;                         // 16Bit Z-Buffer (Depth Buffer)
    cStencilBits:= 0;                        // No Stencil Buffer
    cAuxBuffers:= 0;                         // No Auxiliary Buffer
    iLayerType:= PFD_MAIN_PLANE;             // Main Drawing Layer
    bReserved:= 0;                           // Reserved
    dwLayerMask:= 0;                         // Layer Masks Ignored
    dwVisibleMask:= 0;
    dwDamageMask:= 0;
  end;

  // Setup the OpenGL rendering context
  //-----------------------------------
  h_DC := GetDC(h_WND);
  if ( h_DC = 0 ) then  ShowMessage('Failed to obtain h_DC handle');

  PixelFormat := ChoosePixelFormat(h_Dc, @pfd);
  if ( PixelFormat = 0 ) then ShowMessage('Failed to choose PixelFormat');

  if (not SetPixelFormat(h_Dc,PixelFormat,@pfd)) then ShowMessage('Could not set PixelFormat');

  h_Rc := wglCreateContext(h_Dc);
  if (h_Rc=0) then ShowMessage('Could not create rendering context');

  if (not wglMakeCurrent(h_Dc, h_Rc)) then  ShowMessage('Could not make rendering context current');


  // Initialise the OpenGL
  // ---------------------
  InitGL; 
end;

{ Set up a few parameters for OpenGL, including viewport frustrum and dimensions. }
procedure TOpenGL.InitGL;
begin
  ResizeGL( Width, Height );                       //ResizeGL

  glShadeModel(GL_SMOOTH);			   // Enables Smooth Color Shading
  glClearColor(0.0, 0.0, 0.0, 0.5);		   // Black Background
  glClearDepth(1.0);				   // Depth Buffer Setup
  glEnable(GL_DEPTH_TEST);			   // Enables Depth Testing
  glDepthFunc(GL_LESS);				   // The Type Of Depth Test To Do
  glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST);//Realy Nice perspective calculations

  glEnable(GL_TEXTURE_2D);			   // Enable Texture Mapping
end;

{ Handle resizing of viewport. }
procedure TOpenGL.ResizeGL;
begin
  Width   := NWidth;
  Height  := NHeight;
  fwidth  := Width;
  fheight := Height;

  glViewport(0, 0, Width, Height);   // Reset The Current Viewport And Perspective Transformation
  glMatrixMode(GL_PROJECTION);       // Select The Projection Matrix
  glLoadIdentity();                  // Reset The Projection Matrix
  gluPerspective(45.0,fWidth/fHeight,0.1,100.0);// Calculate The Aspect Ratio Of The Window
  glMatrixMode(GL_MODELVIEW);        // Select The Modelview Matrix
  glLoadIdentity;                     //Reset The Modelview Matrix
end;

{ Destroy and free rendering context. }
procedure TOpenGL.KillGL;
begin
  if ( h_RC <> 0 ) then
    begin
      if (not wglMakeCurrent(h_Dc,0)) then
        MessageBox(0,'Release of DC and RC failed.',' Shutdown Error',MB_OK or MB_ICONERROR);
      if (not wglDeleteContext(h_Rc)) then
        begin
          MessageBox(0,'Release of Rendering Context failed.',' Shutdown Error',MB_OK or MB_ICONERROR);
          h_Rc:=0;
        end;
    end;
  if ( h_DC = 1 ) and ( ReleaseDC( h_Wnd,h_DC ) <> 0 ) then
    begin
      MessageBox( 0, 'Release of Device Context failed.', 'Shutdown Error',MB_OK or MB_ICONERROR);
      h_DC := 0;
    end;
end;

{ Create a texture from a 256 color, palettized TBitmap. Palette must be passed
  as an array of @link(TRGBAQuad) }
procedure TOpenGL.CreateTextureFrom256Bitmap;
var
  i, j           : Integer;
  bits           : array[0..255] of array[0..255] of array[0..3] of GLubyte;    // 3D array to hold data
  P              : PByteArray;
begin
  for i := 0 to Bitmap.Height-1 do
  begin
    P := Bitmap.ScanLine[i];
    for j := 0 to Bitmap.Width-1 do
    begin
      bits[i, j, 0] := RGBAQuads[P[j]].r; // red
      bits[i, j, 1] := RGBAQuads[P[j]].g; // Green
      bits[i, j, 2] := RGBAQuads[P[j]].b; // Blue
      bits[i, j, 3] := 255;               // Alpha
    end;
  end;

  glGenTextures(1, TextureIndex[Index]);
  glBindTexture(GL_TEXTURE_2D, TextureIndex[Index]);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,
               Bitmap.Width, Bitmap.Height,                    // dimensions
               0, GL_RGBA, GL_UNSIGNED_BYTE, @bits);
end;

{ Create a texture from a TBitmap (any color depth). Procedure is currently very
  slow due to the use of TCanvas.Pixels. }
procedure TOpenGL.CreateTextureFromTBitmap;
var
  i, j, k        : Integer;
  x, y           : Integer;
  bits           : array[0..255] of array[0..255] of array[0..3] of GLubyte;    // 3D array to hold data
begin
  for i := 0 to Bitmap.Height-1 do
  begin
    for j := 0 to Bitmap.Width-1 do
    begin
      bits[i, j, 0] := GetRValue(Bitmap.Canvas.Pixels[j,i]);  // Red
      bits[i, j, 1] := GetGValue(Bitmap.Canvas.Pixels[j,i]);  // Green
      bits[i, j, 2] := GetBValue(Bitmap.Canvas.Pixels[j,i]);  // Blue
      bits[i, j, 3] := 255;                                   // Alpha
    end;
  end;

  glGenTextures(1, TextureIndex[Index]);
  glBindTexture(GL_TEXTURE_2D, TextureIndex[Index]);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,
               Bitmap.Width, Bitmap.Height,                    // dimensions
               0, GL_RGBA, GL_UNSIGNED_BYTE, @bits);
end;

{ Create a texture from a bitmap file. Bitmap is loaded and passed to
  @link(TOpenGL.CreateTextureFromTBitmap) as a parameter.  }
procedure TOpenGL.CreateTextureFromFile;
var
  Bitmap    : TBitmap;
begin
  try
    Bitmap := TBitmap.Create;
    Bitmap.LoadFromFile( Filename );
    // call other procedure to create texture
    CreateTextureFromTBitmap( Bitmap, Index );
  finally
    Bitmap.Free;
  end;
end;

{ RePaint is called to update DeltaTime and renders scene. }
procedure TOpenGL.RePaint;
var
  DeltaTime          : longint;
  CurrentTickCount   : Int64;
  h, m, s, ms        : word;
begin
  // Calculate DeltaTime
  DecodeTime(Now, h, m, s, ms);
  CurrentTickCount := ms + 1000*s + 1000*60*m + 1000*60*60*h;
  DeltaTime := CurrentTickCount - LastTickCount;

  // Render
  Render( DeltaTime );

  FrameCount := FrameCount + 1;
  DecodeTime(Now, h, m, s, ms);
  LastTickCount := ms + 1000*s + 1000*60*m + 1000*60*60*h;
end;

//------------------------------------------------------------------------------

end.
