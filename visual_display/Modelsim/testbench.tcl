# Run this testbench against the ECE241-Project visual_display design.
quit -sim

set bench_dir [pwd]
set project_dir [file normalize [file join $bench_dir .. .. .. .. ECE241-Project visual_display]]
if {![file isfile [file join $bench_dir testbench.v]] ||
    ![file isfile [file join $project_dir visual_display.v]]} {
    # Also support running this macro from the ModelSim project Transcript.
    set bench_dir {C:/Users/sabri/UofT/second_year/ece241/examples/DE1-SoC/object/ModelSim}
    set project_dir {C:/Users/sabri/UofT/second_year/ece241/ECE241-Project/visual_display}
}

set sim_dir [file join $bench_dir visual_display_sim]
file mkdir $sim_dir
cd $sim_dir

# The Intel RAM models generate .ver files next to the MIFs they read.
file mkdir MIF
foreach image {bmp_320_9.mif test_sprite.mif} {
    file copy -force [file join $project_dir MIF $image] [file join MIF $image]
}

set sim_lib [file join $sim_dir work]
if {![file exists [file join $sim_lib _info]]} {
    vlib $sim_lib
}

set vga_dir [file join $project_dir vga_adapter]
vlog -work $sim_lib [file join $project_dir background_mem.v] \
                   [file join $project_dir object_mem.v] \
                   [file join $project_dir visual_display.v] \
                   [file join $vga_dir vga_address_translator.v] \
                   [file join $vga_dir vga_controller.v] \
                   [file join $vga_dir vga_pll.v] \
                   [file join $vga_dir vga_adapter.v] \
                   [file join $bench_dir testbench.v]

vsim -wlf [file join $sim_dir visual_display.wlf] -lib $sim_lib \
     -L 220model -L altera_mf_ver -L verilog testbench
if {![batch_mode]} {
    do [file join $bench_dir wave.do]
}
run 800 ns
