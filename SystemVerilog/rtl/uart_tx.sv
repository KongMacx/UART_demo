module uart_tx #(
    parameter int CLK_FREQ = 50_000_000,  //系统时钟频率
    parameter int UART_BPS = 115200
) (
    input logic clk,
    input logic rst_n,

    input logic       uart_tx_start,  //发送请求
    input logic [7:0] uart_tx_data,   //发送数据

    output logic uart_txd,      //UART TX口
    output logic uart_tx_busy,  //发送忙
    output logic uart_tx_done   //发送完成（1 clk宽）
);

    //计算波特率分频
    localparam int BAUD_CNT_MAX = CLK_FREQ / UART_BPS;

    //定义状态机
    typedef enum logic [2:0] {
        ST_IDLE,
        ST_START,
        ST_DATA,
        ST_STOP
    } tx_state_t;

    //状态寄存器
    tx_state_t state;
    tx_state_t next_state;

    logic [7:0] tx_data_t;  //发送数据缓存
    logic [15:0] baud_cnt;  //波特率计数器
    logic [2:0] bit_idx;  //数据位计数（0-7）

    //状态机切换
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE;
        end else begin
            state <= next_state;
        end
    end

    //状态转移条件
    always_comb begin
        next_state = state;
        case (state)
            ST_IDLE:  if (uart_tx_start) next_state = ST_START;
            ST_START: if (baud_cnt == BAUD_CNT_MAX - 1) next_state = ST_DATA;
            ST_DATA:  if (baud_cnt == BAUD_CNT_MAX - 1 && bit_idx == 3'd7) next_state = ST_STOP;
            ST_STOP:  if (baud_cnt == BAUD_CNT_MAX - 1) next_state = ST_IDLE;
        endcase
    end

    //波特率计数器
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_cnt <= '0;
        end else if (state == ST_IDLE) begin
            baud_cnt <= '0;
        end else if (baud_cnt == BAUD_CNT_MAX - 1) begin
            baud_cnt <= '0;
        end else begin
            baud_cnt <= baud_cnt + 1;
        end
    end

    //数据位计数器
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_idx <= '0;
        end else if (state == ST_START) begin
            bit_idx <= '0;
        end else if (state == ST_DATA && baud_cnt == BAUD_CNT_MAX - 1) begin
            bit_idx <= bit_idx + 1;
        end
    end

    //发送数据缓存
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_data_t <= '0;
        end else if (uart_tx_start && state == ST_IDLE) begin
            tx_data_t <= uart_tx_data;
        end
    end

    //串口 TX 输出
    always_comb begin
        case (state)
            ST_IDLE:  uart_txd <= 1'b1;  //空闲 = 高
            ST_START: uart_txd <= 1'b0;  //起始位 = 0
            ST_DATA:  uart_txd <= uart_tx_data[bit_idx];  //数据位
            ST_STOP:  uart_txd <= 1'b1;  //停止位 = 1
            default:  uart_txd <= 1'b1;
        endcase
    end

    //标志信号
    assign uart_tx_busy = (state != ST_IDLE);
    assign uart_tx_done = (state == ST_STOP && baud_cnt == BAUD_CNT_MAX - 1);
endmodule
