module timer
  #(parameter HALF_MS_CONT = 50000000)
(
  // Declaração das portas
  input start,
  input pause,
  input stop,
  input [6:0] min, // min é uma entrada de 7 bits
  input [6:0] sec, // sec é uma entrada de 7 bits
  input reset,
  input clock,
  output [7:0] an,  // qual display ta selecionadp
  output [7:0] dec_cat, // numero q vai ser mostrado
  output done 
);

    // Declaração dos sinais
    // essas variáveis são declaradas como fio pq são os botões, os valores delas não  precisam ser guardados em nunhum lugar
    wire start_ed;
    wire pause_ed;
    wire stop_ed;
    wire [3:0] uni_min, dez_min, uni_seg, dez_seg;

    reg clk_1;
    reg [31:0] cont_50K;
    reg [6:0] min_left, sec_left;
    reg [1:0] EA;
   
  
    
    // Instanciação dos edge_detectors
    // isso ta no arquivo edge_detector.v aqui é só chamada dele
  edge_detector startf (.clock(clock), .reset(reset), .din(start), .rising(start_ed)); // o sinal clock conectado ao pino de entrada clock que estão instanciados no aruqivo do edge detector
  edge_detector pausef (.clock(clock), .reset(reset), .din(pause), .rising(pause_ed));
  edge_detector stopf (.clock(clock), .reset(reset), .din(stop), .rising(stop_ed));
  

    // Divisor de clock para gerar o ck1seg
    always @(posedge clock or posedge reset)
    begin

      if (reset == 1'b1) begin //se o reset for ativado
        clk_1   <= 1'b0;
        cont_50K <= 32'd0; // o contador reinicia
      end

      else begin
        if (cont_50K == HALF_MS_CONT-1) begin
          clk_1  <= ~clk_1; // inversão do sinal de clock
          cont_50K <= 32'd0; // contador reiniciado
       end

      else begin
        if (EA == 2'd1 || EA == 2'd0) begin
        cont_50K <= cont_50K + 1; // o contador é incrementado em 1 a cada ciclo de clock
        end
      end

    end

end

// Máquina de estados para determinar o estado atual (EA)
// reset == 1 -> IDLE 0
// EA IDLE 0: start == 1 -> CD 1
// EA CD 1: stop == 1 OU 00:00 -> IDLE 0
// EA CD 1: pause == 1 -> PAUSED 2
// EA PAUSED 2: pause == 1 OU start == 1 -> CD 1
// EA PAUSED 2: stop == 1 -> IDLE 0

always @(posedge clock or posedge reset)
begin

    // 2'd00 = IDLE
    // 2'd01 = CD
    // 2'd02 = PAUSED 
    // 1'b0 = falso
    // 1'b1 = true

  if (reset == 1) begin
    EA <= 2'd00; // estado IDLE
    //min <= 7'd0; // definindo o temporizador dos minutos em 0
    //sec <= 7'd0; // definindo o temporizador dos segundos em 0
  end

  else begin

    case (EA)
      2'd0: // IDLE
        begin
          if (start_ed == 1) begin // se o start == 1, o EA será o CD
            EA <= 2'd1; // CD 
          end
        end

      2'd1: // CD 
        begin
          if (stop_ed == 1 || (min_left == 7'd0 && sec_left == 7'd0)) begin // se o stop for ativado ou timer estiver em 00:00
            EA <= 2'd00; // a máquina de estados volta para o estado IDLE
          end
          else if (pause_ed == 1) begin // se o pause for ativado
            EA <= 2'd02; // EA - Pause
          end
        end
        
      2'd2: // PAUSED 
        begin
          if (pause_ed == 1 || start_ed == 1) begin // se pause for 1 ou o start for 1
            EA <= 2'd01; // EA - CD
          end
          else if (stop_ed == 1) begin // se o stop for 1
            EA <= 2'd00; // EA - IDLE
          end
        end

    endcase

  end
end

assign done = (EA == 2'd0) ? 1'b1 : 1'b0;
assign uni_min = (min_left%10);
assign dez_min = (min_left/10);
assign uni_seg = (sec_left%10);
assign dez_seg = (sec_left/10);

    // Decrementador de tempo (minutos e segundos)
    // 1'b0 = falso
    // 1'b1 = true

always @(posedge clk_1 or posedge reset) begin
  if(reset)begin    
    min_left <= 7'd0;
    sec_left <= 7'd0;
  end
  else begin
    if(EA == 2'd0)begin
      if(min > 7'd99)begin
        min_left <= 7'd99;
        sec_left <= 7'd59;
      end
      else begin
        min_left <= min;
      end

      if(sec > 7'd59)begin
       sec_left <= 7'd59;
      end
      else begin
       sec_left <= sec;
      end
    end
    else if(EA == 2'd1)begin
      if(sec_left == 7'd0)begin
          min_left <= min_left - 1; // decrementa um nos min faltantes
          sec_left <= 7'd59;
        end
      else begin
       sec_left <=sec_left - 1; // decrementa os segundos faltantes
      end
    end
  end
end 


 // Instanciação da display 7seg
  dspl_drv_NexysA7 driver (.reset(reset), .clock(clock), .d1({1'b1,uni_seg[3:0],1'b0}), .d2({1'b1,dez_seg[3:0],1'b0}), .d3({1'b1,uni_min[3:0],1'b0}), .d4({1'b1,dez_min[3:0],1'b0}), .d5(6'd0), .d6(6'd0), .d7(6'd0), .d8(6'd0), .an(an), .dec_cat(dec_cat));
  
  // .reset(reset): entrada do reset para o driver
  // .clock(clock): entrada do clock para o driver
  // .d1({1'b1,uni_seg[3:0],1'b0}): valor para ser exibido no primeiro dígito dos segundos do display
  // .d2({1'b1,dez_seg[3:0],1'b0}): valor para ser exibido no segundo dígito dos segundos do display
  // .d3({1'b1,uni_min[3:0],1'b0}): valor para ser exibido no terceiro dígito do display (unidade)
  // .d4({1'b1,dez_min[3:0],1'b0}): valor para ser exibido no quarto dígito do display (dezenas)
  // .d4 até .d8 não são utilizados
  // .an(an): sinais de controle
  // .dec_cat(dec_cat): sinais de controle para os displays

endmodule                                                  
