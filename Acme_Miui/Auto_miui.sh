#!/bin/bash

finishimg() {
for partition in ${partitions}; do
    if [[ ! -f Linux/prebuilt/$partition.img ]]; then
	echo "$xiaowan制作失败,因为$partition.img打包失败" >>$tools/fail.txt
    touch $tools/fail >/dev/null 2>&1
    fi
done
}

finishbr() {
for partition in ${partitions}; do
    if [[ ! -f Linux/prebuilt/$partition.new.dat.br ]]; then
	echo "$xiaowan制作失败,因为$partition.new.dat.br打包失败" >>$tools/fail.txt
    touch $tools/fail >/dev/null 2>&1
    fi
done
}

havebr() {
if [ -f "$LOCALDIR/prebuilt/dynamic_partitions_op_list" ]; then
sdat2br
fi
}

file2simg() {
if [ -d "system" ]; then
clear
ls $LOCALDIR/system/system/media/theme/default
cat $LOCALDIR/file_context/fs_config-system 
echo ===============================================
echo ===============================================
echo ===============================================
cat $LOCALDIR/file_context/file_contexts3-system
echo ===============================================
echo ===============================================
echo ===============================================
clear
echo
echo 创建中 system.img \($systemr字节\)
echo
sudo $LOCALDIR/bin/mkuserimg_mke2fs.sh -s "$LOCALDIR/system" "$LOCALDIR/prebuilt/system.img" ext4 / $systemr -j 0 -T 1230768000 -C $LOCALDIR/file_context/fs_config-system -L / $LOCALDIR/file_context/file_contexts3-system
fi

if [ -d "system_ext" ]; then
clear
echo
echo 创建中 system_ext.img \($system_extr字节\)
echo
sudo $LOCALDIR/bin/mkuserimg_mke2fs.sh -s "$LOCALDIR/system_ext" "$LOCALDIR/prebuilt/system_ext.img" ext4 system_ext $system_extr -j 0 -T 1230768000 -C $LOCALDIR/file_context/fs_config-system_ext -L system_ext $LOCALDIR/file_context/file_contexts3-system_ext >/dev/null 2>&1
fi

if [ -d "vendor" ]; then
clear
echo
echo 创建中 vendor.img \($vendorr字节\)
echo
sudo $LOCALDIR/bin/mkuserimg_mke2fs.sh -s "$LOCALDIR/vendor" "$LOCALDIR/prebuilt/vendor.img" ext4 vendor $vendorr -j 0 -T 1230768000 -C $LOCALDIR/file_context/fs_config-vendor -L vendor $LOCALDIR/file_context/file_contexts3-vendor >/dev/null 2>&1
fi

if [ -d "product" ]; then
clear
echo
echo 创建中 product.img \($productr字节\)
echo
sudo $LOCALDIR/bin/mkuserimg_mke2fs.sh -s "$LOCALDIR/product" "$LOCALDIR/prebuilt/product.img" ext4 product $productr -j 0 -T 1230768000 -C $LOCALDIR/file_context/fs_config-product -L product $LOCALDIR/file_context/file_contexts3-product >/dev/null 2>&1
fi
}

simg2sdat() {
ls $LOCALDIR/prebuilt/*.img | grep -v "boot\.img" | grep -v "exaid\.img" | while read i; do
    line=$(echo "$i" | cut -d"/" -f3| cut -d"." -f1)
    clear
    echo
    echo 创建中 $line.new.dat
    echo
    python "$LOCALDIR/bin/img2sdat.py" -o "$LOCALDIR/prebuilt/" -v 4 -p $line $i >/dev/null 2>&1
done

if [[ ! -e "$LOCALDIR/vabrecfast" ]]; then
rm -rf "$LOCALDIR/prebuilt/system_ext.img"
rm -rf "$LOCALDIR/prebuilt/system.img"
rm -rf "$LOCALDIR/prebuilt/vendor.img"
rm -rf "$LOCALDIR/prebuilt/product.img"
rm -rf "$LOCALDIR/prebuilt/odm.img"
fi

}

sdat2br() {
ls $LOCALDIR/prebuilt/*.new.dat | while read i; do
    line=$(echo "$i" | cut -d"/" -f3| cut -d"." -f1)
    clear
    echo
    echo 创建中 $line.new.dat.br
    echo
    "$LOCALDIR/bin/brotli" -q 4 $i >/dev/null 2>&1
    rm -rf $i
done
}

buildrom() {

LOCALDIR=.
# add need
if [ -d "vendor/etc" ]; then
clear
echo " "
echo "修改分区表"
for line in $(grep "<fs_mgr_flags>" vendor/etc/*.* -rn -l ); do
chmod 0777 $line
sed -i 's/ro\,noatime/ro/g' $line
sed -i 's/=vbmeta_system//g' $line
sed -i 's/ro\,noatime/ro/g' $line
sed -i 's/=vbmeta_system//g' $line

if [ ! -f "$LOCALDIR/keep" ];then
sed -i 's/forceencrypt/encryptable/g' $line
sed -i 's/fileencryption=ice/encryptable=ice/g' $line
fi

sed -i 's/\_keys\=\/avb\/q\-gsi\.avbpubkey\:\/avb\/r-gsi\.avbpubkey\:\/avb\/s\-gsi\.avbpubkey//g' $line
sed -i 's/,avb_keys=\/avb\/q-gsi.avbpubkey:\/avb\/r-gsi.avbpubkey:\/avb\/s-gsi.avbpubkey//g' $line
sed -i 's/,avb//g' $line
done

clear
for line in $(grep "<fs_mgr_flags>" vendor/etc/*.* -rn -l ); do
chmod 0777 $line
sed -i 's/\,encryptable=aes/\,fileencryption=aes/g' $line
done
fi

sleep 3s
clear
echo " "
echo "合并 file_contexts"
sed -i 's/\+/\\\+/g' "$LOCALDIR/file_context/file_contexts3-system"
sed -i 's/\+/\\\+/g' "$LOCALDIR/file_context/file_contexts3-vendor"

sed -i 's/\"/\_/g' "$LOCALDIR/file_context/file_contexts3-system"
sed -i 's/\"/\_/g' "$LOCALDIR/file_context/file_contexts3-vendor"
sed -i 's/\"/\_/g' "$LOCALDIR/file_context/fs_config-system"
sed -i 's/\"/\_/g' "$LOCALDIR/file_context/fs_config-vendor"

echo "/lost\+found u:object_r:rootfs:s0" >> "$LOCALDIR/file_context/file_contexts3-system"
echo "/ u:object_r:rootfs:s0" >> "$LOCALDIR/file_context/file_contexts3-system"
echo "vendor/etc/\"permissions\" 0 2000 0755" >> "$LOCALDIR/file_context/fs_config-vendor"
echo "/vendor/etc/\"permissions\" u:object_r:vendor_configs_file:s0" >> "$LOCALDIR/file_context/file_contexts3-vendor"
echo "/system/media/theme/miui_mod_icons/com.google.android.apps.nbu_ u:object_r:system_file:s0" >> "$LOCALDIR/file_context/file_contexts3-system"
echo "/system/media/theme/miui_mod_icons/com.google.android.apps.nbu_/0.png u:object_r:system_file:s0" >> "$LOCALDIR/file_context/file_contexts3-system"
echo "/system/media/theme/miui_mod_icons/com.google.android.apps.nbu_/1.png u:object_r:system_file:s0" >> "$LOCALDIR/file_context/file_contexts3-system"

echo "/system/data-app/com.topjohnwu.magisk u:object_r:system_file:s0" >> "$LOCALDIR/file_context/file_contexts3-system"
echo "/system/data-app/com.topjohnwu.magisk/com.topjohnwu.magisk.apk u:object_r:system_file:s0" >> "$LOCALDIR/file_context/file_contexts3-system"

echo "/ 0000 0000 0755" >> "$LOCALDIR/file_context/fs_config-system_ext"
echo "/ 0000 0000 0755" >> "$LOCALDIR/file_context/fs_config-system"

echo "system/data-app/com.topjohnwu.magisk 0 0 0755" >> "$LOCALDIR/file_context/fs_config-system"
echo "system/data-app/com.topjohnwu.magisk/com.topjohnwu.magisk.apk 0 0 0644" >> "$LOCALDIR/file_context/fs_config-system"

echo "/bin 0000 0000 0644" >> "$LOCALDIR/file_context/fs_config-system"

echo "odm 0 0 0755" >> "$LOCALDIR/file_context/fs_config-vendor"
echo "odm/lost\+found 0 0 0700" >> "$LOCALDIR/file_context/fs_config-vendor"
echo "/odm u:object_r:vendor_file:s0" >> "$LOCALDIR/file_context/file_contexts3-vendor"
echo "/odm/lost\+found u:object_r:vendor_file:s0" >> "$LOCALDIR/file_context/file_contexts3-vendor"

echo "system/media/theme/miui_mod_icons/com.google.android.apps.nbu_ 0 0 0755" >> "$LOCALDIR/file_context/fs_config-system"
echo "system/media/theme/miui_mod_icons/com.google.android.apps.nbu_/0.png 0 0 0644" >> "$LOCALDIR/file_context/fs_config-system"
echo "system/media/theme/miui_mod_icons/com.google.android.apps.nbu_/1.png 0 0 0644" >> "$LOCALDIR/file_context/fs_config-system"

echo "system 0000 0000 0755" >> "$LOCALDIR/file_context/fs_config-system"
echo "vendor 0000 2000 0755" >> "$LOCALDIR/file_context/fs_config-system"
echo "lost\+found 0000 0000 0700" >> "$LOCALDIR/file_context/fs_config-system"
echo "lost\+found 0000 0000 0700" >> "$LOCALDIR/file_context/fs_config-system_ext"

echo "/system_ext/lost\+found u:object_r:system_file:s0" >> "$LOCALDIR/file_context/file_contexts3-system_ext"
echo "/vendor/lost\+found u:object_r:vendor_file:s0" >> "$LOCALDIR/file_context/file_contexts3-vendor"
echo "/ u:object_r:vendor_file:s0" >> "$LOCALDIR/file_context/file_contexts3-vendor"

echo "vendor/lost\+found 0000 0000 0700" >> "$LOCALDIR/file_context/fs_config-vendor"
echo "/ 0000 2000 0755" >> "$LOCALDIR/file_context/fs_config-vendor"
echo "vendor/app/QDMA-UI/lib/arm64/libvndfwk_detect_jni.qti.so 0 0 0644" >> "$LOCALDIR/file_context/fs_config-vendor"

echo "/product/lost\+found u:object_r:system_file:s0" >> "$LOCALDIR/file_context/file_contexts3-product"
echo "/product/ u:object_r:product_file:s0" >> "$LOCALDIR/file_context/file_contexts3-product"

echo "product/lost\+found 0000 0000 0700" >> "$LOCALDIR/file_context/fs_config-product"
echo "/ 0000 0000 0755" >> "$LOCALDIR/file_context/fs_config-product"

echo "/system/product/media/audio/notifications/arcturus.ogg.ex0.srk u:object_r:system_file:s0" >> "$LOCALDIR/file_context/file_contexts3-system"
echo "/system/product/media/audio/ringtones/Andromeda.ogg.ex0.srk u:object_r:system_file:s0" >> "$LOCALDIR/file_context/file_contexts3-system"
echo "/system/product/media/audio/ringtones/hydra.ogg.ex0.srk u:object_r:system_file:s0" >> "$LOCALDIR/file_context/file_contexts3-system"
echo "/system/product/media/audio/notifications/vega.ogg.ex0.srk u:object_r:system_file:s0" >> "$LOCALDIR/file_context/file_contexts3-system"
echo "/system/product/media/audio/ringtones/CanisMajor.ogg.ex0.srk u:object_r:system_file:s0" >> "$LOCALDIR/file_context/file_contexts3-system"
echo "/system/product/media/audio/ringtones/Perseus.ogg.ex0.srk u:object_r:system_file:s0" >> "$LOCALDIR/file_context/file_contexts3-system"
echo "/system/product/media/audio/ringtones/UrsaMinor.ogg.ex0.srk u:object_r:system_file:s0" >> "$LOCALDIR/file_context/file_contexts3-system"

echo "/product/media/audio/notifications/arcturus.ogg.ex0.srk u:object_r:system_file:s0" >> "$LOCALDIR/file_context/file_contexts3-product"
echo "/product/media/audio/ringtones/Andromeda.ogg.ex0.srk u:object_r:system_file:s0" >> "$LOCALDIR/file_context/file_contexts3-product"
echo "/product/media/audio/ringtones/hydra.ogg.ex0.srk u:object_r:system_file:s0" >> "$LOCALDIR/file_context/file_contexts3-product"
echo "/product/media/audio/notifications/vega.ogg.ex0.srk u:object_r:system_file:s0" >> "$LOCALDIR/file_context/file_contexts3-product"
echo "/product/media/audio/ringtones/CanisMajor.ogg.ex0.srk u:object_r:system_file:s0" >> "$LOCALDIR/file_context/file_contexts3-product"
echo "/product/media/audio/ringtones/Perseus.ogg.ex0.srk u:object_r:system_file:s0" >> "$LOCALDIR/file_context/file_contexts3-product"
echo "/product/media/audio/ringtones/UrsaMinor.ogg.ex0.srk u:object_r:system_file:s0" >> "$LOCALDIR/file_context/file_contexts3-product"

#add by xiaowan

sudo chown -hR $myuser:$myuser ./build.sh
sudo chmod 777 ./build.sh
./build.sh

####################
grep -v ^0 "$LOCALDIR/file_context/fs_config-system" >"$LOCALDIR/file_context/fs_config-system1"
cat "$LOCALDIR/file_context/fs_config-system1" >"$LOCALDIR/file_context/fs_config-system"
grep -v ^\  "$LOCALDIR/file_context/file_contexts3-system" >"$LOCALDIR/file_context/file_contexts3-system1"
cat "$LOCALDIR/file_context/file_contexts3-system1" >"$LOCALDIR/file_context/file_contexts3-system"
clear
if [ ! -f "$LOCALDIR/finish" ];then
file2simg
simg2sdat
havebr
else
file2simg
if [[ -f "$LOCALDIR/vabrec" || -f "$LOCALDIR/vabrecfast" ]]; then
simg2sdat
havebr
fi
clear
fi

}

finish_check() {
clear
if [[ -f "$tools/fail.txt" ]]; then
fails=$(cat $tools/fail.txt)
clear
if [[ ! $fails = "" ]]; then
echo 
echo "以下项目制作失败,请查看报错日志:$tools/fail.txt"
echo 
echo $fails
echo 
else
echo 
rm -rf $tools/fail.txt >/dev/null 2>&1
echo 成功制作$all个项目
fi
else
echo 
rm -rf $tools/fail.txt >/dev/null 2>&1
echo 成功制作$all个项目
sleep 3
exit
fi
}

rmLinux() {
rm -rf $xiaowan >/dev/null 2>&1
rm -rf Linux >/dev/null 2>&1
start_build
}

chmtime() {
cd $base
sudo find ./Linux/prebuilt/** |while read line
do
sudo chown -hR $myuser:$myuser "$line"
sudo chmod 777 "$line"
touch -mt 200901010000 "$line"
done
}

fastpack() {
chmtime
mv -f Linux/prebuilt/*.img $xiaowan/output/ >/dev/null 2>&1
mv $xiaowan/output $xiaowan/images >/dev/null 2>&1
cd $base
cp -rf tools/patch/sunday/bin_flash/super.img $xiaowan/images/super.img
cp -rf tools/patch/sunday/bin_flash/* $xiaowan/
mv $xiaowan/odm.img $xiaowan/images/odm.img >/dev/null 2>&1
cd $xiaowan

###

filename="刷机说明.txt"
cat>"${filename}"<<EOF

"首次使用请务必安装驱动文件！！！

驱动位置："线刷驱动环境"  文件夹

1."FASTBOOTD驱动.exe"	（双击文件）
2."一键安装安卓驱动.exe"	（双击文件）
3."USB3.0修复补丁.bat"	（右键管理员权限）

注：
第2个无法打开，安装 "打不开安装这个（net4.0框架）.exe"
建议使用 小米官方 线刷工具 安装一次官方的驱动！！！

此包为线刷包，请进入fastboot模式后双击对应bat脚本进行刷机操作。

首次刷入请点击“flash_all.bat" （会清空数据）

后续刷入可选择“flash_all_except_storage.bat” （不会清空数据）

首次开机较慢，请耐心等待

刷机有风险，请三思而后行，不赔哦！

EOF
##
rm -rf ./misc_info.txt >/dev/null 2>&1
rm -rf ./lpmake >/dev/null 2>&1
rm -rf ./*.py >/dev/null 2>&1
rm -rf ./*.sh >/dev/null 2>&1
rm -rf __pycache__ >/dev/null 2>&1

#为bin格式分去，增加每个分区100M的大小，防止打包失败
#此时同步在打包时，也必须对应加大100M

a=104857600

if [ -f "size/system" ]; then
var=$(cat ./size/system| tr -d '\r' |tr -d '\n')
systemr=$((a+var))
sed -i 's/systemsize/'$systemr'/g' flash_all.bat
sed -i 's/systemsize/'$systemr'/g' flash_all_except_storage.bat
fi

if [ -f "size/vendor" ]; then
var1=$(cat ./size/vendor| tr -d '\r' |tr -d '\n')
vendorr=$((a+var1))
sed -i 's/vendorsize/'$vendorr'/g' flash_all.bat
sed -i 's/vendorsize/'$vendorr'/g' flash_all_except_storage.bat
fi

if [ -f "size/product" ]; then
var2=$(cat ./size/product| tr -d '\r' |tr -d '\n')
productr=$((a+var2))
sed -i 's/productsize/'$productr'/g' flash_all.bat
sed -i 's/productsize/'$productr'/g' flash_all_except_storage.bat
fi

if [ -f "size/system_ext" ]; then
var3=$(cat ./size/system_ext| tr -d '\r' |tr -d '\n')
system_extr=$((a+var3))
sed -i 's/system_extsize/'$system_extr'/g' flash_all.bat
sed -i 's/system_extsize/'$system_extr'/g' flash_all_except_storage.bat
fi

if [ -f "size/odm" ]; then
var3od=$(cat ./size/odm| tr -d '\r' |tr -d '\n')
sed -i 's/odmsize/'$var3od'/g' flash_all.bat
sed -i 's/odmsize/'$var3od'/g' flash_all_except_storage.bat
fi
clear
echo 
echo 生成线刷包
echo 
zip -r 1.zip platform-tools-windows 线刷驱动环境 images 刷机说明.txt flash_all.bat flash_all_except_storage.bat >/dev/null 2>&1
clear
echo 
echo 计算文件md5
echo 
md5=$((md5sum 1.zip) | cut -c1-6| tr -d '\r' |tr -d '\n')
cd $base
mv "$xiaowan/1.zip" "$outputzip1"/"$device"_"$version"_"$md5"_"$release"_"$android"_"fastboot.zip" >/dev/null 2>&1
clear
if [[ -f $xiaowan/finish ]]; then
if [[ $fastboot123 = "3" ]]; then
echo 
else
rmLinux
fi
else
rmLinux
fi
}

zippack() {
chmtime
cd $base
cd Linux/prebuilt
clear
echo 
echo 生成卡刷包
echo 
zip -r 1.zip * >/dev/null 2>&1
clear
echo 
echo 计算文件md5
echo 
md5=$((md5sum 1.zip) | cut -c1-6| tr -d '\r' |tr -d '\n')
cd $base
clear
mv "Linux/prebuilt/1.zip" "outputzip"/"$device"_"$version"_"$md5"_"$release"_"$android.zip" >/dev/null 2>&1
rm -rf tools/project.txt
finish_check
}

recflash() {
cd $base
cd $base/$xiaowan/output
echo "# ---- radio update tasks ----">updater-script1
echo >>updater-script1
echo "ui_print("\"Patching firmware images..."\");">>updater-script1

ls | grep "\.img" | grep -v "^odm\.img" | grep -v "^product\.img" | grep -v "^vendor\.img" | grep -v "^system\.img" | grep -v "^system_ext\.img" | while read i; do
line=$(echo "$i" | cut -d"." -f1)
echo "package_extract_file("\"firmware-update/$line.img"\", "\"/dev/block/bootdevice/by-name/$line"_a""\");">>updater-script1
echo "package_extract_file("\"firmware-update/$line.img"\", "\"/dev/block/bootdevice/by-name/$line"_b""\");">>updater-script1
done

filename="dynamic_partitions_op_list"
cat>"${filename}"<<EOF
# Remove all existing dynamic partitions and groups before applying full OTA
remove_all_groups
# Add group qti_dynamic_partitions_a with maximum size 9126805504
add_group qti_dynamic_partitions_a 9126805504
# Add group qti_dynamic_partitions_b with maximum size 9126805504
add_group qti_dynamic_partitions_b 9126805504
# Add partition system_a to group qti_dynamic_partitions_a
add system_a qti_dynamic_partitions_a
# Add partition system_b to group qti_dynamic_partitions_b
add system_b qti_dynamic_partitions_b
# Add partition system_ext_a to group qti_dynamic_partitions_a
add system_ext_a qti_dynamic_partitions_a
# Add partition system_ext_b to group qti_dynamic_partitions_b
add system_ext_b qti_dynamic_partitions_b
# Add partition product_a to group qti_dynamic_partitions_a
add product_a qti_dynamic_partitions_a
# Add partition product_b to group qti_dynamic_partitions_b
add product_b qti_dynamic_partitions_b
# Add partition vendor_a to group qti_dynamic_partitions_a
add vendor_a qti_dynamic_partitions_a
# Add partition vendor_b to group qti_dynamic_partitions_b
add vendor_b qti_dynamic_partitions_b
# Add partition odm_a to group qti_dynamic_partitions_a
add odm_a qti_dynamic_partitions_a
# Add partition odm_b to group qti_dynamic_partitions_b
add odm_b qti_dynamic_partitions_b
# Grow partition system_a from 0 to systemsize
resize system_a systemsize
# Grow partition system_ext_a from 0 to system_extsize
resize system_ext_a system_extsize
# Grow partition product_a from 0 to productsize
resize product_a productsize
# Grow partition vendor_a from 0 to vendorsize
resize vendor_a vendorsize
# Grow partition odm_a from 0 to odmsize
resize odm_a odmsize
EOF

filename="updater-script2"
cat>"${filename}"<<EOF

# --- Start patching dynamic partitions ---

# Update dynamic partition metadata

assert(update_dynamic_partitions(package_extract_file("dynamic_partitions_op_list")));

# Patch partition system

ui_print("Flashing system_a partition...");
show_progress(0.500000, 0);
block_image_update(map_partition("system_a"), package_extract_file("system.transfer.list"), "system.new.dat.br", "system.patch.dat") ||
  abort("E1001: Failed to flash system_a partition.");

# Patch partition system_ext

ui_print("Flashing system_ext_a partition...");
show_progress(0.100000, 0);
block_image_update(map_partition("system_ext_a"), package_extract_file("system_ext.transfer.list"), "system_ext.new.dat.br", "system_ext.patch.dat") ||
  abort("E2001: Failed to flash system_ext_a partition.");

# Patch partition product

ui_print("Flashing product_a partition...");
show_progress(0.100000, 0);
block_image_update(map_partition("product_a"), package_extract_file("product.transfer.list"), "product.new.dat.br", "product.patch.dat") ||
  abort("E2001: Failed to flash product_a partition.");

# Patch partition vendor

ui_print("Flashing vendor_a partition...");
show_progress(0.100000, 0);
block_image_update(map_partition("vendor_a"), package_extract_file("vendor.transfer.list"), "vendor.new.dat.br", "vendor.patch.dat") ||
  abort("E2001: Failed to flash vendor_a partition.");

# Patch partition odm

ui_print("Flashing odm_a partition...");
show_progress(0.100000, 0);
block_image_update(map_partition("odm_a"), package_extract_file("odm.transfer.list"), "odm.new.dat.br", "odm.patch.dat") ||
  abort("E2001: Failed to flash odm_a partition.");

# --- End patching dynamic partitions ---

set_progress(1.000000);

EOF

cat updater-script1 updater-script2 >updater-script
rm -rf updater-script1
rm -rf updater-script2

cd $base
mkdir -p $xiaowan/META-INF/com/google/android >/dev/null 2>&1
mv -f $xiaowan/output/updater-script $xiaowan/META-INF/com/google/android/ >/dev/null 2>&1
mv -f $xiaowan/output/dynamic_partitions_op_list $xiaowan/ >/dev/null 2>&1
cp -rf tools/patch/sunday/bin_flash/update-binary $xiaowan/META-INF/com/google/android/ >/dev/null 2>&1
}

fastbootflash() {

cd $base/$xiaowan/output
echo "@echo off">flash_all.bat
echo "cd %~dp0">>flash_all.bat
echo >>flash_all.bat
echo "platform-tools-windows\fastboot %* getvar is-userspace 2>&1 | findstr /r /c:$a"^is-userspace: *no"$a || platform-tools-windows\fastboot reboot bootloader">>flash_all.bat

ls | grep "\.img" | grep -v "^odm\.img" | grep -v "^product\.img" | grep -v "^vendor\.img" | grep -v "^system\.img" | grep -v "^system_ext\.img" | while read i; do
line=$(echo "$i" | cut -d"." -f1)
echo "platform-tools-windows\fastboot %* flash $line"_ab" images\\$line.img">>flash_all.bat
done

fastbootbak() {
for partition in ${partitions}; do
if [[ -f vbmeta\_${partition}.img ]]; then
echo "platform-tools-windows\fastboot %* flash vbmeta_${partition}"_ab" images\\vbmeta_${partition}.img">>flash_all.bat
fi
done
}

echo "platform-tools-windows\fastboot %* flash super images\super.img">>flash_all.bat
echo "platform-tools-windows\fastboot %* getvar is-userspace 2>&1 | findstr /r /c:$a"^is-userspace: *yes"$a || platform-tools-windows\fastboot reboot fastboot">>flash_all.bat
clear

for partition in ${partitions}; do
if [[ -f ${partition}.img ]]; then
echo >>flash_all.bat
echo "platform-tools-windows\fastboot %* delete-logical-partition ${partition}"_a"">>flash_all.bat
echo "platform-tools-windows\fastboot %* delete-logical-partition ${partition}"_b"">>flash_all.bat
echo "platform-tools-windows\fastboot %* create-logical-partition ${partition}"_a" ${partition}size">>flash_all.bat
echo "platform-tools-windows\fastboot %* create-logical-partition ${partition}_b 0">>flash_all.bat
echo "platform-tools-windows\fastboot %* flash ${partition}"_a" images\\${partition}.img">>flash_all.bat
fi
done

echo >>flash_all.bat
echo "platform-tools-windows\fastboot %* erase metadata">>flash_all.bat
echo "platform-tools-windows\fastboot %* erase userdata">>flash_all.bat
echo "platform-tools-windows\fastboot %* set_active a">>flash_all.bat
echo "platform-tools-windows\fastboot %* reboot">>flash_all.bat
echo "pause">>flash_all.bat
echo >>flash_all.bat
cat flash_all.bat |sed -e '/erase/d' $i>flash_all_except_storage.bat
cd $base
mv -f $xiaowan/output/*.bat $xiaowan/ >/dev/null 2>&1
}

undate() {
clear
echo 
echo 

#系列环境判断

for depc in ${deps}; do
if [[ $(which $depc) = "" ]]; then
clear
echo 
echo 找不到$depc环境
read -p ""
exit
fi
done

if [[ $(uname -s | grep "CYGWIN\|cygwin\|Cygwin") ]] || [[ $(find /mnt/c -name Windows -maxdepth 1 2>/dev/null | grep -m 1 -o Windows) = "Windows" || $(find /c -name Windows -maxdepth 1 2>/dev/null | grep -m 1 -o Windows) = "Windows" ]]; then
clear
echo 
echo "工具仅支持在Linux环境内运行"
read -p ""
exit
fi

if [[ $(echo $base | grep " ") ]]; then
clear
echo 
echo "路径中含有空格"
read -p ""
exit
fi

if [[ $(which id) ]]; then
if [[ $(id -u) = "0" ]]; then
userid="root"
fi
elif [[ $EUID = "0" ]]; then
userid="root"
fi

if [[ $userid = "root" ]]; then
clear
echo 
echo "工具不允许在root环境下运行"
read -p ""
exit
fi

}

chstat() {
sudo echo ""
sudo sed -i '/%sudo/c %sudo  ALL=(ALL:ALL)  NOPASSWD:ALL' /etc/sudoers
sleep 2
clear
#变量初始化
mversion=1.4.9
echo -e "\033]0;Auto_miui"_v"$mversion\007"
export myuser=$(echo "$(whoami | gawk '{ print $1 }')"| tr -d '\r' |tr -d '\n')
base=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`
export PATH=./tools/patch/sunday/cloudpan189:$PATH
Current=0
and11=false
product=false
Linux=false
tools=$base/tools/patch
rm -rf ./tools/patch/sunday/cloudpan189/"!(cloudpan189-go)"
scount=0
a=\"""

partitions="
odm
product
vendor
system
system_ext
"

deps="
curl
wget
java
python
unzip
aria2c
"

cd $base
rm -rf $tools/repack.txt

#是否首次运行，自动配置环境

####

if [[ ! -f $tools/depment ]]; then
clear
echo 
echo 修复文件权限...
echo 
export TERM=xterm
sudo find ./** | grep tools | while read line; do
sudo chown -hR $myuser:$myuser "$line"
sudo chmod 777 "$line"
done

sudo chown -hR $myuser:$myuser ./*.sh
sudo chmod 777 ./*.sh
touch $tools/depment
undate
else
undate
fi

clear
}

get_rom() {
clear
if [[ -f url.txt ]]; then
clear
echo 
echo "url.txt已存在,即将下载"
sleep 3
clear
echo 
cat url.txt|grep "miui">url1.txt
rm -rf url.txt >/dev/null 2>&1
mv url1.txt url.txt >/dev/null 2>&1
aria2c -s 9 -x 2 -d $officalzip1 -i url.txt  --file-allocation=falloc  -V true -c true
clear
extract_new
else
clear

#获取在线链接
rm -rf url.txt;curl -s https://cdn.jsdelivr.net/gh/mooseIre/update_miui_ota@master/config.json |grep : | while read i; do
model=$(echo ${i} | cut -d\" -f 4);device=$(echo ${i} | cut -d\" -f 2);echo 获取中:$model;curl -s https://gitee.com/RealHeart/update_miui_ota/blob/master/Develop/$(echo ${i} | cut -d\" -f 4|tr -d '\n' |od -An -tx1|tr ' ' %).md |grep $device |head -1| cut -d\( -f 2| cut -d\) -f 1| grep http |while read i; do
echo -e "$model:\\n$i">>url.txt;done;done
sleep 3
clear

if [[ ! -f url.txt ]]; then
clear
echo 
echo 获取失败...
exit
read -p ""
else
clear
echo 
echo 链接已经保存到 url.txt 请自动精简链接后，按回车开始一键下载并制作
echo 
read -p " "
clear
echo 
cat url.txt|grep "miui">url1.txt
rm -rf url.txt >/dev/null 2>&1
mv url1.txt url.txt >/dev/null 2>&1
aria2c -s 9 -x 2 -d $officalzip1 -i url.txt  --file-allocation=falloc  -V true -c true
clear
extract_new
fi;fi
}

extract_new() {


clear
echo 
#不存在官方包，自动获取
if [[ ! -f tools/project.txt ]]; then
clear
echo 
echo "不存在官方包，自动获取链接中"
sleep 3
get_rom
else
all=""
all=$(awk 'END{print NR}' tools/project.txt| tr -d '\r' |tr -d '\n')
start_build
fi

}

getmeta() {

img1=$1
img=$2

if [[ ! $(ls ./00_project_files/) ]]; then
cd $base
start_build
fi 
 
# Mount
starttime=`date +'%Y-%m-%d %H:%M:%S'`
sudo umount $img >/dev/null 2>&1
sudo rm -rf ./$img >/dev/null 2>&1
sudo mkdir $img
sudo rm -rf ./symlinks-$img
sudo rm -rf ./file_contexts3-$img
sudo rm -rf ./fs_config-$img
sudo mount -r $img1 $img/ >/dev/null 2>&1

if [[ ! $(ls ./$img/) ]]; then
cd $base
start_build
fi

# symlinks
if [[ $(sudo find ./$img -type l) ]]; then
 for line in $(sudo find ./$img -type l); do
  sudo ls -al $line |sudo grep ">" | while read line; do
      echo ${line##*  } | while read line; do
              echo ${line#* } | while read line; do          
                     OIFS=$IFS; IFS="  "; set -- $line; sym=$1;files=$3; IFS=$OIFS 
                        printf "symlink(\"$files\", \"$sym\");" >>symlinks-$img; printf "\\n" >>symlinks-$img
                   done
             done 
       done
 done
sed -i 's/\.\//\//' symlinks-$img
fi

# file_contexts3
for line in $(sudo find ./$img** | grep "$img"); do
OIFS=$IFS; IFS=" "; set -- $(sudo ls -Zd $line |grep "\.\/$img"); con=$1;files=$2; IFS=$OIFS 
echo $files $con >>file_contexts3-$img
done
if [ -d "./$img/system/app" ];then
        sed -i 's/.\{8\}//' file_contexts3-$img
          else
           sed -i 's/.\{1\}//' file_contexts3-$img
     fi
     
# fs_config
for file in $(sudo find $img** | grep "$img"); do
    uid=$(stat -c %u $file)
    gid=$(stat -c %g $file)
    fs=$(stat -c %a $file)
    printf "$file $uid $gid 0$fs" >>fs_config-$img
    printf "\\n" >>fs_config-$img
done
if [ -d "./$img/system/app" ];then
        sed -i 's/.\{7\}//' fs_config-$img
     fi

# Finish
export myuser=$(echo "$(whoami | gawk '{ print $1 }')")
rm -rf ./temp >/dev/null 2>&1
sudo mkdir temp
sudo cp -R ./$img/* ./temp
sudo chown -hR $myuser:$myuser ./temp
sudo chmod -R a+rwX ./temp
sudo umount $img >/dev/null 2>&1
endtime=`date +'%Y-%m-%d %H:%M:%S'`
start_seconds=$(date --date="$starttime" +%s);
end_seconds=$(date --date="$endtime" +%s);
echo "Finish (total :$((end_seconds-start_seconds))"s")"
rm -rf ./$img >/dev/null 2>&1
sort -bdf symlinks-$img -o symlinks-$img >/dev/null 2>&1
sort -bdf file_contexts3-$img -o file_contexts3-$img >/dev/null 2>&1
sort -bdf fs_config-$img -o fs_config-$img >/dev/null 2>&1
mv symlinks-$img 00_project_files >/dev/null 2>&1
mv file_contexts3-$img 00_project_files >/dev/null 2>&1
mv fs_config-$img 00_project_files >/dev/null 2>&1
sudo mv temp $img >/dev/null 2>&1
}

start_build() {
cd $base
keeps="
CRUX
"
clear
echo 
if [[ ! -f tools/project.txt ]]; then
clear
echo 
echo "不存在官方包"
read -p ""
exit
fi

#从tools/project.txt取出第一行为项目名称
xiaowan=""
xiaowan=$(awk 'NR==1{print}' tools/project.txt| tr -d '\r' |tr -d '\n')
sed -i '1d' tools/project.txt
if [[ $xiaowan = "" ]]; then
finish_check
if [[ $only1 = "1" ]]; then
read -p ""
exit
fi

clear
cloudpan1891=$(cat $tools/cloudpan189.txt |grep "cloudpan189"| awk -F "=" '{print $2}'| tr -d '\r' |tr -d '\n')

if [[ $cloudpan1891 = "1" ]]; then

if [[ ! $(ls ./$outputzip1/) ]]; then
clear
echo 
echo "不存在刷机包，无法上传"
read -p ""
exit
fi 

clear
echo 
echo "准备上传刷机包到天翼云"
sleep 4
username=$(cat $tools/cloudpan189.txt |grep "username"| awk -F "=" '{print $2}'| tr -d '\r' |tr -d '\n')
password=$(cat $tools/cloudpan189.txt |grep "password"| awk -F "=" '{print $2}'| tr -d '\r' |tr -d '\n')

if [[ $username = "" || $password = "" ]]; then
clear
echo 
echo "天翼云账号或密码未配置！"
sleep 5
read -p ""
exit
else
clear
echo 

dir=$(date +%F |sed 's/-/./g' |sed 's/..//')
echo "上传文件到天翼云目录: MIUI官改/$dir"
echo 
cloudpan189-go login -username=$username -password=$password
cloudpan189-go cd /
cloudpan189-go mkdir MIUI官改/$dir
cloudpan189-go upload ./$outputzip1/* MIUI官改/$dir
read -p ""
exit
fi
else
finish_check 
read -p ""
exit
fi
fi

#选择项目内官方包
findzip=$(ls $xiaowan | grep "zip"| tr -d '\r' |tr -d '\n')
countzip=$(echo "$findzip" | wc -l| tr -d '\r' |tr -d '\n')
if [[ $countzip = "1" ]]; then
zip="$findzip"
else
echo "$xiaowan制作失败,因为存在多个官方包" >>$tools/fail.txt
cd $base
start_build
fi

rm -rf $xiaowan/payload_properties.txt >/dev/null 2>&1
rm -rf $xiaowan/payload.bin >/dev/null 2>&1

clear
#显示目前为第几个项目
if [[ $scount = "0" ]]; then
scount=1
else
scount=$(($scount+1))
fi

#更新窗口标题
echo -e "\033]0;Auto_miui"_v"$mversion"  当前项目：$xiaowan"  "第"$scount"/"$all"个"  \007"
echo "解压文件：$zip"
unzip $xiaowan/$zip -d $xiaowan >/dev/null 2>&1

fastboot123=$(cat $tools/dir.txt |grep "fastbootflash"| awk -F "=" '{print $2}'| tr -d '\r' |tr -d '\n')
vabrom=0
if [[ -f $xiaowan/payload_properties.txt ]]; then
vabrom=1
cp -rf tools/patch/sunday/payload_dumper/* $xiaowan/
#bin格式常规解包
cd $xiaowan
touch finish

clear
#payload.bin解包
echo 
echo 提取文件（推荐方案）...
echo ..........................
python payload_dumper.py payload.bin output
rm -rf payload_dumper.py >/dev/null 2>&1
rm -rf payload_properties.txt >/dev/null 2>&1
rm -rf README.md >/dev/null 2>&1
rm -rf update_metadata_pb2.py >/dev/null 2>&1
rm -rf __pycache__ >/dev/null 2>&1
rm -rf backports >/dev/null 2>&1
rm -rf bsdiff4 >/dev/null 2>&1
if [[ ! -f output/system.img ]]; then

#假如解压失败，换脚本对payload.bin解包
cd $base
cp -rf tools/patch/sunday/payload_dumpera/* $xiaowan/
cd $xiaowan
clear
echo 
echo "提取文件（备用方案）..."
echo ..........................
rm -rf output >/dev/null 2>&1
mkdir output >/dev/null 2>&1
python payload_dumper.py payload.bin

if [[ ! -f output/system.img ]]; then
#bin解包失败
echo "$xiaowan制作失败,因为解包payload.bin失败" >>$tools/fail.txt
cd $base
start_build
fi;fi
else
#常规格式解包
cd $base
fi

#bin格式解压
cd $base
if [[ -f $xiaowan/finish ]]; then
if [[ $fastboot123 = "3" ]]; then
fastbootflash
recflash
else
if [[ $fastboot123 = "1" ]]; then
mkdir -p $xiaowan/dynamic_partitions_op_list >/dev/null 2>&1
fastbootflash
else
recflash
fi
fi

clear
mv -f $xiaowan/output/system.img $xiaowan/ >/dev/null 2>&1
mv -f $xiaowan/output/vendor.img $xiaowan/ >/dev/null 2>&1
mv -f $xiaowan/output/product.img $xiaowan/ >/dev/null 2>&1
mv -f $xiaowan/output/system_ext.img $xiaowan/ >/dev/null 2>&1
mv -f $xiaowan/output/odm.img $xiaowan/ >/dev/null 2>&1

cd $xiaowan
ls | grep ".img" | grep -v "boot" | while read i; do
      line=$(echo "$i" | cut -d"." -f1)
	  clear
	  echo 
      echo "正在将文件复制到$line"
      getmeta $line.img $line >/dev/null 2>&1
done
cd $base
#普通格式解包
else

cd $xiaowan
ls | grep "\.new\.dat" | while read i; do
      line=$(echo "$i" | cut -d"." -f1)
	  if [[ $(echo "$i" | grep "\.dat\.br") ]]; then
	  clear
	  echo 
	  echo "将$i转换为$line.new.dat"
	  cd $base
	  tools/patch/sunday/unpackimg/brotli -j -d -o $xiaowan/$line.new.dat $xiaowan/$i
	  rm -f "$xiaowan/$i" >/dev/null 2>&1
	  fi
	   clear
	   echo 
       echo "转换到$line.img"
	   cd $base
	   python tools/patch/sunday/unpackimg/sdat2img.py $xiaowan/$line.transfer.list $xiaowan/$line.new.dat $xiaowan/$line.img >/dev/null 2>&1
	   rm -rf $xiaowan/$line.transfer.list $xiaowan/$line.new.dat >/dev/null 2>&1
	   clear
	   echo 
       echo "正在将文件复制到$line"
	   echo 
       cd $xiaowan
       getmeta $line.img $line >/dev/null 2>&1
done
cd $base

fi

##
echo 
cd $base
rm -rf $xiaowan/*.patch.dat >/dev/null 2>&1
clear
unzip $xiaowan/$zip *.transfer.list -d $xiaowan >/dev/null 2>&1

only1=$(cat $tools/dir.txt |grep "only"| awk -F "=" '{print $2}'| tr -d '\r' |tr -d '\n')
keep123=$(cat $tools/dir.txt |grep "keep"| awk -F "=" '{print $2}'| tr -d '\r' |tr -d '\n')

if [[ $only1 = "1" ]]; then
clear
start_build
fi

if [[ ! -f $xiaowan/finish ]]; then
if [[ ! -f $xiaowan/boot.img ]]; then
clear
echo 
echo "$xiaowan制作失败,因为找不到内核文件,可能是刷机包下载错误" >>$tools/fail.txt
cd $base
start_build
fi;fi

if [[ -f $xiaowan/system/system/build.prop ]]; then
system=system/system
else
if [[ -f $xiaowan/system/build.prop ]]; then
system=system
else

echo 
echo "$xiaowan制作失败,因为解包失败" >>$tools/fail.txt
cd $base
start_build
fi;fi

if [[ -d $xiaowan/$system/app/ThemeManager ]]; then
ThemeManager=$system/app/ThemeManager
ThemeManagerapk=$ThemeManager/ThemeManager.apk
else
if [[ -d $xiaowan/$system/app/MIUIThemeManager ]]; then
ThemeManager=$system/app/MIUIThemeManager
ThemeManagerapk=$ThemeManager/MIUIThemeManager.apk
else
echo "$xiaowan制作失败,因为解包失败" >>$tools/fail.txt
start_build
fi;fi

cp -rf tools/patch/sunday/ThemeManager.apk $xiaowan/$ThemeManagerapk >/dev/null 2>&1

rm -rf $xiaowan/needsetting >/dev/null 2>&1
rm -rf $xiaowan/sdk29 >/dev/null 2>&1
rm -rf $xiaowan/sdk26 >/dev/null 2>&1
rm -rf $xiaowan/sdk28 >/dev/null 2>&1
rm -rf $xiaowan/sdk30 >/dev/null 2>&1
mkdir -p $xiaowan/$system/priv-app/Xiaowan/res/check

api=$(cat $xiaowan/$system/build.prop |grep "ro.build.version.sdk"| awk -F "=" '{print $2}'| tr -d '\r' |tr -d '\n')
ui=$(cat $xiaowan/$system/build.prop |grep "ro.miui.ui.version.name"| awk -F "=" '{print $2}'| tr -d '\r' |tr -d '\n')

if [[ $api -eq 29 || $api -eq 30 || $api -eq 31 ]]; then
model=$(cat $xiaowan/$system/build.prop |grep "ro.product.system.name"| awk -F "=" '{print $2}'| tr -d '\r' |tr -d '\n')
device=$(cat $xiaowan/$system/build.prop |grep "ro.product.system.model"| awk -F "=" '{print $2}'| tr -d '\r' |tr -d '\n')
else
echo 
echo "$xiaowan制作失败,因为不支持你的安卓版本" >>$tools/fail.txt
cd $base
start_build
fi

#取出机型、版本等信息
android=$(cat $xiaowan/$system/build.prop |grep "ro.build.version.release="| awk -F "=" '{print $2}'| tr -d '\r' |tr -d '\n')
version=$(cat $xiaowan/$system/build.prop |grep "ro.build.version.incremental"| awk -F "=" '{print $2}'| tr -d '\r' |tr -d '\n')

if [[ $device = "" ]]; then
device=NULL
fi

if [[ $model = "" ]]; then
model=NULL
fi

if [[ $device = "qssi system image for arm64" ]]; then
device=$(cat $xiaowan/vendor/build.prop |grep "ro.product.vendor.model"| awk -F "=" '{print $2}'| tr -d '\r' |tr -d '\n')
if [[ $device = "qssi system image for arm64" ]]; then
device=$(cat $xiaowan/$system/build.prop |grep "ro.product.system.model"| awk -F "=" '{print $2}'| tr -d '\r' |tr -d '\n')
fi;fi

if [[ $model = "qssi" ]]; then
redeviceskm=1
model=$(cat $xiaowan/vendor/build.prop |grep "ro.product.vendor.name"| awk -F "=" '{print $2}'| tr -d '\r' |tr -d '\n')
fi

cd $base
aa111=$(echo $zip |cut -d"_" -f2| tr -d '\r' |tr -d '\n')
model=$aa111
bb111=$(cat tools/patch/sunday/device/device.txt |grep -w "$aa111"| awk -F "=" '{print $2}'| tr -d '\r' |tr -d '\n')

if [ "$bb111" = "" ] ;then
echo 
else
device=$bb111
fi
#基本设备信息取出完成

##

#脚本定义:存在$xiaowan/finish文件，则为bin格式刷机包，使用面具补丁patch
if [[ -f $xiaowan/finish ]]; then
if [[ ! -f $xiaowan/bootdone ]]; then
cd $base
mv -f $xiaowan/output/boot.img tools/patch/sunday/magiskboot/boot.img
cd tools/patch/sunday/magiskboot
echo 

BOOTIMAGE=boot.img
KEEPVERITY=true
KEEPFORCEENCRYPT=true
RECOVERYMODE=false

chmod +x magiskboot
export KEEPVERITY
export KEEPFORCEENCRYPT
SHA1=`./magiskboot sha1 "$BOOTIMAGE"`
echo "KEEPVERITY=$KEEPVERITY
KEEPFORCEENCRYPT=$KEEPFORCEENCRYPT
RECOVERYMODE=$RECOVERYMODE
SHA1=$SHA1" > config
./magiskboot unpack $BOOTIMAGE
cp -af ramdisk.cpio ramdisk.cpio.orig
./magiskboot compress=xz magisk32 magisk32.xz
./magiskboot compress=xz magisk64 magisk64.xz
./magiskboot cpio ramdisk.cpio \
        "add 0750 init magiskinit" \
        "mkdir 0750 overlay.d" \
        "mkdir 0750 overlay.d/sbin" \
        "add 0644 overlay.d/sbin/magisk32.xz magisk32.xz" \
        "add 0644 overlay.d/sbin/magisk64.xz magisk64.xz" \
        "patch" \
        "backup ramdisk.cpio.orig" \
        "mkdir 000 .backup" \
        "add 000 .backup/.magisk config"
for dt in dtb kernel_dtb extra; do
        [ -f $dt ] && ./magiskboot dtb $dt patch
done
./magiskboot hexpatch kernel \
        736B69705F696E697472616D667300 \
        77616E745F696E697472616D667300
./magiskboot repack $BOOTIMAGE
./magiskboot cleanup
rm -f ramdisk.cpio.orig config boot.img magisk32.xz magisk64.xz
mv new-boot.img boot.img

cd $base
mv -f tools/patch/sunday/magiskboot/boot.img $xiaowan/output/boot.img
touch $xiaowan/bootdone
if [[ ! -f $xiaowan/output/boot.img ]]; then
echo 
echo "$xiaowan制作失败,因为处理boot.img失败" >>$tools/fail.txt
cd $base
start_build
fi;fi;fi

clear
echo 
echo "以下为当前设备信息:"
echo 
echo 项目:$xiaowan
echo 
echo 机型:$device
echo 
echo 代号:$model
echo 
echo 版本号:$version
echo 
echo 安卓版本:$android

sleep 5

#系统精简部分
cp -rf tools/patch/sunday/system/* $xiaowan/$system/ >/dev/null 2>&1
rm -rf $xiaowan/$system/recovery-from-boot.p

sudo cat $tools/rm.txt |while read line; do
sudo find $xiaowan** -type d -name "$line" | xargs rm -rf
done

rm -rf $xiaowan/$system/system.prop >/dev/null 2>&1
cp -rf tools/patch/system.prop $xiaowan/$system/ >/dev/null 2>&1
cd $xiaowan/$system
sed -i '$r system.prop' build.prop
rm -rf system.prop >/dev/null 2>&1
cd $base

echo ro.config.use=true>>$xiaowan/$system/build.prop
echo ro.rom.author=xiaowan>>$xiaowan/$system/build.prop
echo com.advance.miui=true>>$xiaowan/$system/build.prop
echo sys.tool.miui=true>>$xiaowan/$system/build.prop
echo ro.build.number.xw=xw111$device>>$xiaowan/$system/build.prop
sed -i "s/xw111//g" $xiaowan/$system/build.prop

if [[ $android = "11" ]]; then
if [[ ! -f $xiaowan/dynamic_partitions_op_list ]]; then
if [[ ! -d tools/$xiaowan/com.android.art.release ]]; then
if [[ -d $xiaowan/$system/apex/com.android.art.release ]]; then
rm -rf tools/$xiaowan >/dev/null 2>&1
mkdir -p tools/$xiaowan >/dev/null 2>&1
mv $xiaowan/$system/apex/com.android.art.release tools/$xiaowan/
fi;fi;fi;fi

clear
#合并odex部分

if [[ -f superr ]]; then
echo 
rm -rf superr_1 >/dev/null 2>&1
mv -f $xiaowan superr_1 >/dev/null 2>&1
./superr -f deodex -p superr_1
mv -f superr_1 $xiaowan >/dev/null 2>&1
fi

if [[ -d $xiaowan/$system/framework/arm64 ]]; then
#假如合并失败，那么暴力合并
clear
echo 
echo 使用强制合并方案...
for line in $(find ./$xiaowan/ -type d -name "oat"); do
rm -rf $line
done

for line in $(find ./$xiaowan/** |grep "framework"|grep "vdex"); do
rm -rf $line
done

rm -rf ./$xiaowan/system/system/framework/arm64 ./$xiaowan/system/system/framework/arm
rm -rf ./force.sh
echo 
sleep 2

fi

if [[ $android = "11" ]]; then
if [[ ! -f $xiaowan/dynamic_partitions_op_list ]]; then
if [[ -d tools/$xiaowan/com.android.art.release ]]; then
if [[ -d $xiaowan/$system/apex ]]; then
mv tools/$xiaowan/com.android.art.release $xiaowan/$system/apex/ >/dev/null 2>&1
rm -rf tools/$xiaowan >/dev/null 2>&1
fi;fi;fi;fi

mkdir -p $xiaowan/$ThemeManager/lib/arm64
cp -rf $xiaowan/$system/lib64/libjni_resource_drm.so $xiaowan/$ThemeManager/lib/arm64/ >/dev/null 2>&1
rm -rf $xiaowan/auto >/dev/null 2>&1
rm -rf $xiaowan/sdk26 >/dev/null 2>&1
rm -rf $xiaowan/sdk28 >/dev/null 2>&1
rm -rf $xiaowan/sdk29 >/dev/null 2>&1
rm -rf $xiaowan/sdk30 >/dev/null 2>&1
rm -rf $xiaowan/run >/dev/null 2>&1
rm -rf tools/run >/dev/null 2>&1
rm -rf tools/cmd >/dev/null 2>&1

if [[ $model = "" ]]; then
model=xiaowan
fi

rm -rf $xiaowan/$model/sunday >/dev/null 2>&1
mkdir -p $xiaowan/$model
mv $xiaowan/META-INF $xiaowan/$model/
echo $device >$xiaowan/$model/device.txt
rm -rf $xiaowan/$model/needbr >/dev/null 2>&1

if [[ $android = "11" ]]; then
if [[ ! -d $xiaowan/dynamic_partitions_op_list ]]; then
product=true
fi

if [[ ! -f $xiaowan/dynamic_partitions_op_list ]]; then
product=true
fi

fi

if [[ -d $xiaowan/dynamic_partitions_op_list ]]; then
product=true
echo 1 >>$xiaowan/$model/needbr
fi

if [[ -f $xiaowan/dynamic_partitions_op_list ]]; then
product=true
echo 1 >>$xiaowan/$model/needbr
fi

rm -rf $xiaowan/classes >/dev/null 2>&1
rm -rf $xiaowan/$model/build.prop >/dev/null 2>&1
rm -rf $xiaowan/$model/build1.prop >/dev/null 2>&1

cp -rf $xiaowan/$system/build.prop $xiaowan/$model/ >/dev/null 2>&1
cp -rf $xiaowan/vendor/build.prop $xiaowan/$model/build1.prop >/dev/null 2>&1

cd $base

clear
echo 
java -jar tools/patch/sunday/apktool.jar if "$xiaowan/$system/framework/framework-ext-res/framework-ext-res.apk"
java -jar tools/patch/sunday/apktool.jar if "$xiaowan/$system/framework/framework-res.apk"
java -jar tools/patch/sunday/apktool.jar if "$xiaowan/$system/app/miuisystem/miuisystem.apk"
java -jar tools/patch/sunday/apktool.jar if "$xiaowan/$system/app/miui/miui.apk"

clear
echo 
mkdir -p $xiaowan/$system/priv-app/Xiaowan/check_Xiaowan >/dev/null 2>&1
mkdir -p $xiaowan/$system/priv-app/Xiaowan/res/lite >/dev/null 2>&1
mkdir -p $xiaowan/$system/priv-app/Xiaowan/res/true >/dev/null 2>&1
mkdir -p $xiaowan/$system/priv-app/Xiaowan/Xiaowan >/dev/null 2>&1
mkdir -p $xiaowan/$system/priv-app/Xiaowan/tools/true >/dev/null 2>&1

mkdir -p $xiaowan/temp >/dev/null 2>&1

#移除boot.img内核文件的avb加密系列操作
if [[ -f $xiaowan/boot.img ]]; then
rm -rf tools/patch/sunday/bootimg/ramdisk >/dev/null 2>&1
rm -rf tools/patch/sunday/bootimg/split_img >/dev/null 2>&1
rm -rf tools/patch/sunday/bootimg/boot.img >/dev/null 2>&1
mv $xiaowan/boot.img tools/patch/sunday/bootimg/
cd tools/patch/sunday/bootimg
./cleanup.sh
./unpackimg.sh
cd $base
mv tools/patch/sunday/bootimg/boot.img $xiaowan/
fi

if [[ -f $xiaowan/boot.img ]]; then
sed -i 's/\x2C\x61\x76\x62/\x00\x00\x00\x00/g' $xiaowan/boot.img
fi

if [[ -f $xiaowan/output/dtbo.img ]]; then
sed -i 's/\x2C\x61\x76\x62/\x00\x00\x00\x00/g' $xiaowan/output/dtbo.img
fi

if [[ -f $xiaowan/firmware-update/dtbo.img ]]; then
sed -i 's/\x2C\x61\x76\x62/\x00\x00\x00\x00/g' $xiaowan/firmware-update/dtbo.img
fi

if [[ -f $xiaowan/output/vbmeta_system.img ]]; then
cp -rf tools/patch/sunday/vbmeta.img $xiaowan/output/vbmeta_system.img >/dev/null 2>&1
fi

if [[ -f $xiaowan/output/vbmeta_vendor.img ]]; then
cp -rf tools/patch/sunday/vbmeta.img $xiaowan/output/vbmeta_vendor.img >/dev/null 2>&1
fi

if [[ -f $xiaowan/output/vbmeta.img ]]; then
cp -rf tools/patch/sunday/vbmeta.img $xiaowan/output/vbmeta.img >/dev/null 2>&1
fi

if [[ -f $xiaowan/firmware-update/vbmeta_system.img ]]; then
cp -rf tools/patch/sunday/vbmeta.img $xiaowan/firmware-update/vbmeta_system.img >/dev/null 2>&1
fi

if [[ -f $xiaowan/firmware-update/vbmeta.img ]]; then
cp -rf tools/patch/sunday/vbmeta.img $xiaowan/firmware-update/vbmeta.img >/dev/null 2>&1
fi

#修改分区表来移除加密操作
cd $xiaowan
if [ -d "vendor/etc" ]; then
for line in $(grep "<fs_mgr_flags>" vendor/etc/*.* -rn -l ); do
chmod 0777 $line
sed -i 's/ro\,noatime/ro/g' $line
sed -i 's/=vbmeta_system//g' $line

for keep in ${keeps}; do
if [[ $model = $keep ]]; then
echo 
else
sed -i 's/forceencrypt/encryptable/g' $line
sed -i 's/fileencryption=ice/encryptable=ice/g' $line
fi
done

sed -i 's/\_keys\=\/avb\/q\-gsi\.avbpubkey\:\/avb\/r-gsi\.avbpubkey\:\/avb\/s\-gsi\.avbpubkey//g' $line
sed -i 's/,avb_keys=\/avb\/q-gsi.avbpubkey:\/avb\/r-gsi.avbpubkey:\/avb\/s-gsi.avbpubkey//g' $line
sed -i 's/,avb//g' $line
done
fi

cd $base

#刷机脚本的自定义操作
cd $xiaowan/$model

###
aa='ui_print("'
bb='");'
cc='AcmeTeam_Auto_Make_Rom'
dd='Group:312451233'
ee='*************************'
type='develop'
release='dev'

t=$(date +%Y-%m-%d\ )
a=`cat build.prop|grep "ro.build.version.incremental"` 
c=`cat build.prop|grep "ro.build.version.release"` 

andriod111=`echo $c | awk -F "=" '{print $2}'`
andriod111=`echo $andriod111 | awk -F "r" '{print $1}'`

model111=$(cat device.txt)
version111=`echo $a | awk -F "=" '{print $2}'`

if [ `echo $version111|grep ^V` ];then
type='stable'
release='sta'
fi

model111="$aa Model：$model111 $bb"
time="$aa Make：$t $bb"
version111="$aa Version: $version111 $bb"
andriod111="$aa Andriod：$andriod111 $bb"
id="$aa By: $cc $bb"
dd="$aa $dd $bb"
ee="$aa$ee$bb"
type="$aa Type: $type $bb"
null="$aa $bb"

echo $null>sunday1
echo $ee>>sunday1
echo $null>>sunday1
echo $time>>sunday1
echo $model111>>sunday1
echo $version111>>sunday1
echo $andriod111>>sunday1
echo $type>>sunday1
echo $id>>sunday1
echo $dd>>sunday1
echo $null>>sunday1
echo $ee>>sunday1
echo >>sunday1

if [ -f "META-INF/com/google/android/updater-script" ];then
sed -i "/ro.build.date.utc/d" META-INF/com/google/android/updater-script

if [ ! -f "needbr" ];then
sed -i 's/.br//g' META-INF/com/google/android/updater-script
rm -rf needbr
else
echo ""
fi

sed -i '3 i\xiaowan' META-INF/com/google/android/updater-script
sed -i '/xiaowan/r sunday1' META-INF/com/google/android/updater-script
sed -i '/xiaowan/d' META-INF/com/google/android/updater-script
fi

rm -rf sunday1
rm -rf build.prop
rm -rf build1.prop
cd ..

currentTimeStamp=`date "+%Y-%m-%d %H:%M:%S"`  

echo ro.build.time.xiaowan=$currentTimeStamp >date
echo ro.build.date.xiaowan=$t >>date
echo ro.miui.cust_variant=cn >>date
echo ro.miui.region=CN >>date
echo com.xiaowan.sunday=true >>date
echo #by xiaowan >>date
#####

rm -rf sunday >/dev/null 2>&1
cd ..
sed -i '$r date' $xiaowan/$system/build.prop
rm -rf date >/dev/null 2>&1

cd $base
if [[ $android = "11" ]]; then
if [[ -f $xiaowan/dynamic_partitions_op_list ]]; then
if [[ ! -f $xiaowan/finish ]]; then
cp -rf tools/patch/sunday/apk/com/android/server/update-binary $xiaowan/$model/META-INF/com/google/android/update-binary >/dev/null 2>&1
fi;fi;fi

#复制面具文件并写入刷机脚本
cd $xiaowan/$model

filename="magisk"
cat>"${filename}"<<EOF

package_extract_file("META-INF/com/google/magisk/magisk.zip", "/tmp/magisk.zip");
package_extract_file("META-INF/com/google/magisk/magisk.sh", "/tmp/magisk.sh");
run_program("/sbin/sh", "/tmp/magisk.sh", "dummy", "1", "/tmp/magisk.sh");

EOF

sed -i '$r magisk' META-INF/com/google/android/updater-script
rm -rf magisk >/dev/null 2>&1
cd $base
mkdir -p $xiaowan/$model/META-INF/com/google/magisk
cp -rf tools/patch/sunday/root/magisk.zip $xiaowan/$model/META-INF/com/google/magisk/magisk.zip >/dev/null 2>&1

filename="$xiaowan/$model/META-INF/com/google/magisk/magisk.sh"
cat>"${filename}"<<EOF
#!/sbin/sh
mkdir -p /tmp/magisk/
cd /tmp/magisk/
cp /tmp/magisk.zip /tmp/magisk/magisk.zip
unzip /tmp/magisk/magisk.zip
/sbin/sh /tmp/magisk/META-INF/com/google/android/update-binary dummy 1 /tmp/magisk/magisk.zip
EOF

mkdir -p $xiaowan/temp/miuisystemsdk@boot
mkdir -p $xiaowan/temp/DownloadProvider
mkdir -p $xiaowan/temp/services
mkdir -p $xiaowan/temp/miuisystem

mv $xiaowan/$system/framework/miuisystemsdk@boot.jar $xiaowan/temp/
mv $xiaowan/$system/priv-app/DownloadProvider/DownloadProvider.apk $xiaowan/temp/
mv $xiaowan/$system/framework/services.jar $xiaowan/temp/
mv $xiaowan/$system/app/miuisystem/miuisystem.apk $xiaowan/temp/

unzip $xiaowan/temp/miuisystemsdk@boot.jar class* -d $xiaowan/temp/miuisystemsdk@boot >/dev/null 2>&1
unzip $xiaowan/temp/DownloadProvider.apk class* -d $xiaowan/temp/DownloadProvider >/dev/null 2>&1
unzip $xiaowan/temp/services.jar class* -d $xiaowan/temp/services >/dev/null 2>&1
unzip $xiaowan/temp/miuisystem.apk class* -d $xiaowan/temp/miuisystem >/dev/null 2>&1

clear
echo 
echo  反编译：services/classes.dex
java -jar tools/patch/sunday/baksmali.jar disassemble $xiaowan/temp/services/classes.dex -o $xiaowan/temp/services
echo 
echo  反编译：DownloadProvider/classes.dex
java -jar tools/patch/sunday/baksmali.jar disassemble $xiaowan/temp/DownloadProvider/classes.dex -o $xiaowan/temp/DownloadProvider
echo 
echo  反编译：services/classes2.dex
java -jar tools/patch/sunday/baksmali.jar disassemble $xiaowan/temp/services/classes2.dex -o $xiaowan/temp/services2
echo 
echo  反编译：miuisystemsdk@boot/classes.dex
java -jar tools/patch/sunday/baksmali.jar disassemble $xiaowan/temp/miuisystemsdk@boot/classes.dex -o $xiaowan/temp/miuisystemsdk@boot
echo 
echo  反编译：miuisystem/classes.dex
java -jar tools/patch/sunday/baksmali.jar disassemble $xiaowan/temp/miuisystem/classes.dex -o $xiaowan/temp/miuisystem
echo 

rm -rf $xiaowan/temp/DownloadProvider/classes.dex >/dev/null 2>&1
rm -rf $xiaowan/temp/miuisystem/classes.dex >/dev/null 2>&1
rm -rf $xiaowan/temp/services/classes.dex >/dev/null 2>&1
rm -rf $xiaowan/temp/services/classes2.dex >/dev/null 2>&1
rm -rf $xiaowan/temp/miuisystemsdk@boot/classes.dex >/dev/null 2>&1

if [[ $api = "29" ]]; then
mkdir -p $xiaowan/sdk29
cp -rf tools/patch/patchallq/system/* $xiaowan/$system >/dev/null 2>&1
cp -rf tools/patch/patchallq/smali/MiuiGlobalActions\$1.smali $xiaowan/temp/services/com/android/server/policy/MiuiGlobalActions\$1.smali >/dev/null 2>&1
fi

if [[ $api = "30" ]]; then
mkdir -p $xiaowan/sdk29
mkdir -p $xiaowan/sdk30
fi

cd $base

#自动修改各apk/jar内smali文件开始
cp -rf tools/patch/sunday/bootimg/android_win_tools/auto/* $xiaowan >/dev/null 2>&1
cd $xiaowan
rm -rf fails
rm -rf have
rm -rf nothing
touch fails

checkf=$(find temp/servi*/ -type f -name '*.smali' 2>/dev/null | xargs grep -rl '.method private checkSystemSelfProtection(Z)V' | sed 's/^\.\///' | sort)
sed -i '/^.method private checkSystemSelfProtection(Z)V/,/^.end method/{//!d}' $checkf
sed -i -e '/^.method private checkSystemSelfProtection(Z)V/a\    .locals 1\n\n    return-void' $checkf

if [ -d "sdk30" ]; then
if [ -f "temp/services2/com/miui/server/SecurityManagerService.smali" ]; then
sed -i '/^.method private static compareSignatures(\[Landroid\//,/^.end method/{//!d}' temp/services2/com/miui/server/SecurityManagerService.smali
sed -i '/^.method private enforceAppSignature(\[Landroid\//,/^.end method/{//!d}' temp/services2/com/miui/server/SecurityManagerService.smali
sed -i '/^.method private enforcePlatformSignature(\[Landroid\//,/^.end method/{//!d}' temp/services2/com/miui/server/SecurityManagerService.smali
sed -i '/method private static compareSignatures(\[Landroid\//r auto/return_false_0' temp/services2/com/miui/server/SecurityManagerService.smali
sed -i '/method private enforceAppSignature(\[Landroid\//r auto/return-void' temp/services2/com/miui/server/SecurityManagerService.smali
sed -i '/method private enforcePlatformSignature(\[Landroid\//r auto/return-void' temp/services2/com/miui/server/SecurityManagerService.smali
fi
fi

if [ -d "sdk29" ]; then
sed -i '/^.method public static isLegal(Landroid\/content\/Context;Ljava\/io\/File;Ljava\/io\/File;)Lmiui\/drm\/DrmManager$DrmResult/,/^.end method/{//!d}' temp/miuisystemsdk@boot/miui/drm/DrmManager.smali
sed -i '/method public static isLegal(Landroid\/content\/Context;Ljava\/io\/File;Ljava\/io\/File;)Lmiui\/drm\/DrmManager$DrmResult/r auto/DrmManager_1' temp/miuisystemsdk@boot/miui/drm/DrmManager.smali
sed -i '/^.method public static isLegal(Landroid\/content\/Context;Ljava\/lang\/String;Ljava\/io\/File;)Lmiui\/drm\/DrmManager$DrmResult/,/^.end method/{//!d}' temp/miuisystemsdk@boot/miui/drm/DrmManager.smali
sed -i '/method public static isLegal(Landroid\/content\/Context;Ljava\/lang\/String;Ljava\/io\/File;)Lmiui\/drm\/DrmManager$DrmResult/r auto/DrmManager_2' temp/miuisystemsdk@boot/miui/drm/DrmManager.smali
sed -i '/^.method private static isLegal(Landroid\/content\/Context;Ljava\/lang\/String;Lmiui\/drm\/DrmManager$RightObject;)Lmiui\/drm\/DrmManager$DrmResult/,/^.end method/{//!d}' temp/miuisystemsdk@boot/miui/drm/DrmManager.smali
sed -i '/method private static isLegal(Landroid\/content\/Context;Ljava\/lang\/String;Lmiui\/drm\/DrmManager$RightObject;)Lmiui\/drm\/DrmManager$DrmResult/r auto/DrmManager_3' temp/miuisystemsdk@boot/miui/drm/DrmManager.smali
sed -i '/^.method public static isPermanentRights/,/^.end method/{//!d}' temp/miuisystemsdk@boot/miui/drm/DrmManager.smali
sed -i '/method public static isPermanentRights/r auto/return_true_4' temp/miuisystemsdk@boot/miui/drm/DrmManager.smali
sed -i '/^.method private static isPermanentRights/,/^.end method/{//!d}' temp/miuisystemsdk@boot/miui/drm/DrmManager.smali
sed -i '/method private static isPermanentRights/r auto/return_true_4' temp/miuisystemsdk@boot/miui/drm/DrmManager.smali
sed -i '/^.method private static isRightsFileLegal/,/^.end method/{//!d}' temp/miuisystemsdk@boot/miui/drm/DrmManager.smali
sed -i '/method private static isRightsFileLegal/r auto/return_true_4' temp/miuisystemsdk@boot/miui/drm/DrmManager.smali
sed -i '/^.method public static isSupportAd(Landroid\/content\/Context;)/,/^.end method/{//!d}' temp/miuisystemsdk@boot/miui/drm/DrmManager.smali
sed -i '/method public static isSupportAd(Landroid\/content\/Context;)/r auto/return_false_4' temp/miuisystemsdk@boot/miui/drm/DrmManager.smali
sed -i '/^.method public static isSupportAd(Ljava\/io\/File;)/,/^.end method/{//!d}' temp/miuisystemsdk@boot/miui/drm/DrmManager.smali
sed -i '/method public static isSupportAd(Ljava\/io\/File;)/r auto/return_false_4' temp/miuisystemsdk@boot/miui/drm/DrmManager.smali
fi

if [ -d "sdk29" ]; then
sed -i '/^.method public static getImei/,/^.end method/{//!d}' temp/DownloadProvider/com/android/providers/downloads/util/Util.smali
sed -i '/method public static getImei/r auto/kill' temp/DownloadProvider/com/android/providers/downloads/util/Util.smali
if [ -f "temp/services/com/android/server/pm/PackageManagerServiceUtils.smali" ]; then
sed -i '/^.method public static compareSignatures/,/^.end method/{//!d}' temp/services/com/android/server/pm/PackageManagerServiceUtils.smali
sed -i '/method public static compareSignatures/r auto/return_false_4' temp/services/com/android/server/pm/PackageManagerServiceUtils.smali
else
sed -i '/^.method public static compareSignatures/,/^.end method/{//!d}' temp/services2/com/android/server/pm/PackageManagerServiceUtils.smali
sed -i '/method public static compareSignatures/r auto/return_false_4' temp/services2/com/android/server/pm/PackageManagerServiceUtils.smali
fi
fi

if [ -d "sdk29" ]; then
sed -i '/^.method private onPostNotification()V/,/^.end method/{//!d}' temp/services2/com/android/server/wm/AlertWindowNotification.smali
else 
sed -i '/^.method private onPostNotification()V/,/^.end method/{//!d}' temp/services/com/android/server/wm/AlertWindowNotification.smali
fi

if [ -d "sdk29" ]; then
sed -i '/^.method public run()V/,/^.end method/{//!d}' 'temp/services2/com/miui/server/SecurityManagerService$1.smali'
else 
sed -i '/^.method public run()V/,/^.end method/{//!d}' 'temp/services/com/miui/server/SecurityManagerService$1.smali'
fi

if [ -d "sdk29" ]; then
sed -i '/^.method private checkAppSignature/,/^.end method/{//!d}' temp/services2/com/miui/server/SecurityManagerService.smali
else 
sed -i '/^.method private checkAppSignature/,/^.end method/{//!d}' temp/services/com/miui/server/SecurityManagerService.smali
fi

if [ -d "sdk29" ]; then
sed -i '/^.method private checkSysAppCrack()Z/,/^.end method/{//!d}' temp/services2/com/miui/server/SecurityManagerService.smali
else 
sed -i '/^.method private checkSysAppCrack()Z/,/^.end method/{//!d}' temp/services/com/miui/server/SecurityManagerService.smali
fi

if [ -d "sdk29" ]; then
sed -i '/^.method private checkSystemSelfProtection(Z)V/,/^.end method/{//!d}' temp/services2/com/miui/server/SecurityManagerService.smali
else 
sed -i '/^.method private checkSystemSelfProtection(Z)V/,/^.end method/{//!d}' temp/services/com/miui/server/SecurityManagerService.smali
fi

if [ -d "sdk29" ]; then
sed -i '/method private onPostNotification()V/r auto/return-void' temp/services2/com/android/server/wm/AlertWindowNotification.smali
else 
sed -i '/method private onPostNotification()V/r auto/return-void' temp/services/com/android/server/wm/AlertWindowNotification.smali
fi

if [ -d "sdk29" ]; then
sed -i '/method public run()V/r auto/return-void' 'temp/services2/com/miui/server/SecurityManagerService$1.smali'
else 
sed -i '/method public run()V/r auto/return-void' 'temp/services/com/miui/server/SecurityManagerService$1.smali'
fi

if [ -d "sdk29" ]; then
sed -i '/method private checkAppSignature/r auto/return_true_4' temp/services2/com/miui/server/SecurityManagerService.smali
else 
sed -i '/method private checkAppSignature/r auto/return_true_4' temp/services/com/miui/server/SecurityManagerService.smali
fi

if [ -d "sdk29" ]; then
sed -i '/method private checkSysAppCrack()Z/r auto/return_true_4' temp/services2/com/miui/server/SecurityManagerService.smali
else 
sed -i '/method private checkSysAppCrack()Z/r auto/return_true_4' temp/services/com/miui/server/SecurityManagerService.smali
fi

if [ -d "sdk29" ]; then
sed -i '/method private checkSystemSelfProtection(Z)V/r auto/return-void' temp/services2/com/miui/server/SecurityManagerService.smali
else 
sed -i '/method private checkSystemSelfProtection(Z)V/r auto/return-void' temp/services/com/miui/server/SecurityManagerService.smali
fi

# start
# ThemeManager=$(grep ".method public isAuthorizedResource()Z" temp/ThemeManager/com/android/ -rn -l )

if [ -f "temp/services/com/android/server/policy/PhoneWindowManager.smali" ]; then
sed -i '/^.method private getScreenshotChordLongPressDelay/,/^.end method/{//!d}' temp/services/com/android/server/policy/PhoneWindowManager.smali
sed -i '/method private getScreenshotChordLongPressDelay/r auto/return-wide v0' temp/services/com/android/server/policy/PhoneWindowManager.smali
else
sed -i '/^.method private getScreenshotChordLongPressDelay/,/^.end method/{//!d}' temp/services2/com/android/server/policy/PhoneWindowManager.smali
sed -i '/method private getScreenshotChordLongPressDelay/r auto/return-wide v0' temp/services2/com/android/server/policy/PhoneWindowManager.smali
fi

if [ -d "sdk29" ]; then
if [ -f "temp/services/com/android/server/pm/PackageManagerService.smali" ]; then
sed -i '/^.method private static checkDowngrade/,/^.end method/{//!d}' temp/services/com/android/server/pm/PackageManagerService.smali
sed -i '/method private static checkDowngrade/r auto/return-void' temp/services/com/android/server/pm/PackageManagerService.smali
else
sed -i '/^.method private static checkDowngrade/,/^.end method/{//!d}' temp/services2/com/android/server/pm/PackageManagerService.smali
sed -i '/method private static checkDowngrade/r auto/return-void' temp/services2/com/android/server/pm/PackageManagerService.smali
fi
fi
sed -i '/^.method public static isLegal(Landroid\/content\/Context;Ljava\/io\/File;Ljava\/io\/File;)Lmiui\/drm\/DrmManager$DrmResult/,/^.end method/{//!d}' temp/miuisystem/miui/drm/DrmManager.smali
sed -i '/method public static isLegal(Landroid\/content\/Context;Ljava\/io\/File;Ljava\/io\/File;)Lmiui\/drm\/DrmManager$DrmResult/r auto/DrmManager_1' temp/miuisystem/miui/drm/DrmManager.smali
sed -i '/^.method public static isLegal(Landroid\/content\/Context;Ljava\/lang\/String;Ljava\/io\/File;)Lmiui\/drm\/DrmManager$DrmResult/,/^.end method/{//!d}' temp/miuisystem/miui/drm/DrmManager.smali
sed -i '/method public static isLegal(Landroid\/content\/Context;Ljava\/lang\/String;Ljava\/io\/File;)Lmiui\/drm\/DrmManager$DrmResult/r auto/DrmManager_2' temp/miuisystem/miui/drm/DrmManager.smali
sed -i '/^.method private static isLegal(Landroid\/content\/Context;Ljava\/lang\/String;Lmiui\/drm\/DrmManager$RightObject;)Lmiui\/drm\/DrmManager$DrmResult/,/^.end method/{//!d}' temp/miuisystem/miui/drm/DrmManager.smali
sed -i '/method private static isLegal(Landroid\/content\/Context;Ljava\/lang\/String;Lmiui\/drm\/DrmManager$RightObject;)Lmiui\/drm\/DrmManager$DrmResult/r auto/DrmManager_3' temp/miuisystem/miui/drm/DrmManager.smali
sed -i '/^.method public static isPermanentRights/,/^.end method/{//!d}' temp/miuisystem/miui/drm/DrmManager.smali
sed -i '/method public static isPermanentRights/r auto/return_true_4' temp/miuisystem/miui/drm/DrmManager.smali
sed -i '/^.method private static isPermanentRights/,/^.end method/{//!d}' temp/miuisystem/miui/drm/DrmManager.smali
sed -i '/method private static isPermanentRights/r auto/return_true_4' temp/miuisystem/miui/drm/DrmManager.smali
sed -i '/^.method private static isRightsFileLegal/,/^.end method/{//!d}' temp/miuisystem/miui/drm/DrmManager.smali
sed -i '/method private static isRightsFileLegal/r auto/return_true_4' temp/miuisystem/miui/drm/DrmManager.smali
sed -i '/^.method public static isSupportAd(Landroid\/content\/Context;)/,/^.end method/{//!d}' temp/miuisystem/miui/drm/DrmManager.smali
sed -i '/method public static isSupportAd(Landroid\/content\/Context;)/r auto/return_false_4' temp/miuisystem/miui/drm/DrmManager.smali
sed -i '/^.method public static isSupportAd(Ljava\/io\/File;)/,/^.end method/{//!d}' temp/miuisystem/miui/drm/DrmManager.smali
sed -i '/method public static isSupportAd(Ljava\/io\/File;)/r auto/return_false_4' temp/miuisystem/miui/drm/DrmManager.smali

rm -rf sdk29
rm -rf sdk26
rm -rf sdk28
rm -rf sdk30
rm -rf have
rm -rf nothing

rm -rf tempx >/dev/null 2>&1
rm -rf run >/dev/null 2>&1
rm -rf auto >/dev/null 2>&1
rm -rf V10 >/dev/null 2>&1
rm -rf V11 >/dev/null 2>&1
rm -rf V12 >/dev/null 2>&1
#自动修改各apk/jar内smali文件结束

cd $base

mkdir -p $xiaowan/temp/classes/miuisystemsdk@boot
mkdir -p $xiaowan/temp/classes/DownloadProvider
mkdir -p $xiaowan/temp/classes/services
mkdir -p $xiaowan/temp/classes/miuisystem

clear
echo 
echo  回编译：DownloadProvider/classes.dex
java -jar tools/patch/sunday/smali.jar assemble $xiaowan/temp/DownloadProvider -o $xiaowan/temp/classes/DownloadProvider/classes.dex
echo 
echo  回编译：services/classes2.dex
java -jar tools/patch/sunday/smali.jar assemble $xiaowan/temp/services2 -o $xiaowan/temp/classes/services/classes2.dex
echo 
echo  回编译：miuisystem/classes.dex
java -jar tools/patch/sunday/smali.jar assemble $xiaowan/temp/miuisystem -o $xiaowan/temp/classes/miuisystem/classes.dex
echo 
echo  回编译：miuisystemsdk@boot/classes.dex
java -jar tools/patch/sunday/smali.jar assemble $xiaowan/temp/miuisystemsdk@boot -o $xiaowan/temp/classes/miuisystemsdk@boot/classes.dex
echo 
echo  回编译：services/classes.dex
java -jar tools/patch/sunday/smali.jar assemble $xiaowan/temp/services -o $xiaowan/temp/classes/services/classes.dex

rm -rf $xiaowan/$system/app/Brevent >/dev/null 2>&1

if [[ -f $xiaowan/temp/classes/DownloadProvider/classes.dex && -f $xiaowan/temp/classes/services/classes2.dex && -f $xiaowan/temp/classes/miuisystem/classes.dex && -f $xiaowan/temp/classes/miuisystemsdk@boot/classes.dex && -f $xiaowan/temp/classes/services/classes.dex ]]; then
clear
echo 
else
clear
echo "$xiaowan制作失败,因为回编译部分系统文件出现了问题" >>$tools/fail.txt
cd $base
start_build
fi

#把修改的dex压缩进官方apk/jar
7z a $xiaowan/temp/miuisystemsdk@boot.jar ./$xiaowan/temp/classes/miuisystemsdk@boot/* >/dev/null 2>&1
7z a $xiaowan/temp/DownloadProvider.apk ./$xiaowan/temp/classes/DownloadProvider/* >/dev/null 2>&1
7z a $xiaowan/temp/services.jar ./$xiaowan/temp/classes/services/* >/dev/null 2>&1
7z a $xiaowan/temp/miuisystem.apk ./$xiaowan/temp/classes/miuisystem/* >/dev/null 2>&1

#进行zipalign操作，防止卡米
tools/patch/sunday/unpackimg/zipalign -v -p 4 $xiaowan/temp/miuisystemsdk@boot.jar $xiaowan/$system/framework/miuisystemsdk@boot.jar >/dev/null 2>&1
tools/patch/sunday/unpackimg/zipalign -v -p 4 $xiaowan/temp/DownloadProvider.apk $xiaowan/$system/priv-app/DownloadProvider/DownloadProvider.apk >/dev/null 2>&1
tools/patch/sunday/unpackimg/zipalign -v -p 4 $xiaowan/temp/services.jar $xiaowan/$system/framework/services.jar >/dev/null 2>&1
tools/patch/sunday/unpackimg/zipalign -v -p 4 $xiaowan/temp/miuisystem.apk $xiaowan/$system/app/miuisystem/miuisystem.apk >/dev/null 2>&1
tools/patch/sunday/unpackimg/zipalign -v -p 4 $xiaowan/$ThemeManagerapk $xiaowan/$ThemeManager/1.apk >/dev/null 2>&1
rm -rf $xiaowan/$ThemeManagerapk >/dev/null 2>&1
mv $xiaowan/$ThemeManager/1.apk $xiaowan/$ThemeManagerapk >/dev/null 2>&1

#判断文件是否正常移动成功

if [[ -f $xiaowan/$system/framework/miuisystemsdk@boot.jar && -f $xiaowan/$ThemeManagerapk && -f $xiaowan/$system/priv-app/DownloadProvider/DownloadProvider.apk && -f $xiaowan/$system/framework/services.jar && -f $xiaowan/$system/app/miuisystem/miuisystem.apk ]]; then
clear
sleep 2
else
clear
echo "$xiaowan制作失败,因为移动文件到项目内失败" >>$tools/fail.txt
cd $base
start_build
fi

#添加com.android.settings
if [[ -f $xiaowan/$system/media/theme/default/com.android.settings ]]; then
rm -rf $xiaowan/$system/media/theme/default/com.android.settings
cp $tools/sunday/com.android.settings $xiaowan/$system/media/theme/default
else
cp $tools/sunday/com.android.settings $xiaowan/$system/media/theme/default
sed -i 's/\/system\/media\/theme\/default\/virtuallockscreen u:object_r:system_file:s0/a\/system\/media\/theme\/default\/com.android.settings u:object_r:system_file:s0/' $xiaowan/00_project_files/file_contexts3-system
sed -i 's/system\/media\/theme\/default\/virtuallockscreen 0 0 0644/asystem\/media\/theme\/default\/com.android.settings 0 0 0644/' $xiaowan/00_project_files/fs_config-system 
sed -i 's/asystem/system/' $xiaowan/00_project_files/fs_config-system
sed -i 's/a\/system/system/g' $xiaowan/00_project_files/file_contexts3-system
fi

#清理目录文件
rm -rf $xiaowan/temp/classes >/dev/null 2>&1
rm -rf $xiaowan/classes >/dev/null 2>&1

cd $base

if [[ $android = "11" ]]; then
and11=false
fi

if [[ -f $xiaowan/dynamic_partitions_op_list ]]; then
and11=true
fi

## 打包开始
#移动文件到Linux目录进行打包操作
cd $base
clear
echo 
echo 准备打包...
rm -rf Linux >/dev/null 2>&1
mkdir -p Linux/prebuilt/META-INF >/dev/null 2>&1
mkdir -p Linux/file_context >/dev/null 2>&1
unzip $xiaowan/$zip odm* -d Linux/prebuilt >/dev/null 2>&1

if [[ $keep123 = "1" ]]; then
mv $xiaowan/$zip $officalzip1/done/
fi

mkdir -p Linux/file_context >/dev/null 2>&1
cp -rf $xiaowan/finish Linux/finish >/dev/null 2>&1
mv $xiaowan/$model/* Linux/prebuilt/
mv $xiaowan/system Linux/ >/dev/null 2>&1
mv $xiaowan/vendor Linux/ >/dev/null 2>&1
mv $xiaowan/product Linux/ >/dev/null 2>&1
mv $xiaowan/system_ext Linux/ >/dev/null 2>&1
cp -rf $xiaowan/00_project_files/* Linux/file_context/
rm -rf Linux/prebuilt/META-INF/needbr >/dev/null 2>&1
rm -rf Linux/prebuilt/META-INF/vendor >/dev/null 2>&1
rm -rf Linux/prebuilt/needbr >/dev/null 2>&1
rm -rf Linux/prebuilt/vendor >/dev/null 2>&1
mv $xiaowan/boot.img Linux/prebuilt/ >/dev/null 2>&1
mv $xiaowan/exaid.img Linux/prebuilt/ >/dev/null 2>&1
mv $xiaowan/firmware-update Linux/prebuilt/ >/dev/null 2>&1

### 计算各img的字节大小并写入

cd $base
cp -rf tools/patch/sunday/prebuilt/* Linux/

cd $xiaowan
rm -rf size >/dev/null 2>&1
mkdir size >/dev/null 2>&1

ls *.img | while read ii; do
    line=$(echo "$ii" | cut -d"." -f1)
    echo $(wc -c $ii | gawk '{ print $1 }') >size/$line
done

a=0
if [[ -e dynamic_partitions_op_list ]]; then
a=104857600
fi

if [[ -f size/system ]]; then
var=$(cat ./size/system)
systemr=$((a+var))
fi

if [[ -f size/vendor ]]; then
var1=$(cat ./size/vendor)
vendorr=$((a+var1))
fi

if [[ -f size/product ]]; then
var2=$(cat ./size/product)
productr=$((a+var2))
fi

if [[ -f size/system_ext ]]; then
var3=$(cat ./size/system_ext)
system_extr=$((a+var3))
fi

if [[ -f size/odm ]]; then
var3od=$(cat ./size/odm)
fi

if [[ $a = 104857600 ]]; then
#普通动态分区处理
sed -i 's/'$var'/'$systemr'/g' dynamic_partitions_op_list
sed -i 's/'$var1'/'$vendorr'/g' dynamic_partitions_op_list
sed -i 's/'$var2'/'$productr'/g' dynamic_partitions_op_list
sed -i 's/'$var3'/'$system_extr'/g' dynamic_partitions_op_list

#卡刷格式的虚拟ab分区处理
sed -i 's/system_extsize/'$system_extr'/g' dynamic_partitions_op_list
sed -i 's/systemsize/'$systemr'/g' dynamic_partitions_op_list
sed -i 's/odmsize/'$var3od'/g' dynamic_partitions_op_list
sed -i 's/productsize/'$productr'/g' dynamic_partitions_op_list
sed -i 's/vendorsize/'$vendorr'/g' dynamic_partitions_op_list
fi

cd $base
mv $xiaowan/dynamic_partitions_op_list Linux/prebuilt/ >/dev/null 2>&1
cp -rf tools/patch/sunday/unpackimg/brotli Linux/bin/ >/dev/null 2>&1
cp -rf tools/patch/sunday/prebuilt/build.sh Linux/ >/dev/null 2>&1
cd Linux
clear
echo 

for keep in ${keeps}; do
if [[ $model = $keep ]]; then
touch keep
fi
done

if [[ $vabrom = "1" ]]; then
if [[ $fastboot123 = "3" ]]; then
cd $base
touch Linux/vabrecfast
tools/patch/sunday/prebuilt/bin/img2simg $xiaowan/odm.img Linux/prebuilt/odm.img >/dev/null 2>&1
cd Linux

else
if [[ $fastboot123 = "1" ]]; then
echo 
else
cd $base
touch Linux/vabrec
tools/patch/sunday/prebuilt/bin/img2simg $xiaowan/odm.img Linux/prebuilt/odm.img >/dev/null 2>&1
cd Linux
fi;fi;fi

buildrom
cd $base

rm -rf Linux/prebuilt/device.txt >/dev/null 2>&1

################################
#判断是否成功打包
succed=0
#bin格式，打包为img或者br
if [ -f Linux/finish ]; then
succed=1
#img&br
if [[ $fastboot123 = "3" ]]; then
##
finishimg
finishbr
##
else
#img
if [[ $fastboot123 = "1" ]]; then
##
finishimg
else
#br
finishbr
fi;fi
else
#动态分区打包为br格式
succed=1
rm -rf $tools/fail >/dev/null 2>&1
if [[ -f Linux/prebuilt/dynamic_partitions_op_list ]]; then

ls $xiaowan/*.list | while read i; do
    line=$(echo "$i" | cut -d"/" -f2| cut -d"." -f1)
    if [[ ! -f Linux/prebuilt/$line.new.dat.br ]]; then
	echo "$xiaowan制作失败,因为$line.new.dat.br打包失败" >>$tools/fail.txt
    touch $tools/fail >/dev/null 2>&1
    fi
done

else
#普通分区打包为dat格式

ls $xiaowan/*.list | while read i; do
    line=$(echo "$i" | cut -d"/" -f2| cut -d"." -f1)
    if [[ ! -f Linux/prebuilt/$line.new.dat ]]; then
    echo "$xiaowan制作失败,因为$line.new.dat打包失败" >>$tools/fail.txt
    touch $tools/fail >/dev/null 2>&1
    fi
done

fi
fi
########################################

if [[ -f $tools/fail ]]; then
succed=0
rm -rf $tools/fail >/dev/null 2>&1
fi

#除非succed值为1，否则打包失败
if [[ ! $succed = "1" ]]; then
clear
echo 
echo "$xiaowan制作失败,因为打包过程出现问题" >>$tools/fail.txt
cd $base
start_build
fi

if [ ! -f Linux/finish ]; then
if [[ $and11 = "false" ]]; then
cp -rf tools/patch/sunday/update-binary $xiaowan/META-INF/com/google/android/update-binary >/dev/null 2>&1
cp -rf tools/patch/sunday/update-binary Linux/prebuilt/META-INF/com/google/android/update-binary >/dev/null 2>&1
fi;fi

clear
echo 
echo 准备打包...
echo 

cd $base

rm -rf Linux/file_context >/dev/null 2>&1
rm -rf Linux/bin >/dev/null 2>&1

if [ -f Linux/finish ]; then

if [[ $fastboot123 = "3" ]]; then
fastpack
mv $xiaowan/images Linux/prebuilt/firmware-update >/dev/null 2>&1
cd Linux/prebuilt

rm -rf firmware-update/odm.img
rm -rf firmware-update/system.img
rm -rf firmware-update/vendor.img
rm -rf firmware-update/system_ext.img
rm -rf firmware-update/product.img
rm -rf firmware-update/super.img
cd $base

zippack
else
if [[ $fastboot123 = "1" ]]; then
fastpack
else
#ab分区打包卡刷包
mv $xiaowan/output Linux/prebuilt/firmware-update >/dev/null 2>&1
zippack
fi
fi
else
zippack
fi

start_build
}

chstat
extract_new
start_build
exit
