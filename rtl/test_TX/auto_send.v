module auto_send #(
    parameter CLK_FREQ         = 50_000_000,  // 时钟频率 50MHz
    parameter UART_BPS         = 115200,      // 串口波特率
    parameter SEND_INTERVAL_MS = 100          // 发送间隔（单位：ms）
) (
    input  clk,
    input  rst_n,
    output uart_txd
);

    // ----------- 发送控制信号 -------------
    wire uart_tx_busy;
    wire uart_tx_done;

    reg uart_tx_start;
    wire [7:0] uart_tx_data;

    assign uart_tx_data = 8'h55;  // 发送固定数据

    // ----------- 自动发送控制逻辑 -------------
    localparam INTERVAL_CNT_MAX = CLK_FREQ / 1_000 * SEND_INTERVAL_MS;  // 100ms计数值

    reg [31:0] interval_cnt;
    reg send_en;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            interval_cnt <= 0;
            send_en      <= 0;
        end else if (uart_tx_done) begin
            interval_cnt <= 0;
            send_en      <= 0;
        end else if (!uart_tx_busy) begin
            if (interval_cnt >= INTERVAL_CNT_MAX - 1) begin
                send_en <= 1;
            end else begin
                interval_cnt <= interval_cnt + 1;
                send_en      <= 0;
            end
        end else begin
            send_en <= 0;
        end
    end

    // ----------- uart_tx_start 产生一个周期脉冲 -------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_tx_start <= 0;
        end else if (send_en && !uart_tx_busy) begin
            uart_tx_start <= 1;
        end else begin
            uart_tx_start <= 0;
        end
    end

    // ----------- 实例化 uart_tx 模块 -------------
    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .UART_BPS(UART_BPS)
    ) u_uart_tx (
        .clk          (clk),
        .rst_n        (rst_n),
        .uart_tx_start(uart_tx_start),
        .uart_tx_data (uart_tx_data),
        .uart_txd     (uart_txd),
        .uart_tx_busy (uart_tx_busy),
        .uart_tx_done (uart_tx_done)
    );

endmodule
