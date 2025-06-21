#!/bin/bash

# ------------------------------------------------------------------------- #
# This script runs sbsdig jobs.                                             #
# ---------                                                                 #
# P. Datta <pdbforce@jlab.org> CREATED 11-09-2022                           #
# ---------                                                                 #
# ** Do not tamper with this sticker! Log any updates to the script above.  #
# ------------------------------------------------------------------------- #

#SBATCH --partition=production
#SBATCH --account=halla
#SBATCH --mem-per-cpu=1500

# list of arguments
txtfile=$1 # .txt file containing input file paths
infilename=$2
gemconfig=$3 # valid options: 8,10,12 (Represents # GEM modules)
sbsconfig=$4
run_on_ifarm=$5
g4sbsenv=$6
libsbsdigenv=$7
ANAVER=$8      # Analyzer version
useJLABENV=$9  # Use 12gev_env instead of modulefiles?
JLABENV=$10     # /site/12gev_phys/softenv.sh version

# paths to necessary libraries (ONLY User specific part) ---- #
export G4SBS=$g4sbsenv
export LIBSBSDIG=$libsbsdigenv
# ----------------------------------------------------------- #

ifarmworkdir=${PWD}
if [[ $isifarm == 1 ]]; then
    SWIF_JOB_WORK_DIR=$ifarmworkdir
    echo -e "Running all jobs on ifarm!"
fi
echo 'Work directory = '$SWIF_JOB_WORK_DIR

# Enabling module
MODULES=/etc/profile.d/modules.sh 
if [[ $(type -t module) != function && -r ${MODULES} ]]; then 
    source ${MODULES} 
fi 
# Choosing software environment
if [[ (! -d /group/halla/modulefiles) || ($useJLABENV -eq 1) ]]; then 
    source /site/12gev_phys/softenv.sh $JLABENV
else 
    module use /group/halla/modulefiles
    module load analyzer/$ANAVER
    module list
fi

# Setup sbsdig specific environments
source $G4SBS/bin/g4sbs.sh
source $LIBSBSDIG/bin/sbsdigenv.sh

# Choosing the right DB file depending on GEM config
if [[ $gemconfig -eq 8 ]]; then
    dbfile=$LIBSBSDIG/db/db_gmn_conf_8gemmodules_$sbsconfig.dat
elif [[ $gemconfig -eq 10 ]]; then
    dbfile=$LIBSBSDIG/db/db_gmn_conf_10gemmodules_$sbsconfig.dat
elif [[ $gemconfig -eq 12 ]]; then
    dbfile=$LIBSBSDIG/db/db_gmn_conf_12gemmodules_$sbsconfig.dat
elif [[ $gemconfig -eq 0 ]]; then #GEN-RP
    dbfile=$LIBSBSDIG/db/db_genrp_conf_dev.dat
elif [[ $gemconfig -eq -1 ]]; then #GEP-1
    dbfile=$LIBSBSDIG/db/db_gep1_conf_single-analyzer.dat
elif [[ $gemconfig -eq -2 ]]; then #GEP-2
    dbfile=$LIBSBSDIG/db/db_gep2_conf_single-analyzer.dat
elif [[ $gemconfig -eq -3 ]]; then #GEP-3
    dbfile=$LIBSBSDIG/db/db_gep3_conf_single-analyzer.dat    
else
    echo -e "[run-sbsdig.sh] ERROR!! Enter valid GEM config!"
    exit;
fi

if [[ $sbsconfig -eq GENRP ]]; then
    dbfile=$LIBSBSDIG/db/db_genrp_conf_dev.dat
elif [[ $sbsconfig -eq GEN2 || $sbsconfig -eq GEN3 || $sbsconfig -eq GEN4 ]]; then
    dbfile=$LIBSBSDIG/db/db_gen_conf_8gemmodules_$sbsconfig.dat
fi

# creating input text file
echo $infilename >>$txtfile

# run the sbsdig command
sbsdig $dbfile $txtfile

# cleaning up the work directory
rm $txtfile
