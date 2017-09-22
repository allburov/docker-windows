Stop-Service *postgresql*
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
cp $scriptPath\postgresql.conf 'C:\Program Files\PostgreSQL\9.6\data' -force -verbose
Start-Service *postgresql*

sleep 5

$env:PGPASSWORD='postgres'
cd 'C:\Program Files\PostgreSQL\9.6\bin'
& ./psql.exe --username=postgres --no-password --command="CREATE USER pt_system WITH SUPERUSER CREATEDB CREATEROLE REPLICATION PASSWORD 'P@ssw0rd';"
