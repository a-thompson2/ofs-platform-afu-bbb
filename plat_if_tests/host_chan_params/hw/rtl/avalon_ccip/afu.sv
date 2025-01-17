// Copyright (C) 2022 Intel Corporation
// SPDX-License-Identifier: MIT

`include "ofs_plat_if.vh"

module afu
  #(
    parameter AFU_INSTANCE_ID = 0,
    parameter NUM_PORTS_G1 = 0,
    parameter NUM_PORTS_G2 = 0
    )
   (
`ifdef TEST_PARAM_IFC_CCIP
    // Host memory CCI-P
    ofs_plat_host_ccip_if.to_fiu host_mem_if,
    // Zero length is illegal -- force minimum size 1 dummy entry
    ofs_plat_host_ccip_if.to_fiu host_mem_g1_if[NUM_PORTS_G1 > 0 ? NUM_PORTS_G1 : 1],
    ofs_plat_host_ccip_if.to_fiu host_mem_g2_if[NUM_PORTS_G2 > 0 ? NUM_PORTS_G2 : 1],
`endif
`ifdef TEST_PARAM_IFC_AVALON
    // Host memory (Avalon)
    ofs_plat_avalon_mem_rdwr_if.to_sink host_mem_if,
    // Zero length is illegal -- force minimum size 1 dummy entry
    ofs_plat_avalon_mem_rdwr_if.to_sink host_mem_g1_if[NUM_PORTS_G1 > 0 ? NUM_PORTS_G1 : 1],
    ofs_plat_avalon_mem_rdwr_if.to_sink host_mem_g2_if[NUM_PORTS_G2 > 0 ? NUM_PORTS_G2 : 1],
`endif

    // Events, used for tracking latency through the FIM
    host_chan_events_if.engine host_chan_events_if,
    host_chan_events_if.engine host_chan_g1_events_if[NUM_PORTS_G1 > 0 ? NUM_PORTS_G1 : 1],
    host_chan_events_if.engine host_chan_g2_events_if[NUM_PORTS_G2 > 0 ? NUM_PORTS_G2 : 1],

    // FPGA MMIO source (Avalon)
    ofs_plat_avalon_mem_if.to_source mmio64_if,

    // pClk is used to compute the frequency of the AFU's clk, since pClk
    // is a known frequency.
    input  logic pClk,

    // AFU Power State
    input  t_ofs_plat_power_state pwrState
    );

    localparam NUM_PORTS_G0 = 1;
    localparam NUM_ENGINES = NUM_PORTS_G0 + NUM_PORTS_G1 + NUM_PORTS_G2;

    engine_csr_if eng_csr_glob();
    engine_csr_if eng_csr[NUM_ENGINES]();


    // ====================================================================
    //
    //  Global CSRs (mostly to tell SW about the AFU configuration)
    //
    // ====================================================================

    // Test UUID. Multiple tests may share an AFU UUID and are differentiated
    // with test IDs.
`ifdef TEST_PARAM_IFC_CCIP
    logic [127:0] test_id = 128'hc5ebd585_4b1e_4e3e_a53f_fda6b7b340da;
`endif
`ifdef TEST_PARAM_IFC_AVALON
    logic [127:0] test_id = 128'h04babb2e_4498_48bf_8d94_59dce56eb1d4;
`endif

    always_comb
    begin
        eng_csr_glob.rd_data[0] = test_id[63:0];
        eng_csr_glob.rd_data[1] = test_id[127:64];
        eng_csr_glob.rd_data[2] = { 32'd0,
                                    8'(AFU_INSTANCE_ID),
                                    8'(NUM_PORTS_G2),
                                    8'(NUM_PORTS_G1),
                                    8'(NUM_PORTS_G0) };

        for (int e = 3; e < eng_csr_glob.NUM_CSRS; e = e + 1)
        begin
            eng_csr_glob.rd_data[e] = 64'(0);
        end

        // This signal means nothing
        eng_csr_glob.status_active = 1'b0;
    end


    // ====================================================================
    //
    //  Engines (one per host memory port)
    //
    // ====================================================================

    genvar p;
    generate
        // Group 0 engine
`ifdef TEST_PARAM_IFC_CCIP
        host_mem_rdwr_engine_ccip
`else
        host_mem_rdwr_engine_avalon
`endif
          #(
`ifdef OFS_PLAT_PARAM_HOST_CHAN_ADDRESS_SPACE
            .ADDRESS_SPACE(`OFS_PLAT_PARAM_HOST_CHAN_ADDRESS_SPACE),
`endif
            .ENGINE_NUMBER(0),
            .ENGINE_GROUP(0)
            )
          eng
            (
             .host_mem_if(host_mem_if),
             .host_chan_events_if(host_chan_events_if),
             .csrs(eng_csr[0])
             );

        // Group 1 engines follow group 0
        for (p = 0; p < NUM_PORTS_G1; p = p + 1)
        begin : g1
`ifdef TEST_PARAM_IFC_CCIP
            host_mem_rdwr_engine_ccip
`else
            host_mem_rdwr_engine_avalon
`endif
              #(
`ifdef OFS_PLAT_PARAM_HOST_CHAN_G1_IS_NATIVE_AVALON
                // Simple Avalon ports don't support write fences
                .WRITE_FENCE_SUPPORTED(0),
`endif
`ifdef OFS_PLAT_PARAM_HOST_CHAN_G1_ADDRESS_SPACE
                .ADDRESS_SPACE(`OFS_PLAT_PARAM_HOST_CHAN_G1_ADDRESS_SPACE),
`endif
                .ENGINE_NUMBER(NUM_PORTS_G0 + p),
                .ENGINE_GROUP(1)
                )
              eng
               (
                .host_mem_if(host_mem_g1_if[p]),
                .host_chan_events_if(host_chan_g1_events_if[p]),
                .csrs(eng_csr[NUM_PORTS_G0 + p])
                );
        end

        // Group 2 engines follow group 1
        for (p = 0; p < NUM_PORTS_G2; p = p + 1)
        begin : g2
`ifdef TEST_PARAM_IFC_CCIP
            host_mem_rdwr_engine_ccip
`else
            host_mem_rdwr_engine_avalon
`endif
              #(
`ifdef OFS_PLAT_PARAM_HOST_CHAN_G2_IS_NATIVE_AVALON
                // Simple Avalon ports don't support write fences
                .WRITE_FENCE_SUPPORTED(0),
`endif
`ifdef OFS_PLAT_PARAM_HOST_CHAN_G2_ADDRESS_SPACE
                .ADDRESS_SPACE(`OFS_PLAT_PARAM_HOST_CHAN_G2_ADDRESS_SPACE),
`endif
                .ENGINE_NUMBER(NUM_PORTS_G0 + NUM_PORTS_G1 + p),
                .ENGINE_GROUP(2)
                )
              eng
               (
                .host_mem_if(host_mem_g2_if[p]),
                .host_chan_events_if(host_chan_g2_events_if[p]),
                .csrs(eng_csr[NUM_PORTS_G0 + NUM_PORTS_G1 + p])
                );
        end
    endgenerate


    // ====================================================================
    //
    //  Instantiate control via CSRs
    //
    // ====================================================================

    csr_mgr
      #(
        .NUM_ENGINES(NUM_ENGINES),
        .MMIO_ADDR_WIDTH(mmio64_if.ADDR_WIDTH)
        )
      csr_mgr
       (
        .clk(mmio64_if.clk),
        .reset_n(mmio64_if.reset_n),
        .pClk,

        .wr_write(mmio64_if.write),
        .wr_address(mmio64_if.address),
        .wr_writedata(mmio64_if.writedata),

        .rd_read(mmio64_if.read),
        .rd_address(mmio64_if.address),
        .rd_tid_in('x),
        .rd_readdatavalid(mmio64_if.readdatavalid),
        .rd_readdata(mmio64_if.readdata),
        .rd_tid_out(),

        .eng_csr_glob,
        .eng_csr
        );

    assign mmio64_if.response = 2'b0;
    assign mmio64_if.waitrequest = 1'b0;

endmodule // afu
