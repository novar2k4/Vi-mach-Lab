module risc_cpu (
    input wire clk,
    input wire rst,
    output wire [7:0] debug_pc,
    output wire [7:0] debug_acc,
    output wire [7:0] debug_ir,
    output wire [2:0] debug_state,
    output wire debug_halt
);

    // Internal signals
    wire [4:0] pc_out;
    wire [4:0] addr_mux_out;
    wire [7:0] mem_data_out;
    wire [7:0] ir_out;
    wire [7:0] acc_out;
    wire [7:0] alu_out;
    wire alu_zero;
    wire mem_rd, mem_wr;
    wire sel;
    wire ld_ir;
    wire halt;
    wire inc_pc;
    wire ld_ac;
    wire ld_pc;
    wire data_e;
    
    program_counter pc (
        .clk(clk),
        .rst(rst),
        .inc(inc_pc),
        .load(ld_pc),
        .data_in(ir_out[4:0]),
        .count(pc_out)
    );
    
    address_mux addr_mux (
        .sel(sel),
        .pc_addr(pc_out),
        .ir_addr(ir_out[4:0]),
        .addr_out(addr_mux_out)
    );

    memory mem (
        .clk(clk),
        .addr(addr_mux_out),
        .data_in(acc_out),
        .data_out(mem_data_out),
        .rd(mem_rd),
        .wr(mem_wr)
    );

    instruction_register ir (
        .clk(clk),
        .data_in(mem_data_out),
        .load(ld_ir),
        .data_out(ir_out)
    );

    accumulator acc (
        .clk(clk),
        .rst(rst),
        .data_in(alu_out),
        .load(ld_ac),
        .data_out(acc_out)
    );

    alu alu_unit (
        .inA(acc_out),
        .inB(mem_data_out),
        .opcode(ir_out[7:5]),
        .result(alu_out),
        .is_zero(alu_zero)
    );

    controller ctrl (
        .clk(clk),
        .rst(rst),
        .opcode(ir_out[7:5]),
        .zero(alu_zero),
        .sel(sel),
        .rd(mem_rd),
        .ld_ir(ld_ir),
        .halt(halt),
        .inc_pc(inc_pc),
        .ld_ac(ld_ac),
        .ld_pc(ld_pc),
        .wr(mem_wr),
        .data_e(data_e)
    );

    assign debug_pc = {3'b000, pc_out};
    assign debug_acc = acc_out;
    assign debug_ir = ir_out;
    assign debug_state = {2'b00, ctrl.state};
    assign debug_halt = halt;

endmodule

module program_counter (
    input wire clk,
    input wire rst,
    input wire inc,
    input wire load,
    input wire [4:0] data_in,
    output reg [4:0] count
);
    always @(posedge clk) begin
        if (rst)
            count <= 5'b00000;
        else if (load)
            count <= data_in;
        else if (inc)
            count <= count + 1'b1;
    end
endmodule

module address_mux (
    input wire sel,
    input wire [4:0] pc_addr,
    input wire [4:0] ir_addr,
    output wire [4:0] addr_out
);
    assign addr_out = sel ? pc_addr : ir_addr;
endmodule

module memory (
    input wire clk,
    input wire [4:0] addr,
    input wire [7:0] data_in,
    output reg [7:0] data_out,
    input wire rd,
    input wire wr
);
    reg [7:0] mem [0:31];
    
    always @(posedge clk) begin
        if (rd)
            data_out <= mem[addr];
        if (wr)
            mem[addr] <= data_in;
    end
endmodule

module instruction_register (
    input wire clk,
    input wire [7:0] data_in,
    input wire load,
    output reg [7:0] data_out
);
    always @(posedge clk) begin
        if (load)
            data_out <= data_in;
    end
endmodule

module accumulator (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire load,
    output reg [7:0] data_out
);
    always @(posedge clk) begin
        if (rst)
            data_out <= 8'h00;
        else if (load)
            data_out <= data_in;
    end
endmodule

module alu (
    input wire [7:0] inA,
    input wire [7:0] inB,
    input wire [2:0] opcode,
    output reg [7:0] result,
    output wire is_zero
);

    assign is_zero = (result == 8'h00) ? 1'b1 : 1'b0;
    
    always @(*) begin
        case (opcode)
            3'b000: result = inA;        
            3'b001: result = inA;        
            3'b010: result = inA + inB;  
            3'b011: result = inA & inB;  
            3'b100: result = inA ^ inB;  
            3'b101: result = inB;        
            3'b110: result = inA;        
            3'b111: result = inA;        
            default: result = 8'h00;
        endcase
    end
endmodule

// Controller Module
module controller (
    input wire clk, input wire rst,
    input wire [2:0] opcode, input wire zero,
    output reg sel, output reg rd, output reg ld_ir,
    output reg halt, output reg inc_pc, output reg ld_ac,
    output reg ld_pc, output reg wr, output reg data_e
);
    parameter [2:0] INST_ADDR=0, INST_FETCH=1, INST_LOAD=2, IDLE=3,
                    OP_ADDR=4, OP_FETCH=5, ALU_OP=6, STORE=7;
    reg [2:0] state, next;
    reg skip_reg;                        
    
    always @(posedge clk) begin
        if (rst) begin
            state <= INST_ADDR;
            skip_reg <= 0;               
        end
        else begin
            state <= next;
if (state == IDLE && opcode == 3'b001 && zero)
    skip_reg <= 1;
else if (state == INST_ADDR && skip_reg)
    skip_reg <= 0;
        end
    end
    
    always @(*) begin
        case (state)
            INST_ADDR: next = INST_FETCH;
            INST_FETCH: next = INST_LOAD;
            INST_LOAD: next = IDLE;
            IDLE: next = (opcode==3'b000) ? IDLE : 
                        (opcode==3'b111||opcode==3'b001) ? INST_ADDR : OP_ADDR;
            OP_ADDR: next = OP_FETCH;
            OP_FETCH: next = ALU_OP;
            ALU_OP: next = (opcode==3'b110) ? STORE : INST_ADDR;
            STORE: next = INST_ADDR;
            default: next = INST_ADDR;
        endcase
    end
    
    always @(*) begin
        sel=1; rd=0; ld_ir=0; halt=0; inc_pc=0; ld_ac=0; ld_pc=0; wr=0; data_e=0;
        case (state)
INST_ADDR: begin sel=1; rd=1; end
INST_FETCH: begin sel=1; rd=1; end
INST_LOAD: begin sel=1; ld_ir=1; inc_pc = ~skip_reg; end
            IDLE: begin
                sel=0;
                if (opcode==3'b000) halt=1;
                else if (opcode==3'b001 && zero) inc_pc=1;
                else if (opcode==3'b111) ld_pc=1;
            end
            OP_ADDR: begin sel=0; rd=1; end
            OP_FETCH: begin sel=0; rd=1; end
            ALU_OP: begin sel=0; ld_ac=1; end
            STORE: begin sel=0; wr=1; data_e=1; end
        endcase
    end
endmodule