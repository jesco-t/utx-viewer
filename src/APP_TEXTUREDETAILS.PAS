{ @abstract(This unit contains a form which displays some extended details on
            the currently selected texture.)
  @author(Jesco Topp <jesco@users.sourceforge.net> & Andy Ford <fordy@planetunreal.com>)
  @created(January 2001)
  @lastmod(October 2001)
  This unit contains a form which displays some extended details on the
  currently selected texture. (used renderer is outdated, will be replaced
  with the new extended renderer)}
unit App_TextureDetails;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls, 
  Buttons, ExtCtrls, dialogs, jpeg, OpenGL, GLAux, ComCtrls;

const
  { zoom factor, used to translate in and out }
  ZoomFactor: Real  = 0.4;

//------------------------------------------------------------------------------
// dialog declaration

type
  { form which displays extended infos on a texture and display the texture
    itself (fully animated, if possible) using OpenGL }
  TDlg_TextureDetails = class(TForm)
    OKBtn: TButton;
    GroupBox7: TGroupBox;
    Label12: TLabel;
    Label14: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label23: TLabel;
    Label24: TLabel;
    Label25: TLabel;
    LabelNumberofFrames: TLabel;
    LabelMinFrameRate: TLabel;
    LabelMaxFrameRate: TLabel;
    TextureName: TLabel;
    TextureDimensions: TLabel;
    TextureSize: TLabel;
    TextureMipMapCount: TLabel;
    TexturebMasked: TLabel;
    TextureIsAnimated: TLabel;
    TextureFrameCount: TLabel;
    TextureMinFramerate: TLabel;
    TextureMaxFramerate: TLabel;
    Label30: TLabel;
    TexturePackage: TLabel;
    PropertyMemo: TMemo;
    GroupBox5: TGroupBox;
    OpenGLPanel: TPanel;
    Panel1: TPanel;
    OpenGLTimer: TTimer;
    ZoomBar: TTrackBar;
    imgZoomin: TImage;
    Image2: TImage;
    Image1: TImage;
    procedure FormShow(Sender: TObject);
    procedure FormHide(Sender: TObject);
    { updates the output }
    procedure OpenGLTimerTimer(Sender: TObject);
    { initialises OpenGL }
    function  CreateOpenGL( const WindowHandle : HWND; Width, Height : integer ) : Boolean;
    { destroys OpenGL }
    function  KillOpenGL  : Boolean;
    { loads the texture (and all other parts of the animation if needed) }
    function  LoadTextures: TStrings;
    { renders the scene }
    procedure DrawGL;
    { zooms in and out of the texture }
    procedure ZoomGL( Factor : real );
    { zoom bar handler }
    procedure ZoomBarChange(Sender: TObject);
    { zoom bar handler }
    procedure imgZoominClick(Sender: TObject);
    { zoom bar handler }
    procedure Image2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

//------------------------------------------------------------------------------

  { Generates texture ids. Imported from OpenGL32.dll }
  procedure glGenTextures(n: GLsizei; var textures: GLuint); stdcall; external opengl32;
  { Binds a texture. Imported from OpenGL32.dll }
  procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;

//------------------------------------------------------------------------------

var
  { window handle of the control in which should be rendered to }
  h_WND         : HWND;
  { device context of the control in which should be rendered to }
  h_DC          : HDC;
  { OpenGL rendering context of the control in which should be rendered to }
  h_RC          : HGLRC;
  { array for the texture indices }
  Texture       : array [0..99] of GLuint;
  z, OrigZoom   : GLfloat;
  Tex_Size      : integer;
  TexName       : string;
  TexWidth      : integer;
  TexHeight     : integer;
  Animate       : Boolean;
  FrameCount    : integer;
  MinFrameRate  : single;
  MaxFrameRate  : single;
  CurFrame      : integer;

implementation

uses Main, App_ShowLog;

{$R *.dfm}

//------------------------------------------------------------------------------
// GUI

procedure TDlg_TextureDetails.FormShow(Sender: TObject);
var
  GenericProperties          : TStrings;
begin
  // Init
  GenericProperties := TStringList.Create;
  PropertyMemo.Lines.Clear;

  // Reset trackbar 
  ZoomBar.Position := 0;

  // Load texture
  MainForm.UTPackage_Load.Load_NormalTexture( MainForm.TexId, 256);

  // Fill in infos on current texture
  with MainForm.UTPackage_Load do
  begin
    TextureName.Caption          := Texture.Name;
    TexturePackage.Caption       := ExtractFileName( Name );
    TextureDimensions.Caption    := IntToStr( Texture.USize ) + ' x ' + IntToStr( Texture.VSize );
    TextureSize.Caption          := FloatToStrF( ExportTable.SerialSize[ TextureList.ETIndex[MainForm.TexId] ]/(1024), ffFixed, 4, 2 ) + ' KB';
    TextureMipMapCount.Caption   := IntToStr( Texture.MipMapCount );
    case Texture.bMasked of
      TRUE  : TexturebMasked.Caption := 'TRUE';
      FALSE : TexturebMasked.Caption := 'FALSE';
    end;
    case Texture.IsAnimated of
      TRUE  :
        begin
          TextureIsAnimated.Caption := 'TRUE';
          LabelNumberofFrames.Enabled := TRUE;
          LabelMinFrameRate.Enabled := TRUE;
          LabelMaxFrameRate.Enabled := TRUE;
          TextureFrameCount.Enabled := TRUE;
          TextureMinFrameRate.Enabled := TRUE;
          TextureMaxFrameRate.Enabled := TRUE;
        end;
      FALSE :
        begin
          TextureIsAnimated.Caption := 'FALSE';
          LabelNumberofFrames.Enabled := FALSE;
          LabelMinFrameRate.Enabled := FALSE;
          LabelMaxFrameRate.Enabled := FALSE;
          TextureFrameCount.Enabled := FALSE;
          TextureMinFrameRate.Enabled := FALSE;
          TextureMaxFrameRate.Enabled := FALSE;
        end;
    end;
  end;
  MinFrameRate := MainForm.UTPackage_Load.Texture.MinFrameRate;
  MaxFrameRate := MainForm.UTPackage_Load.Texture.MaxFrameRate;

  // Create OpenGL windows
  with OpenGLPanel do
    CreateOpenGL(Handle, Width, Height);

  // Load textures and read generic properties
  GenericProperties.AddStrings( LoadTextures );
  PropertyMemo.Lines.AddStrings( GenericProperties );

  // FrameCount info (needs all textures to be loaded)
  TextureFrameCount.Caption := IntTostr( FrameCount );
  TextureMinFrameRate.Caption := FloatToStr( MinFrameRate );
  TextureMaxFrameRate.Caption := FloatToStr( MaxFrameRate );

  // Adjust timer to FrameRate
  if ( MinFrameRate <> 0 ) then
    OpenGLTimer.Interval := Round(1000 / MinFrameRate);
  if ( MaxFrameRate <> 0 ) then
    OpenGLTimer.Interval := Round(1000 / MaxFrameRate);
  if ( MinFrameRate + MaxFrameRate = 0 ) then
      OpenGLTimer.Interval := 40;

  // Finish
  GenericProperties.Free;

  // Draw
  DrawGL;

  //Scale Texture
  ZoomGL(OrigZoom);
end;

procedure TDlg_TextureDetails.FormHide(Sender: TObject);
begin
  // Destroy OpenGl
  KillOpenGL;
end;

// Refresh
procedure TDlg_TextureDetails.OpenGLTimerTimer(Sender: TObject);
begin
  DrawGL;
end;

//------------------------------------------------------------------------------
// OpenGL
//

//------------------------------------------------------------------------------
// Init and destroy

// Create a new OpenGL rendering context (needs a HWND, width and height)
function TDlg_TextureDetails.CreateOpenGL;
var
  Pixelformat     : GLuint;                    // Holds The Result After Searching For A Match
  pfd             : TPixelFormatDescriptor;    // Tells Windows How We Want Things To Be
  fwidth, fheight : GLfloat;
begin
  MainForm.App_Log( 'Initialising OpenGL subsystem...', ICO_INFO );

  // copy temporary handle to permanent one in this unit
  h_WND := WindowHandle;

  with pfd do    //Tells Windows How We Want Things To Be
  begin
    nSize:= SizeOf( TPIXELFORMATDESCRIPTOR ); // Size Of This Pixel Format Descriptor
    nVersion:= 1;                            // Version Number (?)
    dwFlags:= PFD_DRAW_TO_WINDOW             // Format Must Support Window
      or PFD_SUPPORT_OPENGL                  // Format Must Support OpenGL
      or PFD_DOUBLEBUFFER;                   // Must Support Double Buffering
    iPixelType:= PFD_TYPE_RGBA;              // Request An RGBA Format
    cColorBits:= 16;                         // Select Our Color Depth
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

  h_DC := GetDC(h_WND);
  if ( h_DC = 0 ) then
  begin
    ShowMessage('Failed to obtain h_DC handle');
    MainForm.App_Log( 'Failed to obtain h_DC handle.', ICO_ERROR );
  end;
  PixelFormat := ChoosePixelFormat(h_Dc, @pfd);               // Finds The Closest Match To The Pixel Format We Set Above
  if ( PixelFormat = 0 ) then
  begin
    ShowMessage('Failed to choose PixelFormat');
    MainForm.App_Log( 'Failed to choose PixelFormat.', ICO_ERROR );
  end;
  if (not SetPixelFormat(h_Dc,PixelFormat,@pfd)) then         // Are We Able To Set The Pixelformat?
  begin
    ShowMessage('Could not set PixelFormat');
    MainForm.App_Log( 'Could not set PixelFormat.', ICO_ERROR );
  end;
  h_Rc := wglCreateContext(h_Dc);                             // Are We Able To Get A Rendering Context?
  if (h_Rc=0) then
  begin
    ShowMessage('Could not create rendering context');
    MainForm.App_Log( 'Could not create rendering context.', ICO_ERROR );
  end;
  if (not wglMakeCurrent(h_Dc, h_Rc)) then                    // Are We Able To Activate The Rendering Context?
  begin
    ShowMessage('Could not make rendering context current');
    MainForm.App_Log( 'Could not make rendering context current.', ICO_ERROR );
  end;

  // ReSizeGL
  fwidth := Width;
  fheight := Height;

  glViewport(0, 0, Width, Height);   // Reset The Current Viewport And Perspective Transformation
  glMatrixMode(GL_PROJECTION);       // Select The Projection Matrix
  glLoadIdentity();                  // Reset The Projection Matrix
  gluPerspective(45.0,fWidth/fHeight,0.1,100.0);// Calculate The Aspect Ratio Of The Window
  glMatrixMode(GL_MODELVIEW);        // Select The Modelview Matrix
  glLoadIdentity;                     //Reset The Modelview Matrix

  //InitGL
  glShadeModel(GL_SMOOTH);			   // Enables Smooth Color Shading
  glClearColor(0.0, 0.0, 0.0, 0.5);		   // Black Background
  glClearDepth(1.0);				   // Depth Buffer Setup
  glEnable(GL_DEPTH_TEST);			   // Enables Depth Testing
  glDepthFunc(GL_LESS);				   // The Type Of Depth Test To Do
  glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST);//Realy Nice perspective calculations

  glEnable(GL_TEXTURE_2D);			   // Enable Texture Mapping

  // set maximum texture size
  case MainForm.OpenGL_TexSize of
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

  // set initial zoom
  case MainForm.OpenGL_TexSize of
    0: z := -16;
    1: z := -8;
    2: z := -4;
    3: z := -2;
    4: z := -2;
    5: z := -1;
    6: z := -0.5;
    7: z := -0.25;
    8: z := -0.125;
  end;
  // Save Initial Zoom
  OrigZoom := z;
  Result := TRUE;
end;

// Destroy an OpenGL rendering context
function TDlg_TextureDetails.KillOpenGL;
begin
  MainForm.App_Log( 'Shutting down OpenGL subsystem...', ICO_INFO );
  if h_rc<>0 then                                                               //Is There A Rendering Context?
    begin
      if (not wglMakeCurrent(h_Dc,0)) then                                      //Are We Able To Release Dc and Rc contexts?
        MessageBox(0,'Release of DC and RC failed.',' Shutdown Error',MB_OK or MB_ICONERROR);
        MainForm.App_Log( 'Release of DC and RC failed.', ICO_ERROR );
      if (not wglDeleteContext(h_Rc)) then                                      //Are We Able To Delete The Rc?
        begin
          MessageBox(0,'Release of Rendering Context failed.',' Shutdown Error',MB_OK or MB_ICONERROR);
          MainForm.App_Log( 'Release of Rendering Context failed.', ICO_ERROR );
          h_Rc:=0;                                                              //Set Rc To Null
        end;
    end;
  if (h_Dc=1) and (releaseDC(h_Wnd,h_Dc)<>0) then                               //Are We Able To Release The Dc?
    begin
      MessageBox(0,'Release of Device Context failed.',' Shutdown Error',MB_OK or MB_ICONERROR);
      MainForm.App_Log( 'Release of Device Context failed.', ICO_ERROR );
      h_Dc:=0;                                                                  //Set Dc To Null
    end;
  Result := TRUE;
end;

//------------------------------------------------------------------------------
// Draw

// Draw the OpenGL output
procedure TDlg_TextureDetails.DrawGL;
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT); // Clear The Screen And The Depth Buffer
  glLoadIdentity();		      // Reset The View
  glTranslatef(0.0,0.0,z);

  glBindTexture(GL_TEXTURE_2D, Texture[CurFrame]);

  glBegin(GL_QUADS);
    glNormal3f(  0.0,  0.0,   1.0);   // Normal vector

      glTexCoord2f( 0.0,  1.0);
    glVertex3f( -TexWidth/200,  TexHeight/200,   0.0);   // upper left

      glTexCoord2f( 1.0,  1.0);
    glVertex3f(  TexWidth/200,  TexHeight/200,   0.0);   // upper right

      glTexCoord2f( 1.0,  0.0);
    glVertex3f(  TexWidth/200,  -TexHeight/200,   0.0);   // lower right

      glTexCoord2f( 0.0,  0.0);
    glVertex3f( -TexWidth/200,  -TexHeight/200,   0.0);   // lower left

  glEnd();

  if ( CurFrame + 1 > FrameCount-1 ) then CurFrame := 0 else CurFrame := CurFrame + 1;

  SwapBuffers(h_DC);
end;

// Load current textures and convert them to OpenGL
function TDlg_TextureDetails.LoadTextures;
var
  texture1   : PTAUX_RGBImageRec;
  ConvJPEG   : TJPEGImage;
  ConvBitmap : TBitmap;
  FileName   : string;
  AnimNext   : string;
  i          : integer;
  Properties : TStrings;
begin
  // Init
  Properties := TStringList.Create;
  FrameCount := 0;
  MinFrameRate := 0;
  MaxFrameRate := 0;

  // Load texture and save it to disk temporary   (*ugly*)
  MainForm.UTPackage_Load.Load_NormalTexture( MainForm.TexId , Tex_Size);

  ConvJPEG := TJPEGImage.Create;
  ConvJPEG.PixelFormat := jf24bit;
  ConvJPEG.Assign( MainForm.UTPackage_Load.Texture.MipMap );

  ConvBitmap := TBitmap.Create;
  ConvBitmap.Assign(ConvJPEG);
  ConvBitmap.SaveToFile( MainForm.SaveDir + 'OGL.BMP' );
  ConvBitmap.Free;
  ConvJPEG.Free;

  // Get texture infos
  TexWidth  := MainForm.UTPackage_Load.Texture.Mipmap.Width;
  TexHeight := MainForm.UTPackage_Load.Texture.Mipmap.Height;
  TexName   := MainForm.UTPackage_Load.Texture.Name;
  MainForm.UTPackage_Load.Texture.Read_GenericTextureProperties( Properties );


  // Load Texture
  texture1 := auxDIBImageLoadA(PChar(MainForm.SaveDir + 'OGL.BMP'));
  if (not Assigned(texture1)) then
     Halt(1);

  // Create Texture
  glGenTextures(1, texture[0]);
  glBindTexture(GL_TEXTURE_2D, texture[0]);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
  glTexImage2D(GL_TEXTURE_2D, 0, 3, texture1^.sizeX, texture1^.sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, texture1^.data);

  // Delete all temporary files
  FileName := MainForm.SaveDir + 'OGL.BMP';
  DeleteFile(PChar(FileName));

  // Load following frames if texture is animated
  if ( MainForm.UTPackage_Load.Texture.IsAnimated = TRUE ) then
  begin
    Animate := TRUE;
    FrameCount := 1;

    // Find AnimNext and load it
    repeat
      AnimNext := MainForm.UTPackage_Load.Texture.AnimNext;

      if ( MainForm.UTPackage_Load.Texture.HasMaxFrameRate = TRUE ) then
        MaxFrameRate := MainForm.UTPackage_Load.Texture.MaxFrameRate;
      if ( MainForm.UTPackage_Load.Texture.HasMinFrameRate = TRUE ) then
        MinFrameRate := MainForm.UTPackage_Load.Texture.MinFrameRate;

      for i:=0 to MainForm.UTPackage_Load.TextureList.Count-1 do
      begin
        if ( MainForm.UTPackage_Load.TextureList.Name[i] = AnimNext ) then
        begin
          // Load texture  and save it to disk temporary   (*ugly*)
          MainForm.UTPackage_Load.Load_NormalTexture( i, Tex_Size);

          ConvJPEG := TJPEGImage.Create;
          ConvJPEG.PixelFormat := jf24bit;
          ConvJPEG.Assign(MainForm.UTPackage_Load.Texture.Mipmap);

          ConvBitmap := TBitmap.Create;
          ConvBitmap.Assign(ConvJPEG);
          ConvBitmap.SaveToFile(MainForm.SaveDir + 'OGL.BMP');
          ConvBitmap.Free;
          ConvJPEG.Free;

          // Generic Properties
          MainForm.UTPackage_Load.Texture.Read_GenericTextureProperties( Properties );

          // Load Texture
          texture1 := auxDIBImageLoadA(PChar(MainForm.SaveDir + 'OGL.BMP'));
          if (not Assigned(texture1)) then
            Halt(1);

          // Create Texture
          glGenTextures(1{FrameCount+1}, texture[FrameCount]);
          glBindTexture(GL_TEXTURE_2D, texture[FrameCount]);
          glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
          glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
          glTexImage2D(GL_TEXTURE_2D, 0, 3, texture1^.sizeX, texture1^.sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, texture1^.data);

          // Delete all temporary files
          FileName := MainForm.SaveDir + 'OGL.BMP';
          DeleteFile(PChar(FileName));

          FrameCount := FrameCount + 1;

          break;
        end;
      end;

      // Additional break condition
      if ( AnimNext = '' ) then
        break;
    until ( AnimNext = TexName );
  end
  else
    Animate := FALSE;

  // Return value
  Result := TStringList.Create;
  Result.AddStrings(Properties);
  //Result.Free;
  Properties.Free;
end;

// Zoom In & Out with track bar
procedure TDlg_TextureDetails.ZoomGL;
begin
  // positive values = zoom in
  // negative values = zoom out
  z := OrigZoom + Factor;
end;

procedure TDlg_TextureDetails.ZoomBarChange(Sender: TObject);
Var
 r : real;
begin
  // Zoom in/out
  r := (ZoomBar.Position * ZoomFactor);
  r := (OrigZoom + r);
  ZoomGL(r);
end;

// Zoom in
procedure TDlg_TextureDetails.imgZoominClick(Sender: TObject);
Var
 r : real;
begin
  if ZoomBar.Position < ZoomBar.Max then
  Begin
    ZoomBar.Position := ZoomBar.Position+1;
    r := (ZoomBar.Position * ZoomFactor);
    r := (OrigZoom + r);
    ZoomGL(r);
  End;
end;

// Zoom out
procedure TDlg_TextureDetails.Image2Click(Sender: TObject);
Var
 r : real;
begin
  if ZoomBar.Position > ZoomBar.Min then
  Begin
    ZoomBar.Position := ZoomBar.Position-1;
    r := (ZoomBar.Position * ZoomFactor);
    r := (OrigZoom + r);
    ZoomGL(r);
  End;
end;

end.
