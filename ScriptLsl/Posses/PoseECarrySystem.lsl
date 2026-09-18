// ==========================================
// ULTIMATE SIT & PROP SYSTEM - DEFINITIVE CODE
// ==========================================

// Configurações principais (altere conforme os nomes no inventário)
string PROP_NAME = "Copo de Cafe";          // Nome exato do objeto prop no inventário
string SIT_ANIMATION = "sit_relaxado";     // Nome exato da animação no inventário
vector SIT_POSITION = <0.0, 0.0, 0.4>;     // Posição exata do encaixe (X, Y, Z)
rotation SIT_ROTATION = ZERO_ROTATION;     // Rotação inicial ao sentar

key currentAvatar = NULL_KEY;
key rezzedPropID = NULL_KEY;

default
{
    state_entry()
    {
        // Configura o objeto para agir como assento e exibe o texto ao passar o mouse
        llSetClickAction(CLICK_ACTION_SIT);
        llSetSitText("Sentar & Usar");
        llSitTarget(SIT_POSITION, SIT_ROTATION);
    }

    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            key avatar = llAvatarOnSitTarget();
            
            // Evento: Alguém sentou no móvel
            if (avatar != NULL_KEY && currentAvatar == NULL_KEY)
            {
                currentAvatar = avatar;
                // Pede permissão para animar o avatar e anexar o objeto
                llRequestPermissions(currentAvatar, PERMISSION_TRIGGER_ANIMATION | PERMISSION_ATTACH);
            }
            // Evento: Alguém levantou do móvel
            else if (avatar == NULL_KEY && currentAvatar != NULL_KEY)
            {
                // Para a animação de sentar
                llStopAnimation(SIT_ANIMATION);
                
                // Limpa o prop criado se ele ainda existir na região
                if (rezzedPropID != NULL_KEY)
                {
                    llRegionSayTo(currentAvatar, 0, "Guardando acessório...");
                }
                
                currentAvatar = NULL_KEY;
                rezzedPropID = NULL_KEY;
            }
        }
    }

    run_time_permissions(integer perm)
    {
        if ((perm & PERMISSION_TRIGGER_ANIMATION) && (perm & PERMISSION_ATTACH))
        {
            // Para a animação padrão de sentar do sistema e inicia a customizada
            llStopAnimation("sit");
            llStartAnimation(SIT_ANIMATION);
            
            // Cria o prop (copo/livro) próximo ao móvel passando o parâmetro de ID (99)
            vector spawnPos = llGetPos() + <0.0, 0.0, 0.8>;
            llRezObject(PROP_NAME, spawnPos, ZERO_VECTOR, ZERO_ROTATION, 99);
        }
    }
}