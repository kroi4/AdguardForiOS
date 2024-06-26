CREATE TABLE [version] (
[schema_version] TEXT  PRIMARY KEY NOT NULL
);

INSERT INTO [version] ([schema_version]) VALUES ('0.103');

CREATE TABLE [filter_groups] (
[group_id] INTEGER NOT NULL PRIMARY KEY,
[name] TEXT,
[display_number] INTEGER NOT NULL DEFAULT 0,
[is_enabled] BOOLEAN NOT NULL DEFAULT 0
);

CREATE TABLE [filter_group_localizations] (
[group_id] INTEGER NOT NULL,
[lang] TEXT NOT NULL,
[name] TEXT,
CONSTRAINT [pkey] PRIMARY KEY ([group_id], [lang])
);

CREATE TABLE [filters] (
[filter_id] INTEGER NOT NULL PRIMARY KEY,
[group_id] INTEGER NOT NULL DEFAULT 0,
[is_enabled] BOOLEAN NOT NULL DEFAULT 1,
[version] TEXT,
[last_update_time] TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
[display_number] INTEGER NOT NULL DEFAULT 0,
[name] TEXT,
[description] TEXT,
[homepage] TEXT,
[subscriptionUrl] TEXT
);

CREATE TABLE [filter_langs] (
[filter_id] INTEGER NOT NULL,
[lang] TEXT,
CONSTRAINT [filter_lang_pkey] PRIMARY KEY ([filter_id], [lang])
);

CREATE TABLE [filter_tags] (
[filter_id] INTEGER NOT NULL,
[tag_id] INTEGER NOT NULL,
[type] INTEGER NOT NULL,
[name] TEXT,
CONSTRAINT [filter_tag_pkey] PRIMARY KEY ([filter_id], [tag_id])
);


CREATE TABLE [filter_localizations] (
[filter_id] INTEGER NOT NULL,
[lang] TEXT,
[name] TEXT,
[description] TEXT,
CONSTRAINT [filter_localizations_pkey] PRIMARY KEY ([filter_id], [lang])
);

CREATE TABLE [filter_rules] (
[filter_id] INTEGER NOT NULL,
[rule_id] INTEGER NOT NULL,
[rule_text] TEXT NOT NULL,
[is_enabled] BOOLEAN NOT NULL DEFAULT 1,
[affinity] INTEGER,
CONSTRAINT [filter_rules_pkey] PRIMARY KEY ([filter_id], [rule_id])
);
