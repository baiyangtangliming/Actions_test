get_rom(){
link=$(head -1 url.txt)
sed -i '1d' url.txt
rom_name=$(echo $link | cut -d / -f 5)
curl "$link" --output "officialzip/$rom_name"

code=$(echo $rom_name | cut -d _ -f 2| tr -d '\r' |tr -d '\n')
echo $code
echo xiaowan_$code > tools/project.txt
cat tools/project.txt
rm -rf xiaowan_$code
mkdir -p xiaowan_$code/00_project_files/logs
mv officialzip/$rom_name xiaowan_$code/

bash Auto_miui.sh

cd outputzip
ls > ../temp.txt
cd ..

out_rom=$(cat temp.txt)

if [[ $code = "CEPHEUS" ]]; then
cd aliyun
python3 main.py upload "../outputzip/$out_rom" "AcmeTeam/Acme官改/小米9"
cd ..
fi

rm -rf xiaowan_$code temp.txt "outputzip/$out_rom"

start
}

start(){
romlink=$(cat url.txt)
if [[ ! $romlink = "" ]]; then
get_rom
else
rm -rf url.txt
exit
fi
}

check(){
if [[ ! -f url.txt ]]; then
devices="
%E5%B0%8F%E7%B1%B39=小米9
"
clear
rm -rf 1.txt
for device in ${devices}
   do
   device=$(echo ${device} | cut -d = -f 1)
   for line in $(curl -L -s https://github.com/mooseIre/update_miui_ota/blob/master/Develop/${device}.md | grep "zip") 
      do
      echo ${line#*\"} |grep "https" |cut -d "\"" -f 1 >> 2.txt
   done
   head -n +1 2.txt >> url.txt
   rm -rf 2.txt
   sed -i 's/hugeota/bigota/' url.txt
   echo 
done
start
else
start
fi
}

check
