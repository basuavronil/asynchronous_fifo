`timescale 1ns / 1ps

module tb_async_fifo;

    // Testbench Signals
    reg        clk_rd;
    reg        clk_wr;
    reg        wr_en;
    reg        rd_en;
    reg        rst;
    reg  [7:0] d_in;
    wire       empty;
    wire       full;
    wire [7:0] d_out;

    // Instantiate Unit Under Test (UUT)
    async_fifo uut (
        .clk_rd (clk_rd),
        .clk_wr (clk_wr),
        .wr_en  (wr_en),
        .rd_en  (rd_en),
        .rst    (rst),
        .d_in   (d_in),
        .empty  (empty),
        .full   (full),
        .d_out  (d_out)
    );

    // -------------------------------------------------------------
    // 1. Asynchronous Clock Generators (100 MHz Write, ~60 MHz Read)
    // -------------------------------------------------------------
    initial clk_wr = 0;
    always #5 clk_wr = ~clk_wr;      // 10ns period (100 MHz)

    initial clk_rd = 0;
    always #8.33 clk_rd = ~clk_rd;  // 16.66ns period (~60 MHz)

    // -------------------------------------------------------------
    // 2. Main Stimulus
    // -------------------------------------------------------------
    integer i;

    initial begin
        // Initialize Inputs
        rst   = 0; // Active-low reset asserted
        wr_en = 0;
        rd_en = 0;
        d_in  = 8'h00;

        // Apply Reset for 30ns
        #30;
        rst = 1;   // Release Reset
        #20;

        $display("--------------------------------------------------");
        $display("TEST 1: Writing until FIFO is FULL");
        $display("--------------------------------------------------");
        for (i = 0; i < 16; i = i + 1) begin
            write_data(8'hA0 + i);
        end

        // Wait for synchronizers (2 clk_wr cycles) to trigger FULL flag
        #40;
        if (full)
            $display("-> SUCCESS: FIFO generated FULL flag correctly.");
        else
            $display("-> ERROR: FIFO failed to report FULL.");

        $display("\n--------------------------------------------------");
        $display("TEST 2: Attempting write while FULL (Overflow Check)");
        $display("--------------------------------------------------");
        write_data(8'hFF); // Should be ignored

        $display("\n--------------------------------------------------");
        $display("TEST 3: Reading until FIFO is EMPTY");
        $display("--------------------------------------------------");
        for (i = 0; i < 16; i = i + 1) begin
            read_data();
        end

        // Wait for synchronizers (2 clk_rd cycles) to trigger EMPTY flag
        #50;
        if (empty)
            $display("-> SUCCESS: FIFO generated EMPTY flag correctly.");
        else
            $display("-> ERROR: FIFO failed to report EMPTY.");

        $display("\n--------------------------------------------------");
        $display("TEST 4: Concurrent Write and Read Operations");
        $display("--------------------------------------------------");
        fork
            begin
                repeat(5) write_data(8'hC0 + ($random % 10));
            end
            begin
                repeat(5) read_data();
            end
        join

        #100;
        $display("\n--------------------------------------------------");
        $display("SIMULATION COMPLETE");
        $display("--------------------------------------------------");
        $finish;
    end

    // -------------------------------------------------------------
    // 3. Helper Tasks for Write & Read
    // -------------------------------------------------------------
    task write_data(input [7:0] data);
        begin
            @(posedge clk_wr);
            if (!full) begin
                wr_en <= 1'b1;
                d_in  <= data;
                $display("[WRITE] Time=%0t ns | Data = 0x%h", $time, data);
            end else begin
                $display("[WRITE BLOCKED] Time=%0t ns | FIFO Full! Data 0x%h dropped", $time, data);
            end
            @(posedge clk_wr);
            wr_en <= 1'b0;
        end
    endtask

    task read_data();
        begin
            @(posedge clk_rd);
            if (!empty) begin
                rd_en <= 1'b1;
            end else begin
                $display("[READ BLOCKED] Time=%0t ns | FIFO Empty!", $time);
            end
            @(posedge clk_rd);
            rd_en <= 1'b0;
            $display("[READ]  Time=%0t ns | Data = 0x%h", $time, d_out);
        end
    endtask

endmodule
