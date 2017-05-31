unit migration_004_update_price_in_users_table;

interface

uses
  OlfeiSchema;

implementation

begin
  OlfeiTable := UpdateTable('users');

  OlfeiTable.UpdateInteger('test');
end.


