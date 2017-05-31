unit OlfeiTest;

interface

uses
  OlfeiSQL, OlfeiORM, OlfeiUser;

type
  [TOlfeiTable('test')]
  TOlfeiTest = class(TOlfeiCoreORM)
    protected
      function GetOlfeiUser(index: Integer): TOlfeiUser;
    public
      [TOlfeiField('name')]
      property Name: String index 0 read GetString write SetString;

      [TOlfeiField('year')]
      property Years: Integer index 1 read GetInteger write SetInteger;

      [TOlfeiField('user_id')]
      property User: TOlfeiUser index 2 read GetOlfeiUser;
  end;

implementation

function TOlfeiTest.GetOlfeiUser(index: Integer): TOlfeiUser;
begin
  Result := TOlfeiUser(Self.GetForeignObject(index, TOlfeiUser));
end;

end.
