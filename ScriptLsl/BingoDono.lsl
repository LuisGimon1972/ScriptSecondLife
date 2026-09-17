list bolas_disponiveis = [];
integer total_bolas = 75;
integer jogo_ativo = FALSE;
integer canal_bingo = 7777; // Canal de rádio privado para as cartelas

default
{
    state_entry()
    {
        llOwnerSay("🎲 [GLOBO PRINCIPAL] Sorteador pronto. Toque no objeto para iniciar ou parar o jogo!");
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
                
                // Define o tempo do sorteio (ex: a cada 5 segundos sai um número)
                llSetTimerEvent(5.0);
            }
            else
            {
                // Pausa/Encerra o jogo
                jogo_ativo = FALSE;
                llSetTimerEvent(0.0);
                llSay(0, "🛑 [GLOBO PRINCIPAL] O jogo de Bingo foi encerrado pelo anfitrião.");
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
        }
        else
        {
            // Fim de jogo automático quando acabam as 75 bolas
            jogo_ativo = FALSE;
            llSetTimerEvent(0.0);
            llSay(0, "🏆 [GLOBO PRINCIPAL] Fim de rodada! Todas as bolas foram sorteadas.");
        }
    }
}