#!/bin/bash

module load gcp
echo "Model started:  " `date`
current_folder=$(basename "$PWD")

pushd INPUT/
ln -fs MOM_layout_20 MOM_layout
ln -fs MOM_layout_20 SIS_layout
popd

#runlen_month="0" ###one time run duration
#runlen_day="2" ####cannot exceed a month
NUM_TOT=4  ###overall duration/months
calmstart=false ###set to true if starting from calm

##modified ww3_multi.inp to make the start date match with input.nml
current_year=$(grep "current_date" "input.nml" | awk -F'=' '{print $2}' | awk -F',' '{print $1}' | xargs)
current_month=$(grep "current_date" "input.nml" | awk -F'=' '{print $2}' | awk -F',' '{print $2}' | xargs)
current_day=$(grep "current_date" "input.nml" | awk -F'=' '{print $2}' | awk -F',' '{print $3}' | xargs)
current_month_ww3=$current_month
current_day_ww3=$current_day
# Print the results
echo "Current year is: $current_year"
echo "Current month is: $current_month"
echo "Current day is: $current_day"
if [ ${#current_month} -eq 1 ]; then
   current_month_ww3="0$current_month"
fi
if [ ${#current_day} -eq 1 ]; then

        current_day_ww3="0$current_day"
fi
newline_ww3="   $current_year$current_month_ww3$current_day_ww3 000000   20231231 000000"
sed -i "8s/.*/${newline_ww3}/" "ww3_multi.inp"

######run time read from input.nml
runlen_month=$(grep "months" "input.nml" | awk -F'=' '{print $2}' | xargs)
echo "add month number is: $runlen_month"
runlen_day=$(grep "days" "input.nml" | awk -F'=' '{print $2}' | xargs)
echo "add day number is: $runlen_day"


###modify the restart files output
start_date_ww3="${current_year}-${current_month_ww3}-${current_day_ww3}"
number_month=$((runlen_month + 0))
number_day=$((runlen_day + 0))
end_date_ww3=$(date -u -d "$start_date_ww3 +$number_month months +$number_day days" +"%Y-%m-%d")

# Output the result
echo "Start date: $start_date_ww3"
echo "Days to add: $number_day"
echo "Months to add: $number_month"
echo "End date: $end_date_ww3"

start_sec=$(date -u -d "$start_date_ww3" +%s)
end_sec=$(date -u -d "$end_date_ww3" +%s)
# Calculate the difference in seconds, then convert to days
diff_sec=$((end_sec - start_sec))
diff_days=$((diff_sec / 86400)) # 86400 seconds in a day
echo "There are $diff_days days $diff_sec seconds between $start_date_ww3 and $end_date_ww3."

newline_ww3="   $current_year$current_month_ww3$current_day_ww3 000000  $diff_sec   20231231 000000"
sed -i "19s/.*/${newline_ww3}/" "ww3_multi.inp"


###modify data_table
fyear=$current_year
cat > "data_table" << EOF
"ATM", "p_surf",             "msl",    "INPUT/ERA5_msl_${fyear}_padded.nc",           "bilinear",  1.0
"ATM", "p_bot",              "msl",    "INPUT/ERA5_msl_${fyear}_padded.nc",           "bilinear",  1.0
"ATM", "t_bot",              "t2m",    "INPUT/ERA5_t2m_${fyear}_padded.nc",           "bilinear",  1.0
"ATM", "sphum_bot",          "sphum",  "INPUT/ERA5_sphum_${fyear}_padded.nc",          "bilinear",  1.0
"ATM", "u_bot",              "u10",    "INPUT/ERA5_u10_${fyear}_padded.nc",          "bicubic",   1.0
"ATM", "v_bot",              "v10",    "INPUT/ERA5_v10_${fyear}_padded.nc",          "bicubic",   1.0
"ATM", "z_bot",              "",       "",                           "bilinear", 10.0
"ATM", "gust",               "",       "",                           "bilinear",  1.0e-4
"ATM", "o2_flux_pcair_atm",  "",       "",                           "none",      0.214
"ATM", "co2_flux_pcair_atm", "mole_fraction_of_carbon_dioxide_in_air", "INPUT/mole_fraction_of_co2_extended_ssp245.nc", "bilinear", 1.0e-06
"ATM", "co2_bot",            "mole_fraction_of_carbon_dioxide_in_air", "INPUT/mole_fraction_of_co2_extended_ssp245.nc", "bilinear", 1.0e-06
"ATM", "co2_dvmr_restore",   "mole_fraction_of_carbon_dioxide_in_air", "INPUT/mole_fraction_of_co2_extended_ssp245.nc", "bilinear", 1.0e-06
#
"ICE", "lw_flux_dn"        , "strd",   "INPUT/ERA5_strd_${fyear}_padded.nc",          "bilinear", 2.77778e-4
"ICE", "sw_flux_vis_dir_dn", "ssrd",   "INPUT/ERA5_ssrd_${fyear}_padded.nc",          "bilinear",  7.9167e-5
"ICE", "sw_flux_vis_dif_dn", "ssrd",   "INPUT/ERA5_ssrd_${fyear}_padded.nc",          "bilinear",  7.9167e-5
"ICE", "sw_flux_nir_dir_dn", "ssrd",   "INPUT/ERA5_ssrd_${fyear}_padded.nc",          "bilinear",  5.9722e-5
"ICE", "sw_flux_nir_dif_dn", "ssrd",   "INPUT/ERA5_ssrd_${fyear}_padded.nc",          "bilinear",  5.9722e-5
"ICE", "lprec",              "lp",     "INPUT/ERA5_lp_${fyear}_padded.nc",            "bilinear", 0.277777778
"ICE", "fprec",              "sf",     "INPUT/ERA5_sf_${fyear}_padded.nc",            "bilinear", 0.277777778
"ICE", "runoff",             "runoff", "INPUT/glofas_runoff_${fyear}.nc",     "none",      1.0
"ICE", "calving",            "",       "",                           "none",      0.0
"ICE", "dhdt",               "",       "",                           "none",     80.0
"ICE", "dedt",               "",       "",                           "none",      2.0e-6
"ICE", "drdt",               "",       "",                           "none",     10.0
#
"LND", "t_surf",             "",       "",                           "none",    273.0
"LND", "t_ca",               "",       "",                           "none",    273.0
"LND", "q_ca",               "",       "",                           "none",     0.0
"LND", "rough_mom",          "",       "",                           "none",     0.01
"LND", "rough_heat",         "",       "",                           "none",     0.1
"LND", "albedo",             "",       "",                           "none",     0.1
"LND", "sphum_surf",         "",       "",                           "none",     0.0
"LND", "sphum_ca",           "",       "",                           "none",     0.0
"LND", "t_flux",             "",       "",                           "none",     0.0
"LND", "sphum_flux",         "",       "",                           "none",     0.0
"LND", "lw_flux",            "",       "",                           "none",     0.0
"LND", "sw_flux",            "",       "",                           "none",     0.0
"LND", "lprec",              "",       "",                           "none",     0.0
"LND", "fprec",              "",       "",                           "none",     0.0
"LND", "dhdt",               "",       "",                           "none",     5.0
"LND", "dedt",               "",       "",                           "none",     2.0e-6
"LND", "dedq",               "",       "",                           "none",     0.0
"LND", "drdt",               "",       "",                           "none",     5.0
"LND", "drag_q",             "",       "",                           "none",     0.0
"LND", "p_surf",             "",       "",                           "none",     1.0e5
EOF

##relink the input files to the corret file:
cd INPUT/
find . -type l -name "ERA5*_padded.nc" -exec rm {} \;
find . -type l -name "glofas_runoff_*.nc" -exec rm {} \;
ln -sf ../../era5/ERA5_msl_${fyear}_padded.nc ERA5_msl_${fyear}_padded.nc

ln -sf ../../era5/ERA5_t2m_${fyear}_padded.nc ERA5_t2m_${fyear}_padded.nc

ln -sf ../../era5/ERA5_sphum_${fyear}_padded.nc ERA5_sphum_${fyear}_padded.nc

ln -sf ../../era5/ERA5_strd_${fyear}_padded.nc ERA5_strd_${fyear}_padded.nc

ln -sf ../../era5/ERA5_ssrd_${fyear}_padded.nc ERA5_ssrd_${fyear}_padded.nc

ln -sf ../../era5/ERA5_lp_${fyear}_padded.nc ERA5_lp_${fyear}_padded.nc

ln -sf ../../era5/ERA5_sf_${fyear}_padded.nc ERA5_sf_${fyear}_padded.nc

ln -sf ../../era5/ERA5_u10_${fyear}_padded.nc ERA5_u10_${fyear}_padded.nc

ln -sf ../../era5/ERA5_v10_${fyear}_padded.nc ERA5_v10_${fyear}_padded.nc

ln -sf ../../datasets1/glofas/2023_04_v2/glofas_runoff_${fyear}.nc glofas_runoff_${fyear}.nc


###modify MOM_override file

new_line="#override OBC_TIDE_NODAL_REF_DATE = ${current_year},7,2"
# Replace the line with the keyword
sed -i "/#override OBC_TIDE_NODAL_REF_DATE/c\\$new_line" "MOM_override"
echo "Replaced the line with: $new_line in the file MOM_override."
cd ../
###return to main directory of NWA12
if "$calmstart"; then
  echo "start from beginging"
  sed -i "s/input_filename = 'r'/input_filename = 'n'/g" "input.nml"
  rm restart*.ww3
  rm RESTART/*
  rm time*out
  cd INPUT/
  rm coupler.res ice_model.res.nc MOM.res_1.nc MOM.res.nc MOM.res_2.nc
  cd ../
else
  echo "start from restart file"
fi

JOB_ID=$(sbatch --parsable job_script.sh 1)  # First task with argument "1"
echo "Submitted Job ID: $JOB_ID"

# Monitor the job until it finishes
while true; do
    # Check if the job is still in the queue
    squeue --job $JOB_ID &> /dev/null
    JOB_EXISTS=$?  # Capture the exit status of squeue
    if [[ $JOB_EXISTS -ne 0 ]]; then
        echo " Job is no longer in the queue, breaks"
        break
    fi
    sleep 5  # Check every 5 seconds
done

# Check the job completion status using sacct
JOB_STATE=$(sacct -j $JOB_ID --format=State --noheader | tail -n 1 | awk '{print $1}')
echo "Job ID $JOB_ID has completed with status: $JOB_STATE"

# Handle job success or failure
if [[ "$JOB_STATE" == "COMPLETED" ]]; then
    echo "Job completed successfully. Proceeding..."
else
    echo "Job failed or was cancelled. Exiting..."
    exit 1
fi

####resubmit start
###start run restartfiles
lines=()
while  read -r line; do
        lines+=("$line")
done < "time_stamp.out"

startdate=${lines[0]}
IFS=' ' read -r -a sarray <<< "$startdate"
start_y=${sarray[0]}
start_m=${sarray[1]}
start_d=${sarray[2]}
echo "Zeraceoutput Startdate $startdate"
if [ ${#start_m} -eq 1 ]; then
   start_m="0$start_m"
fi
if [ ${#start_d} -eq 1 ]; then

	start_d="0$start_d"
fi

newline_ww3="  $start_y$start_m$start_d 000000  3600.  100000"
echo "WW3 postProcessing starting at $start_y$start_m$start_d"
mkdir results
cd WW3/PostProc
	sed -i "7s/.*/${newline_ww3}/" "ww3_ounf.inp"
	../../../../build/ncrc6.intel23/ww3_ounf/REPRO/ww3_ounf > ../../log.ww3_ounf
	if [[ -e "ww3.$start_y$start_m.nc" && -e "ww3.$start_y${start_m}_usp.nc" ]]; then
	    echo "Task 0 ww3 postprocessing profile successfully. Continuing..."
	else
	    echo "Error in Task 0. No files ww3.$start_y$start_m.nc or ww3.$start_y${start_m}_usp.nc have been found."
	fi
	mv ww3.$start_y$start_m.nc ww3.$start_y$start_m$start_d.nc
	mv ww3.${start_y}${start_m}_usp.nc ww3.${start_y}${start_m}${start_d}_usp.nc
	cp -rf ww3*nc ../../results/
        cp -rf ww3_ounf.inp ../../results/
        rm ww3.$start_y*nc
cd ../../
rm logfile*
cp -rf ${start_y}${start_m}${start_d}*.nc results/
cp -rf out_grd.ww3 results/
cp -rf RESTART results/
cp -rf ocean.stats results/
cp -rf ocean.stats.nc results/
cp -rf time_stamp.out results/
cp -rf input.nml results/
cp -rf ww3_multi.inp results/
cp -rf restart0*.ww3 results/
rm -rf ${start_y}${start_m}${start_d}*.nc

mv results ${start_y}${start_m}${start_d}_results
tar -czf ${start_y}${start_m}${start_d}_results.tar.gz ${start_y}${start_m}${start_d}_results
gcp -r ${start_y}${start_m}${start_d}_results.tar.gz gfdl:/archive/Qian.Xiao/Qian.Xiao/FMS_Wave_Coupling_ZC/postProcessing/$current_folder/

if [[ $? -eq 0 ]]; then
  echo "File transfer was successful."
else
  echo "File transfer failed.try to create a folder"
  mkdir $current_folder
  cp ${start_y}${start_m}${start_d}_results.tar.gz $current_folder/
  gcp -r $current_folder gfdl:/archive/Qian.Xiao/Qian.Xiao/FMS_Wave_Coupling_ZC/postProcessing/
	  if [[ $? -eq 0 ]]; then
		  echo "file transfer succedded"
	  else
		  echo "file transfer failed even with new filename created"
	 fi
   rm -rf $current_folder
fi 

if [[ -e "./${start_y}${start_m}${start_d}_results.tar.gz" ]]; then
echo "Task 0 completed successfully with results zipped. Continuing..."
else
echo "Error in results store for Task 0. Stopping."
exit 1
fi
rm -rf ${start_y}${start_m}${start_d}_results
echo -n " $( date +%s )," >> job_timestamp.txt

NUM_TOT=$((NUM_TOT -1))
##edit input.nml coupler months=run_length
while read line; do
  if [[ $line == *"months"* ]]; then
    month_line=$line
  fi
  if [[ $line == *"days"* ]]; then
    day_line=$line
  fi
done < "input.nml"
sed -i "s/$month_line/months = "$runlen_month"/g" "input.nml"
sed -i "s/$day_line/days   = "$runlen_day"/g" "input.nml"
if [[ $NUM_TOT -eq 0 ]]; then
    echo "NUM_TOT is 0. Exiting..."
    exit 1
fi
for ((i_loop=1; i_loop<=NUM_TOT; i_loop++)); do
    echo "Iteration $i_loop"
	##edit input.nml input_filename='r'
	if "$calmstart"; then
	  sed -i "s/input_filename = 'n'/input_filename = 'r'/g" "input.nml"
	  echo "start from beginging and now from restart file"
	  calmstart=false
	else
	  echo "start from restart file"
	fi

	##read time_stamp.out to make sure the starttime and end time
	lines=()
	while  read -r line; do
		lines+=("$line")
	done < "time_stamp.out"
       
	enddate=${lines[1]}
	IFS=' ' read -r -a earray <<< "$enddate"
	end_y=${earray[0]}
	end_m=${earray[1]}
	end_d=${earray[2]}
	###edit input.nml about the current_date

	while read line; do
	  if [[ $line == *"current_date = "* ]]; then
	    currentdate_line=$line
	  fi
	done < "input.nml"

	sed -i "s/$currentdate_line/current_date = "$end_y,$end_m,$end_d,0,0,0"/g" "input.nml"
	
	###modify data_table for restart
	fyear=$end_y
	cat > "data_table" << EOF
"ATM", "p_surf",             "msl",    "INPUT/ERA5_msl_${fyear}_padded.nc",           "bilinear",  1.0
"ATM", "p_bot",              "msl",    "INPUT/ERA5_msl_${fyear}_padded.nc",           "bilinear",  1.0
"ATM", "t_bot",              "t2m",    "INPUT/ERA5_t2m_${fyear}_padded.nc",           "bilinear",  1.0
"ATM", "sphum_bot",          "sphum",  "INPUT/ERA5_sphum_${fyear}_padded.nc",          "bilinear",  1.0
"ATM", "u_bot",              "u10",    "INPUT/ERA5_u10_${fyear}_padded.nc",          "bicubic",   1.0
"ATM", "v_bot",              "v10",    "INPUT/ERA5_v10_${fyear}_padded.nc",          "bicubic",   1.0
"ATM", "z_bot",              "",       "",                           "bilinear", 10.0
"ATM", "gust",               "",       "",                           "bilinear",  1.0e-4
"ATM", "o2_flux_pcair_atm",  "",       "",                           "none",      0.214
"ATM", "co2_flux_pcair_atm", "mole_fraction_of_carbon_dioxide_in_air", "INPUT/mole_fraction_of_co2_extended_ssp245.nc", "bilinear", 1.0e-06
"ATM", "co2_bot",            "mole_fraction_of_carbon_dioxide_in_air", "INPUT/mole_fraction_of_co2_extended_ssp245.nc", "bilinear", 1.0e-06
"ATM", "co2_dvmr_restore",   "mole_fraction_of_carbon_dioxide_in_air", "INPUT/mole_fraction_of_co2_extended_ssp245.nc", "bilinear", 1.0e-06
#
"ICE", "lw_flux_dn"        , "strd",   "INPUT/ERA5_strd_${fyear}_padded.nc",          "bilinear", 2.77778e-4
"ICE", "sw_flux_vis_dir_dn", "ssrd",   "INPUT/ERA5_ssrd_${fyear}_padded.nc",          "bilinear",  7.9167e-5
"ICE", "sw_flux_vis_dif_dn", "ssrd",   "INPUT/ERA5_ssrd_${fyear}_padded.nc",          "bilinear",  7.9167e-5
"ICE", "sw_flux_nir_dir_dn", "ssrd",   "INPUT/ERA5_ssrd_${fyear}_padded.nc",          "bilinear",  5.9722e-5
"ICE", "sw_flux_nir_dif_dn", "ssrd",   "INPUT/ERA5_ssrd_${fyear}_padded.nc",          "bilinear",  5.9722e-5
"ICE", "lprec",              "lp",     "INPUT/ERA5_lp_${fyear}_padded.nc",            "bilinear", 0.277777778
"ICE", "fprec",              "sf",     "INPUT/ERA5_sf_${fyear}_padded.nc",            "bilinear", 0.277777778
"ICE", "runoff",             "runoff", "INPUT/glofas_runoff_${fyear}.nc",     "none",      1.0
"ICE", "calving",            "",       "",                           "none",      0.0
"ICE", "dhdt",               "",       "",                           "none",     80.0
"ICE", "dedt",               "",       "",                           "none",      2.0e-6
"ICE", "drdt",               "",       "",                           "none",     10.0
#
"LND", "t_surf",             "",       "",                           "none",    273.0
"LND", "t_ca",               "",       "",                           "none",    273.0
"LND", "q_ca",               "",       "",                           "none",     0.0
"LND", "rough_mom",          "",       "",                           "none",     0.01
"LND", "rough_heat",         "",       "",                           "none",     0.1
"LND", "albedo",             "",       "",                           "none",     0.1
"LND", "sphum_surf",         "",       "",                           "none",     0.0
"LND", "sphum_ca",           "",       "",                           "none",     0.0
"LND", "t_flux",             "",       "",                           "none",     0.0
"LND", "sphum_flux",         "",       "",                           "none",     0.0
"LND", "lw_flux",            "",       "",                           "none",     0.0
"LND", "sw_flux",            "",       "",                           "none",     0.0
"LND", "lprec",              "",       "",                           "none",     0.0
"LND", "fprec",              "",       "",                           "none",     0.0
"LND", "dhdt",               "",       "",                           "none",     5.0
"LND", "dedt",               "",       "",                           "none",     2.0e-6
"LND", "dedq",               "",       "",                           "none",     0.0
"LND", "drdt",               "",       "",                           "none",     5.0
"LND", "drag_q",             "",       "",                           "none",     0.0
"LND", "p_surf",             "",       "",                           "none",     1.0e5
EOF
	##relink the input files to the corret file:
	cd INPUT/
	find . -type l -name "ERA5*_padded.nc" -exec rm {} \;
	find . -type l -name "glofas_runoff_*.nc" -exec rm {} \;
	ln -sf ../../era5/ERA5_msl_${fyear}_padded.nc ERA5_msl_${fyear}_padded.nc

	ln -sf ../../era5/ERA5_t2m_${fyear}_padded.nc ERA5_t2m_${fyear}_padded.nc

	ln -sf ../../era5/ERA5_sphum_${fyear}_padded.nc ERA5_sphum_${fyear}_padded.nc

	ln -sf ../../era5/ERA5_strd_${fyear}_padded.nc ERA5_strd_${fyear}_padded.nc

	ln -sf ../../era5/ERA5_ssrd_${fyear}_padded.nc ERA5_ssrd_${fyear}_padded.nc

	ln -sf ../../era5/ERA5_lp_${fyear}_padded.nc ERA5_lp_${fyear}_padded.nc

	ln -sf ../../era5/ERA5_sf_${fyear}_padded.nc ERA5_sf_${fyear}_padded.nc

	ln -sf ../../era5/ERA5_u10_${fyear}_padded.nc ERA5_u10_${fyear}_padded.nc

	ln -sf ../../era5/ERA5_v10_${fyear}_padded.nc ERA5_v10_${fyear}_padded.nc

	ln -sf ../../datasets1/glofas/2023_04_v2/glofas_runoff_${fyear}.nc glofas_runoff_${fyear}.nc


	###modify MOM_override file

	new_line="#override OBC_TIDE_NODAL_REF_DATE = ${fyear},7,2"
	# Replace the line with the keyword
	sed -i "/#override OBC_TIDE_NODAL_REF_DATE/c\\$new_line" "MOM_override"
	echo "Replaced the line with: $new_line in the file MOM_override."
	cd ../

	##modified ww3_file for the new start date
	if [ ${#end_m} -eq 1 ]; then
	   end_m="0$end_m"
	fi
	if [ ${#end_d} -eq 1 ]; then
	   end_d="0$end_d"
	fi
	newline_ww3="   $end_y$end_m$end_d 000000   20231231 000000"

	sed -i "8s/.*/${newline_ww3}/" "ww3_multi.inp"
	###modify the restart files output
	start_date_ww3="$end_y-$end_m-$end_d"
        number_month=$((runlen_month + 0))
	number_day=$((runlen_day + 0))
	end_date_ww3=$(date -u -d "$start_date_ww3 +$number_month months +$number_day days" +"%Y-%m-%d")

	# Output the result
	echo "Start date: $start_date_ww3"
	echo "Days to add: $number_day"
	echo "Months to add: $number_month"
	echo "End date: $end_date_ww3"
#	number_endml=$((end_m + 0))
#	number_runlen=$((runlen_month + 0))
#	number_year=$((end_y + 0))
#	input_month=$(( number_endml + number_runlen ))
#	while (( input_month > 12 )); do
#	   input_month=$((input_month - 12))
#	   number_year=$((number_year + 1))
#	done
#	s_input_month="$input_month"
#	if [ ${#s_input_month} -eq 1 ]; then
#	   s_input_month="0$s_input_month"
#	fi
#	end_date_ww3="$number_year-$s_input_month-$end_d"

	start_sec=$(date -u -d "$start_date_ww3" +%s)
	end_sec=$(date -u -d "$end_date_ww3" +%s)
	# Calculate the difference in seconds, then convert to days
	diff_sec=$((end_sec - start_sec))
	diff_days=$((diff_sec / 86400)) # 86400 seconds in a day
	echo "There are $diff_days days $diff_sec seconds between $start_date_ww3 and $end_date_ww3."

	newline_ww3="   $end_y$end_m$end_d 000000  $diff_sec   20231231 000000"
	sed -i "19s/.*/${newline_ww3}/" "ww3_multi.inp"
	cd INPUT/
	rm coupler.res ice_model.res.nc MOM.res_1.nc MOM.res.nc MOM.res_2.nc
	cd ../
	cp RESTART/* INPUT/
	cp RESTART/* res_backup/*
	rm RESTART/*

#	keyword="restart"
#	extension="ww3"
#
#	# Find matching files, sort them using version sort, and get the last one
#	max_file=$(ls *"${keyword}"*.${extension} 2>/dev/null | sort -V | tail -n 1)
#
#	# Check if a file was found
#	if [[ -n "$max_file" ]]; then
#	    echo "File with the maximum number: $max_file"
#	else
#	    echo "No files found matching the pattern *${keyword}*.${extension}"
#	fi
	latest_file=$(ls -t restart0*.ww3 2>/dev/null | head -n 1)

	# Check if a file was found
	if [[ -n "$latest_file" ]]; then
	    echo "The most recent file is: $latest_file"
	else
	    echo "No files matching the pattern restart0*.ww3 were found."
	fi
	cp "$latest_file" "restart.ww3"
	rm restart0*ww3
	JOB_ID=$(sbatch --parsable job_script.sh $i_loop)  # First task with argument "1"
	echo "Submitted Job ID: $JOB_ID for task $i_loop"

	# Monitor the job until it finishes
	while true; do
	    # Check if the job is still in the queue
	    squeue --job $JOB_ID &> /dev/null
	    JOB_EXISTS=$?  # Capture the exit status of squeue
	    if [[ $JOB_EXISTS -ne 0 ]]; then
		# Job is no longer in the queue
		break
	    fi
	    sleep 5  # Check every 5 seconds
	done

	# Check the job completion status using sacct
	JOB_STATE=$(sacct -j $JOB_ID --format=State --noheader | tail -n 1 | awk '{print $1}')
	echo "Job ID $JOB_ID $i_loop has completed with status: $JOB_STATE"

	# Handle job success or failure
	if [[ "$JOB_STATE" == "COMPLETED" ]]; then
	    echo "Task $i_loop Job completed successfully. Proceeding..."
	else
	    echo "Task $i_loop Job failed or was cancelled. Exiting..."
	    exit 1
	fi
	newline_ww3="  $end_y$end_m$end_d 000000  3600.  100000"
	echo "WW3 postProcessing starting at $end_y$end_m$end_d"
	mkdir results
	cd WW3/PostProc
	sed -i "7s/.*/${newline_ww3}/" "ww3_ounf.inp"
	../../../../build/ncrc6.intel23/ww3_ounf/REPRO/ww3_ounf > ../../log.ww3_ounf
	if [[ -e "ww3.$end_y$end_m.nc" && -e "ww3.$end_y${end_m}_usp.nc" ]]; then
	    echo "Task $i_loop ww3 postprocessing profile successfully. Continuing..."
	else
	    echo "Error in Task $i_loop. no files of ww3.$end_y$end_m.nc has been found."

	fi
	mv ww3.$end_y$end_m.nc ww3.$end_y$end_m$end_d.nc
	mv ww3.${end_y}${end_m}_usp.nc ww3.${end_y}${end_m}${end_d}_usp.nc
	cp -rf ww3*nc ../../results/
	cp -rf ww3_ounf.inp ../../results/
	rm ww3.$end_y*nc
	cd ../../
	rm logfile*
	echo -n " $( date +%s )," >> job_timestamp.txt
	  # Zip all results and send it to gfdl archive

	
	cp -rf ${end_y}${end_m}${end_d}*.nc results/
	cp -rf out_grd.ww3 results/
	cp -rf RESTART results/
	cp -rf ocean.stats results/
        cp -rf ocean.stats.nc results/
	cp -rf time_stamp.out results/
	cp -rf input.nml results/
	cp -rf ww3_multi.inp results/
	cp -rf restart0*.ww3 results/
	rm -rf ${end_y}${end_m}${end_d}*.nc
 	mv results ${end_y}${end_m}${end_d}_results
	tar -czf ${end_y}${end_m}${end_d}_results.tar.gz ${end_y}${end_m}${end_d}_results
        gcp -r ${end_y}${end_m}${end_d}_results.tar.gz gfdl:/archive/Qian.Xiao/Qian.Xiao/FMS_Wave_Coupling_ZC/postProcessing/$current_folder/
	if [[ $? -eq 0 ]]; then
	  echo "File transfer was successful."
	else
	  echo "File transfer failed.try to create a folder"
	  mkdir $current_folder
	  cp ${end_y}${end_m}${end_d}_results.tar.gz $current_folder/
	  gcp -r $current_folder gfdl:/archive/Qian.Xiao/Qian.Xiao/FMS_Wave_Coupling_ZC/postProcessing/
	          if [[ $? -eq 0 ]]; then
			  echo "file transfer succedded"
	 	  else
			  echo "file transfer failed even with new filename created"
		 fi
	  rm -rf $current_folder
	fi 
	
	  if [[ -e "./${end_y}${end_m}${end_d}_results.tar.gz" ]]; then
	    echo "Task $i_loop completed successfully with results zipped. Continuing..."
	  else
	    echo "Error in results store for Task $i_loop. Stopping."
	    exit 1
	  fi
	rm -rf ${end_y}${end_m}${end_d}_results

done

echo "Model end:  " `date`
