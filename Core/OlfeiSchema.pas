unit OlfeiSchema;

interface

uses
  OlfeiSQL, SysUtils, OlfeiSQLDriver, System.Classes;

const
  TOlfeiFieldTypeString = 0;
  TOlfeiFieldTypeInteger = 1;
  TOlfeiFieldTypeIntegerUnsigned = 2;
  TOlfeiFieldTypeFloat = 3;
  TOlfeiFieldTypeText = 4;
  TOlfeiFieldTypeBoolean = 5;
  TOlfeiFieldTypeDateTime = 6;
  TOlfeiFieldTypeDate = 7;
  TOlfeiFieldTypeBlob = 8;

type
  TOlfeiTableIndex = record
    FName: string;
  end;

  TOlfeiTableForeign = record
    FTable, FLocalKey, FRemoteKey, FOnDelete: string;
  end;

  TOlfeiTableField = record
    FName, Default: string;
    FType: word;
    DecimalSize, Size: integer;
  end;

  TOlfeiTableFields = array of TOlfeiTableField;
  TOlfeiTableSeeds = array of TStringList;
  TOlfeiTableIndexes = array of TOlfeiTableIndex;
  TOlfeiTableForeigns = array of TOlfeiTableForeign;

  TOlfeiTableSchema = class
  private
    IsNew: boolean;
    FNewFields: TOlfeiTableFields;
    FUpdateFields: TOlfeiTableFields;
    FDropFields: TOlfeiTableFields;
    FTableName: string;
    FMigrationName: string;
    FSeeds: TOlfeiTableSeeds;
    FIndexes: TOlfeiTableIndexes;
    FForeigns: TOlfeiTableForeigns;
    FDropIndexes: TOlfeiTableIndexes;
    FDropForeigns: TOlfeiTableIndexes;

    procedure AddField(AName: string; AType: word; ASize: Integer; ADefault: string);
    procedure AddDecimalField(AName: string; AType: word; ASize, ADecimalSize: Integer; ADefault: string);

    procedure UpdateField(AName: string; AType: word; ASize: Integer; ADefault: string);
    procedure UpdateDecimalField(AName: string; AType: word; ASize, ADecimalSize: Integer; ADefault: string);
  public
    Pivot: boolean;

    property Migration: string read FMigrationName;
    property Table: string read FTableName;
    property NewFields: TOlfeiTableFields read FNewFields;
    property UpdateFields: TOlfeiTableFields read FUpdateFields;
    property DropFields: TOlfeiTableFields read FDropFields;
    property Seeds: TOlfeiTableSeeds read FSeeds;
    property Indexes: TOlfeiTableIndexes read FIndexes;
    property Foreigns: TOlfeiTableForeigns read FForeigns;
    property DropIndexes: TOlfeiTableIndexes read FDropIndexes;
    property DropForeigns: TOlfeiTableIndexes read FDropForeigns;
    property New: boolean read IsNew;

    procedure NewString(AName: string; ASize: integer = 255; ADefault: string = 'NULL');
    procedure NewInteger(AName: string; ASize: integer = 11; ADefault: string = 'NULL');
    procedure NewIntegerUnsigned(AName: string; ASize: integer = 11; ADefault: string = 'NULL');
    procedure NewFloat(AName: string; ASize: integer = 16; ADecimalSize: integer = 2; ADefault: string = 'NULL');
    procedure NewText(AName: string; ASize: integer = 65535; ADefault: string = 'NULL');
    procedure NewBoolean(AName: string; ADefault: boolean = false);
    procedure NewDateTime(AName: string; ADefault: string = 'NULL');
    procedure NewDate(AName: string; ADefault: string = 'NULL');
    procedure NewBlob(AName: string);

    procedure NewTimestamps;

    procedure UpdateString(AName: string; ASize: integer = 255; ADefault: string = 'NULL');
    procedure UpdateInteger(AName: string; ASize: integer = 11; ADefault: string = 'NULL');
    procedure UpdateIntegerUnsigned(AName: string; ASize: integer = 11; ADefault: string = 'NULL');
    procedure UpdateFloat(AName: string; ASize: integer = 16; ADecimalSize: integer = 2; ADefault: string = 'NULL');
    procedure UpdateText(AName: string; ASize: integer = 65525; ADefault: string = 'NULL');
    procedure UpdateBoolean(AName: string; ADefault: boolean = false);
    procedure UpdateDateTime(AName: string; ADefault: string = 'NULL');
    procedure UpdateDate(AName: string; ADefault: string = 'NULL');
    procedure UpdateBlob(AName: string);

    procedure NewIndex(AName: string);
    procedure NewForeign(ATable, ALocalKey, ARemoteKey: string; AOnDelete: string = 'NO ACTION');

    procedure Drop(AName: string);
    procedure DropIndex(AName: string);
    procedure DropForeign(AName: string);

    function Seed(AName: string = ''): TStringList;

    constructor Create(ATable: string; New: boolean = false); overload;
    destructor Destroy; override;
  end;

  TOlfeiSchema = class
  private
    Driver: TOlfeiSQLDriver;
  public
    constructor Create(ADriver: TOlfeiSQLDriver); overload;
    procedure Run;
  end;
  
var
  OlfeiTable: TOlfeiTableSchema;
  OlfeiTables: array of TOlfeiTableSchema;
  OlfeiSeed: TStringList;

function NewTable(ATable: string): TOlfeiTableSchema;
function UpdateTable(ATable: string): TOlfeiTableSchema;
function PivotTable(ATable: string): TOlfeiTableSchema;

implementation

procedure ClearMigrations;
var
  i: integer;
begin
  for i := Length(OlfeiTables) - 1 downto 0 do
    OlfeiTables[i].Free;

  SetLength(OlfeiTables, 0);
end;

function NewTable(ATable: string): TOlfeiTableSchema;
begin
  SetLength(OlfeiTables, Length(OlfeiTables) + 1);
  OlfeiTables[Length(OlfeiTables) - 1] := TOlfeiTableSchema.Create(ATable, True);

  Result := OlfeiTables[Length(OlfeiTables) - 1];
end;

function UpdateTable(ATable: string): TOlfeiTableSchema;
begin
  SetLength(OlfeiTables, Length(OlfeiTables) + 1);
  OlfeiTables[Length(OlfeiTables) - 1] := TOlfeiTableSchema.Create(ATable);

  Result := OlfeiTables[Length(OlfeiTables) - 1];
end;

function PivotTable(ATable: string): TOlfeiTableSchema;
begin
  SetLength(OlfeiTables, Length(OlfeiTables) + 1);
  OlfeiTables[Length(OlfeiTables) - 1] := TOlfeiTableSchema.Create(ATable, True);
  OlfeiTables[Length(OlfeiTables) - 1].Pivot := True;

  Result := OlfeiTables[Length(OlfeiTables) - 1];
end;

constructor TOlfeiSchema.Create(ADriver: TOlfeiSQLDriver);
begin
  Driver := ADriver;
end;

constructor TOlfeiTableSchema.Create(ATable: string; New: Boolean = False);
begin
  Self.IsNew := New;
  Self.FTableName := ATable;
  Self.Pivot := false;

  if Self.IsNew then
    Self.FMigrationName := 'create_table_' + AnsiLowerCase(ATable)
  else
    Self.FMigrationName := 'update_table_' + AnsiLowerCase(ATable);
end;

destructor TOlfeiTableSchema.Destroy;
var
  i: integer;
begin
  for i := Length(FSeeds) - 1 downto 0 do
    FSeeds[i].Free;

  SetLength(FSeeds, 0);
  SetLength(FNewFields, 0);
  SetLength(FUpdateFields, 0);
  SetLength(FDropFields, 0);
  SetLength(FIndexes, 0);
  SetLength(FForeigns, 0);
  SetLength(FDropIndexes, 0);
  SetLength(FDropForeigns, 0);
end;

procedure TOlfeiTableSchema.DropIndex(AName: string);
begin
  Self.FMigrationName := Self.FMigrationName + '_drop_index_' + AName;

  SetLength(FDropIndexes, Length(FDropIndexes) + 1);
  FDropIndexes[Length(FDropIndexes) - 1].FName := AName;
end;

procedure TOlfeiTableSchema.DropForeign(AName: string);
begin
  Self.FMigrationName := Self.FMigrationName + '_drop_foreign_' + AName;

  SetLength(FDropForeigns, Length(FDropForeigns) + 1);
  FDropForeigns[Length(FDropForeigns) - 1].FName := AName;
end;

function TOlfeiTableSchema.Seed(AName: string = ''): TStringList;
begin
  Self.FMigrationName := Self.FMigrationName;

  if Length(AName) > 0 then
    Self.FMigrationName := Self.FMigrationName + '_seed_' + AName;

  SetLength(FSeeds, Length(FSeeds) + 1);
  FSeeds[Length(FSeeds) - 1] := TStringList.Create;

  Result := FSeeds[Length(FSeeds) - 1];
end;

procedure TOlfeiSchema.Run;
var
  i: integer;
  MigrationTable: TOlfeiTableSchema;
begin
  if not Self.Driver.CheckTable('migrations') then
  begin
    MigrationTable := TOlfeiTableSchema.Create('migrations', true);
    MigrationTable.NewText('name', 4096);

    Self.Driver.NewTable(MigrationTable);

    MigrationTable.Free;
  end;

  for i := 0 to Length(OlfeiTables) - 1 do
  begin
    Self.Driver.OlfeiDB.BeginTransaction;

    if not Self.Driver.IsMigrate(OlfeiTables[i].Migration) then
      if OlfeiTables[i].IsNew then
        Self.Driver.NewTable(OlfeiTables[i])
      else
        Self.Driver.UpdateTable(OlfeiTables[i]);

    Self.Driver.OlfeiDB.EndTransaction;
  end;
end;

procedure TOlfeiTableSchema.Drop(AName: string);
begin
  Self.FMigrationName := Self.FMigrationName + '_drop_' + AName;

  SetLength(Self.FDropFields, Length(Self.FDropFields) + 1);

  Self.FDropFields[Length(Self.FDropFields) - 1].FName := AName;
end;

procedure TOlfeiTableSchema.AddField(AName: string; AType: word; ASize: Integer; ADefault: string);
begin
  Self.FMigrationName := Self.FMigrationName + '_add_' + AName;
  
  SetLength(Self.FNewFields, Length(Self.FNewFields) + 1);

  Self.FNewFields[Length(Self.FNewFields) - 1].FName := AName;
  Self.FNewFields[Length(Self.FNewFields) - 1].FType := AType;
  Self.FNewFields[Length(Self.FNewFields) - 1].Default := ADefault;
  Self.FNewFields[Length(Self.FNewFields) - 1].Size := ASize;
  Self.FNewFields[Length(Self.FNewFields) - 1].DecimalSize := 0;
end;

procedure TOlfeiTableSchema.AddDecimalField(AName: string; AType: word; ASize, ADecimalSize: Integer; ADefault: string);
begin
  Self.FMigrationName := Self.FMigrationName + '_add_' + AName;

  SetLength(Self.FNewFields, Length(Self.FNewFields) + 1);

  Self.FNewFields[Length(Self.FNewFields) - 1].FName := AName;
  Self.FNewFields[Length(Self.FNewFields) - 1].FType := AType;
  Self.FNewFields[Length(Self.FNewFields) - 1].Default := ADefault;
  Self.FNewFields[Length(Self.FNewFields) - 1].Size := ASize;
  Self.FNewFields[Length(Self.FNewFields) - 1].DecimalSize := ADecimalSize;
end;

procedure TOlfeiTableSchema.UpdateField(AName: string; AType: word; ASize: Integer; ADefault: string);
begin
  Self.FMigrationName := Self.FMigrationName + '_update_' + AName;

  SetLength(Self.FUpdateFields, Length(Self.FUpdateFields) + 1);

  Self.FUpdateFields[Length(Self.FUpdateFields) - 1].FName := AName;
  Self.FUpdateFields[Length(Self.FUpdateFields) - 1].FType := AType;
  Self.FUpdateFields[Length(Self.FUpdateFields) - 1].Default := ADefault;
  Self.FUpdateFields[Length(Self.FUpdateFields) - 1].Size := ASize;
  Self.FUpdateFields[Length(Self.FUpdateFields) - 1].DecimalSize := 0;
end;

procedure TOlfeiTableSchema.UpdateDecimalField(AName: string; AType: word; ASize, ADecimalSize: Integer; ADefault: string);
begin
  Self.FMigrationName := Self.FMigrationName + '_update_' + AName;

  SetLength(Self.FUpdateFields, Length(Self.FUpdateFields) + 1);

  Self.FUpdateFields[Length(Self.FUpdateFields) - 1].FName := AName;
  Self.FUpdateFields[Length(Self.FUpdateFields) - 1].FType := AType;
  Self.FUpdateFields[Length(Self.FUpdateFields) - 1].Default := ADefault;
  Self.FUpdateFields[Length(Self.FUpdateFields) - 1].Size := ASize;
  Self.FUpdateFields[Length(Self.FUpdateFields) - 1].DecimalSize := ADecimalSize;
end;

procedure TOlfeiTableSchema.NewBoolean(AName: string; ADefault: boolean);
begin
  Self.AddField(AName, TOlfeiFieldTypeBoolean, 1, ADefault.ToString());
end;

procedure TOlfeiTableSchema.NewDate(AName: string; ADefault: string);
begin
  Self.AddField(AName, TOlfeiFieldTypeDate, 0, ADefault);
end;

procedure TOlfeiTableSchema.NewFloat(AName: string; ASize: integer; ADecimalSize: integer;
  ADefault: string);
begin
  Self.AddDecimalField(AName, TOlfeiFieldTypeFloat, ASize, ADecimalSize, ADefault);
end;

procedure TOlfeiTableSchema.NewForeign(ATable, ALocalKey, ARemoteKey: string; AOnDelete: string = 'NO ACTION');
begin
  Self.FMigrationName := Self.FMigrationName + '_add_foreign_' + ALocalKey;

  SetLength(FForeigns, Length(FForeigns) + 1);
  FForeigns[Length(FForeigns) - 1].FTable := ATable;
  FForeigns[Length(FForeigns) - 1].FLocalKey := ALocalKey;
  FForeigns[Length(FForeigns) - 1].FRemoteKey := ARemoteKey;
  FForeigns[Length(FForeigns) - 1].FOnDelete := AOnDelete;
end;

procedure TOlfeiTableSchema.NewIndex(AName: string);
begin
  Self.FMigrationName := Self.FMigrationName + '_add_index_' + AName;

  SetLength(FIndexes, Length(FIndexes) + 1);
  FIndexes[Length(FIndexes) - 1].FName := AName;
end;

procedure TOlfeiTableSchema.NewInteger(AName: string; ASize: integer;
  ADefault: string);
begin
  Self.AddField(AName, TOlfeiFieldTypeInteger, ASize, ADefault);
end;

procedure TOlfeiTableSchema.NewIntegerUnsigned(AName: string; ASize: integer;
  ADefault: string);
begin
  Self.AddField(AName, TOlfeiFieldTypeIntegerUnsigned, ASize, ADefault);
end;

procedure TOlfeiTableSchema.NewString(AName: string; ASize: integer;
  ADefault: string);
begin
  Self.AddField(AName, TOlfeiFieldTypeString, ASize, ADefault);
end;

procedure TOlfeiTableSchema.NewBlob(AName: string);
begin
  Self.AddField(AName, TOlfeiFieldTypeBlob, 0, 'NULL');
end;

procedure TOlfeiTableSchema.UpdateBlob(AName: string);
begin
  Self.UpdateField(AName, TOlfeiFieldTypeBlob, 0, 'NULL');
end;

procedure TOlfeiTableSchema.NewText(AName: string; ASize: integer;
  ADefault: string);
begin
  Self.AddField(AName, TOlfeiFieldTypeText, ASize, ADefault);
end;

procedure TOlfeiTableSchema.NewDateTime(AName: string; ADefault: string);
begin
  Self.AddField(AName, TOlfeiFieldTypeDateTime, 0, ADefault);
end;

procedure TOlfeiTableSchema.NewTimestamps;
begin
  Self.AddField('created_at', TOlfeiFieldTypeDateTime, 0, 'NULL');
  Self.AddField('updated_at', TOlfeiFieldTypeDateTime, 0, 'NULL');
end;

procedure TOlfeiTableSchema.UpdateBoolean(AName: string; ADefault: boolean);
begin
  Self.UpdateField(AName, TOlfeiFieldTypeBoolean, 1, ADefault.ToString());
end;

procedure TOlfeiTableSchema.UpdateDate(AName, ADefault: string);
begin
  Self.UpdateField(AName, TOlfeiFieldTypeDate, 0, ADefault);
end;

procedure TOlfeiTableSchema.UpdateFloat(AName: string; ASize: integer; ADecimalSize: integer;
  ADefault: string);
begin
  Self.UpdateDecimalField(AName, TOlfeiFieldTypeFloat, ASize, ADecimalSize, ADefault);
end;

procedure TOlfeiTableSchema.UpdateInteger(AName: string; ASize: integer;
  ADefault: string);
begin
  Self.UpdateField(AName, TOlfeiFieldTypeInteger, ASize, ADefault);
end;

procedure TOlfeiTableSchema.UpdateIntegerUnsigned(AName: string; ASize: integer;
  ADefault: string);
begin
  Self.UpdateField(AName, TOlfeiFieldTypeIntegerUnsigned, ASize, ADefault);
end;

procedure TOlfeiTableSchema.UpdateString(AName: string; ASize: integer;
  ADefault: string);
begin
  Self.UpdateField(AName, TOlfeiFieldTypeString, ASize, ADefault);
end;

procedure TOlfeiTableSchema.UpdateText(AName: string; ASize: integer;
  ADefault: string);
begin
  Self.UpdateField(AName, TOlfeiFieldTypeText, ASize, ADefault);
end;

procedure TOlfeiTableSchema.UpdateDateTime(AName: string; ADefault: string);
begin
  Self.UpdateField(AName, TOlfeiFieldTypeDateTime, 0, ADefault);
end;

initialization

finalization
  ClearMigrations;

end.
