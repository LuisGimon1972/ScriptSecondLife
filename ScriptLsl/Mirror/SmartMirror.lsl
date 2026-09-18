// Lista de itens disponíveis no espelho
list menu_itens = ["Jaqueta Couro", "Vestido Festa", "Oculos Sol", "Limpar Look"];
integer canal_dialogo = -112233;
integer listener_handle;

default
{
    state_entry()
    {
        llSetObjectName("Smart Mirror v1.00");
        llOwnerSay("🪞 Smart-Mirror pronto e operacional.");
        
        // Efeito visual sutil de partículas na moldura
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
        key cliente = llDetectedKey(0);
        
        // Pede permissão para interagir com o inventário/anexo do avatar
        llRequestPermissions(cliente, PERMISSION_ATTACH);
        
        // Abre o canal exclusivo para este cliente
        listener_handle = llListen(canal_dialogo, "", cliente, "");
        
        // Exibe o menu holográfico na tela
        llDialog(cliente, "\n🪞 PROVADOR VIRTUAL INTELIGENTE\nEscolha um item para testar instantaneamente:", menu_itens, canal_dialogo);
        
        // Timer de segurança de 30 segundos
        llSetTimerEvent(30.0);
    }

    listen(integer channel, string name, key id, string message)
    {
        if (channel == canal_dialogo)
        {
            llListenRemove(listener_handle);
            llSetTimerEvent(0.0);
            
            if (message == "Limpar Look")
            {
                llRegionSayTo(id, 0, "🔄 Provador limpo com sucesso.");
            }
            else
            {
                // Verifica se o item existe no inventário do espelho
                if (llGetInventoryType(message) != INVENTORY_NONE)
                {
                    // Envia a peça de teste diretamente para o inventário do cliente
                    llGiveInventory(id, message);
                    
                    llRegionSayTo(id, 0, "✨ Look aplicado: '" + message + "'. Verifique seu avatar!");
                }
                else
                {
                    llRegionSayTo(id, 0, "⚠️ Ops! Este item não está disponível no espelho no momento.");
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