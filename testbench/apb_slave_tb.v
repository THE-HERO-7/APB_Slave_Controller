`timescale 1ns/1ps

module apb_slave_tb;

    // ------------------------------------------------
    // 1. Testbench signals
    // ------------------------------------------------

    reg pclk;
    reg presetn;
    reg psel;
    reg penable;
    reg pwrite;
    reg [7:0] paddr;
    reg [31:0] pwdata;

    wire [31:0] prdata;
    wire pready;
    wire pslverr;

    reg [31:0] read_data;
    reg error_flag;

    // ------------------------------------------------
    // 2. DUT instantiation
    // ------------------------------------------------

    apb_slave dut (
        .pclk(pclk),
        .presetn(presetn),
        .psel(psel),
        .penable(penable),
        .pwrite(pwrite),
        .paddr(paddr),
        .pwdata(pwdata),
        .prdata(prdata),
        .pready(pready),
        .pslverr(pslverr)
    );

    // ------------------------------------------------
    // 3. Clock generation
    // ------------------------------------------------

    initial begin
        pclk = 0;
        forever #5 pclk = ~pclk;
    end

    // ------------------------------------------------
    // 4. Waveform generation
    // ------------------------------------------------

    initial begin
        $dumpfile("simulation/apb_slave_tb.vcd");
        $dumpvars(0, apb_slave_tb);
    end

    // ------------------------------------------------
    // 5. APB WRITE TASK
    // ------------------------------------------------

    task apb_write;
        input [7:0] address;
        input [31:0] write_data;
        output reg error;

        begin
            // Setup phase
            @(negedge pclk);
            psel = 1;
            penable = 0;
            pwrite = 1;
            paddr = address;
            pwdata = write_data;

            // Access phase
            @(negedge pclk);
            penable = 1;

            // Wait until slave is ready
            while (pready !== 1'b1)
                @(negedge pclk);

            // Complete transfer
            @(posedge pclk);
            #1;
            error = pslverr;

            // Return to idle
            @(negedge pclk);
            psel = 0;
            penable = 0;
            pwrite = 0;
        end
    endtask

    // ------------------------------------------------
    // 6. APB READ TASK
    // ------------------------------------------------

    task apb_read;
        input [7:0] address;
        output reg [31:0] read_value;
        output reg error;

        begin
            // Setup phase
            @(negedge pclk);
            psel = 1;
            penable = 0;
            pwrite = 0;
            paddr = address;
            pwdata = 0;

            // Access phase
            @(negedge pclk);
            penable = 1;

            // Wait until slave is ready
            while (pready !== 1'b1)
                @(negedge pclk);

            // Complete transfer
            @(posedge pclk);
            #1;
            read_value = prdata;
            error = pslverr;

            // Return to idle
            @(negedge pclk);
            psel = 0;
            penable = 0;
        end
    endtask

    // ------------------------------------------------
    // 7. Main verification sequence
    // ------------------------------------------------

    initial begin

        // Initialize inputs
        presetn = 0;
        psel = 0;
        penable = 0;
        pwrite = 0;
        paddr = 0;
        pwdata = 0;

        // Release reset
        repeat (2) @(negedge pclk);
        presetn = 1;

        repeat (1) @(negedge pclk);

        $display("\n==================================");
        $display(" APB SLAVE VERIFICATION STARTED");
        $display("==================================");

        // --------------------------------------------
        // TEST 1: CTRL_REG
        // --------------------------------------------

        apb_write(8'h00, 32'hA5A5A5A5, error_flag);
        apb_read(8'h00, read_data, error_flag);

        if (read_data == 32'hA5A5A5A5 && !error_flag)
            $display("PASS: CTRL_REG write/read");
        else
            $display("FAIL: CTRL_REG, Data = %h", read_data);

        // --------------------------------------------
        // TEST 2: DATA_REG
        // --------------------------------------------

        apb_write(8'h08, 32'hDEADBEEF, error_flag);
        apb_read(8'h08, read_data, error_flag);

        if (read_data == 32'hDEADBEEF && !error_flag)
            $display("PASS: DATA_REG write/read");
        else
            $display("FAIL: DATA_REG, Data = %h", read_data);

        // --------------------------------------------
        // TEST 3: CONFIG_REG
        // --------------------------------------------

        apb_write(8'h0C, 32'h12345678, error_flag);
        apb_read(8'h0C, read_data, error_flag);

        if (read_data == 32'h12345678 && !error_flag)
            $display("PASS: CONFIG_REG write/read");
        else
            $display("FAIL: CONFIG_REG, Data = %h", read_data);

        // --------------------------------------------
        // TEST 4: STATUS_REG read-only protection
        // --------------------------------------------

        apb_write(8'h04, 32'hFFFFFFFF, error_flag);

        if (error_flag)
            $display("PASS: STATUS_REG write rejected");
        else
            $display("FAIL: STATUS_REG write not rejected");

        apb_read(8'h04, read_data, error_flag);

        if (read_data == 32'h00000000 && !error_flag)
            $display("PASS: STATUS_REG read");
        else
            $display("FAIL: STATUS_REG read");

        // --------------------------------------------
        // TEST 5: Invalid address
        // --------------------------------------------

        apb_read(8'h10, read_data, error_flag);

        if (error_flag)
            $display("PASS: Invalid address detected");
        else
            $display("FAIL: Invalid address not detected");

        // --------------------------------------------
        // TEST 6: Reset verification
        // --------------------------------------------

        $display("\n--- Registers before reset ---");

        $display("CTRL_REG   = %h", dut.ctrl_reg);
        $display("STATUS_REG = %h", dut.status_reg);
        $display("DATA_REG   = %h", dut.data_reg);
        $display("CONFIG_REG = %h", dut.config_reg);

        // Assert asynchronous reset
        @(negedge pclk);
        presetn = 0;

        #1;

        if (dut.ctrl_reg == 0 &&
            dut.status_reg == 0 &&
            dut.data_reg == 0 &&
            dut.config_reg == 0 &&
            prdata == 0)
            $display("PASS: Asynchronous reset");
        else
            $display("FAIL: Reset verification");

        $display("\n--- Registers after reset ---");

        $display("CTRL_REG   = %h", dut.ctrl_reg);
        $display("STATUS_REG = %h", dut.status_reg);
        $display("DATA_REG   = %h", dut.data_reg);
        $display("CONFIG_REG = %h", dut.config_reg);

        // Release reset
        @(negedge pclk);
        presetn = 1;

        // --------------------------------------------
        // TEST SUMMARY
        // --------------------------------------------

        repeat (2) @(negedge pclk);

        $display("\n==================================");
        $display(" APB SLAVE VERIFICATION COMPLETED");
        $display("==================================");

        $finish;

    end

endmodule