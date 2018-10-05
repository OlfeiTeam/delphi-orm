unit OlfeiCollection;

interface

uses
  OlfeiSQL, System.SysUtils, System.Classes, FireDac.Comp.Client, System.Rtti,
    OlfeiORM, System.Generics.Collections, System.JSON;

type
  TOlfeiCollectionEnumerator<T> = class
  protected
    FList: TOlfeiResultArray<T>;
    FIndex: integer;
    function GetCurrent: T;
  public
    constructor Create(AList: TOlfeiResultArray<T>);
    function MoveNext: Boolean;
    property Current: T read GetCurrent;
  end;

  TOlfeiCollectionResult<T> = class
  protected
    FList: TOlfeiResultArray<T>;
  public
    constructor Create; overload;
    function GetEnumerator: TOlfeiCollectionEnumerator<T>;
    procedure Assign(AList: TOlfeiResultArray<T>);
  end;

  TOlfeiCollection<T: class> = class
    private
      FJSONArray: TJSONArray;
      FTable: String;
      FDB: TOlfeiDB;
      FParentClass: TClass;
      IsPreInput: Boolean;
      IsPivot: boolean;
      QueryString, OrderString, LimitString, DistinctString: String;

      FFilterFields: TOlfeiFilterFields;

      FRemoteKey, FRemoteTable, FLocalKey: string;

      procedure Clear;
    protected
      Elements: TOlfeiResultArray<T>;
      Iterator: TOlfeiCollectionResult<T>;

      function GetResultQuery: string;
      function RttiMethodInvokeEx(const MethodName:string; RttiType : TRttiType; Instance: TValue; const Args: array of TValue): TValue;
    public
      property RemoteKey: string read FRemoteKey write FRemoteKey;
      property RemoteTable: string read FRemoteTable write FRemoteTable;
      property LocalKey: string read FLocalKey write FLocalKey;

      function Where(Name, Comparison, Value: String): TOlfeiCollection<T>; overload;
      function Where(Name, Value: string): TOlfeiCollection<T>; overload;
      function StartGroup: TOlfeiCollection<T>;
      function StartAndGroup: TOlfeiCollection<T>;
      function StartOrGroup: TOlfeiCollection<T>;
      function EndGroup: TOlfeiCollection<T>;
      function OrWhere(Name, Comparison, Value: String): TOlfeiCollection<T>;
      function OrderBy(Field, Direction: String): TOlfeiCollection<T>;
      function WhereFor(Table, Name, Comparison, Value: String): TOlfeiCollection<T>;
      function OrWhereFor(Table, Name, Comparison, Value: String): TOlfeiCollection<T>;
      function OrderByFor(Table, Field, Direction: String): TOlfeiCollection<T>;
      function Limit(Offset, Limit: integer): TOlfeiCollection<T>;
      function Distinct(Field: string): TOlfeiCollection<T>;

      function Join(Table, FieldJoin, FieldJoinWith: String): TOlfeiCollection<T>;

      function Count: Integer;
      function Sum(Field: string): Real;
      function Min(Field: string): Real;
      function Max(Field: string): Real;

      procedure Truncate;
      procedure Delete;

      function Select(const AFilterFields: array of string): TOlfeiCollection<T>;

      constructor Create(ADB: TOlfeiDB; AParentClass: TClass; Pivot: boolean = false); overload;
      destructor Destroy; override;

      function All(WithCache: Boolean = True): TOlfeiCollectionResult<T>;
      function First(LockBeforeUpdate: boolean = false; WithCache: Boolean = True): T;
      function ToJSON(WithCache: Boolean = True): TJSONArray;
  end;

implementation

function TOlfeiCollection<T>.RttiMethodInvokeEx(const MethodName: string; RttiType: TRttiType; Instance: TValue; const Args: array of TValue): TValue;
var
  Found   : Boolean;
  LMethod : TRttiMethod;
  LIndex  : Integer;
  LParams : TArray<TRttiParameter>;
begin
  Result := nil;
  LMethod := nil;
  Found := False;

  for LMethod in RttiType.GetMethods do
    if SameText(LMethod.Name, MethodName) then
    begin
      LParams := LMethod.GetParameters;
      if Length(Args) = Length(LParams) then
      begin
        Found := True;
        for LIndex := 0 to Length(LParams) - 1 do
        if LParams[LIndex].ParamType.Handle <> Args[LIndex].TypeInfo then
        begin
          Found := False;
          Break;
        end;
      end;

      if Found then
        Break;
   end;

  if (LMethod <> nil) and Found then
    Result := LMethod.Invoke(Instance, Args)
  else
    raise Exception.CreateFmt('method %s not found', [MethodName]);
end;

procedure TOlfeiCollectionResult<T>.Assign(AList: TOlfeiResultArray<T>);
begin
  FList := AList;
end;

constructor TOlfeiCollectionEnumerator<T>.Create(AList: TOlfeiResultArray<T>);
begin
  inherited Create;
  FList := AList;
  FIndex := 0;
end;

function TOlfeiCollectionEnumerator<T>.MoveNext: Boolean;
begin
  Result := FIndex < Length(FList);
  if Result then
  begin
    Inc(FIndex);
  end;
end;

function TOlfeiCollectionEnumerator<T>.GetCurrent: T;
begin
  Result := FList[FIndex - 1];
end;

constructor TOlfeiCollectionResult<T>.Create;
begin
  inherited Create;
end;

function TOlfeiCollectionResult<T>.GetEnumerator: TOlfeiCollectionEnumerator<T>;
begin
  Result := TOlfeiCollectionEnumerator<T>.Create(FList);
end;

constructor TOlfeiCollection<T>.Create(ADB: TOlfeiDB; AParentClass: TClass; Pivot: boolean = false);
var
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  RttiValue: TValue;
  RttiParameters: TArray<TValue>;
begin
  FJSONArray := TJSONArray.Create;

  FDB := ADB;
  FParentClass := AParentClass;
  IsPivot := Pivot;

  RttiContext := TRttiContext.Create;
  RttiType := RttiContext.GetType(FParentClass);

  Setlength(RttiParameters, 2);
  RttiParameters[0] := TValue.From<TOlfeiDB>(ADB);
  RttiParameters[1] := TValue.From<Integer>(0);

  RttiValue := RttiType.GetMethod('Create').Invoke(RttiType.AsInstance.MetaclassType, RttiParameters);

  FTable := TOlfeiORM(RttiValue.AsObject).Table;

  TOlfeiORM(RttiValue.AsObject).Free;

  RttiContext.Free;

  QueryString := '';
  OrderString := '';
  LimitString := '';
  DistinctString := '';

  IsPreInput := False;

  Iterator := TOlfeiCollectionResult<T>.Create;
end;

destructor TOlfeiCollection<T>.Destroy;
begin
  if Assigned(FJSONArray) then
    FJSONArray.Free;

  Self.Clear;
  Iterator.Free;

  inherited;
end;

function TOlfeiCollection<T>.Limit(Offset, Limit: integer): TOlfeiCollection<T>;
begin
  LimitString := LimitString + 'LIMIT ' + Offset.ToString() + ',' + Limit.ToString() + ' ';

  Result := Self;
end;

function TOlfeiCollection<T>.Distinct(Field: string): TOlfeiCollection<T>;
begin
  DistinctString := ' DISTINCT ' + FDB.Quote + FTable + FDB.Quote + '.' + FDB.Quote + Field + FDB.Quote + ' ';

  Result := Self;
end;

function TOlfeiCollection<T>.Where(Name: String; Comparison: String; Value: String): TOlfeiCollection<T>;
begin
  if StrPos(PChar(QueryString), PChar('WHERE')) = nil then
    QueryString := QueryString + 'WHERE ' + FDB.Quote + FTable + FDB.Quote + '.' + FDB.Quote + name + FDB.Quote + ' ' + comparison + ' ' + FDB.FullQuoted(value) + ' '
  else
    if IsPreInput then
      QueryString := QueryString + 'AND ' + FDB.Quote + FTable + FDB.Quote + '.' + FDB.Quote + name + FDB.Quote + ' ' + comparison + ' ' + FDB.FullQuoted(value) + ' '
    else
      QueryString := QueryString + FDB.Quote + FTable + FDB.Quote + '.' + FDB.Quote + name + FDB.Quote + ' ' + comparison + ' ' + FDB.FullQuoted(value) + ' ';

  IsPreInput := True;

  Result := Self;
end;

function TOlfeiCollection<T>.Where(Name: String; Value: String): TOlfeiCollection<T>;
var
  Comparison: String;
begin
  Comparison := '=';

  if StrPos(PChar(QueryString), PChar('WHERE')) = nil then
    QueryString := QueryString + 'WHERE ' + FDB.Quote + FTable + FDB.Quote + '.' + FDB.Quote + name + FDB.Quote + ' ' + comparison + ' ' + FDB.FullQuoted(value) + ' '
  else
    if IsPreInput then
      QueryString := QueryString + 'AND ' + FDB.Quote + FTable + FDB.Quote + '.' + FDB.Quote + name + FDB.Quote + ' ' + comparison + ' ' + FDB.FullQuoted(value) + ' '
    else
      QueryString := QueryString + FDB.Quote + FTable + FDB.Quote + '.' + FDB.Quote + name + FDB.Quote + ' ' + comparison + ' ' + FDB.FullQuoted(value) + ' ';

  IsPreInput := True;

  Result := Self;
end;

function TOlfeiCollection<T>.StartAndGroup: TOlfeiCollection<T>;
begin
  IsPreInput := False;

  QueryString := QueryString + 'AND ( ';

  Result := Self;
end;

function TOlfeiCollection<T>.StartGroup: TOlfeiCollection<T>;
begin
  IsPreInput := False;

  if StrPos(PChar(QueryString), PChar('WHERE')) = nil then
    QueryString := QueryString + 'WHERE ( '
  else
    QueryString := QueryString + ' (';

  Result := Self;
end;

function TOlfeiCollection<T>.Select(const AFilterFields: array of string): TOlfeiCollection<T>;
var
  i: integer;
begin
  SetLength(FFilterFields, 0);
  for i := 0 to Length(AFilterFields) - 1 do
  begin
    SetLength(FFilterFields, Length(FFilterFields) + 1);
    FFilterFields[Length(FFilterFields) - 1] := AFilterFields[i];
  end;

  Result := Self;
end;

function TOlfeiCollection<T>.StartOrGroup: TOlfeiCollection<T>;
begin
  IsPreInput := False;

  QueryString := QueryString + 'OR ( ';

  Result := Self;
end;

function TOlfeiCollection<T>.EndGroup: TOlfeiCollection<T>;
begin
  IsPreInput := True;

  QueryString := QueryString + ') ';

  Result := Self;
end;

function TOlfeiCollection<T>.WhereFor(Table, Name, Comparison, Value: String): TOlfeiCollection<T>;
begin
  if StrPos(PChar(QueryString), PChar('WHERE')) = nil then
    QueryString := QueryString + 'WHERE ' + FDB.Quote + Table + FDB.Quote + '.' + FDB.Quote + name + FDB.Quote + ' ' + comparison + ' ' + FDB.FullQuoted(value) + ' '
  else
    if IsPreInput then
      QueryString := QueryString + 'AND ' + FDB.Quote + Table + FDB.Quote + '.' + FDB.Quote + name + FDB.Quote + ' ' + comparison + ' ' + FDB.FullQuoted(value) + ' '
    else
      QueryString := QueryString + FDB.Quote + Table + FDB.Quote + '.' + FDB.Quote + name + FDB.Quote + ' ' + comparison + ' ' + FDB.FullQuoted(value) + ' ';

  IsPreInput := True;

  Result := Self;
end;

function TOlfeiCollection<T>.OrWhere(Name: String; Comparison: String; Value: String): TOlfeiCollection<T>;
begin
  if StrPos(PChar(QueryString), PChar('WHERE')) = nil then
    QueryString := QueryString + 'WHERE ' + FDB.Quote + FTable + FDB.Quote + '.' + FDB.Quote + name + FDB.Quote + ' ' + comparison + ' ' + FDB.FullQuoted(value) + ' '
  else
    if IsPreInput then
      QueryString := QueryString + 'OR ' + FDB.Quote + FTable + FDB.Quote + '.' + FDB.Quote + name + FDB.Quote + ' ' + comparison + ' ' + FDB.FullQuoted(value) + ' '
    else
      QueryString := QueryString + FDB.Quote + FTable + FDB.Quote + '.' + FDB.Quote + name + FDB.Quote + ' ' + comparison + ' ' + FDB.FullQuoted(value) + ' ';

  IsPreInput := True;

  Result := Self;
end;

function TOlfeiCollection<T>.OrWhereFor(Table, Name, Comparison, Value: String): TOlfeiCollection<T>;
begin
  if StrPos(PChar(QueryString), PChar('WHERE')) = nil then
    QueryString := QueryString + 'WHERE ' + FDB.Quote + Table + FDB.Quote + '.' + FDB.Quote + name + FDB.Quote + ' ' + comparison + ' ' + FDB.FullQuoted(value) + ' '
  else
    if IsPreInput then
      QueryString := QueryString + 'OR ' + FDB.Quote + Table + FDB.Quote + '.' + FDB.Quote + name + FDB.Quote + ' ' + comparison + ' ' + FDB.FullQuoted(value) + ' '
    else
      QueryString := QueryString + FDB.Quote + Table + FDB.Quote + '.' + FDB.Quote + name + FDB.Quote + ' ' + comparison + ' ' + FDB.FullQuoted(value) + ' ';

  IsPreInput := True;

  Result := Self;
end;

function TOlfeiCollection<T>.OrderBy(field: string; direction: string): TOlfeiCollection<T>;
begin
  OrderString := OrderString + ' ORDER BY ' + FDB.Quote + FTable + FDB.Quote + '.' + FDB.Quote + field + FDB.Quote + ' ' + direction + ' ';

  Result := Self;
end;

function TOlfeiCollection<T>.OrderByFor(Table, Field: String; Direction: String): TOlfeiCollection<T>;
begin
  OrderString := OrderString + ' ORDER BY ' + FDB.Quote + Table + FDB.Quote + '.' + FDB.Quote + field + FDB.Quote + ' ' + direction + ' ';

  Result := Self;
end;

function TolfeiCollection<T>.GetResultQuery: string;
begin
  if not Self.IsPivot then
    Result := 'SELECT ' + DistinctString + FDB.Quote + FTable + FDB.Quote + '.' + FDB.Quote + 'id' + FDB.Quote + ' FROM ' + FDB.Quote + FTable + FDB.Quote + ' ' + QueryString + OrderString + LimitString
  else
    Result := 'SELECT ' + DistinctString + FDB.Quote + FTable + FDB.Quote + '.' + FDB.Quote + 'id' + FDB.Quote + ' FROM ' + FDB.Quote + FTable + FDB.Quote +
      ' JOIN ' + FDB.Quote + Self.FRemoteTable + FDB.Quote + ' ON ' + FDB.Quote + Self.FRemoteTable + FDB.Quote + '.' + FDB.Quote + Self.FRemoteKey + FDB.Quote + ' = ' + FDB.Quote + FTable + FDB.Quote + '.' + FDB.Quote + 'id' + FDB.Quote +
      ' ' + QueryString + OrderString + LimitString;
end;

function TOlfeiCollection<T>.All(WithCache: boolean = True): TOlfeiCollectionResult<T>;
var
  DS: TFDMemTable;

  RttiContext: TRttiContext;
  RttiType: TRttiType;
  RttiValue: TValue;
  RttiParameters: TArray<TValue>;
begin
  DS := FDB.GetSQL(Self.GetResultQuery);

  Self.Clear;

  while not DS.Eof do
  begin
    RttiContext := TRttiContext.Create;
    RttiType := RttiContext.GetType(FParentClass);

    Setlength(RttiParameters, 3);
    RttiParameters[0] := TValue.From<TOlfeiDB>(FDB);
    RttiParameters[1] := TValue.From<TOlfeiFilterFields>(FFilterFields);
    RttiParameters[2] := TValue.From<Integer>(DS.FieldByName('id').AsInteger);
    RttiParameters[3] := TValue.From<Boolean>(WithCache);

    RttiValue := RttiMethodInvokeEx('Create', RttiType, RttiType.AsInstance.MetaclassType, RttiParameters);

    SetLength(Elements, Length(Elements) + 1);
    Elements[Length(Elements) - 1] := T(RttiValue.AsObject);

    RttiContext.Free;

    DS.Next;
  end;

  QueryString := '';
  OrderString := '';
  LimitString := '';

  DS.Free;

  Iterator.Assign(Elements);
  Result := Iterator;
end;

function TOlfeiCollection<T>.ToJSON(WithCache: boolean = true): TJSONArray;
var
  DS: TFDMemTable;

  RttiContext: TRttiContext;
  RttiType: TRttiType;
  RttiValue: TValue;
  RttiParameters: TArray<TValue>;
  JSONObject: TJSONObject;
begin
  DS := FDB.GetSQL(Self.GetResultQuery);

  while not DS.Eof do
  begin
    RttiContext := TRttiContext.Create;
    RttiType := RttiContext.GetType(FParentClass);

    Setlength(RttiParameters, 3);
    RttiParameters[0] := TValue.From<TOlfeiDB>(FDB);
    RttiParameters[1] := TValue.From<TOlfeiFilterFields>(FFilterFields);
    RttiParameters[2] := TValue.From<Integer>(DS.FieldByName('id').AsInteger);
    RttiParameters[3] := TValue.From<Boolean>(WithCache);

    RttiValue := RttiMethodInvokeEx('Create', RttiType, RttiType.AsInstance.MetaclassType, RttiParameters);

    SetLength(Elements, Length(Elements) + 1);
    Elements[Length(Elements) - 1] := T(RttiValue.AsObject);

    JSONObject := (TJSONObject.ParseJSONValue((Elements[Length(Elements) - 1] as TOlfeiCoreORM).ToJSON.ToString) as TJSONObject);
    FJSONArray.Add(JSONObject);

    RttiContext.Free;

    DS.Next;
  end;

  QueryString := '';
  OrderString := '';
  LimitString := '';

  DS.Free;

  Result := FJSONArray;
end;

procedure TOlfeiCollection<T>.Delete;
var
  SQL: string;
begin
  if not Self.IsPivot then
    SQL := 'DELETE FROM ' + FDB.Quote + FTable + FDB.Quote + ' ' + QueryString + OrderString
  else
    SQL := 'DELETE FROM ' + FDB.Quote + FTable + FDB.Quote +
      ' JOIN ' + FDB.Quote + Self.FRemoteTable + FDB.Quote + ' ON ' + FDB.Quote + Self.FRemoteTable + FDB.Quote + '.' + FDB.Quote + Self.FRemoteKey + FDB.Quote + ' = ' + FDB.Quote + FTable + FDB.Quote + '.' + FDB.Quote + 'id' + FDB.Quote +
      ' ' + QueryString + OrderString;

  FDB.RunSQL(SQL);
end;

function TOlfeiCollection<T>.First(LockBeforeUpdate: Boolean = false; WithCache: boolean = true): T;
var
  DS: TFDMemTable;

  RttiContext: TRttiContext;
  RttiType: TRttiType;
  RttiValue: TValue;
  RttiParameters: TArray<TValue>;
begin
  if (LockBeforeUpdate) and (FDB.Driver = 'mysql') then
    DS := FDB.GetSQL(Self.GetResultQuery + ' LIMIT 1 FOR UPDATE')
  else
    DS := FDB.GetSQL(Self.GetResultQuery + ' LIMIT 1');

  Self.Clear;

  RttiContext := TRttiContext.Create;
  RttiType := RttiContext.GetType(FParentClass);

  Setlength(RttiParameters, 3);
  RttiParameters[0] := TValue.From<TOlfeiDB>(FDB);
  RttiParameters[1] := TValue.From<TOlfeiFilterFields>(FFilterFields);

  if not DS.Eof then
    RttiParameters[2] := TValue.From<Integer>(DS.FieldByName('id').AsInteger)
  else
    RttiParameters[2] := 0;

  RttiParameters[3] := TValue.From<Boolean>(WithCache);

  RttiValue := RttiMethodInvokeEx('Create', RttiType, RttiType.AsInstance.MetaclassType, RttiParameters);

  SetLength(Elements, Length(Elements) + 1);
  Elements[Length(Elements) - 1] := T(RttiValue.AsObject);

  Result := Elements[0];

  RttiContext.Free;

  QueryString := '';
  OrderString := '';
  LimitString := '';

  DS.Free;
end;

function TOlfeiCollection<T>.Count: Integer;
begin
  Result := FDB.GetOnce('SELECT ' + DistinctString + ' COUNT(' + FDB.Quote + FTable + FDB.Quote + '.' + FDB.Quote + 'id' + FDB.Quote + ') FROM ' + FDB.Quote + FTable + FDB.Quote + ' ' + QueryString, 'integer').ToInteger();

  QueryString := '';
end;

function TOlfeiCollection<T>.Sum(Field: string): real;
begin
  Result := FDB.GetOnce('SELECT ' + DistinctString + ' SUM(' + FDB.Quote + FTable + FDB.Quote + '.' + FDB.Quote + Field + FDB.Quote + ') FROM ' + FDB.Quote + FTable + FDB.Quote + ' ' + QueryString, 'integer').ToDouble();

  QueryString := '';
end;

function TOlfeiCollection<T>.Max(Field: string): real;
begin
  Result := FDB.GetOnce('SELECT ' + DistinctString + ' MAX(' + FDB.Quote + FTable + FDB.Quote + '.' + FDB.Quote + Field + FDB.Quote + ') FROM ' + FDB.Quote + FTable + FDB.Quote + ' ' + QueryString, 'integer').ToDouble();

  QueryString := '';
end;

function TOlfeiCollection<T>.Min(Field: string): real;
begin
  Result := FDB.GetOnce('SELECT ' + DistinctString + ' MIN(' + FDB.Quote + FTable + FDB.Quote + '.' + FDB.Quote + Field + FDB.Quote + ') FROM ' + FDB.Quote + FTable + FDB.Quote + ' ' + QueryString, 'integer').ToDouble();

  QueryString := '';
end;

function TOlfeiCollection<T>.Join(Table, FieldJoin, FieldJoinWith: string): TOlfeiCollection<T>;
begin
  if QueryString = '' then
    QueryString := 'LEFT JOIN ' + FDB.Quote + Table + FDB.Quote + ' ON ' + FDB.Quote + Table + FDB.Quote + '.' + FDB.Quote + FieldJoinWith + FDB.Quote + ' = ' + FDB.Quote + FTable + FDB.Quote + '.' + FDB.Quote + FieldJoin + FDB.Quote + ' '
  else
    QueryString := QueryString + 'LEFT JOIN ' + FDB.Quote + Table + FDB.Quote + ' ON ' + FDB.Quote + Table + FDB.Quote + '.' + FDB.Quote + FieldJoinWith + FDB.Quote + ' = ' + FDB.Quote + FTable + FDB.Quote + '.' + FDB.Quote + FieldJoin + FDB.Quote + ' ';

  Result := Self;
end;

procedure TOlfeiCollection<T>.Truncate;
begin
  FDB.RunSQL('DELETE FROM ' + FDB.Quote + FTable + FDB.Quote);

  if FDB.Driver = 'sqlite' then
    FDB.RunSQL('DELETE FROM ' + FDB.Quote + 'sqlite_sequence' + FDB.Quote + ' WHERE name = "' + FTable + '"');

  if FDB.Driver = 'mysql' then
    FDB.RunSQL('ALTER TABLE' + FDB.Quote + FTable + FDB.Quote + ' '+ 'AUTO_INCREMENT = 1');
end;

procedure TOlfeiCollection<T>.Clear;
var
  i: integer;
begin
  for i := Length(Elements) - 1 downto 0 do
    T(Elements[i]).Free;

  SetLength(Elements, 0);
end;

end.
