rem Http
FOR /L %%A IN (30000,1,31000) DO (
netsh http add urlacl url="http://+:%%A/" sddl="D:(A;;GX;;;WD)"
)
rem Https
FOR /L %%A IN (31001,1,31100) DO (
netsh http add urlacl url="https://+:%%A/" sddl="D:(A;;GX;;;WD)"
)

netsh int ipv4 set dynamicport tcp start=40000 num=10000