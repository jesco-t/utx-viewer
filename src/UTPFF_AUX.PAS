{ @abstract(Contains additional classes & functions for the implementation of
            the UTPFF.)
  @author(Jesco Topp <jesco@users.sourceforge.net>)
  @created(October 2000)
  @lastmod(20th Febr. 2002)
  Auxiliary unit which contains additional classes & functions for the
  implementation of the UTPFF (UnrealTournament Package-FileFormat). These
  includes classes for the header-tables, internal lists and exception
  handlers. The functions include read/write implementation of Unreal's
  unique FCompactIndex (named INDEX in this code) and NAME type format.}
unit UTPFF_Aux;

interface

uses
  Windows, Classes, SysUtils;

{ texture constants }
const
  { standard texture (bmp, single texture/mipmap) }
  TEX_STD     = 0;
  { standard texture, animated }
  TEX_ANI     = 1;
  { multiple mipmaps, not animated }
  TEX_MMP     = 2;
  { multiple mipmaps, animated }
  TEX_MMP_ANI = 3;

//------------------------------------------------------------------------------
{ header-tables }
type
  { Class to hold the NameTable. The NameTable is some sort of encyclopedia
    in which Unreal stores the name and flags of every single object which is
    stored in a package or referenced by the package. }
  TNameTable = Class(TObject)
    { array to hold the name of each object in the NameTable }
    ObjectName     : array of string;
    { array to store the flags of each object in the NameTable }
    ObjectFlags    : array of DWORD;
    { number of entries in the NameTable }
    Count          : integer;
    { offset of the NameTable inside the package }
    Offset         : integer;
    { constructor, initialises all the arrays and copies the offset }
    constructor Create( Size : integer; FOffset : longint );
end;

type
  { Class to hold the ImportTable. All references to objects in other packages
    are stored in the ImportTable. }
  TImportTable = Class(TObject)
    { package of the class }
    ClassPackage         : array of string;
    { name of the class of the object }
    ClassName            : array of string;
    { package the object resides in }
    ImportPackage        : array of string;
    { package the object resides in; un-resolved ObjectReference (see the UTPFF docs) }
    ImportPackage_ObjRef : array of DWORD;
    { name of the referenced object }
    ObjectName           : array of string;
    { number of entries in the NameTable }
    Count          : integer;
    { offset of the NameTable inside the package }
    Offset         : integer;
    { constructor, initialises all the arrays and copies the offset }
    constructor Create( Size : integer; FOffset : longint );
end;

type
  { Class to hold the ImportTable. All objects of the package, which may be
    accessed from outside (thus exported) are listed here. It's basically the
    table of contents for the package. }
  TExportTable = Class(TObject)
    { class of the object }
    ExportClass          : array of string;
    { class of the object; un-resolved ObjectReference (see the UTPFF docs) }
    ExportClass_ObjRef   : array of DWORD;
    { parent of the object (from which it inherits) }
    Super                : array of string;
    { parent of the object (from which it inherits); un-resolved ObjectReference
      (see the UTPFF docs) }
    Super_ObjRef         : array of DWORD;
    { package this object resides in (could be an internal package, called
      group) }
    ExportPackage        : array of string;
    { package this object resides in (could be an internal package, called
      group); un-resolved ObjectReference (see the UTPFF docs) }
    ExportPackage_ObjRef : array of DWORD;
    { name of the object }
    ObjectName           : array of string;
    { flags of the object }
    ObjectFlags          : array of DWORD;
    { size of the object within the package file }
    SerialSize           : array of DWORD;
    { offset of the object within the file; if SerialSize = 0, then this is -1 }
    SerialOffset         : array of DWORD;
    { number of entries in the NameTable }
    Count          : integer;
    { offset of the NameTable inside the package }
    Offset         : integer;
    { constructor, initialises all the arrays and copies the offset }
    constructor Create( Size : integer; FOffset : longint );
end;
//------------------------------------------------------------------------------
{ misc }
type
  { Class to hold a list of all texture within a package. This class is used to
    iterate through and get the indices of the textures to display. }
  TTextureList = Class(TObject)
    { array which stores the name of each texture }
    Name       : array of string;
    { array which stores the name of the internal package (or group) of the
      texture }
    Group      : array of string;
    { array which stores the indices of the textures into the ExportTable
      (which you need to get further information on the texture, like SerialSize
      and offset) }
    ETIndex    : array of DWORD;   // index into ExportTable
    { number of entries in TextureList }
    Count      : integer;
    { constructor, initialises all the arrays and copies the offset }
    constructor Create( Size : integer );
end;

type
  { record which stores the RGBA values for a single pixel or palette-entry;
    only used in conjunction with arrays }
  TRGBAQuad = record
    { red }
    r : BYTE;
    { green }
    g : BYTE;
    { blue }
    b : BYTE;
    { alpha (transparency) }
    a : BYTE;
  end;

type
  { custom exception if a package with an invalid header is loaded }
  EHeaderTableException = Class(Exception)
  end;

//------------------------------------------------------------------------------
{ functions to read INDEX and NAME }

  { decodes (read) a FCompactIndex type from a THandleStream }
  function  Read_INDEX( Str_Handle : integer ): longint;
  { encodes (write) a FCompactIndex into a THandleStream }
  procedure Write_INDEX(const Index : longint; Str_Handle : integer);
  { calculates the theoretical size of a DWORD, if stored as a FCompactIndex }
  function  SizeOf_INDEX(const Index : longint): integer;

  { decodes (read) a NAME type from a THandleStream }
  function  Read_NAME(Str_Handle : integer; PkgVer : integer): string;
  { encodes (write) a NAME type into a THandleStream; only for package version 69 }
  procedure Write_NAME(const Name : string; Str_Handle : integer);

//------------------------------------------------------------------------------

implementation

//------------------------------------------------------------------------------
// Initialise Table-Arrays

constructor TNameTable.Create;
begin
  SetLength( ObjectName, Size );
  SetLength( ObjectFlags, Size );

  Count := Size + 1;
  Offset := FOffset;
end;

constructor TImportTable.Create;
begin
  SetLength( ClassPackage, Size );
  SetLength( ClassName, Size );
  SetLength( ImportPackage, Size );
  SetLength( ImportPackage_ObjRef, Size );
  SetLength( ObjectName, Size );

  Count := Size + 1;
  Offset := FOffset;
end;

constructor TExportTable.Create;
begin
  SetLength( ExportClass, Size );
  SetLength( ExportClass_ObjRef, Size );
  SetLength( Super, Size );
  SetLength( Super_ObjRef, Size );
  SetLength( ExportPackage, Size );
  SetLength( ExportPackage_ObjRef, Size );
  SetLength( ObjectName, Size );
  SetLength( ObjectFlags, Size );
  SetLength( SerialSize, Size );
  SetLength( SerialOffset, Size );
  
  Count := Size + 1;
  Offset := FOffset;
end;

constructor TTextureList.Create;
begin
  SetLength( Name, Size );
  SetLength( Group, Size );
  SetLength( ETIndex, Size );
end;

//------------------------------------------------------------------------------

{ decode (read) a FCompactIndex type from a THandleStream }
function Read_INDEX;
var
  B0,B1,B2,B3,B4 : BYTE;
  D0,D1,D2,D3,D4 : longint;
  INDEX          : longint;
  IsNegative     : Boolean;
  Hstr           : THandleStream;
begin
  Hstr := THandleStream.Create( Str_Handle );
  B0 := 0;
  B1 := 0;
  B2 := 0;
  B3 := 0;
  B4 := 0;

  HStr.ReadBuffer( B0, 1);
  if (B0 > $80) then
  begin
    B0 := B0 - $80;
    IsNegative := TRUE;
  end
  else
    IsNegative := FALSE;

  //Read Following Bytes
  if (B0 >= $40) then
  begin
    B0 := B0 - $40;
    HStr.ReadBuffer( B1, 1);
    if (B1 >= $80) then
    begin
      B1 := B1 - $80;
      HStr.ReadBuffer( B2, 1);
      if (B2 >= $80) then
      begin
        B2 := B2 - $80;
        HStr.ReadBuffer( B3, 1);
        if (B3 >= $80) then
        begin
          B3 := B3 - $80;
          HStr.ReadBuffer( B4, 1);
        end;
      end;
    end;
  end;

  //Assign DWORDs
  D0 := B0;
  D1 := B1;
  D2 := B2;
  D3 := B3;
  D4 := B4;
  //Shift Bytes
  D1 := D1 shl 6;
  D2 := D2 shl 13;
  D3 := D3 shl 20;
  D4 := D4 shl 27;

  //Create resulting DWORD
  INDEX := D0 + D1 + D2 + D3 + D4;

  //Check for sign
  if (IsNegative = TRUE) then INDEX := INDEX * (-1);

  Result := INDEX;
end;

{ encode (write) a FCompactIndex into a THandleStream }
procedure Write_INDEX;
var
  B0,B1,B2,B3,B4 : Variant;
  D0,D1,D2,D3,D4 : longint;
  length         : integer;
  IsNegative     : Boolean;
  Value          : longint;
  Hstr           : THandleStream;
begin
  Hstr := THandleStream.Create( Str_Handle );
  // check sign and remove it from original DWORD if necessary
  if ( Index < 0 ) then
  begin
    Value := Index * -1;
    IsNegative := TRUE;
  end
  else
  begin
    Value := Index;
    IsNegative := FALSE;
  end;

  // Create BYTEs from DWORD
  B0 := BYTE(Value);
  if ( B0 >= $80 ) then
    B0 := B0 - $80;
  if ( B0 >= $40 ) then
    B0 := B0 - $40;
  Value := Value shr 6;
  B1 := BYTE(Value);
  if ( B1 >= $80 ) then
    B1 := B1 - $80;
  Value := Value shr 7;
  B2 := BYTE(Value);
  if ( B2 >= $80 ) then
    B2 := B2 - $80;
  Value := Value shr 7;
  B3 := BYTE(Value);
  if ( B3 >= $80 ) then
    B3 := B3 - $80;
  Value := Value shr 7;
  B4 := BYTE(Value);
  if ( B4 >= $80 ) then
    B4 := B4- $80;

  // Assign sign-bit
  if ( IsNegative ) then
    B0 := B0 + $80;

  // Assign length-bits
  length := 1;
  if ( B1 + B2 + B3 + B4 > 0 ) then
  begin
    B0 := B0 + $40;
    length := length + 1;
    if ( B2 + B3 + B4 > 0 ) then
    begin
      B1 := B1 + $80;
      length := length + 1;
      if (  B3 + B4 > 0 ) then
      begin
        B2 := B2 + $80;
        length := length + 1;
        if ( B4 > 0 ) then
        begin
          length := length + 1;
          B3 := B3 + $80;
        end;
      end;
    end;
  end;

  D0 := B0;
  // Write INDEX to disk
  HStr.WriteBuffer( D0, 1);
  if ( length > 1 ) then
  begin
    D1 := B1;
    HStr.WriteBuffer(D1, 1);
    if ( length > 2 ) then
    begin
      D2 := B2;
      HStr.WriteBuffer(D2, 1);
      if ( length > 3 ) then
      begin
        D3 := B3;
        HStr.WriteBuffer(D3, 1);
        if ( length > 4 ) then
        begin
          D4 := B4;
          HStr.WriteBuffer(D4, 1);
        end;
      end;
    end;
  end;
end;

{ calculates the theoretical size of a DWORD, if stored as a FCompactIndex }
function SizeOf_INDEX;
var
  B0,B1,B2,B3,B4 : BYTE;
  length         : integer;
  Value          : DWORD;
begin
  // Create BYTEs
  if ( Index < 0 ) then
  begin
    Value := Index * -1;
  end
  else
  begin
    Value := Index;
  end;

  // Create BYTEs from DWORD
  B0 := BYTE(Value);
  if ( B0 >= $80 ) then
    B0 := B0 - $80;
  if ( B0 >= $40 ) then
    B0 := B0 - $40;
  Value := Value shr 6;
  B1 := BYTE(Value);
  if ( B1 >= $80 ) then
    B1 := B1 - $80;
  Value := Value shr 7;
  B2 := BYTE(Value);
  if ( B2 >= $80 ) then
    B2 := B2 - $80;
  Value := Value shr 7;
  B3 := BYTE(Value);
  if ( B3 >= $80 ) then
    B3 := B3 - $80;
  Value := Value shr 7;
  B4 := BYTE(Value);
  if ( B4 >= $80 ) then
    B4 := B4- $80;

  // length
  length := 1;
  if ( B1 > 0 ) then
  begin
    length := length + 1;
    if ( B2 > 0 ) then
    begin
      length := length + 1;
      if (  B3 > 0 ) then
      begin
        length := length + 1;
        if ( B4 > 0 ) then
        begin
          length := length + 1;
        end;
      end;
    end;
  end;

  Result := length;
end;

//------------------------------------------------------------------------------
{ decode (read) a NAME type from a THandleStream }
function Read_NAME;
var
  zero : BYTE;
  i    : integer;
  NAME : string;
  temp : char;
  Hstr : THandleStream;
begin
  Hstr := THandleStream.Create( Str_Handle );
  Hstr.Size;
  i := 0;
  if (PkgVer < 64) then
  begin
    repeat
    i := i + 1;
    HStr.ReadBuffer( zero, 1);
    if (zero <> $00) then
    begin
      Hstr.Seek( HStr.Position - 1, soFromBeginning );
      HStr.ReadBuffer( temp, 1);
      Insert(temp, NAME, i);
    end;
    until (zero = $00);
  end
  else
  begin
    Hstr.Seek( HStr.Position + 1, soFromBeginning ); //quit length byte
    Hstr.Position;
    repeat
    i := i + 1;
    HStr.ReadBuffer( zero, 1);
    if (zero <> $00) then
    begin
      Hstr.Seek( HStr.Position - 1, soFromBeginning );
      HStr.ReadBuffer( temp, 1);
      Insert(temp, NAME, i);
    end;
    until (zero = $00);
  end;

  Result := NAME;
end;

{ encode (write) a NAME type into a THandleStream; only for package version 69 }
procedure Write_Name;
var
  tempBYTE : BYTE;
  tempCHAR : char;
  i        : integer;
  Hstr : THandleStream;
begin
  Hstr := THandleStream.Create( Str_Handle );

  tempBYTE := length(Name) + 1;
  HStr.WriteBuffer(tempBYTE, 1);
  for i:=0 to length(Name)-1 do
  begin
    tempCHAR := Name[i+1];
    HStr.WriteBuffer(tempCHAR, 1);
  end;
  tempBYTE := $00;
  HStr.WriteBuffer(tempBYTE, 1);
end;

//------------------------------------------------------------------------------

end.
