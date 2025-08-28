module uart_rx #(
    parameter UART_BPS = 115200,
    parameter CLK_FREQ = 50_000_000
) (
    input clk,
    input rst_n,

    input uart_rxd,  //串口接收输入

    output reg [7:0] rx_data,     // 接收数据 
    output reg       done_flag,   // 接收完成标志
    output reg       frame_error  // 帧错误标志
);

    // 计算波特率分频值
    localparam BAUD_CNT_MAX = CLK_FREQ / UART_BPS;
    localparam BAUD_BITS = $clog2(BAUD_CNT_MAX);

    //reg define
    reg [BAUD_BITS-1:0] baud_cnt;
    reg [3:0] bit_cnt;
    reg [7:0] rx_data_t;

    // 同步串口输入信号，消除亚稳态
    reg uart_rxd_d0;
    reg uart_rxd_d1;
    reg uart_rxd_d2;

    // 接收状态标志
    reg rx_flag;

    //wire define

    // 起始位检测（下降沿）
    wire start_en = (uart_rxd_d2 == 1'b1) && (uart_rxd_d1 == 1'b0);

    // 输入同步消除亚稳态
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_rxd_d0 <= 1'b1;
            uart_rxd_d1 <= 1'b1;
            uart_rxd_d2 <= 1'b1;
        end else begin
            uart_rxd_d0 <= uart_rxd;
            uart_rxd_d1 <= uart_rxd_d0;
            uart_rxd_d2 <= uart_rxd_d1;
        end
    end

    // rx_flag:接收标志控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_flag <= 1'b0;
        end else if (start_en) begin
            rx_flag <= 1'b1;
        end else if ((bit_cnt == 4'd9) && (baud_cnt == BAUD_CNT_MAX - 1)) begin
            rx_flag <= 1'b0;
        end
    end

    // baud_cnt:波特率计数器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_cnt <= 0;
        end else if (rx_flag) begin
            if (baud_cnt < BAUD_CNT_MAX - 1) begin
                baud_cnt <= baud_cnt + 1;
            end else begin
                baud_cnt <= 0;
            end
        end else begin
            baud_cnt <= 0;
        end
    end

    // bit_cnt:位计数器，起始 + 8 bit + 停止
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt <= 0;
        end else if (rx_flag && baud_cnt == BAUD_CNT_MAX - 1) begin
            bit_cnt <= bit_cnt + 1;
        end else if (!rx_flag) begin
            bit_cnt <= 0;
        end
    end

    // 数据采样：每个位的中间采样
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data_t <= 8'b0;
        end else if (rx_flag && baud_cnt == (BAUD_CNT_MAX >> 1)) begin
            case (bit_cnt)
                4'd1: rx_data_t[0] <= uart_rxd_d1;
                4'd2: rx_data_t[1] <= uart_rxd_d1;
                4'd3: rx_data_t[2] <= uart_rxd_d1;
                4'd4: rx_data_t[3] <= uart_rxd_d1;
                4'd5: rx_data_t[4] <= uart_rxd_d1;
                4'd6: rx_data_t[5] <= uart_rxd_d1;
                4'd7: rx_data_t[6] <= uart_rxd_d1;
                4'd8: rx_data_t[7] <= uart_rxd_d1;
                default: ;
            endcase
        end
    end

    // frame_error:帧错误检测：停止位应为高
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            frame_error <= 1'b0;
        end else if (rx_flag && bit_cnt == 4'd9 && baud_cnt == (BAUD_CNT_MAX >> 1)) begin
            frame_error <= ~uart_rxd_d1;
        end else if (!rx_flag) begin
            frame_error <= 1'b0;
        end
    end

    // done_flag:接收完成
    // rx_data:输出数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done_flag <= 1'b0;
            rx_data   <= 8'd0;
        end else if ((bit_cnt == 4'd9) && (baud_cnt == BAUD_CNT_MAX - 1)) begin
            done_flag <= 1'b1;
            rx_data   <= rx_data_t;
        end else begin
            done_flag <= 1'b0;
        end
    end

endmodule
