## Generated by import_user_clk_sdc.tcl during BBS build

##
## Global namespace for defining some static properties of user clocks,
## used by other user clock management scripts.
##
namespace eval userClocks {
    variable u_clkdiv2_name {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_iopll_u0|iopll_0_outclk1}
    variable u_clk_name {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_iopll_u0|iopll_0_outclk0}
    variable u_clkdiv2_fmax 600
    variable u_clk_fmax 600
}

##
## Constrain the user clocks given a list of targets, ordered low to high.
##   (The code assumes that the relative values of the low and high clocks
##   are legal and treats them independently.)
##
proc constrain_user_clks { u_clks } {
    global ::userClocks

    set u_clk_low_mhz [lindex $u_clks 0]
    set u_clk_high_mhz [lindex $u_clks 1]

    if {$u_clk_high_mhz > $::userClocks::u_clk_fmax} {
        set u_clk_high_mhz $::userClocks::u_clk_fmax
    }
    set mult_high [expr {int(ceil(20.0 * $u_clk_high_mhz))}]
    create_generated_clock -name {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_iopll_u0|iopll_0_outclk0} -source [get_registers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_iopll_u0|iopll_0|stratix10_altera_iopll_i|s10_iopll.fourteennm_pll~ncntr_reg}] -multiply_by ${mult_high} -divide_by 1000 -master_clock {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_iopll_u0|iopll_0_n_cnt_clk} [get_pins {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_iopll_u0|iopll_0|stratix10_altera_iopll_i|s10_iopll.fourteennm_pll|outclk[0]}]

    if {$u_clk_low_mhz > $::userClocks::u_clkdiv2_fmax} {
        set u_clk_low_mhz $::userClocks::u_clkdiv2_fmax
    }
    set mult_low [expr {int(ceil(20.0 * $u_clk_low_mhz))}]
    create_generated_clock -name {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_iopll_u0|iopll_0_outclk1} -source [get_registers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_iopll_u0|iopll_0|stratix10_altera_iopll_i|s10_iopll.fourteennm_pll~ncntr_reg}] -multiply_by ${mult_low} -divide_by 1000 -master_clock {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_iopll_u0|iopll_0_n_cnt_clk} [get_pins {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_iopll_u0|iopll_0|stratix10_altera_iopll_i|s10_iopll.fourteennm_pll|outclk[1]}]
}
