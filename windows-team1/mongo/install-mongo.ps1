mkdir 'C:\data\logs'
mkdir 'C:\data\db'
& "mongod.exe" --config "C:\data\mongod.cfg" --install; exit 0
