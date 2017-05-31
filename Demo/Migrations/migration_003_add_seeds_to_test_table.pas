unit migration_003_add_seeds_to_test_table;

interface

uses
  OlfeiSchema, OlfeiTest;

implementation

begin
  {$REGION 'USERS SEED'}
  OlfeiTable := UpdateTable('users');

  OlfeiSeed := OlfeiTable.Seed;

  OlfeiSeed.Values['name'] := 'test';
  {$ENDREGION}

  {$REGION 'TEST SEEDS'}
  OlfeiTable := UpdateTable('test');

  OlfeiSeed := OlfeiTable.Seed;

  OlfeiSeed.Values['name'] := 'Кирилл';
  OlfeiSeed.Values['years'] := '21';
  OlfeiSeed.Values['user_id'] := '1';

  OlfeiSeed := OlfeiTable.Seed;

  OlfeiSeed.Values['name'] := 'Марина';
  OlfeiSeed.Values['years'] := '17';
  OlfeiSeed.Values['user_id'] := '1';
  {$ENDREGION}
end.




