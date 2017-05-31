# delphi-orm

Поддерживает работу с MySQL и SQLite

Подкиньте в папку с проектом SchemaGenerator.exe. и в настройках проекта пропишите project-options-build events-prebuild events-command
$(PROJECTDIR)\SchemaGenerator migration="$(PROJECTDIR)\Classes\DataBase\Migrations\" , где "$(PROJECTDIR)\Classes\DataBase\Migrations\" путь к файлам для миграций

# Типы данных

	procedure NewString(AName: string; ASize: integer = 255; ADefault: string = 'NULL');
    procedure NewInteger(AName: string; ASize: integer = 11; ADefault: string = 'NULL');
    procedure NewIntegerUnsigned(AName: string; ASize: integer = 11; ADefault: string = 'NULL');
    procedure NewFloat(AName: string; ASize: integer = 16; ADecimalSize: integer = 2; ADefault: string = 'NULL');
    procedure NewText(AName: string; ASize: integer = 65535; ADefault: string = 'NULL');
    procedure NewBoolean(AName: string; ADefault: boolean = false);
    procedure NewDateTime(AName: string; ADefault: string = 'NULL');
    procedure NewDate(AName: string; ADefault: string = 'NULL');
    procedure NewBlob(AName: string);

    procedure NewTimestamps;

# Пример миграции

	unit migration_001_create_users_table;

	interface

	uses
	  OlfeiSchema;

	implementation

	begin
	  OlfeiTable := NewTable('users');

	  OlfeiTable.NewString('name'); 
	  OlfeiTable.NewString('password');
	  OlfeiTable.NewString('login');
	  OlfeiTable.NewTimestamps(); // Создает поля created_at и update_at

	end.

# Пример сида

	unit migration_002_add_user_seed;

	interface

	uses
	  OlfeiSchema;

	implementation

	begin
	  OlfeiSeed := OlfeiTable.Seed;
	  
	  OlfeiSeed.Values['login'] := 'admin';
	  OlfeiSeed.Values['password'] := '123';
	  OlfeiSeed.Values['name'] := 'Администратор';
	end.

# Пример модели

	unit UserModel;

	interface

	uses
	  OlfeiSQL, OlfeiORM;

	type
	  [TOlfeiTable('users')]
	  TUserModel = class(TOlfeiORM)
		public
		  [TOlfeiField('login')]
		  property Login: String index 0 read GetString write SetString;

		  [TOlfeiField('password')]
		  property Password: String index 1 read GetString write SetString;

		  [TOlfeiField('name')]
		  property Name: String index 2 read GetString write SetString;
	  end;

	implementation

	end.
	
# Пример коллекции

	unit UserModel;

	interface

	uses
	  OlfeiSQL, OlfeiCollection, UserModel;

	type
	  TUsersModels = class(TOlfeiCollection<TUserModel>)
		public
		  constructor Create(FDB: TOlfeiDB); overload;
	  end;

	implementation

	constructor TUsersModels.Create(FDB: TOlfeiDB);
	begin
	  inherited Create(FDB, TUserModel);
	end;

	end.

# Пример модели со связанной коллекцией

	[TOlfeiTable('users')]
	TUserModel = class(TOlfeiORM)
		private
			function GetOlfeiImages(index: integer): TOlfeiCollection<TOlfeiImage>;
			function GetOlfeiFriends(index: integer): TOlfeiCollection<TUserModel>;
		public
			[TOlfeiField('login')]
			property Login: String index 0 read GetString write SetString;

			[TOlfeiField('password')]
			property Password: String index 1 read GetString write SetString;

			[TOlfeiField('name')]
			property Name: String index 2 read GetString write SetString;
			
			[TOlfeiCollectionField('id', 'user_id')]
			property Images: TOlfeiCollection<TOlfeiImage> index 0 read GetOlfeiImages;

			[TOlfeiPivotField('user_friend', 'user_id', 'friend_id')]
			property Friends: TOlfeiCollection<TUserModel> index 1 read GetOlfeiFriends;
		end;
		
	// Методы привязки
	
	function TUserModel.GetOlfeiImages(index: Integer): TOlfeiCollection<TOlfeiImage>;
	begin
	  Result := TOlfeiCollection<TOlfeiImage>(Self.GetForeignCollection(index, TOlfeiImage));
	end;

	function TUserModel.GetOlfeiFriends(index: Integer): TOlfeiCollection<TUserModel>;
	begin
	  Result := TOlfeiCollection<TUserModel>(Self.GetPivotCollection(index, TUserModel));
	end;
	
# Работа с моделями и коллекциями

    DB := InitDB; // Пример можно найти в Demo
    Users := TUsersModels.Create(DB);

    User := Users.Where('login', Login).Where('password', Pass).First;
    Result := User.Exists;
	
	User.Images; // Коллекция связанных изображений
	for Image in User.Images do
		ShowMessage(Image.Path);

    Users.Free; // Очищаем коллекцию, все связанные модели очистит сборщик мусора
    DB.Free;

# Обход данных

	Users := TUsersModels.Create(DB);
	for User in Users.All do
		ShowMessage(User.Name);

# Удаление записи

	User.Delete;

#Очистка таблицы

	Users.Truncate;

# Методы для коллекций
	
	.Where('field', 'value')
	.Where('field', '=', 'value') // Тажке можно любое условие >, >=, <, <= и тд
	.Where('field, 'IN', DB.Raw('(1, 2, 3)'))
	.OrWhere('field', 'value')
	.OrWhere('field', '=', 'value') // Тажке можно любое условие >, >=, <, <= и тд
	.OrWhere('field, 'IN', DB.Raw('(1, 2, 3)'))
	
	.OrderBy('field', 'ASC') // Можно также указать как DESC

	.StartGroup
	.StartAndGroup
	.StartOrGroup
	.EndGroup
	
	.Join('table', 'remote_key', 'local_key')
	.WhereFor('table', 'field', '=', 'value') // Тажке можно любое условие >, >=, <, <= и тд
	.OrWhereFor('table', 'field', '=', 'value') // Тажке можно любое условие >, >=, <, <= и тд
	.OrderByFor('table', 'field', 'ASC') // Можно также указать как DESC
	
	.Limit('offset', 'limit')
	.Count
	.Sum('field')
	.All
	.First

Продолжение следует...






