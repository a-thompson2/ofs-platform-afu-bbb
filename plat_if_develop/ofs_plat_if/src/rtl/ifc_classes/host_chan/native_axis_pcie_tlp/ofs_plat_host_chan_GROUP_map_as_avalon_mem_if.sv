//
// Copyright (c) 2020, Intel Corporation
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of the Intel Corporation nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.


//
// Map PCIe TLPs to an Avalon memory interface.
//

`include "ofs_plat_if.vh"


// The TLP mapper has multiple request/response AXI streams. Define a macro
// that instantiates a stream "instance_name" of "data_type" and assigns
// standard clock, reset and debug info.
`define AXI_STREAM_INSTANCE(instance_name, data_type) \
    ofs_plat_axi_stream_if \
      #( \
        .TDATA_TYPE(data_type), \
        .TUSER_TYPE(logic) /* Unused */ \
        ) \
      instance_name(); \
    assign instance_name.clk = clk; \
    assign instance_name.reset_n = reset_n; \
    assign instance_name.instance_number = to_fiu_tlp.instance_number


module ofs_plat_host_chan_@group@_map_as_avalon_mem_if
  #(
    parameter USER_ROB_IDX_START = 0
    )
   (
    ofs_plat_host_chan_@group@_axis_pcie_tlp_if to_fiu_tlp,
    ofs_plat_avalon_mem_rdwr_if.to_master mem_master,
    ofs_plat_avalon_mem_if.to_slave mmio_slave,

    // A second, write-only MMIO slave. If used, an AFU will likely use
    // this interface to receive wide MMIO writes without also having to
    // build wide MMIO read channels.
    ofs_plat_avalon_mem_if.to_slave mmio_wo_slave
    );

    import ofs_plat_host_chan_@group@_pcie_tlp_pkg::*;
    import ofs_plat_host_chan_@group@_gen_tlps_pkg::*;

    logic clk;
    assign clk = to_fiu_tlp.clk;
    logic reset_n;
    assign reset_n = to_fiu_tlp.reset_n;


    // ====================================================================
    //
    //  Forward all memory and MMIO channels through skid buffers for
    //  channel synchronization and timing.
    //
    // ====================================================================

    //
    // Host memory
    //

    ofs_plat_avalon_mem_rdwr_if
      #(
        `OFS_PLAT_AVALON_MEM_RDWR_IF_REPLICATE_PARAMS(mem_master)
        )
      mem_if();

    assign mem_if.clk = clk;
    assign mem_if.reset_n = reset_n;
    assign mem_if.instance_number = to_fiu_tlp.instance_number;

    ofs_plat_avalon_mem_rdwr_if_skid mem_skid
       (
        .mem_master,
        .mem_slave(mem_if)
        );

    //
    // MMIO
    //

    ofs_plat_avalon_mem_if
      #(
        `OFS_PLAT_AVALON_MEM_IF_REPLICATE_PARAMS(mmio_slave)
        )
      mmio_if();

    assign mmio_if.clk = clk;
    assign mmio_if.reset_n = reset_n;
    assign mmio_if.instance_number = to_fiu_tlp.instance_number;

    ofs_plat_avalon_mem_if_skid mmio_skid
       (
        .mem_slave(mmio_slave),
        .mem_master(mmio_if)
        );

    // Second (write-only) MMIO interface
    ofs_plat_avalon_mem_if
      #(
        `OFS_PLAT_AVALON_MEM_IF_REPLICATE_PARAMS(mmio_wo_slave)
        )
      mmio_wo_if();

    assign mmio_wo_if.clk = clk;
    assign mmio_wo_if.reset_n = reset_n;
    assign mmio_wo_if.instance_number = to_fiu_tlp.instance_number;

    ofs_plat_avalon_mem_if_skid
      #(
        .REG_RSP(0)
        )
      mmio_wo_skid
       (
        .mem_slave(mmio_wo_slave),
        .mem_master(mmio_wo_if)
        );


    // ====================================================================
    //
    //  MMIO requests from host
    //
    // ====================================================================

    // MMIO requests from host to AFU (t_gen_tx_mmio_afu_req)
    `AXI_STREAM_INSTANCE(host_mmio_req, t_gen_tx_mmio_afu_req);

    localparam MMIO_ADDR_WIDTH = mmio_slave.ADDR_WIDTH_;
    typedef logic [MMIO_ADDR_WIDTH-1 : 0] t_mmio_addr;
    localparam MMIO_DATA_WIDTH = mmio_slave.DATA_WIDTH_;
    typedef logic [MMIO_DATA_WIDTH-1 : 0] t_mmio_data;

    localparam MMIO_WO_ADDR_WIDTH = mmio_wo_slave.ADDR_WIDTH_;
    typedef logic [MMIO_WO_ADDR_WIDTH-1 : 0] t_mmio_wo_addr;
    localparam MMIO_WO_DATA_WIDTH = mmio_wo_slave.DATA_WIDTH_;
    typedef logic [MMIO_WO_DATA_WIDTH-1 : 0] t_mmio_wo_data;

    // Index of the minimum addressable size (32 bit DWORD)
    localparam MMIO_DWORDS = MMIO_DATA_WIDTH / 32;
    localparam MMIO_DWORD_IDX_BITS = $clog2(MMIO_DWORDS);
    typedef logic [MMIO_DWORD_IDX_BITS-1 : 0] t_mmio_dword_idx;

    localparam MMIO_DATA_WIDTH_LEGAL =
        (MMIO_DATA_WIDTH >= 64) && (MMIO_DATA_WIDTH <= 512) &&
        (MMIO_DATA_WIDTH == (2 ** $clog2(MMIO_DATA_WIDTH)));
    localparam MMIO_WO_DATA_WIDTH_LEGAL =
        (MMIO_WO_DATA_WIDTH >= 64) && (MMIO_WO_DATA_WIDTH <= 512) &&
        (MMIO_WO_DATA_WIDTH == (2 ** $clog2(MMIO_WO_DATA_WIDTH)));

    // synthesis translate_off
    initial
    begin
        if (! MMIO_DATA_WIDTH_LEGAL)
            $fatal(2, "** ERROR ** %m: MMIO data width (%0d) must be a power of 2 between 64 and 512.", MMIO_DATA_WIDTH);
        if (! MMIO_WO_DATA_WIDTH_LEGAL)
            $fatal(2, "** ERROR ** %m: MMIO write-only data width (%0d) must be a power of 2 between 64 and 512.", MMIO_WO_DATA_WIDTH);
    end
    // synthesis translate_on

    // We must be ready to accept either an MMIO write or read, without knowing which.
    assign host_mmio_req.tready = MMIO_DATA_WIDTH_LEGAL &&
                                  !mmio_if.waitrequest &&
                                  !mmio_wo_if.waitrequest;

    // MMIO requests
    assign mmio_if.read  = host_mmio_req.tready && host_mmio_req.tvalid &&
                           !host_mmio_req.t.data.is_write;
    assign mmio_if.write = host_mmio_req.tready && host_mmio_req.tvalid &&
                           host_mmio_req.t.data.is_write &&
                           (host_mmio_req.t.data.byte_count <= (MMIO_DATA_WIDTH / 8));

    assign mmio_if.address = host_mmio_req.t.data.addr[$clog2(MMIO_DATA_WIDTH/8) +: MMIO_ADDR_WIDTH];
    assign mmio_if.burstcount = '1;
    assign mmio_if.user = '0;

    // Reformat MMIO write data and mask for Avalon
    ofs_plat_host_chan_mmio_wr_data_comb
      #(
        .DATA_WIDTH(MMIO_DATA_WIDTH)
        )
      mmio_data
       (
        .byte_addr(host_mmio_req.t.data.addr),
        .byte_count(host_mmio_req.t.data.byte_count),
        .payload_in(MMIO_DATA_WIDTH'(host_mmio_req.t.data.payload)),

        .payload_out(mmio_if.writedata),
        .byte_mask(mmio_if.byteenable)
        );

    // Record read tag and address details. Responses will be returned in order,
    // so a FIFO is sufficient.
    t_mmio_rd_tag mmio_rd_tag;
    t_mmio_dword_idx mmio_rd_dword_idx;

    ofs_plat_prim_fifo_lutram
      #(
        .N_DATA_BITS($bits(t_mmio_rd_tag) + MMIO_DWORD_IDX_BITS),
        .N_ENTRIES(MAX_OUTSTANDING_MMIO_RD_REQS),
        .REGISTER_OUTPUT(1)
        )
      mmio_rd_meta
       (
        .clk,
        .reset_n,

        .enq_data({ host_mmio_req.t.data.tag,
                    host_mmio_req.t.data.addr[2 +: MMIO_DWORD_IDX_BITS] }),
        .enq_en(mmio_if.read && !mmio_if.waitrequest),
        .notFull(),
        .almostFull(),

        .first({ mmio_rd_tag, mmio_rd_dword_idx }),
        .deq_en(host_mmio_rsp.tvalid && host_mmio_rsp.tready),
        .notEmpty()
        );

    // Write-only MMIO requests
    assign mmio_wo_if.read = 1'b0;
    assign mmio_wo_if.write = host_mmio_req.tready && host_mmio_req.tvalid &&
                           host_mmio_req.t.data.is_write &&
                           (host_mmio_req.t.data.byte_count <= (MMIO_WO_DATA_WIDTH / 8));

    assign mmio_wo_if.address = host_mmio_req.t.data.addr[$clog2(MMIO_WO_DATA_WIDTH/8) +: MMIO_WO_ADDR_WIDTH];
    assign mmio_wo_if.burstcount = '1;
    assign mmio_wo_if.user = '0;

    // Reformat MMIO write data and mask for Avalon
    ofs_plat_host_chan_mmio_wr_data_comb
      #(
        .DATA_WIDTH(MMIO_WO_DATA_WIDTH)
        )
      mmio_wo_data
       (
        .byte_addr(host_mmio_req.t.data.addr),
        .byte_count(host_mmio_req.t.data.byte_count),
        .payload_in(MMIO_WO_DATA_WIDTH'(host_mmio_req.t.data.payload)),

        .payload_out(mmio_wo_if.writedata),
        .byte_mask(mmio_wo_if.byteenable)
        );


    // AFU responses (t_gen_tx_mmio_afu_rsp)
    `AXI_STREAM_INSTANCE(host_mmio_rsp, t_gen_tx_mmio_afu_rsp);

    // Buffer read responses. Avalon has no flow control but the PCIe interface
    // does.
    logic mmio_rd_datavalid;
    t_mmio_data mmio_rd_data;

    ofs_plat_prim_fifo_bram
      #(
        .N_DATA_BITS(MMIO_DATA_WIDTH),
        .N_ENTRIES(MAX_OUTSTANDING_MMIO_RD_REQS)
        )
      mmio_rd_rsp
       (
        .clk,
        .reset_n,

        .enq_data(mmio_if.readdata),
        .enq_en(mmio_if.readdatavalid),
        .notFull(),
        .almostFull(),

        .first(mmio_rd_data),
        .deq_en(host_mmio_rsp.tvalid && host_mmio_rsp.tready),
        .notEmpty(mmio_rd_datavalid)
        );

    // Shift MMIO read responses that are smaller than the bus width into the
    // proper position.
    t_mmio_data mmio_rd_data_shifted;

    ofs_plat_prim_rshift_words_comb
      #(
        .DATA_WIDTH(MMIO_DATA_WIDTH),
        .WORD_WIDTH(32)
        )
      mmio_r_data_shift
       (
        .d_in(mmio_rd_data),
        .rshift_cnt(mmio_rd_dword_idx),
        .d_out(mmio_rd_data_shifted)
        );

    assign host_mmio_rsp.tvalid = mmio_rd_datavalid;
    assign host_mmio_rsp.t.data.tag = mmio_rd_tag;
    assign host_mmio_rsp.t.data.payload = { '0, mmio_rd_data_shifted };


    // ====================================================================
    //
    //  Manage AFU read requests and host completion responses
    //
    // ====================================================================

    localparam ADDR_WIDTH = mem_master.ADDR_WIDTH_;
    typedef logic [ADDR_WIDTH-1 : 0] t_addr;
    localparam DATA_WIDTH = mem_master.DATA_WIDTH_;
    typedef logic [DATA_WIDTH-1 : 0] t_data;

    localparam USER_WIDTH = mem_master.USER_WIDTH_;
    localparam ROB_IDX_WIDTH = USER_WIDTH - USER_ROB_IDX_START;

    // Byte-level address bits within a line. (Avalon doesn't have these
    // but PCIe expects them.)
    localparam LINE_ADDR_BITS = $clog2(DATA_WIDTH/8);
    typedef logic [LINE_ADDR_BITS-1 : 0] t_line_addr_idx;

    function automatic logic [ROB_IDX_WIDTH-1:0] robIdxFromUser(logic [USER_WIDTH-1:0] user);
        return user[USER_WIDTH-1 : USER_ROB_IDX_START];
    endfunction // robIdxFromUser

    function automatic logic [USER_WIDTH-1:0] robIdxToUser(logic [ROB_IDX_WIDTH-1:0] idx);
        logic [USER_WIDTH-1:0] user = 0;
        user[USER_WIDTH-1 : USER_ROB_IDX_START] = idx;
        return user;
    endfunction // robIdxToUser

    // Read requests from AFU (t_gen_tx_afu_rd_req)
    `AXI_STREAM_INSTANCE(afu_rd_req, t_gen_tx_afu_rd_req);
    assign afu_rd_req.tvalid = mem_if.rd_read;
    assign mem_if.rd_waitrequest = !afu_rd_req.tready;
    assign afu_rd_req.t.data.tag = { '0, robIdxFromUser(mem_if.rd_user) };
    assign afu_rd_req.t.data.line_count = t_tlp_payload_line_count'(mem_if.rd_burstcount);
    assign afu_rd_req.t.data.addr = { '0, mem_if.rd_address, t_line_addr_idx'(0) };

    // Read responses to AFU (t_gen_tx_afu_rd_rsp)
    `AXI_STREAM_INSTANCE(afu_rd_rsp, t_gen_tx_afu_rd_rsp);
    assign afu_rd_rsp.tready = 1'b1;
    assign mem_if.rd_readdatavalid = afu_rd_rsp.tvalid;
    always_comb
    begin
        mem_if.rd_readdata = afu_rd_rsp.t.data.payload;
        mem_if.rd_response = '0;

        // Index of the ROB entry.
        mem_if.rd_readresponseuser = { '0, robIdxToUser(afu_rd_rsp.t.data.tag +
                                                        afu_rd_rsp.t.data.line_idx) };
        // Use the no reply flag to indicate the beat isn't SOP.
        mem_if.rd_readresponseuser[ofs_plat_host_chan_avalon_mem_pkg::HC_AVALON_UFLAG_NO_REPLY] <=
            |(afu_rd_rsp.t.data.line_idx);
    end


    // ====================================================================
    //
    //  Manage AFU write requests
    //
    // ====================================================================

    // Mapping byte masks to start and length needs to be broken apart
    // for timing. This first stage uses a FIFO in parallel with the
    // mem_if.w skid buffer to store start and end indices.
    t_tlp_payload_line_byte_idx w_byte_start_in, w_byte_end_in;
    t_tlp_payload_line_byte_idx w_byte_start, w_byte_end;

    always_comb
    begin
        w_byte_start_in = '0;
        for (int i = 0; i < DATA_WIDTH/8; i = i + 1)
        begin
            if (mem_master.wr_byteenable[i])
            begin
                w_byte_start_in = i;
                break;
            end
        end

        w_byte_end_in = ~'0;
        for (int i = DATA_WIDTH/8 - 1; i >= 0; i = i - 1)
        begin
            if (mem_master.wr_byteenable[i])
            begin
                w_byte_end_in = i;
                break;
            end
        end
    end

    ofs_plat_prim_fifo2
      #(
        .N_DATA_BITS(2 * $bits(t_tlp_payload_line_byte_idx))
        )
      byte_range_idx
       (
        .clk,
        .reset_n,

        .enq_data({ w_byte_start_in, w_byte_end_in }),
        .enq_en(mem_master.wr_write && !mem_master.wr_waitrequest),
        // Space is the same as the mem_if.w skid buffer
        .notFull(),

        .first({ w_byte_start, w_byte_end }),
        .deq_en(mem_if.wr_write && !mem_if.wr_waitrequest),
        .notEmpty()
        );

    // Write requests from AFU (t_gen_tx_afu_wr_req)
    `AXI_STREAM_INSTANCE(afu_wr_req, t_gen_tx_afu_wr_req);

    logic wr_is_sop, wr_is_eop;
    ofs_plat_prim_burstcount1_sop_tracker
      #(
        .BURST_CNT_WIDTH(mem_if.BURST_CNT_WIDTH_)
        )
      wr_sop_tracker
       (
        .clk,
        .reset_n,
        .flit_valid(mem_if.wr_write && !mem_if.wr_waitrequest),
        .burstcount(mem_if.wr_burstcount),
        .sop(wr_is_sop),
        .eop(wr_is_eop)
        );

    assign mem_if.wr_waitrequest = !afu_wr_req.tready;
    assign afu_wr_req.tvalid = mem_if.wr_write;

    always_comb
    begin
        afu_wr_req.t.data = '0;

        afu_wr_req.t.data.sop = wr_is_sop;
        afu_wr_req.t.data.eop = wr_is_eop;

        if (wr_is_sop)
        begin
            afu_wr_req.t.data.is_fence =
                (mem_if.USER_WIDTH > ofs_plat_host_chan_avalon_mem_pkg::HC_AVALON_UFLAG_FENCE) &&
                 mem_if.wr_user[ofs_plat_host_chan_avalon_mem_pkg::HC_AVALON_UFLAG_FENCE];
            afu_wr_req.t.data.is_interrupt =
                (mem_if.USER_WIDTH > ofs_plat_host_chan_avalon_mem_pkg::HC_AVALON_UFLAG_INTERRUPT) &&
                 mem_if.wr_user[ofs_plat_host_chan_avalon_mem_pkg::HC_AVALON_UFLAG_INTERRUPT];

            // If either the first or the last mask bit is 0 then write only
            // a portion of the line. This is supported only for simple line requests.
            if ((!mem_if.wr_byteenable[0] || !mem_if.wr_byteenable[DATA_WIDTH/8-1]) &&
                (mem_if.wr_burstcount == 1) &&
                !afu_wr_req.t.data.is_fence &&
                !afu_wr_req.t.data.is_interrupt)
            begin
                afu_wr_req.t.data.enable_byte_range = 1'b1;
                afu_wr_req.t.data.byte_start_idx = w_byte_start;
                afu_wr_req.t.data.byte_len = w_byte_end - w_byte_start + 1;
            end

            afu_wr_req.t.data.line_count = t_tlp_payload_line_count'(mem_if.wr_burstcount);
            afu_wr_req.t.data.addr = { '0, mem_if.wr_address, t_line_addr_idx'(0) };
            afu_wr_req.t.data.tag = { '0, robIdxFromUser(mem_if.wr_user) };

            if (afu_wr_req.t.data.is_interrupt)
            begin
                // Our Avalon-MM protocol stores the interrupt ID in the low bits
                // of wr_address.
                afu_wr_req.t.data.tag = { '0, t_interrupt_idx'(mem_if.wr_address) };
            end
        end

        afu_wr_req.t.data.payload = mem_if.wr_writedata;
    end

    // Preserve ROB index from interrupt requests so responses can be tagged properly
    // on return to the AFU. (Interrupts use the same index space is normal writes
    // in our encoding.)
    logic [ROB_IDX_WIDTH-1:0] intrWID[NUM_AFU_INTERRUPTS];

    always_ff @(posedge clk)
    begin
        if (afu_wr_req.tready && afu_wr_req.tvalid && afu_wr_req.t.data.is_interrupt)
        begin
            intrWID[t_interrupt_idx'(mem_if.wr_address)] <= robIdxFromUser(mem_if.wr_user);
        end
    end

    // Write responses to AFU once the packet is completely sent (t_gen_tx_afu_wr_rsp)
    `AXI_STREAM_INSTANCE(afu_wr_rsp, t_gen_tx_afu_wr_rsp);

    assign afu_wr_rsp.tready = 1'b1;
    assign mem_if.wr_writeresponsevalid = afu_wr_rsp.tvalid;
    assign mem_if.wr_response = '0;

    always_comb
    begin
        mem_if.wr_writeresponseuser = { '0, robIdxToUser(afu_wr_rsp.t.data.tag) };

        // Restore transaction ID for interrupts. (The response tag is the
        // interrupt index, not the transaction ID.)
        if (afu_wr_rsp.t.data.is_interrupt)
        begin
            mem_if.wr_writeresponseuser =
                { '0, robIdxToUser(intrWID[t_interrupt_idx'(afu_wr_rsp.t.data.tag)]) };
        end
    end


    // ====================================================================
    //
    //  Instantiate the TLP mapper.
    //
    // ====================================================================

    ofs_plat_host_chan_@group@_map_to_tlps tlp_mapper
       (
        .to_fiu_tlp,

        .host_mmio_req,
        .host_mmio_rsp,

        .afu_rd_req,
        .afu_rd_rsp,

        .afu_wr_req,
        .afu_wr_rsp
        );

endmodule // ofs_plat_host_chan_@group@_map_as_avalon_mem_if
