unit OlfeiDriverMySQL;

interface

uses
  OlfeiSQL, FireDAC.Comp.Client, System.SysUtils, System.Classes, OlfeiSchema,
    OlfeiSQLDriver;

type
  TOlfeiDriverMySQL = class(TOlfeiSQLDriver)
    procedure Init(Parameters: TStringList); override;

    function CheckTable(TableName: string): Boolean; override;
    procedure NewTable(OlfeiTable: TObject); override;
    procedure UpdateTable(OlfeiTable: TObject); override;
    procedure DropTable(OlfeiTable: TObject); override;
    function FieldTypeToSQL(AType: Word; ASize, ADecimalSize: integer): string; override;

    procedure ConfirmUpdate(OlfeiTable: TObject);
  end;

implementation

procedure TOlfeiDriverMySQL.Init(Parameters: TStringList);
begin
  OlfeiDB.Quote := '`';

  OlfeiDB.SQLConnection.DriverName := 'MySQL';
  OlfeiDB.SQLConnection.Params.Values['DriverID'] := 'MySQL';
  OlfeiDB.SQLConnection.Params.Values['Server'] := Parameters.Values['host'];
  OlfeiDB.SQLConnection.Params.Values['Port'] := Parameters.Values['port'];
  OlfeiDB.SQLConnection.Params.Values['CharacterSet'] := 'utf8';
  OlfeiDB.SQLConnection.Params.Values['Database'] := Parameters.Values['database'];
  OlfeiDB.SQLConnection.Params.Values['User_Name'] := Parameters.Values['user'];
  OlfeiDB.SQLConnection.Params.Values['Password'] := Parameters.Values['password'];
end;

function TOlfeiDriverMySQL.FieldTypeToSQL(AType: Word; ASize, ADecimalSize: integer): string;
begin
  if AType = TOlfeiFieldTypeString then
    Result := ' VARCHAR(' + ASize.ToString() + ')';

  if AType = TOlfeiFieldTypeInteger then
    Result := ' INT(' + ASize.ToString() + ')';

  if AType = TOlfeiFieldTypeIntegerUnsigned then
    Result := ' INT(' + ASize.ToString() + ') UNSIGNED';

  if AType = TOlfeiFieldTypeFloat then
    Result := ' DECIMAL(' + ASize.ToString() + ',' + ADecimalSize.ToString + ')';

  if AType = TOlfeiFieldTypeText then
    Result := ' TEXT(' + ASize.ToString() + ')';

  if AType = TOlfeiFieldTypeBoolean then
    Result := ' BOOL';

  if AType = TOlfeiFieldTypeDateTime then
    Result := ' DATETIME';

  if AType = TOlfeiFieldTypeDate then
    Result := ' DATE';

  if AType = TOlfeiFieldTypeBlob then
    Result := ' LONGBLOB';
end;

function TOlfeiDriverMySQL.CheckTable(TableName: string): Boolean;
var
  DS: TFDMemTable;
begin
  DS := OlfeiDB.GetSQL('SHOW TABLES LIKE "' + TableName + '"');
  Result := not DS.Eof;
  DS.Free;
end;

procedure TOlfeiDriverMySQL.NewTable(OlfeiTable: TObject);
var
  Table: TOlfeiTableSchema;
  SQL: string;
  i: integer;
begin
  Table := (OlfeiTable as TOlfeiTableSchema);

  if not Table.Pivot then
    OlfeiDB.RunSQL('CREATE TABLE ' + OlfeiDB.Quote + Table.Table + OlfeiDB.Quote + ' (' + OlfeiDB.Quote + 'id' + OlfeiDB.Quote + ' INT UNSIGNED NOT NULL AUTO_INCREMENT, PRIMARY KEY (' + OlfeiDB.Quote + 'id' + OlfeiDB.Quote + '))')
  else
  begin
    SQL := '';
    for i := 0 to Length(Table.NewFields) - 1 do
      SQL := SQL + OlfeiDB.Quote + Table.NewFields[i].FName + OlfeiDB.Quote + FieldTypeToSQL(Table.NewFields[i].FType, Table.NewFields[i].Size, Table.NewFields[i].DecimalSize) + ' ' + PrepareDefault(Table.NewFields[i].Default) + ',';

    if Length(SQL) > 0 then
      SetLength(SQL, Length(SQL) - 1);

    SQL := 'CREATE TABLE ' + OlfeiDB.Quote + Table.Table + OlfeiDB.Quote + ' (' + SQL + ')';
    OlfeiDB.RunSQL(SQL);
  end;

  ConfirmUpdate(OlfeiTable);
end;

procedure TOlfeiDriverMySQL.UpdateTable(OlfeiTable: TObject);
begin
  ConfirmUpdate(OlfeiTable);
end;

procedure TOlfeiDriverMySQL.DropTable(OlfeiTable: TObject);
begin
  OlfeiDB.RunSQL('DROP TABLE ' + OlfeiDB.Quote + (OlfeiTable as TOlfeiTableSchema).Table + OlfeiDB.Quote);
end;

procedure TOlfeiDriverMySQL.ConfirmUpdate(OlfeiTable: TObject);
var
  Table: TOlfeiTableSchema;
  i, j: integer;
  SQL, QueryFields, QueryValues: string;
begin
  Table := (OlfeiTable as TOlfeiTableSchema);

  if (not Table.Pivot) or (not Table.New) then
    for i := 0 to Length(Table.NewFields) - 1 do
    begin
      SQL := 'ALTER TABLE ' + OlfeiDB.Quote + Table.Table + OlfeiDB.Quote + ' ADD COLUMN ' + OlfeiDB.Quote + Table.NewFields[i].FName + OlfeiDB.Quote;

      SQL := SQL + FieldTypeToSQL(Table.NewFields[i].FType, Table.NewFields[i].Size, Table.NewFields[i].DecimalSize);
      SQL := SQL + ' ' + PrepareDefault(Table.NewFields[i].Default);

      OlfeiDB.RunSQL(SQL);
    end;

  for i := 0 to Length(Table.UpdateFields) - 1 do
  begin
    SQL := 'ALTER TABLE ' + OlfeiDB.Quote + Table.Table + OlfeiDB.Quote + ' MODIFY ' + OlfeiDB.Quote + Table.UpdateFields[i].FName + OlfeiDB.Quote;

    SQL := SQL + FieldTypeToSQL(Table.UpdateFields[i].FType, Table.UpdateFields[i].Size, Table.UpdateFields[i].DecimalSize);
    SQL := SQL + ' ' + PrepareDefault(Table.UpdateFields[i].Default);

    OlfeiDB.RunSQL(SQL);
  end;

  for i := 0 to Length(Table.DropFields) - 1 do
  begin
    SQL := 'ALTER TABLE ' + OlfeiDB.Quote + Table.Table + OlfeiDB.Quote + ' DROP ' + OlfeiDB.Quote + Table.DropFields[i].FName + OlfeiDB.Quote;

    OlfeiDB.RunSQL(SQL);
  end;

  for i := 0 to Length(Table.Indexes) - 1 do
    OlfeiDB.RunSQL('CREATE INDEX ' + OlfeiDB.Quote + Table.Table + '_' + Table.Indexes[i].FName + '_index' + OlfeiDB.Quote + ' ON ' + OlfeiDB.Quote + Table.Table + OlfeiDB.Quote + ' (' + OlfeiDB.Quote + Table.Indexes[i].FName + OlfeiDB.Quote + ')');

  for i := 0 to Length(Table.DropIndexes) - 1 do
    OlfeiDB.RunSQL('DROP INDEX ' + OlfeiDB.Quote + Table.Table + '_' + Table.DropIndexes[i].FName + '_index' + OlfeiDB.Quote + ' ON ' + OlfeiDB.Quote + Table.Table + OlfeiDB.Quote);

  for i := 0 to Length(Table.Foreigns) - 1 do
    OlfeiDB.RunSQL('ALTER TABLE ' + OlfeiDB.Quote + Table.Table + OlfeiDB.Quote + ' ADD CONSTRAINT ' + OlfeiDB.Quote + Table.Table + '_' + Table.Foreigns[i].FLocalKey + '_foreign' + OlfeiDB.Quote + ' FOREIGN KEY (' + OlfeiDB.Quote + Table.Foreigns[i].FLocalKey + OlfeiDB.Quote + ') REFERENCES ' + OlfeiDB.Quote + Table.Foreigns[i].FTable + OlfeiDB.Quote + '(' + OlfeiDB.Quote + Table.Foreigns[i].FRemoteKey + OlfeiDB.Quote + ') ON DELETE ' + Table.Foreigns[i].FOnDelete);

  for i := 0 to Length(Table.DropForeigns) - 1 do
    OlfeiDB.RunSQL('ALTER TABLE ' + OlfeiDB.Quote + Table.Table + OlfeiDB.Quote + ' DROP FOREIGN KEY ' + OlfeiDB.Quote + Table.Table + '_' + Table.DropForeigns[i].FName + '_foreign' + OlfeiDB.Quote);

  for i := 0 to Length(Table.Seeds) - 1 do
  begin
    QueryFields := '';
    QueryValues := '';

    for j := 0 to Table.Seeds[i].Count - 1 do
    begin
      QueryFields := QueryFields + OlfeiDB.Quote + Table.Seeds[i].Names[j] + OlfeiDB.Quote + ',';
      QueryValues := QueryValues + '"' + Table.Seeds[i].ValueFromIndex[j] + '"' + ',';
    end;

    SetLength(QueryFields, Length(QueryFields) - 1);
    SetLength(QueryValues, Length(QueryValues) - 1);

    OlfeiDB.RunSQL('INSERT INTO ' + OlfeiDB.Quote + Table.Table + OlfeiDB.Quote + '(' + QueryFields + ') VALUES (' + QueryValues + ')');
  end;

  OlfeiDB.RunSQL('INSERT INTO ' + OlfeiDB.Quote + 'migrations' + OlfeiDB.Quote + ' (' + OlfeiDB.Quote + 'name' + OlfeiDB.Quote + ') VALUES ("' + Table.Migration + '")');
end;

end.

