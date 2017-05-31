unit migration_002_create_test_table;

interface

uses
  OlfeiSchema;

implementation

begin
  OlfeiTable := NewTable('test');

  OlfeiTable.NewString('name');
  OlfeiTable.NewInteger('years');
  OlfeiTable.NewIntegerUnsigned('user_id');

  OlfeiTable.NewForeign('users', 'user_id', 'id', 'CASCADE');
end.


