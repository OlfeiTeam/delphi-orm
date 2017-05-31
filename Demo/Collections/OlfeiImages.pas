unit OlfeiImages;

interface

uses
  OlfeiSQL, OlfeiCollection, OlfeiImage;

type
  TOlfeiImages = class(TOlfeiCollection<TOlfeiImage>)
    public
      constructor Create(FDB: TOlfeiDB); overload;
  end;

implementation

constructor TOlfeiImages.Create(FDB: TOlfeiDB);
begin
  inherited Create(FDB, TOlfeiImage);
end;

end.
