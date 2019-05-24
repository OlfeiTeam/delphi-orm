unit OlfeiSQLDriver;

interface

uses
  OlfeiSQL, Classes;

type
  TOlfeiSQLDriver = class
  public
    OlfeiDB: TOlfeiDB;

    function CheckTable(TableName: string): Boolean; virtual; abstract;
    function FieldTypeToSQL(AType: Word; ASize, ADecimalSize: integer): string; virtual; abstract;
    procedure NewTable(OlfeiTable: TObject); virtual; abstract;
    procedure UpdateTable(OlfeiTable: TObject); virtual; abstract;
    procedure DropTable(OlfeiTable: TObject); virtual; abstract;
    procedure Init(Parameters: TStringList); virtual; abstract;
    function Convert(Parameters: TStringList): TStringList; virtual; abstract;
    function RandomOrder: string; virtual; abstract;

    function PrepareDefault(ADefault: string): String;
    function IsMigrate(MigrationName: string): Boolean;

    constructor Create(DB: TOlfeiDB); overload;
  end;

implementation

constructor TOlfeiSQLDriver.Create(DB: TOlfeiDB);
begin
  Self.OlfeiDB := DB;
end;

function TOlfeiSQLDriver.IsMigrate(MigrationName: string): boolean;
begin
  Result := Self.OlfeiDB.GetOnce('SELECT COUNT(id) FROM `migrations` WHERE name LIKE "' + MigrationName + '"', 'integer') <> '0';
end;

function TOlfeiSQLDriver.PrepareDefault(ADefault: string): string;
begin
  if ADefault = 'NULL' then
    Result := 'DEFAULT NULL'
  else if ADefault = 'NOT NULL' then
    Result := 'NOT NULL'
  else
    Result := 'DEFAULT "' + ADefault + '"';
end;

end.

