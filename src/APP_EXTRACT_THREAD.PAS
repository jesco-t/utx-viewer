{ @abstract(This unit contains the thread object which takes care of the
            batch-(mass-)extraction of packages.)
  @author(Jesco Topp <jesco@users.sourceforge.net>)
  @created(August 2001)
  @lastmod(unknown)
  This unit contains the thread object which takes care of the
  batch-(mass-)extraction of packages. }
unit App_Extract_Thread;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls, ComCtrls,
  UTPFF_Load;

type
  { Thread object which takes care of the batch-(mass-)extraction of packages. }
  TExtractThread = class(TThread)
  private
    { Calculate/create the information which should be passed to the extract
      dialog @link(TDlg_Extract). Infos include remaining time, textures and
      packages. }
    procedure CreateInfos;
    { Pass the informations to the @link(TDlg_Extract) dialog. }
    procedure UpdateInfos;
    { Calculate the approximate remaining time. This time will be  }
    procedure CalcTime;
  protected
    { the thread's main procedure; all actions take place here. }
    procedure Execute; override;
  end;

var
  { @link(TUTPackage_Load) object; used to load/extract the textures from }
  UTPackage     : TUTPackage_Load;
  { loop variable }
  Cur_Loop      : integer;
  { loop variable }
  i             : integer;

implementation

uses
  App_Extract, Main, App_ShowLog;

var
  StartMsecs    : longint;          // vars to calc remaining time
  RemTime       : TDateTime;
  PasTime       : TDateTime;
  Tex_Counter   : integer;
  Tex_Count     : integer;

//-----------------------------------------------------------------------------_
// Thread
//

procedure TExtractThread.Execute;
var
  j             : integer;
  Directory     : string;
begin
  Dlg_Extract.Btn_Start.Enabled := FALSE;
  Tex_Counter := 0;
  Tex_Count   := StrToInt( Dlg_Extract.TexCount.Caption );

  // extract single
  if ( Dlg_Extract.ExtractMode = 1 ) then
  begin
    // init
    UTPackage := TUTPackage_Load.Create;
    UTPackage.Load( Dlg_Extract.FileName );

    Synchronize( CreateInfos );

    if ( not DirectoryExists( MainForm.SaveDir + Dlg_Extract.CurPkg.Caption ) ) then
      mkDir( MainForm.SaveDir + Dlg_Extract.CurPkg.Caption );

      // extract
    for i:=0 to UTPackage.TextureList.Count-1 do
    begin
      Cur_Loop := i;
      Synchronize( UpdateInfos );
      Synchronize( CalcTime );

      // check if group-structure should be preserve
      if ( Dlg_Extract.Preserve_Groups.Checked = TRUE ) then
      begin
        if ( not DirectoryExists( MainForm.SaveDir + Dlg_Extract.CurPkg.Caption + '\' + UTPackage.TextureList.Group[i] ) ) then
          CreateDir( MainForm.SaveDir + Dlg_Extract.CurPkg.Caption + '\' + UTPackage.TextureList.Group[i] );
        Directory := MainForm.SaveDir + Dlg_Extract.CurPkg.Caption + '\' + UTPackage.TextureList.Group[i] + '\';
      end
      else
        Directory := MainForm.SaveDir + Dlg_Extract.CurPkg.Caption + '\';

      // save texture
      UTPackage.Load_NormalTexture( i, 512 );
      UTPackage.Texture.MipMap.SaveToFile( Directory + UTPackage.TextureList.Name[i] + '.bmp');

      if ( Terminated ) then
      begin
        // logging
        MainForm.App_Log( 'Extraction process cancelled by user.', ICO_WARNING );

        break;
      end;
    end;

    UTPackage.Free;
  end;

  // extract all packages
  if ( Dlg_Extract.ExtractMode = 2 ) then
  begin
    for j:=0 to Dlg_Extract.FileCount-1 do
    begin
      // init
      UTPackage := TUTPackage_Load.Create;
      UTPackage.Load( Dlg_Extract.FileList[j] );

      Synchronize( CreateInfos );

      if ( not DirectoryExists( MainForm.SaveDir + Dlg_Extract.CurPkg.Caption ) ) then
        mkDir( MainForm.SaveDir + Dlg_Extract.CurPkg.Caption );

      // extract
      for i:=0 to UTPackage.TextureList.Count-1 do
      begin
        Cur_Loop := i;
        Synchronize( UpdateInfos );
        Synchronize( CalcTime );

      // check if group-structure should be preserve
      if ( Dlg_Extract.Preserve_Groups.Checked = TRUE ) then
      begin
        if ( not DirectoryExists( MainForm.SaveDir + Dlg_Extract.CurPkg.Caption + '\' + UTPackage.TextureList.Group[i] ) ) then
          CreateDir( MainForm.SaveDir + Dlg_Extract.CurPkg.Caption + '\' + UTPackage.TextureList.Group[i] );
        Directory := MainForm.SaveDir + Dlg_Extract.CurPkg.Caption + '\' + UTPackage.TextureList.Group[i] + '\';
      end
      else
        Directory := MainForm.SaveDir + Dlg_Extract.CurPkg.Caption + '\';

      // save texture
      UTPackage.Load_NormalTexture( i, 512 );
      UTPackage.Texture.MipMap.SaveToFile( Directory + UTPackage.TextureList.Name[i] + '.bmp');

      if ( Terminated ) then
      begin
        // logging
        MainForm.App_Log( 'Extraction process cancelled by user.', ICO_WARNING );

        break;
      end;
      end;

      UTPackage.Free;

      if ( Terminated ) then break;
    end;
  end;
  Dlg_Extract.Btn_Start.Enabled := TRUE;
end;

//-----------------------------------------------------------------------------_

procedure TExtractThread.CreateInfos;
begin
  // show first stats
  Dlg_Extract.CurPkg.Caption := ExtractFileName( UTPackage.Name );

  // init progressbars
  Dlg_Extract.CurPrg.Min := 0;
  Dlg_Extract.CurPrg.Max := UTPackage.TextureList.Count;
  Dlg_Extract.CurPrg.Step := 1;
  Dlg_Extract.CurPrg.Position := 0;

  // logging
  MainForm.App_Log( 'Extracting package ' + Dlg_Extract.CurPkg.Caption + ' ( ' + IntToStr( UTPackage.TextureList.Count ) + ' Textures )', ICO_INFO );
end;

procedure TExtractThread.UpdateInfos;
begin
  Dlg_Extract.CurTex.Caption := UTPackage.TextureList.Name[Cur_Loop];
  Dlg_Extract.RePaint;
  Dlg_Extract.CurPrg.StepIt;
  Dlg_Extract.ComPrg.StepIt;

  if ( Dlg_Extract.Preserve_Groups.Checked = TRUE ) then
    Dlg_Extract.txtExtractTo.Caption := MainForm.SaveDir + Dlg_Extract.CurPkg.Caption + '\' + UTPackage.TextureList.Group[i]
  else
    Dlg_Extract.txtExtractTo.Caption := MainForm.SaveDir + Dlg_Extract.CurPkg.Caption;
end;

//------------------------------------------------------------------------------

// Calculate remaining time
procedure TExtractThread.CalcTime;
var
  RemMsecs      : longint;
  PasMsecs      : longint;
  ComMsecs      : longint;
  h, m, s, msec : word;
begin
  // either get start time or calculate remaining time
  if ( Tex_Counter = 0 ) then
  begin
    DecodeTime( Time, h, m, s, msec );
    StartMsecs := msec + s*1000 + m*60*1000 + h*60*60*1000;
  end
  else
  begin
    // get current time difference
    DecodeTime( Time, h, m, s, msec );
    PasMsecs := msec + s*1000 + m*60*1000 + h*60*60*1000;
    PasMsecs := PasMsecs - StartMsecs;

    // approximate time to complete job
    ComMsecs := Round( ( PasMsecs / Tex_Counter ) * Tex_Count );

    // remaining time
    RemMsecs := ComMsecs - PasMsecs;

    // format ouput for passed time
    h := Trunc( PasMsecs / 3600000 );
    m := Trunc( ( PasMsecs - h*3600000 ) / 60000 );
    s := Trunc( ( PasMsecs - h*3600000 - m*60000 ) / 1000 );
    PasTime := EncodeTime( h, m, s, 0 );
    Dlg_Extract.lblTime.Caption := TimeToStr( PasTime );

    // format output for remaining time
    h := Trunc( RemMsecs / 3600000 );
    m := Trunc( ( RemMsecs - h*3600000 ) / 60000 );
    s := Trunc( ( RemMsecs - h*3600000 - m*60000 ) / 1000 );
    RemTime := EncodeTime( h, m, s, 0 );
    Dlg_Extract.lblTimeLeft.Caption := TimeToStr( RemTime );

  end;

  Tex_Counter := Tex_Counter + 1;
end;

//-----------------------------------------------------------------------------_

end.
