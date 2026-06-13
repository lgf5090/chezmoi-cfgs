@echo off
chcp 65001 >nul

echo 正在创建完整的 aliases.txt 文件...

(
echo mkcd=mkdir "$1" $T cd /d "$1"
echo ff=dir /s /b $*
echo dirsize=dir /s /-c $* ^^| find "bytes"
echo ep=explorer .
echo fm=explorer .
echo open=explorer $*
echo reload=call %%USERPROFILE%%\cmd_init.cmd
echo ..=cd ..
echo ...=cd ..\..
echo ....=cd ..\..\..
echo ~=cd %%USERPROFILE%%
echo home=cd %%USERPROFILE%%
echo cdt=cd %%USERPROFILE%%\Desktop
echo cdl=cd %%USERPROFILE%%\Downloads
echo cdm=cd %%USERPROFILE%%\Documents
echo cdv=cd %%USERPROFILE%%\Videos
echo cds=cd %%USERPROFILE%%\Music
echo cdp=cd %%USERPROFILE%%\Pictures
echo cdd=cd %%USERPROFILE%%\.local\share\chezmoi
echo cdc=cd %%USERPROFILE%%\.local\share\chezmoi
echo ls=dir /b $*
echo ll=dir $*
echo la=dir /a $*
echo l=dir /w $*
echo cat=type $*
echo touch=type nul $g$g $* 2$gnul
echo clear=cls
echo which=where $*
echo history=doskey /history
echo h=doskey /history
echo pwd=cd
echo edit=%%EDITOR%% $*
echo vi=vim $*
echo ip=ipconfig $*
echo ports=netstat -ano $*
echo ping=ping -n 4 $*
echo py=python $*
echo py3=python3 $*
echo d=docker $*
echo drun=docker run $*
echo dps=docker ps $*
echo dpsa=docker ps -a $*
echo dimg=docker images $*
echo dimages=docker images $*
echo dsp=docker stop $*
echo dstop=docker stop $*
echo dst=docker start $*
echo dstart=docker start $*
echo drst=docker restart $*
echo drestart=docker restart $*
echo drm=docker rm $*
echo dremove=docker rm $*
echo drmi=docker rmi $*
echo dbd=docker build $*
echo dbuild=docker build $*
echo dpl=docker pull $*
echo dpull=docker pull $*
echo dph=docker push $*
echo dpush=docker push $*
echo dlgs=docker logs $*
echo dlogs=docker logs $*
echo dins=docker inspect $*
echo dinspect=docker inspect $*
echo dinfo=docker system info $*
echo ddf=docker system df $*
echo dexec=docker exec -it $*
echo dsh=docker exec -it $* sh
echo dbash=docker exec -it $* bash
echo dprune=docker system prune -f $*
echo dclean=docker system prune -af --volumes $*
echo dc=docker-compose $*
echo dcup=docker-compose up -d $*
echo dcdown=docker-compose down $*
echo dcrestart=docker-compose restart $*
echo dclogs=docker-compose logs $*
echo dcps=docker-compose ps $*
echo dcexec=docker-compose exec $*
echo dcp=docker-compose up -d $*
echo dcd=docker-compose down $*
echo dcrst=docker-compose restart $*
echo dclgs=docker-compose logs $*
echo g=git $*
echo gs=git status
echo gst=git status
echo ga=git add $*
echo gaa=git add --all
echo gc=git commit -m "$*"
echo gca=git commit -am "$*"
echo gp=git push
echo gpl=git pull
echo gl=git log --oneline --graph --decorate $*
echo gd=git diff $*
echo gb=git branch $*
echo gco=git checkout $*
echo gcb=git checkout -b $*
echo gm=git merge $*
echo gr=git remote -v
echo gf=git fetch
echo gcl=git clone $*
echo bb=busybox $*
echo bbls=busybox ls --color=auto $*
echo bbcat=busybox cat $*
echo bbcp=busybox cp $*
echo bbmv=busybox mv $*
echo bbrm=busybox rm $*
echo bbmkdir=busybox mkdir $*
echo bbtouch=busybox touch $*
echo bbgrep=busybox grep $*
echo bbsed=busybox sed $*
echo bbawk=busybox awk $*
echo bbcut=busybox cut $*
echo bbsort=busybox sort $*
echo bbuniq=busybox uniq $*
echo bbwc=busybox wc $*
echo bbhead=busybox head $*
echo bbtail=busybox tail $*
echo bbtar=busybox tar $*
echo bbgzip=busybox gzip $*
echo bbgunzip=busybox gunzip $*
echo bbunzip=busybox unzip $*
echo bbbase64=busybox base64 $*
echo bbbase32=busybox base32 $*
echo bbmd5sum=busybox md5sum $*
echo bbsha1sum=busybox sha1sum $*
echo bbsha256sum=busybox sha256sum $*
echo bbsha512sum=busybox sha512sum $*
echo bbps=busybox ps $*
echo bbdf=busybox df $*
echo bbdu=busybox du $*
echo bbfree=busybox free $*
echo bbwget=busybox wget $*
echo bbnc=busybox nc $*
echo bbfind=busybox find $*
echo bbwhich=busybox which $*
echo bbxargs=busybox xargs $*
) > ".\aliases.txt"

echo 文件创建完成: .\aliases.txt
echo.
echo 测试加载别名文件...
doskey /macrofile=".\aliases.txt"

if errorlevel 1 (
    echo 错误: 别名文件加载失败
) else (
    echo 成功: 别名文件加载完成
    echo.
    echo 测试几个常用别名:
    echo - 输入 'ls' 测试文件列表
    echo - 输入 'clear' 测试清屏
    echo - 输入 'pwd' 测试当前目录
)