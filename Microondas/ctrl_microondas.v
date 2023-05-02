module ctrl_microondas
(
  // Declaração das portas
  input start,
  input stop,
  input pause,
  input porta,
  input mais,
  input menos,
  input potencia,
  input [1:0] min_mode,
  input sec_mode,
  input reset,
  input clock,

  output [7:0] an,
  output [7:0] dec_cat, // retorna o dígito mais significativo do contador do micro
  output [2:0] potencia_rgb
);


  // as crianças abaixo foram declaradas como wire pq são simples botões
  // e como o iaçanã disse que usamos muito reg, essa foi uma das alternativas :D

  wire start_ed;
  wire pause_ed;
  wire stop_ed;
  wire mais_ed;
  wire menos_ed;
  wire [7:0]an_s; // vai servir para a luz da potência
  wire [7:0]dec_cat_timer, dec_cat_pot;
  wire done_ed;

  reg [1:0] EA;
  reg [6:0] min, sec;
  reg [1:0] sel_potencia;
  reg [1:0]porta_pause;

  // instanciação do timer
  timer timepp (.clock(clock), .stop(stop_ed), .pause(porta_pause),.start(start_ed), .reset(reset), .done(done_ed), .min(min), .sec(sec), .an(an_s), .dec_cat(dec_cat_timer)); // min daqui vira o do timer

  assign an = an_s;
  
  
  //EDGE DETECTOR INSTANCIAÇÃO 
  edge_detector startf (.clock(clock), .reset(reset), .din(start), .rising(start_ed)); // o sinal clock conectado ao pino de entrada clock que estão instanciados no arquivo do edge detector
  edge_detector pausef (.clock(clock), .reset(reset), .din(pause), .rising(pause_ed));
  edge_detector stopf (.clock(clock), .reset(reset), .din(stop), .rising(stop_ed));
  edge_detector menosf (.clock(clock), .reset(reset), .din(menos), .rising(menos_ed));
  edge_detector maisf (.clock(clock), .reset(reset), .din(mais), .rising(mais_ed));
  
  // Porta aberta: 1
  // Porta fechada: 0

   always @(posedge clock or posedge reset)begin
   if(reset == 1)begin 
    porta_pause <= 1'b0;
   end 
   else if(pause_ed == 1 || porta == 1)begin //Se for pausado OU a porta for aberta, vamos de pause
        porta_pause <= 1'b1;
   end
   else begin
        porta_pause <= 1'b0;
   end
   end
  

// ---------------------------------------------------------------------------------------------------------

  // Máquina de estados
  always @(posedge clock or posedge reset)begin
  
  // EA = 2'd0 -> configuração
  // EA = 2'd1 -> decrementa tempo
  // EA = 2'd2 -> pausa
  // EA = 2'd3 -> espera

  if(reset == 1)begin
   EA <= 2'd0;
  end

  else begin
    case(EA)
      2'd0: // Estamos configurando
        begin
          if(start_ed == 1)begin // começamos a contar o tempo
            EA <= 2'd3;
          end
        end

      2'd1: // Estamos decrementando o tempo
        begin
          if(porta_pause == 1'b1)begin //Se a porta estiver aberta, entra no pause
            EA <= 2'd2; // entramos no estado de pause
          end
          else if(stop_ed == 1 || done_ed == 1 )begin  // se o stop ou done forem ativados, aí o bagulho acaba 
              EA <= 2'd0; // e voltamos pra config :D
          end
        end

      2'd2: // Estamos pausando
        begin
          if(start_ed == 1 || porta_pause == 1 )begin //se o start for iniciado ou o botão de pause for apertado mais uma vez
            EA <= 2'd1; // tamo rodando
          end
        end
      
      2'd3: // Estamos esperando
      begin
          if(done_ed == 0)begin //acabou a espera?
            EA <= 2'd1; // show decrementa ai
          end 
          else begin
            EA <= 2'd3; // continua esperando
          end
       end
          
       default: begin
            EA <= 2'd0; // a tendencia de um corpo é permanecer parado até que uma força mexa com ele
       end 
    endcase
    end
  end

// ---------------------------------------------------------------------------------------------------------

always@(posedge clock or posedge reset) begin

  //SOMA E SUB DE MIN E SEC
  // EA = 2'd0 -> configuração
  // EA = 2'd1 -> decrementa tempo
  // EA = 2'd2 -> pausa
  // EA = 2'd3 -> espera

if(reset == 1)begin //ativamos o reset e zeramos os minutos e segundos, quem diria
     min <= 7'd0;
     sec <= 7'd0;
end
else if( EA == 2'd1)begin // se estivermos decrementando, os valores tb serão setados para zero
    min <= 7'd0;
     sec <= 7'd0;
end

else begin
if(potencia == 0)begin // se a potência estiver em 0

// MINUTOS

if(min_mode[1])begin // se o bit mais significativo de min_mode for 1, o incremento/decremento será de 10 em 10
    if(mais_ed == 1)begin // se for adicionado na plaquinha:
        if(min >= 7'd90) begin // se o valor dos minutos for maior que 90:
            min <= 7'd99; // o valor dos minutos será definido para 99
            sec <= 7'd59; // o valor dos segundos será definido para 59
        end
        else begin 
        min <= min + 7'd10; // aqui ele tá acrescentando tempo de 10 em 10
        end
    end
    else if(menos_ed == 1)begin  // se apertarmos o botão de diminuir na plaquinha:
      min <= min - 10; // bom, vamos diminuir de 10 em 10 também
    end
end 
else if(min_mode[0])begin // se o bit mais significativo de min_mode for 0, o incremento/decremento será de 1 em 1
    if(mais_ed == 1)begin // se for adicionado na plaquinha:
      min <= min + 1; // +1 no tempo
    end
    else if(menos_ed == 1)begin  // se for removido na plaquinha:
        if(min == 7'd0)begin // -1 no tempo
        min <= 7'd0;
        end
      min <= min - 1;
    end
end

// SEGUNDOS 

else if(sec_mode == 1)begin // se o sec mode for 1
  if(mais_ed == 1)begin // se o botão de mais foi pressionado:
       if(sec >= 7'd59) begin // vamos verificar se o valor atual de segundos é maior que 59
          sec <= 7'd59; // é? beleza, vou manter meu 59 aqui.
        end
      sec <= sec + 10; // não é? beleza, vou comer 10 unidades de segundos aqui
    end
    else if(menos_ed == 1)begin  // se o botão de menos foi pressionado:
        if(sec == 7'd0)begin // os segundos estão zerados?
        sec <= 7'd0; // mantém em 0 
        end
      sec <= sec - 10; // não estão zerados? vou comer 10 unidades de segundos
    end
  end
else if(sec_mode == 0)begin // se o sec mode for 0
   if(mais_ed == 1)begin // o botão de mais foi pressionado?
      sec <= sec + 1; // foi? toma 1s aí
    end
        else if(menos_ed == 1)begin  // o botão de menos foi pressionado?
         sec <= sec - 1; // foi? me dá 1s aí
        end
      end
    end
  end
end

// ---------------------------------------------------------------------------------------------------------

// PORTA ABERTA OU FECHADA
// 1'b1 = true = está aberta
// 1'b0 = false = porta está fechada
// isso aqui é feito na máquina de estados

// Seleção das potências
assign dec_cat_pot = (sel_potencia == 2'd0) ?  8'b11101111:
                      (sel_potencia == 2'd1) ? 8'b11111101:
                      8'b01111111 ;


always @(posedge clock or posedge reset)begin
    if(reset == 1)begin
      sel_potencia <= 2'd0; // nível baixo
    end
    
    else begin
    if(potencia == 1 && EA == 2'd0)begin
      case(sel_potencia)
        2'd0:
          begin
            if(mais_ed == 1)begin
              sel_potencia <= 2'd1;
            end 
            else if(menos_ed == 1)begin
              sel_potencia <= 2'd0; 
            end
          end
        2'd1:
          begin
            if(mais_ed == 1)begin
              sel_potencia <= 2'd2;
            end
            else if(menos_ed == 1)begin
              sel_potencia <= 2'd0;   
            end
          end
        2'd2:
          begin
            if(mais_ed == 1)begin
              sel_potencia <= 2'd2;
            end
            else if(menos_ed == 1)begin
              sel_potencia <= 2'd1; 
            end
          end
        endcase
    end
  end 
end


assign dec_cat = (an_s[5] == 0) ? dec_cat_pot :
                  dec_cat_timer;

assign potencia_rgb = (EA == 2'd0 || EA == 2'd2 || porta_pause == 1'b1) ? 3'b000: // esse fica desligado enquanto n ser start
                      (sel_potencia == 2'd0) ? 3'b001: // esse é o azul
                      (sel_potencia == 2'd1) ? 3'b010: // esse é o verde
                      3'b100; // esse é o vermelho

endmodule

