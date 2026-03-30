set script_dir [file normalize [file dirname [info script]]]
set repo_dir [file normalize [file join $script_dir ".."]]
if {[info exists ::env(SERVO_PWM_COMPONENT_XML)] && $::env(SERVO_PWM_COMPONENT_XML) ne ""} {
    set component_xml [file normalize $::env(SERVO_PWM_COMPONENT_XML)]
} else {
    set component_xml [file join $repo_dir "component.xml"]
}
set package_dir [file dirname $component_xml]
set tmp_dir [file join $repo_dir ".ipx_repackage_tmp"]

if {![file exists $component_xml]} {
    puts stderr "ERROR: component.xml not found at $component_xml"
    exit 1
}

if {[file exists $tmp_dir]} {
    file delete -force $tmp_dir
}
file mkdir $tmp_dir

set project_dir [file join $tmp_dir "edit_ip"]
set helper_project_dir [file join $tmp_dir "helper_project"]

puts "INFO: Repackaging IP from $component_xml"

set available_parts [get_parts -quiet]
if {[llength $available_parts] == 0} {
    puts stderr "ERROR: No Vivado parts are available in this installation"
    exit 1
}

set helper_part [lindex $available_parts 0]
create_project -force ipx_repackage_helper $helper_project_dir -part $helper_part

ipx::edit_ip_in_project \
    -name repackage_servo_pwm \
    -directory $project_dir \
    $component_xml

set src_files [lsort [glob -nocomplain [file join $package_dir "src" "*.v"]]]
if {[llength $src_files] == 0} {
    puts stderr "ERROR: No RTL sources found under [file join $package_dir src]"
    close_project -delete
    exit 1
}

foreach src_file $src_files {
    if {[llength [get_files -quiet $src_file]] == 0} {
        add_files -norecurse $src_file
    }
}

update_compile_order -fileset sources_1
set_property top servo_pwm [get_filesets sources_1]

set core [ipx::current_core]
if {$core eq ""} {
    puts stderr "ERROR: No current IP core is open"
    close_project -delete
    exit 1
}

ipx::merge_project_changes files $core
ipx::merge_project_changes ports $core
ipx::merge_project_changes parameters $core
ipx::create_xgui_files $core

set integrity_status [catch {ipx::check_integrity -quiet $core} integrity_result]
if {$integrity_status != 0} {
    puts stderr "ERROR: ipx::check_integrity failed"
    puts stderr $integrity_result
    ipx::save_core $core
    close_project -delete
    exit 1
}

ipx::save_core $core
close_project -delete

file delete -force $tmp_dir

puts "INFO: Repackage complete"
