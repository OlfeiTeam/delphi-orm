unit OlfeiImage;

interface

uses
  OlfeiSQL, OlfeiORM;

type
  [TOlfeiTable('images')]
  TOlfeiImage = class(TOlfeiCoreORM)
    public
      [TOlfeiField('name')]
      property Name: String index 0 read GetString write SetString;
  end;

implementation

end.
