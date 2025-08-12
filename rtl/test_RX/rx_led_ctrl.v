module rx_led_ctrl (
    input clk,
    input rst_n,

    input wire [7:0] rx_data,     // 从 uart_rx 输出的数据
    input wire       rx_done,     // 从 uart_rx 输出的接收完成标志位
    input wire       frame_error, //帧错误标志

    output reg led1,
    output reg led2
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            led1 <= 1'b0;
            led2 <= 1'b0;
        end else if (rx_done && !frame_error) begin
            case (rx_data)
                8'h03:   led1 <= 1'b1;
                8'h04:   led2 <= 1'b1;
                8'h05:   led1 <= 1'b0;
                8'h06:   led2 <= 1'b0;
                default: ;
            endcase
        end
    end


endmodule  //rx_led_ctrl
