#!/bin/sh

dialog_main() {
    HEIGHT=40
    WIDTH=90
    CHOICE_HEIGHT=38
    #BACKTITLE="0516320 SIM"
    MENU="SYS INFO"
    CHOICE=$(dialog --backtitle "$BACKTITLE" \
                    --menu "$MENU"  \
                    $HEIGHT $WIDTH $CHOICE_HEIGHT \
                    1 "CPU INFO" 2 "MEMORY INFO" 3 "NETWORK INFO" 4 "FILE BROWSER"\
                    2>&1 >/dev/tty)
    return $CHOICE
}

dialog_CPU() {
    hw_model=$(sysctl hw.model)
    hw_model=${hw_model#"hw.model: "}
    hw_machine=$(sysctl hw.machine)
    hw_machine=${hw_machine#"hw.machine: "}
    hw_ncpu=$(sysctl hw.ncpu)
    hw_ncpu=${hw_ncpu#"hw.ncpu: "}
    CPUresult=" CPU Info\n CPU Model:  ${hw_model}\n CPU Machine:  ${hw_machine}\n CPU Core:  ${hw_ncpu}\n"
    dialog --backtitle "$BACKTITLE" --msgbox "$CPUresult" 40 90 
}

calculate_bytes() {
    f=0
    tmp=$1
    smp=$1
    while [ 1023 -lt $smp ]; do
        smp=`expr $smp / 1024`
        tmp=$(echo "scale=2;${tmp}/1024" | bc)
        f=`expr $f + 1`
    done
    case $f in
        0) echo $tmp "B";;
        1) echo $tmp "KB";;
        2) echo $tmp "MB";;
        3) echo $tmp "GB";;
        4) echo $tmp "TB";;
    esac
}


dialog_Memory() {
    persentage=0
    while [ $persentage -le 100 ];
    do
    cachemem=$(sysctl vm.stats.vm.v_cache_count | sed 's/^vm.stats.vm.v_cache_count:.//')
    inactmem=$(sysctl vm.stats.vm.v_inactive_count | sed 's/^vm.stats.vm.v_inactive_count:.//')
    free_mem=$(sysctl vm.stats.vm.v_free_count | sed 's/^vm.stats.vm.v_free_count:.//')
    pagesize=$(sysctl hw.pagesize | sed 's/^hw.pagesize:.//')
    availmem=`expr $cachemem + $inactmem`
    availmem=`expr $availmem + $free_mem`
    availmem=`expr $availmem \* $pagesize`
    totalmem=$(sysctl hw.physmem | sed 's/^hw.physmem:.//') 
    used_mem=`expr $totalmem - $availmem`
    persentage=$(echo "scale=2;${used_mem}/${totalmem}" | bc)
    persentage=$(echo "${persentage}*100" | bc)
    persentage=${persentage%.*}
    
    availmem=$(calculate_bytes $availmem)
    used_mem=$(calculate_bytes $used_mem)
    totalmem=$(calculate_bytes $totalmem)
    MEMresult=" Memory Info and Usage\n\n Total: ${totalmem}\n Used: ${used_mem}\n Free: ${availmem} "    
    echo $persentage | dialog --backtitle "$BACKTITLE" --title "Memory Info" --gauge "$MEMresult" 40 90
    sleep 1
    read -t 1 var 
    if [ $? == 0 ]; then
        break
    fi
    done
}

dialog_Net(){
    NETLIST=$(ifconfig -l | awk '{for(i=1;i<=NF;i++) printf $i " - "}')
    while true; do
        NetC=$(dialog --backtitle "$BACKTITLE" \
                  --menu "Network Interfaces" 40 90 38 \
                  $NETLIST 2>&1 >/dev/tty)
        if [ $? -eq 0 ]; then 
            MAC=$(ifconfig "$NetC" | grep "ether" | sed 's/^.*ether.//')
            IP=$(ifconfig "$NetC" inet | grep "inet" | sed 's/^.*inet.//g' | sed 's/.netmask.*$//')
            NMk=$(ifconfig "$NetC" | grep "netmask" | sed 's/^.*netmask.//g' | sed 's/.broadcast.*$//')
            NETresult=" Interface Name: ${NetC}\n\n IPv4___:  ${IP}\n netmask:  ${NMk}\n MAC____:  ${MAC}"
            dialog --backtitle "$BACKTITLE" --msgbox "$NETresult" 40 90
        else
            break
        fi
    done
}


dialog_File(){
    currentPath=$(dirname $0)
    while true; do
        fullPath=$(readlink -f "$currentPath")
        fileLIST=$(printf "..\n$(find "$fullPath")")
        IFS=$'\n'
        fileSHOW=""
        for p in $fileLIST ;do
            fileSHOW=$fileSHOW" "$(echo "$p" | sed 's/.*\///' | tr ' ' '+' )
            fileSHOW=$fileSHOW" "$(echo $(file --mime-type "$p") | sed 's/^.*:.//')
        done
        IFS=$' '
        fileSHOW=$(echo "$fileSHOW" | sed 's/ //' )
        FileSel=$(dialog --backtitle "$BACKTITLE" --menu "File Browser: ${fullPath}" 40 90 38 $fileSHOW 2>&1 >/dev/tty)
        if [ $? -eq 0 ]; then
            PathSel=$(echo $fileLIST | grep -m 1 "${FileSel}$" | sort)
            TypeSel=$(file "$PathSel"| sed 's/.*:.//')
            case $TypeSel in
                "directory")  
                    if [ "$PathSel" == ".." ]; then
                        currentPath=${fullPath%/*}
                    else
                        currentPath="$PathSel"
                    fi;;
                "ASCII text") 
                    SizeSel=$(stat -f%z "$PathSel")
                    SizeSel=$(calculate_bytes $SizeSel)
                    FILEresult=" <File Name>:  ${FileSel}\n <File Info>:  ${TypeSel}\n <File Size>:  ${SizeSel}"
                    while true; do
                    dialog --backtitle "$BACKTITLE" --extra-button --extra-label "Edit" --msgbox "$FILEresult" 40 90
                    EdSel=$? 
                    if [ "$EdSel" == 3 ]; then
                            $EDITOR "$PathSel"
                        else
                            break
                        fi
                    done;;
                *)  SizeSel=$(stat -f%z "$PathSel")
                    SizeSel=$(calculate_bytes $SizeSel)
                    FILEresult=" <File Name>:  ${FileSel}\n <File Info>:  ${TypeSel}\n <File Size>:  ${SizeSel}"
                    dialog --backtitle "$BACKTITLE" --msgbox "$FILEresult" 40 90;;
            esac
        else
            break  
        fi
    done
}

dialog_CPUUsage() {
    hw_ncpu=$(sysctl hw.ncpu)
    hw_ncpu=${hw_ncpu#"hw.ncpu: "}
}


while true; do
    dialog_main
    case $CHOICE in
        1) dialog_CPU;;
        2) dialog_Memory;;
        3) dialog_Net;;
        4) dialog_File;;
        *) return 0;;
    esac
done
