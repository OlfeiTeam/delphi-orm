unit OlfeiUsers;

interface

uses
  OlfeiSQL, OlfeiCollection, OlfeiUser;

type
  TOlfeiUsers = class(TOlfeiCollection<TOlfeiUser>)
    public
      constructor Create(FDB: TOlfeiDB); overload;
  end;

implementation

constructor TOlfeiUsers.Create(FDB: TOlfeiDB);
begin
  inherited Create(FDB, TOlfeiUser);
end;

end.
