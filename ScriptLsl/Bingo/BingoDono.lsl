integer canal_bingo = 7777;
float intervalo_sorteio = 6.0; // Segundos entre cada número cantado
list numeros_sorteados = [];
integer jogando = FALSE;

default
{
    state_entry()
    {
        // O globo ouve o mesmo canal para escutar quando alguém ganha
        llSetObjectName("Bingo Dono");
        llListen(canal_bingo, "", NULL_KEY, "");
        llSetText("🎱 BINGO MASTER PRO 🎱\nClique para Iniciar o Jogo", <1.0, 1.0, 1.0>, 1.0);
    }

    touch_start(integer total_number)
    {
        // Apenas o dono pode iniciar ou parar o bingo
        if (llDetectedKey(0) == llGetOwner())
        {
            if (jogando == FALSE)
            {
                jogando = TRUE;
                numeros_sorteados = [];
                llSay(0, "Atenção todos! O Bingo vai começar! O globo está a girar...");
                llSetText("🎱 SORTEIO EM ANDAMENTO 🎱", <1.0, 1.0, 0.0>, 1.0);
                llSetTimerEvent(intervalo_sorteio); // Inicia o temporizador
            }
            else
            {
                // Se clicar novamente enquanto joga, ele pausa
                jogando = FALSE;
                llSetTimerEvent(0.0);
                llSay(0, "Sorteio pausado pelo anfitrião.");
                llSetText("🎱 JOGO PAUSADO 🎱\nClique para continuar", <1.0, 0.5, 0.0>, 1.0);
            }
        }
    }

    timer()
    {
        if (llGetListLength(numeros_sorteados) >= 75)
        {
            llSetTimerEvent(0.0);
            jogando = FALSE;
            llSay(0, "Todos os números foram sorteados! O jogo terminou.");
            llSetText("🎱 FIM DE JOGO 🎱\nClique para recomeçar", <1.0, 1.0, 1.0>, 1.0);
            return;
        }

        integer num_sorteado;
        // Garante que não sorteia repetido
        do {
            num_sorteado = 1 + (integer)llFrand(75.0);
        } while (llListFindList(numeros_sorteados, [num_sorteado]) != -1);
        
        numeros_sorteados += [num_sorteado];
        
        // Canta o número para todos no chat local
        llSay(0, "Sorteado: " + (string)num_sorteado);
        
        // Envia o número silenciosamente para as cartelas marcarem
        llRegionSay(canal_bingo, (string)num_sorteado);
        
        // Atualiza o texto flutuante no globo
        llSetText("🎱 SORTEANDO 🎱\nÚltimo número: " + (string)num_sorteado, <0.0, 1.0, 1.0>, 1.0);
    }

    listen(integer channel, string name, key id, string message)
    {
        // O GLOBO OUVE A CARTELA DO VENCEDOR
        if (llSubStringIndex(message, "VENCEDOR:") == 0)
        {
            // Para o sorteio imediatamente
            llSetTimerEvent(0.0);
            jogando = FALSE;
            
            // Extrai o nome de quem ganhou
            string nome_vencedor = llGetSubString(message, 9, -1);
            
            llSay(0, "🏆 O GLOBO PAROU AUTOMATICAMENTE! O jogador " + nome_vencedor + " bateu a cartela!");
            llSetText("🏆 TEMOS UM VENCEDOR! 🏆\n" + nome_vencedor + "\nClique para iniciar outra rodada", <0.0, 1.0, 0.0>, 1.0);
        }
    }
}