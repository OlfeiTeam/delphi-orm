unit OlfeiDriverSQLite;

interface

uses
  OlfeiSQL, FireDAC.Comp.Client, System.SysUtils, System.Classes,
    System.IOUtils, OlfeiSQLDriver;

type
  TOlfeiDriverSQLite = class(TOlfeiSQLDriver)
    procedure Init(Parameters: TStringList); override;
    function Convert(Parameters: TStringList): TStringList; override;

    function CheckTable(TableName: string): Boolean; override;
    procedure NewTable(OlfeiTable: TObject); override;
    procedure UpdateTable(OlfeiTable: TObject); override;
    procedure DropTable(OlfeiTable: TObject); override;
    function FieldTypeToSQL(AType: Word; ASize, ADecimalSize: integer): string; override;

    procedure ConfirmUpdate(OlfeiTable: TObject);
  end;

implementation

uses
  OlfeiSchema;

function TOlfeiDriverSQLite.Convert(Parameters: TStringList): TStringList;

  function PreparePath(FilePath: string): string;
  begin
    {$IF DEFINED(iOS) or DEFINED(ANDROID)}
      Result := StringReplace(FilePath, '.\', TPath.GetDocumentsPath, []);
      Result := StringReplace(FilePath, './', TPath.GetDocumentsPath, []);
    {$ELSE}
      Result := StringReplace(FilePath, '.\', ExtractFilePath(ParamStr(0)), []);
      Result := StringReplace(FilePath, './', ExtractFilePath(ParamStr(0)), []);
    {$ENDIF}
  end;

begin
  Result := TStringList.Create;

  Result.Values['DriverID'] := 'SQLite';
  Result.Values['Database'] := PreparePath(Parameters.Values['database']);
end;

function TOlfeiDriverSQLite.FieldTypeToSQL(AType: Word; ASize, ADecimalSize: integer): string;
begin
  if AType = TOlfeiFieldTypeString then
    Result := ' VARCHAR(' + ASize.ToString() + ')';

  if AType = TOlfeiFieldTypeInteger then
    Result := ' INTEGER(' + ASize.ToString() + ')';

  if AType = TOlfeiFieldTypeIntegerUnsigned then
    Result := ' INTEGER(' + ASize.ToString() + ')';

  if AType = TOlfeiFieldTypeFloat then
    Result := ' REAL(' + ASize.ToString() + ',' + ADecimalSize.ToString() + ')';

  if AType = TOlfeiFieldTypeText then
    Result := ' TEXT(' + ASize.ToString() + ')';

  if AType = TOlfeiFieldTypeBoolean then
    Result := ' SMALLINT(1)';

  if AType = TOlfeiFieldTypeDateTime then
    Result := ' DATETIME';

  if AType = TOlfeiFieldTypeDate then
    Result := ' DATE';

  if AType = TOlfeiFieldTypeBlob then
    Result := ' BLOB';
end;

procedure TOlfeiDriverSQLite.ConfirmUpdate(OlfeiTable: TObject);
var
  i, j: integer;
  Table: TOlfeiTableSchema;
  QueryFields, QueryValues: string;
  ForeignText, SQL: string;
  DS, DSInfo: TFDMemTable;
begin
  Table := (OlfeiTable as TOlfeiTableSchema);

  if Length(Table.Foreigns) > 0 then
  begin
    ForeignText := '';
    for i := 0 to Length(Table.Foreigns) - 1 do
      ForeignText := ForeignText + 'FOREIGN KEY(' + OlfeiDB.Quote + Table.Foreigns[i].FLocalKey + OlfeiDB.Quote + ') REFERENCES ' + OlfeiDB.Quote + Table.Foreigns[i].FTable + OlfeiDB.Quote + '(' + OlfeiDB.Quote + Table.Foreigns[i].FRemoteKey + OlfeiDB.Quote + ') ON DELETE ' + Table.Foreigns[i].FOnDelete + ',';

    DS := OlfeiDB.GetSQL('PRAGMA table_info(`' + Table.Table + '`)');

    QueryFields := '';
    SQL := '';
    while not DS.Eof do
    begin
      if DS.FieldByName('name').AsString <> 'id' then
       SQL := SQL + OlfeiDB.Quote + DS.FieldByName('name').AsString + OlfeiDB.Quote + ' ' + DS.FieldByName('type').AsString + ' ' + PrepareDefault(StringReplace(DS.FieldByName('dflt_value').AsString, '"', '', [rfReplaceAll])) + ',';

      QueryFields := QueryFields + OlfeiDB.Quote + DS.FieldByName('name').AsString + OlfeiDB.Quote + ',';

      DS.Next;
    end;

    DS.Free;

    if Length(QueryFields) > 0 then
      SetLength(QueryFields, Length(QueryFields) - 1);

    if Length(SQL) > 0 then
      SetLength(SQL, Length(SQL) - 1);

    if Length(ForeignText) > 0 then
      SetLength(ForeignText, Length(ForeignText) - 1);

    OlfeiDB.RunSQL('ALTER TABLE ' + OlfeiDB.Quote + Table.Table + OlfeiDB.Quote + ' RENAME TO ' + OlfeiDB.Quote + 'tmp_' + Table.Table + OlfeiDB.Quote);
    OlfeiDB.RunSQL('CREATE TABLE ' + OlfeiDB.Quote + Table.Table + OlfeiDB.Quote + ' (' + OlfeiDB.Quote + 'id' + OlfeiDB.Quote + ' INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, ' + SQL + ',' + ForeignText + ')');

    DS := OlfeiDB.GetSQL('PRAGMA index_list(`tmp_' + Table.Table + '`)');
    while not DS.Eof do
    begin
      DSInfo := OlfeiDB.GetSQL('PRAGMA index_info(' + OlfeiDB.Quote + DS.FieldByName('name').AsString + OlfeiDB.Quote + ')');
      Table.NewIndex(DSInfo.FieldByName('name').AsString);
      DSInfo.Free;

      DS.Next;
    end;

    OlfeiDB.RunSQL('INSERT INTO ' + OlfeiDB.Quote + Table.Table + OlfeiDB.Quote + ' (' + QueryFields + ') SELECT ' + QueryFields + ' FROM ' + OlfeiDB.Quote + 'tmp_' + Table.Table + OlfeiDB.Quote);
    OlfeiDB.RunSQL('DROP TABLE ' + OlfeiDB.Quote + 'tmp_' + Table.Table + OlfeiDB.Quote);
  end;

  for i := 0 to Length(Table.Indexes) - 1 do
    OlfeiDB.RunSQL('CREATE INDEX ' + OlfeiDB.Quote + Table.Table + '_' + Table.Indexes[i].FName + '_index' + OlfeiDB.Quote + ' ON ' + OlfeiDB.Quote + Table.Table + OlfeiDB.Quote + ' (' + OlfeiDB.Quote + Table.Indexes[i].FName + OlfeiDB.Quote + ')');

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

procedure TOlfeiDriverSQLite.NewTable(OlfeiTable: TObject);
var
  i: integer;
  Table: TOlfeiTableSchema;
  SQL: string;
begin
  Table := (OlfeiTable as TOlfeiTableSchema);

  if not Table.Pivot then
  begin
    OlfeiDB.RunSQL('CREATE TABLE ' + OlfeiDB.Quote + Table.Table + OlfeiDB.Quote + ' (' + OlfeiDB.Quote + 'id' + OlfeiDB.Quote + ' INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL)');

    for i := 0 to Length(Table.NewFields) - 1 do
    begin
      SQL := 'ALTER TABLE ' + OlfeiDB.Quote + Table.Table + OlfeiDB.Quote + ' ADD COLUMN ' + OlfeiDB.Quote + Table.NewFields[i].FName + OlfeiDB.Quote;

      SQL := SQL + FieldTypeToSQL(Table.NewFields[i].FType, Table.NewFields[i].Size, Table.NewFields[i].DecimalSize);
      SQL := SQL + ' ' + PrepareDefault(Table.NewFields[i].Default);

      OlfeiDB.RunSQL(SQL);
    end;
  end
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

procedure TOlfeiDriverSQLite.DropTable(OlfeiTable: TObject);
begin
  OlfeiDB.RunSQL('DROP TABLE ' + OlfeiDB.Quote + (OlfeiTable as TOlfeiTableSchema).Table + OlfeiDB.Quote);
end;

procedure TOlfeiDriverSQLite.UpdateTable(OlfeiTable: TObject);
var
  i, key: integer;
  Table: TOlfeiTableSchema;
  SQL, QueryFields: string;
  DS, DSInfo: TFDMemTable;
  flUpdate, flSkip: boolean;
begin
  OlfeiDB.RunSQL('PRAGMA foreign_keys=OFF');

  Table := (OlfeiTable as TOlfeiTableSchema);

  if (Length(Table.UpdateFields) > 0) or (Length(Table.DropFields) > 0) then
  begin
    OlfeiDB.RunSQL('ALTER TABLE ' + OlfeiDB.Quote + Table.Table + OlfeiDB.Quote + ' RENAME TO ' + OlfeiDB.Quote + 'tmp_' + Table.Table + OlfeiDB.Quote);
    OlfeiDB.RunSQL('CREATE TABLE ' + OlfeiDB.Quote + Table.Table + OlfeiDB.Quote + ' (' + OlfeiDB.Quote + 'id' + OlfeiDB.Quote + ' INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL)');

    DS := OlfeiDB.GetSQL('PRAGMA table_info(`tmp_' + Table.Table + '`)');

    QueryFields := '';
    while not DS.Eof do
    begin
      flSkip := false;

      if DS.FieldByName('name').AsString <> 'id' then
      begin
        flUpdate := false;
        key := 0;

        for i := 0 to Length(Table.DropFields) - 1 do
        begin
          if AnsiLowerCase(Table.DropFields[i].FName) = AnsiLowerCase(DS.FieldByName('name').AsString) then
          begin
            flSkip := True;
            Break;
          end;
        end;

        if not flSkip then
        begin
          for i := 0 to Length(Table.UpdateFields) - 1 do
          begin
            if AnsiLowerCase(Table.UpdateFields[i].FName) = AnsiLowerCase(DS.FieldByName('name').AsString) then
            begin
              flUpdate := true;
              key := i;

              break;
            end;
          end;

          if flUpdate then
          begin
            SQL := 'ALTER TABLE ' + OlfeiDB.Quote + Table.Table + OlfeiDB.Quote + ' ADD COLUMN ' + OlfeiDB.Quote + Table.UpdateFields[key].FName + OlfeiDB.Quote;

            SQL := SQL + FieldTypeToSQL(Table.UpdateFields[key].FType, Table.UpdateFields[key].Size, Table.UpdateFields[key].DecimalSize);
            SQL := SQL + ' ' + PrepareDefault(Table.UpdateFields[key].Default);

            OlfeiDB.RunSQL(SQL);
          end
          else
          begin
            SQL := 'ALTER TABLE ' + OlfeiDB.Quote + Table.Table + OlfeiDB.Quote + ' ADD COLUMN ' + OlfeiDB.Quote + DS.FieldByName('name').AsString + OlfeiDB.Quote;

            SQL := SQL + ' ' + DS.FieldByName('type').AsString;
            SQL := SQL + ' ' + PrepareDefault(StringReplace(DS.FieldByName('dflt_value').AsString, '"', '', [rfReplaceAll]));

            OlfeiDB.RunSQL(SQL);
          end;
        end;
      end;

      if not flSkip then
        QueryFields := QueryFields + OlfeiDB.Quote + DS.FieldByName('name').AsString + OlfeiDB.Quote + ',';

      DS.Next;
    end;

    DS.Free;

    SetLength(QueryFields, Length(QueryFields) - 1);

    DS := OlfeiDB.GetSQL('PRAGMA index_list(' + OlfeiDB.Quote + 'tmp_' + Table.Table + OlfeiDB.Quote + ')');
    while not DS.Eof do
    begin
      DSInfo := OlfeiDB.GetSQL('PRAGMA index_info(' + OlfeiDB.Quote + DS.FieldByName('name').AsString + OlfeiDB.Quote + ')');

      flSkip := false;
      for i := 0 to Length(Table.DropIndexes) - 1 do
        if Table.DropIndexes[i].FName = DSInfo.FieldByName('name').AsString then
        begin
          flSkip := True;
          Break;
        end;

      if not flSkip then
        Table.NewIndex(DSInfo.FieldByName('name').AsString);

      DSInfo.Free;

      DS.Next;
    end;

    DS.Free;

    try
      DS := OlfeiDB.GetSQL('PRAGMA foreign_key_list(' + OlfeiDB.Quote + 'tmp_' + Table.Table + OlfeiDB.Quote + ')');

      while not DS.Eof do
      begin
        flSkip := false;
        for i := 0 to Length(Table.DropForeigns) - 1 do
          if Table.DropForeigns[i].FName = DS.FieldByName('from').AsString then
          begin
            flSkip := True;
            Break;
          end;

        if not flSkip then
          Table.NewForeign(DS.FieldByName('table').AsString, DS.FieldByName('from').AsString, DS.FieldByName('to').AsString);

        DS.Next;
      end;

      DS.Free;
    except
    end;

    OlfeiDB.RunSQL('INSERT INTO ' + OlfeiDB.Quote + Table.Table + OlfeiDB.Quote + ' (' + QueryFields + ') SELECT ' + QueryFields + ' FROM ' + OlfeiDB.Quote + 'tmp_' + Table.Table + OlfeiDB.Quote);
    OlfeiDB.RunSQL('DROP TABLE ' + OlfeiDB.Quote + 'tmp_' + Table.Table + OlfeiDB.Quote);
  end;

  for i := 0 to Length(Table.NewFields) - 1 do
  begin
    SQL := 'ALTER TABLE ' + OlfeiDB.Quote + Table.Table + OlfeiDB.Quote + ' ADD COLUMN ' + OlfeiDB.Quote + Table.NewFields[i].FName + OlfeiDB.Quote;

    SQL := SQL + FieldTypeToSQL(Table.NewFields[i].FType, Table.NewFields[i].Size, Table.NewFields[i].DecimalSize);
    SQL := SQL + ' ' + PrepareDefault(Table.NewFields[i].Default);

    OlfeiDB.RunSQL(SQL);
  end;

  ConfirmUpdate(OlfeiTable);

  OlfeiDB.RunSQL('PRAGMA foreign_keys=ON');
end;

procedure TOlfeiDriverSQLite.Init(Parameters: TStringList);

  function PreparePath(FilePath: string): string;
  begin
    {$IF DEFINED(iOS) or DEFINED(ANDROID)}
      Result := StringReplace(FilePath, '.\', TPath.GetDocumentsPath, []);
      Result := StringReplace(FilePath, './', TPath.GetDocumentsPath, []);
    {$ELSE}
      Result := StringReplace(FilePath, '.\', ExtractFilePath(ParamStr(0)), []);
      Result := StringReplace(FilePath, './', ExtractFilePath(ParamStr(0)), []);
    {$ENDIF}
  end;

begin
  OlfeiDB.Quote := '`';

  OlfeiDB.SQLConnection.DriverName := 'SQLite';
  OlfeiDB.SQLConnection.Params.Values['DriverID'] := 'SQLite';
  OlfeiDB.SQLConnection.Params.Values['Database'] := PreparePath(Parameters.Values['database']);
  OlfeiDB.SQLConnection.LoginPrompt := false;
end;

function TOlfeiDriverSQLite.CheckTable(TableName: string): Boolean;
begin
  Result := OlfeiDB.GetOnce('SELECT COUNT(name) FROM sqlite_master WHERE type = ''table'' AND name = ''' + TableName + '''', 'integer') = '1';
end;

end.
