list bolas_disponiveis = [];
integer total_bolas = 75;
integer jogo_ativo = FALSE;
integer canal_bingo = 7777; // Canal de rádio privado para as cartelas

default
{
    state_entry()
    {
        llOwnerSay("🎲 [GLOBO PRINCIPAL] Sorteador pronto. Toque no objeto para iniciar ou parar o jogo!");
        
        // Define um texto inicial indicando que o globo está pronto
        llSetText("🎲 BINGO PRONTO\nToque para iniciar", <0.0, 1.0, 1.0>, 1.0);
    }

    touch_start(integer total_number)
    {
        // Garante que apenas o dono do objeto/simulação pode controlar o jogo
        if (llDetectedKey(0) == llGetOwner())
        {
            if (!jogo_ativo)
            {
                // Inicia o jogo e recria o globo de 1 a 75
                jogo_ativo = TRUE;
                bolas_disponiveis = [];
                integer i;
                for (i = 1; i <= total_bolas; i++)
                {
                    bolas_disponiveis = (list)i + bolas_disponiveis;
                }
                
                llSay(0, "📢 BINGO INICIADO! As cartelas já estão ativas e ouvindo os números.");
                
                // Atualiza o texto flutuante informando que o jogo começou
                llSetText("🎲 BINGO EM ANDAMENTO\nAguardando próximo número...", <1.0, 1.0, 0.0>, 1.0);
                
                // Define o tempo do sorteio (a cada 5 segundos sai um número)
                llSetTimerEvent(5.0);
            }
            else
            {
                // Pausa/Encerra o jogo
                jogo_ativo = FALSE;
                llSetTimerEvent(0.0);
                llSay(0, "🛑 [GLOBO PRINCIPAL] O jogo de Bingo foi encerrado pelo anfitrião.");
                
                // Limpa ou reseta o texto flutuante ao encerrar
                llSetText("⏹️ BINGO ENCERRADO", <1.0, 0.0, 0.0>, 1.0);
            }
        }
    }

    timer()
    {
        if (jogo_ativo && llGetListLength(bolas_disponiveis) > 0)
        {
            // Sorteia um índice aleatório na lista restante
            integer indice = (integer)llFrand(llGetListLength(bolas_disponiveis));
            integer numero_sorteado = llList2Integer(bolas_disponiveis, indice);
            
            // Remove a bola sorteada para evitar repetições
            bolas_disponiveis = llDeleteSubList(bolas_disponiveis, indice, indice);
            
            // Anuncia publicamente no chat da região para todos verem
            llSay(0, "🎯 Sorteado: " + (string)numero_sorteado);
            
            // Transmite o número silenciosamente para as cartelas dos jogadores
            llRegionSay(canal_bingo, (string)numero_sorteado);
            
            // 🌟 ATUALIZA O TEXTO FLUTUANTE COM O NÚMERO SORTEADO EM DESTAQUE (Amarelo)
            llSetText("🎯 ÚLTIMO NÚMERO:\n[ " + (string)numero_sorteado + " ]", <1.0, 1.0, 0.0>, 1.0);
        }
        else
        {
            // Fim de jogo automático quando acabam as 75 bolas
            jogo_ativo = FALSE;
            llSetTimerEvent(0.0);
            llSay(0, "🏆 [GLOBO PRINCIPAL] Fim de rodada! Todas as bolas foram sorteadas.");
            
            // Atualiza o texto flutuante para fim de rodada
            llSetText("🏆 FIM DE JOGO!\nTodas as bolas sorteadas", <0.0, 1.0, 0.0>, 1.0);
        }
    }
}