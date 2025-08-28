module uart_rx #(
    parameter int CLK_FREQ = 50_000_000,
    parameter int UART_BPS = 115200
) (
    input logic clk,
    input logic rst_n,

    input logic uart_txd,  //串口接收输入

    output logic [7:0] rx_data,     //接收数据
    output logic       done_flag,   //接收完成标志位
    output logic       frame_error  //帧错误标志
);

    //计算波特率分频
    localparam int BAUD_CNT_MAX = CLK_FREQ / UART_BPS;
    localparam int BAUD_BITS = $clog2(BAUD_CNT_MAX);

    //信号定义
    logic [BAUD_BITS-1:0] baud_cnt;
    logic [3:0] bit_cnt;
    logic [7:0] rx_data_t;

    //输入同步寄存器，消除亚稳态
    logic uart_rxd_d0;
    logic uart_rxd_d1;
    logic uart_rxd_d2;

    //接收状态标志
    logic rx_flag;

    //起始位检测（下降沿）
    wire start_en = (uart_rxd_d2 == 1'b1) && (uart_rxd_d1 == 1'b0);

    //main code

    //输入同步消除亚稳态
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_rxd_d0 <= 1'b1;
            uart_rxd_d1 <= 1'b1;
            uart_rxd_d2 <= 1'b1;
        end else begin
            uart_rxd_d0 <= uart_txd;
            uart_rxd_d1 <= uart_rxd_d0;
            uart_rxd_d2 <= uart_rxd_d1;
        end
    end

    //rx_flag:接收标志控制
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_flag <= '0;
        end else if (start_en) begin
            rx_flag <= 1'b1;
        end else if ((bit_cnt == 4'd9) && (baud_cnt == BAUD_CNT_MAX - 1)) begin
            rx_flag <= '0;
        end
    end

    //baud_cnt:波特率计数器
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_cnt <= '0;
        end else if (rx_flag) begin
            if (baud_cnt < BAUD_CNT_MAX - 1) begin
                baud_cnt <= baud_cnt + 1'b1;
            end else begin
                baud_cnt <= '0;
            end
        end else begin
            baud_cnt <= '0;
        end
    end

    //bit_cnt:比特计数器
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt <= '0;
        end else if (rx_flag && baud_cnt == BAUD_CNT_MAX - 1) begin
            bit_cnt <= bit_cnt + 1'b1;
        end else if (!rx_flag) begin
            bit_cnt <= '0;
        end
    end

    //数据采样:每个位的中间点采样
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data <= '0;
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

    //frame_error:错位帧检测；停止位应为高
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            frame_error <= '0;
        end else if (rx_flag && bit_cnt == 4'd9 && baud_cnt == (BAUD_CNT_MAX >> 1)) begin
            frame_error <= ~uart_rxd_d1;
        end else if (!rx_flag) begin
            frame_error <= 'b0;
        end
    end

    //done_flag:接收完成
    //rx_data:输出数据
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done_flag <= '0;
            rx_data   <= '0;
        end else if ((bit_cnt == 4'd9) && (baud_cnt == BAUD_CNT_MAX - 1)) begin
            done_flag <= 1'b1;
            rx_data   <= rx_data_t;
        end else begin
            done_flag <= '0;
        end
    end
endmodule
