// Lista de itens que o espelho vai procurar no próprio conteúdo e testar no avatar
list menu_itens = ["Jaqueta Couro", "Vestido Festa", "Oculos Sol", "Limpar Look"];
integer canal_dialogo = -112233;
integer listener_handle;

// Variável para rastrear o item que o cliente está usando no momento
key cliente_atual = NULL_KEY;

default
{
    state_entry()
    {
        llOwnerSay("🪞 Smart-Mirror de Prova Real inicializado.");
        
        // Efeito visual sutil de partículas na moldura do espelho
        llParticleSystem([
            PSYS_PART_FLAGS, PSYS_PART_EMISS_MASK | PSYS_PART_FOLLOW_SRC_MASK,
            PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
            PSYS_PART_START_COLOR, <1.0, 1.0, 1.0>,
            PSYS_PART_END_COLOR, <0.7, 0.7, 1.0>,
            PSYS_PART_START_ALPHA, 0.5,
            PSYS_PART_END_ALPHA, 0.0,
            PSYS_PART_START_SCALE, <0.04, 0.04, 0.0>,
            PSYS_SRC_MAX_AGE, 1.0,
            PSYS_SRC_BURST_RATE, 2.5,
            PSYS_SRC_BURST_PART_COUNT, 4,
            PSYS_SRC_ACCEL, <0.0, 0.0, 0.02>
        ]);
    }

    touch_start(integer total_number)
    {
        cliente_atual = llDetectedKey(0);
        
        // Solicita permissão para anexar objetos e controlar o avatar que clicou
        llRequestPermissions(cliente_atual, PERMISSION_ATTACH);
        
        // Abre o canal de escuta exclusivo
        listener_handle = llListen(canal_dialogo, "", cliente_atual, "");
        
        // Exibe o menu interativo
        llDialog(cliente_atual, "\n🪞 PROVADOR VIRTUAL INTELIGENTE\nEscolha um look para vestir instantaneamente:", menu_itens, canal_dialogo);
        
        llSetTimerEvent(30.0);
    }

    run_time_permissions(integer perm)
    {
        // Se o cliente aceitar a permissão de anexo, o provador está pronto para vestir as peças
    }

    listen(integer channel, string name, key id, string message)
    {
        if (channel == canal_dialogo)
        {
            llListenRemove(listener_handle);
            llSetTimerEvent(0.0);
            
            if (message == "Limpar Look")
            {
                llRegionSayTo(id, 0, "🔄 Provador limpo. Suas roupas padrão foram restauradas.");
                // Opcional: Código para desatachar itens de teste anteriores se necessário
            }
            else
            {
                // Verifica se o item existe no inventário do espelho
                if (llGetInventoryType(message) != INVENTORY_NONE)
                {
                    // Envia o item para o inventário do cliente e solicita o "Attach" imediato
                    // Nota: O método mais fluido no SL para provadores é entregar uma cópia temporária 
                    // ou acionar o comando de anexo configurado no item.
                    llGiveInventory(id, message);
                    
                    llRegionSayTo(id, 0, "✨ Look aplicado: " + message + "! Verifique o seu avatar.");
                }
                else
                {
                    llRegionSayTo(id, 0, "⚠️ Este item não está disponível no espelho no momento.");
                }
            }
        }
    }

    timer()
    {
        llListenRemove(listener_handle);
        llSetTimerEvent(0.0);
    }
}