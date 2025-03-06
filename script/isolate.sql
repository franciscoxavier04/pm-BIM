DELETE FROM deploy_targets;
DELETE FROM deploy_status_checks;

DELETE FROM storages;
DELETE FROM storages_file_links_journals;
DELETE FROM project_storages;
DELETE FROM last_project_folders;
DELETE FROM remote_identities;
DELETE FROM file_links;
DELETE FROM webhooks_events;
DELETE FROM webhooks_logs;
DELETE FROM webhooks_webhooks;
DELETE FROM settings WHERE name = 'mail_from';
DELETE FROM settings WHERE lower(name) like 'smtp_%';

UPDATE users set mail = '';
