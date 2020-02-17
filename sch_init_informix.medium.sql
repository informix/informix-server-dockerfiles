database sysadmin;
grant dba to root;

execute function admin ('modify chunk extendable', 1);

execute function admin('STORAGEPOOL ADD', '$BASEDIR/data/spaces', 
                      0,0,'64MB',1); 
execute function admin('CREATE DBSPACE FROM STORAGEPOOL', 
                       'datadbs', '100 MB'); 
execute function admin('CREATE TEMPDBSPACE FROM STORAGEPOOL', 
                       'tmpdbspace', '50 MB'); 