#!/bin/bash

# ------------------------------------------------------------------------- #
# This script runs sbsdig jobs on ifarm or submits them to batch farm.      #
# ---------                                                                 #
# P. Datta <pdbforce@jlab.org> CREATED 11-09-2022                           #
# ---------                                                                 #
# ** Do not tamper with this sticker! Log any updates to the script above.  #
# ------------------------------------------------------------------------- #

# Setting necessary environments via setenv.sh
source setenv.sh

# Filebase of the g4sbs output file (w/o file extention)
g4sbsfilebase=$1
# Directory at which g4sbs output files are existing which we want to digitize
g4sbsfiledir=$2
sbsconfig=$3    # GEM config (Valid options: 8,10,12)
fjobid=$4       # first job id
njobs=$5        # total no. of jobs to submit 
run_on_ifarm=$6 # 1=>Yes (If true, runs all jobs on ifarm)
# workflow name
workflowname=

# Checking the environments
if [[ ! -d $SCRIPT_DIR ]]; then
    echo -e '\nERROR!! Please set "SCRIPT_DIR" path properly in setenv.sh script!\n'; exit;
elif [[ ! -d $LIBSBSDIG ]]; then
    echo -e '\nERROR!! Please set "LIBSBSDIG" path properly in setenv.sh script!\n'; exit;
fi

# Validating the number of arguments provided
if [[ "$#" -ne 6 ]]; then
    echo -e "\n--!--\n Illegal number of arguments!!"
    echo -e " This script expects 6 arguments: <g4sbsfilebase> <g4sbsfiledir> <gemconfig> <fjobid> <njobs> <run_on_ifarm>\n"
    exit;
else 
    if [[ $run_on_ifarm -ne 1 ]]; then
	echo -e '\n------'
	echo -e ' Check the following variable(s):'
	echo -e ' "workflowname" : '$workflowname''
	while true; do
	    read -p "Do they look good? [y/n] " yn
	    echo -e ""
	    case $yn in
		[Yy]*) 
		    break; ;;
		[Nn]*) 
		    read -p "Enter desired workflowname : " temp1
		    workflowname=$temp1
		    break; ;;
	    esac
	done
    fi
fi

# Creating the workflow
if [[ $run_on_ifarm -ne 1 ]]; then
    swif2 create $workflowname
else
    echo -e "\nRunning all jobs on ifarm!\n"
fi

#adjusting gemconfig
gemconfig=0
if [[ ($sbsconfig == GMN4) || ($sbsconfig == GMN7) ]]; then
    gemconfig=12
elif [[ $sbsconfig == GMN11 ]]; then
    gemconfig=10
elif [[ ($sbsconfig == GMN14) || ($sbsconfig == GMN8) || ($sbsconfig == GMN9) || ($sbsconfig == GEN2) || ($sbsconfig == GEN3) || ($sbsconfig == GEN4) ]]; then
    gemconfig=8
    # GEP has only one SBS GEM config. However, each setting has a different DB file for digitization. To handle that without major change to the code we are using gemconfig flag.
elif [[ $sbsconfig == GENRP ]]; then
    gemconfig=0
elif [[ $sbsconfig == GEP1 ]]; then
    gemconfig=-1
elif [[ $sbsconfig == GEP2 ]]; then
    gemconfig=-2
elif [[ $sbsconfig == GEP3 ]]; then
    gemconfig=-3        
else
    echo -e "Enter valid SBS config! Valid options: GMN4,GMN7,GMN11,GMN14,GMN8,GMN9,GEN2,GEN3,GEN4,GENRP,GEP1,GEP2,GEP3"
    exit;
fi

# creating jobs
for ((i=$fjobid; i<$((fjobid+njobs)); i++))
do
    txtfile=$g4sbsfilebase'_job_'$i'.txt'
    sbsdigjobname=$g4sbsfilebase'_digi_job_'$i
    sbsdiginfile=$g4sbsfiledir'/'$g4sbsfilebase'_job_'$i'.root'

    sbsdigscript=$SCRIPT_DIR'/run-sbsdig.sh'' '$txtfile' '$sbsdiginfile' '$gemconfig' '$sbsconfig' '$run_on_ifarm' '$G4SBS' '$LIBSBSDIG' '$ANAVER' '$useJLABENV' '$JLABENV

    if [[ $run_on_ifarm -ne 1 ]]; then
	swif2 add-job -workflow $workflowname -partition production -name $sbsdigjobname -cores 1 -disk 5GB -ram 1500MB $sbsdigscript
    else
	$sbsdigscript
    fi
done

# run the workflow and then print status
if [[ $run_on_ifarm -ne 1 ]]; then
    swif2 run $workflowname
    echo -e "\n Getting workflow status.. [may take a few minutes!] \n"
    swif2 status $workflowname
fi
