program UTPackage;

uses
  Forms,
  Main in 'Main.pas' {MainForm},
  App_About in 'App_About.pas' {Dlg_About},
  App_About_GPL in 'App_About_GPL.pas' {Dlg_About_GPL},
  App_About_Readme in 'App_About_Readme.pas' {Dlg_About_Readme},
  App_Extract in 'App_Extract.pas' {Dlg_Extract},
  App_Extract_Thread in 'App_Extract_Thread.pas',
  App_Splashscreen in 'App_Splashscreen.pas' {SplashForm},
  App_Preferences in 'App_Preferences.pas' {Dlg_Preferences},
  App_ShowLog in 'App_ShowLog.pas' {Dlg_ShowLog},
  App_TiledPreview in 'App_TiledPreview.pas' {Dlg_TiledPreview},
  App_PackageInfo in 'App_PackageInfo.pas' {Dlg_PackageInfo},
  App_TextureDetails in 'App_TextureDetails.pas' {Dlg_TextureDetails},
  App_FullsizePreview in 'App_FullsizePreview.pas' {Dlg_FullSize},
  ErrorBox in 'ErrorBox.pas' {frmError},
  UTPFF_Load in 'UTPFF_Load.pas',
  UTPFF_Load_Texture in 'UTPFF_Load_Texture.pas',
  UTPFF_Load_Palette in 'UTPFF_Load_Palette.pas',
  UTPFF_Aux in 'UTPFF_Aux.pas',
  OpenGL_Base in 'OpenGL_Base.pas',
  OpenGL_Preview in 'OpenGL_Preview.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'UTX-Viewer';
  Application.HelpFile := '';
  Application.CreateForm(TMainForm, MainForm);
  //Application.CreateForm(TDlg_About, Dlg_About);
  //Application.CreateForm(TDlg_About_GPL, Dlg_About_GPL);
  //Application.CreateForm(TDlg_About_Readme, Dlg_About_Readme);
  Application.CreateForm(TDlg_Extract, Dlg_Extract);
  //Application.CreateForm(TDlg_Preferences, Dlg_Preferences);
  Application.CreateForm(TDlg_ShowLog, Dlg_ShowLog);
  //Application.CreateForm(TfrmError, frmError);
  //Application.CreateForm(TDlg_TiledPreview, Dlg_TiledPreview);
  //Application.CreateForm(TDlg_PackageInfo, Dlg_PackageInfo);
  //Application.CreateForm(TDlg_TextureDetails, Dlg_TextureDetails);
  //Application.CreateForm(TDlg_FullSize, Dlg_FullSize);
  Application.Run;
end.
