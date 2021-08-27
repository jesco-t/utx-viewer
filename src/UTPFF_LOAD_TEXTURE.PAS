//------------------------------------------------------------------------------
// TTexture_Load : base-class for loading textures
//
// (c) 2000, 2001, Jesco Topp & Andy Ford
//------------------------------------------------------------------------------
unit UTPFF_Load_Texture;

interface

uses Windows, graphics, SysUtils, classes,
     UTPFF_Aux, UTPFF_Load_Palette;

//------------------------------------------------------------------------------
// TTexture_Load
type
  TTexture_Load = class(TObject)
    Name        : string;       // same as in TTextureList
    Group       : string;       // --        ""         --
    Offset      : longint;      // offset in file
    // infos
    Palette     : longint;      // index to palette in NameTable
    Palette_NAME: string;       // name of palette
    USize,
    VSize       : longint;      // dimension
    UBits,
    VBits       : longint;
    MipMapCount : BYTE;
    bMasked     : Boolean;      // flags needed for Animation and Texture Details
    IsAnimated  : Boolean;
    AnimNext    : string;
    MaxFrameRate: single;
    MinFrameRate: single;
    HasMinFrameRate : Boolean;
    HasMaxFrameRate : Boolean;
    // properties of actual mipmap
    MHeight        : longint;
    MWidth         : longint;
    MaxPreviewSize : integer;
    // copy of tables
    NameTable   : TNameTable;
    ImportTable : TImportTable;
    ExportTable : TExportTable;
    // actual raw data
    RawMipMap   : array[0..262143] of BYTE;
    // init & finish stuff
    constructor Create;
    procedure   Free;
    destructor  Destroy; override;
  public
    MipMap      : TBitmap;
    Pal         : TPalette_Load;
    procedure   Load( Str_Handle : integer;
                          NT : TNameTable; IT : TImportTable; ET : TExportTable;
                          TexName : string; TexIndex : longint;                   // index of texture into exporttable
                          MaximumPreviewSize : integer; PkgVer : integer);
    procedure   Read_GenericTextureProperties( Output : TStrings );
  private
    HasToBeResized : Boolean;
    Hstr           : THandleStream;
    HStr_Handle     : integer;
    function    Evaluate_ObjectReference( Value : longint): string;
    function    Decode_UnknownProperty( Index : longint) : string;  // used to decode generic (unknown) properties
    procedure   Read_TextureProperties;
    procedure   Read_MipMap( PkgVer : integer);
    procedure   Convert_RAW2BMP;
end;
//------------------------------------------------------------------------------

implementation

//------------------------------------------------------------------------------
// init & finish stuff
constructor TTexture_Load.Create;
begin
  pal := TPalette_Load.Create;
  MipMap := TBitmap.Create;

  IsAnimated := FALSE;
  HasMinFrameRate := FALSE;
  HasMaxFrameRate := FALSE;
end;

destructor TTexture_Load.Destroy;
begin
  pal.Free;
  MipMap.Free;
  
  inherited Destroy;
end;

procedure TTexture_Load.Free;
begin
  if ( Self <> nil ) then Destroy;
end;
//------------------------------------------------------------------------------
// Load texture
procedure TTexture_Load.Load;
begin
  // copy tables
  NameTable   := NT;
  ImportTable := IT;
  ExportTable := ET;

  MaxPreviewSize := MaximumPreviewSize;

  Name := TexName;

  // Open Stream
  Hstr := THandleStream.Create( Str_Handle );
  HStr_Handle := Hstr.Handle;
  
  // move to offset in file
  Offset := ExportTable.SerialOffset[TexIndex];
  Hstr.Seek( Offset, soFromBeginning );

  // read properties
  Read_TextureProperties;

  // read mipmap-data
  Read_MipMap( PkgVer );

  // convert raw-data to bitmap
  pal.Load( NameTable, ImportTable, ExportTable, Hstr_Handle, Palette );
  Convert_RAW2BMP;
end;

// reads the properties
procedure TTexture_Load.Read_TextureProperties;
var
  INDEX     : longint;
  TypeBYTE  : longint;
  tempBYTE  : BYTE;
  IsUnknown : Boolean;
begin
  INDEX := Read_INDEX( Hstr_Handle );

  while ( NameTable.ObjectName[INDEX] <> 'None' ) do
  begin
    IsUnknown := TRUE;  // type of property is unknown at the beginning

    // Palette
    if ( NameTable.ObjectName[INDEX] = 'Palette' ) then
    begin
      IsUnknown := FALSE;

      HStr.ReadBuffer( TypeBYTE, 1 );  // should be 0x05 or 0x15 (ObjRef)
      Palette      := Read_INDEX( Hstr_Handle );
      Palette_NAME := Evaluate_ObjectReference( Palette );
    end;

    // USize (x)
    if ( NameTable.ObjectName[INDEX] = 'USize' ) then
    begin
      IsUnknown := FALSE;

      HStr.ReadBuffer( TypeByte, 1); //Should be 0x22 (longint-Integer value follows)
      HStr.ReadBuffer( USize, 4);
    end;

    // VSize (y)
    if ( NameTable.ObjectName[INDEX] = 'VSize' ) then
    begin
      IsUnknown := FALSE;

      HStr.ReadBuffer( TypeByte, 1); //Should 0x22 (longint-Integer value follows)
      HStr.ReadBuffer( VSize, 4);
    end;

    //------------------------------------------------------
    // Special flags needed for TextureDetails and Animation

    // bMasked
    if ( NameTable.ObjectName[INDEX] = 'bMasked' ) then
    begin
      IsUnknown := FALSE;

       HStr.ReadBuffer( TypeByte, 1); //0x53 = FALSE, 0xD3 = TRUE
       if ( TypeByte = $53 ) then
         bMasked := FALSE
       else
         bMasked := TRUE;
       HStr.ReadBuffer( tempByte, 1); //always 0x00
    end;

    // AnimNext ( Is Animated )
    if ( NameTable.ObjectName[INDEX] = 'AnimNext' ) then
    begin
      IsUnknown := FALSE;

       HStr.ReadBuffer( TypeByte, 1); //Should be 0x05 or 0x15 (ObjRef)
       AnimNext := Evaluate_ObjectReference( Read_INDEX( HStr_Handle ) );

       IsAnimated := TRUE;
    end;

     // MaxFrameRate
     if ( NameTable.ObjectName[INDEX] = 'MaxFrameRate' ) then
     begin
       IsUnknown := FALSE;

       HStr.ReadBuffer( TypeByte, 1); //Should be 0x24 (Float)
       HStr.ReadBuffer( MaxFrameRate, 4);

       IsAnimated := TRUE;
       HasMaxFrameRate := TRUE;
     end;

     // MinFrameRate
     if ( NameTable.ObjectName[INDEX] = 'MinFrameRate' ) then
     begin
       IsUnknown := FALSE;

       HStr.ReadBuffer( TypeByte, 1); //Should be 0x24 (Float)
       HStr.ReadBuffer( MinFrameRate, 4);

       IsAnimated := TRUE;
       HasMinFrameRate := TRUE;
     end;

    //--------------------------------------------------------
    // Unknown

    if ( IsUnknown = TRUE ) then
    begin
      Decode_UnknownProperty( INDEX );
    end;

    // read INDEX for next pass
    INDEX := Read_INDEX( Hstr_Handle );
  end;
end;

// reads the mipmap-data
procedure TTexture_Load.Read_MipMap;
var
  // header
  WidthOffset       : longint;  // only if PkgVer >=63
  MipMapSize        : longint;
  Width             : longint;
  Height            : longint;
  // misc
  MipMapsPassed     : integer;
begin
  // MipMapCount
  HStr.ReadBuffer( MipMapCount, 1 );

  for MipMapsPassed := 0 to MipMapCount-1  do
  begin
    if ( USize > VSize ) then   // x > y
    begin
      // read header
      if ( PkgVer >= 63 ) then
        HStr.ReadBuffer( WidthOffset, 4 );
      MipMapSize  := Read_INDEX( Hstr_Handle );
      Hstr.Seek( HStr.Position + MipMapSize, soFromBeginning );
      HStr.ReadBuffer( Width, 4 );
      HStr.ReadBuffer( Height, 4 );
      Hstr.Seek( HStr.Position + 2, soFromBeginning  );

      // check if mipmap has proper size
      if ( Width <= MaxPreviewSize ) then
      begin
        // read mipmap
        HasToBeResized := FALSE;
        Hstr.Seek( HStr.Position - 10 - MipMapSize, soFromBeginning  );
        HStr.ReadBuffer( RawMipMap, MipMapSize);

        MWidth := Width;
        MHeight:= Height;

        break;
      end
      else
      if ( MipMapsPassed = MipMapCount-1 ) then
      begin
        // read mipmap and resize it
        HasToBeResized := TRUE;
        Hstr.Seek( HStr.Position - 10 - MipMapSize, soFromBeginning  );
        HStr.ReadBuffer( RawMipMap, MipMapSize);

        MWidth := Width;
        MHeight:= Height;

        break;
      end;
    end
    else
    begin
      // read header
      if ( PkgVer >= 63 ) then
        HStr.ReadBuffer( WidthOffset, 4 );
      MipMapSize  := Read_INDEX( Hstr_Handle );
      Hstr.Seek( HStr.Position + MipMapSize, soFromBeginning  );
      HStr.ReadBuffer( Width, 4 );
      HStr.ReadBuffer( Height, 4 );
      Hstr.Seek( HStr.Position + 2, soFromBeginning  );

      // check if mipmap has proper size
      if ( MaxPreviewSize >= Height ) then
      begin
        // read mipmap
        HasToBeResized := FALSE;
        Hstr.Seek( HStr.Position - 10 - MipMapSize, soFromBeginning  );
        HStr.ReadBuffer( RawMipMap, MipMapSize);

        MWidth := Width;
        MHeight:= Height;

        break;
      end
      else
      if ( MipMapsPassed = MipMapCount-1 ) then
      begin
        // read mipmap and resize it
        HasToBeResized := TRUE;
        Hstr.Seek( HStr.Position - 10 - MipMapSize, soFromBeginning  );
        HStr.ReadBuffer( RawMipMap, MipMapSize);

        MWidth := Width;
        MHeight:= Height;

        break;
      end;
    end;
  end;
end;

// converts raw to bmp
procedure TTexture_Load.Convert_RAW2BMP;
var
  y,x          : integer;
  Row          : PByteArray;
  tempBitmap   : TBitmap;
  StretchRect  : TRect;
begin
  //Initialize everything
  MipMap.Height := MHeight;
  MipMap.Width  := MWidth;
  MipMap.PixelFormat := pf8bit;

  //Assign Palette
  if (pal.WinPalette <> 0) then
    MipMap.Palette := pal.WinPalette;

  //Create bitmap
  for y:=0 to MipMap.Height-1 do
  begin
    Row := MipMap.ScanLine[y];
    for x:=0 to MipMap.Width-1 do
      Row[x] := RawMipMap[y*MipMap.Width+x];
  end;

  // Resize bitmap if larger than allowed
  if ( HasToBeResized = TRUE ) then
  begin
    tempBitmap := TBitmap.Create;
    tempBitmap.PixelFormat := pf8bit;

    if ( MipMap.Width > MipMap.Height ) then
    begin
      tempBitmap.Width  := MaxPreviewSize;
      tempBitmap.Height := MaxPreviewSize * ( MaxPreviewSize div MipMap.Width );
    end;
    if ( MipMap.Height > MipMap.Width ) then
    begin
      tempBitmap.Height  := MaxPreviewSize;
      tempBitmap.Width := MaxPreviewSize * ( MaxPreviewSize div MipMap.Height );
    end;
    if ( MipMap.Width = MipMap.Height ) then
    begin
      tempBitmap.Height  := MaxPreviewSize;
      tempBitmap.Width   := MaxPreviewSize;
    end;

    StretchRect.Top    := 0;
    StretchRect.Left   := 0;
    StretchRect.Right  := tempBitmap.Width-1;
    StretchRect.Bottom := tempBitmap.Height-1;
    
    //tempBitmap.Assign(B);
    tempBitmap.Canvas.StretchDraw( StretchRect, MipMap);

    MipMap.Assign(tempBitmap);
    tempBitmap.Free;
  end;
end;

//------------------------------------------------------------------------------
// Evaluate Object-Reference (placed here due to massive performance-increase)
function TTexture_Load.Evaluate_ObjectReference;
begin
  if (Value = 0) then Result := '';
  if (Value < 0) then Result := ImportTable.ObjectName[-Value-1];
  if (Value > 0) then Result := ExportTable.ObjectName[Value-1];
end;

//------------------------------------------------------------------------------
// decode unknown properties (exactly one per pass)
function TTexture_Load.Decode_UnknownProperty;
var
  Line            : string;
  TypeBYTE        : BYTE;
  ValueBYTE       : BYTE;
  ValueDWORD      : longint;
  ValueINDEX      : longint;
  ValueFloat      : single;
  ValueString     : string;
  ArrayIndex      : BYTE;
  StructINDEX     : longint;
begin
  // read index into NameTable
    Line  := NameTable.ObjectName[Index];

    HStr.ReadBuffer( TypeBYTE, 1);

    case TypeBYTE of
    $01 : // BYTE
      begin
        HStr.ReadBuffer( ValueBYTE, 1);
        Line := Line + ' (Byte) = ' + IntToStr(ValueBYTE);
      end;
    $81 : // BYTE + array
      begin
        HStr.ReadBuffer( ArrayIndex, 1);
        HStr.ReadBuffer( ValueBYTE, 1);
        Line := Line + '[' + IntToStr(ArrayINDEX) + '] (Byte) = ' + IntToStr(ValueBYTE);
      end;
    $05, $15 : // ObjRef
      begin
        ValueINDEX := Read_INDEX( Hstr_Handle );
        Line := Line + ' (ObjRef) = ' + Evaluate_ObjectReference(ValueINDEX);
      end;
    $85, $95 : // ObjRef + array
      begin
        HStr.ReadBuffer( ArrayIndex, 1);
        ValueINDEX := Read_INDEX( Hstr_Handle );
        Line := Line + '[' + IntToStr(ArrayIndex) + '] (ObjRef) = ' + Evaluate_ObjectReference(ValueINDEX);
      end;
    $55 : //ObjRef + unnown INDEX
      begin
        ValueINDEX := Read_INDEX( Hstr_Handle );
        Line := Line + ' (ObjRef) = ' + IntToStr(ValueIndex);
        ValueINDEX := Read_INDEX( Hstr_Handle );
        Line := Line + ', ' + Evaluate_ObjectReference(ValueINDEX);
      end;
    $D5 : //ObjRef + unnown INDEX + array
      begin
        HStr.ReadBuffer( ArrayIndex, 1);
        ValueINDEX := Read_INDEX( Hstr_Handle );
        Line := Line + '[' + IntToStr(ArrayIndex) + '] (ObjRef) = ' + IntToStr(ValueIndex);
        ValueINDEX := Read_INDEX( Hstr_Handle );
        Line := Line + ', ' + Evaluate_ObjectReference(ValueINDEX);
      end;
    $06, $16 : // Index into NameTable
      begin
        ValueINDEX := Read_INDEX( Hstr_Handle );
        Line := Line + ' (Name) = ' + IntToStr(ValueINDEX);
      end;
    $86, $96 : // Index into NameTable
      begin
        HStr.ReadBuffer( ArrayIndex, 1);
        ValueINDEX := Read_INDEX( Hstr_Handle );
        Line := Line + '[' + IntToStr(ArrayIndex) + '] (Name) = ' + IntToStr(ValueINDEX);
      end;
    $08 : // ADrop
      begin
        HStr.ReadBuffer( ValueDWORD, 4);
        HStr.ReadBuffer( ValueBYTE, 1);
        Line := Line + ' (ADrop) = [' + IntToStr(ValueDWORD) + ', x = ' + IntToStr(ValueBYTE);
        HStr.ReadBuffer( ValueBYTE, 1);
        HStr.ReadBuffer( ValueDWORD, 4);
        Line := Line + ', y = ' + IntToStr(ValueBYTE) + ', ' + IntToStr(ValueDWORD) + ']';
      end;
    $88 : // ADrop + array
      begin
        HStr.ReadBuffer( ArrayIndex, 1);
        HStr.ReadBuffer( ValueDWORD, 4);
        HStr.ReadBuffer( ValueBYTE, 1);
        Line := Line + '[' + IntToStr(ArrayIndex) + '] (ADrop) = [' + IntToStr(ValueDWORD) + ', x = ' + IntToStr(ValueBYTE);
        HStr.ReadBuffer( ValueBYTE, 1);
        HStr.ReadBuffer( ValueDWORD, 4);
        Line := Line + ', y = ' + IntToStr(ValueBYTE) + ', ' + IntToStr(ValueDWORD) + ']';
      end;
    $0D : // Localized string
      begin
        ValueINDEX := Read_INDEX( Hstr_Handle );
        HStr.ReadBuffer( ValueString, ValueINDEX);
        Line := Line + ' (String) = ' + ValueString;
      end;
    $8D : // Localized string + array
      begin
        HStr.ReadBuffer( ArrayIndex, 1);
        ValueINDEX := Read_INDEX( Hstr_Handle );
        HStr.ReadBuffer( ValueString, ValueINDEX);
        Line := Line + '[' + IntToStr(ArrayIndex) + '] (String) = ' + ValueString;
      end;
    $22 : // Integer
      begin
        HStr.ReadBuffer( ValueDWORD, 4);
        Line := Line + ' (Integer) = ' + IntToStr(ValueDWORD);
      end;
    $A2 : // Integer + array
      begin
        HStr.ReadBuffer( ArrayIndex, 1);
        HStr.ReadBuffer( ValueDWORD, 4);
        Line := Line + '[' + IntToStr(ArrayIndex) + '] (Integer) = ' + IntToStr(ValueDWORD);
      end;
    $24 : // Floating point
      begin
        HStr.ReadBuffer( ValueFloat, 4);
        Line := Line + ' (Float) = ' + FloatToStr(ValueFloat);     //buggy
      end;
    $A4 : // Floating point + array
      begin
        HStr.ReadBuffer( ArrayIndex, 1);
        HStr.ReadBuffer( ValueFloat, 4);
        Line := Line + '[' + IntToStr(ArrayIndex) + '] (Float) = ' + FloatToStr(ValueFloat);  //buggy
      end;
    $3D, $4D : // Text
      begin
        HStr.ReadBuffer( ValueBYTE, 1);
        HStr.ReadBuffer( ValueString, ValueBYTE);
        Line := Line + ' (Text) = ' + ValueString;
      end;
    $BD, $CD : // Text + array
      begin
        HStr.ReadBuffer( ArrayIndex, 1);
        HStr.ReadBuffer( ValueBYTE, 1);
        HStr.ReadBuffer( ValueString, ValueBYTE);
        Line := Line + '[' + IntToStr(ArrayIndex) + '] (Text) = ' + ValueString;
      end;
    $5D : // Text
      begin
        HStr.ReadBuffer( ValueBYTE, 1);
        ValueINDEX := Read_INDEX( Hstr_Handle );
        HStr.ReadBuffer( ValueString, ValueINDEX);
        Line := Line + ' (Text) = ' + ValueString;
      end;
    $DD : // Text + array
      begin
        HStr.ReadBuffer( ArrayIndex, 1);
        HStr.ReadBuffer( ValueBYTE, 1);
        ValueINDEX := Read_INDEX( Hstr_Handle );
        HStr.ReadBuffer( ValueString, ValueINDEX);
        Line := Line + '[' + IntToStr(ArrayIndex) + '] (Text) = ' + ValueString;
      end;
    $6D : // Text
      begin
        HStr.ReadBuffer( ValueBYTE, 1);
        HStr.ReadBuffer( ValueBYTE, 1);
        ValueINDEX := Read_INDEX( Hstr_Handle );
        HStr.ReadBuffer( ValueString, ValueINDEX);
        Line := Line + ' (Text) = ' + ValueString;
      end;
    $ED : // Text + array
      begin
        HStr.ReadBuffer( ArrayIndex, 1);
        HStr.ReadBuffer( ValueBYTE, 1);
        HStr.ReadBuffer( ValueBYTE, 1);
        ValueINDEX := Read_INDEX( Hstr_Handle );
        HStr.ReadBuffer( ValueString, ValueINDEX);
        Line := Line + '[' + IntToStr(ArrayIndex) + '] (Text) = ' + ValueString;
      end;
    $53 : // bool = FALSE
      begin
        HStr.ReadBuffer( ValueBYTE, 1);
        Line := Line + ' (Boolean) = FALSE';
      end;
    $D3 : // bool = TRUE
      begin
        HStr.ReadBuffer( ValueBYTE, 1);
        Line := Line + ' (Boolean) = TRUE';
      end;
    $2A, $3A : // struct
      begin
        StructINDEX := Read_INDEX( Hstr_Handle );

        // Color struct
        if ( NameTable.ObjectName[StructINDEX] = 'Color' ) then
        begin
          HStr.ReadBuffer( ValueBYTE, 1);
          Line := Line + ' (Color) = [R=' + IntToStr(ValueBYTE);
          HStr.ReadBuffer( ValueBYTE, 1);
          Line := Line + ';G=' + IntToStr(ValueBYTE);
          HStr.ReadBuffer( ValueBYTE, 1);
          Line := Line + ';B=' + IntToStr(ValueBYTE);
          HStr.ReadBuffer( ValueBYTE, 1);
          Line := Line + ';A=' + IntToStr(ValueBYTE) + ']';
        end;
        // Vector struct
        if ( NameTable.ObjectName[StructINDEX] = 'Vector' ) then
        begin
          HStr.ReadBuffer( ValueFloat, 4);
          Line := Line + ' (Vector) = [x=' + FloatToStr(ValueFloat);
          HStr.ReadBuffer( ValueFloat, 4);
          Line := Line + '; y=' + FloatToStr(ValueFloat);
          HStr.ReadBuffer( ValueFloat, 4);
          Line := Line + '; x=' + FloatToStr(ValueFloat) + ']';
        end;
        // Rotator struct
        if ( NameTable.ObjectName[StructINDEX] = 'Rotator' ) then
        begin
          HStr.ReadBuffer( ValueDWORD, 4);
          Line := Line + ' (Rotator) = [pitch=' + IntToStr(ValueDWORD);
          HStr.ReadBuffer( ValueDWORD, 4);
          Line := Line + '; yaw=' + IntToStr(ValueDWORD);
          HStr.ReadBuffer( ValueDWORD, 4);
          Line := Line + '; roll=' + IntToStr(ValueDWORD) + ']';
        end;
        // Scale struct
        if ( NameTable.ObjectName[StructINDEX] = 'Scale' ) then
        begin
          HStr.ReadBuffer( ValueFloat, 4);
          Line := Line + ' (Scale) = [x=' + FloatToStr(ValueFloat);
          HStr.ReadBuffer( ValueFloat, 4);
          Line := Line + '; y=' + FloatToStr(ValueFloat);
          HStr.ReadBuffer( ValueFloat, 4);
          Line := Line + '; x=' + FloatToStr(ValueFloat);
          HStr.ReadBuffer( ValueDWORD, 4);
          Line := Line + '; sheerrate=' + IntToStr(ValueDWORD);
          HStr.ReadBuffer( ValueBYTE, 1);
          Line := Line + '; sheeraxis=' + IntToStr(ValueBYTE) + ']';
        end;
        // PointRegion
        if ( NameTable.ObjectName[StructINDEX] = 'PointRegion' ) then
        begin
          ValueINDEX := Read_INDEX( Hstr_Handle );
          Line := Line + ' (PointRegion) = [zone=' + Evaluate_ObjectReference(ValueINDEX);
          HStr.ReadBuffer( ValueDWORD, 4);
          Line := Line + '; ileaf=' + IntToStr(ValueDWORD);
          HStr.ReadBuffer( ValueBYTE, 1);
          Line := Line + '; zonenumber=' + IntToStr(ValueBYTE) + ']';
        end;
      end;
    $AA, $BA : //struct + array
      begin
        StructINDEX := Read_INDEX( Hstr_Handle );
        HStr.ReadBuffer( ArrayIndex, 1);

        // Color struct
        if ( NameTable.ObjectName[StructINDEX] = 'Color' ) then
        begin
          HStr.ReadBuffer( ValueBYTE, 1);
          Line := Line + '[' + IntToStr(ArrayIndex) + '] (Color) = [R=' + IntToStr(ValueBYTE);
          HStr.ReadBuffer( ValueBYTE, 1);
          Line := Line + ';G=' + IntToStr(ValueBYTE);
          HStr.ReadBuffer( ValueBYTE, 1);
          Line := Line + ';B=' + IntToStr(ValueBYTE);
          HStr.ReadBuffer( ValueBYTE, 1);
          Line := Line + ';A=' + IntToStr(ValueBYTE) + ']';
        end;
        // Vector struct
        if ( NameTable.ObjectName[StructINDEX] = 'Vector' ) then
        begin
          HStr.ReadBuffer( ValueFloat, 4);
          Line := Line + '[' + IntToStr(ArrayIndex) + '] (Vector) = [x=' + FloatToStr(ValueFloat);
          HStr.ReadBuffer( ValueFloat, 4);
          Line := Line + '; y=' + FloatToStr(ValueFloat);
          HStr.ReadBuffer( ValueFloat, 4);
          Line := Line + '; x=' + FloatToStr(ValueFloat) + ']';
        end;
        // Rotator struct
        if ( NameTable.ObjectName[StructINDEX] = 'Rotator' ) then
        begin
          HStr.ReadBuffer( ValueDWORD, 4);
          Line := Line + '[' + IntToStr(ArrayIndex) + '] (Rotator) = [pitch=' + IntToStr(ValueDWORD);
          HStr.ReadBuffer( ValueDWORD, 4);
          Line := Line + '; yaw=' + IntToStr(ValueDWORD);
          HStr.ReadBuffer( ValueDWORD, 4);
          Line := Line + '; roll=' + IntToStr(ValueDWORD) + ']';
        end;
        // Scale struct
        if ( NameTable.ObjectName[StructINDEX] = 'Scale' ) then
        begin
          HStr.ReadBuffer( ValueFloat, 4);
          Line := Line + '[' + IntToStr(ArrayIndex) + '] (Scale) = [x=' + FloatToStr(ValueFloat);
          HStr.ReadBuffer( ValueFloat, 4);
          Line := Line + '; y=' + FloatToStr(ValueFloat);
          HStr.ReadBuffer( ValueFloat, 4);
          Line := Line + '; x=' + FloatToStr(ValueFloat);
          HStr.ReadBuffer( ValueDWORD, 4);
          Line := Line + '; sheerrate=' + IntToStr(ValueDWORD);
          HStr.ReadBuffer( ValueBYTE, 1);
          Line := Line + '; sheeraxis=' + IntToStr(ValueBYTE) + ']';
        end;
        // PointRegion
        if ( NameTable.ObjectName[StructINDEX] = 'PointRegion' ) then
        begin
          ValueINDEX := Read_INDEX( Hstr_Handle );
          Line := Line + '[' + IntToStr(ArrayIndex) + '] (PointRegion) = [zone=' + Evaluate_ObjectReference(ValueINDEX);
          HStr.ReadBuffer( ValueDWORD, 4);
          Line := Line + '; ileaf=' + IntToStr(ValueDWORD);
          HStr.ReadBuffer( ValueBYTE, 1);
          Line := Line + '; zonenumber=' + IntToStr(ValueBYTE) + ']';
        end;
      end;
    $5A : // struct
      begin
        StructINDEX := Read_INDEX( Hstr_Handle );
        ValueINDEX := Read_INDEX( Hstr_Handle );

        // Color struct
        if ( NameTable.ObjectName[StructINDEX] = 'Color' ) then
        begin
          HStr.ReadBuffer( ValueBYTE, 1);
          Line := Line + ' (Color) = [R=' + IntToStr(ValueBYTE);
          HStr.ReadBuffer( ValueBYTE, 1);
          Line := Line + ';G=' + IntToStr(ValueBYTE);
          HStr.ReadBuffer( ValueBYTE, 1);
          Line := Line + ';B=' + IntToStr(ValueBYTE);
          HStr.ReadBuffer( ValueBYTE, 1);
          Line := Line + ';A=' + IntToStr(ValueBYTE) + ']';
        end;
        // Vector struct
        if ( NameTable.ObjectName[StructINDEX] = 'Vector' ) then
        begin
          HStr.ReadBuffer( ValueFloat, 4);
          Line := Line + ' (Vector) = [x=' + FloatToStr(ValueFloat);
          HStr.ReadBuffer( ValueFloat, 4);
          Line := Line + '; y=' + FloatToStr(ValueFloat);
          HStr.ReadBuffer( ValueFloat, 4);
          Line := Line + '; x=' + FloatToStr(ValueFloat) + ']';
        end;
        // Rotator struct
        if ( NameTable.ObjectName[StructINDEX] = 'Rotator' ) then
        begin
          HStr.ReadBuffer( ValueDWORD, 4);
          Line := Line + ' (Rotator) = [pitch=' + IntToStr(ValueDWORD);
          HStr.ReadBuffer( ValueDWORD, 4);
          Line := Line + '; yaw=' + IntToStr(ValueDWORD);
          HStr.ReadBuffer( ValueDWORD, 4);
          Line := Line + '; roll=' + IntToStr(ValueDWORD) + ']';
        end;
        // Scale struct
        if ( NameTable.ObjectName[StructINDEX] = 'Scale' ) then
        begin
          HStr.ReadBuffer( ValueFloat, 4);
          Line := Line + ' (Scale) = [x=' + FloatToStr(ValueFloat);
          HStr.ReadBuffer( ValueFloat, 4);
          Line := Line + '; y=' + FloatToStr(ValueFloat);
          HStr.ReadBuffer( ValueFloat, 4);
          Line := Line + '; x=' + FloatToStr(ValueFloat);
          HStr.ReadBuffer( ValueDWORD, 4);
          Line := Line + '; sheerrate=' + IntToStr(ValueDWORD);
          HStr.ReadBuffer( ValueBYTE, 1);
          Line := Line + '; sheeraxis=' + IntToStr(ValueBYTE) + ']';
        end;
        // PointRegion
        if ( NameTable.ObjectName[StructINDEX] = 'PointRegion' ) then
        begin
          ValueINDEX := Read_INDEX( Hstr_Handle );
          Line := Line + ' (PointRegion) = [zone=' + Evaluate_ObjectReference(ValueINDEX);
          HStr.ReadBuffer( ValueDWORD, 4);
          Line := Line + '; ileaf=' + IntToStr(ValueDWORD);
          HStr.ReadBuffer( ValueBYTE, 1);
          Line := Line + '; zonenumber=' + IntToStr(ValueBYTE) + ']';
        end;
      end;
    $DA : //struct + array
      begin
        StructINDEX := Read_INDEX( Hstr_Handle );
        ValueINDEX := Read_INDEX( Hstr_Handle );
        HStr.ReadBuffer( ArrayIndex, 1);

        // Color struct
        if ( NameTable.ObjectName[StructINDEX] = 'Color' ) then
        begin
          HStr.ReadBuffer( ValueBYTE, 1);
          Line := Line + '[' + IntToStr(ArrayIndex) + '] (Color) = [R=' + IntToStr(ValueBYTE);
          HStr.ReadBuffer( ValueBYTE, 1);
          Line := Line + ';G=' + IntToStr(ValueBYTE);
          HStr.ReadBuffer( ValueBYTE, 1);
          Line := Line + ';B=' + IntToStr(ValueBYTE);
          HStr.ReadBuffer( ValueBYTE, 1);
          Line := Line + ';A=' + IntToStr(ValueBYTE) + ']';
        end;
        // Vector struct
        if ( NameTable.ObjectName[StructINDEX] = 'Vector' ) then
        begin
          HStr.ReadBuffer( ValueFloat, 4);
          Line := Line + '[' + IntToStr(ArrayIndex) + '] (Vector) = [x=' + FloatToStr(ValueFloat);
          HStr.ReadBuffer( ValueFloat, 4);
          Line := Line + '; y=' + FloatToStr(ValueFloat);
          HStr.ReadBuffer( ValueFloat, 4);
          Line := Line + '; x=' + FloatToStr(ValueFloat) + ']';
        end;
        // Rotator struct
        if ( NameTable.ObjectName[StructINDEX] = 'Rotator' ) then
        begin
          HStr.ReadBuffer( ValueDWORD, 4);
          Line := Line + '[' + IntToStr(ArrayIndex) + '] (Rotator) = [pitch=' + IntToStr(ValueDWORD);
          HStr.ReadBuffer( ValueDWORD, 4);
          Line := Line + '; yaw=' + IntToStr(ValueDWORD);
          HStr.ReadBuffer( ValueDWORD, 4);
          Line := Line + '; roll=' + IntToStr(ValueDWORD) + ']';
        end;
        // Scale struct
        if ( NameTable.ObjectName[StructINDEX] = 'Scale' ) then
        begin
          HStr.ReadBuffer( ValueFloat, 4);
          Line := Line + '[' + IntToStr(ArrayIndex) + '] (Scale) = [x=' + FloatToStr(ValueFloat);
          HStr.ReadBuffer( ValueFloat, 4);
          Line := Line + '; y=' + FloatToStr(ValueFloat);
          HStr.ReadBuffer( ValueFloat, 4);
          Line := Line + '; x=' + FloatToStr(ValueFloat);
          HStr.ReadBuffer( ValueDWORD, 4);
          Line := Line + '; sheerrate=' + IntToStr(ValueDWORD);
          HStr.ReadBuffer( ValueBYTE, 1);
          Line := Line + '; sheeraxis=' + IntToStr(ValueBYTE) + ']';
        end;
        // PointRegion
        if ( NameTable.ObjectName[StructINDEX] = 'PointRegion' ) then
        begin
          ValueINDEX := Read_INDEX( Hstr_Handle );
          Line := Line + '[' + IntToStr(ArrayIndex) + '] (PointRegion) = [zone=' + Evaluate_ObjectReference(ValueINDEX);
          HStr.ReadBuffer( ValueDWORD, 4);
          Line := Line + '; ileaf=' + IntToStr(ValueDWORD);
          HStr.ReadBuffer( ValueBYTE, 1);
          Line := Line + '; zonenumber=' + IntToStr(ValueBYTE) + ']';
        end;
      end;
    end;

  // pass Line back
  Result := Line;
end;


//------------------------------------------------------------------------------
// Read all properties of current texture

procedure TTexture_Load.Read_GenericTextureProperties;
var
  Line            : string;
  Index           : integer;
begin
  Output.Add(' ');

  if ( IsAnimated = TRUE ) then
  begin
    Output.Add('Additional Properties of Frame ' + Name);
    Output.Add('---------------------------------------------');
    Output.Add(' ');
  end;

  Hstr.Seek( Offset, soFromBeginning );

  Index := Read_INDEX( Hstr_Handle );            // Read INDEX into NameTable for first loop

  while ( NameTable.ObjectName[Index] <> 'None' ) do
  begin
    Line := Decode_UnknownProperty( Index );

    // Add line to output StringList
    Output.Add(Line);

    // Read INDEX into NameTable for next pass of this loop
    Index := Read_INDEX( Hstr_Handle );
    // Check for additional break-conditions (like unknown properties)
    if ( Index > NameTable.Count - 1 ) then
    begin
      Output.Add('Unknown property. Scan aborted.');
      break;
    end;
    if ( Index < 0 ) then
    begin
      Output.Add('Unknown property. Scan aborted.');
      break;
    end;
  end;
end;

end.
