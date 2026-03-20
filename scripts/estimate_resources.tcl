set repo_dir [file normalize [file join [file dirname [info script]] ".."]]
set part_name "xc7z020clg400-1"
set rpt_file [file join $repo_dir "resource_estimate.rpt"]

create_project -in_memory util_estimate -part $part_name
add_files [list \
    [file join $repo_dir "src/servo_pwm_io_pin.v"] \
    [file join $repo_dir "src/servo_pwm_ch.v"] \
    [file join $repo_dir "src/servo_pwm_gen.v"] \
    [file join $repo_dir "src/servo_pwm_slave_lite_v1_1_S00_AXI.v"] \
    [file join $repo_dir "src/servo_pwm.v"] \
]
set_property top servo_pwm [current_fileset]

synth_design -top servo_pwm -mode out_of_context -part $part_name
report_utilization -file $rpt_file

puts "Wrote utilization report to $rpt_file"
