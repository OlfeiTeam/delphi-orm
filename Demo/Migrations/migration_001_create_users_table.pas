unit migration_001_create_users_table;

interface

uses
  OlfeiSchema;

implementation

begin
  OlfeiTable := NewTable('users');

  OlfeiTable.NewString('name');
  OlfeiTable.NewInteger('count');
  OlfeiTable.NewFloat('price');
  OlfeiTable.NewText('description');
  OlfeiTable.NewBoolean('active');
  OlfeiTable.NewDate('birthday');
  OlfeiTable.NewDateTime('last');
  OlfeiTable.NewTimestamps();

  OlfeiTable.NewFloat('test');

  OlfeiTable.NewIndex('name');
end.