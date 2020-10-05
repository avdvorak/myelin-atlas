#!/bin/bash

#####################################################################################
# Script functions

# Create our "press_enter function"
function press_enter
{
    echo ""
    echo -n "Press Enter to continue"
    read
    clear
}

# Create a simple method for using comment blocks
[ -z $BASH ] || shopt -s expand_aliases
alias BCOMM="if [ ]; then"
alias ECOMM="fi"

#####################################################################################

if [ "$1" == "-h" ]; then
  echo "------------------------------------------------------------------------------------------------------------------------"
  echo "Pipeline for structural template and quantitative myelin water imaging atlas creation"
  echo ""
  echo -e "Useage to detach and save output: $0 2>&1 | tee Output.txt"
  echo ""
  echo " NOTE: "
  echo " - Currently FOR loops over all 100 subjects from C001 to C100 "
  echo " - Switch commented FOR loops to run only specific subjects, if desired"
  echo " - Move the BCOMM and ECOMM comment blocks to run one section at a time"
  echo ""
  echo " Written by Adam Dvorak (09/2019) for"
  echo "        An atlas for human brain myelin content throughout the adult life span"
  echo ""
  echo "------------------------------------------------------------------------------------------------------------------------"
  exit 0
fi


###############  SETUP SUBJECTS

# Specify subset of subjects to process, if desired
subjects=' C001 C002 '

###############  SETUP PATHS

# Set the generic input path
inputPath='/local/atlas/Adam/grase48_atlas'
# Set the path to OASIS template
oasisPath='/local/atlas/OASIS'
# Set the path to QC
qcPath=${inputPath}/QualityControl
# Set path for template to be created in
templatePath=${inputPath}/Template
# Cores to use for general processing
cores=21


BCOMM
##################################################################################### Prep 3DT1
# for subject in ${subjects} # For loop over subject specified above
for subject in $(seq -f "C%03g" 1 100) # For loop over all 100 subjects
do
  # Change into the subject folder
  cd ${inputPath}/${subject}/3DT1/

  # start the timer
  timer_start="$(date +"Date : %d/%m/%Y Time : %H.%M.%S")"
  printf " \n Beginning ${subject} 3DT1 Preparation at: \n ${timer_start} \n "

  # N4 correction
  N4BiasFieldCorrection \
    -d 3 \
    -i ${subject}_3DT1.nii.gz \
    -o ${subject}_3DT1_N4.nii.gz \
    -v 0
  printf " \n ${subject} N4 Correction Complete \n "


  # Brain extraction
  antsBrainExtraction.sh \
    -d 3 \
    -k 1 \
    -z 0 \
    -c 3x1x2x3 \
    -a ${subject}_3DT1_N4.nii.gz \
    -e ${oasisPath}/T_template0.nii.gz \
    -m ${oasisPath}/T_template0_BrainCerebellumProbabilityMask.nii.gz \
    -f ${oasisPath}/T_template0_BrainCerebellumRegistrationMask.nii.gz \
    -o ${inputPath}/${subject}/3DT1/${subject}_3DT1_N4

  printf " \n ${subject} Brain Extraction Complete \n "

  # Clean up extra output
  rm *Warp.* *Affine* *Tmp.* *0.*

  printf " \n Creating ${subject} Brain Extraction Quality Control Images "
  # create mask
  ThresholdImage 3 ${subject}_3DT1_N4BrainExtractionSegmentation.nii.gz segmentationMask.nii.gz 0 0 0 1
  # create RGB from segmentation
  ConvertScalarImageToRGB 3 ${subject}_3DT1_N4BrainExtractionSegmentation.nii.gz segmentationRgb.nii.gz none custom ${qcPath}/snapColormap.txt 0 6

  # create tiled mosaic in each orientation
  for dim in 0 1 2
  do
    printf " ${dim} \n "
    printf "${qcPath}/3DT1_BE/${subject}_${dim}.png "
    CreateTiledMosaic -i ${subject}_3DT1_N4.nii.gz -r segmentationRgb.nii.gz -o ${qcPath}/3DT1_BE/${subject}_${dim}.png -a 0.3 -t -1x-1 -p mask -s [3,mask,mask] -x segmentationMask.nii.gz -d ${dim}
  done

  # stop the timer
  timer_stop="$(date +"Date : %d/%m/%Y Time : %H.%M.%S")"
  printf " \n \n ${subject} 3DT1 Preparation Complete \n Started: \n ${timer_start} \n Finished: \n ${timer_stop} \n \n "

done
#####################################################################################


##################################################################################### Prep GRASE
# for subject in ${subjects} # For loop over subject specified above
for subject in $(seq -f "C%03g" 1 100) # For loop over all 100 subjects
do
  # Change into the subject folder
  cd ${inputPath}/${subject}/GRASE/

  # start the timer
  timer_start="$(date +"Date : %d/%m/%Y Time : %H.%M.%S")"
  printf " \n Beginning ${subject} GRASE Preparation at: \n ${timer_start} \n "

  # Grab echo 1
  fsl5.0-fslroi \
    ${subject}_GRASE.nii.gz \
    ${subject}_GRASE_E1.nii.gz \
    0 1

  # N4 correction
  N4BiasFieldCorrection \
    -d 3 \
    -v 0 \
    -i ${subject}_GRASE_E1.nii.gz \
    -o ${subject}_GRASE_E1_N4.nii.gz
  printf " \n ${subject} N4 Correction Complete \n "

  # Take echo1 to power of 2 to replicate T1 weighting
  fsl5.0-fslmaths \
    ${subject}_GRASE_E1_N4.nii.gz \
    -sqr ${subject}_GRASE_E1_N4_T1rep.nii.gz

  # Brain Extract GRASE 
  antsBrainExtraction.sh \
    -d 3 \
    -k 1 \
    -z 0 \
    -c 3x1x2x3 \
    -a ${subject}_GRASE_E1_N4_T1rep.nii.gz \
    -e ${oasisPath}/T_template0.nii.gz \
    -m ${oasisPath}/T_template0_BrainCerebellumProbabilityMask.nii.gz \
    -f ${oasisPath}/T_template0_BrainCerebellumRegistrationMask.nii.gz \
    -o ${inputPath}/${subject}/GRASE/${subject}_GRASE_E1_N4_T1rep

  # Clean up extra output
  rm *Warp.* *Affine* *Tmp.* *0.*

  printf " \n Creating ${subject} Brain Extraction Quality Control Images "

  # create mask
  ThresholdImage 3 ${subject}_GRASE_E1_N4_T1repBrainExtractionMask.nii.gz segmentationMask.nii.gz 0 0 0 1
  # create RGB from segmentation
  ConvertScalarImageToRGB 3 ${subject}_GRASE_E1_N4_T1repBrainExtractionMask.nii.gz segmentationRgb.nii.gz none custom ${qcPath}/snapColormap.txt 0 6 

  # create tiled mosaic in each orientation
  CreateTiledMosaic -i ${subject}_GRASE_E1_N4_T1rep.nii.gz -r segmentationRgb.nii.gz -o ${qcPath}/GRASE_BE/${subject}.png -a 0.3 -t -1x-1 -d 2 -p mask -s [1,mask,mask] -x segmentationMask.nii.gz -d 2

  # stop the timer
  timer_stop="$(date +"Date : %d/%m/%Y Time : %H.%M.%S")"
  printf " \n \n ${subject} GRASE Preparation Complete \n Started: \n ${timer_start} \n Finished: \n ${timer_stop} \n \n "

done
#####################################################################################


##################################################################################### GRASE <-> 3DT1 Registration
# for subject in ${subjects} # For loop over subject specified above
for subject in $(seq -f "C%03g" 1 100) # For loop over all 100 subjects
do

  # start the timer
  timer_start="$(date +"Date : %d/%m/%Y Time : %H.%M.%S")"
  printf " \n Beginning ${subject} GRASE <-> 3DT1 Registration: \n ${timer_start} \n "

  # Change into the subject folder
  cd ${inputPath}/${subject}/GRASE/

  # Create more generous mask with CSF
  fsl5.0-fslmaths \
    ${subject}_GRASE_E1_N4_T1repBrainExtractionMask.nii.gz \
    -max ${subject}_GRASE_E1_N4_T1repBrainExtractionCSF.nii.gz \
    -fillh ${subject}_GRASE_E1_N4_T1repBrainExtractionMaskwCSF.nii.gz

  # apply mask to GRASE N4 (to be registered)
  fsl5.0-fslmaths \
    ${subject}_GRASE_E1_N4.nii.gz \
    -mas ${subject}_GRASE_E1_N4_T1repBrainExtractionMaskwCSF.nii.gz \
    ${subject}_GRASE_E1_N4_Brain.nii.gz

  # Change dir
  cd ${inputPath}/${subject}/3DT1/

  # Register
  antsRegistrationSyN.sh \
    -d 3 \
    -f ${subject}_3DT1_N4BrainExtractionBrain.nii.gz \
    -m ${inputPath}/${subject}/GRASE/${subject}_GRASE_E1_N4_Brain.nii.gz \
    -t r \
    -z 1 \
    -j 0 \
    -p d \
    -n ${cores} \
    -x ${subject}_3DT1_N4BrainExtractionMask.nii.gz \
    -o ${subject}_GRASE_E1_N4_Brain

  # apply sharper 3DT1 mask to warped GRASE
  fsl5.0-fslmaths \
    ${subject}_GRASE_E1_N4_BrainWarped.nii.gz \
    -mas ${subject}_3DT1_N4BrainExtractionMask.nii.gz \
    ${subject}_GRASE_E1_N4_BrainWarpedMasked.nii.gz

  printf " \n Creating ${subject} GRASE <-> 3DT1 Registration Quality Control Images "

    # create mask
  ThresholdImage 3 ${subject}_3DT1_N4BrainExtractionMask.nii.gz segmentationMask_wholebrain.nii.gz 0 0 0 1
  # create RGB from segmentation
  # ConvertScalarImageToRGB 3 ${subject}_GRASE_E1_N4_T1repBrainExtractionMask.nii.gz segmentationRgb_wholebrain.nii.gz none custom ${qcPath}/snapColormap.txt 0 6 

  for dim in 0 1 2
  do
    # create 3DT1 tiled mosaic
    CreateTiledMosaic -i ${subject}_3DT1_N4BrainExtractionBrain.nii.gz -r segmentationRgb.nii.gz -a 0.0 -o ${qcPath}/GRASE_3DT1_Reg/${subject}_${dim}_3DT1.png -t -1x-1 -d ${dim} -p mask -s [4,mask+39,mask] -x segmentationMask_wholebrain.nii.gz

    # create GRASE tiled mosaic
    CreateTiledMosaic -i ${subject}_GRASE_E1_N4_BrainWarpedMasked.nii.gz -r segmentationRgb.nii.gz -a 0.0 -o ${qcPath}/GRASE_3DT1_Reg/${subject}_${dim}_GRASE.png -t -1x-1 -d ${dim} -p mask -s [4,mask+39,mask] -x segmentationMask_wholebrain.nii.gz
  done

  # stop the timer
  timer_stop="$(date +"Date : %d/%m/%Y Time : %H.%M.%S")"
  printf " \n \n ${subject} GRASE <-> 3DT1 Registration Complete \n Started: \n ${timer_start} \n Finished: \n ${timer_stop} \n \n "

done
#####################################################################################
ECOMM


BCOMM
##################################################################################### TEMPLATE CREATION

############### Prep all 3DT1 in template creation directory

# for subject in ${subjects} # For loop over subject specified above
for subject in $(seq -f "C%03g" 1 100) # For loop over all 100 subjects
do
  cp ${inputPath}/${subject}/3DT1/${subject}_3DT1_N4BrainExtractionBrain.nii.gz ${templatePath}/${subject}_3DT1.nii.gz
done


###############  MAKE TEMPLATE: With 3DT1 (brain extracted)

# Print date and time that template creation begins
printf " \n \n \n \n BEGINNING TEMPLATE CREATION \n \n \n \n "
date +"Date : %d/%m/%Y Time : %H.%M.%S"
printf "  \n \n \n \n "

cd ${templatePath}/

${ANTSPATH}/antsMultivariateTemplateConstruction2.sh \
  -d 3 \
  -o ${templatePath}/T_ \
  -i 4 \
  -g 0.2 \
  -b 1 \
  -e 1 \
  -c 2 \
  -j 21 \
  -k 1 \
  -w 1 \
  -f 6x4x2x1 \
  -s 3x2x1x0 \
  -q 140x120x100x100 \
  -n 1 \
  -a 1 \
  -y 1 \
  -r 1 \
  -m CC[2] \
  -l 1 \
  -t SyN \
  templateInput.csv
###############

# Print date and time that template creation finishes
printf " \n \n \n \n COMPLETED TEMPLATE CREATION \n \n \n \n "
date +"Date : %d/%m/%Y Time : %H.%M.%S"
printf "  \n \n \n \n "

#####################################################################################
ECOMM



BCOMM
######################################   MWI ANALYSIS 
# Can be done before or after template creation
# Request code at:   https://mriresearch.med.ubc.ca/news-projects/myelin-water-fraction/

# for subject in ${subjects} # For loop over subject specified above
for subject in $(seq -f "C%03g" 1 100) # For loop over all 100 subjects
do
  # start the timer
  timer_start="$(date +"Date : %d/%m/%Y Time : %H.%M.%S")"
  printf " \n Beginning ${subject} MWI Analysis at: \n ${timer_start} \n "
  # analyze  
  grase48_MWI_analysis.sh ${subject}
done

######################################
ECOMM



BCOMM
#####################################################################################

###############  Prep Maps in template space for MWF template creation

# Make life easier (wildcard to grab correct warps)
cd ${templatePath}/
mkdir Inverse_Warps
mv *Inverse* Inverse_Warps/

# for subject in ${subjects} # For loop over subject specified above
for subject in $(seq -f "C%03g" 1 100) # For loop over all 100 subjects
do

  cd ${inputPath}/${subject}/MWI
  # zip all 
  gzip *.nii
  for image in E1_N4 MWF IET2 MYELT2
  do
    # Mask using the GRASE brain mask
    fsl5.0-fslmaths \
      ${subject}_GRASE_${image}.nii.gz \
      -mas ${subject}_GRASE_E1_N4_T1repBrainExtractionMaskwCSF.nii.gz \
      ${subject}_${image}_Masked.nii.gz

    # Now warp to 3DT1 space using the previous registration (affine only)
    antsApplyTransforms \
      -d 3 \
      -i ${subject}_${image}_Masked.nii.gz \
      -r ${inputPath}/${subject}/3DT1/${subject}_3DT1_N4BrainExtractionBrain.nii.gz \
      -t ${inputPath}/${subject}/3DT1/${subject}_GRASE_E1_N4_Brain0GenericAffine.mat \
      -o ${subject}_${image}_Masked_3DT1Warped.nii.gz

    # Now mask out the MWF brain using the better 3DT1 brain mask
    fsl5.0-fslmaths \
      ${subject}_${image}_Masked_3DT1Warped.nii.gz \
      -mas ${inputPath}/${subject}/3DT1/${subject}_3DT1_N4BrainExtractionMask.nii.gz \
      ${subject}_${image}_Masked_3DT1Warped_3DT1Masked.nii.gz

    # Now actually warp the masked images to template space
    antsApplyTransforms \
      -d 3 \
      -i ${subject}_${image}_Masked_3DT1Warped_3DT1Masked.nii.gz \
      -r ${templatePath}/T_template0.nii.gz \
      -t ${templatePath}/T_${subject}_3DT1*Warp.nii.gz \
      -t ${templatePath}/T_${subject}_3DT1*GenericAffine.mat \
      -o ${templatePath}/${subject}_${image}_WarpedToTemplate.nii.gz

    # Print that this subject is finished
    printf " \n \n \n \n COMPLETED ${subject}  ${image} \n \n \n \n "
  done
done
#####################################################################################
ECOMM

BCOMM
#####################################################################################

for image in MWF IET2
do

  cd ${templatePath}/
  # sort
  mkdir ${image}
  mv ${templatePath}/C*${image}*_WarpedToTemplate.nii.gz ${templatePath}/${image}/
  cd ${templatePath}/${image}/
  
  # Merge all MWF maps into a 4D volume
  # NOTE: Redone with 2 incidental findings excluded
  fsl5.0-fslmerge \
    -t ${image}_merged.nii.gz \
    C*${image}*_WarpedToTemplate.nii.gz

  # Calculate standard deviation map
  fsl5.0-fslmaths \
    ${image}_merged.nii.gz \
    -Tstd ${image}_stddev.nii.gz

  # Calculate mean map
  fsl5.0-fslmaths \
    ${image}_merged.nii.gz \
    -Tmean ${image}_mean.nii.gz

  # Calculate median map
  fsl5.0-fslmaths \
    ${image}_merged.nii.gz \
    -Tmedian ${image}_median.nii.gz

  # Calculate COV map
  fsl5.0-fslmaths \
    ${image}_stddev.nii.gz \
    -div ${image}_mean.nii.gz \
    ${image}_cov.nii.gz
done

#####################################################################################
ECOMM






