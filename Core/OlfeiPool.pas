unit OlfeiPool;

interface

uses
  FireDAC.Comp.Client, Classes, System.SysUtils;

type
  TOlfeiPoolResult = record
    name: string;
  end;

  TOlfeiPool = class
    private
      ConnectionManager: TFDManager;
      CountConnection: TStringList;

    public
      constructor Create;
      destructor Destroy; override;

      function AddConnection(Driver: string; SL: TStringList): TOlfeiPoolResult;
  end;

implementation

{ TOlfeiPool }

uses
  OlfeiDriverMySQL, OlfeiDriverSQLite;

constructor TOlfeiPool.Create;
begin
  inherited;

  Self.ConnectionManager := TFDManager.Create(nil);
  Self.ConnectionManager.Active := True;

  CountConnection := TStringList.Create;
end;

destructor TOlfeiPool.Destroy;
begin
  Self.ConnectionManager.Free;
  CountConnection.Free;
end;

function TOlfeiPool.AddConnection(Driver: string; SL: TStringList): TOlfeiPoolResult;
var
  tmp: string;
  Parameters: TStringList;
  DriverConnect: TObject;
begin
  Driver := SL.Values['driver'];
  Parameters := TStringList.Create;

  if Driver = 'sqlite' then
  begin
    DriverConnect := TOlfeiDriverSQLite.Create(nil);
    Parameters := (DriverConnect as TOlfeiDriverSQLite).Convert(SL);
    (DriverConnect as TOlfeiDriverSQLite).Free;
  end;

  if Driver = 'mysql' then
  begin
    {$IFDEF MSWINDOWS}
      DriverConnect := TOlfeiDriverMySQL.Create(nil);
      Parameters := (DriverConnect as TOlfeiDriverMySQL).Convert(SL);
      (DriverConnect as TOlfeiDriverMySQL).Free;
    {$ELSE}
      raise Exception.Create('Mobile platforms support only SQLite');
    {$ENDIF}
  end;

  Parameters.Values['Pooled']:= 'True';

  tmp := '1';
  if CountConnection.IndexOf(Driver) > -1 then
    tmp := (CountConnection.Values[Driver].ToInteger + 1).ToString;

  Self.ConnectionManager.AddConnectionDef('Connection_' + Driver + '_' + tmp, Driver, Parameters);

  CountConnection.Values[Driver] := tmp;

  Result.name := 'Connection_' + Driver + '_' + tmp;

  Parameters.Free;
end;

end.
