{ @abstract(This unit contains a class to read/decode the palette of a texture.)
  @author(Jesco Topp <jesco@users.sourceforge.net>)
  @created(November 2000)
  @lastmod(22nd Febr. 2002)
  This unit contains a class to read/decode the palette of a texture. The
  @link(TPalette_Load) class takes care of all necessary things. }
unit UTPFF_Load_Palette;

interface

uses Windows, Classes,
     UTPFF_Aux;

//------------------------------------------------------------------------------
type
  { UTPFF-class which loads and stores the palette of a texture }
  TPalette_Load = Class(TObject)
    { name of the palette }
    Palette_NAME   : string;
    { reference to the palette; undecoded ObjectReference (the palette is always
      stored in the ExportTable, so we can slip any further investigation and just
      use it as Palette_INDEX-1), see the UTPFF docs for further information }
    Palette_INDEX  : DWORD;
    { reference to the palette; decoded object reference }
    Palette_ETINDEX: DWORD;
    { number of entries in the palette }
    PaletteSize    : DWORD;
    { offset of the palette within the package }
    PaletteOffset  : DWORD;
    { array of raw palette entries, @link(TRGBAQuad) }
    Color          : array [0..255] of TRGBAQuad;
    { converted HPALETTE }
    WinPalette     : HPalette;
    { copy of the NameTable }
    NameTable   : TNameTable;
    { copy of the ImportTable }
    ImportTable : TImportTable;
    { copy of the ExportTable }
    ExportTable : TExportTable;
  public
    { interface procedure; all necessary informations to read a palette are
      passed as parameters }
    procedure Load(var NT : TNameTable; IT : TImportTable; ET : TExportTable;
                   Str_Handle : integer; INDEX : DWORD);
  private
    { reads the raw palette }
    procedure   Read_Palette(Str_Handle : integer);
    { converts the raw pallete into a windows HPALETTE }
    procedure   Convert_RAW2HPALETTE;
end;

//------------------------------------------------------------------------------
implementation

//------------------------------------------------------------------------------

// loads specified palette
procedure TPalette_Load.Load;
begin
  // copy tables
  NameTable   := NT;
  ImportTable := IT;
  ExportTable := ET;
  Palette_INDEX := INDEX;

  // Read raw data
  Read_Palette( Str_Handle );

  // Convert to HPalette
  Convert_RAW2HPALETTE;
end;

procedure TPalette_Load.Read_Palette;
var
  PaletteOffset  : longint;
  i              : integer;
  Hstr           : THandleStream;
begin
  Hstr := THandleStream.Create( Str_Handle );
  // get offset of palette in current file
  Palette_INDEX := Palette_INDEX - 1;               // palette is always in exporttable
  PaletteOffset := ExportTable.SerialOffset[Palette_INDEX];

  Hstr.Seek(PaletteOffset, soFromBeginning);

  // read property (only a 'None' one should exist)
  Read_INDEX(HStr.Handle);

  // read data
  PaletteSize := Read_INDEX( Str_Handle );
  for i:=0 to PaletteSize-1 do
  begin
    HStr.ReadBuffer( Color[i].r, 1);
    HStr.ReadBuffer( Color[i].g, 1);
    HStr.ReadBuffer( Color[i].b, 1);
    HStr.ReadBuffer( Color[i].a, 1);
  end;
  HStr.Free;
end;

//Create Hpalette
procedure TPalette_Load.Convert_RAW2HPALETTE;
var
  pal     : PLogPalette;
  i       : integer;
begin
  pal := nil;
  try
    GetMem(pal, sizeof(TLogPalette) + sizeof(TPaletteEntry) * PaletteSize);
    pal.palVersion := $300;
    pal.palNumEntries := PaletteSize;
    for i := 0 to PaletteSize-1 do
    begin
      pal.palPalEntry[i].peRed := Color[i].r;
      pal.palPalEntry[i].peGreen := Color[i].g;
      pal.palPalEntry[i].peBlue := Color[i].b;
      pal.palPalEntry[i].peFlags := 0;
    end;
    WinPalette := CreatePalette(pal^);
  finally
    FreeMem(pal);
  end;
end;

end.
