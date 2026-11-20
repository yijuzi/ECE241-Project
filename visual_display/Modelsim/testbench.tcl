quit -sim

file mkdir MIF
file copy -force ../MIF/bmp_320_9.mif ../MIF/test_sprite.mif ../MIF/test_sprite2.mif MIF

if {![file exists work/_info]} {
    vlib work
}

vlog -work work ../visual_display.v ../object_mem.v ../background_mem.v \
    ../vga_adapter/vga_adapter.v ../vga_adapter/vga_controller.v \
    ../vga_adapter/vga_address_translator.v ../vga_adapter/vga_pll.v \
    testbench.v

vsim -L 220model -L altera_mf_ver -L verilog work.testbench
do wave.do
run 800 ns