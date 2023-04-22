module timer
  #(parameter HALF_MS_CONT = 50000)
(
  // Declaração das portas
  input start,
  input pause,
  input stop,
  input min[6:0], // min é uma entrada de 6 bits
  input sec[6:0], // sec é uma entrada de 6 bits
  input reset,
  input clock,
  output an[7:0],  // qual display ta selecionadp
  output dec_cat[7:0], // numero q vai ser mostrado??
  output reg done // precisamos guardar o valor disso até q outro seja enviado
);

    // Declaração dos sinais
    // essas variáveis são declaradas como fio pq são os botões, os valores delas não  precisam ser guardados em nunhum lugar
    wire start_f,
    wire pause_f,
    wire stop_f,

    reg clk_1;
    reg [31:0] cont_50K;
    reg [6:0] min_reg, sec_reg;
    reg [1:0] EA_reg;
    reg [13:0] count; // contador de tempo, 14 bits para contar até 24h
    reg done; // sinal que indica que o contador chegou a 00:00
    
    // Instanciação dos edge_detectors
    // isso ta no arquivo edge_detector.v aqui é só chamada dele
  edge_detector startf (.clock(clock), .reset(reset), .din(start), .rising(start_f)); // o sinal clock conectado ao pino de entrada clock que estão instanciados no aruqivo do edge detector
  edge_detector pausef (.clock(clock), .reset(reset), .din(pause), .rising(pause_f));
  edge_detector stopf (.clock(clock), .reset(reset), .din(stop), .rising(stop_f));
  

    // Divisor de clock para gerar o ck1seg
    always @(posedge clock or posedge reset)
    begin
      // esse ta em 1Khz mas me disseram q n precisa colocar pra um, pq?
      if (reset == 1'b1) begin // se o reset estiver no valor l´´ogico um(ativado)
        clk_1   <= 1'b0;
        cont_50K <= 32'd0; // contador reinuciado com o valor 0
      end
      else begin
        if (cont_50K == HALF_MS_CONT-1) begin
          clk_1  <= ~clk_1; // o sinal de clock é invertido de 0 para um ou de 1 para 0
          cont_50K <= 32'd0; // contador reinuciado com o valor 0
       end
      else begin
        cont_50K <= cont_50K + 1; // o contador é incrementado em 1 a cada ciclo de clock
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

    // 2'b00 = IDLE
    // 2'b01 = CD
    // 2'B10 = PAUSED 
    // 1'b0 = falso
    // 1'b1 = true

  if (reset == 1) begin
    EA_reg <= 2'b00; // estado IDLE
    done <= 1'b0;
    min_reg <= 7'd0; // definindo o temporizador dos minutos em 0
    sec_reg <= 7'd0; // definindo o temporizador dos segundos em 0
  end

  else begin

    case (EA_reg)
      2'b00: // IDLE
        begin
          if (start == 1) begin // se o start == 1, o EA será o CD
            EA_reg <= 2'b01; // CD 
            done <= 1'b0;
            min_reg <= 7'd0; 
            sec_reg <= 7'd0; 
          end
        end

      2'b01: // CD 
        begin
          if (stop == 1 || (min_reg == 7'd0 && sec_reg == 7'd0)) begin // se o stop for ativado ou timer estiver em 00:00
            EA_reg <= 2'b00; // a máquina de estados volta para o estado IDLE
            done <= 1'b1; 
          end
          else if (pause == 1) begin // se o pause for ativado
            EA_reg <= 2'b10; // EA - Paused
            done <= 1'b0;
          end
        end
        
      2'b10: // PAUSED 
        begin
          if (pause == 1 || start == 1) begin // se pause for 1 ou o start for 1
            EA_reg <= 2'b01; // EA - CD
            done <= 1'b0;
          end
          else if (stop == 1) begin // se o stop for 1
            EA_reg <= 2'b00; // EA - IDLE
            done <= 1'b1;
          end
        end

    endcase

  end
end


    // Decrementador de tempo (minutos e segundos)
    // 1'b0 = falso
    // 1'b1 = true
    // perguntar pro Tomáz quantos bits tem o contador dele

always @(posedge clk1seg or posedge reset) begin

  if (reset == 1'b1) begin
    count <= {7'd0, 7'd0}; // reinicia o contador
    done <= 1'b0; // zera o sinal done
  end

  else begin
    if (count == 14'd0) begin
      done <= 1'b1; // o contador chegou a 00:00
    end

    else begin
      count <= count - 1; // decrementa o contador a cada pulso de clock
    end

  end

end

    // Instanciação da display 7seg
    //------------
    // COMPLETAR
    //------------
    
    
endmodule
