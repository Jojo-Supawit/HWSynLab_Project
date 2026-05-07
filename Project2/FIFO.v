module FIFO #(
    parameter word_size = 32,
    parameter address_size = 10
) (
    input   clk,
    input   reset,
    input   [word_size - 1:0] data_in,
    output  [word_size - 1:0] data_out,
    input   read_enb,
    input   write_enb,
    output  free,
    output  empty,
    output  trigger
);

    localparam FIFO_SIZE = (1<<address_size);

    reg [word_size - 1:0] mem [0:FIFO_SIZE - 1];
    reg [address_size - 1:0] read_ptr = 0;
    reg [address_size - 1:0] write_ptr = 0;
    reg [address_size:0] size = 0;

    reg [word_size - 1:0] dout = {word_size{1'b1}};
    assign data_out = dout;

    assign free = size < FIFO_SIZE - 3;
    assign empty = size == 0;
    assign trigger = size > FIFO_SIZE - 20;

    always @(posedge clk ) begin
        if(reset) begin
            read_ptr <= 0;
            write_ptr <= 0;
            size <= 0;
        end else begin
            // if(size >= FIFO_SIZE - 10) trigger <= 1;
            // else if(size <= FIFO_SIZE>>1) trigger <= 0;
            if(read_enb && write_enb) begin
                if(size == FIFO_SIZE) begin
                    dout <= mem[read_ptr];
                    read_ptr <= read_ptr + 1;
                    size <= size - 1;
                end else if(size == 0) begin
                    mem[write_ptr] <= data_in;
                    write_ptr <= write_ptr + 1;
                    size <= size + 1;
                end else begin
                    dout <= mem[read_ptr];
                    read_ptr <= read_ptr + 1;
                    mem[write_ptr] <= data_in;
                    write_ptr <= write_ptr + 1;
                end
            end else if(read_enb) begin
                if(size > 0) begin
                    dout <= mem[read_ptr];
                    read_ptr <= read_ptr + 1;
                    size <= size - 1;
                end
            end else if(write_enb) begin
                if(size < FIFO_SIZE) begin
                    mem[write_ptr] <= data_in;
                    write_ptr <= write_ptr + 1;
                    size <= size + 1;
                end
            end
        end
    end

endmodule