//------------------------------------------------------------------------------
// TUTPackage_Load : base-class for loading packages
//
// (c) 2000, 2001, Jesco Topp & Andy Ford
//------------------------------------------------------------------------------

unit UTPFF_Load;

interface

uses Windows, SysUtils, Classes,                                                         // base
     Dialogs,                                                                   // debug
     UTPFF_Aux, UTPFF_Load_Texture;                // user


//------------------------------------------------------------------------------
type
  TUTPackage_Load = class(TObject)
    // global header (partially)
    Signature     : longint;
    PkgVer        : longint;
    PkgFlags      : longint;
    NameCount     : longint;
    NameOffset    : longint;
    ExportCount   : longint;
    ExportOffset  : longint;
    ImportCount   : longint;
    ImportOffset  : longint;
    // Tables
    NameTable     : TNameTable;
    ImportTable   : TImportTable;
    ExportTable   : TExportTable;
    // init & finish stuff
    constructor Create;
    destructor  Destroy; override;
    procedure   Free;
  public
    // general
    Name          : string;                 // filename of the package
    Size          : Int64;                  // filesize ---   ""   ---
    TextureList   : TTextureList;           // list of all textures
    Hstr          : TFileStream;
    Str_Handle    : integer;
    // texture-objects
    Texture       : TTexture_Load;          // object for loading normaltextures
    procedure   Load( FileName : string );  // load the file specified in FileName
    procedure   Load_NormalTexture( ListIndex : integer; MaxPreviewSize : integer );
    procedure   Get_PackageInformation( var Tex, Mus, Snd, Geo, Mdl, Scri : Boolean );
  private
    IsPkgOpen     : Boolean;
    procedure   Read_Header;      // reads the global headers
    procedure   Read_Tables;      // reads name-, import- and export-table
    procedure   Build_ObjectReferences;  // creates all neccessary object-references (requieres complete tables)
    function    Evaluate_ObjectReference( Value : longint): string;
    procedure   Build_TextureList;  // builds list of all available textures
end;
//------------------------------------------------------------------------------


implementation

uses Main, App_ShowLog;

//------------------------------------------------------------------------------
// Load a file

procedure TUTPackage_Load.Load;
begin
  try
    MainForm.App_Log( 'Loading package ' + ExtractFileName( FileName ) + '...', ICO_INFO);

    Hstr := TFileStream.Create( FileName, fmOpenRead );
    IsPkgOpen := TRUE;

    Str_Handle := HStr.Handle;
    Name := FileName;
    Size := Hstr.Size;

    // Read global header, tables, build object-references & TextureList
    Read_Header;
    Read_Tables;
    Build_ObjectReferences;
    Build_TextureList;

    MainForm.App_Log( '...successfully loaded ' + IntToStr( TextureList.Count ) + ' textures.', ICO_INFO );
  except
    Hstr.Free;
    MainForm.App_Log( '... action failed.', ICO_ERROR);
  end;
end;

// Read global header
procedure TUTPackage_Load.Read_Header;
begin
  HStr.ReadBuffer( Signature, 4 );
  HStr.ReadBuffer( PkgVer, 4 );
  HStr.ReadBuffer( PkgFlags, 4 );
  HStr.ReadBuffer( NameCount, 4 );
  HStr.ReadBuffer( NameOffset, 4 );
  HStr.ReadBuffer( ExportCount, 4 );
  HStr.ReadBuffer( ExportOffset, 4 );
  HStr.ReadBuffer( ImportCount, 4 );
  HStr.ReadBuffer( ImportOffset, 4 );
  // the rest of the header is unimportant and therefore skipped

  // check for package-signature
  if ( Signature <> -1641380927 ) then
    raise EHeaderTableException.Create( 'Invalid file format. File ' + ExtractFileName ( Name ) + ' does not appear to be a unreal texture package.' );

  // Initialise Table Arrays
  NameTable := TNameTable.Create( NameCount, NameOffset );
  ImportTable := TImportTable.Create( ImportCount, ImportOffset );
  ExportTable := TExportTable.Create( ExportCount, ExportOffset );
  // Initialise TextureList Array
  TextureList := TTextureList.Create( ExportCount );
end;

// reads name-, import- and export-table
procedure TUTPackage_Load.Read_Tables;
var
  i           : integer;  // counter
begin
  // NameTable
  Hstr.Seek(  NameOffset, soFromBeginning );
  for i:=0 to NameCount-1 do
  begin
    NameTable.ObjectName[i] := Read_NAME( Str_Handle, PkgVer );
    HStr.ReadBuffer( NameTable.ObjectFlags[i], 4 );
  end;

  // ImportTable
  Hstr.Seek(  ImportOffset, soFromBeginning );
  for i:=0 to ImportCount-1 do
  begin
    ImportTable.ClassPackage[i] := NameTable.ObjectName[Read_INDEX( Str_Handle )];
    ImportTable.ClassName[i]    := NameTable.ObjectName[Read_INDEX( Str_Handle )];
    HStr.ReadBuffer( ImportTable.ImportPackage_ObjRef[i], 4 );  // ObjRef
    ImportTable.ObjectName[i]   := NameTable.ObjectName[Read_INDEX( Str_Handle )];
  end;

  // ExportTable
  Hstr.Seek( ExportOffset, soFromBeginning );
  for i:=0 to ExportCount-1 do
  begin
    ExportTable.ExportClass_ObjRef[i]   := Read_INDEX( Str_Handle );  // ObjRef
    ExportTable.Super_ObjRef[i]         := Read_INDEX( Str_Handle );  // ObjRef
    HStr.ReadBuffer( ExportTable.ExportPackage_ObjRef[i], 4 );  // ObjRef
    ExportTable.ObjectName[i]           := NameTable.ObjectName[Read_INDEX( Str_Handle )];
    HStr.ReadBuffer( ExportTable.ObjectFlags[i], 4 );
    ExportTable.SerialSize[i]           := Read_INDEX( Str_Handle );
    if ( ExportTable.SerialSize[i] > 0 ) then
      ExportTable.SerialOffset[i]       := Read_INDEX( Str_Handle );
  end;
end;

// creates all neccessary object-references (requieres complete tables)
procedure TUTPackage_Load.Build_ObjectReferences;
var
  i       : integer;
begin
  for i:=0 to ImportCount-1 do
  begin
    ImportTable.ImportPackage[i] := Evaluate_ObjectReference( ImportTable.ImportPackage_ObjRef[i] );
  end;
  for i:=0 to ExportCount-1 do
  begin
    ExportTable.ExportClass[i]   := Evaluate_ObjectReference( ExportTable.ExportClass_ObjRef[i] );
    ExportTable.Super[i]         := Evaluate_ObjectReference( ExportTable.Super_ObjRef[i] );
    ExportTable.ExportPackage[i] := Evaluate_ObjectReference( ExportTable.ExportPackage_ObjRef[i] );
  end;
end;

// Evaluate Object-Reference (placed here due to massive performance-increase)
function TUTPackage_Load.Evaluate_ObjectReference;
begin
  if (Value = 0) then Result := '';
  if (Value < 0) then Result := ImportTable.ObjectName[-Value-1];
  if (Value > 0) then Result := ExportTable.ObjectName[Value-1];
end;

// builds list of all available textures
procedure TUTPackage_Load.Build_TextureList;
var
  i       : integer;
begin
  TextureList.Count := 0;
  for i:=0 to ExportCount-1 do
    with TextureList do
      if ( ExportTable.ExportClass[i] = 'Texture' ) then
      begin
        Name[Count]    := ExportTable.ObjectName[i];
        Group[Count]   := ExportTable.ExportPackage[i];
        ETIndex[Count] := i;
        Count := Count + 1;
      end;
end;
//------------------------------------------------------------------------------
// load a normaltexture
procedure TUTPackage_Load.Load_NormalTexture;
begin
  // logging
  //MainForm.App_Log( 'Loading texture: ' + TextureList.Name[ListIndex] + '. Maximum size is ' + IntToStr(MaxPreviewSize) + '*' + IntToStr(MaxPreviewSize), ICO_INFO );;

  Texture.Free;
  Texture := TTexture_Load.Create;

  Texture.Load( Str_Handle,
                NameTable, ImportTable, ExportTable,
                TextureList.Name[ListIndex], TextureList.ETIndex[ListIndex],
                MaxPreviewSize, PkgVer );
end;

//------------------------------------------------------------------------------
// Init & Finish stuff
constructor TUTPackage_Load.Create;
begin
  IsPkgOpen := FALSE;
end;

destructor TUTPackage_Load.Destroy;
begin
  NameTable.Free;
  ImportTable.Free;
  ExportTable.Free;

  TextureList.Free;
  Texture.Free;
  if ( IsPkgOpen = TRUE ) then
    Hstr.Free;

  inherited Destroy;
end;

procedure TUTPackage_Load.Free;
begin
  if ( self <> nil ) then Destroy;
end;

//------------------------------------------------------------------------------
// statistical stuff

procedure TUTPackage_Load.Get_PackageInformation;
var
  i        : integer;
begin
  // logging
  MainForm.App_Log( 'Reading extended package-information... ' + ExtractFileName( Name ), ICO_INFO );

  // check for textures
  Tex := FALSE;
  for i:=0 to ExportCount-1 do
    if ( ExportTable.ExportClass[i] = 'Texture' ) then
      Tex := TRUE;

  // check for music
  Mus := FALSE;
  for i:=0 to ExportCount-1 do
    if ( ExportTable.ExportClass[i] = 'Music' ) then
      Mus := TRUE;

  // check for sound
  Snd := FALSE;
  for i:=0 to ExportCount-1 do
    if ( ExportTable.ExportClass[i] = 'Sound' ) then
      Snd := TRUE;

  // check for geometry
  Geo := FALSE;
  for i:=0 to ExportCount-1 do
    if ( ExportTable.ExportClass[i] = 'Polys' ) then
      Geo := TRUE;

  // check for models
  mdl := FALSE;
  for i:=0 to ExportCount-1 do
    if ( ExportTable.ExportClass[i] = 'LodMesh' ) then
      mdl := TRUE;

  // check for scripts
  Scri := FALSE;
  for i:=0 to ExportCount-1 do
    if ( ExportTable.ObjectName[i] = 'ScriptText' ) then
      Scri := TRUE;
end;
//------------------------------------------------------------------------------

end.
