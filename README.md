# ULib-SQL
A MySQL data provider for the ULib framework

# Installation
Simple how-to guide on installing it
### Server
1. Make sure you have [ULib](http://ulyssesmod.net/index.php) version 2.52 or hight installed on your server
1. Put the ulib-sql folder into your addons folder
2. Make sure you have [mysqloo](http://facepunch.com/showthread.php?t=1220537) installed correctly
3. Edit the settings in ulib-sql.lua as your perfer

### Database
* Add the table "groups"

CREATE TABLE `groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(200) NOT NULL,
  `definition` longtext NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idgroups_UNIQUE` (`id`),
  UNIQUE KEY `name_UNIQUE` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=53 DEFAULT CHARSET=latin1;

* Add the table player_permissions

CREATE TABLE `player_permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `steamid` varchar(50) NOT NULL,
  `content` longtext NOT NULL,
  `group` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idnew_table_UNIQUE` (`id`),
  UNIQUE KEY `steamid_UNIQUE` (`steamid`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=latin1;

# Usage
Simple usage guide
### First use
I recommend to turn on the Transfer-mode which will move all the data from local files into the database.
After running the module once, you'll then be able to turn off Transfer-mode and turn on the module again!

### Commands
`libsql_save_groups` - Force-save groups

`libsql_save_users` - Force-save users

`libsql_reload_groups` - Reload groups

`libsql_reload_users` - Reload users

# License
Feel free to edit, develop and redistribute as long as you keep it for free and keep the top comment in ulib-sql.lua :-)
