##############################################################################
## Design Setup
##############################################################################
set DESIGN risc_cpu

# Output folder
set _OUTPUTS_PATH "./outputs"
file mkdir $_OUTPUTS_PATH

##############################################################################
## Library Setup
##############################################################################
set LIB_PATH "/home/cc01group8/vlsi/2252190/work/synthesis_env/Genus_BoundFlasher/LIB/"
set LEF_PATH "/home/cc01group8/vlsi/2252190/work/synthesis_env/Genus_BoundFlasher/LEF/"

# Load .lib (timing)
set_db library [glob $LIB_PATH/*.lib]

# Load .lef (physical - optional nhưng nên có)
set_db lef_library [glob $LEF_PATH/*.lef]

##############################################################################
## Load Design
##############################################################################
read_hdl "src.v"
elaborate $DESIGN

##############################################################################
## Constraints
##############################################################################
read_sdc risc_cpu.sdc

##############################################################################
## Synthesis Flow (Genus NEW FLOW)
##############################################################################
syn_gen
syn_map
syn_opt

##############################################################################
## Reports (QUAN TRỌNG cho report)
##############################################################################

# QoR 
report_qor > ${_OUTPUTS_PATH}/qor.rpt

# Timing / Area / Power
report_timing > ${_OUTPUTS_PATH}/timing.rpt
report_area   > ${_OUTPUTS_PATH}/area.rpt
report_power  > ${_OUTPUTS_PATH}/power.rpt

# Netlist analysis (bonus ăn điểm)
report_cell        > ${_OUTPUTS_PATH}/cell.rpt
report_hierarchy   > ${_OUTPUTS_PATH}/hierarchy.rpt
report_instance    > ${_OUTPUTS_PATH}/instance.rpt

##############################################################################
## Output Netlist
##############################################################################
write_hdl > ${_OUTPUTS_PATH}/${DESIGN}_m.v

##############################################################################
## Done
##############################################################################
quit