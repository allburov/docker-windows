$PathToNuget = "nuget.exe"
$repos = ('repo.snapshot', 'repo.release')
$username = "user_reader"
$password = "password"
  
# Добавляем
$repos | %{ & $PathToNuget sources Add -Name $_ -Source https://yournugetrepo.example.com/artifactory/api/nuget/$_} 
$repos | %{ & $PathToNuget sources update -Name $_ -UserName $username -Password $password}