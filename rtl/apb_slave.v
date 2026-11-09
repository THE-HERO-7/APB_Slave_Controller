module apb_slave (
    input pclk,
    input presetn,
    input psel,
    input penable,
    input pwrite,
    input [7:0] paddr,
    input [31:0] pwdata,
    output reg [31:0] prdata,
    output wire pready,
    output wire pslverr
);

wire transfer;
wire write_enable;
wire read_enable;

assign transfer = psel && penable && pready;
assign write_enable = transfer && pwrite;
assign read_enable = transfer && !pwrite;

reg [1:0] wait_count;
reg transfer_started;

assign pready = psel && penable &&
                transfer_started && (wait_count == 0);


reg [31:0] ctrl_reg; //control register
reg [31:0] status_reg; //status register
reg [31:0] data_reg; //data register
reg [31:0] config_reg; //configuration register

always @(posedge pclk or negedge presetn) begin
    if(!presetn) begin
        wait_count <= 0;
        transfer_started <= 0;
        ctrl_reg <= 32'h00000000; 
        status_reg <= 32'h00000000;
        data_reg <= 32'h00000000;
        config_reg <= 32'h00000000;
        prdata <= 32'h00000000;
    end 
    else begin
        if(write_enable) begin
            case(paddr)
                8'h00: ctrl_reg <= pwdata; //write to control register
                8'h04: ; //read-only status register, do nothing on write
                8'h08: data_reg <= pwdata; //write to data register
                8'h0C: config_reg <= pwdata; //write to configuration register
                default: ;
            endcase
        end
        else if (read_enable) begin
            case(paddr)
                8'h00: prdata <= ctrl_reg; //read from control register
                8'h04: prdata <= status_reg; //read from status register
                8'h08: prdata <= data_reg; //read from data register
                8'h0C: prdata <= config_reg; //read from configuration register
                default: prdata <= 32'h00000000;
            endcase
        end
        if (!psel || !penable) begin
            transfer_started <= 1'b0;
            wait_count <= 0;
        end
        else if (!transfer_started) begin
            wait_count <= 2;
            transfer_started <= 1'b1;
        end
        else if (!pready) begin
            wait_count <= wait_count - 1'b1;
        end

    end

end

wire invalid_addr;
assign invalid_addr = (paddr != 8'h00) &&
                      (paddr != 8'h04) &&
                      (paddr != 8'h08) &&
                      (paddr != 8'h0C);

wire invalid_write;
assign invalid_write = pwrite && (paddr == 8'h04);

assign pslverr = transfer &&(invalid_addr || invalid_write);

endmodule