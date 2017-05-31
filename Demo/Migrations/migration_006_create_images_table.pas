unit migration_006_create_images_table;

interface

uses
  OlfeiSchema;

implementation

begin
  OlfeiTable := NewTable('images');

  OlfeiTable.NewText('name');
  OlfeiTable.NewIntegerUnsigned('user_id');
  OlfeiTable.NewForeign('users', 'user_id', 'id');
end.
